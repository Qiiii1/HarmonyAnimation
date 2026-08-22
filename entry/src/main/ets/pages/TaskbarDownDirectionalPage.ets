import curves from '@ohos.curves';
import { AnimatorResult } from '@kit.ArkUI';
import {
  unlockDirectionalPathCoordinate,
  unlockDirectionalPathLateralCoordinate,
  unlockDirectionalOvershootDistance,
  unlockModuleArrivalOvershootScale,
  unlockModuleArrivalProgress,
  unlockModuleArrivalStartScale,
  unlockModuleDirectionProjection,
  unlockModuleDistanceFalloff
} from './UnlockDesktopDirectionalMotion';
import {
  taskbarDownHorizontalArrivalEndProgress,
  taskbarDownHorizontalDistanceRank,
  taskbarDownNoOvershootCoordinate,
  taskbarDownOpacityColumnIndex,
  taskbarDownOpacityColumnOrder,
  taskbarDownReleaseDirection,
  taskbarDownStaggeredArrivalProgress
} from './TaskbarDownDirectionalMotion';

interface TaskbarDownDirectionalRouteParams {
  staggeredArrival: boolean;
  overshootEnabled: boolean;
  staggerLeadRatio: number;
}

@Entry
@Component
struct TaskbarDownDirectionalPage {
  @State pageWidth: number = 1;
  @State pageHeight: number = 1;
  @State progress: number = 0;
  @State backgroundBlurProgress: number = 0;
  @State iconTimelineProgress: number = 0;
  @State dragging: boolean = false;
  @State animating: boolean = false;
  @State closingVertically: boolean = false;
  @State iconCloseScale: number = 1;
  @State staggeredArrival: boolean = false;
  @State overshootEnabled: boolean = true;
  @State staggerLeadRatio: number = 0.42;
  @StorageLink('taskbarDownOpenDragDampingRatio') openDragDampingRatio: number = 1.5;
  @StorageLink('taskbarDownModuleEnterDurationMs') moduleEnterTotalDurationMs: number = 750;
  @StorageLink('taskbarDownModuleReboundPercent') moduleReboundPercent: number = 2;

  private dragStartX: number = 0;
  private dragStartY: number = 0;
  private dragStartProgress: number = 0;
  private dragDeltaX: number = 0;
  private dragDeltaY: number = 0;
  private closeDragProgress: number = 1;
  private dragMode: number = 0;
  private releaseDirectionX: number = 0;
  private releaseDirectionY: number = 1;
  private releaseTouchX: number = 0;
  private releaseTouchY: number = 0;
  private animationToken: number = 0;
  private iconAnimator: AnimatorResult | undefined = undefined;
  private iconArrivalMinimumProjection: number = 0;
  private iconArrivalMaximumProjection: number = 0;
  private openingBackgroundFinished: boolean = false;
  private openingIconsFinished: boolean = false;

  private readonly PULL_TRIGGER_HEIGHT: number = 190;
  private readonly PANEL_DRAG_DISTANCE: number = 520;
  private readonly PANEL_OPEN_THRESHOLD: number = 0.14;
  private readonly PANEL_CLOSE_THRESHOLD: number = 0.82;
  private readonly DRAG_MODE_OPEN: number = 1;
  private readonly DRAG_MODE_OPEN_FOLLOW: number = 2;
  private readonly DRAG_MODE_CLOSE: number = 3;
  private readonly POST_OPEN_DIRECTION_THRESHOLD: number = 6;
  private readonly BACKGROUND_STAGE_DURATION_MS: number = 420;
  private readonly BACKGROUND_BLUR_STAGE_DURATION_MS: number = 420;
  private readonly PANEL_CLOSE_DURATION_MS: number = 420;
  private readonly OPEN_TAP_MOVE_TOLERANCE: number = 12;

  // 与原下拉任务栏保持相同的背景参数。
  private readonly BACKGROUND_BLUR_MAX: number = 148;
  private readonly BACKGROUND_BLUR_OPACITY: number = 1;
  private readonly BACKGROUND_BLACK_WASH_OPACITY: number = 0.22;
  private readonly BACKGROUND_EFFECT_END_PROGRESS: number = 0.82;
  private readonly BACKGROUND3_END_SCALE: number = 0.89;
  private readonly BACKGROUND3_END_RADIUS: number = 28;
  private readonly BACKGROUND_BLUR_OVERSCAN_SCALE: number = 1.05;
  private readonly BACKGROUND3_BLUR_PADDING: number = 168;

  // 方向运动沿用创意上滑解锁桌面的轨迹模型：反方向入场、顺势过冲、回到终点。
  private readonly DIRECTION_DEAD_ZONE: number = 18;
  private readonly ICON_START_SCALE: number = 0.965;
  private readonly ICON_START_OFFSET: number = -110;
  private readonly ICON_TURN_PROGRESS: number = 0.4980680286858419;
  private readonly ICON_TURN_LATERAL_OFFSET: number = 8;
  private readonly ICON_MAX_OVERSHOOT_SCALE: number = 1.35;
  private readonly ICON_NEAR_START_DISTANCE_SCALE: number = 0.72;
  private readonly ICON_FAR_START_DISTANCE_SCALE: number = 1.24;
  private readonly ICON_NEAR_OVERSHOOT_SCALE: number = 0.55;
  private readonly ICON_FAR_OVERSHOOT_SCALE: number = 1.35;
  private readonly ICON_MIN_DISTANCE_RESPONSE: number = 0.68;
  private readonly ICON_BOTTOM_TRAVEL_BOOST: number = 0.18;
  private readonly ICON_CLOSE_OFFSET_Y: number = -360;
  private readonly ICON_MAX_X_COMPRESSION: number = 0.03;
  private readonly ICON_CLOSE_END_SCALE: number = 0.96;
  private readonly ICON_CLOSE_Y_AXIS_FOLLOW_RATIO: number = 0.08;
  private readonly ICON_OVERSHOOT_DISTANCE_SCALE: number = 0.45;
  private readonly ICON_OPACITY_MAX_START_DELAY: number = 0.34;
  private readonly ICON_OPACITY_REVEAL_DURATION: number = 0.56;
  private readonly STAGGERED_ICON_OPACITY_COLUMN_START_GAP: number = 0.04;
  private readonly STAGGERED_ICON_OPACITY_REVEAL_DURATION: number = 0.26;
  private readonly ICON_CENTER_X_RATIOS: number[] = [
    0.8511, 0.1482, 0.7112, 0.2884, 0.7112, 0.2872, 0.7119,
    0.6056, 0.3936, 0.1809, 0.8184, 0.6056, 0.3936, 0.1809
  ];
  private readonly ICON_CENTER_Y_RATIOS: number[] = [
    0.1186, 0.1201, 0.3030, 0.2535, 0.2030, 0.4011, 0.4008,
    0.5101, 0.5101, 0.5101, 0.5101, 0.6335, 0.6337, 0.6337
  ];

  private clamp(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }

  private lerp(start: number, end: number, t: number): number {
    return start + (end - start) * t;
  }

  private fullFrameWidth(): number {
    return Math.max(this.pageWidth, 1);
  }

  private fullFrameHeight(): number {
    return Math.max(this.pageHeight, 1);
  }

  private primaryTouchX(event: TouchEvent): number {
    if (event.touches.length > 0) {
      return event.touches[0].windowX;
    }
    if (event.changedTouches.length > 0) {
      return event.changedTouches[0].windowX;
    }
    return this.dragStartX;
  }

  private primaryTouchY(event: TouchEvent): number {
    if (event.touches.length > 0) {
      return event.touches[0].windowY;
    }
    if (event.changedTouches.length > 0) {
      return event.changedTouches[0].windowY;
    }
    return this.dragStartY;
  }

  private backgroundEffectProgress(): number {
    const t = this.clamp(this.backgroundBlurProgress / this.BACKGROUND_EFFECT_END_PROGRESS, 0, 1);
    const smoothT = t * t * (3 - 2 * t);
    return this.lerp(t, smoothT, 0.45);
  }

  private backgroundBlurOpacity(): number {
    return Math.pow(this.backgroundEffectProgress(), 0.8) * this.BACKGROUND_BLUR_OPACITY;
  }

  private backgroundBlurAmount(): number {
    return this.BACKGROUND_BLUR_MAX * this.backgroundEffectProgress();
  }

  private backgroundBlackWashOpacity(): number {
    return Math.pow(this.backgroundEffectProgress(), 0.72) * this.BACKGROUND_BLACK_WASH_OPACITY;
  }

  private backgroundBlurLayerScale(): number {
    return this.lerp(1, this.BACKGROUND_BLUR_OVERSCAN_SCALE, this.backgroundEffectProgress());
  }

  private background3Scale(): number {
    return this.lerp(1, this.BACKGROUND3_END_SCALE, this.progress);
  }

  private background3Radius(): number {
    return this.lerp(0, this.BACKGROUND3_END_RADIUS, this.progress);
  }

  private iconDirectionProjection(centerXRatio: number, centerYRatio: number): number {
    return unlockModuleDirectionProjection(
      centerXRatio,
      centerYRatio,
      this.releaseDirectionX,
      this.releaseDirectionY,
      this.fullFrameWidth(),
      this.fullFrameHeight()
    );
  }

  private updateIconArrivalProjectionRange(): void {
    const firstProjection = this.iconDirectionProjection(
      this.ICON_CENTER_X_RATIOS[0],
      this.ICON_CENTER_Y_RATIOS[0]
    );
    let minimumProjection = firstProjection;
    let maximumProjection = firstProjection;
    for (let index = 1; index < this.ICON_CENTER_X_RATIOS.length; index += 1) {
      const projection = this.iconDirectionProjection(
        this.ICON_CENTER_X_RATIOS[index],
        this.ICON_CENTER_Y_RATIOS[index]
      );
      minimumProjection = Math.min(minimumProjection, projection);
      maximumProjection = Math.max(maximumProjection, projection);
    }
    this.iconArrivalMinimumProjection = minimumProjection;
    this.iconArrivalMaximumProjection = maximumProjection;
  }

  private iconArrivalEndProgress(centerXRatio: number, centerYRatio: number): number {
    if (!this.staggeredArrival) {
      return 1;
    }
    return taskbarDownHorizontalArrivalEndProgress(
      this.dragStartX,
      this.fullFrameWidth() * centerXRatio,
      this.fullFrameWidth(),
      1 - this.staggerLeadRatio
    );
  }

  private iconArrivalProgress(centerXRatio: number, centerYRatio: number): number {
    if (this.staggeredArrival) {
      return taskbarDownStaggeredArrivalProgress(
        this.iconTimelineProgress,
        this.iconArrivalEndProgress(centerXRatio, centerYRatio)
      );
    }
    return unlockModuleArrivalProgress(
      this.iconTimelineProgress,
      this.iconArrivalEndProgress(centerXRatio, centerYRatio)
    );
  }

  private iconHorizontalDistanceRank(centerXRatio: number): number {
    return taskbarDownHorizontalDistanceRank(
      this.dragStartX,
      this.fullFrameWidth() * centerXRatio,
      this.fullFrameWidth()
    );
  }

  private iconOvershootScale(centerXRatio: number, centerYRatio: number): number {
    if (this.staggeredArrival) {
      return this.lerp(
        this.ICON_NEAR_OVERSHOOT_SCALE,
        this.ICON_FAR_OVERSHOOT_SCALE,
        this.iconHorizontalDistanceRank(centerXRatio)
      );
    }
    return unlockModuleArrivalOvershootScale(
      this.iconArrivalEndProgress(centerXRatio, centerYRatio),
      this.ICON_MAX_OVERSHOOT_SCALE
    );
  }

  private iconStartOffset(centerXRatio: number, centerYRatio: number): number {
    if (this.staggeredArrival) {
      const distanceScale = this.lerp(
        this.ICON_NEAR_START_DISTANCE_SCALE,
        this.ICON_FAR_START_DISTANCE_SCALE,
        this.iconHorizontalDistanceRank(centerXRatio)
      );
      return this.ICON_START_OFFSET * distanceScale;
    }
    return this.ICON_START_OFFSET * unlockModuleArrivalStartScale(
      this.iconArrivalEndProgress(centerXRatio, centerYRatio)
    );
  }

  private iconOvershootDistance(centerXRatio: number, centerYRatio: number): number {
    return unlockDirectionalOvershootDistance(this.moduleReboundPercent) *
      this.iconOvershootScale(centerXRatio, centerYRatio) * this.ICON_OVERSHOOT_DISTANCE_SCALE;
  }

  private iconLateralOffset(centerXRatio: number, centerYRatio: number): number {
    return this.ICON_TURN_LATERAL_OFFSET * this.iconOvershootScale(centerXRatio, centerYRatio);
  }

  private iconDistanceResponse(centerXRatio: number, centerYRatio: number): number {
    const bottomProgress = this.clamp((centerYRatio - 0.45) / 0.20, 0, 1);
    if (this.staggeredArrival) {
      return 1 + bottomProgress * this.ICON_BOTTOM_TRAVEL_BOOST;
    }
    const rawResponse = unlockModuleDistanceFalloff(
      this.dragStartX,
      this.dragStartY,
      this.releaseTouchX,
      this.releaseTouchY,
      this.fullFrameWidth() * centerXRatio,
      this.fullFrameHeight() * centerYRatio,
      this.fullFrameWidth(),
      this.fullFrameHeight()
    );
    const distanceResponse = this.lerp(this.ICON_MIN_DISTANCE_RESPONSE, 1, rawResponse);
    return distanceResponse * (1 + bottomProgress * this.ICON_BOTTOM_TRAVEL_BOOST);
  }

  private iconDirectionalCoordinate(centerXRatio: number, centerYRatio: number): number {
    if (!this.overshootEnabled) {
      return taskbarDownNoOvershootCoordinate(
        this.iconArrivalProgress(centerXRatio, centerYRatio),
        this.iconStartOffset(centerXRatio, centerYRatio)
      );
    }
    return unlockDirectionalPathCoordinate(
      this.iconArrivalProgress(centerXRatio, centerYRatio),
      this.iconStartOffset(centerXRatio, centerYRatio),
      this.iconOvershootDistance(centerXRatio, centerYRatio),
      this.ICON_TURN_PROGRESS
    );
  }

  private iconLateralCoordinate(centerXRatio: number, centerYRatio: number): number {
    if (!this.overshootEnabled) {
      return 0;
    }
    return unlockDirectionalPathLateralCoordinate(
      this.iconArrivalProgress(centerXRatio, centerYRatio),
      this.iconStartOffset(centerXRatio, centerYRatio),
      this.iconOvershootDistance(centerXRatio, centerYRatio),
      this.iconLateralOffset(centerXRatio, centerYRatio),
      this.ICON_TURN_PROGRESS
    );
  }

  private iconTranslateX(centerXRatio: number, centerYRatio: number, motionFactor: number): number {
    if (this.closingVertically) {
      const closeProgress = 1 - this.iconTimelineProgress;
      return (0.5 - centerXRatio) * this.fullFrameWidth() *
        this.ICON_CLOSE_Y_AXIS_FOLLOW_RATIO * closeProgress;
    }
    if (this.staggeredArrival) {
      return 0;
    }
    const directional = this.iconDirectionalCoordinate(centerXRatio, centerYRatio);
    const lateral = this.iconLateralCoordinate(centerXRatio, centerYRatio);
    const response = this.iconDistanceResponse(centerXRatio, centerYRatio) * motionFactor;
    return (this.releaseDirectionX * directional - this.releaseDirectionY * lateral) * response;
  }

  private iconTranslateY(centerXRatio: number, centerYRatio: number, motionFactor: number): number {
    if (this.closingVertically) {
      return this.ICON_CLOSE_OFFSET_Y * (1 - this.iconTimelineProgress);
    }
    const directional = this.iconDirectionalCoordinate(centerXRatio, centerYRatio);
    const lateral = this.iconLateralCoordinate(centerXRatio, centerYRatio);
    const response = this.iconDistanceResponse(centerXRatio, centerYRatio) * motionFactor;
    return (this.releaseDirectionY * directional + this.releaseDirectionX * lateral) * response;
  }

  private baseModuleOpacity(progress: number): number {
    if (progress >= 0.999) {
      return 1;
    }
    const t = this.clamp(progress, 0, 1);
    return 1 - Math.pow(1 - t, 2.3);
  }

  private staggeredModuleOpacity(progress: number): number {
    if (progress >= 0.999) {
      return 1;
    }
    const t = this.clamp(progress, 0, 1);
    return 1 - Math.pow(1 - t, 3.4);
  }

  private iconOpacityLayerRank(centerXRatio: number, centerYRatio: number): number {
    const projectionRange = this.iconArrivalMaximumProjection - this.iconArrivalMinimumProjection;
    if (projectionRange <= 0.001) {
      return 0;
    }
    return this.clamp(
      (this.iconDirectionProjection(centerXRatio, centerYRatio) - this.iconArrivalMinimumProjection) /
        projectionRange,
      0,
      1
    );
  }

  private iconLayerOpacityProgress(centerXRatio: number, centerYRatio: number): number {
    if (this.staggeredArrival) {
      const columnIndex = taskbarDownOpacityColumnIndex(centerXRatio);
      const columnOrder = taskbarDownOpacityColumnOrder(
        this.dragStartX,
        this.fullFrameWidth(),
        columnIndex
      );
      const startProgress = columnOrder * this.STAGGERED_ICON_OPACITY_COLUMN_START_GAP;
      return this.clamp(
        (this.iconTimelineProgress - startProgress) / this.STAGGERED_ICON_OPACITY_REVEAL_DURATION,
        0,
        1
      );
    }
    const layerRank = this.iconOpacityLayerRank(centerXRatio, centerYRatio);
    const startProgress = layerRank * this.ICON_OPACITY_MAX_START_DELAY;
    return this.clamp(
      (this.iconTimelineProgress - startProgress) / this.ICON_OPACITY_REVEAL_DURATION,
      0,
      1
    );
  }

  private iconOpacity(centerXRatio: number, centerYRatio: number): number {
    const opacityProgress = this.closingVertically
      ? this.iconTimelineProgress
      : this.iconLayerOpacityProgress(centerXRatio, centerYRatio);
    if (this.staggeredArrival && !this.closingVertically) {
      return this.staggeredModuleOpacity(opacityProgress);
    }
    return this.baseModuleOpacity(opacityProgress);
  }

  private iconScale(centerXRatio: number, centerYRatio: number): number {
    if (this.closingVertically) {
      return this.iconCloseScale;
    }
    return this.lerp(
      this.ICON_START_SCALE,
      1,
      this.iconArrivalProgress(centerXRatio, centerYRatio)
    );
  }

  private iconScaleX(centerXRatio: number, centerYRatio: number): number {
    if (this.closingVertically) {
      return this.iconCloseScale;
    }
    const arrivalProgress = this.iconArrivalProgress(centerXRatio, centerYRatio);
    const compression = (1 - arrivalProgress) * this.ICON_MAX_X_COMPRESSION;
    return this.iconScale(centerXRatio, centerYRatio) * (1 - compression);
  }

  private updateReleaseDirection(currentX: number, currentY: number): void {
    this.dragDeltaX = currentX - this.dragStartX;
    this.dragDeltaY = currentY - this.dragStartY;
    if (this.staggeredArrival) {
      this.releaseDirectionX = 0;
      this.releaseDirectionY = 1;
      this.releaseTouchX = this.clamp(currentX, 0, this.fullFrameWidth());
      this.releaseTouchY = this.clamp(currentY, 0, this.fullFrameHeight());
      this.updateIconArrivalProjectionRange();
      return;
    }
    const direction = taskbarDownReleaseDirection(
      this.dragDeltaX,
      this.dragDeltaY,
      this.DIRECTION_DEAD_ZONE
    );
    this.releaseDirectionX = direction.x;
    this.releaseDirectionY = direction.y;
    this.releaseTouchX = this.clamp(currentX, 0, this.fullFrameWidth());
    this.releaseTouchY = this.clamp(currentY, 0, this.fullFrameHeight());
    this.updateIconArrivalProjectionRange();
  }

  private stopIconAnimator(): void {
    if (this.iconAnimator !== undefined) {
      this.iconAnimator.onFrame = (): void => {};
      this.iconAnimator.onFinish = (): void => {};
      this.iconAnimator.cancel();
      this.iconAnimator = undefined;
    }
  }

  private finishOpeningPart(token: number, backgroundFinished: boolean): void {
    if (token !== this.animationToken) {
      return;
    }
    if (backgroundFinished) {
      this.openingBackgroundFinished = true;
    } else {
      this.openingIconsFinished = true;
    }
    if (this.openingBackgroundFinished && this.openingIconsFinished) {
      this.animating = false;
    }
  }

  private playDirectionalIconEntrance(token: number): void {
    if (token !== this.animationToken) {
      return;
    }
    this.stopIconAnimator();
    this.iconTimelineProgress = 0;
    this.iconAnimator = this.getUIContext().createAnimator({
      duration: Math.max(1, Math.floor(this.moduleEnterTotalDurationMs)),
      easing: 'linear',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 0,
      end: 1
    });
    this.iconAnimator.onFrame = (value: number): void => {
      if (token === this.animationToken) {
        this.iconTimelineProgress = value;
      }
    };
    this.iconAnimator.onFinish = (): void => {
      if (token === this.animationToken) {
        this.iconTimelineProgress = 1;
        this.finishOpeningPart(token, false);
      }
    };
    this.iconAnimator.play();
  }

  private canStartDrag(startY: number): boolean {
    return this.progress > 0.999 || this.progress > 0.001 || startY <= this.PULL_TRIGGER_HEIGHT;
  }

  private isOpenTap(event: TouchEvent): boolean {
    if (event.type !== TouchType.Up || this.dragStartProgress < 0.999 || this.progress < 0.999) {
      return false;
    }
    const moveX = Math.abs(this.primaryTouchX(event) - this.dragStartX);
    const moveY = Math.abs(this.primaryTouchY(event) - this.dragStartY);
    return moveX <= this.OPEN_TAP_MOVE_TOLERANCE && moveY <= this.OPEN_TAP_MOVE_TOLERANCE;
  }

  private animateOpenSequence(currentX: number, currentY: number): void {
    this.closingVertically = false;
    this.iconCloseScale = 1;
    this.updateReleaseDirection(currentX, currentY);
    this.dragMode = this.DRAG_MODE_OPEN_FOLLOW;
    this.animating = true;
    this.animationToken += 1;
    const token = this.animationToken;
    this.openingBackgroundFinished = false;
    this.openingIconsFinished = false;
    this.playDirectionalIconEntrance(token);
    this.getUIContext().animateTo({
      duration: this.BACKGROUND_STAGE_DURATION_MS,
      curve: curves.cubicBezierCurve(0.2, 0.9, 0.2, 1)
    }, () => {
      this.progress = 1;
    });
    this.getUIContext().animateTo({
      duration: this.BACKGROUND_BLUR_STAGE_DURATION_MS,
      curve: curves.cubicBezierCurve(0.2, 0.82, 0.2, 1),
      onFinish: () => {
        this.finishOpeningPart(token, true);
      }
    }, () => {
      this.backgroundBlurProgress = 1;
    });
  }

  private playCloseMovement(token: number, durationMs: number): void {
    if (token !== this.animationToken) {
      return;
    }
    this.getUIContext().animateTo({
      duration: Math.max(1, durationMs),
      curve: curves.cubicBezierCurve(0.18, 0.88, 0.22, 1),
      onFinish: () => {
        if (token === this.animationToken) {
          this.animating = false;
          this.closingVertically = false;
          this.iconCloseScale = 1;
        }
      }
    }, () => {
      this.progress = 0;
      this.backgroundBlurProgress = 0;
      this.iconTimelineProgress = 0;
      if (this.closingVertically) {
        this.iconCloseScale = this.ICON_CLOSE_END_SCALE;
      }
    });
  }

  private animateClosed(): void {
    this.animationToken += 1;
    const token = this.animationToken;
    this.stopIconAnimator();
    this.dragging = false;
    this.dragMode = 0;
    this.animating = true;
    this.closingVertically = this.progress >= 0.999 && this.iconTimelineProgress >= 0.999;
    this.iconCloseScale = 1;
    this.playCloseMovement(token, this.PANEL_CLOSE_DURATION_MS);
  }

  aboutToDisappear(): void {
    this.animationToken += 1;
    this.stopIconAnimator();
  }

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as TaskbarDownDirectionalRouteParams;
    this.staggeredArrival = params.staggeredArrival === true;
    this.overshootEnabled = params.overshootEnabled !== false;
    this.staggerLeadRatio = this.clamp(params.staggerLeadRatio, 0, 0.92);
  }

  private handleTouch(event: TouchEvent): void {
    if (this.animating && !this.dragging) {
      return;
    }

    if (event.type === TouchType.Down) {
      const startY = this.primaryTouchY(event);
      if (!this.canStartDrag(startY)) {
        return;
      }
      this.dragging = true;
      this.closingVertically = false;
      this.dragStartX = this.primaryTouchX(event);
      this.dragStartY = startY;
      this.dragStartProgress = this.progress;
      this.dragDeltaX = 0;
      this.dragDeltaY = 0;
      this.closeDragProgress = 1;
      this.dragMode = this.progress >= 0.999 ? 0 : this.DRAG_MODE_OPEN;
      return;
    }

    if (event.type === TouchType.Move && this.dragging) {
      const currentX = this.primaryTouchX(event);
      const currentY = this.primaryTouchY(event);
      const deltaY = currentY - this.dragStartY;

      if (this.dragMode === 0 && this.progress >= 0.999) {
        if (deltaY >= this.POST_OPEN_DIRECTION_THRESHOLD) {
          this.dragMode = this.DRAG_MODE_OPEN_FOLLOW;
        } else if (deltaY <= -this.POST_OPEN_DIRECTION_THRESHOLD) {
          this.dragMode = this.DRAG_MODE_CLOSE;
        } else {
          return;
        }
      }

      if (this.dragMode === this.DRAG_MODE_OPEN) {
        const rawProgress = this.dragStartProgress
          + deltaY / (this.PANEL_DRAG_DISTANCE * Math.max(this.openDragDampingRatio, 0.01));
        const nextProgress = this.clamp(rawProgress, 0, 1);
        this.progress = nextProgress;
        this.backgroundBlurProgress = nextProgress;
        if (nextProgress >= this.PANEL_OPEN_THRESHOLD) {
          this.animateOpenSequence(currentX, currentY);
        }
        return;
      }

      if (this.dragMode === this.DRAG_MODE_CLOSE) {
        this.closeDragProgress = this.clamp(1 + deltaY / this.PANEL_DRAG_DISTANCE, 0, 1);
        if (this.closeDragProgress <= this.PANEL_CLOSE_THRESHOLD) {
          this.animateClosed();
        }
      }
      return;
    }

    if ((event.type === TouchType.Up || event.type === TouchType.Cancel) && this.dragging) {
      this.dragging = false;
      if (this.isOpenTap(event)) {
        this.animateClosed();
        return;
      }
      if (this.dragMode === this.DRAG_MODE_OPEN) {
        if (this.progress >= this.PANEL_OPEN_THRESHOLD) {
          this.animateOpenSequence(this.primaryTouchX(event), this.primaryTouchY(event));
        } else {
          this.animateClosed();
        }
      } else if (this.dragMode === this.DRAG_MODE_CLOSE && this.closeDragProgress <= this.PANEL_CLOSE_THRESHOLD) {
        this.animateClosed();
      }
      this.dragMode = 0;
    }
  }

  @Builder
  private buildControlModule(
    resource: Resource,
    centerXRatio: number,
    centerYRatio: number,
    motionFactor: number
  ) {
    Image(resource)
      .width(this.fullFrameWidth())
      .height(this.fullFrameHeight())
      .objectFit(ImageFit.Fill)
      .opacity(this.iconOpacity(centerXRatio, centerYRatio))
      .scale({
        x: this.iconScaleX(centerXRatio, centerYRatio),
        y: this.iconScale(centerXRatio, centerYRatio),
        centerX: `${centerXRatio * 100}%`,
        centerY: `${centerYRatio * 100}%`
      })
      .translate({
        x: this.iconTranslateX(centerXRatio, centerYRatio, motionFactor),
        y: this.iconTranslateY(centerXRatio, centerYRatio, motionFactor)
      })
      .expandSafeArea(
        [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
        [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
      )
  }

  build() {
    Stack() {
      Image($r('app.media.Background5'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.Background5'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .blur(this.backgroundBlurAmount())
        .opacity(this.backgroundBlurOpacity())
        .scale({ x: this.backgroundBlurLayerScale(), y: this.backgroundBlurLayerScale() })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.Background3'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .scale({ x: this.background3Scale(), y: this.background3Scale() })
        .borderRadius(this.background3Radius())
        .clip(true)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      // 在屏幕外预留模糊缓冲区，避免大半径模糊在左右视口内被截断。
      Stack() {
        Image($r('app.media.Background3'))
          .width(this.fullFrameWidth())
          .height(this.fullFrameHeight())
          .objectFit(ImageFit.Fill)
          .scale({
            x: this.background3Scale() * this.backgroundBlurLayerScale(),
            y: this.background3Scale() * this.backgroundBlurLayerScale()
          })
      }
        .width(this.fullFrameWidth() + this.BACKGROUND3_BLUR_PADDING * 2)
        .height(this.fullFrameHeight() + this.BACKGROUND3_BLUR_PADDING * 2)
        .renderGroup(true)
        .blur(this.backgroundBlurAmount())
        .opacity(this.backgroundBlurOpacity())

      Column()
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .backgroundColor(Color.Black)
        .opacity(this.backgroundBlackWashOpacity())
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      this.buildControlModule($r('app.media.CM1'), 0.8511, 0.1186, 0.88)
      this.buildControlModule($r('app.media.CM2'), 0.1482, 0.1201, 0.92)
      this.buildControlModule($r('app.media.CM3'), 0.7112, 0.3030, 1.06)
      this.buildControlModule($r('app.media.CM4'), 0.2884, 0.2535, 1.10)
      this.buildControlModule($r('app.media.CM5'), 0.7112, 0.2030, 1.02)
      this.buildControlModule($r('app.media.CM6'), 0.2872, 0.4011, 1.08)
      this.buildControlModule($r('app.media.CM7'), 0.7119, 0.4008, 1.04)
      this.buildControlModule($r('app.media.CM8'), 0.6056, 0.5101, 1.00)
      this.buildControlModule($r('app.media.CM9'), 0.3936, 0.5101, 1.05)
      this.buildControlModule($r('app.media.CM10'), 0.1809, 0.5101, 1.12)
      this.buildControlModule($r('app.media.CM11'), 0.8184, 0.5101, 0.96)
      this.buildControlModule($r('app.media.CM12'), 0.6056, 0.6335, 1.08)
      this.buildControlModule($r('app.media.CM13'), 0.3936, 0.6337, 1.03)
      this.buildControlModule($r('app.media.CM14'), 0.1809, 0.6337, 1.10)

      Column()
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .backgroundColor('#01000000')
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )
        .onTouch((event) => {
          this.handleTouch(event);
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .expandSafeArea(
      [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
      [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
    )
    .onAreaChange((oldValue, newValue) => {
      const nextW = parseFloat(`${newValue.width}`);
      const nextH = parseFloat(`${newValue.height}`);
      if (!Number.isNaN(nextW) && nextW > 0) {
        this.pageWidth = nextW;
      }
      if (!Number.isNaN(nextH) && nextH > 0) {
        this.pageHeight = nextH;
      }
    })
  }
}
