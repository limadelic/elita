import { chromium } from 'playwright';
import { writeFileSync, mkdirSync, renameSync, watch } from 'fs';
import { createConnection } from 'net';

function irc() {
  const client = createConnection(6667, 'localhost');
  client.write('NICK stage\r\n');
  client.write('USER stage 0 * :stage\r\n');
  client.on('data', (data) => {
    const msg = data.toString();
    if (msg.includes('PING')) {
      const token = msg.split(' ')[1];
      client.write(`PONG ${token}`);
    }
    if (msg.includes('001')) {
      client.write('JOIN #the-lab\r\n');
    }
  });
  return {
    close() {
      client.write('QUIT\r\n');
      client.end();
    }
  };
}

async function join(page) {
  const url = 'http://localhost:8787/?freeq=ws://localhost:8080/irc&room=%23the-lab&nick=cam&bare=1';
  await page.goto(url);
}

async function ready(page) {
  const canvas = page.locator('canvas#world');
  await canvas.waitFor({ timeout: 10000 });
  const world = page.locator('#world');
  try {
    await world.waitFor({ timeout: 10000, state: 'visible' });
    return true;
  } catch {
    return false;
  }
}

async function wait() {
  return new Promise((resolve) => {
    const timeout = setTimeout(() => resolve(), 10 * 60 * 1000);
    const watcher = watch('/tmp', (event, file) => {
      if (file === 'cam.stop') {
        clearTimeout(timeout);
        watcher.close();
        resolve();
      }
    });
  });
}

async function main() {
  mkdirSync('/tmp/cam', { recursive: true });
  const stage = irc();
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ recordVideo: { dir: '/tmp/cam' } });
  const page = await context.newPage();
  await context.addInitScript(() => {
    localStorage.setItem('fimp-first-steps-dismissed', '1');
  });

  await join(page);
  if (await ready(page)) {
    writeFileSync('/tmp/cam.ready', '');
  }

  await wait();

  const video = await page.video()?.path();
  await context.close();
  await browser.close();
  stage.close();

  if (video) {
    renameSync(video, '/tmp/cam/greet.webm');
  }
  process.exit(0);
}

main().catch(() => process.exit(1));
