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

export function taskbarDownHorizontalArrivalEndProgress(
  touchStartX: number,
  moduleCenterX: number,
  pageWidth: number,
  earliestEndProgress: number = 0.58
): number {
  const distanceRank = taskbarDownHorizontalDistanceRank(
    touchStartX,
    moduleCenterX,
    pageWidth
  );
  const smoothDistanceRank = distanceRank * distanceRank * (3 - 2 * distanceRank);
  const earliest = clampTaskbarDownMotion(earliestEndProgress, 0.08, 1);
  return earliest + (1 - earliest) * smoothDistanceRank;
}

export function taskbarDownHorizontalDistanceRank(
  touchStartX: number,
  moduleCenterX: number,
  pageWidth: number
): number {
  const width = Math.max(pageWidth, 1);
  const startX = clampTaskbarDownMotion(touchStartX, 0, width);
  const centerX = clampTaskbarDownMotion(moduleCenterX, 0, width);
  const maximumDistance = Math.max(startX, width - startX, 1);
  return clampTaskbarDownMotion(
    Math.abs(centerX - startX) / maximumDistance,
    0,
    1
  );
}

export function taskbarDownStaggeredArrivalProgress(
  timelineProgress: number,
  arrivalEndProgress: number
): number {
  const endProgress = clampTaskbarDownMotion(arrivalEndProgress, 0.08, 1);
  const normalizedProgress = clampTaskbarDownMotion(timelineProgress / endProgress, 0, 1);
  return 1 - Math.pow(1 - normalizedProgress, 1.7);
}

export function taskbarDownOpacityColumnIndex(centerXRatio: number): number {
  const normalizedX = clampTaskbarDownMotion(centerXRatio, 0, 0.9999);
  return Math.floor(normalizedX * 4);
}

export function taskbarDownOpacityColumnOrder(
  touchStartX: number,
  pageWidth: number,
  columnIndex: number
): number {
  const width = Math.max(pageWidth, 1);
  const touchXRatio = clampTaskbarDownMotion(touchStartX / width, 0, 1);
  const normalizedColumnIndex = Math.floor(clampTaskbarDownMotion(columnIndex, 0, 3));
  const columnCenter = (normalizedColumnIndex + 0.5) / 4;
  const columnDistance = Math.abs(columnCenter - touchXRatio);
  let order = 0;
  for (let index = 0; index < 4; index += 1) {
    if (index === normalizedColumnIndex) {
      continue;
    }
    const otherDistance = Math.abs((index + 0.5) / 4 - touchXRatio);
    if (otherDistance < columnDistance - 0.0001 ||
      (Math.abs(otherDistance - columnDistance) <= 0.0001 && index < normalizedColumnIndex)) {
      order += 1;
    }
  }
  return order;
}
