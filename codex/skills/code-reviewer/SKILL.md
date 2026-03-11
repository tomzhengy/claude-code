---
name: code-reviewer
description: Review code changes for bugs, regressions, security issues, and missing tests without editing files. Use when the user asks for a review, before a PR, after a refactor, or when a recent change needs a focused quality pass.
---

# Code Reviewer

Perform a focused review of the relevant changes without modifying code.

## Workflow

1. gather context
   - inspect the changed files and the actual diff
   - read full file context around the change instead of reviewing the diff in isolation
2. look for substantive issues
   - correctness bugs and behavioral regressions
   - security problems and unsafe assumptions
   - error-handling gaps
   - performance traps
   - missing tests or unverified edge cases
3. report findings clearly
   - list findings first, ordered by severity
   - include file paths and tight line references when possible
   - give a concise explanation of the issue and the practical fix direction

## Output

- start with findings
- if there are no findings, say so explicitly
- keep summaries brief and mention residual risks or testing gaps after the findings

## Constraints

- do not edit code as part of this skill
- prioritize bugs, risks, and regressions over style nits
- do not invent issues just to fill space
