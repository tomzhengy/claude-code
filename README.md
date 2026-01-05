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

## setup

from the `claude-code-config` directory, symlink these to `~/.claude/`:

```bash
# remove old symlinks if they exist
rm -f ~/.claude/settings.json ~/.claude/hooks.json ~/.claude/mcp.json ~/.claude/CLAUDE.md ~/.claude/agents ~/.claude/rules

# create new symlinks
ln -s $(pwd)/config/settings.json ~/.claude/settings.json
ln -s $(pwd)/config/hooks.json ~/.claude/hooks.json
ln -s $(pwd)/config/mcp.json ~/.claude/mcp.json
ln -s $(pwd)/config/CLAUDE.md ~/.claude/CLAUDE.md
ln -s $(pwd)/agents ~/.claude/agents
ln -s $(pwd)/rules ~/.claude/rules
```

## structure

```
config/
  settings.json   # model, statusline, notification sounds
  hooks.json      # prettier + bun lint on file changes
  mcp.json        # mcp server configuration
  CLAUDE.md       # global instructions (style, principles, machines)

agents/
  code-reviewer.md    # proactive code review
  code-simplifier.md  # proactive code simplification
  plan.md             # architecture planning

rules/
  nia.md          # nia research assistant rules
```
