# claude-code

claude code config files.

## setup

symlink these to `~/.claude/`:

```bash
ln -s $(pwd)/config/settings.json ~/.claude/settings.json
ln -s $(pwd)/config/hooks.json ~/.claude/hooks.json
ln -s $(pwd)/config/CLAUDE.md ~/.claude/CLAUDE.md
ln -s $(pwd)/agents ~/.claude/agents
ln -s $(pwd)/rules ~/.claude/rules
```

## structure

```
config/
  settings.json   # model, statusline, notification sounds
  hooks.json      # prettier + bun lint on file changes
  CLAUDE.md       # global instructions (lowercase commits/comments)

agents/
  code-reviewer.md    # proactive code review
  code-simplifier.md  # proactive code simplification
  plan.md             # architecture planning

rules/
  nia.md          # nia research assistant rules
```
