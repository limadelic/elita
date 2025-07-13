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

## Elixir Style Guide
- Avoid compound names
- Follow BDD to name things
- Create reusable helpers to stay DRY
- Use pattern matching never CASE
