---
description: Ask a side question with a native background subagent
---

Dispatch the following side question with OpenCode's native `task` tool immediately:

$ARGUMENTS

Requirements:

- Use `subagent_type: "preset-btw"`.
- Use `background: true`.
- Use a short description beginning with `BTW:`.
- Put the complete side question in the task prompt.
- Do not answer the side question yourself.
- Do not poll or wait for the task. OpenCode will inject the result when it completes.
- After dispatch, continue only work that does not depend on the side-question result. If there is no other active work, briefly acknowledge the dispatch and stop.
- If native background subagents are unavailable, say that `OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true` is required instead of silently falling back to a foreground task.
