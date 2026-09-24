import { spawn } from 'child_process';
import { writeFileSync } from 'fs';
import { resolve } from 'path';

async function start() {
  const scriptPath = resolve(import.meta.url, '..', 'cam.mjs').slice(7);
  const proc = spawn('node', [scriptPath], {
    detached: true,
    stdio: ['ignore', 'append:/tmp/cam.log', 'append:/tmp/cam.log']
  });
  const pid = proc.pid;
  proc.unref();

  writeFileSync('/tmp/cam.pid', String(pid));
  if (process.env.GITHUB_STATE) {
    writeFileSync(process.env.GITHUB_STATE, `pid=${pid}\n`, { flag: 'a' });
  }

  return new Promise((resolve) => {
    const timeout = setTimeout(() => resolve(), 60000);
    const check = setInterval(async () => {
      try {
        const { readFileSync } = await import('fs');
        readFileSync('/tmp/cam.ready');
        clearTimeout(timeout);
        clearInterval(check);
        resolve();
      } catch { }
    }, 100);
  });
}

start().catch(() => process.exit(1));
