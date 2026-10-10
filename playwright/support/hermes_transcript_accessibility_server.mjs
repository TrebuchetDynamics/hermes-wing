// Generate an ignored, isolated server composition; never edit serve_web.mjs.
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const root = process.cwd();
const scratch = path.join(root, '.dart_tool/transcript-accessibility');
fs.mkdirSync(scratch, { recursive: true });
let source = fs.readFileSync(path.join(root, 'serve_web.mjs'), 'utf8');
source = source.replaceAll("'./playwright/support/", `'${pathToFileURL(path.join(root, 'playwright/support/')).href}`);
source = source.replace('const __dirname = path.dirname(fileURLToPath(import.meta.url));', `const __dirname = ${JSON.stringify(root)};`);
source = source.replace('const root = path.resolve(__dirname, "build/web");', 'const root = path.resolve(__dirname, ".dart_tool/transcript-accessibility/wing/build/web");');
const marker = '  if (req.method === "OPTIONS") return json(res, 204, {});';
if (!source.includes(marker)) throw new Error('Shared fixture hook changed');
source = `import { handleTranscriptAccessibility } from ${JSON.stringify(pathToFileURL(path.join(root, 'playwright/support/hermes_transcript_accessibility_fixture.mjs')).href)};\n` +
  source.replace(marker, `${marker}\n  const reconnect = await handleTranscriptAccessibility(req, res, url, json, readJsonBody);\n  if (reconnect !== false) return reconnect;`);
const snapshot = path.join(scratch, 'server.mjs');
fs.writeFileSync(snapshot, source);
await import(pathToFileURL(snapshot).href);
