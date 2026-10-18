// Build/readback tooling only: this module is not copied into the public site.
import { createHash } from "node:crypto";
import { readFile, readdir, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { setTimeout as delay } from "node:timers/promises";

function fingerprint(bytes) {
  return { bytes: bytes.length, sha256: createHash("sha256").update(bytes).digest("hex") };
}

export async function stampArtifact(directory, revision) {
  if (!/^[a-f0-9]{40}$/.test(revision ?? "")) throw new Error("Expected a full Git revision");
  const paths = [
    "index.html", "styles.css",
    "app/index.html", "app/flutter_bootstrap.js", "app/flutter.js", "app/main.dart.js",
    ...(await readdir(join(directory, "assets"))).map((name) => `assets/${name}`),
  ].sort();
  const files = {};
  for (const path of paths) files[path] = fingerprint(await readFile(join(directory, path)));
  await writeFile(join(directory, "artifact.json"), `${JSON.stringify({ revision, files }, null, 2)}\n`);
}

export async function verifyArtifact(manifestPath, root, { attempts = 6, delayMs = 10000 } = {}) {
  const expectedBytes = await readFile(manifestPath);
  const expected = JSON.parse(expectedBytes);
  const base = new URL(root.endsWith("/") ? root : `${root}/`);
  async function get(path) {
    const url = new URL(path, base);
    url.searchParams.set("revision", expected.revision);
    const response = await fetch(url, {
      headers: { "Cache-Control": "no-cache" }, signal: AbortSignal.timeout(10000),
      redirect: "error",
    });
    if (!response.ok) throw new Error(`${path}: HTTP ${response.status}`);
    return Buffer.from(await response.arrayBuffer());
  }
  for (let attempt = 1; attempt <= attempts; attempt++) {
    try {
      if (!(await get("artifact.json")).equals(expectedBytes)) throw new Error("artifact.json differs from candidate");
      for (const [path, expectedHash] of Object.entries(expected.files)) {
        const actual = fingerprint(await get(path));
        if (actual.bytes !== expectedHash.bytes || actual.sha256 !== expectedHash.sha256) {
          throw new Error(`${path}: candidate digest mismatch`);
        }
      }
      console.log(`Verified exact Pages candidate ${expected.revision} (${Object.keys(expected.files).length} entry/asset digests)`);
      return;
    } catch (error) {
      if (attempt === attempts) throw new Error(`Pages freshness failed after ${attempts} attempts: ${error.message}`);
      console.warn(`Pages propagation attempt ${attempt}/${attempts}: ${error.message}`);
      await delay(delayMs);
    }
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const [command, path, value] = process.argv.slice(2);
  if (command === "stamp" && path && value) await stampArtifact(path, value);
  else if (command === "verify" && path && value) await verifyArtifact(path, value);
  else throw new Error("Usage: node site/pages-artifact.mjs stamp <artifact-dir> <revision> | verify <artifact.json> <base-url>");
}
