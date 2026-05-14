import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const helperPath = path.resolve(
  'entry/src/main/ets/pages/TaskbarUpReleaseMotion.ets'
);
const pagePath = path.resolve(
  'entry/src/main/ets/pages/TaskbarUpPage.ets'
);

function loadHelper() {
  const source = fs.readFileSync(helperPath, 'utf8');
  const withoutInterfaces = source.replace(/export interface[\s\S]*?\n}\n/g, '');
  const jsSource = withoutInterfaces
    .replace(/export const ([A-Za-z0-9_]+): [^=]+ =/g, 'const $1 =')
    .replace(/export function ([A-Za-z0-9_]+)\(([^)]*)\): [^{]+ \{/g, 'function $1($2) {')
    .replace(/\): [A-Za-z0-9_]+ \{/g, ') {')
    .replace(/([A-Za-z0-9_]+): number/g, '$1')
    .replace(/([A-Za-z0-9_]+): boolean/g, '$1')
    .replace(/: TaskbarUpReleaseDurations/g, '');

  const context = {};
  vm.createContext(context);
  vm.runInContext(`${jsSource}
this.taskbarUpReleaseDurations = taskbarUpReleaseDurations;
this.taskbarUpReleaseEaseOut = taskbarUpReleaseEaseOut;
this.taskbarUpReleaseEaseIn = taskbarUpReleaseEaseIn;
this.taskbarUpReleaseForwardControlY = taskbarUpReleaseForwardControlY;
this.taskbarUpReleaseInitialSlope = taskbarUpReleaseInitialSlope;
this.taskbarUpFollowerReleaseMultiplier = taskbarUpFollowerReleaseMultiplier;
this.taskbarUpFollowerReleaseTranslateX = taskbarUpFollowerReleaseTranslateX;`, context);
  return context;
}

const {
  taskbarUpReleaseDurations,
  taskbarUpReleaseEaseOut,
  taskbarUpReleaseEaseIn,
  taskbarUpReleaseForwardControlY,
  taskbarUpReleaseInitialSlope,
  taskbarUpFollowerReleaseMultiplier,
  taskbarUpFollowerReleaseTranslateX
} = loadHelper();

function assertAlmostEqual(actual, expected) {
  assert.ok(Math.abs(actual - expected) < 0.000001, `${actual} !== ${expected}`);
}

const durations = taskbarUpReleaseDurations(1000, 0.3);
assert.equal(durations.forwardMs + durations.returnMs, 1000);
assert.equal(durations.forwardMs, 300);
assert.equal(durations.returnMs, 700);

assert.ok(
  taskbarUpReleaseEaseOut(0.5) > 0.5,
  'right-moving overshoot segment should start fast and slow down'
);
assert.ok(
  taskbarUpReleaseEaseIn(0.5) < 0.5,
  'return segment should start slow and speed up'
);
assert.equal(taskbarUpReleaseEaseOut(0), 0);
assert.equal(taskbarUpReleaseEaseOut(1), 1);
assert.equal(taskbarUpReleaseEaseIn(0), 0);
assert.equal(taskbarUpReleaseEaseIn(1), 1);

assertAlmostEqual(
  taskbarUpReleaseInitialSlope(1, 200, 300, 0.35, 2.4),
  1.5
);
assert.equal(taskbarUpReleaseInitialSlope(0, 200, 300, 0.35, 2.4), 0.35);
assert.equal(taskbarUpReleaseInitialSlope(10, 200, 300, 0.35, 2.4), 2.4);
assertAlmostEqual(taskbarUpReleaseForwardControlY(1.5, 0.24), 0.36);
assert.equal(taskbarUpReleaseForwardControlY(10, 0.24), 1);
assert.equal(taskbarUpReleaseForwardControlY(-1, 0.24), 0);

assert.ok(
  taskbarUpReleaseForwardControlY(2.0, 0.24) > taskbarUpReleaseForwardControlY(0.35, 0.24),
  'release curve should preserve a faster pre-release velocity at the start'
);

assert.equal(taskbarUpFollowerReleaseMultiplier(3, 3, 0.58), 1);
const trailingCard2 = taskbarUpFollowerReleaseMultiplier(2, 3, 0.58);
const trailingCard1 = taskbarUpFollowerReleaseMultiplier(1, 3, 0.58);
const trailingCard0 = taskbarUpFollowerReleaseMultiplier(0, 3, 0.58);
assert.ok(trailingCard2 < 1 && trailingCard2 > 0);
assert.ok(trailingCard1 < trailingCard2 && trailingCard1 > 0);
assert.ok(trailingCard0 < trailingCard1 && trailingCard0 > 0);

const sharedStartX = -260;
const leadOvershootX = 24;
const halfwayFollowerX = taskbarUpFollowerReleaseTranslateX(
  2,
  3,
  0.58,
  sharedStartX,
  leadOvershootX,
  false,
  0.5
);
assertAlmostEqual(
  halfwayFollowerX,
  sharedStartX + (leadOvershootX * trailingCard2 - sharedStartX) * 0.5
);
assert.equal(
  taskbarUpFollowerReleaseTranslateX(2, 3, 0.58, sharedStartX, leadOvershootX, false, 0),
  sharedStartX
);
assertAlmostEqual(
  taskbarUpFollowerReleaseTranslateX(2, 3, 0.58, sharedStartX, leadOvershootX, false, 1),
  leadOvershootX * trailingCard2
);
assertAlmostEqual(
  taskbarUpFollowerReleaseTranslateX(2, 3, 0.58, sharedStartX, leadOvershootX, true, 0),
  leadOvershootX * trailingCard2
);
assert.equal(
  taskbarUpFollowerReleaseTranslateX(2, 3, 0.58, sharedStartX, leadOvershootX, true, 1),
  0
);

const pageSource = fs.readFileSync(pagePath, 'utf8');
assert.ok(
  !pageSource.includes('LEAD_CARD_RELEASE_FRAME_MS'),
  'release motion should use ArkUI animateTo instead of a manual timer frame loop'
);
assert.ok(
  !pageSource.includes('runLeadCardReleaseSegment'),
  'release motion should stay on the framework animation clock'
);
