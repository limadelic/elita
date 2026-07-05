import { writeFileSync } from 'fs';
import { extract } from './tree.js';

const paths = {
  content: '/tmp/silk-content.txt',
  elements: '/tmp/silk-elements.txt',
  screenshot: '/tmp/silk-screenshot.png'
};

export const save = async (page) => {
  const content = await page.evaluate(() => {
    const clone = document.body.cloneNode(true);
    clone.querySelectorAll('style, script, noscript').forEach(el => el.remove());
    return clone.innerText;
  });
  const snap = await page.accessibility.snapshot();
  const { list, selectors } = extract(snap);
  const screenshot = await page.screenshot();

  writeFileSync(paths.content, content);
  writeFileSync(paths.elements, list);
  writeFileSync(paths.screenshot, screenshot);

  return { elements: list, selectors };
};

export const result = () => `Content: ${paths.content}\nElements: ${paths.elements}\nScreenshot: ${paths.screenshot}`;
