import { chromium } from 'playwright';

const videoDir = '/tmp/freeq-playwright-videos';

async function open(page) {
  await page.goto('http://127.0.0.1:8080/#auto-join=%23the-lab');
}

async function login(page) {
  await page.click('button:has-text("Guest")');
  const nickInput = page.locator('input[placeholder="your_nick"]');
  await nickInput.fill('brian');
  await nickInput.press('Enter');

  const skipButton = page.locator('button:has-text("Skip")').first();
  if (await skipButton.count() > 0) {
    await skipButton.click();
  }

  const composeInput = page.locator('[data-testid="compose-input"]');
  await composeInput.waitFor({ timeout: 10000 });
}

async function say(page) {
  const composeInput = page.locator('[data-testid="compose-input"]');
  await composeInput.focus();
  await composeInput.type('greet');
  await composeInput.press('Enter');
}

async function heard(page) {
  const messageList = page.locator('[data-testid="message-list"]');
  await messageList.waitFor({ timeout: 10000 });

  await page.waitForFunction(
    () => {
      const text = document.querySelector('[data-testid="message-list"]')?.textContent || '';
      return text.includes('greet');
    },
    { timeout: 60000 }
  );
}

async function members(page) {
  const memberAside = page.locator('aside[aria-label="Channel members"]');
  await memberAside.waitFor({ timeout: 10000 });

  const memberButtons = await memberAside.locator('button').count();
  const memberListText = await memberAside.textContent();

  if (memberButtons !== 1) {
    console.error(`FAIL: Expected exactly 1 member button, found ${memberButtons}`);
    console.error('Member list rendered:');
    console.error(memberListText);
    process.exit(1);
  }

  if (!memberListText.includes('brian')) {
    console.error('FAIL: Member list does not contain "brian"');
    console.error('Member list rendered:');
    console.error(memberListText);
    process.exit(1);
  }
}

async function test() {
  const browser = await chromium.launch({ headless: true });

  try {
    const context = await browser.newContext({
      recordVideo: { dir: videoDir }
    });

    const page = await context.newPage();

    await open(page);
    await login(page);
    await say(page);
    await heard(page);

    const videoPath = await page.video().path();
    if (videoPath) {
      console.log(`VIDEO: ${videoPath}`);
      const { execSync } = await import('child_process');
      try {
        const lsOutput = execSync(`ls -l ${videoPath}`).toString().trim();
        console.log(lsOutput);
      } catch (e) {
        // Ignore if file doesn't exist yet
      }
    }

    await members(page);
    await context.close();

    console.log('GREEN');
    process.exit(0);
  } catch (error) {
    console.error('Test failed:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

test();
