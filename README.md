# claude-code-config

claude code and codex cli config files. please feel free to add suggestions!! i enjoy optimizing my agent workflows.

## claude code features

- **granular bash permissions** - only safe read-only commands allowed (cat, ls, find, grep, git status/log/diff/show/blame, etc.)
- **sound notifications** - ping sound on permission prompts, glass sound when done
- **auto-formatting** - prettier runs automatically on every file edit/write
- **auto-linting** - bun lint runs automatically after file changes
- **code-reviewer agent** - proactively reviews code for security, quality, and performance issues after changes
- **code-simplifier agent** - proactively simplifies code for better readability after modifications
- **plan agent** - architecture planning agent using opus model for deeper reasoning
- **/commit command** - auto-generate commit messages from git changes

## setup

### 1. environment variables

copy `.env.example` to `.env` and add your api keys:

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

### 3. codex cli symlinks

from the `claude-code-config` directory, symlink these to `~/.codex/`:

```bash
ln -s $(pwd)/codex/config.toml ~/.codex/config.toml
ln -s $(pwd)/codex/AGENTS.md ~/.codex/AGENTS.md
ln -s $(pwd)/codex/instructions.md ~/.codex/instructions.md
ln -s $(pwd)/codex/rules ~/.codex/rules
ln -s $(pwd)/codex/skills ~/.codex/skills
```

## structure

```
claude-code/
  config/
    settings.json           # model, permissions, statusline, hooks (prettier, lint, sounds)
    mcp.json
    CLAUDE.md               # global instructions (style, principles, machines)
    statusline-command.sh   # custom statusline with git branch, model, context

  agents/
    code-reviewer.md    # proactive code review
    code-simplifier.md  # proactive code simplification
    plan.md             # architecture planning

  rules/
    nia.md          # nia research assistant rules

  commands/
    commit.md       # /commit - generate commit messages

codex/
  config.toml
  AGENTS.md
  instructions.md
  rules/
    default.rules
  skills/
    .system/
```
