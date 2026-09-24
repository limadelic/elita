import { spawn, spawnSync } from 'child_process';
import { writeFileSync, openSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

async function install() {
  const dir = dirname(fileURLToPath(import.meta.url));
  spawnSync('npm', ['ci'], { cwd: dir, stdio: 'inherit' });
  spawnSync('npx', ['playwright', 'install', '--with-deps', 'chromium'], { cwd: dir, stdio: 'inherit' });
}

async function start() {
  const dir = dirname(fileURLToPath(import.meta.url));
  const scriptPath = join(dir, 'cam.mjs');
  const logFile = openSync('/tmp/cam.log', 'a');

  const proc = spawn('node', [scriptPath], {
    detached: true,
    stdio: ['ignore', logFile, logFile]
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

async function main() {
  await install();
  await start();
}

main().catch(() => process.exit(1));
