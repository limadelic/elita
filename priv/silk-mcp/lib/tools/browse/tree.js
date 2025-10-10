const roles = ['textbox', 'button', 'link', 'combobox', 'searchbox'];

const build = (node) => [
  node.role === 'link' && node.name && `a:has-text('${(node.name.split(' ')[0] || '').slice(0, 16)}')`,
  node.name?.length > 5 && `[aria-label*='${node.name.slice(0, 31)}']`,
  node.role && `[role='${node.role}']`,
  "[data-unknown='true']"
].find(Boolean);

const walk = (node, index, acc) => {
  const add = roles.includes(node.role) && node.name;
  add && acc.push({ index, selector: build(node), desc: `${node.role}: ${node.name}` });
  let current = add ? index + 1 : index;
  for (const child of (node.children || [])) {
    const result = walk(child, current, acc);
    acc = result.acc;
    current = result.nextIndex;
  }
  return { acc, nextIndex: current };
};

export const extract = (data) => {
  const elements = [];
  walk(data, 1, elements);
  return {
    list: elements.map(e => `[${e.index}] ${e.desc}`).join('\n'),
    selectors: elements.reduce((acc, e) => ({ ...acc, [e.index]: e.selector }), {})
  };
};
