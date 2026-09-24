import { chromium } from 'playwright';
import { writeFileSync, mkdirSync, renameSync } from 'fs';

async function join(page) {
  await page.goto('http://127.0.0.1:8080/#auto-join=%23the-lab');
  await page.click('button:has-text("Guest")');
  const nick = page.locator('input[placeholder="your_nick"]');
  await nick.fill('watcher');
  await nick.press('Enter');
}

async function ready(page) {
  await page.locator('[data-testid="compose-input"]').waitFor({ timeout: 10000 });
  await page.locator('aside[aria-label="Channel members"]').waitFor({ timeout: 10000 });
}

async function wait(page) {
  const list = page.locator('[data-testid="message-list"]');
  const timeout = 5 * 60 * 1000;
  const start = Date.now();
  let saw = false;
  while (Date.now() - start < timeout) {
    const text = await list.textContent().catch(() => '');
    if (text.includes('greet') && text.includes('left')) {
      saw = true;
      break;
    }
    await page.waitForTimeout(500);
  }
  if (!saw) process.exit(1);
}

async function main() {
  mkdirSync('/tmp/freeq-video', { recursive: true });
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ recordVideo: { dir: '/tmp/freeq-video' } });
  const page = await context.newPage();

  await join(page);
  await ready(page);
  writeFileSync('/tmp/camera.ready', '');

  await wait(page);

  const video = await page.video()?.path();
  await context.close();
  await browser.close();

  if (video) {
    renameSync(video, '/tmp/freeq-video/greet.webm');
  }
  process.exit(0);
}

main().catch(() => process.exit(1));
