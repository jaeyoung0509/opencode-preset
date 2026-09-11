---
description: Run an independent read-only review in a fresh subagent
agent: preset-reviewer
subagent: true
---

Review the current work independently.

Scope supplied by the user:

$ARGUMENTS

If no scope is supplied, inspect the current git diff and the relevant surrounding code. Report actionable findings first, ordered by severity. Focus on correctness, regressions, concurrency, security, data integrity, operational risk, and missing verification. Do not edit files.
