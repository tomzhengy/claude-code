# claude-code-config

claude code and codex cli config files. please feel free to add suggestions!! i enjoy optimizing my agent workflows.

## claude code features

- **granular bash permissions** - read-only commands auto-allowed, write commands (git add/commit/merge/checkout/worktree) explicitly permitted
- **sound notifications** - async ping on permission prompts, idle prompts, auth, elicitations, and plan mode responses; glass sound when done
- **auto-formatting** - prettier runs automatically on every file edit/write
- **auto-linting** - bun lint runs automatically after file changes
- **git worktree workflow** - auto-creates worktrees for non-trivial tasks to isolate branches across sessions
- **behavioral guardrails** - assumption surfacing, confusion management, change summaries
- **systems-first design** - iterates on system design before writing code
- **plan agent** - architecture planning agent using opus model for deeper reasoning
- **/commit command** - auto-generate commit messages from git changes
- **/merge command** - merge a worktree branch back into the target branch and clean up
- **nia research rules** - integrated nia mcp for external code/docs research and indexing
- **custom statusline** - git branch, model, and context info

## setup

### 1. environment variables

copy `.env.example` to `.env`, add your api keys, then load it in your shell:

```bash
cp .env.example .env
# edit .env with your keys
set -a
source .env
set +a
```

### 2. claude code symlinks

from the `claude-code-config` directory, symlink these to `~/.claude/`:

```bash
ln -s $(pwd)/claude-code/config/settings.json ~/.claude/settings.json
ln -s $(pwd)/claude-code/config/mcp.json ~/.claude/mcp.json
ln -s $(pwd)/claude-code/config/CLAUDE.md ~/.claude/CLAUDE.md
ln -s $(pwd)/claude-code/config/statusline-command.sh ~/.claude/statusline-command.sh
ln -s $(pwd)/claude-code/agents ~/.claude/agents
ln -s $(pwd)/claude-code/rules ~/.claude/rules
ln -s $(pwd)/claude-code/commands ~/.claude/commands
```

### 3. codex cli setup

from the `claude-code-config` directory, symlink these files to `~/.codex/`:

```bash
mkdir -p ~/.codex
ln -sf $(pwd)/codex/config.toml ~/.codex/config.toml
ln -sf $(pwd)/codex/AGENTS.md ~/.codex/AGENTS.md
ln -sf $(pwd)/codex/instructions.md ~/.codex/instructions.md
ln -sfn $(pwd)/codex/rules ~/.codex/rules
ln -sfn $(pwd)/codex/skills ~/.codex/skills
```

verify codex setup:

```bash
codex --help
ls -la ~/.codex
```

if prompted, run `codex` once and complete sign-in. keep your env vars loaded before launching codex so mcp tokens resolve correctly.

## structure

```
claude-code/
  config/
    settings.json           # model, permissions, statusline, hooks (prettier, lint, sounds)
    mcp.json                # mcp server config (nia, github, etc.)
    CLAUDE.md               # global instructions (style, behavior, principles)
    statusline-command.sh   # custom statusline with git branch, model, context

  agents/
    plan.md                 # architecture planning
    disabled/
      code-reviewer.md      # proactive code review (disabled)
      code-simplifier.md    # proactive code simplification (disabled)

  rules/
    nia.md                  # nia research assistant rules

  commands/
    commit.md               # /commit - generate commit messages
    merge.md                # /merge - merge worktree branch and clean up

codex/
  config.toml
  AGENTS.md
  instructions.md
  rules/
    default.rules
  skills/
    .system/

gpu-setup/
  Dockerfile                # runpod pytorch gpu environment
  bootstrap.sh              # system setup script
  entrypoint.sh             # container entrypoint
```
