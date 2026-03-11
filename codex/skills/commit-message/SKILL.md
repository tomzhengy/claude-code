---
name: commit-message
description: Draft concise conventional commit messages from the current git changes. Use when the user asks for a commit message, wants help summarizing staged or unstaged diffs, or needs a one-line commit title that matches the repo's commit style.
---

# Commit Message

Generate a single commit message line from the current git state.

## Workflow

1. inspect the current changes
   - check `git status` first
   - inspect `git diff --staged` when there are staged changes
   - if nothing is staged, inspect `git diff`
2. summarize what actually changed
   - focus on the implementation result, not the motivation
   - prefer the smallest truthful summary that still distinguishes the change from neighboring commits
3. return one commit title only
   - do not add explanation, bullets, or body text

## Style Rules

- use a conventional commit prefix when it fits: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:`, `style:`
- keep everything lowercase
- keep it to one line
- do not add signatures, co-authors, or emojis
- be specific enough that the commit can be understood later without reopening the diff
