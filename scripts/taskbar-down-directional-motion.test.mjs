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
  vm.runInContext(`${jsSource}\nthis.taskbarDownReleaseDirection = taskbarDownReleaseDirection;`, context);
  return context.taskbarDownReleaseDirection;
}

const taskbarDownReleaseDirection = loadHelper();
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

const pageSource = fs.readFileSync(pagePath, 'utf8');
assert.match(pageSource, /unlockDirectionalPathCoordinate/);
assert.match(pageSource, /unlockDirectionalPathLateralCoordinate/);
assert.match(pageSource, /taskbarDownReleaseDirection/);
assert.doesNotMatch(pageSource, /directionalScaleX|GESTURE_STRETCH|GESTURE_CROSS_COMPRESSION/);
assert.match(pageSource, /x: this\.iconScaleX\([^)]+\),\s*y: this\.iconScale\(/);
assert.match(pageSource, /if \(this\.closingVertically\) \{\s*return 0;\s*}/);
assert.match(pageSource, /ICON_CLOSE_OFFSET_Y \* \(1 - this\.iconTimelineProgress\)/);
assert.match(pageSource, /ICON_MIN_DISTANCE_RESPONSE: number = 0\.68/);
assert.match(pageSource, /ICON_BOTTOM_TRAVEL_BOOST: number = 0\.18/);
assert.match(pageSource, /ICON_START_OFFSET: number = -110/);
assert.match(pageSource, /ICON_TURN_LATERAL_OFFSET: number = 8/);
assert.match(pageSource, /ICON_MAX_X_COMPRESSION: number = 0\.06/);
assert.match(pageSource, /ICON_OVERSHOOT_DISTANCE_SCALE: number = 0\.70/);
assert.match(pageSource, /const compression = \(1 - arrivalProgress\) \* this\.ICON_MAX_X_COMPRESSION/);
assert.doesNotMatch(pageSource, /Math\.sin\(Math\.PI \* arrivalProgress\)/);
assert.match(pageSource, /PANEL_CLOSE_DURATION_MS: number = 280/);
assert.match(pageSource, /OPEN_TAP_MOVE_TOLERANCE: number = 12/);
assert.match(pageSource, /private baseModuleOpacity\(progress: number\): number/);
assert.match(pageSource, /return 1 - Math\.pow\(1 - t, 2\.3\)/);
assert.match(pageSource, /return this\.baseModuleOpacity\(opacityProgress\)/);
assert.match(pageSource, /ICON_OPACITY_MAX_START_DELAY: number = 0\.34/);
assert.match(pageSource, /ICON_OPACITY_REVEAL_DURATION: number = 0\.56/);
assert.match(pageSource, /BACKGROUND_STAGE_DURATION_MS: number = 260/);
assert.match(pageSource, /BACKGROUND_BLUR_STAGE_DURATION_MS: number = 420/);
assert.match(pageSource, /BACKGROUND_EFFECT_END_PROGRESS: number = 0\.82/);
assert.match(pageSource, /BACKGROUND3_END_SCALE: number = 0\.92/);
assert.match(pageSource, /this\.playDirectionalIconEntrance\(token\);\s*this\.getUIContext\(\)\.animateTo/);
assert.match(pageSource, /this\.finishOpeningPart\(token, true\)/);
assert.match(pageSource, /this\.finishOpeningPart\(token, false\)/);
assert.match(pageSource, /this\.backgroundBlurProgress = 1/);
assert.match(pageSource, /this\.backgroundBlurProgress = nextProgress/);
assert.match(pageSource, /private iconOpacityLayerRank\(/);
assert.match(pageSource, /private iconLayerOpacityProgress\(/);
assert.match(pageSource, /: this\.iconLayerOpacityProgress\(centerXRatio, centerYRatio\)/);
assert.match(pageSource, /if \(this\.isOpenTap\(event\)\) \{\s*this\.animateClosed\(\);\s*return;/);

const configSource = fs.readFileSync(configPath, 'utf8');
assert.match(pageSource, /if \(!this\.staggeredArrival\) \{\s*return 1;/);
assert.match(pageSource, /params\.staggeredArrival === true/);
assert.match(configSource, /方向曲线 · 同步到达/);
assert.match(configSource, /方向曲线 · 错峰到达/);
assert.match(configSource, /this\.openDirectionalPreviewPage\(staggeredArrival\)/);

console.log('taskbar-down directional motion tests passed');
