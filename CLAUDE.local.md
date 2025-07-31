# Elita Agent System - Function Calling FULLY WORKING!

Elixir agent system with proper Vertex AI function calling:
- CLI: `./elita greet` and `./elita todo` work perfectly
- GenServer agents with YAML configs in `agents/*.md`
- **Complete Vertex AI function calling** with proper conversation history!
- ETS memory storage with set/get tools
- Clean modular architecture

## Current Structure:
- `lib/elita.ex` - Clean GenServer with act/done pipeline
- `lib/llm/llm.ex` - HTTP to Vertex AI with full prompt/result tracing
- `lib/llm/prompt.ex` - Builds Vertex format with tools
- `lib/llm/resp.ex` - Parses Vertex responses 
- `lib/llm/msg.ex` - **NEW** Creates proper Vertex message formats
- `lib/mem.ex` - ETS memory management
- `lib/utils/history.ex` - **NEW** Proper conversation history with function calling
- `lib/tools/tools.ex` - Tool execution and management
- `lib/tools/set.ex` + `get.ex` - Clean tool implementations

## Major Breakthrough:
**Fixed function calling conversation history!** Now using proper Vertex AI format:
- Model messages: `functionCall` objects 
- User messages: `functionResponse` with `{content: result}` format
- Two log entries per tool call (call + response)
- LLM sees function results and responds correctly

## Working Features:
- Todo agent stores/retrieves tasks correctly
- LLM responds intelligently after function calls  
- "Mark as done" works by clearing storage
- Conversation history maintains proper context
- Function calling no longer loops infinitely

## Architecture:
Clean functional pipeline: `prompt |> llm |> exec |> record |> done`