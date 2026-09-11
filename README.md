# opencode-preset

A tiny, model-agnostic workflow preset for OpenCode.

It keeps the default OpenCode harness intact and adds only a handful of high-value workflows:

- `/btw <question>` — dispatch a side question to a native background subagent while the main task keeps going
- `/goal <objective>` — keep a durable objective active until it is verified complete, blocked, paused, or cleared
- `/grill-me [topic]` — interview the user one focused question at a time before implementation
- `/review [scope]` — run an independent, read-only review in a fresh subagent
- `/plan [task]` — build an implementation plan in an isolated, read-only planning subagent

The preset deliberately avoids replacing OpenCode's orchestrator or hard-coding a model.

## Install

### One command

```bash
curl -fsSL https://raw.githubusercontent.com/jaeyoung0509/opencode-preset/main/install.sh | bash
```

### From a clone

```bash
git clone https://github.com/jaeyoung0509/opencode-preset.git
cd opencode-preset
bash install.sh
```

The installer enables OpenCode's native background-subagent feature in your shell rc file. Open a new terminal, then restart OpenCode.

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

1. **Native primitives first.** Commands, skills, Markdown agents, permissions, and OpenCode's own task/subagent machinery are preferred over custom orchestration.
2. **Plugins only when behavior really needs durable state.** `/goal` uses a dedicated persistent goal plugin. `/btw` uses the native background task path instead of maintaining a custom session plugin.
3. **Fresh context for independent work.** Planning, review, and side questions use separate subagents instead of bloating the primary conversation.
4. **Separate planning from execution.** The planner cannot edit files and must produce concrete acceptance criteria and verification steps.
5. **Independent verification.** The reviewer cannot edit files, reports findings before summaries, and treats repository evidence and observed behavior as stronger than implementation intent.
6. **Progressive disclosure.** Detailed interview behavior lives in a skill and is loaded only when relevant.
7. **Model agnostic by default.** Commands do not pin a provider or model, so the preset works with OpenCode Go, DeepSeek, Anthropic, OpenAI, and other configured providers.
8. **Verification should be proportional.** Plans and reviews ask for the smallest meaningful checks rather than creating test work mechanically.

This is closer to Pi's "small core, composable extensions" philosophy and Codex-style evidence/verification discipline than to a full replacement orchestration layer. It also takes the useful fresh-context specialist pattern seen in richer OpenCode and Pi setups without installing their entire harness.

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

The installer also adds:

```bash
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
```

to your shell rc file inside a clearly marked block.

`preset-btw` is intentionally read-only and cannot edit files or launch nested subagents. `/goal` is installed through OpenCode's plugin CLI using `@prevalentware/opencode-goal-plugin` rather than vendoring the plugin.

Existing files with the same names are backed up before replacement.

## Why each feature has a different shape

| Feature | OpenCode primitive | Reason |
| --- | --- | --- |
| `/plan` | command + read-only subagent | planning benefits from fresh context and should not mutate code |
| `/review` | command + read-only subagent | independent verification should not self-edit the implementation |
| `/grill-me` | command + skill | the command is explicit UX; the detailed interview method is reusable on demand |
| `/btw` | command + native background task + read-only subagent | side questions should run concurrently without blocking or mutating the project |
| `/goal` | published plugin | durable state, compaction survival, evidence-gated completion, and idle continuation are stateful concerns |

## `/btw` behavior

`/btw` asks the active agent to invoke OpenCode's `task` tool with:

```text
subagent_type: preset-btw
background: true
```

The main session does not wait for the result. OpenCode injects the completed subagent result when it finishes.

If `/btw` reports that background subagents are unavailable, start OpenCode after exporting:

```bash
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
```

The installer does this for future shells automatically.

## Project instructions

Keep repository-specific conventions, architecture constraints, build commands, and domain rules in that project's `AGENTS.md`. This preset should stay generic and reusable.

## Updating

Run the installer again:

```bash
curl -fsSL https://raw.githubusercontent.com/jaeyoung0509/opencode-preset/main/install.sh | bash
```

Then open a new terminal and restart OpenCode.

## Uninstall

From a clone:

```bash
bash uninstall.sh
```

The uninstaller only moves the preset's known global files into a timestamped backup directory and removes the environment-variable block added by the installer. It leaves unrelated OpenCode configuration untouched. The goal plugin is managed by OpenCode itself, so the script does not silently remove it.

## Notes

- No API keys, auth files, provider settings, or model settings belong in this repository.
- Commands, agents, skills, and prompts are English internally, but user prompts and command arguments can be written in any language.
- `/btw` is deliberately read-only and uses OpenCode's native background subagent path.

## License

MIT
