// Saathi session + guide server on Cloudflare Workers (free plan). Same API as
// server/session_server.mjs, but online, so the phone needs no USB cable or laptop.
//
//   POST /session          (app, X-Dev-Token)    mint a short-lived Bolna web-call session
//   GET  /events?device=   (app, X-Dev-Token)    long-poll: next guide action from the agent
//   POST /events/result    (app, X-Dev-Token)    the app's answer to that action
//   POST /tool             (Bolna, Bearer token) agent asks the app to move the guide
//
// Each phone gets its own Durable Object (DeviceRelay), which holds the agent's pending
// requests in memory and pairs them with the app's long-poll.
//
// Secrets (wrangler secret put): BOLNA_API_KEY, BOLNA_AGENT_ID, DEV_SESSION_TOKEN, TOOL_TOKEN.

const BOLNA_MINT_URL = "https://api.bolna.ai/web-call/session";
const LANGUAGES = new Set(["en", "mr"]);
// Context the app may pass to the agent prompt as {variables}. Informational only:
// the app's workflow engine, not the agent, decides the current step.
const USER_DATA_KEYS = [
  "saathi_device",
  "saathi_welcome",
  "saathi_task",
  "saathi_step",
  "saathi_instruction",
];
const TOOL_ACTIONS = new Set([
  "show_topic",
  "start_guide",
  "step_done",
  "go_back",
  "outcome",
  "close_topic",
  "current_step",
]);
const MAX_MINTS_PER_MINUTE = 10; // each mint can hold a concurrent-call slot on the account
const APP_ANSWER_TIMEOUT_MS = 6000;
const LONG_POLL_MS = 25_000;
const MAX_BODY = 8192;
// Event ids carry the device id, so the app's answer finds its relay.
const ID_SEP = "~";

const json = (status, body) =>
  new Response(typeof body === "string" ? body : JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });

function same(given, expected) {
  const enc = new TextEncoder();
  const a = enc.encode(given ?? "");
  const b = enc.encode(expected ?? "");
  return a.byteLength === b.byteLength && b.byteLength > 0 && crypto.subtle.timingSafeEqual(a, b);
}

async function readJson(request) {
  const text = await request.text();
  if (text.length > MAX_BODY) throw new Error("body too large");
  return JSON.parse(text || "{}");
}

const relay = (env, device) => env.RELAY.get(env.RELAY.idFromName(`device:${device}`));

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    try {
      if (request.method === "POST" && url.pathname === "/tool") return await handleTool(request, env, url);

      if (!same(request.headers.get("x-dev-token"), env.DEV_SESSION_TOKEN)) {
        return json(401, { error: "bad or missing X-Dev-Token" });
      }
      if (request.method === "GET" && url.pathname === "/events") {
        const device = url.searchParams.get("device") ?? "";
        if (!device || device.includes(ID_SEP)) return json(400, { error: "device required" });
        return relay(env, device).fetch("https://relay/events");
      }
      if (request.method === "POST" && url.pathname === "/events/result") {
        const input = await readJson(request);
        const id = typeof input.id === "string" ? input.id : "";
        const device = id.slice(0, id.lastIndexOf(ID_SEP));
        if (!device) return json(200, { ok: true });
        return relay(env, device).fetch("https://relay/result", {
          method: "POST",
          body: JSON.stringify({ id, result: input.result ?? { ok: false } }),
        });
      }
      if (request.method === "POST" && url.pathname === "/session") return await handleMint(request, env);
      return json(404, { error: "not found" });
    } catch (e) {
      return json(400, { error: String(e.message ?? e) });
    }
  },
};

/** Bolna custom function: forwards to the app and returns the app's answer. */
async function handleTool(request, env, url) {
  if (!same(request.headers.get("authorization"), `Bearer ${env.TOOL_TOKEN}`)) {
    return json(401, { error: "unauthorized" });
  }
  let body = {};
  try {
    body = await readJson(request);
  } catch {}
  const input = { ...Object.fromEntries(url.searchParams), ...body };
  const device = typeof input.saathi_device === "string" ? input.saathi_device : "";
  const action = input.action;
  if (!device || device.includes(ID_SEP) || !TOOL_ACTIONS.has(action)) {
    return json(200, { ok: false, message: "Unknown device or action." });
  }
  const event = {
    id: `${device}${ID_SEP}${crypto.randomUUID()}`,
    action,
    app: typeof input.app === "string" ? input.app.toLowerCase() : null,
    topic: typeof input.topic === "string" ? input.topic.toLowerCase() : null,
    language: input.language === "mr" || input.language === "en" ? input.language : null,
    new_user: input.new_user === true || input.new_user === "yes" || input.new_user === "true",
    step_id: typeof input.step_id === "string" ? input.step_id : null,
    booked: input.booked === true || input.booked === "yes" || input.booked === "true",
  };
  const r = await relay(env, device).fetch("https://relay/tool", {
    method: "POST",
    body: JSON.stringify(event),
  });
  const result = await r.text();
  console.log("tool", { action, step: event.step_id, result: result.slice(0, 120) });
  return json(200, result);
}

async function handleMint(request, env) {
  const limit = await env.RELAY.get(env.RELAY.idFromName("mint-limit")).fetch("https://relay/mint-slot", {
    method: "POST",
  });
  if (limit.status !== 200) return json(429, { error: "rate limit" });

  const input = await readJson(request);
  // Only agent_id, an optional language and whitelisted context reach Bolna.
  const mintBody = { agent_id: env.BOLNA_AGENT_ID };
  const userData = {};
  for (const key of USER_DATA_KEYS) {
    const value = input.user_data?.[key];
    if (typeof value === "string" && value.length <= 400) userData[key] = value;
  }
  if (Object.keys(userData).length) mintBody.user_data = userData;
  if (input.language !== undefined && input.language !== null) {
    if (!LANGUAGES.has(input.language)) return json(400, { error: "language must be en or mr" });
    mintBody.agent_data = { language: input.language };
  }

  try {
    const r = await fetch(BOLNA_MINT_URL, {
      method: "POST",
      headers: { Authorization: `Bearer ${env.BOLNA_API_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify(mintBody),
    });
    const text = await r.text();
    // The response carries one-time SIP/TURN credentials: log only non-secret fields.
    let runId = null;
    try {
      runId = JSON.parse(text).run_id ?? null;
    } catch {}
    console.log("mint", {
      status: r.status,
      language: mintBody.agent_data?.language ?? "(agent default)",
      runId,
      ...(r.ok ? {} : { error: text.slice(0, 300) }),
    });
    return json(r.status, text); // returned unchanged, as the docs prescribe
  } catch (e) {
    console.log("mint request failed:", e.message);
    return json(502, { error: "could not reach Bolna" });
  }
}

/** One per phone (plus one for the mint rate limit). State is in memory only. */
export class DeviceRelay {
  constructor() {
    this.queue = [];
    this.waiter = null;
    /** event id -> resolve(result text) for the waiting /tool request */
    this.pending = new Map();
    this.mints = [];
  }

  async fetch(request) {
    const { pathname } = new URL(request.url);
    if (pathname === "/tool") return this.tool(await request.json());
    if (pathname === "/events") return this.nextEvent();
    if (pathname === "/result") {
      const { id, result } = await request.json();
      const resolve = this.pending.get(id);
      if (resolve) {
        this.pending.delete(id);
        resolve(JSON.stringify(result));
      }
      return json(200, { ok: true });
    }
    if (pathname === "/mint-slot") {
      const now = Date.now();
      this.mints = this.mints.filter((t) => now - t < 60_000);
      if (this.mints.length >= MAX_MINTS_PER_MINUTE) return json(429, { error: "rate limit" });
      this.mints.push(now);
      return json(200, { ok: true });
    }
    return json(404, { error: "not found" });
  }

  async tool(event) {
    const answer = new Promise((resolve) => {
      this.pending.set(event.id, resolve);
      setTimeout(() => {
        if (this.pending.delete(event.id)) {
          // Never let a stale action apply later (e.g. after the app restarts).
          this.queue = this.queue.filter((e) => e.id !== event.id);
          resolve(JSON.stringify({ ok: false, message: "The Saathi screen did not respond. Keep guiding by voice." }));
        }
      }, APP_ANSWER_TIMEOUT_MS);
    });
    if (this.waiter) {
      const w = this.waiter;
      this.waiter = null;
      w(event);
    } else {
      this.queue.push(event);
    }
    return json(200, await answer);
  }

  async nextEvent() {
    const event = this.queue.length
      ? this.queue.shift()
      : await new Promise((resolve) => {
          // A newer poll (e.g. after the app restarted) replaces the old one.
          if (this.waiter) this.waiter(null);
          const timer = setTimeout(() => {
            if (this.waiter === wrapped) this.waiter = null;
            resolve(null);
          }, LONG_POLL_MS);
          const wrapped = (e) => {
            clearTimeout(timer);
            resolve(e);
          };
          this.waiter = wrapped;
        });
    return event ? json(200, event) : new Response(null, { status: 204 });
  }
}
