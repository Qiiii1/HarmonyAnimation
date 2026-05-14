export interface TaskbarUpReleaseDurations {
  forwardMs: number;
  returnMs: number;
}

export const TASKBAR_UP_RELEASE_EASE_POWER: number = 5.2;

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
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

export function taskbarUpReleaseEaseIn(
  progress: number,
  power: number = TASKBAR_UP_RELEASE_EASE_POWER
): number {
  const t: number = clamp(progress, 0, 1);
  return Math.pow(t, power);
}
