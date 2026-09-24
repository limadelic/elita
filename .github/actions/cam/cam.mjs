import { chromium } from 'playwright';
import { writeFileSync, mkdirSync, renameSync, watch } from 'fs';

async function join(page) {
  await page.goto('http://127.0.0.1:8080/#auto-join=%23the-lab');
  await page.click('button:has-text("Guest")');
  const nick = page.locator('input[placeholder="your_nick"]');
  await nick.fill('cam');
  await nick.press('Enter');
}

async function ready(page) {
  await page.locator('[data-testid="compose-input"]').waitFor({ timeout: 10000 });
  await page.locator('aside[aria-label="Channel members"]').waitFor({ timeout: 10000 });
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
  const context = await browser.newContext({ recordVideo: { dir: '/tmp/cam' } });
  const page = await context.newPage();

  await join(page);
  await ready(page);
  writeFileSync('/tmp/cam.ready', '');

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
