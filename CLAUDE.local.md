# Elita Agent System

Working Elixir agent system with:
- CLI: `./elita greet` starts greet agent in chat mode
- GenServer-based agents that load config from markdown files
- LLM integration via HTTP to 192.168.1.22:3001
- Distributed Erlang for inter-agent communication
- E2E tests hitting real LLM server

Structure:
- `lib/cli.ex` - command line interface
- `lib/elita.ex` - main GenServer with imports
- `lib/config.ex` - loads agent configs from `agents/*.md`
- `lib/prompt.ex` - builds prompts with history
- `lib/llm.ex` - HTTP calls to LLM server
- `agents/greet.md` - Greeeet agent that asks for names

Current state: fully working, tests pass, ready for more agents.