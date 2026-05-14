export interface TaskbarUpReleaseDurations {
  forwardMs: number;
  returnMs: number;
}

export const TASKBAR_UP_RELEASE_EASE_POWER: number = 5.2;

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function lerp(start: number, end: number, progress: number): number {
  return start + (end - start) * clamp(progress, 0, 1);
}

export function taskbarUpReleaseDurations(
  totalDurationMs: number,
  forwardRatio: number
): TaskbarUpReleaseDurations {
  const totalMs: number = Math.max(2, Math.floor(totalDurationMs));
  const boundedForwardRatio: number = clamp(forwardRatio, 0.05, 0.95);
  const forwardMs: number = clamp(Math.round(totalMs * boundedForwardRatio), 1, totalMs - 1);
  return {
    forwardMs: forwardMs,
    returnMs: totalMs - forwardMs
  };
}

export function taskbarUpReleaseEaseOut(
  progress: number,
  power: number = TASKBAR_UP_RELEASE_EASE_POWER
): number {
  const t: number = clamp(progress, 0, 1);
  return 1 - Math.pow(1 - t, power);
}

export function taskbarUpReleaseInitialSlope(
  translateVelocityPxPerMs: number,
  distancePx: number,
  durationMs: number,
  minSlope: number,
  maxSlope: number
): number {
  const distance: number = Math.max(Math.abs(distancePx), 1);
  const lowerBound: number = Math.min(minSlope, maxSlope);
  const upperBound: number = Math.max(minSlope, maxSlope);
  const rawSlope: number = Math.max(translateVelocityPxPerMs, 0) * Math.max(durationMs, 1) / distance;
  return clamp(rawSlope, lowerBound, upperBound);
}

export function taskbarUpReleaseForwardControlY(
  initialSlope: number,
  controlX: number
): number {
  return clamp(Math.max(initialSlope, 0) * clamp(controlX, 0, 1), 0, 1);
}

export function taskbarUpReleaseEaseIn(
  progress: number,
  power: number = TASKBAR_UP_RELEASE_EASE_POWER
): number {
  const t: number = clamp(progress, 0, 1);
  return Math.pow(t, power);
}

export function taskbarUpFollowerReleaseMultiplier(
  index: number,
  leadIndex: number,
  falloff: number
): number {
  const distanceFromLead: number = Math.abs(leadIndex - index);
  if (distanceFromLead <= 0) {
    return 1;
  }

  return Math.pow(clamp(falloff, 0, 1), distanceFromLead);
}

export function taskbarUpFollowerReleaseTranslateX(
  index: number,
  leadIndex: number,
  falloff: number,
  sharedStartX: number,
  leadOvershootX: number,
  returning: boolean,
  progress: number
): number {
  const overshootX: number = leadOvershootX * taskbarUpFollowerReleaseMultiplier(index, leadIndex, falloff);
  if (returning) {
    return lerp(overshootX, 0, progress);
  }

  return lerp(sharedStartX, overshootX, progress);
}
