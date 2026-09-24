import { chromium } from 'playwright';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const videoDir = '/tmp/freeq-playwright-videos';

async function test() {
  const browser = await chromium.launch({ headless: true });

  try {
    const context = await browser.newContext({
      recordVideo: { dir: videoDir }
    });

    const page = await context.newPage();

    // 1. Open the auto-join URL
    await page.goto('http://127.0.0.1:8080/#auto-join=%23the-lab');

    // 2. Click the Guest button
    await page.click('button:has-text("Guest")');

    // 3. Fill nick input and press Enter
    const nickInput = page.locator('input[placeholder="your_nick"]');
    await nickInput.fill('brian');
    await nickInput.press('Enter');

    // Dismiss welcome modal if it appears
    const skipButton = page.locator('button:has-text("Skip")').first();
    if (await skipButton.count() > 0) {
      console.log('Dismissing welcome modal');
      await skipButton.click();
    }

    // 4. Wait for compose-input to appear
    const composeInput = page.locator('[data-testid="compose-input"]');
    await composeInput.waitFor({ timeout: 10000 });
    console.log('Compose input found');

    // Wait for channel to come online (might be initializing)
    // Check if "Offline" status changes in the channel info panel
    await page.waitForFunction(
      () => {
        const channelInfo = document.querySelector('aside')?.textContent || '';
        // Wait until channel status is NOT "Offline"
        return !channelInfo.includes('Offline');
      },
      { timeout: 30000 }
    ).catch(() => {
      // It's okay if this times out - channel might stay offline
      console.log('Channel did not come online, proceeding anyway');
    });

    // 5. Type "greet" into the composer and press Enter
    await composeInput.focus();
    await composeInput.type('greet');
    console.log('Typed "greet"');
    await composeInput.press('Enter');
    console.log('Pressed Enter');

    // 6. Wait for message-list to contain "greet" on brian's line
    const messageList = page.locator('[data-testid="message-list"]');
    await messageList.waitFor({ timeout: 10000 });

    // Try to wait for greet, but log diagnostics if it times out
    let messageFound = false;
    try {
      await page.waitForFunction(
        () => {
          const text = document.querySelector('[data-testid="message-list"]')?.textContent || '';
          return text.includes('greet');
        },
        { timeout: 60000 }
      );
      messageFound = true;
      console.log('Found greet text in message list');
    } catch (e) {
      // Log what's actually in the message list
      const messageListText = await messageList.textContent();
      console.log('Message list content after 60s wait:');
      console.log(messageListText);
      console.log('\nDiagnostics: Channel offline, message not appearing in list');
    }

    // 7. Assert member list has exactly one member (brian)
    // Try to find the member list aside element
    console.log('\nSearching for member list aside element...');
    const allAsides = await page.locator('aside').count();
    console.log(`Found ${allAsides} aside elements`);

    // Try different selectors for the member list
    const memberAside1 = page.locator('aside[aria-label="Channel members"]');
    const memberAside2 = page.locator('aside:has-text("members")');
    const memberAside3 = page.locator('aside').last();

    let memberAside = null;
    if (await memberAside1.count() > 0) {
      console.log('Found via aria-label');
      memberAside = memberAside1;
    } else if (await memberAside2.count() > 0) {
      console.log('Found via :has-text(members)');
      memberAside = memberAside2;
    } else {
      console.log('Using last aside element');
      const asideText = await memberAside3.textContent();
      console.log('Last aside content preview:', asideText.substring(0, 100));
      memberAside = memberAside3;
    }

    await memberAside.waitFor({ timeout: 10000 });

    const memberButtons = await memberAside.locator('button').count();
    const memberListText = await memberAside.textContent();

    console.log('\n=== MEMBER LIST ===');
    console.log(memberListText);
    console.log('=== END MEMBER LIST ===\n');
    console.log(`Member buttons count: ${memberButtons}`);

    // If message wasn't found, take screenshot and stop
    if (!messageFound) {
      await page.screenshot({ path: '/tmp/final-screenshot.png' });
      console.error('\nFAIL: Message not found in message list');
      console.error('Screenshot saved to /tmp/final-screenshot.png');
      console.error('Stopping due to message assertion failure');
      process.exit(1);
    }

    if (memberButtons !== 1) {
      console.error(`FAIL: Expected exactly 1 member button, found ${memberButtons}`);
      console.error('Member list rendered:');
      console.error(memberListText);
      process.exit(1);
    }

    // Verify the member is brian
    if (!memberListText.includes('brian')) {
      console.error('FAIL: Member list does not contain "brian"');
      console.error('Member list rendered:');
      console.error(memberListText);
      process.exit(1);
    }

    // 8. Close context to finalize video
    const videoPath = await context.close();

    // Get video file path from the returned path
    const videoFile = videoPath ? videoPath : null;
    if (videoFile) {
      console.log(`\nVIDEO: ${videoFile}`);
      // Print file size
      const { execSync } = await import('child_process');
      try {
        const lsOutput = execSync(`ls -l ${videoFile}`).toString().trim();
        console.log(lsOutput);
      } catch (e) {
        // Ignore if file doesn't exist yet
      }
    }

    console.log('\nGREEN');
    process.exit(0);
  } catch (error) {
    console.error('Test failed:', error.message);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

test();
