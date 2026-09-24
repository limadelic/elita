import { chromium } from 'playwright';
import { execSync } from 'child_process';

async function run() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ recordVideo: { dir: '/tmp/freeq-videos' } });
  const page = await context.newPage();

  try {
    // Open and login as watcher
    await page.goto('http://127.0.0.1:8080/#auto-join=%23the-lab');
    await page.click('button:has-text("Guest")');

    const nickInput = page.locator('input[placeholder="your_nick"]');
    await nickInput.fill('watcher');
    await nickInput.press('Enter');

    // Wait for compose input
    const composeInput = page.locator('[data-testid="compose-input"]');
    await composeInput.waitFor({ timeout: 10000 });

    // Wait until in channel - check for members list
    const memberAside = page.locator('aside[aria-label="Channel members"]');
    await memberAside.waitFor({ timeout: 10000 });

    // Run tests
    try {
      execSync('cd apps/elita && mix test --only freeq --warnings-as-errors', {
        cwd: process.cwd(),
        stdio: 'inherit'
      });
    } catch (err) {
      console.error(`Tests failed: ${err.message}`);
      throw err;
    }
  } finally {
    await context.close();
    await browser.close();

    const videoPath = await page.video()?.path();
    if (videoPath) {
      console.log(videoPath);
    }

    process.exit(0);
  }
}

run().catch(err => {
  console.error(`ERROR: ${err.message}`);
  process.exit(1);
});
