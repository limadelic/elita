import { init, current, reset } from './session.js';
import { save, result } from './files.js';

let selectors = {};

const wait = async (page) => {
  await page.waitForLoadState('networkidle');
  const data = await save(page);
  selectors = data.selectors;
};

const finish = async () => (await wait(current()), result());

export default async function({ action, url, index, text, key }) {
  try {
    const actions = {
      navigate: async () => {
        const page = await init();
        await page.goto(url);
        await wait(page);
        return result();
      },
      snapshot: () => finish(),
      click: async () => (await current().click(selectors[index], { timeout: 5000 }), finish()),
      type: async () => (await current().type(selectors[index], text, { timeout: 5000, delay: 100 }), finish()),
      press: async () => (await current().keyboard.press(key), finish())
    };
    return await actions[action]();
  } catch (e) {
    reset();
    throw e;
  }
}
