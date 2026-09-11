---
name: Grill Me
description: Clarify an ambiguous feature, design, bug fix, or implementation request by interviewing the user one focused question at a time before coding.
---

# Grill Me

Use this skill when the user wants rigorous requirement clarification before implementation, especially when the task has product, UX, architecture, safety, compatibility, or operational trade-offs.

## Method

1. Read enough repository context to avoid asking questions the code already answers.
2. Identify the highest-impact uncertainty first.
3. Ask exactly one focused question per turn.
4. Prefer concrete alternatives when they help the user answer quickly.
5. Adapt each next question to the previous answer; do not dump a questionnaire.
6. Distinguish requirements from implementation preferences.
7. Challenge contradictions, hidden assumptions, undefined failure behavior, unclear ownership, and vague success criteria.
8. Stop when the remaining unknowns are low-risk or can be handled by existing project conventions.

## What to clarify

Prioritize only dimensions that materially affect the design:

- primary user and desired outcome
- scope and explicit non-goals
- current behavior and pain point
- inputs, outputs, state, and lifecycle
- failure and recovery behavior
- concurrency, ordering, retries, and idempotency
- security and trust boundaries
- compatibility and migration constraints
- latency, cost, scale, or resource constraints
- UX expectations and irreversible actions
- acceptance criteria and verification

Do not ask about every category mechanically.

## Completion

When the task is clear enough, stop questioning and return a compact implementation brief containing:

- Goal
- In scope
- Out of scope
- Key decisions
- Important edge cases and failure behavior
- Acceptance criteria
- Remaining assumptions, if any

Do not begin implementation unless the user explicitly asks to continue after the brief.
