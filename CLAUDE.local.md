# Current Session Progress

## API Design Decisions
- REST API with POST for agent decisions
- Route: `POST /agents/{agent_name}` (no /decide suffix)
- PUT /agents/{agent_name} for uploading agent markdown
- No sessions - stateless requests with full context
- Store agents as .md files in filesystem (agents/greedy.md)
- Files persist across restarts, lost on redeploys (fine for now)

## Implementation Approach
- Skip Phoenix/Ash - just Cowboy/Bandit HTTP server
- GenServer per agent or simple request handler
- File I/O for markdown storage
- HTTP client for LLM calls
- Keep it minimal (~100 lines)

## Next Steps
- Spec out the exact POST request/response format
- Build minimal HTTP server that can load/execute agents
- Test greedy agent with actual domino scenarios

## Architecture Notes
- doble9 app (customer) talks to elita via REST
- elita loads agent markdown, processes with LLM, returns decision
- Agent = GenServer that handles message -> LLM -> response flow
- Retry loops for format validation, strict contracts