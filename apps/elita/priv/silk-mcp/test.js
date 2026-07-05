#!/usr/bin/env node

import { spawn } from 'child_process';

const server = spawn('node', ['index.js']);

server.stdout.on('data', (data) => {
  console.log('Server:', data.toString());
});

server.stderr.on('data', (data) => {
  console.error('Error:', data.toString());
});

setTimeout(() => {
  const listToolsRequest = {
    jsonrpc: '2.0',
    id: 1,
    method: 'tools/list',
    params: {}
  };

  server.stdin.write(JSON.stringify(listToolsRequest) + '\n');

  setTimeout(() => {
    const browseRequest = {
      jsonrpc: '2.0',
      id: 2,
      method: 'tools/call',
      params: {
        name: 'browse',
        arguments: {
          action: 'navigate',
          url: 'https://www.google.com'
        }
      }
    };

    server.stdin.write(JSON.stringify(browseRequest) + '\n');

    setTimeout(() => {
      server.kill();
      process.exit(0);
    }, 5000);
  }, 2000);
}, 1000);
