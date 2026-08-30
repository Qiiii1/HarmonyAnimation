import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const helperPath = path.resolve(
  'entry/src/main/ets/pages/UnlockDesktopDirectionalMotion.ets'
);
const pagePath = path.resolve(
  'entry/src/main/ets/pages/UnlockDesktopDirectionalPage.ets'
);
const configPath = path.resolve(
  'entry/src/main/ets/pages/config/UnlockDesktopConfigPage.ets'
);
const routesPath = path.resolve(
  'entry/src/main/resources/base/profile/main_pages.json'
);

function loadHelper() {
  const source = fs.readFileSync(helperPath, 'utf8');
  const withoutInterfaces = source.replace(/export interface[\s\S]*?\n}\n/g, '');
  const jsSource = withoutInterfaces
    .replace(/export function ([A-Za-z0-9_]+)\(/g, 'function $1(')
    .replace(/([A-Za-z0-9_]+): number/g, '$1')
    .replace(/\): UnlockReleaseDirection/g, ')')
    .replace(/\): number/g, ')');

  const context = {};
  vm.createContext(context);
  vm.runInContext(`${jsSource}
this.unlockReleaseDirection = unlockReleaseDirection;
this.unlockDirectionalOvershootDistance = unlockDirectionalOvershootDistance;
this.unlockEaseOutProgress = unlockEaseOutProgress;
this.unlockDirectionalPathCoordinate = unlockDirectionalPathCoordinate;
this.unlockDirectionalPathLateralCoordinate = unlockDirectionalPathLateralCoordinate;
this.unlockModuleDirectionProjection = unlockModuleDirectionProjection;
this.unlockModuleArrivalEndProgress = unlockModuleArrivalEndProgress;
this.unlockModuleArrivalProgress = unlockModuleArrivalProgress;
this.unlockModuleArrivalOvershootScale = unlockModuleArrivalOvershootScale;
this.unlockModuleArrivalStartScale = unlockModuleArrivalStartScale;
this.unlockModuleDistanceFalloff = unlockModuleDistanceFalloff;`, context);
  return context;
}

const {
  unlockReleaseDirection,
  unlockDirectionalOvershootDistance,
  unlockEaseOutProgress,
  unlockDirectionalPathCoordinate,
  unlockDirectionalPathLateralCoordinate,
  unlockModuleDirectionProjection,
  unlockModuleArrivalEndProgress,
  unlockModuleArrivalProgress,
  unlockModuleArrivalOvershootScale,
  unlockModuleArrivalStartScale,
  unlockModuleDistanceFalloff
} = loadHelper();

function assertAlmostEqual(actual, expected) {
  assert.ok(Math.abs(actual - expected) < 0.000001, `${actual} !== ${expected}`);
}

const straightUp = unlockReleaseDirection(4, -180, 18);
assert.equal(straightUp.x, 0);
assert.equal(straightUp.y, -1);

const diagonalRight = unlockReleaseDirection(120, -120, 18);
assert.ok(diagonalRight.x > 0, 'right-up swipe should produce rightward icon travel');
assert.ok(diagonalRight.y < 0, 'right-up swipe should keep upward icon travel');
assertAlmostEqual(Math.sqrt(diagonalRight.x ** 2 + diagonalRight.y ** 2), 1);

const diagonalLeft = unlockReleaseDirection(-120, -120, 18);
assert.equal(diagonalLeft.x, -diagonalRight.x);
assert.equal(diagonalLeft.y, diagonalRight.y);

assert.equal(unlockDirectionalOvershootDistance(0), 48);
assert.equal(unlockDirectionalOvershootDistance(15), 60);
assert.equal(unlockDirectionalOvershootDistance(40), 80);
assert.equal(unlockDirectionalOvershootDistance(80), 80);
assertAlmostEqual(unlockDirectionalOvershootDistance(3, 16, 1.6), 20.8);
assertAlmostEqual(unlockDirectionalOvershootDistance(6, 16, 1.6), 25.6);
assert.equal(unlockDirectionalOvershootDistance(10, 16, 1.6), 32);

assert.equal(unlockEaseOutProgress(0), 0);
assert.equal(unlockEaseOutProgress(1), 1);
const firstQuarterTravel = unlockEaseOutProgress(0.25) - unlockEaseOutProgress(0);
const lastQuarterTravel = unlockEaseOutProgress(1) - unlockEaseOutProgress(0.75);
assert.ok(firstQuarterTravel > lastQuarterTravel * 4, 'the global timeline must clearly decelerate');
const firstFivePercentTravel = unlockEaseOutProgress(0.05) - unlockEaseOutProgress(0);
const lastFivePercentTravel = unlockEaseOutProgress(1) - unlockEaseOutProgress(0.95);
assert.ok(
  firstFivePercentTravel > lastFivePercentTravel * 13,
  'the beginning and ending speed difference must stay pronounced without a harsh launch'
);

let previousEaseStep = Number.POSITIVE_INFINITY;
for (let frame = 1; frame <= 100; frame += 1) {
  const currentProgress = unlockEaseOutProgress(frame / 100);
  const previousProgress = unlockEaseOutProgress((frame - 1) / 100);
  const easeStep = currentProgress - previousProgress;
  assert.ok(easeStep <= previousEaseStep + 0.000001, 'global easing speed must never increase');
  previousEaseStep = easeStep;
}

const moduleCenters = [
  [0.3864, 0.3858],
  [0.3906, 0.5039],
  [0.7196, 0.4502],
  [0.1580, 0.3824],
  [0.1343, 0.5035],
  [0.4996, 0.2052],
  [0.6350, 0.6135],
  [0.3829, 0.6218],
  [0.8451, 0.6132],
  [0.1423, 0.6183],
  [0.4996, 0.8911],
];

function arrivalTimingForDirection(direction) {
  const projections = moduleCenters.map(([centerXRatio, centerYRatio]) =>
    unlockModuleDirectionProjection(centerXRatio, centerYRatio, direction.x, direction.y, 420, 900));
  const minimumProjection = Math.min(...projections);
  const maximumProjection = Math.max(...projections);
  const arrivalEnds = projections.map((projection) => unlockModuleArrivalEndProgress(
    projection,
    minimumProjection,
    maximumProjection,
    0.5
  ));
  assertAlmostEqual(Math.min(...arrivalEnds), 0.5);
  assertAlmostEqual(Math.max(...arrivalEnds), 1);
  for (let firstIndex = 0; firstIndex < projections.length; firstIndex += 1) {
    for (let secondIndex = 0; secondIndex < projections.length; secondIndex += 1) {
      if (projections[firstIndex] > projections[secondIndex] + 0.000001) {
        assert.ok(
          arrivalEnds[firstIndex] > arrivalEnds[secondIndex],
          'an icon farther along the swipe direction must arrive later'
        );
      }
    }
  }
  return arrivalEnds;
}

const straightUpArrivalEnds = arrivalTimingForDirection(straightUp);
assert.ok(
  straightUpArrivalEnds[5] > straightUpArrivalEnds[10],
  'the top icon must arrive after the bottom icon on a straight-up swipe'
);
arrivalTimingForDirection(diagonalRight);
arrivalTimingForDirection(diagonalLeft);
assert.ok(
  unlockModuleDirectionProjection(0.5, 0.2, diagonalRight.x, diagonalRight.y, 420, 900) >
    unlockModuleDirectionProjection(0.9, 0.5, diagonalRight.x, diagonalRight.y, 420, 900),
  'direction projection must use physical screen dimensions on a portrait display'
);
assertAlmostEqual(unlockModuleArrivalEndProgress(0.25, 0, 1, 0.5), 0.5517578125);
assertAlmostEqual(unlockModuleArrivalEndProgress(0.75, 0, 1, 0.5), 0.9482421875);
assert.equal(unlockModuleArrivalProgress(0, 0.5), 0);
assert.equal(unlockModuleArrivalProgress(0.5, 0.5), 1);
assert.equal(unlockModuleArrivalProgress(1, 1), 1);
assert.equal(unlockModuleArrivalProgress(1 / 3, 0.5), unlockEaseOutProgress(1 / 3));
assert.ok(
  unlockModuleArrivalProgress(0.45, 0.5) > unlockModuleArrivalProgress(0.45, 1),
  'an earlier icon must be farther through the same easing curve at the same global time'
);
assertAlmostEqual(unlockModuleArrivalOvershootScale(0.5), 0.25);
assert.equal(unlockModuleArrivalOvershootScale(1), 1);
assertAlmostEqual(unlockModuleArrivalOvershootScale(0.5, 1.5), 0.25);
assert.equal(unlockModuleArrivalOvershootScale(1, 1.5), 1.5);
assertAlmostEqual(unlockModuleArrivalStartScale(0.5), 0.55);
assert.equal(unlockModuleArrivalStartScale(1), 1);

const pathStart = -520;
const pathOvershoot = 60;
const pathTurnProgress = 0.4980680286858419;
const pathTurnLateralOffset = 12;
assertAlmostEqual(
  unlockDirectionalPathCoordinate(0, pathStart, pathOvershoot, pathTurnProgress),
  pathStart
);
assertAlmostEqual(
  unlockDirectionalPathCoordinate(pathTurnProgress, pathStart, pathOvershoot, pathTurnProgress),
  pathOvershoot
);
assertAlmostEqual(
  unlockDirectionalPathCoordinate(1, pathStart, pathOvershoot, pathTurnProgress),
  0
);
const forwardSpatialGain = (pathOvershoot - pathStart) / pathTurnProgress;
const returnSpatialGain = pathOvershoot / (1 - pathTurnProgress);
assert.ok(
  returnSpatialGain < forwardSpatialGain * 0.15,
  'the return must begin much slower than the approach to the overshoot'
);

for (let frameCount = 2; frameCount <= 500; frameCount += 1) {
  let previousDirectional = pathStart;
  let previousLateral = 0;
  let previousAxisStep = Number.POSITIVE_INFINITY;
  let previousTotalStep = Number.POSITIVE_INFINITY;
  let sawReturn = false;
  for (let frame = 1; frame <= frameCount; frame += 1) {
    const timelineProgress = unlockEaseOutProgress(frame / frameCount);
    const directional = unlockDirectionalPathCoordinate(
      timelineProgress,
      pathStart,
      pathOvershoot,
      pathTurnProgress
    );
    const lateral = unlockDirectionalPathLateralCoordinate(
      timelineProgress,
      pathStart,
      pathOvershoot,
      pathTurnLateralOffset,
      pathTurnProgress
    );
    const directionalDelta = directional - previousDirectional;
    const lateralDelta = lateral - previousLateral;
    const axisStep = Math.abs(directionalDelta);
    const totalStep = Math.hypot(directionalDelta, lateralDelta);
    if (directionalDelta < 0) {
      sawReturn = true;
    }
    assert.ok(
      axisStep <= previousAxisStep + 0.000001,
      `gesture-axis speed must not increase at frame ${frame}/${frameCount}`
    );
    assert.ok(
      totalStep <= previousTotalStep + 0.000001,
      `rendered path speed must not increase at frame ${frame}/${frameCount}`
    );
    previousDirectional = directional;
    previousLateral = lateral;
    previousAxisStep = axisStep;
    previousTotalStep = totalStep;
  }
  assert.ok(sawReturn, `frame count ${frameCount} must include the overshoot return`);
}

for (const arrivalEndProgress of [0.5, 0.6, 0.7, 0.85, 1]) {
  const arrivalOvershootScale = unlockModuleArrivalOvershootScale(arrivalEndProgress, 1.5);
  const staggeredPathStart = pathStart * unlockModuleArrivalStartScale(arrivalEndProgress);
  const staggeredPathOvershoot = pathOvershoot * arrivalOvershootScale;
  const staggeredPathTurnLateralOffset = pathTurnLateralOffset * arrivalOvershootScale;
  for (let frameCount = 2; frameCount <= 500; frameCount += 1) {
    let previousDirectional = staggeredPathStart;
    let previousLateral = 0;
    let previousTotalStep = Number.POSITIVE_INFINITY;
    for (let frame = 1; frame <= frameCount; frame += 1) {
      const arrivalProgress = unlockModuleArrivalProgress(frame / frameCount, arrivalEndProgress);
      const directional = unlockDirectionalPathCoordinate(
        arrivalProgress,
        staggeredPathStart,
        staggeredPathOvershoot,
        pathTurnProgress
      );
      const lateral = unlockDirectionalPathLateralCoordinate(
        arrivalProgress,
        staggeredPathStart,
        staggeredPathOvershoot,
        staggeredPathTurnLateralOffset,
        pathTurnProgress
      );
      const totalStep = Math.hypot(
        directional - previousDirectional,
        lateral - previousLateral
      );
      assert.ok(
        totalStep <= previousTotalStep + 0.000001,
        `staggered icon speed must not increase for end ${arrivalEndProgress} at frame ${frame}/${frameCount}`
      );
      previousDirectional = directional;
      previousLateral = lateral;
      previousTotalStep = totalStep;
    }
  }
}

const defaultTotalDurationMs = 750;
const defaultModuleDelayMs = Math.floor(defaultTotalDurationMs * 0.22);
const defaultModuleDurationMs = defaultTotalDurationMs - defaultModuleDelayMs;
assertAlmostEqual(defaultModuleDelayMs + defaultModuleDurationMs * 0.5, 457.5);
assert.equal(defaultModuleDelayMs + defaultModuleDurationMs, defaultTotalDurationMs);

const defaultFrameSteps = [];
let previousDefaultCoordinate = pathStart;
for (let frame = 1; frame <= 70; frame += 1) {
  const coordinate = unlockDirectionalPathCoordinate(
    unlockEaseOutProgress(frame / 70),
    pathStart,
    pathOvershoot,
    pathTurnProgress
  );
  defaultFrameSteps.push(Math.abs(coordinate - previousDefaultCoordinate));
  previousDefaultCoordinate = coordinate;
}
assert.ok(defaultFrameSteps[0] < 29, 'the default launch should stay below 29px per frame');
assert.ok(defaultFrameSteps[22] < 22, 'the approach to overshoot should already be slowing down');
assert.ok(defaultFrameSteps[24] < 2.2, 'the softened return should begin at about 2px per frame');
assert.ok(defaultFrameSteps[69] < 0.09, 'the default final frame should settle almost imperceptibly');

const nearFalloff = unlockModuleDistanceFalloff(200, 820, 250, 260, 245, 500, 420, 900);
const middleFalloff = unlockModuleDistanceFalloff(200, 820, 250, 260, 400, 500, 420, 900);
const farFalloff = unlockModuleDistanceFalloff(200, 820, 250, 260, 700, 500, 420, 900);
assert.ok(nearFalloff > middleFalloff, 'a module near the finger should move more');
assert.ok(middleFalloff > farFalloff, 'distance falloff should reduce remote module travel');
assert.ok(farFalloff >= 0.22, 'remote modules should retain a subtle response');

const pageSource = fs.readFileSync(pagePath, 'utf8');
assert.ok(pageSource.includes("Image($r('app.media.Background5'))"));
assert.ok(pageSource.includes("Image($r('app.media.Background4'))"));
for (let index = 1; index <= 11; index += 1) {
  assert.ok(
    pageSource.includes(`this.buildModule($r('app.media.module${index}'),`),
    `directional unlock page should render module${index}`
  );
}
assert.ok(pageSource.includes('unlockDirectionalPathCoordinate('));
assert.ok(pageSource.includes('unlockDirectionalPathLateralCoordinate('));
assert.ok(pageSource.includes("import { AnimatorResult } from '@kit.ArkUI';"));
assert.ok(pageSource.includes('this.getUIContext().createAnimator({'));
assert.ok(pageSource.includes("easing: 'linear'"));
assert.ok(pageSource.includes('this.moduleTimelineProgress = value;'));
assert.ok(pageSource.includes('unlockModuleArrivalEndProgress('));
assert.ok(pageSource.includes('unlockModuleArrivalProgress('));
assert.ok(pageSource.includes('this.moduleArrivalEndProgress(centerXRatio, centerYRatio)'));
assert.ok(pageSource.includes('this.updateModuleArrivalProjectionRange();'));
assert.ok(pageSource.includes('@State unlockDirectionalStaggeredArrival: boolean = false;'));
assert.ok(pageSource.includes('this.unlockDirectionalStaggeredArrival'));
assert.ok(pageSource.includes('this.getUIContext().getRouter().getParams()'));
assert.ok(pageSource.includes('this.unlockDirectionalStaggeredArrival = params.staggeredArrival === true;'));
assert.ok(!pageSource.includes('modulePathLookup'));
assert.ok(!pageSource.includes('unlockQuadraticPathParameter'));
assert.ok(pageSource.includes('this.moduleAnimator.onFrame = (value: number): void => {'));
assert.ok(pageSource.includes('this.moduleAnimator.play();'));
assert.ok(pageSource.includes('Releasing it here triggers an extra SDK endpoint frame'));
assert.ok(!pageSource.includes('this.moduleAnimator = undefined;\n    };'));
assert.ok(!pageSource.includes('@AnimatableExtend(Image)'));
assert.ok(!pageSource.includes('moduleCurveProgress'));
assert.ok(!pageSource.includes('moduleArcProgress'));
assert.ok(!pageSource.includes('curveOffset'));
assert.ok(pageSource.includes("module7'), 0.6350, 0.6135, 1.15"));
assert.ok(pageSource.includes("module11'), 0.4996, 0.8911, 0.64"));
assert.ok(!pageSource.includes('.motionPath({'));
assert.ok(pageSource.includes('this.moduleDistanceFalloff(centerXRatio, centerYRatio)'));
assert.ok(pageSource.includes('MODULE_START_SCALE: number = 0.88'));
assert.ok(pageSource.includes('MODULE_START_OFFSET: number = -520'));
assert.ok(pageSource.includes('MODULE_TURN_PROGRESS: number = 0.4980680286858419'));
assert.ok(pageSource.includes('MODULE_TURN_LATERAL_OFFSET: number = 12'));
assert.ok(pageSource.includes('MODULE_OVERSHOOT_BASE_DISTANCE: number = 16'));
assert.ok(pageSource.includes('MODULE_OVERSHOOT_DISTANCE_PER_PERCENT: number = 1.6'));
assert.ok(pageSource.includes('MODULE_EARLIEST_ARRIVAL_PROGRESS: number = 0.5'));
assert.ok(pageSource.includes('MODULE_STAGGERED_MAX_OVERSHOOT_SCALE: number = 1.5'));
assert.ok(pageSource.includes('unlockModuleArrivalOvershootScale('));
assert.ok(pageSource.includes(
  'this.unlockDirectionalStaggeredArrival ? this.MODULE_STAGGERED_MAX_OVERSHOOT_SCALE : 1'
));
assert.ok(pageSource.includes('private moduleStartOffsetFor(centerXRatio: number, centerYRatio: number): number'));
assert.ok(pageSource.includes('return this.MODULE_START_OFFSET *'));
assert.ok(pageSource.includes('private moduleMotionDurationMs(): number'));
assert.ok(
  pageSource.includes('return Math.max(1, this.totalUnlockDurationMs() - this.moduleStartDelayMs());'),
  'the delayed module motion must finish inside the configured total duration'
);
assert.ok(
  pageSource.includes('return Math.max(1, Math.floor(this.unlockToHomeDurationMs));'),
  'the configured total duration must not be silently raised above a preset value'
);
assert.ok(!pageSource.includes('(this.totalUnlockDurationMs() - this.moduleStartDelayMs()) * 2'));
for (const configuredDurationMs of [300, 450, 600, 630, 750, 800, 890, 900]) {
  const totalDurationMs = Math.max(1, Math.floor(configuredDurationMs));
  const moduleDelayMs = Math.floor(totalDurationMs * 0.22);
  const moduleDurationMs = Math.max(1, totalDurationMs - moduleDelayMs);
  assert.equal(
    moduleDelayMs + moduleDurationMs,
    configuredDurationMs,
    `the ${configuredDurationMs}ms parameter must include delay, overshoot, and return`
  );
}
assert.ok(!pageSource.includes('private moduleForwardDurationMs(): number'));
assert.ok(!pageSource.includes('private moduleReturnDurationMs(): number'));
assert.ok(!pageSource.includes('private moduleFadeInDurationMs(): number'));
assert.equal(pageSource.match(/this\.moduleAnimator\.play\(\);/g)?.length, 1);
assert.equal(pageSource.match(/createAnimator\(\{/g)?.length, 1);
assert.equal(pageSource.match(/this\.moduleTimelineProgress = 1;/g)?.length ?? 0, 0);
assert.ok(!pageSource.includes('curves.springMotion'), 'the return should not switch to a spring curve');

const configSource = fs.readFileSync(configPath, 'utf8');
assert.ok(configSource.includes("url: 'pages/UnlockDesktopDirectionalPage'"));
assert.ok(configSource.includes('private openDirectionalPreviewPage(staggeredArrival: boolean): void'));
assert.ok(configSource.includes('staggeredArrival: staggeredArrival'));
assert.ok(configSource.includes("this.buildDirectionalPreviewButton('方向响应 · 同时到达', false)"));
assert.ok(configSource.includes("this.buildDirectionalPreviewButton('方向响应 · 错峰到达', true)"));
assert.ok(configSource.includes("{ label: '小', value: 3 }"));
assert.ok(configSource.includes("{ label: '中', value: 6 }"));
assert.ok(configSource.includes("{ label: '大', value: 10 }"));
assert.ok(configSource.includes('this.buildReboundLevelSelector()'));
assert.ok(configSource.includes('this.unlockIconReboundPercent = level.value;'));
const presetSource = fs.readFileSync(path.resolve(
  'entry/src/main/ets/pages/config/ExperimentPresetData.ets'
), 'utf8');
assert.ok(presetSource.includes(
  "{ mark: '创新S标', name: '创新参数', duration: '630ms', rebound: '3%', damping: '0.6', durationMs: 630, reboundPercent: 3, dampingRatio: 0.6 }"
));

const routes = JSON.parse(fs.readFileSync(routesPath, 'utf8'));
assert.ok(routes.src.includes('pages/UnlockDesktopDirectionalPage'));
