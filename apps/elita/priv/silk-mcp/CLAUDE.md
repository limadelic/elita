# Silk MCP

Minimal browser automation MCP server with index-based element interaction.

## What it is

MCP server that exposes a single `browse` tool for web automation.
Built to solve token bloat problem in official @playwright/mcp.

## Current Status

Basic scaffold working:
- MCP server setup with STDIO transport
- Single `browse` tool registered
- Navigate action implemented (launches browser, goes to URL)

## What's Next

1. Add snapshot action - return numbered interactive elements
2. Port numbering logic from lib/silkd.ex
3. Add click/type actions that use element indices
4. Test with Claude Code to verify token usage is reasonable

## Testing

Standalone test:
```bash
node test.js
```

Configure in Claude Code `~/.claude/settings.json`:
```json
"mcpServers": {
  "silk-mcp": {
    "command": "node",
    "args": ["/Users/maykel.suarez/dev/self/elita/priv/silk-mcp/index.js"]
  }
}
```

Then restart Claude Code. Tool will be available as `mcp__silk_mcp__browse`.

## Context

Built as foundation for silkd product (web butler for Elita agents).
See /Users/maykel.suarez/dev/self/elita/lib/silkd.ex for numbering logic to port.
