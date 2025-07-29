# Elita Agent System - Function Calling Working!

Working Elixir agent system with Vertex AI function calling:
- CLI: `./elita greet` and `./elita todo` work  
- GenServer agents with YAML configs in `agents/*.md`
- **Vertex AI native function calling** - no regex parsing!
- ETS memory storage with set/get tools
- First todo test GREEN ✅

Structure:
- `lib/elita.ex` - GenServer with tool execution
- `lib/llm.ex` - Vertex AI function calling API
- `lib/prompt.ex` - smart prompt builder (no conflicting tool instructions)
- `agents/todo.md` - Todo agent with tools: set, get
- `agents/greet.md` - Simple greet agent (no tools)

Breakthrough: Removed conflicting text instructions about tools from agent configs. 
Native function calling works when prompts don't include tool usage examples.

Status: Core function calling infrastructure complete. Ready for more agents.