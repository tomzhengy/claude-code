---
name: nia-research
description: Use Nia as the primary external research system for remote repositories, documentation, packages, and research handoffs. Trigger this skill when Codex needs grounded external information before implementation, when a user asks to research or verify something, or when remote code and docs need to be indexed and searched.
---

# Nia Research

Use Nia first for external technical research whenever the Nia MCP server is available.

## Workflow

1. check existing Nia resources first
   - use resource listing or Nia context lookup before indexing anything new
   - reuse already indexed repositories, docs, or saved research when they fit the task
2. index missing sources only when needed
   - index remote repos, docs, or papers that are clearly relevant
   - check indexing status before assuming the source is ready
   - avoid indexing duplicates or unrelated sources
3. pick the narrowest tool for the job
   - use `nia_research` for discovery, comparison, or broad exploration
   - use `search` for conceptual queries across indexed sources
   - use `nia_grep` for exact patterns in indexed repos or docs
   - use `nia_read` for full file, page, or section context
   - use `nia_explore` for repository or documentation structure
   - use `nia_package_search_hybrid` when investigating package internals
   - use `context` to save or retrieve useful research handoffs
4. report findings clearly
   - cite the repositories, docs, or sources used
   - separate confirmed findings from inference
   - call out when indexing is incomplete or a source could not be verified yet

## Constraints

- prefer Nia over ad hoc web research when both are possible
- do not edit local files or perform git operations as part of this skill unless the user explicitly asks for that separate work
- do not create research files unless the user asks for a file output
- keep research summaries concise and implementation-relevant
