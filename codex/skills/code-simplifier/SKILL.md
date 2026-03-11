---
name: code-simplifier
description: Simplify code after changes are made without changing behavior or public APIs. Use when the user asks for simplification, when a recent change is correct but overly complex, or when a targeted readability pass is needed after implementation.
---

# Code Simplifier

Use this skill for focused readability and maintainability improvements after the intended behavior is already correct.

## Workflow

1. read the relevant files first
   - inspect the changed code and enough surrounding context to understand the current behavior
   - identify functions, conditions, or repeated logic that can be simplified safely
2. choose only low-risk simplifications
   - reduce nesting with guard clauses
   - extract repeated logic into well-named helpers when it removes duplication
   - improve vague names
   - remove dead or obviously obsolete code
3. verify integrity after the edit
   - run the narrowest relevant checks
   - mention any manual verification that is still needed

## Constraints

- do not change functionality
- do not remove error handling just to make code shorter
- do not change public APIs unless the task explicitly allows it
- skip uncertain simplifications and explain the uncertainty instead
