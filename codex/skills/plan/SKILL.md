---
name: plan
description: Research a codebase and produce decision-complete implementation plans before code is written. Use when the user asks for a plan, wants to compare implementation approaches, or needs a concrete execution strategy with impacted files, risks, and tests.
---

# Plan

Create implementation plans that another engineer or agent can execute without making major product or architecture decisions.

## Workflow

1. ground the plan in the actual repo
   - inspect the relevant files, configs, types, tests, and similar implementations
   - identify the stack, conventions, and existing patterns before proposing changes
   - do not propose edits to code you have not read
2. analyze the change surface
   - identify the files, interfaces, and dependencies that will change
   - note edge cases, rollout risks, and compatibility constraints
   - preserve existing naming, structure, and error-handling patterns unless the task explicitly calls for a change
3. design the implementation
   - break the work into ordered steps that are specific and reviewable
   - group by behavior or subsystem unless file names are needed to avoid ambiguity
   - call out alternatives only when the tradeoff materially changes the design

## Output

Structure the plan so it is easy to hand off:

1. summary - what will be built and the high-level approach
2. implementation changes - ordered steps with the key files or interfaces involved
3. test plan - the checks, scenarios, and acceptance criteria needed to validate the change
4. assumptions - anything unresolved or intentionally chosen by default

## Constraints

- do not write code while using this skill
- keep the plan concise, but decision complete
- prefer minimal, focused changes over broad refactors
- note open questions instead of silently guessing when a requirement is ambiguous
