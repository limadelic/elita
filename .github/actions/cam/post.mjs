import { writeFileSync, readFileSync, existsSync } from 'fs';
import { exec } from 'child_process';

async function stop() {
  writeFileSync('/tmp/cam.stop', '');

  return new Promise((resolve) => {
    const timeout = setTimeout(() => resolve(), 120000);
    const check = setInterval(() => {
      if (existsSync('/tmp/cam/greet.webm')) {
        const stat = require('fs').statSync('/tmp/cam/greet.webm');
        if (stat.size > 0) {
          clearTimeout(timeout);
          clearInterval(check);
          resolve();
        }
      }
    }, 500);
  });
}

async function upload() {
  if (process.env.GITHUB_ACTIONS && process.env.GITHUB_REPOSITORY) {
    try {
      await exec('npx @actions/artifact upload-artifact --name brian-cam --path /tmp/cam', (err) => {
        if (err) console.error('Upload failed:', err.message);
      });
    } catch (e) {
      console.error('Upload error:', e.message);
    }
  }
}

async function main() {
  await stop();
  if (existsSync('/tmp/cam.log')) {
    console.log(readFileSync('/tmp/cam.log', 'utf8'));
  }
  await upload();
}

main().catch(() => process.exit(1));
