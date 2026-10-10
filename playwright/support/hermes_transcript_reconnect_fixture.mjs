// Deterministic Agent-shaped history and run stream. No provider/host execution.
const session = 'synthetic-reconnect';
const hidden = 'Synthetic hidden model context /tmp/synthetic-only';
const event = (name, value) => `event: ${name}\ndata: ${JSON.stringify(value)}\n\n`;
const row = (id, role, content, tool_name) => ({ id, session_id: session, role, content,
  ...(tool_name ? { tool_name } : {}) });
const history = [
  row('canonical-user', 'user', 'Synthetic reconnect request'),
  row('canonical-commentary', 'assistant', 'Synthetic reconnect commentary'),
  row('canonical-read', 'tool', hidden, 'read_file'),
  row('canonical-web', 'tool', hidden, 'web_search'),
  row('canonical-answer', 'assistant', 'Synthetic canonical answer'),
];
let canonical = false;
let mutations = [], reads = [], streams = [], decisions = [];
let nextRun = 1;

export async function handleReconnect(req, res, url, json, readJsonBody) {
  if (url === '/e2e/hermes/transcript-reconnect/reset' && req.method === 'POST') {
    for (const stream of streams) if (!stream.writableEnded) stream.end();
    canonical = false; mutations = []; reads = []; streams = []; decisions = []; nextRun = 1;
    return json(res, 200, { synthetic: true });
  }
  if (url === '/e2e/hermes/transcript-reconnect/recover' && req.method === 'POST') {
    canonical = true;
    // Authoritative completion on the fixture host, independent of client intent.
    return json(res, 200, { synthetic: true, history_ids: history.map(r => r.id) });
  }
  if (url === '/e2e/hermes/transcript-reconnect/receipt' && req.method === 'GET') {
    return json(res, 200, { synthetic: true, canonical, reads, mutations, decisions,
      prompts: mutations.filter(r => r.path === '/v1/runs').length,
      stops: mutations.filter(r => r.path.endsWith('/stop')).length,
      history_ids: canonical ? history.map(r => r.id) : [] });
  }
  if (url === '/api/sessions' && req.method === 'GET') {
    return json(res, 200, { object: 'list', data: [{ id: session, source: 'synthetic', title: 'Synthetic reconnect' }] });
  }
  if (url === `/api/sessions/${session}/messages` && req.method === 'GET') {
    reads.push({ path: url, canonical });
    return json(res, 200, { object: 'list', session_id: session, data: canonical ? history : [],
      pagination: { limit: 500, offset: 0, order: 'latest', returned: canonical ? history.length : 0 } });
  }
  if (url === '/v1/runs' && req.method === 'POST') {
    const body = await readJsonBody(req);
    mutations.push({ method: req.method, path: url, session_id: body.session_id, message: body.message });
    return json(res, 200, { run_id: `run_${nextRun++}`, session_id: session });
  }
  if (/^\/v1\/runs\/run_\d+$/.test(url) && req.method === 'GET') {
    return json(res, 200, { run_id: url.split('/').at(-1), session_id: session, status: canonical ? 'completed' : 'running' });
  }
  if (/^\/v1\/runs\/run_\d+\/events$/.test(url) && req.method === 'GET') {
    const run_id = url.split('/')[3];
    streams.push(res);
    res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-store' });
    const owner = { run_id, session_id: session };
    res.write(event('message.delta', { ...owner, delta: 'Synthetic reconnect commentary' }));
    for (const tool of ['read_file', 'web_search']) {
      res.write(event('tool.started', { ...owner, tool, tool_call_id: tool }));
      res.write(event('tool.completed', { ...owner, tool, tool_call_id: tool, result_text: hidden }));
    }
    res.write(event('approval.request', { ...owner, command: 'synthetic', description: 'Synthetic pending approval', choices: ['once', 'deny'] }));
    return true;
  }
  if (/^\/v1\/runs\/run_\d+\/(approval|stop)$/.test(url) && req.method === 'POST') {
    const body = await readJsonBody(req);
    mutations.push({ method: req.method, path: url });
    if (url.endsWith('/approval')) {
      decisions.push(body.choice ?? body.decision);
      const stream = streams.at(-1);
      if (stream && !stream.writableEnded) stream.end(event('message.delta', { delta: 'Synthetic current answer' }) +
        event('run.completed', { run_id: url.split('/')[3], session_id: session, status: 'completed' }) + 'data: [DONE]\n\n');
    }
    return json(res, 200, {});
  }
  return false;
}
