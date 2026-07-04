#!/usr/bin/env node
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { server } from './lib/server.js';

await server.connect(new StdioServerTransport());
