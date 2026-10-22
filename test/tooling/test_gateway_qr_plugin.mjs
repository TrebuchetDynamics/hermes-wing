// Run: node --experimental-vm-modules --test test/tooling/test_gateway_qr_plugin.mjs
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';
import vm from 'node:vm';

const file = new URL('../../desktop_plugins/wing-connect/plugin.js', import.meta.url);

async function load() {
  const source = readFileSync(file, 'utf8');
  let state;
  const element = (type, props) => ({ type, props });
  const context = vm.createContext({ URL }); // No DOM, network, storage, process or credential bridge.
  const modules = {
    '@hermes/plugin-sdk': { ROUTES_AREA: 'routes', SIDEBAR_NAV_AREA: 'sidebar.nav', Input: 'input', Button: 'button' },
    react: { useState: initial => [state ?? initial, value => { state = value; }] },
    'react/jsx-runtime': { jsx: element, jsxs: element },
  };
  const plugin = new vm.SourceTextModule(source, { context });
  await plugin.link(name => {
    assert.ok(Object.hasOwn(modules, name), `Forbidden import: ${name}`);
    const values = modules[name];
    return new vm.SyntheticModule(Object.keys(values), function () {
      for (const [key, value] of Object.entries(values)) this.setExport(key, value);
    }, { context });
  });
  await plugin.evaluate();
  const contributions = [];
  plugin.namespace.default.register({ register: value => contributions.push(value) });
  function expand(node) {
    if (!node || typeof node !== 'object') return node;
    if (typeof node.type === 'function') return expand(node.type(node.props));
    return { ...node, props: { ...node.props, children: [node.props?.children].flat().map(expand) } };
  }
  const render = () => expand(contributions.find(c => c.area === 'routes').render());
  function nodes(tree, type) {
    if (!tree || typeof tree !== 'object') return [];
    return [...(tree.type === type ? [tree] : []), ...tree.props.children.flatMap(x => nodes(x, type))];
  }
  function submit(origin, profile = 'default') {
    nodes(render(), 'form')[0].props.onSubmit({ preventDefault() {}, currentTarget: {
      elements: { namedItem: name => ({ value: name === 'origin' ? origin : profile }) },
    } });
    return render();
  }
  return { plugin: plugin.namespace.default, contributions, render, submit, nodes, source };
}

test('self-contained SDK page emits only strict gateway metadata', async () => {
  const app = await load();
  assert.equal(app.plugin.id, 'wing-connect');
  assert.equal(app.contributions.length, 2);
  assert.equal(app.contributions.find(c => c.area === 'sidebar.nav').data.label, 'Connect phone to Wing');
  assert.equal(app.nodes(app.render(), 'svg').length, 0);
  const tree = app.submit('https://gateway.example:8443/', 'exact_profile-1');
  const payload = JSON.parse(app.nodes(tree, 'pre')[0].props.children.join(''));
  assert.deepEqual(payload, { type: 'hermes-wing-gateway', version: 1, origin: 'https://gateway.example:8443', profile: 'exact_profile-1' });
  assert.equal(app.nodes(tree, 'svg').length, 1);
});

test('rejects unsafe origins and malformed exact profile IDs without echoing input', async () => {
  const app = await load();
  const origins = ['http://gateway.example', 'https://a:b@gateway.example', 'https://@gateway.example', 'https://gateway.example/path', 'https://gateway.example/?', 'https://gateway.example/#', 'https://gateway.example/..', 'https://gateway.example\\evil', ' https://gateway.example', 'https://gate\nway.example', 'https://gateway.example:99999', 'https://'];
  for (const origin of origins) {
    const tree = app.submit(origin);
    assert.equal(app.nodes(tree, 'svg').length, 0, origin);
    assert.ok(app.nodes(tree, 'p').some(n => n.props.role === 'alert'), origin);
  }
  for (const profile of ['', 'Default', '../default', 'default ', 'default\n', '-default', 'a'.repeat(65)]) {
    const tree = app.submit('https://gateway.example', profile);
    assert.equal(app.nodes(tree, 'svg').length, 0, JSON.stringify(profile));
    assert.ok(app.nodes(tree, 'p').some(n => n.props.role === 'alert'));
  }
});

test('editing or hiding clears previous metadata and QR, even after rapid submissions', async () => {
  const app = await load();
  let tree = app.submit('https://first.example');
  app.nodes(tree, 'form')[0].props.onChange();
  assert.equal(app.nodes(app.render(), 'svg').length, 0);
  app.submit('https://second.example', 'second');
  tree = app.submit('https://third.example', 'third');
  assert.equal(JSON.parse(app.nodes(tree, 'pre')[0].props.children.join('')).profile, 'third');
  app.nodes(tree, 'button').find(n => n.props.children.includes('Hide QR')).props.onClick();
  assert.equal(app.nodes(app.render(), 'pre').length, 0);
  app.submit('https://valid.example');
  assert.equal(app.nodes(app.submit('not-an-origin'), 'svg').length, 0);
});

test('rendered SVG modules decode to the exact JSON offline with zbar', async () => {
  const app = await load();
  for (const [origin, profile] of [['https://gateway.example', 'default'], ['https://[2001:db8::1]:8443', 'a'.repeat(64)], ['https://' + 'a'.repeat(60) + '.example', 'profile_123']]) {
    const tree = app.submit(origin, profile);
    const svg = app.nodes(tree, 'svg')[0];
    assert.ok(svg, 'QR generated');
    const size = Number(svg.props.viewBox.split(' ').at(-1));
    const scale = 6;
    const width = size * scale;
    const pixels = Buffer.alloc(width * width, 255);
    const path = app.nodes(tree, 'path')[0].props.d;
    const modules = [...path.matchAll(/M(\d+),(\d+)h1v1h-1z/g)];
    assert.ok(modules.length > 100);
    for (const [, x, y] of modules) {
      for (let dy = 0; dy < scale; dy++) {
        pixels.fill(0, (Number(y) * scale + dy) * width + Number(x) * scale, (Number(y) * scale + dy) * width + (Number(x) + 1) * scale);
      }
    }
    const decoded = spawnSync('zbarimg', ['--quiet', '--raw', '-'], { input: Buffer.concat([Buffer.from(`P5\n${width} ${width}\n255\n`), pixels]), encoding: 'utf8' });
    assert.equal(decoded.status, 0, `Install zbarimg for independent decode: ${decoded.stderr}`);
    assert.equal(decoded.stdout.trim(), app.nodes(tree, 'pre')[0].props.children.join(''));
  }
});

test('checked-in disk artifact is reproducible and has no host/network dependencies', async () => {
  const app = await load();
  const build = spawnSync(process.execPath, [new URL('../../desktop_plugins/wing-connect/build.mjs', import.meta.url).pathname, '--check'], { encoding: 'utf8' });
  assert.equal(build.status, 0, build.stderr);
  for (const forbidden of [/\bimport\s*\(/, /\bfetch\s*\(/, /\bXMLHttpRequest\b/, /\bWebSocket\b/, /\blocalStorage\b/, /\bsessionStorage\b/, /\bwindow\b/, /\bdocument\b/, /\bhost\s*\./, /\bctx\.(?!register\b)/]) {
    assert.ok(!forbidden.test(app.source), String(forbidden));
  }
});
