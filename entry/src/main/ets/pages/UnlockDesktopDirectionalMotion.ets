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

export function unlockDirectionalOvershootDistance(reboundPercent: number): number {
  return 48 + clampUnlockMotion(reboundPercent, 0, 40) * 0.8;
}

export function unlockEaseOutProgress(progress: number): number {
  const normalizedProgress = clampUnlockMotion(progress, 0, 1);
  return 1 - Math.pow(1 - normalizedProgress, 1.7);
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
