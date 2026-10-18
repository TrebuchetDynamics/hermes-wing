import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { join } from "node:path";
import { tmpdir } from "node:os";
import test from "node:test";
import { stampArtifact, verifyArtifact } from "../../site/pages-artifact.mjs";

const revision = "a".repeat(40);
async function fixture(t) {
  const dir = await mkdtemp(join(process.env.TMPDIR ?? process.env.RUNNER_TEMP ?? tmpdir(), "pages-artifact-"));
  t.after(() => rm(dir, { recursive: true, force: true }));
  await mkdir(join(dir, "assets"));
  await mkdir(join(dir, "app"));
  for (const path of ["index.html", "styles.css", "assets/proof.svg", "app/index.html", "app/flutter_bootstrap.js", "app/flutter.js", "app/main.dart.js"]) {
    await writeFile(join(dir, path), `candidate ${path}`);
  }
  return dir;
}

test("stamp binds the revision to actual assembled landing, proof and app bytes", async (t) => {
  const dir = await fixture(t);
  await stampArtifact(dir, revision);
  const manifestPath = join(dir, "artifact.json");
  const first = await readFile(manifestPath, "utf8");
  const manifest = JSON.parse(first);
  assert.equal(manifest.revision, revision);
  assert.equal(Object.keys(manifest.files).length, 7);
  assert.deepEqual(manifest.files["assets/proof.svg"], {
    bytes: Buffer.byteLength("candidate assets/proof.svg"),
    sha256: createHash("sha256").update("candidate assets/proof.svg").digest("hex"),
  });
  await stampArtifact(dir, revision);
  assert.equal(await readFile(manifestPath, "utf8"), first);
  await writeFile(join(dir, "app/main.dart.js"), "changed app");
  await stampArtifact(dir, revision);
  assert.notEqual(await readFile(manifestPath, "utf8"), first);
  await assert.rejects(stampArtifact(dir, "not-a-commit"), /revision/);
  await rm(join(dir, "app/flutter_bootstrap.js"));
  await assert.rejects(stampArtifact(dir, revision), /ENOENT/);
});

test("readback retries stale manifests but rejects mixed, missing and persistently old content", async (t) => {
  const dir = await fixture(t);
  await stampArtifact(dir, revision);
  let mode = "propagating";
  let manifestReads = 0;
  const server = createServer(async (request, response) => {
    const url = new URL(request.url, "http://localhost");
    assert.equal(url.searchParams.get("revision"), revision);
    assert.equal(request.headers["cache-control"], "no-cache");
    const path = url.pathname.replace("/hermes-wing/", "");
    if (path === "artifact.json") manifestReads++;
    if (mode === "old" || (mode === "propagating" && manifestReads === 1)) {
      response.end('{"revision":"old"}');
    } else if (mode === "mixed" && path === "styles.css") {
      response.end("old css");
    } else if (mode === "missing" && path === "app/main.dart.js") {
      response.writeHead(404).end();
    } else {
      response.end(await readFile(join(dir, path)));
    }
  });
  await new Promise((resolve) => server.listen(Number(process.env.AUTOWORK_PORT_BASE ?? 8769), "127.0.0.1", resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const root = `http://127.0.0.1:${server.address().port}/hermes-wing/`;
  const manifest = join(dir, "artifact.json");
  const options = { attempts: 2, delayMs: 1 };
  await verifyArtifact(manifest, root, options);
  assert.equal(manifestReads, 2);
  for (mode of ["mixed", "missing", "old"]) {
    await assert.rejects(verifyArtifact(manifest, root, options), /freshness/);
  }
});
