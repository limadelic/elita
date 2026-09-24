import { writeFileSync, readFileSync, existsSync, statSync, renameSync } from 'fs';
import { execSync } from 'child_process';
import { DefaultArtifactClient } from '@actions/artifact';

async function stop() {
  writeFileSync('/tmp/cam.stop', '');

  return new Promise((resolve) => {
    const timeout = setTimeout(() => resolve(), 120000);
    const check = setInterval(() => {
      if (existsSync('/tmp/cam/greet.webm')) {
        const stat = statSync('/tmp/cam/greet.webm');
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
  if (!process.env.ACTIONS_RUNTIME_TOKEN) {
    console.log('upload skipped');
    return null;
  }

  const branch = process.env.GITHUB_REF_NAME || 'unknown';
  const slug = branch.replace(/\//g, '-');
  const artifactName = `cam-${slug}`;

  if (existsSync('/tmp/cam/greet.webm')) {
    const freeqPath = '/tmp/cam/freeq.webm';
    renameSync('/tmp/cam/greet.webm', freeqPath);
  }

  const client = new DefaultArtifactClient();
  const result = await client.uploadArtifact(artifactName, ['/tmp/cam/freeq.webm'], '/tmp/cam');
  return result;
}

async function comment(token, url) {
  if (!token) return;
  try {
    execSync(`gh pr comment --body "Video: ${url}"`, {
      env: { ...process.env, GH_TOKEN: token },
      stdio: 'inherit'
    });
  } catch {
    // Silently fail if not in PR context
  }
}

async function main() {
  await stop();
  if (existsSync('/tmp/cam.log')) {
    console.log(readFileSync('/tmp/cam.log', 'utf8'));
  }

  const result = await upload();
  if (result) {
    const token = process.env.INPUT_TOKEN || '';
    const url = `${process.env.GITHUB_SERVER_URL}/${process.env.GITHUB_REPOSITORY}/actions/runs/${process.env.GITHUB_RUN_ID}`;
    await comment(token, url);
  }
}

main().catch(() => process.exit(1));
