import test from "node:test";
import assert from "node:assert/strict";
import { readmeTranscriptClip } from "../../scripts/support/readme_transcript_crop.mjs";

const viewport = { width: 1000, height: 800 };
const story = [
  { x: 261, y: 258, width: 715, height: 75 },
  { x: 261, y: 333, width: 560, height: 72 },
  { x: 261, y: 405, width: 715, height: 89 },
];
function contains(clip, box) {
  assert.ok(clip.x <= box.x && clip.y <= box.y);
  assert.ok(clip.x + clip.width >= box.x + box.width);
  assert.ok(clip.y + clip.height >= box.y + box.height);
}

test("frames the complete prompt, activity and summary within the fixed showcase", () => {
  const clip = readmeTranscriptClip({ viewport, boxes: story });
  story.forEach((box) => contains(clip, box));
  assert.ok(clip.width <= 750 && clip.height <= 310);
  assert.ok(clip.x < 261, "retain padding before the first message character");
  assert.ok(clip.y + clip.height < 512, "exclude the unrelated composer guidance below the story");
});
test("follows translated layout instead of a historical screen origin", () => {
  const boxes = story.map((box) => ({ ...box, x: box.x - 180, y: box.y - 120 }));
  const clip = readmeTranscriptClip({ viewport, boxes });
  boxes.forEach((box) => contains(clip, box));
  assert.ok(clip.x < 81 && clip.y < 138);
});
test("rounding and viewport-edge padding cannot cut fractional content", () => {
  const boxes = [{ x: 0.25, y: 0.75, width: 701.2, height: 200.6 }];
  const clip = readmeTranscriptClip({ viewport, boxes });
  boxes.forEach((box) => contains(clip, box));
  assert.equal(clip.x, 0); assert.equal(clip.y, 0);
});
test("rejects the current full-width 1280px transcript instead of silently cropping its left", () => {
  assert.throws(() => readmeTranscriptClip({
    viewport: { width: 1280, height: 800 },
    boxes: story.map((box) => ({ ...box, width: 995 })),
  }), /does not fit/);
});
test("rejects content taller than the published frame", () => {
  assert.throws(() => readmeTranscriptClip({ viewport, boxes: [{ x: 20, y: 20, width: 500, height: 350 }] }), /does not fit/);
});
test("rejects absent, offscreen and invalid semantic bounds", () => {
  for (const boxes of [[], [null], [{ x: -1, y: 1, width: 10, height: 10 }], [{ x: 1, y: 1, width: Infinity, height: 10 }], [{ x: 900, y: 1, width: 200, height: 10 }]]) {
    assert.throws(() => readmeTranscriptClip({ viewport, boxes }));
  }
});
