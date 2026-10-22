// Local PoC backend.
//
//  :8787 (USB only, via `adb reverse`)  — for the app
//     POST /session          mint a short-lived Bolna web-call session
//     GET  /events           long-poll: next guide action the agent requested
//     POST /events/result    app's answer to that action
//  :8788 (public only through the tunnel) — for Bolna's custom function
//     POST /tool             agent asks the app to move the guide; waits for the app
//
// The agent can only *request* guide actions. The app validates them with its workflow
// engine (current step only, no skipping) and answers; the answer is what the agent
// speaks next. TEMPORARY / LOCAL ONLY — see README.md "Security limitations".
//
//   node server/session_server.mjs
//   adb reverse tcp:8787 tcp:8787
//   cloudflared tunnel --url http://127.0.0.1:8788      (see dev.ps1)
import http from "node:http";
import { randomUUID, timingSafeEqual } from "node:crypto";
import { fileURLToPath } from "node:url";

const envPath = fileURLToPath(new URL(".env", import.meta.url));
try {
  process.loadEnvFile(envPath); // Node >= 20.12; no dotenv dependency
} catch {
  // fall through to the check below
}

const {
  BOLNA_API_KEY,
  BOLNA_AGENT_ID,
  DEV_SESSION_TOKEN,
  TOOL_TOKEN,
  HOST = "127.0.0.1", // loopback only
  PORT = "8787",
  TOOL_PORT = "8788",
} = process.env;

const missing = Object.entries({ BOLNA_API_KEY, BOLNA_AGENT_ID, DEV_SESSION_TOKEN, TOOL_TOKEN })
  .filter(([, v]) => !v || v.startsWith("replace-with"))
  .map(([k]) => k);
if (missing.length) {
  console.error(`Not configured: set ${missing.join(", ")} in ${envPath} (see .env.example).`);
  process.exit(1);
}
if (DEV_SESSION_TOKEN.length < 16 || TOOL_TOKEN.length < 16) {
  console.error("DEV_SESSION_TOKEN and TOOL_TOKEN must be at least 16 characters.");
  process.exit(1);
}

const BOLNA_MINT_URL = "https://api.bolna.ai/web-call/session";
const LANGUAGES = new Set(["en", "mr"]);
// Context the app may pass to the agent prompt as {{variables}}. Informational only:
// the app's workflow engine, not the agent, decides the current step.
const USER_DATA_KEYS = ["saathi_device", "saathi_task", "saathi_step", "saathi_instruction"];
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
let recentMints = [];

const send = (res, status, body) =>
  res
    .writeHead(status, { "Content-Type": "application/json", "Cache-Control": "no-store" })
    .end(typeof body === "string" ? body : JSON.stringify(body));

function same(given, expected) {
  const a = Buffer.from(given ?? "");
  const b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);
}

async function readJson(req) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > 8192) throw new Error("body too large");
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString() || "{}");
}

// ---------------------------------------------------------------- guide event relay

/** device id -> { queue: event[], waiter: fn|null } */
const devices = new Map();
/** event id -> resolve(result) for the waiting /tool request */
const pendingAnswers = new Map();

function deviceState(id) {
  if (!devices.has(id)) devices.set(id, { queue: [], waiter: null });
  return devices.get(id);
}

function deliver(deviceId, event) {
  const state = deviceState(deviceId);
  if (state.waiter) {
    const w = state.waiter;
    state.waiter = null;
    w(event);
  } else {
    state.queue.push(event);
  }
}

function nextEvent(deviceId) {
  const state = deviceState(deviceId);
  if (state.queue.length) return Promise.resolve(state.queue.shift());
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      if (state.waiter === wrapped) state.waiter = null;
      resolve(null);
    }, LONG_POLL_MS);
    const wrapped = (e) => {
      clearTimeout(timer);
      resolve(e);
    };
    state.waiter = wrapped;
  });
}

/** Bolna custom function: forwards to the app and returns the app's answer. */
async function handleTool(req, res) {
  if (!same(req.headers.authorization, `Bearer ${TOOL_TOKEN}`)) {
    return send(res, 401, { error: "unauthorized" });
  }
  let body = {};
  try {
    body = await readJson(req);
  } catch {}
  const url = new URL(req.url, "http://x");
  const input = { ...Object.fromEntries(url.searchParams), ...body };
  const device = typeof input.saathi_device === "string" ? input.saathi_device : "";
  const action = input.action;
  if (!device || !TOOL_ACTIONS.has(action)) {
    return send(res, 200, { ok: false, message: "Unknown device or action." });
  }
  const event = {
    id: randomUUID(),
    action,
    app: typeof input.app === "string" ? input.app.toLowerCase() : null,
    topic: typeof input.topic === "string" ? input.topic.toLowerCase() : null,
    new_user: input.new_user === true || input.new_user === "yes" || input.new_user === "true",
    step_id: typeof input.step_id === "string" ? input.step_id : null,
    booked: input.booked === true || input.booked === "yes" || input.booked === "true",
  };
  const answer = new Promise((resolve) => {
    pendingAnswers.set(event.id, resolve);
    setTimeout(() => {
      if (pendingAnswers.delete(event.id)) {
        // Never let a stale action apply later (e.g. after the app restarts).
        const state = deviceState(device);
        state.queue = state.queue.filter((e) => e.id !== event.id);
        resolve({ ok: false, message: "The Saathi screen did not respond. Keep guiding by voice." });
      }
    }, APP_ANSWER_TIMEOUT_MS);
  });
  deliver(device, event);
  const result = await answer;
  console.log(new Date().toISOString(), "tool", { action, step: event.step_id, ok: result.ok });
  send(res, 200, result);
}

// ---------------------------------------------------------------- app-facing server

async function handleApp(req, res) {
  if (!same(req.headers["x-dev-token"], DEV_SESSION_TOKEN)) {
    return send(res, 401, { error: "bad or missing X-Dev-Token" });
  }
  const url = new URL(req.url, "http://x");

  if (req.method === "GET" && url.pathname === "/events") {
    const device = url.searchParams.get("device") ?? "";
    if (!device) return send(res, 400, { error: "device required" });
    const event = await nextEvent(device);
    return event ? send(res, 200, event) : res.writeHead(204).end();
  }

  if (req.method === "POST" && url.pathname === "/events/result") {
    let input;
    try {
      input = await readJson(req);
    } catch (e) {
      return send(res, 400, { error: e.message });
    }
    const resolve = pendingAnswers.get(input.id);
    if (resolve) {
      pendingAnswers.delete(input.id);
      resolve(input.result ?? { ok: false });
    }
    return send(res, 200, { ok: true });
  }

  if (req.method === "POST" && url.pathname === "/session") return handleMint(req, res);
  return send(res, 404, { error: "not found" });
}

async function handleMint(req, res) {
  const now = Date.now();
  recentMints = recentMints.filter((t) => now - t < 60_000);
  if (recentMints.length >= MAX_MINTS_PER_MINUTE) return send(res, 429, { error: "local rate limit" });

  let input;
  try {
    input = await readJson(req);
  } catch (e) {
    return send(res, 400, { error: `invalid body: ${e.message}` });
  }

  // Only agent_id, an optional language and whitelisted context reach Bolna.
  const mintBody = { agent_id: BOLNA_AGENT_ID };
  const userData = {};
  for (const key of USER_DATA_KEYS) {
    const value = input.user_data?.[key];
    if (typeof value === "string" && value.length <= 400) userData[key] = value;
  }
  if (Object.keys(userData).length) mintBody.user_data = userData;
  if (input.language !== undefined && input.language !== null) {
    if (!LANGUAGES.has(input.language)) return send(res, 400, { error: "language must be en or mr" });
    // Bolna returns 400 if the agent isn't multilingual or lacks this language.
    mintBody.agent_data = { language: input.language };
  }

  recentMints.push(now);
  try {
    const r = await fetch(BOLNA_MINT_URL, {
      method: "POST",
      headers: { Authorization: `Bearer ${BOLNA_API_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify(mintBody),
    });
    const text = await r.text();
    // The response carries one-time SIP/TURN credentials: log only non-secret fields.
    let runId = null;
    try {
      runId = JSON.parse(text).run_id ?? null;
    } catch {}
    console.log(new Date().toISOString(), "mint", {
      status: r.status,
      language: mintBody.agent_data?.language ?? "(agent default)",
      runId,
      ...(r.ok ? {} : { error: text.slice(0, 300) }),
    });
    send(res, r.status, text); // returned unchanged, as the docs prescribe
  } catch (e) {
    console.error("mint request failed:", e.message);
    send(res, 502, { error: "could not reach Bolna" });
  }
}

http
  .createServer(handleApp)
  .listen(Number(PORT), HOST, () => console.log(`app endpoint:  http://${HOST}:${PORT}`));

http
  .createServer((req, res) =>
    req.method === "POST" && new URL(req.url, "http://x").pathname === "/tool"
      ? handleTool(req, res)
      : send(res, 404, { error: "not found" }),
  )
  .listen(Number(TOOL_PORT), HOST, () => console.log(`tool endpoint: http://${HOST}:${TOOL_PORT}/tool`));
