# global instructions

## code style

- use lowercase for all comments
- keep code simple, avoid over-engineering
- prefer readability over cleverness
- no emojis
- no em dashes - use hyphens or colons instead

## python

- use uv for everything: uv run, uv pip, uv venv

## git commits

- use conventional commit prefixes: feat, fix, docs, refactor, chore, test, style
- lowercase only (including the prefix)
- one-liner describing what was implemented
- no signatures or co-authored-by lines
- commit after completing each task

## communication

- narrate every step

## don'ts

- don't add features that weren't requested (but you can suggest them)
- don't refactor unrelated code
- don't add documentation unless asked

## principles

### research

- for all the principles below always use nia to research and index documents when needed
- use nia mcp as ground truth source

### epistemology

- assumptions are the enemy - never guess numerical values
- benchmark instead of estimating
- when uncertain, measure - say "this needs to be measured" rather than inventing statistics

### scaling

- validate at small scale before scaling up
- run a sub-minute version first to verify the full pipeline works
- when scaling, only the scale parameter should change

### interaction

- clarify unclear requests, then proceed autonomously
- only ask for help when scripts timeout (>2min), sudo is needed, or genuine blockers arise

### ground-truth-clarification

- for non-trivial tasks, reach ground truth understanding before coding
- simple tasks execute immediately
- complex tasks (refactors, new features, ambiguous requirements) require clarification first: research codebase, ask targeted questions, confirm understanding, persist the plan, then execute autonomously

### spec-driven-development

- when starting a new project, after compaction, or when SPEC.md is missing/stale and substantial work is requested: invoke /spec skill to interview the user
- the spec persists across compactions and prevents context loss
- update SPEC.md as the project evolves
- if stuck or losing track of goals, re-read SPEC.md or re-interview

### first-principles-reimplementation

- building from scratch can beat adapting legacy code when implementations are in wrong languages, carry historical baggage, or need architectural rewrites
- understand domain at spec level, choose optimal stack, implement incrementally with human verification

### constraint-persistence

- when user defines constraints ("never X", "always Y", "from now on"), immediately persist to project's local CLAUDE.md
- acknowledge, write, confirm
