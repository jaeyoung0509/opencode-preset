# opencode-preset

A tiny, model-agnostic workflow preset for OpenCode.

It keeps the default OpenCode harness intact and adds only a handful of high-value workflows:

- `/btw <question>` — run a side question in an ephemeral background session while the main task keeps going
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

`/btw` uses the active session's model when OpenCode exposes it to the plugin. You can explicitly choose a model for side questions with:

```bash
export OPENCODE_BTW_MODEL="provider/model"
```

## Design

This preset borrows a few durable ideas from strong coding-agent harnesses while staying intentionally small:

1. **Native primitives first.** Commands, skills, Markdown agents, permissions, and the official plugin directories follow OpenCode's extension model.
2. **Plugins only when behavior really needs hooks or state.** `/goal` uses a dedicated persistent goal plugin. `/btw` is a tiny local plugin because true non-blocking side questions need an ephemeral session and a command hook.
3. **Fresh context for independent work.** Planning, review, and side questions use separate sessions instead of bloating the primary conversation.
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
│   ├── preset-planner.md
│   └── preset-reviewer.md
├── plugins/
│   └── btw.ts
└── skills/
    └── grill-me/
        └── SKILL.md
```

`/goal` is installed through OpenCode's plugin CLI using `@prevalentware/opencode-goal-plugin` rather than vendoring the plugin.

Existing files with the same names are backed up before replacement.

## Why each feature has a different shape

| Feature | OpenCode primitive | Reason |
| --- | --- | --- |
| `/plan` | command + read-only subagent | planning benefits from fresh context and should not mutate code |
| `/review` | command + read-only subagent | independent verification should not self-edit the implementation |
| `/grill-me` | command + skill | the command is explicit UX; the detailed interview method is reusable on demand |
| `/btw` | command + local plugin | background ephemeral sessions require lifecycle hooks |
| `/goal` | published plugin | durable state, compaction survival, evidence-gated completion, and idle continuation are stateful concerns |

## Project instructions

Keep repository-specific conventions, architecture constraints, build commands, and domain rules in that project's `AGENTS.md`. This preset should stay generic and reusable.

## Updating

Run the installer again:

```bash
curl -fsSL https://raw.githubusercontent.com/jaeyoung0509/opencode-preset/main/install.sh | bash
```

## Uninstall

From a clone:

```bash
bash uninstall.sh
```

The uninstaller only moves the preset's known global files into a timestamped backup directory. It leaves unrelated OpenCode configuration untouched. The goal plugin is managed by OpenCode itself, so the script does not silently remove it.

## Notes

- No API keys, auth files, provider settings, or model settings belong in this repository.
- Commands, agents, skills, and plugin prompts are English internally, but user prompts and command arguments can be written in any language.
- `/btw` intentionally keeps its answer concise and does not allow the temporary session to edit project files.

## License

MIT
