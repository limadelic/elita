# Elita Project Context

## Vision
Agentic platform using Elixir/OTP for reliable agent behavior. Natural language as the new programming paradigm. Anti-RAG, explicit memory control.

## Agent Definition Pattern
- Name, Role, Goals, Instructions, Examples
- Future: Constraints, Memory (assert/retract style)
- No Tools section (handled by platform)

## Philosophy
- Treat LLMs as unreliable components with guardrails
- Strict contracts with retry loops
- Explicit memory control vs auto-magic
- GenServer = Agent (but don't mention OTP to users)

## ALWAYS TEST FIRST BEFORE ANY CODE CHANGES - RUN `mix test` EVERY TIME

## Elixir Style Guide
- Avoid compound names
- Follow BDD to name things
- Create reusable helpers to stay DRY
- Use pattern matching never CASE
- Always use alias for module references, never write Elita.ModuleName.function
- Import functions to avoid Module.function calls, prefer bare function names

## TESTING RULES
- ALWAYS run `mix test` before making ANY code changes
- ALWAYS run `mix test` after making ANY code changes  
- If tests fail, fix them before doing anything else
- Use `mix test` for development feedback (unit/integration tests)
- Use `mix test test/` for final validation before work is done (e2e tests)
- NEVER cd into directories - always run commands from project root

## PROJECT STRUCTURE
- Umbrella project with apps/elita (core platform) and apps/api (gateway)
- Each app has unit tests in their test/ directories
- E2E tests live in umbrella root test/ directory

