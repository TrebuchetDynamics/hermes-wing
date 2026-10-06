// Fixed synthetic Agent-API journey. No inference, runtime access, or credentials.
export function lifecycleReceipt(state) {
  const fixture = state.lifecycle;
  if (!fixture) return { synthetic: false };
  return { synthetic: true, profile_id: 'default', ...fixture,
    runs: [...state.runs.values()].map(({ id, session_id, status, request_id }) => ({
      run_id: id, session_id, profile_id: 'default', status, request_id,
    })),
    sessions: state.sessions.map(session => ({ session_id: session.id,
      messages: session.messages.map(({ id, role, content }) => ({ id, role, content })) })),
  };
}

export async function handleLifecycle(req, res, url, state, json, readJsonBody, reset) {
  const control = '/e2e/hermes/lifecycle';
  if (req.method === 'POST' && url === control) {
    const body = await readJsonBody(req);
    if (!body || Array.isArray(body) || typeof body !== 'object' ||
        Object.keys(body).some(key => key !== 'scenario') ||
        (body.scenario !== undefined && body.scenario !== 'desktop-daily')) {
      return json(res, 400, { error: 'synthetic invalid lifecycle scenario' });
    }
    reset();
    state.lifecycle = { submits: [], approvals: [], stops: [], status_reads: [],
      history_reads: [], event_reads: [], transport_failures: [], unexpected_mutations: [] };
    if (body.scenario === 'desktop-daily') {
      state.modelPicker = true;
      state.rejectModelLock = true;
      state.lifecycle.scenario = body.scenario;
      state.lifecycle.model_locks = [];
    }
    state.sessions.push({ id: 'synthetic-untouched', title: 'Synthetic untouched session',
      source: 'e2e', messages: [{ id: 'untouched', role: 'assistant', content: 'Synthetic isolated history.' }] });
    return json(res, 200, lifecycleReceipt(state));
  }
  if (req.method === 'GET' && url === control) return json(res, 200, lifecycleReceipt(state));
  const fixture = state.lifecycle;
  if (!fixture) return false;
  function record(key, value) {
    if (fixture[key].length >= 128) throw new Error('synthetic receipt bound');
    fixture[key].push(value);
  }
  function terminal(run, status, content) {
    run.status = status;
    state.sessions.find(s => s.id === run.session_id).messages.push({
      id: `canonical_${run.id}`, role: 'assistant', content,
    });
  }
  if (req.method === 'POST' && url === `${control}/terminal`) {
    const body = await readJsonBody(req);
    const run = state.runs.get(body.run_id);
    if (!run || run.status !== 'stopping') return json(res, 409, { error: 'synthetic run is not stopping' });
    terminal(run, 'cancelled', 'Synthetic canonical stopped outcome.');
    return json(res, 200, lifecycleReceipt(state));
  }
  if (req.method === 'POST' && url === `${control}/recover`) {
    fixture.transport_unavailable = false;
    return json(res, 200, lifecycleReceipt(state));
  }
  const profile = new URL(req.url, 'http://fixture.invalid').searchParams.get('profile');
  // Keep the daily model exception on the exact owner, never inventory position.
  if (fixture.scenario === 'desktop-daily' && req.method === 'POST' &&
      url === '/api/sessions/e2e-hermes-session/model') {
    if (profile !== 'default') return json(res, 403, { error: 'synthetic profile mismatch' });
    const body = await readJsonBody(req);
    const { provider, model } = body ?? {};
    if (!body || Object.keys(body).some(key => !['provider', 'model'].includes(key)) ||
        !['alpha', 'beta', 'gamma'].includes(provider) ||
        !(model === 'shared' || Array.from({ length: 100 }, (_, i) => `${provider}/model-${i}`).includes(model))) {
      return json(res, 400, { error: 'synthetic invalid identity' });
    }
    const session = state.sessions.find(item => item.id === 'e2e-hermes-session');
    if (!session || fixture.model_locks.length >= 128) {
      return json(res, 409, { error: 'synthetic model lock bound' });
    }
    const rejected = state.rejectModelLock;
    record('model_locks', { profile_id: profile, session_id: session.id, provider, model,
      status: rejected ? 'rejected' : 'accepted' });
    state.modelLocks.push({ provider, model });
    if (rejected) {
      state.rejectModelLock = false;
      return json(res, 409, { error: 'synthetic rejection' });
    }
    const runtime = { provider, model, model_lock: 'accepted', route_source: 'session' };
    session.runtime = runtime;
    session.model = model;
    return json(res, 200, { session_id: session.id, runtime });
  }
  const history = url.match(/^\/api\/sessions\/([^/]+)\/messages$/);
  if (history && req.method === 'GET') {
    const session = state.sessions.find(s => s.id === history[1]);
    record('history_reads', { session_id: history[1], profile_id: profile,
      message_ids: session?.messages.map(m => m.id) ?? [] });
    if (fixture.transport_unavailable) return json(res, 503, { error: 'synthetic transport unavailable' });
  }
  if (/^\/(api|v1)\//.test(url) && ['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method) &&
      !/^\/v1\/runs(?:\/[^/]+\/(?:stop|approval))?$/.test(url)) {
    record('unexpected_mutations', { method: req.method, route: url });
    return json(res, 403, { error: 'synthetic unexpected mutation' });
  }
  if (!url.startsWith('/v1/runs')) return false;
  if (profile !== 'default') return json(res, 403, { error: 'synthetic profile mismatch' });
  if (req.method === 'POST' && url === '/v1/runs') {
    const body = await readJsonBody(req);
    const session = state.sessions.find(s => s.id === body.session_id);
    if (!session || session.id === 'synthetic-untouched' || fixture.submits.length >= 5) {
      return json(res, 409, { error: 'synthetic session/submission bound' });
    }
    const id = `run_${state.nextRunId++}`;
    const run = { id, session_id: session.id, profile_id: profile, status: 'running',
      request_id: `approval_${id}`, reply: `Deterministic fixture reply ${fixture.submits.length + 1}.` };
    state.runs.set(id, run);
    record('submits', { run_id: id, session_id: session.id, profile_id: profile,
      input_matches_message: (typeof body.input === 'string' ? body.input : body.input?.at(-1)?.content) === body.message,
      message: body.message, history: body.conversation_history ?? [] });
    session.messages.push({ id: `user_${id}`, role: 'user', content: body.message });
    return json(res, 202, { run_id: id, session_id: session.id, status: 'queued' });
  }
  const match = url.match(/^\/v1\/runs\/([^/]+)(?:\/(events|approval|stop))?$/);
  const run = match && state.runs.get(match[1]);
  if (!run) return json(res, 404, { error: 'synthetic run not found' });
  const owner = { run_id: run.id, session_id: run.session_id, profile_id: profile };
  const action = match[2];
  if (req.method === 'GET' && !action) {
    record('status_reads', { ...owner, status: run.status });
    if (fixture.transport_unavailable) return json(res, 503, { error: 'synthetic transport unavailable' });
    return json(res, 200, { ...owner, status: run.status,
      ...(run.status === 'completed' ? { output: run.reply } : {}) });
  }
  if (req.method === 'GET' && action === 'events') {
    record('event_reads', owner);
    res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-store',
      'Access-Control-Allow-Origin': '*' });
    const event = (name, payload) => res.write(`event: ${name}\ndata: ${JSON.stringify({ ...owner, ...payload })}\n\n`);
    event('message.delta', { delta: 'Synthetic streamed prelude.' });
    event('tool.started', { call_id: `tool_${run.id}`, tool: 'bash', preview: 'synthetic fixture tool' });
    if (run.id === 'run_4') {
      terminal(run, 'failed', 'Synthetic recovered canonical history.');
      fixture.transport_unavailable = true;
      record('transport_failures', { ...owner, status: run.status });
      // Transport EOF is not a run terminal event. Status/history own recovery.
      res.end();
      return;
    }
    run.status = 'waiting_for_approval';
    event('approval.request', { request_id: run.request_id, command: 'synthetic fixture tool',
      description: 'Synthetic fixture approval', choices: ['once', 'deny'] });
    const choice = await new Promise(resolve => {
      run.release = resolve;
      res.once('close', () => resolve('closed'));
    });
    run.release = null;
    if (choice === 'closed' || res.writableEnded) return;
    if (choice === 'stop' || choice === 'reset') { res.end(); return; }
    if (choice === 'deny') {
      terminal(run, 'cancelled', 'Synthetic canonical denied outcome.');
      event('run.cancelled', { status: 'cancelled' });
    } else {
      terminal(run, 'completed', run.reply);
      event('tool.completed', { call_id: `tool_${run.id}`, tool: 'bash', result_text: 'Synthetic tool complete.' });
      event('message.delta', { delta: run.reply });
      event('run.completed', { status: 'completed' });
    }
    res.end('data: [DONE]\n\n');
    return;
  }
  if (req.method === 'POST' && action === 'stop') {
    await readJsonBody(req);
    record('stops', { ...owner, status: 'stopping' });
    run.status = 'stopping';
    run.release?.('stop');
    return json(res, 200, { run_id: run.id, status: 'stopping' });
  }
  if (req.method === 'POST' && action === 'approval') {
    const body = await readJsonBody(req);
    if (!run.release || run.answered || body.request_id !== run.request_id ||
        !['once', 'deny'].includes(body.choice)) return json(res, 409, { error: 'synthetic approval mismatch' });
    run.answered = true;
    record('approvals', { ...owner, request_id: body.request_id, choice: body.choice });
    run.release(body.choice);
    return json(res, 200, { run_id: run.id, choice: body.choice });
  }
  return json(res, 405, { error: 'synthetic method mismatch' });
}
