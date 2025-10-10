import exec from './exec.js';

export const description = {
  name: 'browse',
  description: 'Browser automation',
  inputSchema: {
    type: 'object',
    properties: {
      action: { type: 'string', enum: ['navigate', 'snapshot', 'click', 'type', 'press'] },
      url: { type: 'string' },
      index: { type: 'number' },
      text: { type: 'string' },
      key: { type: 'string' }
    },
    required: ['action']
  }
};

export { exec };
