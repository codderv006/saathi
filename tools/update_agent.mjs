// Adds the `saathi_guide` custom function and its instructions to the Bolna agent, so
// the app screen follows the conversation. Only ADDS (or replaces its own marked
// block); everything else in the agent is sent back unchanged.
//
//   node tools/update_agent.mjs https://<tunnel>.trycloudflare.com          # dry run
//   node tools/update_agent.mjs https://<tunnel>.trycloudflare.com --apply  # update
//
// A full backup of the live agent is written to server/agent_backups/ first.
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

process.loadEnvFile(fileURLToPath(new URL("../server/.env", import.meta.url)));
const { BOLNA_API_KEY, BOLNA_AGENT_ID, TOOL_TOKEN } = process.env;
const [, , tunnelArg, flag] = process.argv;
const apply = flag === "--apply";
if (!tunnelArg?.startsWith("https://")) {
  console.error("Usage: node tools/update_agent.mjs https://<public-tool-host> [--apply]");
  process.exit(1);
}
const toolUrl = `${tunnelArg.replace(/\/$/, "")}/tool`;
const api = `https://api.bolna.ai/v2/agent/${BOLNA_AGENT_ID}`;
const headers = { Authorization: `Bearer ${BOLNA_API_KEY}`, "Content-Type": "application/json" };

const START = "[SAATHI SCREEN GUIDE]";
const END = "[/SAATHI SCREEN GUIDE]";
const MIN_CALL_SECONDS = 900;
const WELCOME =
  "Namaskar! I'm Saathi. I can help you use Ola, Uber, Rapido, Google Pay, PhonePe and WhatsApp. What do you need?";

// Topic list for the prompt, generated from the app's own catalog.
const catalog = JSON.parse(
  readFileSync(fileURLToPath(new URL("../assets/guides/catalog.json", import.meta.url)), "utf8"),
);
const groups = new Map();
for (const t of catalog.topics) {
  const key = t.apps.join(", ");
  if (!groups.has(key)) groups.set(key, []);
  groups.get(key).push(`${t.id} (${t.title.en}${t.about ? ": " + t.about : ""})`);
}
const topicList = [...groups]
  .map(([apps, list]) => `- ${apps}: ${list.join("; ")}`)
  .join("\n");
const appIds = Object.keys(catalog.apps);
const topicIds = [...new Set(catalog.topics.map((t) => t.id))];

const rules = [
  `You are Saathi, a patient, warm voice helper for people who are not confident with phones, often older parents. You ONLY help with these six apps: Ola, Uber and Rapido (rides), Google Pay and PhonePe (UPI payments), and WhatsApp (messages). Answer any question about using them: simply, in the user's language, one step at a time, waiting for them to act.
If a question is about anything else (other apps, general knowledge, news, health, money advice, maths, jokes, and so on), politely say you can only help with these six apps, and give an example of what you can do. Do not answer it.

The user sees the Saathi app on their phone. It shows a picture for each step. Keep it in step with the conversation by calling `,
  { tool: true },
  ". Always pass saathi_device = ",
  { variable: "saathi_device" },
  `.
- When a question matches a topic below, call action "show_topic" with app and topic, then explain only the current step from the answer. For book_ride also pass new_user ("yes" if they are new to the app; ask if you don't know).
- Every answer tells you step_id, step_title and instruction. Explain that step briefly, then wait.
- When the user says they finished the step ("done", "ho", "zala", "kela"), call "step_done" with that step_id, then explain the next step from the answer. The screen moves by itself.
- If they want to go back, call "go_back" with the current step_id. If unsure where they are, call "current_step". If an answer has ok false, follow its message and its step.
- If is_final_question is true, ask what the app shows and call "outcome" with booked "yes" or "no", only from what the user says.
- If the conversation moves to something with no topic, call "close_topic" and answer by voice.
- Never ask for, repeat or listen to OTPs, UPI PINs, card numbers, CVV or passwords. If the user starts to read one out, stop them kindly.
- Never say you can see their screen, or that you tapped, typed, paid or booked anything.

Topics (app ids: topic id (title: about)):
${topicList}`,
];

const toolDef = {
  key: "custom_task",
  name: "saathi_guide",
  description:
    "Controls the guide on the user's Saathi screen: open a topic (show_topic), the user finished the current step (step_done), go back (go_back), ride booked or not (outcome), clear the screen (close_topic), or get the current step (current_step).",
  pre_call_message: "",
  parameters: {
    type: "object",
    properties: {
      saathi_device: { type: "string", description: "Device id given in the prompt." },
      action: {
        type: "string",
        enum: ["show_topic", "step_done", "go_back", "outcome", "close_topic", "current_step"],
        description: "What happened in the conversation.",
      },
      app: { type: "string", enum: appIds, description: "App id, for show_topic." },
      topic: { type: "string", enum: topicIds, description: "Topic id, for show_topic." },
      new_user: { type: "string", enum: ["yes", "no"], description: "For book_ride." },
      step_id: { type: "string", description: "The current step_id from the last answer." },
      booked: { type: "string", enum: ["yes", "no"], description: "For outcome." },
    },
    required: ["saathi_device", "action"],
  },
};

const toolParams = {
  method: "POST",
  url: toolUrl,
  api_token: `Bearer ${TOOL_TOKEN}`,
  headers: {},
  param: Object.fromEntries(
    Object.keys(toolDef.parameters.properties).map((k) => [k, `%(${k})s`]),
  ),
};

function stripBlock(text) {
  const a = text.indexOf(START);
  const b = text.indexOf(END);
  return a >= 0 && b > a ? (text.slice(0, a) + text.slice(b + END.length)).trimEnd() : text;
}

function plainRules() {
  return rules
    .map((r) => (typeof r === "string" ? r : r.tool ? "saathi_guide" : `{${r.variable}}`))
    .join("");
}

function compositionNodes() {
  return [
    { type: "text", text: `\n\n${START}\n` },
    ...rules.map((r) =>
      typeof r === "string"
        ? { type: "text", text: r }
        : r.tool
          ? { type: "function_tool", name: "saathi_guide" }
          : { type: "variable", scope: "execution", name: r.variable },
    ),
    { type: "text", text: `\n${END}` },
  ];
}

/** Removes our previously added nodes (between the START and END text nodes). */
function stripNodes(nodes) {
  const out = [];
  let inside = false;
  for (const n of nodes) {
    const t = n.type === "text" ? n.text : "";
    if (!inside && t.includes(START)) {
      const before = t.slice(0, t.indexOf(START)).trimEnd();
      if (before) out.push({ ...n, text: before });
      inside = !t.includes(END);
      continue;
    }
    if (inside) {
      if (t.includes(END)) inside = false;
      continue;
    }
    out.push(n);
  }
  return out;
}

const current = await (await fetch(api, { headers })).json();
mkdirSync(fileURLToPath(new URL("../server/agent_backups/", import.meta.url)), { recursive: true });
const backup = fileURLToPath(
  new URL(`../server/agent_backups/${new Date().toISOString().replace(/[:.]/g, "-")}.json`, import.meta.url),
);
writeFileSync(backup, JSON.stringify(current, null, 2));

const tasks = structuredClone(current.tasks);
const task = tasks[0];
const apiTools = task.tools_config.api_tools ?? { tools: [], tools_params: {} };
apiTools.tools = [...(apiTools.tools ?? []).filter((t) => t.name !== "saathi_guide"), toolDef];
apiTools.tools_params = { ...(apiTools.tools_params ?? {}), saathi_guide: toolParams };
task.tools_config.api_tools = apiTools;
const oldTerminate = task.task_config?.call_terminate;
if (task.task_config && (oldTerminate ?? 0) < MIN_CALL_SECONDS) {
  task.task_config.call_terminate = MIN_CALL_SECONDS;
}

const agentConfig = {};
if (current.agent_welcome_message !== WELCOME) {
  console.log(`welcome:          "${current.agent_welcome_message}" -> "${WELCOME}"`);
}
for (const key of [
  "agent_name",
  "agent_welcome_message",
  "agent_type",
  "webhook_url",
  "calling_guardrails",
  "ingest_source_config",
  "call_summary_enabled",
]) {
  if (current[key] !== undefined && current[key] !== null) agentConfig[key] = current[key];
}
agentConfig.tasks = tasks;
agentConfig.agent_welcome_message = WELCOME;

const prompts = structuredClone(current.agent_prompts ?? { task_1: { system_prompt: "" } });
prompts.task_1.system_prompt = `${stripBlock(prompts.task_1.system_prompt ?? "")}\n\n${START}\n${plainRules()}\n${END}`;

const body = { agent_config: agentConfig, agent_prompts: prompts };
if (current.composition_by_language) {
  body.composition_by_language = Object.fromEntries(
    Object.entries(current.composition_by_language).map(([lang, nodes]) => [
      lang,
      [...stripNodes(nodes), ...compositionNodes()],
    ]),
  );
}

console.log(`backup:           ${backup}`);
console.log(`agent:            ${current.agent_name}`);
console.log(`tool url:         ${toolUrl}`);
console.log(`tools:            ${apiTools.tools.map((t) => t.name).join(", ")}`);
console.log(`call_terminate:   ${oldTerminate} -> ${task.task_config?.call_terminate}`);
console.log(`prompt languages: ${Object.keys(body.composition_by_language ?? { plain: 1 }).join(", ")}`);
if (!apply) {
  console.log("\nDry run. Re-run with --apply to update the agent.");
  process.exit(0);
}
const r = await fetch(api, { method: "PUT", headers, body: JSON.stringify(body) });
const text = await r.text();
console.log(`PUT -> HTTP ${r.status} ${text.slice(0, 500)}`);
process.exit(r.ok ? 0 : 1);
