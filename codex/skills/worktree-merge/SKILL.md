---
name: worktree-merge
description: Merge the current git worktree branch back into a target branch and clean up the worktree. Use when the user wants to finish a worktree-based task, merge the worktree branch into `main` or another base branch, and remove the temporary worktree safely.
---

# Worktree Merge

Use this skill to finish worktree-based tasks safely and predictably.

## Workflow

1. verify the current location
   - run `git worktree list`
   - run `pwd` and `git rev-parse --show-toplevel`
   - abort if the current directory is the main worktree
2. verify the worktree is clean
   - run `git status --porcelain`
   - abort if there are uncommitted changes
3. gather the merge inputs
   - current branch from `git rev-parse --abbrev-ref HEAD`
   - main worktree path from the first entry in `git worktree list`
   - target branch from the user if provided, otherwise default to `main`
4. perform the merge from the main worktree
   - change to the main worktree path
   - run `git merge <current-branch> --no-edit`
   - if conflicts occur, stop and report the main worktree path for manual resolution
5. clean up
   - remove the completed worktree with `git worktree remove <worktree-path>`
   - confirm with `git worktree list`

## Output

- report the merged branch, the target branch, and the removed worktree path
- if the merge cannot proceed, explain the exact blocker and the next manual step

## Constraints

- do not force merges
- do not discard uncommitted work
- keep the report concise
