/** Frame complete visible transcript semantics; fail rather than crop text. */
export function readmeTranscriptClip({
  viewport,
  boxes,
  frame = { width: 750, height: 310 },
  padding = 16,
}) {
  if (!boxes.length) throw new Error("No transcript content to frame");
  if (![viewport.width, viewport.height, frame.width, frame.height].every(
    (value) => Number.isFinite(value) && value > 0,
  ) || !Number.isFinite(padding) || padding < 0) {
    throw new Error("Invalid transcript frame dimensions");
  }
  for (const box of boxes) {
    if (!box || ![box.x, box.y, box.width, box.height].every(Number.isFinite) ||
        box.width <= 0 || box.height <= 0 || box.x < 0 || box.y < 0 ||
        box.x + box.width > viewport.width || box.y + box.height > viewport.height) {
      throw new Error("Transcript content is missing or outside the viewport");
    }
  }
  const left = Math.max(0, Math.floor(Math.min(...boxes.map((box) => box.x)) - padding));
  const top = Math.max(0, Math.floor(Math.min(...boxes.map((box) => box.y)) - padding));
  const right = Math.min(viewport.width, Math.ceil(Math.max(...boxes.map((box) => box.x + box.width)) + padding));
  const bottom = Math.min(viewport.height, Math.ceil(Math.max(...boxes.map((box) => box.y + box.height)) + padding));
  const clip = { x: left, y: top, width: right - left, height: bottom - top };
  if (clip.width > frame.width || clip.height > frame.height) {
    throw new Error("Transcript content does not fit the readable showcase frame");
  }
  return clip;
}
