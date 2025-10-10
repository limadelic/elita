import { chromium } from 'playwright';

let browser, page;

export const init = async () => {
  browser = browser || await chromium.launch({ headless: false });
  page = page || await browser.newPage();
  return page;
};

export const current = () => page;

export const reset = () => {
  browser = page = null;
};
