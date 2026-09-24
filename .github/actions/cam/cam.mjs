import { chromium } from 'playwright';
import { writeFileSync, mkdirSync, renameSync, watch } from 'fs';

async function join(page) {
  const url = 'http://localhost:8787/?freeq=ws://localhost:8080/irc&room=%23the-lab&nick=cam';
  await page.goto(url);
}

async function ready(page) {
  const canvas = page.locator('canvas#world');
  await canvas.waitFor({ timeout: 10000 });
  const world = page.locator('#world');
  try {
    await world.waitFor({ timeout: 10000, state: 'visible' });
    await page.waitForFunction(
      () => document.querySelector('[data-testid="header-loc"]')?.textContent.includes('#the-lab'),
      { timeout: 10000 }
    );
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
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    recordVideo: { dir: '/tmp/cam', size: { width: 1280, height: 720 } }
  });
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

  if (video) {
    renameSync(video, '/tmp/cam/greet.webm');
  }
  process.exit(0);
}

main().catch(() => process.exit(1));
