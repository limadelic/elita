#!/usr/bin/env node

const { chromium } = require('/opt/homebrew/lib/node_modules/playwright');
const readline = require('readline');

let browser = null;
let page = null;
let ready = false;

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

process.stdin.on('end', async () => {
  if (browser) await browser.close();
  process.exit(0);
});

async function init() {
  browser = await chromium.launch({ headless: false });
  page = await browser.newPage();
  ready = true;
  console.log(JSON.stringify({ status: 'ready' }));
}

async function handle(command) {
  if (!ready) {
    return { status: 'error', message: 'not ready' };
  }

  const { action, params } = command;

  switch (action) {
    case 'navigate':
      await page.goto(params.url);
      return { status: 'ok', url: page.url() };

    case 'content':
      const content = await page.content();
      return { status: 'ok', content };

    case 'snapshot':
      const snapshot = await page.accessibility.snapshot();
      return { status: 'ok', snapshot: JSON.stringify(snapshot) };

    case 'click':
      await page.click(params.selector, { timeout: 5000 });
      if (params.wait) {
        await page.waitForTimeout(params.wait);
      }
      return { status: 'ok' };

    case 'type':
      await page.type(params.selector, params.text, { timeout: 5000 });
      if (params.wait) {
        await page.waitForTimeout(params.wait);
      }
      return { status: 'ok' };

    case 'press':
      await page.keyboard.press(params.key);
      if (params.wait) {
        await page.waitForTimeout(params.wait);
      }
      return { status: 'ok' };

    case 'screenshot':
      const screenshot = await page.screenshot({ type: 'png', encoding: 'base64' });
      return { status: 'ok', screenshot };

    case 'close':
      await browser.close();
      return { status: 'ok' };

    default:
      return { status: 'error', message: `unknown action: ${action}` };
  }
}

rl.on('line', async (line) => {
  try {
    const command = JSON.parse(line);
    const result = await handle(command);
    console.log(JSON.stringify(result));
  } catch (error) {
    console.log(JSON.stringify({ status: 'error', message: error.message, stack: error.stack }));
  }
});

init().catch(error => {
  console.log(JSON.stringify({ status: 'error', message: error.message }));
  process.exit(1);
});
