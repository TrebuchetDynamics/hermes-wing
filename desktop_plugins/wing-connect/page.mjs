import { ROUTES_AREA, SIDEBAR_NAV_AREA, Button, Input } from '@hermes/plugin-sdk';
import { useState } from 'react';
import { jsx, jsxs } from 'react/jsx-runtime';

/* INLINE_QR_GENERATOR */

function gatewayMetadata(origin, profile) {
  // Validate the spelling before URL parsing can silently repair paths or controls.
  if (typeof origin !== 'string' || origin.length > 1024 ||
      !/^https:\/\/[^/\\?#\s@]+\/?$/.test(origin)) {
    throw new Error('Enter an HTTPS root origin without credentials, paths, query or fragment.');
  }
  let url;
  try { url = new URL(origin); } catch (_) {
    throw new Error('Enter a valid HTTPS root origin.');
  }
  if (url.protocol !== 'https:' || !url.hostname || url.username || url.password ||
      url.pathname !== '/' || url.search || url.hash) {
    throw new Error('Enter a valid HTTPS root origin.');
  }
  if (!/^[a-z0-9][a-z0-9_-]{0,63}$/.test(profile)) {
    throw new Error('Enter the exact profile ID: 1–64 lowercase letters, digits, underscores or hyphens, starting with a letter or digit.');
  }
  return JSON.stringify({ type: 'hermes-wing-gateway', version: 1, origin: url.origin, profile });
}

function makeQr(payload) {
  const qr = qrcode(0, 'M');
  qr.addData(payload, 'Byte');
  qr.make();
  const count = qr.getModuleCount();
  const segments = [];
  // Four-module quiet zone is part of the SVG, not a theme-dependent margin.
  for (let row = 0; row < count; row++) {
    for (let col = 0; col < count; col++) {
      if (qr.isDark(row, col)) segments.push(`M${col + 4},${row + 4}h1v1h-1z`);
    }
  }
  return { size: count + 8, path: segments.join('') };
}

function ConnectPhonePage() {
  const [result, setResult] = useState(null);
  function submit(event) {
    event.preventDefault();
    // Read the current form on the deliberate gesture, never a stale render closure.
    const fields = event.currentTarget.elements;
    try {
      const payload = gatewayMetadata(fields.namedItem('origin').value, fields.namedItem('profile').value);
      setResult({ payload, qr: makeQr(payload) });
    } catch (error) {
      setResult({ error: error instanceof Error ? error.message : 'Could not generate the QR. Check the origin and profile ID.' });
    }
  }
  const clear = () => setResult(null);
  return jsxs('section', {
    style: { padding: '24px', maxWidth: '680px', margin: '0 auto', overflow: 'auto', height: '100%', color: 'var(--ui-text-primary)' },
    'aria-label': 'Connect phone to Wing',
    children: [
      jsx('h1', { style: { fontSize: '24px', marginBottom: '12px' }, children: 'Connect phone to Wing' }),
      jsx('p', { children: 'Enter the existing gateway HTTPS origin reachable from your phone and its exact profile ID. This page does not discover, start or expose a gateway, or verify reachability.' }),
      jsx('p', { style: { margin: '12px 0', color: 'var(--ui-text-secondary)' }, children: 'The QR contains connection metadata only, not credentials or authorization. Check the origin on your phone, then sign in through the official gateway. Desktop login is not transferred.' }),
      jsxs('form', { onSubmit: submit, onChange: clear, style: { display: 'grid', gap: '12px' }, children: [
        jsx('label', { htmlFor: 'wing-connect-origin', children: 'Reachable HTTPS root origin' }),
        jsx(Input, { id: 'wing-connect-origin', name: 'origin', type: 'url', required: true, maxLength: 1024, autoComplete: 'off', spellCheck: false, placeholder: 'https://gateway.example', 'aria-describedby': 'wing-connect-origin-help' }),
        jsx('p', { id: 'wing-connect-origin-help', children: 'HTTPS only. No path, query, fragment or username/password. An optional root slash is accepted.' }),
        jsx('label', { htmlFor: 'wing-connect-profile', children: 'Exact profile ID' }),
        jsx(Input, { id: 'wing-connect-profile', name: 'profile', type: 'text', required: true, maxLength: 64, defaultValue: 'default', autoComplete: 'off', autoCapitalize: 'none', spellCheck: false }),
        jsx(Button, { type: 'submit', children: 'Generate QR' }),
      ] }),
      result?.error ? jsx('p', { role: 'alert', children: result.error }) : null,
      result?.qr ? jsxs('div', { 'aria-live': 'polite', style: { marginTop: '20px' }, children: [
        // Fixed black/white are intentional machine-readable QR ink, not themed UI.
        jsxs('svg', { role: 'img', 'aria-label': 'Gateway connection metadata QR; manual details below', viewBox: `0 0 ${result.qr.size} ${result.qr.size}`, width: 320, height: 320, style: { width: '100%', maxWidth: '320px', height: 'auto' }, shapeRendering: 'crispEdges', children: [
          jsx('rect', { width: result.qr.size, height: result.qr.size, fill: '#fff' }),
          jsx('path', { d: result.qr.path, fill: '#000' }),
        ] }),
        jsx('p', { children: 'Scan in Wing. If scanning is unavailable, enter this origin and profile ID manually in Wing, then sign in. These details are not proof of server identity.' }),
        jsx('pre', { tabIndex: 0, 'aria-label': 'Connection metadata for manual entry', style: { whiteSpace: 'pre-wrap', overflowWrap: 'anywhere', userSelect: 'text' }, children: result.payload }),
        jsx(Button, { type: 'button', onClick: clear, children: 'Hide QR' }),
      ] }) : null,
    ],
  });
}

export default {
  id: 'wing-connect',
  name: 'Connect phone to Wing',
  register(ctx) {
    ctx.register({ id: 'page', area: ROUTES_AREA, data: { path: '/wing-connect' }, render: () => jsx(ConnectPhonePage, {}) });
    ctx.register({ id: 'nav', area: SIDEBAR_NAV_AREA, data: { path: '/wing-connect', label: 'Connect phone to Wing', codicon: 'device-mobile' } });
  },
};
