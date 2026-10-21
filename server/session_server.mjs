// Local PoC backend: mints a short-lived Bolna web-call session.
// Docs: https://www.bolna.ai/docs/developer-resources/sdks/web-call ("Set up your backend")
//
// TEMPORARY / LOCAL ONLY — see README.md "Security limitations". Not a production API.
//
//   cp server/.env.example server/.env    # fill in real values; .env is gitignored
//   node server/session_server.mjs
//   adb reverse tcp:8787 tcp:8787         # phone's localhost:8787 → this PC over USB
import http from "node:http";
import { timingSafeEqual } from "node:crypto";
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
  HOST = "127.0.0.1", // loopback only: reachable from the phone via `adb reverse`, not the LAN
  PORT = "8787",
} = process.env;

const missing = Object.entries({ BOLNA_API_KEY, BOLNA_AGENT_ID, DEV_SESSION_TOKEN })
  .filter(([, v]) => !v || v.startsWith("replace-with"))
  .map(([k]) => k);
if (missing.length) {
  console.error(`Not configured: set ${missing.join(", ")} in ${envPath} (see .env.example).`);
  process.exit(1);
}
if (DEV_SESSION_TOKEN.length < 16) {
  console.error("DEV_SESSION_TOKEN must be at least 16 characters.");
  process.exit(1);
}

const BOLNA_MINT_URL = "https://api.bolna.ai/web-call/session";
const LANGUAGES = new Set(["en", "mr"]);
// Context the app may pass to the agent prompt as {{variables}}. Informational only:
// the app's workflow engine, not the agent, decides the current step.
const USER_DATA_KEYS = ["saathi_task", "saathi_step", "saathi_instruction"];
const MAX_MINTS_PER_MINUTE = 10; // each mint can hold a concurrent-call slot on the account
let recentMints = [];

const send = (res, status, body) =>
  res
    .writeHead(status, { "Content-Type": "application/json", "Cache-Control": "no-store" })
    .end(typeof body === "string" ? body : JSON.stringify(body));

function tokenOk(given) {
  const a = Buffer.from(given ?? "");
  const b = Buffer.from(DEV_SESSION_TOKEN);
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

http
  .createServer(async (req, res) => {
    if (req.method !== "POST" || req.url !== "/session") return send(res, 404, { error: "not found" });
    if (!tokenOk(req.headers["x-dev-token"])) return send(res, 401, { error: "bad or missing X-Dev-Token" });

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
  })
  .listen(Number(PORT), HOST, () => console.log(`session endpoint: http://${HOST}:${PORT}/session`));
