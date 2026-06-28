export interface TaskbarUpReleaseDurations {
  forwardMs: number;
  returnMs: number;
}

export interface TaskbarUpCardSwipeDeformation {
  rotateYDeg: number;
  rotateZDeg: number;
  skewXDeg: number;
  scaleX: number;
  scaleY: number;
  originXPercent: number;
  highlightOpacity: number;
  shadowOpacity: number;
  highlightOffsetX: number;
  edgeRadiusOffset: number;
  materialTranslateX: number;
  materialTranslateY: number;
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

export function taskbarUpCardSwipeDeformation(
  visualOffsetX: number,
  cardWidthPx: number,
  maxDragPx: number,
  velocitySignal: number = 0
): TaskbarUpCardSwipeDeformation {
  const cardWidth: number = Math.max(Math.abs(cardWidthPx), 1);
  const referenceDrag: number = Math.max(Math.abs(maxDragPx), cardWidth * 0.35, 1);
  const normalizedDrag: number = clamp(visualOffsetX / referenceDrag + velocitySignal, -1, 1);
  const direction: number = normalizedDrag === 0 ? 0 : (normalizedDrag > 0 ? 1 : -1);
  const dragStrength: number = 1 - Math.pow(1 - Math.abs(normalizedDrag), 2.05);
  if (dragStrength <= 0) {
    return {
      rotateYDeg: 0,
      rotateZDeg: 0,
      skewXDeg: 0,
      scaleX: 1,
      scaleY: 1,
      originXPercent: 50,
      highlightOpacity: 0,
      shadowOpacity: 0,
      highlightOffsetX: 0,
      edgeRadiusOffset: 0,
      materialTranslateX: 0,
      materialTranslateY: 0
    };
  }

  return {
    rotateYDeg: -direction * 36 * dragStrength,
    rotateZDeg: direction * 1.6 * dragStrength,
    skewXDeg: 0,
    scaleX: 1 + 0.12 * dragStrength,
    scaleY: 1,
    originXPercent: direction > 0 ? lerp(50, -8, dragStrength) : lerp(50, 108, dragStrength),
    highlightOpacity: 0.28 * dragStrength,
    shadowOpacity: 0,
    highlightOffsetX: -direction * 62 * dragStrength,
    edgeRadiusOffset: 16 * dragStrength,
    materialTranslateX: direction * 20 * dragStrength,
    materialTranslateY: -7 * dragStrength
  };
}
