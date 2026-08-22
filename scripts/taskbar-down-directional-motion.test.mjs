import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const helperPath = path.resolve(
  'entry/src/main/ets/pages/TaskbarDownDirectionalMotion.ets'
);
const pagePath = path.resolve(
  'entry/src/main/ets/pages/TaskbarDownDirectionalPage.ets'
);
const configPath = path.resolve(
  'entry/src/main/ets/pages/config/TaskbarDownConfigPage.ets'
);

function loadHelper() {
  const source = fs.readFileSync(helperPath, 'utf8');
  const jsSource = source
    .replace(/export interface[\s\S]*?\n}\n/g, '')
    .replace(/export function ([A-Za-z0-9_]+)\(/g, 'function $1(')
    .replace(/([A-Za-z0-9_]+): number/g, '$1')
    .replace(/\): TaskbarDownReleaseDirection/g, ')')
    .replace(/\): number/g, ')');
  const context = {};
  vm.createContext(context);
  vm.runInContext(
    `${jsSource}\nthis.taskbarDownReleaseDirection = taskbarDownReleaseDirection;` +
      `this.taskbarDownNoOvershootCoordinate = taskbarDownNoOvershootCoordinate;` +
      `this.taskbarDownHorizontalArrivalEndProgress = taskbarDownHorizontalArrivalEndProgress;` +
      `this.taskbarDownHorizontalDistanceRank = taskbarDownHorizontalDistanceRank;` +
      `this.taskbarDownStaggeredArrivalProgress = taskbarDownStaggeredArrivalProgress;` +
      `this.taskbarDownOpacityColumnIndex = taskbarDownOpacityColumnIndex;` +
      `this.taskbarDownOpacityColumnOrder = taskbarDownOpacityColumnOrder;`,
    context
  );
  return {
    taskbarDownReleaseDirection: context.taskbarDownReleaseDirection,
    taskbarDownNoOvershootCoordinate: context.taskbarDownNoOvershootCoordinate,
    taskbarDownHorizontalArrivalEndProgress: context.taskbarDownHorizontalArrivalEndProgress,
    taskbarDownHorizontalDistanceRank: context.taskbarDownHorizontalDistanceRank,
    taskbarDownStaggeredArrivalProgress: context.taskbarDownStaggeredArrivalProgress,
    taskbarDownOpacityColumnIndex: context.taskbarDownOpacityColumnIndex,
    taskbarDownOpacityColumnOrder: context.taskbarDownOpacityColumnOrder
  };
}

const {
  taskbarDownReleaseDirection,
  taskbarDownNoOvershootCoordinate,
  taskbarDownHorizontalArrivalEndProgress,
  taskbarDownHorizontalDistanceRank,
  taskbarDownStaggeredArrivalProgress,
  taskbarDownOpacityColumnIndex,
  taskbarDownOpacityColumnOrder
} = loadHelper();
const straightDown = taskbarDownReleaseDirection(4, 180, 18);
assert.equal(straightDown.x, 0);
assert.equal(straightDown.y, 1);

const diagonalRight = taskbarDownReleaseDirection(120, 120, 18);
assert.ok(diagonalRight.x > 0);
assert.ok(diagonalRight.y > 0);
assert.ok(Math.abs(Math.hypot(diagonalRight.x, diagonalRight.y) - 1) < 0.000001);

const diagonalLeft = taskbarDownReleaseDirection(-120, 120, 18);
assert.equal(diagonalLeft.x, -diagonalRight.x);
assert.equal(diagonalLeft.y, diagonalRight.y);

const noOvershootSamples = [0, 0.25, 0.5, 0.75, 1]
  .map((progress) => taskbarDownNoOvershootCoordinate(progress, -100));
assert.deepEqual(noOvershootSamples, [-100, -75, -50, -25, 0]);
for (let index = 1; index < noOvershootSamples.length; index += 1) {
  assert.ok(noOvershootSamples[index] >= noOvershootSamples[index - 1]);
  assert.ok(noOvershootSamples[index] <= 0);
}

const leftTouchNear = taskbarDownHorizontalArrivalEndProgress(80, 120, 1000, 0.66);
const leftTouchMiddle = taskbarDownHorizontalArrivalEndProgress(80, 500, 1000, 0.66);
const leftTouchFar = taskbarDownHorizontalArrivalEndProgress(80, 880, 1000, 0.66);
assert.ok(leftTouchNear < leftTouchMiddle);
assert.ok(leftTouchMiddle < leftTouchFar);
assert.ok(leftTouchNear >= 0.66);
assert.ok(leftTouchFar <= 1);

const rightTouchNear = taskbarDownHorizontalArrivalEndProgress(920, 880, 1000, 0.66);
const rightTouchFar = taskbarDownHorizontalArrivalEndProgress(920, 120, 1000, 0.66);
assert.ok(rightTouchNear < rightTouchFar);

assert.equal(taskbarDownHorizontalDistanceRank(0, 0, 1000), 0);
assert.equal(taskbarDownHorizontalDistanceRank(0, 500, 1000), 0.5);
assert.equal(taskbarDownHorizontalDistanceRank(0, 1000, 1000), 1);

assert.equal(taskbarDownHorizontalArrivalEndProgress(100, 100, 1000, 0.35), 0.35);
assert.equal(taskbarDownHorizontalArrivalEndProgress(100, 100, 1000, 0.22), 0.22);
assert.equal(taskbarDownHorizontalArrivalEndProgress(100, 100, 1000, 0.12), 0.12);

assert.equal(taskbarDownStaggeredArrivalProgress(0, 0.25), 0);
assert.equal(taskbarDownStaggeredArrivalProgress(0.25, 0.25), 1);
assert.equal(taskbarDownStaggeredArrivalProgress(0.45, 0.45), 1);
assert.ok(taskbarDownStaggeredArrivalProgress(0.2, 0.45) < 1);

assert.deepEqual(
  [0.1, 0.3, 0.6, 0.9].map((ratio) => taskbarDownOpacityColumnIndex(ratio)),
  [0, 1, 2, 3]
);
assert.deepEqual(
  [0, 1, 2, 3].map((column) => taskbarDownOpacityColumnOrder(0, 1000, column)),
  [0, 1, 2, 3]
);
assert.deepEqual(
  [0, 1, 2, 3].map((column) => taskbarDownOpacityColumnOrder(1000, 1000, column)),
  [3, 2, 1, 0]
);

const pageSource = fs.readFileSync(pagePath, 'utf8');
assert.match(pageSource, /unlockDirectionalPathCoordinate/);
assert.match(pageSource, /unlockDirectionalPathLateralCoordinate/);
assert.match(pageSource, /taskbarDownReleaseDirection/);
assert.doesNotMatch(pageSource, /directionalScaleX|GESTURE_STRETCH|GESTURE_CROSS_COMPRESSION/);
assert.match(pageSource, /x: this\.iconScaleX\([^)]+\),\s*y: this\.iconScale\(/);
assert.match(pageSource, /ICON_CLOSE_Y_AXIS_FOLLOW_RATIO: number = 0\.08/);
assert.match(pageSource, /\(0\.5 - centerXRatio\) \* this\.fullFrameWidth\(\)/);
assert.match(pageSource, /ICON_CLOSE_OFFSET_Y \* \(1 - this\.iconTimelineProgress\)/);
assert.match(pageSource, /ICON_MIN_DISTANCE_RESPONSE: number = 0\.68/);
assert.match(pageSource, /ICON_BOTTOM_TRAVEL_BOOST: number = 0\.18/);
assert.match(pageSource, /ICON_START_OFFSET: number = -110/);
assert.match(pageSource, /ICON_TURN_LATERAL_OFFSET: number = 8/);
assert.match(pageSource, /ICON_MAX_X_COMPRESSION: number = 0\.03/);
assert.match(pageSource, /ICON_CLOSE_END_SCALE: number = 0\.96/);
assert.match(pageSource, /ICON_OVERSHOOT_DISTANCE_SCALE: number = 0\.45/);
assert.match(pageSource, /const compression = \(1 - arrivalProgress\) \* this\.ICON_MAX_X_COMPRESSION/);
assert.doesNotMatch(pageSource, /Math\.sin\(Math\.PI \* arrivalProgress\)/);
assert.match(pageSource, /PANEL_CLOSE_DURATION_MS: number = 420/);
assert.match(pageSource, /OPEN_TAP_MOVE_TOLERANCE: number = 12/);
assert.match(pageSource, /private baseModuleOpacity\(progress: number\): number/);
assert.match(pageSource, /return 1 - Math\.pow\(1 - t, 2\.3\)/);
assert.match(pageSource, /return this\.baseModuleOpacity\(opacityProgress\)/);
assert.match(pageSource, /ICON_OPACITY_MAX_START_DELAY: number = 0\.34/);
assert.match(pageSource, /ICON_OPACITY_REVEAL_DURATION: number = 0\.56/);
assert.match(pageSource, /BACKGROUND_STAGE_DURATION_MS: number = 420/);
assert.match(pageSource, /BACKGROUND_BLUR_STAGE_DURATION_MS: number = 420/);
assert.match(pageSource, /BACKGROUND_EFFECT_END_PROGRESS: number = 0\.82/);
assert.match(pageSource, /BACKGROUND3_END_SCALE: number = 0\.89/);
assert.match(pageSource, /BACKGROUND3_BLUR_PADDING: number = 168/);
const background3BlurLayer = pageSource.match(
  /\/\/ 在屏幕外预留模糊缓冲区[\s\S]*?\.opacity\(this\.backgroundBlurOpacity\(\)\)/
)?.[0] ?? '';
assert.match(background3BlurLayer, /\.blur\(this\.backgroundBlurAmount\(\)\)/);
assert.match(
  background3BlurLayer,
  /this\.background3Scale\(\) \* this\.backgroundBlurLayerScale\(\)/
);
assert.match(
  background3BlurLayer,
  /this\.fullFrameWidth\(\) \+ this\.BACKGROUND3_BLUR_PADDING \* 2/
);
assert.match(background3BlurLayer, /\.renderGroup\(true\)/);
assert.doesNotMatch(background3BlurLayer, /\.clip\(true\)/);
assert.doesNotMatch(background3BlurLayer, /\.borderRadius\(/);
assert.match(pageSource, /this\.playDirectionalIconEntrance\(token\);\s*this\.getUIContext\(\)\.animateTo/);
assert.match(pageSource, /this\.finishOpeningPart\(token, true\)/);
assert.match(pageSource, /this\.finishOpeningPart\(token, false\)/);
assert.match(pageSource, /this\.backgroundBlurProgress = 1/);
assert.match(pageSource, /this\.backgroundBlurProgress = nextProgress/);
assert.match(pageSource, /this\.iconCloseScale = this\.ICON_CLOSE_END_SCALE/);
assert.doesNotMatch(pageSource, /ICON_CLOSE_COMPRESSION_DURATION_MS/);
assert.match(pageSource, /private iconOpacityLayerRank\(/);
assert.match(pageSource, /private iconLayerOpacityProgress\(/);
assert.match(pageSource, /: this\.iconLayerOpacityProgress\(centerXRatio, centerYRatio\)/);
assert.match(pageSource, /if \(this\.isOpenTap\(event\)\) \{\s*this\.animateClosed\(\);\s*return;/);

const configSource = fs.readFileSync(configPath, 'utf8');
assert.match(pageSource, /if \(!this\.staggeredArrival\) \{\s*return 1;/);
assert.match(pageSource, /params\.staggeredArrival === true/);
assert.match(pageSource, /params\.overshootEnabled !== false/);
assert.match(pageSource, /1 - this\.staggerLeadRatio/);
assert.match(pageSource, /params\.staggerLeadRatio, 0, 0\.92/);
assert.match(pageSource, /taskbarDownStaggeredArrivalProgress\(\s*this\.iconTimelineProgress/);
assert.match(pageSource, /ICON_NEAR_START_DISTANCE_SCALE: number = 0\.72/);
assert.match(pageSource, /ICON_FAR_START_DISTANCE_SCALE: number = 1\.24/);
assert.match(pageSource, /ICON_NEAR_OVERSHOOT_SCALE: number = 0\.55/);
assert.match(pageSource, /ICON_FAR_OVERSHOOT_SCALE: number = 1\.35/);
assert.match(pageSource, /STAGGERED_ICON_OPACITY_COLUMN_START_GAP: number = 0\.04/);
assert.match(pageSource, /STAGGERED_ICON_OPACITY_REVEAL_DURATION: number = 0\.26/);
assert.match(pageSource, /private staggeredModuleOpacity\(progress: number\): number/);
assert.match(pageSource, /return 1 - Math\.pow\(1 - t, 3\.4\)/);
assert.match(pageSource, /private iconHorizontalDistanceRank\(/);
const opacityLayerRankSource = pageSource.match(
  /private iconOpacityLayerRank\([\s\S]*?\n  }/
)?.[0] ?? '';
const opacityProgressSource = pageSource.match(
  /private iconLayerOpacityProgress\([\s\S]*?\n  }/
)?.[0] ?? '';
assert.doesNotMatch(opacityLayerRankSource, /iconHorizontalDistanceRank/);
assert.doesNotMatch(opacityProgressSource, /iconArrivalEndProgress/);
assert.match(opacityProgressSource, /if \(this\.staggeredArrival\)/);
assert.match(opacityProgressSource, /taskbarDownOpacityColumnIndex\(centerXRatio\)/);
assert.match(opacityProgressSource, /taskbarDownOpacityColumnOrder\(/);
assert.match(opacityProgressSource, /STAGGERED_ICON_OPACITY_COLUMN_START_GAP/);
assert.match(opacityProgressSource, /STAGGERED_ICON_OPACITY_REVEAL_DURATION/);
assert.match(opacityProgressSource, /ICON_OPACITY_REVEAL_DURATION/);
assert.match(pageSource, /if \(this\.staggeredArrival && !this\.closingVertically\) \{\s*return this\.staggeredModuleOpacity/);
assert.match(pageSource, /taskbarDownHorizontalArrivalEndProgress\(\s*this\.dragStartX/);
assert.match(pageSource, /if \(this\.staggeredArrival\) \{\s*return 0;\s*}/);
assert.match(pageSource, /if \(this\.staggeredArrival\) \{\s*this\.releaseDirectionX = 0;\s*this\.releaseDirectionY = 1;/);
assert.match(
  pageSource,
  /if \(this\.staggeredArrival\) \{\s*const distanceScale = this\.lerp\([\s\S]*?return this\.ICON_START_OFFSET \* distanceScale;/
);
assert.match(pageSource, /if \(!this\.overshootEnabled\) \{\s*return taskbarDownNoOvershootCoordinate/);
assert.match(pageSource, /if \(!this\.overshootEnabled\) \{\s*return 0;\s*}/);
assert.doesNotMatch(configSource, /方向曲线 · 同步到达/);
assert.match(configSource, /private staggerPreviewLabel\(name: string, staggerLeadRatio: number\): string/);
assert.match(configSource, /Math\.round\(this\.moduleEnterTotalDurationMs \* staggerLeadRatio\)/);
assert.match(configSource, /`\$\{name\} · 首尾差 \$\{gapMs\}ms`/);
assert.match(configSource, /staggerPreviewLabel\('错峰配比 1', 0\.65\)/);
assert.match(configSource, /staggerPreviewLabel\('错峰配比 2', 0\.78\)/);
assert.match(configSource, /staggerPreviewLabel\('错峰配比 3', 0\.88\)/);
assert.match(configSource, /staggerPreviewLabel\('方向曲线 · 无过冲', 0\.78\)/);
assert.match(configSource, /overshootEnabled: overshootEnabled/);
assert.match(configSource, /staggerLeadRatio: staggerLeadRatio/);
assert.match(configSource, /staggerPreviewLabel\('错峰配比 3', 0\.88\), true, true, 0\.88/);
assert.match(configSource, /staggerPreviewLabel\('方向曲线 · 无过冲', 0\.78\), true, false, 0\.78/);
assert.match(
  configSource,
  /this\.openDirectionalPreviewPage\(staggeredArrival, overshootEnabled, staggerLeadRatio\)/
);

console.log('taskbar-down directional motion tests passed');
