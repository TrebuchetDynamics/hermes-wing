// Fixed deterministic stream: completed reasoning, commentary, adjacent tools,
// human request, then a final answer. No provider or host tool is executed.
const event = (name, payload) => `event: ${name}\ndata: ${JSON.stringify(payload)}\n\n`;

export function writeTranscriptOrderPrelude(res, run) {
  const owner = { run_id: run.id, session_id: run.session_id };
  res.write(event('reasoning.available', { ...owner, text: 'Synthetic ordered reasoning' }));
  res.write(event('message.delta', { ...owner, delta: 'Synthetic ordered commentary' }));
  for (const [tool, id] of [['read_file', 'ordered-read'], ['web_search', 'ordered-search']]) {
    res.write(event('tool.started', { ...owner, tool, tool_call_id: id, preview: 'Synthetic activity' }));
    res.write(event('tool.completed', { ...owner, tool, tool_call_id: id, result_text: 'Synthetic complete' }));
  }
}

export function finishTranscriptOrder(res, run) {
  res.end(event('message.delta', { delta: run.reply }) +
    event('run.completed', { run_id: run.id, session_id: run.session_id, status: 'completed' }) +
    'data: [DONE]\n\n');
}
