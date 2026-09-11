# opencode-preset

A tiny, model-agnostic workflow preset for OpenCode V2.

It keeps the default OpenCode harness intact and adds only a handful of high-value workflows:

- `/btw <question>` — run a side question in a native background child session while the main task keeps going
- `/goal <objective>` — keep a durable objective active until it is verified complete, blocked, paused, or cleared
- `/grill-me [topic]` — interview the user one focused question at a time before implementation
- `/review [scope]` — run an independent, read-only review in a fresh background subagent
- `/plan [task]` — build an implementation plan in an isolated, read-only background subagent

The preset deliberately avoids replacing OpenCode's orchestrator or hard-coding a model.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/jaeyoung0509/opencode-preset/main/install.sh | bash
```

Or:

```bash
git clone https://github.com/jaeyoung0509/opencode-preset.git
cd opencode-preset
bash install.sh
```

Restart OpenCode after installation.

## Usage

```text
/btw why is this mutex necessary?
/goal fix the flaky queue tests and verify the full test suite
/grill-me design a billing retry workflow
/review
/review src/auth
/plan migrate this package from REST to gRPC
```

## Design

This preset borrows a few durable ideas from strong coding-agent harnesses while staying intentionally small:

1. **Native primitives first.** Commands, skills, Markdown agents, permissions, and OpenCode's own background command delegation are preferred over custom orchestration.
2. **Plugins only when durable state is required.** `/goal` uses a dedicated persistent goal plugin. `/btw`, `/plan`, and `/review` use native command-level background subagents.
3. **Fresh context for independent work.** Planning, review, and side questions use separate child sessions instead of bloating the primary conversation.
4. **Separate planning from execution.** The planner cannot edit files and must produce concrete acceptance criteria and verification steps.
5. **Independent verification.** The reviewer cannot edit files, reports findings before summaries, and treats repository evidence and observed behavior as stronger than implementation intent.
6. **Progressive disclosure.** Detailed interview behavior lives in a skill and is loaded only when relevant.
7. **Model agnostic by default.** Commands do not pin a provider or model.
8. **Verification should be proportional.** Plans and reviews ask for the smallest meaningful checks rather than creating test work mechanically.

This is closer to Pi's small-core, composable-extension philosophy and Codex-style evidence/verification discipline than to a full replacement orchestration layer.

## What gets installed

```text
~/.config/opencode/
├── commands/
│   ├── btw.md
│   ├── grill-me.md
│   ├── plan.md
│   └── review.md
├── agents/
│   ├── preset-btw.md
│   ├── preset-planner.md
│   └── preset-reviewer.md
└── skills/
    └── grill-me/
        └── SKILL.md
```

All custom agents use OpenCode V2 permissions. The side-question agent is read-only and cannot edit files, execute shell commands, ask interactive questions, or launch nested subagents.

`/goal` is installed through OpenCode's plugin CLI using `@prevalentware/opencode-goal-plugin` rather than vendoring the plugin.

Existing files with the same names are backed up before replacement.

## Native background delegation

OpenCode V2 commands support background delegation directly in command frontmatter:

```yaml
---
agent: preset-btw
subagent: true
---
```

That means `/btw` does **not** ask the main model to call a task tool. OpenCode itself creates a background child session, leaves the parent session available, and reports the child result when it completes.

No experimental environment variable is required for this command path.

## Why each feature has a different shape

| Feature | OpenCode primitive | Reason |
| --- | --- | --- |
| `/plan` | command + `subagent: true` + read-only agent | planning benefits from fresh context and should not mutate code |
| `/review` | command + `subagent: true` + read-only agent | independent verification should not self-edit the implementation |
| `/grill-me` | command + skill | the command is explicit UX; the detailed interview method is reusable on demand |
| `/btw` | command + `subagent: true` + read-only agent | side questions should run concurrently without mutating the project |
| `/goal` | published plugin | durable state, compaction survival, evidence-gated completion, and idle continuation are stateful concerns |

## Project instructions

Keep repository-specific conventions, architecture constraints, build commands, and domain rules in that project's `AGENTS.md`. This preset should stay generic and reusable.

## Updating

```bash
curl -fsSL https://raw.githubusercontent.com/jaeyoung0509/opencode-preset/main/install.sh | bash
```

Then restart OpenCode.

## Uninstall

```bash
bash uninstall.sh
```

The uninstaller only moves the preset's known global files into a timestamped backup directory. It leaves unrelated OpenCode configuration untouched. The goal plugin is managed by OpenCode itself, so the script does not silently remove it.

## Notes

- No API keys, auth files, provider settings, or model settings belong in this repository.
- Commands, agents, skills, and prompts are English internally, but user prompts and command arguments can be written in any language.
- The preset targets OpenCode V2 conventions.

## License

MIT
