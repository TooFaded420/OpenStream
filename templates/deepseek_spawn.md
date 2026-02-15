# DeepSeek Spawn Template

Use this template to trigger the `deepseek` agent for long-form reasoning without invoking tools. Replace the placeholder task description with the actual problem.

```
/sessions_spawn
agentId: deepseek
label: deep-reasoning
thinking: medium
runTimeoutSeconds: 1800
task: |
  Deep-dive research / strategy work:
  - Describe what you need DeepSeek to analyze (data, context, constraints)
  - Explain what "success" looks like for this run
  - Ask for the desired output format (structured list, summary, critique, etc.)
```

After the DeepSeek run completes, ask the default agent (`main` / `qwen2.5:32b-instruct`) to convert the reasoning output into action items or tool calls, e.g.:

> “Qwen, take DeepSeek’s reasoning summary and build a checklist for implementation.”
