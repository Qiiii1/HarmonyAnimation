export interface TaskbarDownReleaseDirection {
  x: number;
  y: number;
}

function clampTaskbarDownMotion(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

export function taskbarDownReleaseDirection(
  deltaX: number,
  deltaY: number,
  horizontalDeadZone: number = 18
): TaskbarDownReleaseDirection {
  const downwardDistance = Math.max(deltaY, 1);
  let horizontalRatio = clampTaskbarDownMotion(deltaX / downwardDistance, -0.9, 0.9);
  if (Math.abs(deltaX) < horizontalDeadZone || Math.abs(horizontalRatio) < 0.12) {
    horizontalRatio = 0;
  }

  const length = Math.sqrt(horizontalRatio * horizontalRatio + 1);
  return {
    x: horizontalRatio / length,
    y: 1 / length
  };
}

export function taskbarDownNoOvershootCoordinate(
  arrivalProgress: number,
  startOffset: number
): number {
  const progress = clampTaskbarDownMotion(arrivalProgress, 0, 1);
  if (progress >= 1) {
    return 0;
  }
  return startOffset * (1 - progress);
}
