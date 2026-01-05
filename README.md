# claude-code

claude code config files. please feel free to add suggestions!! i enjoy optimizing my agent workflows.

## setup

symlink these to `~/.claude/`:

```bash
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
