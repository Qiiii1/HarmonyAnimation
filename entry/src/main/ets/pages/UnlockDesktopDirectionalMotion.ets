export interface UnlockReleaseDirection {
  x: number;
  y: number;
}

function clampUnlockMotion(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

export function unlockReleaseDirection(
  deltaX: number,
  deltaY: number,
  horizontalDeadZone: number = 18
): UnlockReleaseDirection {
  const upwardDistance = Math.max(-deltaY, 1);
  let horizontalRatio = clampUnlockMotion(deltaX / upwardDistance, -0.9, 0.9);
  if (Math.abs(deltaX) < horizontalDeadZone || Math.abs(horizontalRatio) < 0.12) {
    horizontalRatio = 0;
  }

  const length = Math.sqrt(horizontalRatio * horizontalRatio + 1);
  return {
    x: horizontalRatio / length,
    y: -1 / length,
  };
}

export function unlockDirectionalOvershootDistance(
  reboundPercent: number,
  baseDistance: number = 48,
  distancePerPercent: number = 0.8
): number {
  return Math.max(0, baseDistance) +
    clampUnlockMotion(reboundPercent, 0, 40) * Math.max(0, distancePerPercent);
}

export function unlockEaseOutProgress(progress: number): number {
  const normalizedProgress = clampUnlockMotion(progress, 0, 1);
  return 1 - Math.pow(1 - normalizedProgress, 1.7);
}

export function unlockModuleDirectionProjection(
  centerXRatio: number,
  centerYRatio: number,
  directionX: number,
  directionY: number,
  pageWidth: number,
  pageHeight: number
): number {
  const centerOffsetX = (centerXRatio - 0.5) * Math.max(pageWidth, 1);
  const centerOffsetY = (centerYRatio - 0.5) * Math.max(pageHeight, 1);
  const directionLength = Math.sqrt(directionX * directionX + directionY * directionY);
  if (directionLength < 0.0001) {
    return -centerOffsetY;
  }
  return centerOffsetX * directionX / directionLength +
    centerOffsetY * directionY / directionLength;
}

export function unlockModuleArrivalEndProgress(
  directionProjection: number,
  minimumProjection: number,
  maximumProjection: number,
  earliestEndProgress: number = 0.8
): number {
  const earliest = clampUnlockMotion(earliestEndProgress, 0.5, 1);
  const projectionRange = maximumProjection - minimumProjection;
  if (projectionRange < 0.0001) {
    return 1;
  }
  const directionRank = clampUnlockMotion(
    (directionProjection - minimumProjection) / projectionRange,
    0,
    1
  );
  const emphasizedRank = directionRank * directionRank * directionRank *
    (directionRank * (directionRank * 6 - 15) + 10);
  return earliest + (1 - earliest) * emphasizedRank;
}

export function unlockModuleArrivalProgress(
  rawTimelineProgress: number,
  arrivalEndProgress: number
): number {
  const pathTurnTimelineProgress = 1 / 3;
  const rawProgress = clampUnlockMotion(rawTimelineProgress, 0, 1);
  if (rawProgress <= pathTurnTimelineProgress) {
    return unlockEaseOutProgress(rawProgress);
  }
  const normalizedEndProgress = clampUnlockMotion(
    arrivalEndProgress,
    pathTurnTimelineProgress + 0.05,
    1
  );
  const settleTimelineProgress = pathTurnTimelineProgress +
    (rawProgress - pathTurnTimelineProgress) * (1 - pathTurnTimelineProgress) /
      (normalizedEndProgress - pathTurnTimelineProgress);
  return unlockEaseOutProgress(clampUnlockMotion(settleTimelineProgress, 0, 1));
}

export function unlockModuleArrivalOvershootScale(
  arrivalEndProgress: number,
  maximumOvershootScale: number = 1
): number {
  const pathTurnTimelineProgress = 1 / 3;
  const normalizedEndProgress = clampUnlockMotion(
    arrivalEndProgress,
    pathTurnTimelineProgress + 0.05,
    1
  );
  const timingScale = (normalizedEndProgress - pathTurnTimelineProgress) /
    (1 - pathTurnTimelineProgress);
  const arrivalRank = clampUnlockMotion((normalizedEndProgress - 0.5) / 0.5, 0, 1);
  const normalizedMaximumOvershootScale = clampUnlockMotion(maximumOvershootScale, 1, 2);
  const overshootBoost = 1 + (normalizedMaximumOvershootScale - 1) * arrivalRank;
  return timingScale * overshootBoost;
}

export function unlockModuleArrivalStartScale(arrivalEndProgress: number): number {
  const normalizedEndProgress = clampUnlockMotion(arrivalEndProgress, 0.5, 1);
  return 0.1 + normalizedEndProgress * 0.9;
}

function unlockHermiteCoordinate(
  progress: number,
  startCoordinate: number,
  endCoordinate: number,
  startTangent: number,
  endTangent: number
): number {
  const normalizedProgress = clampUnlockMotion(progress, 0, 1);
  const progressSquared = normalizedProgress * normalizedProgress;
  const progressCubed = progressSquared * normalizedProgress;
  const startWeight = 2 * progressCubed - 3 * progressSquared + 1;
  const startTangentWeight = progressCubed - 2 * progressSquared + normalizedProgress;
  const endWeight = -2 * progressCubed + 3 * progressSquared;
  const endTangentWeight = progressCubed - progressSquared;
  return startWeight * startCoordinate + startTangentWeight * startTangent +
    endWeight * endCoordinate + endTangentWeight * endTangent;
}

export function unlockDirectionalPathCoordinate(
  timelineProgress: number,
  startCoordinate: number,
  overshootCoordinate: number,
  turnProgress: number
): number {
  const progress = clampUnlockMotion(timelineProgress, 0, 1);
  const turn = clampUnlockMotion(turnProgress, 0.05, 0.95);
  const forwardProgress = clampUnlockMotion(progress / turn, 0, 1);
  const settleProgress = clampUnlockMotion((progress - turn) / (1 - turn), 0, 1);
  return startCoordinate + (overshootCoordinate - startCoordinate) * forwardProgress -
    overshootCoordinate * settleProgress;
}

export function unlockDirectionalPathLateralCoordinate(
  timelineProgress: number,
  startCoordinate: number,
  overshootCoordinate: number,
  turnLateralOffset: number,
  turnProgress: number
): number {
  const progress = clampUnlockMotion(timelineProgress, 0, 1);
  const turn = clampUnlockMotion(turnProgress, 0.05, 0.95);
  if (progress <= turn) {
    return unlockHermiteCoordinate(
      progress / turn,
      0,
      turnLateralOffset,
      0,
      (overshootCoordinate - startCoordinate) * 0.015
    );
  }
  return unlockHermiteCoordinate(
    (progress - turn) / (1 - turn),
    turnLateralOffset,
    0,
    -overshootCoordinate * 0.04,
    0
  );
}

export function unlockModuleDistanceFalloff(
  gestureStartX: number,
  gestureStartY: number,
  gestureEndX: number,
  gestureEndY: number,
  moduleCenterX: number,
  moduleCenterY: number,
  pageWidth: number,
  pageHeight: number
): number {
  const gestureX = gestureEndX - gestureStartX;
  const gestureY = gestureEndY - gestureStartY;
  const gestureLengthSquared = gestureX * gestureX + gestureY * gestureY;
  let pathProgress = 0;
  if (gestureLengthSquared > 0.0001) {
    pathProgress = clampUnlockMotion(
      ((moduleCenterX - gestureStartX) * gestureX + (moduleCenterY - gestureStartY) * gestureY) /
        gestureLengthSquared,
      0,
      1
    );
  }

  const closestX = gestureStartX + gestureX * pathProgress;
  const closestY = gestureStartY + gestureY * pathProgress;
  const deltaX = moduleCenterX - closestX;
  const deltaY = moduleCenterY - closestY;
  const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
  const influenceRadius = Math.max(pageWidth * 0.85, pageHeight * 0.38, 1);
  const proximity = 1 - clampUnlockMotion(distance / influenceRadius, 0, 1);
  return 0.22 + 0.78 * Math.pow(proximity, 1.45);
}
