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
    .replace(/: TaskbarUpCardSwipeDeformation/g, '')
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
this.taskbarUpFollowerReleaseTranslateX = taskbarUpFollowerReleaseTranslateX;
this.taskbarUpCardSwipeDeformation = taskbarUpCardSwipeDeformation;`, context);
  return context;
}

const {
  taskbarUpReleaseDurations,
  taskbarUpReleaseEaseOut,
  taskbarUpReleaseEaseIn,
  taskbarUpReleaseForwardControlY,
  taskbarUpReleaseInitialSlope,
  taskbarUpFollowerReleaseMultiplier,
  taskbarUpFollowerReleaseTranslateX,
  taskbarUpCardSwipeDeformation
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

const neutralSwipe = taskbarUpCardSwipeDeformation(0, 234, 260, 0);
assert.equal(neutralSwipe.rotateYDeg, 0);
assert.equal(neutralSwipe.skewXDeg, 0);
assert.equal(neutralSwipe.scaleX, 1);
assert.equal(neutralSwipe.scaleY, 1);
assert.equal(neutralSwipe.highlightOpacity, 0);
assert.equal(neutralSwipe.shadowOpacity, 0);
assert.equal(neutralSwipe.edgeRadiusOffset, 0);

const rightSwipe = taskbarUpCardSwipeDeformation(117, 234, 260, 0.05);
const leftSwipe = taskbarUpCardSwipeDeformation(-117, 234, 260, -0.05);
assert.ok(rightSwipe.rotateYDeg < 0, 'right drag should tip cards toward the drag direction');
assert.ok(Math.abs(rightSwipe.rotateYDeg) >= 22, 'medium drag should create a stronger visible card bend');
assert.equal(leftSwipe.rotateYDeg, -rightSwipe.rotateYDeg);
assert.equal(rightSwipe.skewXDeg, 0, 'horizontal deformation should not tilt the top/bottom edges');
assert.equal(leftSwipe.skewXDeg, 0, 'horizontal deformation should not tilt the top/bottom edges');
assert.ok(rightSwipe.scaleX > 1, 'right drag should stretch the card horizontally');
assert.ok(rightSwipe.scaleX >= 1.06, 'medium right drag should make the right side visibly extend');
assert.equal(rightSwipe.scaleY, 1, 'right drag should not create vertical top/bottom deformation');
assert.equal(leftSwipe.scaleY, 1, 'left drag should not create vertical top/bottom deformation');
assert.equal(leftSwipe.scaleX, rightSwipe.scaleX);
assert.ok(rightSwipe.originXPercent <= 8, 'right drag should pin the left side so the right edge deforms');
assert.ok(leftSwipe.originXPercent >= 92, 'left drag should pin the right side so the left edge deforms');
assert.ok(rightSwipe.highlightOpacity > 0);
assert.ok(rightSwipe.highlightOpacity >= 0.2, 'medium drag should show stronger light feedback');
assert.equal(rightSwipe.shadowOpacity, 0, 'moving black side shadow should be disabled');
assert.equal(leftSwipe.highlightOpacity, rightSwipe.highlightOpacity);
assert.ok(rightSwipe.highlightOffsetX < 0);
assert.ok(leftSwipe.highlightOffsetX > 0);

const clampedSwipe = taskbarUpCardSwipeDeformation(2000, 234, 260, 8);
assert.ok(Math.abs(clampedSwipe.rotateYDeg) >= 32);
assert.ok(Math.abs(clampedSwipe.rotateYDeg) <= 38);
assert.equal(clampedSwipe.skewXDeg, 0);
assert.ok(clampedSwipe.scaleX >= 1.1);
assert.ok(clampedSwipe.scaleX <= 1.13);
assert.equal(clampedSwipe.scaleY, 1);
assert.ok(clampedSwipe.edgeRadiusOffset >= 14);
assert.ok(clampedSwipe.edgeRadiusOffset <= 16);
assert.ok(Math.abs(clampedSwipe.materialTranslateX) >= 18);
assert.equal(clampedSwipe.shadowOpacity, 0);

const pageSource = fs.readFileSync(pagePath, 'utf8');
assert.ok(
  !pageSource.includes('LEAD_CARD_RELEASE_FRAME_MS'),
  'release motion should use ArkUI animateTo instead of a manual timer frame loop'
);
assert.ok(
  !pageSource.includes('runLeadCardReleaseSegment'),
  'release motion should stay on the framework animation clock'
);
assert.ok(
  pageSource.includes('taskbarUpCardSwipeDeformation'),
  'TaskbarUpPage should drive horizontal card deformation with the shared helper'
);
assert.ok(
  pageSource.includes('.rotate({') && pageSource.includes('swipeDeformation'),
  'TaskbarUpPage should apply a 3D rotation while cards are dragged horizontally'
);
assert.ok(
  pageSource.includes('swipeHighlightOpacity'),
  'TaskbarUpPage should render swipe highlight/shadow feedback from the deformation'
);
assert.ok(
  !pageSource.includes('buildLeftCardPane') && !pageSource.includes('buildRightCardPane'),
  'TaskbarUpPage should keep each card image continuous instead of splitting it into visible panes'
);
assert.ok(
  !pageSource.includes('leftPaneScale') && !pageSource.includes('rightPaneScale'),
  'card side deformation should come from perspective and origin shifts, not hard image splitting'
);
assert.ok(
  pageSource.includes('Image(this.cardImage(index))') && pageSource.includes('.transform3D(this.swipeTransform3D(index))'),
  'TaskbarUpPage should keep one continuous card image and apply a visible 3D matrix bend'
);
assert.ok(
  pageSource.includes("import matrix4 from '@ohos.matrix4';"),
  'TaskbarUpPage should use ArkUI matrix4 for visible horizontal deformation'
);
assert.ok(
  pageSource.includes('swipeTransform3D') && pageSource.includes('.transform3D('),
  'TaskbarUpPage should apply a 3D matrix transform instead of relying only on scale'
);
assert.ok(
  pageSource.includes('matrix4.identity()') && pageSource.includes('.rotate({'),
  'TaskbarUpPage should use matrix rotation for directional horizontal deformation'
);
assert.ok(
  pageSource.includes('.rotate({') && pageSource.includes('centerX: this.swipeMatrixCenterX(index)'),
  'TaskbarUpPage should rotate through the matrix transform around a drag-dependent center'
);
assert.ok(
  pageSource.includes('this.swipeScaleX(index)') && pageSource.includes('centerX: this.swipeOriginX(index)'),
  'TaskbarUpPage should apply horizontal scale from a side anchor so the right/left edge visibly deforms'
);
assert.ok(
  !pageSource.includes('CARD_SWIPE_SHADOW_WIDTH') && !pageSource.includes('swipeShadowOpacity'),
  'TaskbarUpPage should remove the hard moving black side shadow'
);
assert.ok(
  !pageSource.includes('#FF000000'),
  'TaskbarUpPage should not render a hard black swipe shadow block'
);
assert.ok(
  !/private buildCard\(index: number\) \{\s*const /m.test(pageSource),
  'ArkUI @Builder bodies should start with component syntax, not local const declarations'
);
assert.ok(
  !pageSource.includes('.skew('),
  'TaskbarUpPage should avoid skew because the requested deformation is left/right, not top/bottom'
);
const pageMaxOffset = pageSource.match(/CARD_SWIPE_DEFORM_MAX_OFFSET: number = ([0-9.]+)/);
const pageEdgeRatio = pageSource.match(/CARD_SWIPE_EDGE_DEFORM_RATIO: number = ([0-9.]+)/);
assert.ok(pageMaxOffset, 'TaskbarUpPage should expose horizontal deformation travel');
assert.ok(Number(pageMaxOffset[1]) <= 200, 'horizontal swipe deformation should respond faster to the same drag');
assert.ok(pageEdgeRatio, 'TaskbarUpPage should expose edge pull deformation ratio');
assert.ok(Number(pageEdgeRatio[1]) >= 0.3, 'edge pull should produce a more visible deformation');
