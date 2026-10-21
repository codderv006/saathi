// Adds the `saathi_guide` custom function and its instructions to the Bolna agent, so
// the app screen follows the conversation. Only ADDS (or replaces its own marked
// block); everything else in the agent is sent back unchanged.
//
//   node tools/update_agent.mjs https://<tunnel>.trycloudflare.com          # dry run
//   node tools/update_agent.mjs https://<tunnel>.trycloudflare.com --apply  # update
//
// A full backup of the live agent is written to server/agent_backups/ first.
import { mkdirSync, writeFileSync } from "node:fs";
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

const rules = [
  "The user sees the Saathi app on their phone while talking to you. It shows one step at a time with a picture of the ride app. Keep the screen in step with the conversation by calling ",
  { tool: true },
  ". Always pass saathi_device = ",
  { variable: "saathi_device" },
  `.
- At the start, ask which ride app they use (Ola, Uber or Rapido) and whether they already use it or are new to it. Then call saathi_guide with action "start_guide", app ("ola", "uber" or "rapido") and new_user ("yes" if they are new, otherwise "no").
- Every answer from the tool tells you the current step: step_id, step_title and instruction. Explain only that step, briefly and simply, in the user's language. Then wait.
- When the user says they finished the step (for example "done", "ho", "zala", "kela"), call saathi_guide with action "step_done" and that step_id. Then explain the next step from the answer. The screen moves on by itself.
- If they want to go back, call action "go_back" with the current step_id.
- When the answer has is_final_question true, ask what the app shows. Call action "outcome" with booked "yes" or "no" based only on what the user says.
- If you are not sure which step they are on, call action "current_step".
- If the answer has ok false, follow its message and its step.
- Never skip steps. Never ask for, repeat or listen to OTPs, PINs or passwords.`,
];

const toolDef = {
  key: "custom_task",
  name: "saathi_guide",
  description:
    "Moves the guide on the user's Saathi screen. Call it when the user names their ride app (start_guide), says they finished the current step (step_done), wants to go back (go_back), reports whether the ride was booked (outcome), or when you need the current step (current_step).",
  pre_call_message: "",
  parameters: {
    type: "object",
    properties: {
      saathi_device: { type: "string", description: "Device id given in the prompt." },
      action: {
        type: "string",
        enum: ["start_guide", "step_done", "go_back", "outcome", "current_step"],
        description: "What happened in the conversation.",
      },
      app: { type: "string", enum: ["ola", "uber", "rapido"], description: "For start_guide." },
      new_user: { type: "string", enum: ["yes", "no"], description: "For start_guide." },
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
