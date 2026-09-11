# Repository Instructions

This repository is intentionally small. Preserve OpenCode's default harness and prefer native extension points over custom orchestration.

## Principles

- Keep the preset model- and provider-agnostic.
- Never commit credentials, auth files, provider configuration, or user-specific paths.
- Prefer Markdown commands, Markdown agents, and Agent Skills before introducing a plugin.
- Use a plugin only when the workflow needs hooks, durable state, or asynchronous lifecycle behavior.
- Keep planning and review agents read-only.
- Keep prompts concise and evidence-oriented. Avoid generic ceremony and artificial finding/test quotas.
- Preserve fresh-context boundaries for planning, review, and side questions.
- Keep project-specific rules out of this preset; they belong in the consuming repository's `AGENTS.md`.
- Back up user files before replacing them and avoid modifying unrelated OpenCode configuration.

## Verification

For installer changes, run:

```bash
bash -n install.sh
bash -n uninstall.sh
```

For command, agent, or skill changes, verify the frontmatter against the current OpenCode documentation and confirm the referenced agent/skill names match installed paths.

For `/btw`, verify that the side question runs in a temporary session, the temporary session is deleted, the answer is injected with `noReply`, and project files cannot be modified by the side-session prompt.
