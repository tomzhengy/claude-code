# global instructions

## code style

- lowercase comments, no emojis, no em dashes (use hyphens/colons)
- keep code simple, prefer readability over cleverness

## python

- use uv for everything: uv run, uv pip, uv venv
- use `hf` cli instead of `huggingface-cli`

## bash

- avoid output buffering: don't pipe through head/tail/less/more
- use command flags instead (e.g., `git log -n 10` not `git log | head -10`)
- run commands directly without pipes when possible

## git commits

- conventional prefixes: feat, fix, docs, refactor, chore, test, style
- lowercase, one-liner, no signatures/co-authored-by

## communication

- narrate every step

## don'ts

- don't add unrequested features (suggest instead)
- don't refactor unrelated code or add docs unless asked

## principles

- **research**: use nia mcp as ground truth source
- **epistemology**: never guess numbers - benchmark/measure instead
- **scaling**: validate at small scale first, then only change scale parameter
- **interaction**: clarify unclear requests, ask for help only on timeouts/sudo/blockers
- **ground-truth**: complex tasks need clarification first, simple tasks execute immediately
- **spec-driven**: invoke /spec for new projects or after compaction, maintain SPEC.md
- **first-principles**: building from scratch can beat adapting legacy code
- **constraint-persistence**: persist user constraints ("never X", "always Y") to local CLAUDE.md
