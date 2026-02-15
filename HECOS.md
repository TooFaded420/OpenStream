# HECOS Project: Local Model Setup for OpenClaw

## Purpose
Capture the steps and knowledge needed for anyone (including other AI helpers) to run a local Ollama model inside OpenClaw, keep tooling lean, and teach users how to recover when a model lacks tool support.

## Current status
- Primary agent: `ollama/qwen2.5:32b-instruct` (tool-friendly, streaming enabled)
- Reasoning specialist agent: `ollama/deepseek-r1:32b` running under the `deepseek` agent so Qwen (main agent) can spawn it when heavy reasoning is needed
- Fallback: `ollama/qwen2.5:7b-instruct` for parity and faster recovery
- Removed 70B variants (too heavy) to keep the setup efficient

## Key steps
1. **Install + download** – use `ollama pull` or `ollama run` to fetch each model while DNS is reachable. Keep `qwen2.5:32b` and `deepseek-r1:32b` locally cached.
2. **Config edits** – update `openclaw.json` so the defaults/fallbacks mirror the above, add readable aliases, and ensure the Ollama provider list includes both 32B entries with accurate context windows.
3. **Restart gateway** – cycle `openclaw gateway stop`/`start` after config edits so Telegram/redirections pick up the latest catalog and tool permissions.
4. **Tool governance** – because DeepSeek 32B returns `Ollama API error 400: ... does not support tools`, only spawn it for tasks that do **not** rely on tools. Let OpenClaw default to `qwen2.5:32b-instruct` for most Telegram/tasks requiring tools, and treat DeepSeek as a firing-only reasoning specialist (no tool requests, no web search, etc.).

## Tooling policy (lean + resilient)
- Keep `tools` available for the main session (`naj` model) only.
- Disable/restrict them when triggering DeepSeek runs (per spawn call, specify `tools: []` or rely on the natural limitation so the request never includes tool calls).
- Leave `qwen2.5:7b` available as a fast fallback when the 32B models need a cold-start break.

## DeepSeek partnership
- `main` (Qwen 32B) is now part of a multi-agent setup; when you need DeepSeek you spawn the `deepseek` agent or use the `sessions_spawn` tool targeting `agentId: "deepseek"`.
- DeepSeek runs with tools disabled (`tools.allow = []`) so it never tries to call unsupported APIs.
- After a DeepSeek run finishes, ask the main agent or spawn another short session to turn that answer into actionable steps or tool calls if needed.

## Memory / Self files
- The workspace already uses `memory/`, `SOUL.md`, `TOOLS.md`, etc., per architect instructions.
- Keep this HECOS entry up to date whenever the model catalog or project plan changes so other agents (and future documentation) have a clear reference.
