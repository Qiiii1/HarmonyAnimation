import curves from '@ohos.curves';
import { AnimatorResult } from '@kit.ArkUI';
import {
  unlockDirectionalPathCoordinate,
  unlockDirectionalPathLateralCoordinate,
  unlockDirectionalOvershootDistance,
  unlockEaseOutProgress,
  unlockModuleDistanceFalloff,
  unlockReleaseDirection,
} from './UnlockDesktopDirectionalMotion';

@Entry
@Component
struct UnlockDesktopDirectionalPage {
  @State pageWidth: number = 1;
  @State pageHeight: number = 1;
  @State progress: number = 0;
  @State moduleOpacityValue: number = 0;
  @State moduleScaleValue: number = 0.88;
  @State moduleMotionProgress: number = 0;
  @State dragging: boolean = false;
  @State animating: boolean = false;
  @StorageLink('unlockDragFollowFactor') unlockDragFollowFactor: number = 1.5;
  @StorageLink('unlockToHomeDurationMs') unlockToHomeDurationMs: number = 750;
  @StorageLink('unlockIconReboundPercent') unlockIconReboundPercent: number = 15;

  private dragStartX: number = 0;
  private dragStartY: number = 0;
  private dragStartProgress: number = 0;
  private dragDeltaX: number = 0;
  private dragDeltaY: number = 0;
  private releaseDirectionX: number = 0;
  private releaseDirectionY: number = -1;
  private releaseTouchX: number = 0;
  private releaseTouchY: number = 0;
  private animationToken: number = 0;
  private moduleAnimator: AnimatorResult | undefined = undefined;

  private readonly UNLOCK_DRAG_DISTANCE: number = 520;
  private readonly UNLOCK_COMPLETE_THRESHOLD: number = 0.34;
  private readonly LOCKSCREEN_EXIT_END_PROGRESS: number = 0.7;
  private readonly LOCKSCREEN_END_SCALE: number = 1.24;
  private readonly MODULE_TAP_MOVE_TOLERANCE: number = 12;
  private readonly MODULE_GLOBAL_OFFSET_Y: number = -24;
  private readonly DIRECTION_DEAD_ZONE: number = 18;
  private readonly MODULE_START_SCALE: number = 0.88;
  private readonly MODULE_START_OFFSET: number = -520;
  private readonly MODULE_TURN_PROGRESS: number = 0.4980680286858419;
  private readonly MODULE_TURN_LATERAL_OFFSET: number = 12;

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

  private lockscreenExitProgress(): number {
    return this.clamp(this.progress / this.LOCKSCREEN_EXIT_END_PROGRESS, 0, 1);
  }

  private lockscreenScale(): number {
    return this.lerp(1, this.LOCKSCREEN_END_SCALE, Math.pow(this.lockscreenExitProgress(), 0.86));
  }

  private lockscreenOpacity(): number {
    if (this.progress >= 0.999) {
      return 0;
    }
    return 1 - Math.pow(this.lockscreenExitProgress(), 0.92);
  }

  private totalUnlockDurationMs(): number {
    return Math.max(1, Math.floor(this.unlockToHomeDurationMs));
  }

  private moduleStartDelayMs(): number {
    return Math.floor(this.totalUnlockDurationMs() * 0.22);
  }

  private moduleMotionDurationMs(): number {
    return Math.max(1, this.totalUnlockDurationMs() - this.moduleStartDelayMs());
  }

  private moduleOvershootDistance(): number {
    return unlockDirectionalOvershootDistance(this.unlockIconReboundPercent);
  }

  private resetModuleEntrance(): void {
    this.stopModuleAnimator();
    this.moduleOpacityValue = 0;
    this.moduleScaleValue = this.MODULE_START_SCALE;
    this.moduleMotionProgress = 0;
  }

  private updateReleaseDirection(): void {
    const direction = unlockReleaseDirection(this.dragDeltaX, this.dragDeltaY, this.DIRECTION_DEAD_ZONE);
    this.releaseDirectionX = direction.x;
    this.releaseDirectionY = direction.y;
  }

  private prepareModuleStartPosition(): void {
    // Start well behind the gesture, then travel through the home position in the swipe direction.
    // For a right-up swipe this places the icons down-left before they move right-up.
    this.stopModuleAnimator();
    this.moduleOpacityValue = 0;
    this.moduleScaleValue = this.MODULE_START_SCALE;
    this.moduleMotionProgress = 0;
  }

  private playDirectionalModuleEntrance(token: number): void {
    if (token !== this.animationToken) {
      return;
    }

    this.moduleAnimator = this.getUIContext().createAnimator({
      duration: this.moduleMotionDurationMs(),
      easing: 'linear',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 0,
      end: 1
    });
    this.moduleAnimator.onFrame = (value: number): void => {
      if (token !== this.animationToken) {
        return;
      }
      const easedProgress = unlockEaseOutProgress(value);
      this.moduleMotionProgress = easedProgress;
      this.moduleOpacityValue = this.clamp(easedProgress / 0.32, 0, 1);
      this.moduleScaleValue = this.lerp(
        this.MODULE_START_SCALE,
        1,
        easedProgress
      );
    };
    this.moduleAnimator.onFinish = (): void => {
      // Keep the completed animator alive until the next gesture or page teardown.
      // Releasing it here triggers an extra SDK endpoint frame and creates a visible final-position jump.
    };
    this.moduleAnimator.play();
  }

  private stopModuleAnimator(): void {
    if (this.moduleAnimator !== undefined) {
      this.moduleAnimator.onFrame = (): void => {};
      this.moduleAnimator.onFinish = (): void => {};
      this.moduleAnimator.cancel();
      this.moduleAnimator = undefined;
    }
  }

  aboutToDisappear(): void {
    this.animationToken += 1;
    this.stopModuleAnimator();
  }

  private moduleTranslateXValue(
    centerXRatio: number,
    centerYRatio: number,
    motionFactor: number
  ): number {
    const response = this.moduleDistanceFalloff(centerXRatio, centerYRatio) * motionFactor;
    const overshootDistance = this.moduleOvershootDistance();
    const directionalCoordinate = unlockDirectionalPathCoordinate(
      this.moduleMotionProgress,
      this.MODULE_START_OFFSET,
      overshootDistance,
      this.MODULE_TURN_PROGRESS
    );
    const lateralCoordinate = unlockDirectionalPathLateralCoordinate(
      this.moduleMotionProgress,
      this.MODULE_START_OFFSET,
      overshootDistance,
      this.MODULE_TURN_LATERAL_OFFSET,
      this.MODULE_TURN_PROGRESS
    );
    return (this.releaseDirectionX * directionalCoordinate -
      this.releaseDirectionY * lateralCoordinate) * response;
  }

  private moduleTranslateYValue(
    centerXRatio: number,
    centerYRatio: number,
    motionFactor: number
  ): number {
    const response = this.moduleDistanceFalloff(centerXRatio, centerYRatio) * motionFactor;
    const overshootDistance = this.moduleOvershootDistance();
    const directionalCoordinate = unlockDirectionalPathCoordinate(
      this.moduleMotionProgress,
      this.MODULE_START_OFFSET,
      overshootDistance,
      this.MODULE_TURN_PROGRESS
    );
    const lateralCoordinate = unlockDirectionalPathLateralCoordinate(
      this.moduleMotionProgress,
      this.MODULE_START_OFFSET,
      overshootDistance,
      this.MODULE_TURN_LATERAL_OFFSET,
      this.MODULE_TURN_PROGRESS
    );
    return this.MODULE_GLOBAL_OFFSET_Y + (this.releaseDirectionY * directionalCoordinate +
      this.releaseDirectionX * lateralCoordinate) * response;
  }

  private animateTo(target: number): void {
    this.animating = true;
    this.animationToken += 1;
    const token = this.animationToken;

    if (target >= 1) {
      this.prepareModuleStartPosition();
      setTimeout(() => {
        this.playDirectionalModuleEntrance(token);
      }, this.moduleStartDelayMs());
    }

    this.getUIContext().animateTo({
      duration: this.totalUnlockDurationMs(),
      curve: curves.cubicBezierCurve(0.2, 0.9, 0.2, 1),
      onFinish: () => {
        if (token === this.animationToken) {
          this.animating = false;
        }
      }
    }, () => {
      this.progress = target;
      if (target < 1) {
        this.resetModuleEntrance();
      }
    });
  }

  private isUnlockedTap(event: TouchEvent): boolean {
    if (this.dragStartProgress < 0.999 || this.progress < 0.999) {
      return false;
    }
    const moveX = Math.abs(this.primaryTouchX(event) - this.dragStartX);
    const moveY = Math.abs(this.primaryTouchY(event) - this.dragStartY);
    return moveX <= this.MODULE_TAP_MOVE_TOLERANCE && moveY <= this.MODULE_TAP_MOVE_TOLERANCE;
  }

  private handleTouch(event: TouchEvent): void {
    if (this.animating) {
      return;
    }

    if (event.type === TouchType.Down) {
      this.dragging = true;
      this.dragStartX = this.primaryTouchX(event);
      this.dragStartY = this.primaryTouchY(event);
      this.dragStartProgress = this.progress;
      this.dragDeltaX = 0;
      this.dragDeltaY = 0;
      return;
    }

    if (event.type === TouchType.Move && this.dragging) {
      this.dragDeltaX = this.primaryTouchX(event) - this.dragStartX;
      this.dragDeltaY = this.primaryTouchY(event) - this.dragStartY;
      const dragDampingRatio = Math.max(this.unlockDragFollowFactor, 0.01);
      this.progress = this.clamp(
        this.dragStartProgress - this.dragDeltaY / (this.UNLOCK_DRAG_DISTANCE * dragDampingRatio),
        0,
        1
      );
      return;
    }

    if ((event.type === TouchType.Up || event.type === TouchType.Cancel) && this.dragging) {
      this.dragging = false;
      this.dragDeltaX = this.primaryTouchX(event) - this.dragStartX;
      this.dragDeltaY = this.primaryTouchY(event) - this.dragStartY;
      if (event.type === TouchType.Up && this.isUnlockedTap(event)) {
        this.animateTo(0);
        return;
      }
      if (event.type === TouchType.Up && this.progress >= this.UNLOCK_COMPLETE_THRESHOLD) {
        this.releaseTouchX = this.clamp(this.primaryTouchX(event), 0, this.fullFrameWidth());
        this.releaseTouchY = this.clamp(this.primaryTouchY(event), 0, this.fullFrameHeight());
        this.updateReleaseDirection();
        this.animateTo(1);
      } else {
        this.animateTo(0);
      }
    }
  }

  private moduleDistanceFalloff(centerXRatio: number, centerYRatio: number): number {
    return unlockModuleDistanceFalloff(
      this.dragStartX,
      this.dragStartY,
      this.releaseTouchX,
      this.releaseTouchY,
      this.fullFrameWidth() * centerXRatio,
      this.fullFrameHeight() * centerYRatio + this.MODULE_GLOBAL_OFFSET_Y,
      this.fullFrameWidth(),
      this.fullFrameHeight()
    );
  }

  @Builder
  private buildModule(
    resource: Resource,
    centerXRatio: number,
    centerYRatio: number,
    motionFactor: number
  ) {
    Image(resource)
      .width(this.fullFrameWidth())
      .height(this.fullFrameHeight())
      .objectFit(ImageFit.Fill)
      .opacity(this.moduleOpacityValue)
      .scale({
        x: this.moduleScaleValue,
        y: this.moduleScaleValue,
        centerX: `${centerXRatio * 100}%`,
        centerY: `${centerYRatio * 100}%`
      })
      .translate({
        x: this.moduleTranslateXValue(centerXRatio, centerYRatio, motionFactor),
        y: this.moduleTranslateYValue(centerXRatio, centerYRatio, motionFactor)
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

      this.buildModule($r('app.media.module1'), 0.3864, 0.3858, 1.04)
      this.buildModule($r('app.media.module2'), 0.3906, 0.5039, 0.92)
      this.buildModule($r('app.media.module3'), 0.7196, 0.4502, 1.12)
      this.buildModule($r('app.media.module4'), 0.1580, 0.3824, 0.84)
      this.buildModule($r('app.media.module5'), 0.1343, 0.5035, 0.98)
      this.buildModule($r('app.media.module6'), 0.4996, 0.2052, 0.78)
      this.buildModule($r('app.media.module7'), 0.6350, 0.6135, 1.15)
      this.buildModule($r('app.media.module8'), 0.3829, 0.6218, 1.03)
      this.buildModule($r('app.media.module9'), 0.8451, 0.6132, 0.90)
      this.buildModule($r('app.media.module10'), 0.1423, 0.6183, 0.82)
      this.buildModule($r('app.media.module11'), 0.4996, 0.8911, 0.64)

      Image($r('app.media.Background4'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.lockscreenOpacity())
        .scale({ x: this.lockscreenScale(), y: this.lockscreenScale() })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )
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
    .onTouch((event) => {
      this.handleTouch(event);
    })
  }
}
