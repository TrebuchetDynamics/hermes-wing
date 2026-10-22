// Build-time only. The disk plugin needs only plugin.js, not Node or this file.
import { readFileSync, writeFileSync } from 'node:fs';
const read = path => readFileSync(new URL(path, import.meta.url), 'utf8');
const vendor = read('./vendor/qrcode-generator.js');
const license = read('./vendor/LICENSE');
const page = read('./page.mjs');
const umd = '\n(function (factory) {';
if (!vendor.includes(umd)) throw new Error('Unexpected QR vendor wrapper');
const inline = `/*\nVendored qrcode-generator 1.4.4; UMD export removed for inline ESM.\n${license}\n*/\n${vendor.slice(0, vendor.indexOf(umd))}`;
const output = page.replace('/* INLINE_QR_GENERATOR */', () => inline);
if (process.argv.includes('--check')) {
  if (read('./plugin.js') !== output) throw new Error('plugin.js is stale: run node desktop_plugins/wing-connect/build.mjs');
} else {
  writeFileSync(new URL('./plugin.js', import.meta.url), output);
}
