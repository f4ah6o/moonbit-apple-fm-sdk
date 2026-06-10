// Records the ui_dashboard_demo into PNG frames for GIF conversion.
//
// Prereqs: the demo server must be running
//   moon run src/examples/ui_dashboard_demo --target native
// Usage:
//   cd scripts && npm install && node record-demo.mjs
// Frames land in /tmp/demo-frames; convert to GIF with (run from repo root):
//   ffmpeg -y -framerate 6 -i /tmp/demo-frames/frame-%04d.png \
//     -vf "scale=880:-1:flags=lanczos,palettegen" /tmp/palette.png
//   ffmpeg -y -framerate 6 -i /tmp/demo-frames/frame-%04d.png -i /tmp/palette.png \
//     -lavfi "scale=880:-1:flags=lanczos [x]; [x][1:v] paletteuse" docs/demo.gif

import { chromium } from 'playwright-core';
import { globSync } from 'node:fs';
import { mkdirSync, rmSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const URL = 'http://127.0.0.1:8080';
const FRAME_DIR = '/tmp/demo-frames';
const PROMPT = '今月の進捗まとめて。タスク完了率、週ごとの完了タスク数の棒グラフ、残課題リストも';
const FRAME_INTERVAL_MS = 250;
const TAIL_MS = 1500; // keep recording a beat after completion
const TIMEOUT_MS = 60000;

function findChromium() {
  const cache = join(homedir(), 'Library/Caches/ms-playwright');
  const hits = globSync('chromium-*/chrome-mac-arm64/*.app/Contents/MacOS/*', { cwd: cache })
    .filter((p) => !p.includes('Helper'))
    .sort();
  if (hits.length === 0) {
    throw new Error(
      `No cached Chromium under ${cache}. Run: npx playwright install chromium`,
    );
  }
  return join(cache, hits[hits.length - 1]);
}

const executablePath = findChromium();
console.log(`Using Chromium: ${executablePath}`);

rmSync(FRAME_DIR, { recursive: true, force: true });
mkdirSync(FRAME_DIR, { recursive: true });

const browser = await chromium.launch({ executablePath });
const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
await page.goto(URL);

let frame = 0;
const snap = async () => {
  const name = `frame-${String(frame++).padStart(4, '0')}.png`;
  await page.screenshot({ path: join(FRAME_DIR, name) });
};

// a quiet second on the empty page, then "type" the prompt for effect
for (let i = 0; i < 4; i++) await snap();
await page.click('#q');
const typing = page.type('#q', PROMPT, { delay: 25 });
const typeSnaps = (async () => {
  while (frame < 4 + 12) {
    await snap();
    await page.waitForTimeout(FRAME_INTERVAL_MS);
  }
})();
await Promise.all([typing, typeSnaps]);
await snap();

await page.click('#go');

const start = Date.now();
let done = false;
while (Date.now() - start < TIMEOUT_MS) {
  await snap();
  const status = await page.textContent('#status');
  if (!done && (status === '完了' || status.startsWith('エラー'))) {
    done = true;
    const tailFrames = Math.ceil(TAIL_MS / FRAME_INTERVAL_MS);
    for (let i = 0; i < tailFrames; i++) {
      await page.waitForTimeout(FRAME_INTERVAL_MS);
      await snap();
    }
    break;
  }
  await page.waitForTimeout(FRAME_INTERVAL_MS);
}

await browser.close();
if (!done) {
  console.error(`Timed out after ${TIMEOUT_MS}ms — frames kept for inspection`);
  process.exit(1);
}
console.log(`${frame} frames in ${FRAME_DIR} (${((Date.now() - start) / 1000).toFixed(1)}s of generation)`);
