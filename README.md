# claude-code

claude code config files. please feel free to add suggestions!! i enjoy optimizing my agent workflows.

## features

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

### 2. symlink configuration files

from the `claude-code-config` directory, symlink these to `~/.claude/`:

```bash
ln -s $(pwd)/config/settings.json ~/.claude/settings.json
ln -s $(pwd)/config/mcp.json ~/.claude/mcp.json
ln -s $(pwd)/config/CLAUDE.md ~/.claude/CLAUDE.md
ln -s $(pwd)/config/statusline-command.sh ~/.claude/statusline-command.sh
ln -s $(pwd)/agents ~/.claude/agents
ln -s $(pwd)/rules ~/.claude/rules
ln -s $(pwd)/commands ~/.claude/commands
```

## structure

```
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
```
