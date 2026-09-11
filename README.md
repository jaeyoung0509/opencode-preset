# opencode-preset

A tiny, model-agnostic workflow preset for OpenCode.

It keeps the default OpenCode harness intact and adds only a handful of high-value workflows:

- `/btw <question>` — run a side question in a background child session while the main session stays available
- `/goal <objective>` — keep a durable objective active until it is verified complete, blocked, paused, or cleared
- `/grill-me [topic]` — interview the user one focused question at a time before implementation
- `/review [scope]` — run an independent, read-only review in a background subagent
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
./install.sh
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

This preset follows a few principles used by strong coding-agent harnesses:

1. **Native primitives first.** Commands, skills, agents, permissions, and background child sessions use OpenCode's own extension points.
2. **Plugins only when a primitive is missing.** `/goal` needs durable state and idle continuation, so the installer uses a dedicated goal plugin. `/btw` does not need a plugin because OpenCode supports background commands natively.
3. **Fresh context for independent work.** Planning, review, and side questions run in child sessions instead of bloating the main conversation.
4. **Separate planning from execution.** The planner is read-only and must produce acceptance criteria and verification steps before implementation.
5. **Independent verification.** The reviewer is read-only, reports findings before summaries, and treats tests and observed behavior as stronger evidence than self-reports.
6. **Progressive disclosure.** Detailed interactive behavior lives in a skill and is loaded only when needed.
7. **Model agnostic by default.** No command pins a provider or model; child agents inherit the active model unless the user configures an override.

The shape is intentionally small: useful Codex-style persistence and review discipline, OpenCode-native background work, and the interview/verification patterns popular in richer harnesses such as Oh My OpenCode and Pi-based agent setups, without installing a second orchestration layer.

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
└── skills/
    └── grill-me/
        └── SKILL.md
```

`/goal` is installed through OpenCode's plugin CLI using `@prevalentware/opencode-goal-plugin`.

Existing files with the same names are backed up before replacement.

## Updating

Run the installer again:

```bash
curl -fsSL https://raw.githubusercontent.com/jaeyoung0509/opencode-preset/main/install.sh | bash
```

## Uninstall

From a clone:

```bash
./uninstall.sh
```

The uninstaller removes only files carrying this preset's management marker. It leaves unrelated OpenCode configuration untouched and prints the command for removing the goal plugin separately.

## Notes

- No API keys, auth files, provider settings, or model settings belong in this repository.
- The preset is intended for global use. Project-specific architecture and build instructions should stay in that project's `AGENTS.md`.
- Commands and agents are English internally, but prompts and arguments can be written in any language.

## License

MIT
