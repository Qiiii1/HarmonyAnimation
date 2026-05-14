import curves from '@ohos.curves';

@Entry
@Component
struct UnlockDesktopPage {
  @State pageWidth: number = 1;
  @State pageHeight: number = 1;
  // 第一段进度：只控制 Background4 锁屏层放大和渐隐。
  @State progress: number = 0;
  // 第二段进度：松手确认解锁后，才控制 module 放大、渐入和回弹。
  @State moduleProgress: number = 0;
  @State module1OpacityValue: number = 0;
  @State module2OpacityValue: number = 0;
  @State module3OpacityValue: number = 0;
  @State module4OpacityValue: number = 0;
  @State module5OpacityValue: number = 0;
  @State module6OpacityValue: number = 0;
  @State module7OpacityValue: number = 0;
  @State module8OpacityValue: number = 0;
  @State module9OpacityValue: number = 0;
  @State module10OpacityValue: number = 0;
  @State module11OpacityValue: number = 0;
  @State module1ScaleValue: number = 0.62;
  @State module2ScaleValue: number = 0.72;
  @State module3ScaleValue: number = 0.66;
  @State module4ScaleValue: number = 0.68;
  @State module5ScaleValue: number = 0.7;
  @State module6ScaleValue: number = 0.64;
  @State module7ScaleValue: number = 0.7;
  @State module8ScaleValue: number = 0.66;
  @State module9ScaleValue: number = 0.72;
  @State module10ScaleValue: number = 0.68;
  @State module11ScaleValue: number = 0.72;
  @State dragging: boolean = false;
  @State animating: boolean = false;
  // 解锁上划阻尼比。
  // 控制手指上划时，动画进度跟随手指位移的灵敏度；1 为基线，值越大越沉，值越小越跟手。
  @StorageLink('unlockDragFollowFactor') unlockDragFollowFactor: number = 1.5;
  // 解锁主动画时长，单位毫秒。
  // 控制从解锁动效触发到进入第一屏完成所需的持续时间；值越大越慢。
  @StorageLink('unlockToHomeDurationMs') unlockToHomeDurationMs: number = 750;
  // 解锁进入第一屏后图标回弹幅度，单位百分比。
  // 例如 6 表示图标会先放大到 106% 再回到 100%。
  @StorageLink('unlockIconReboundPercent') unlockIconReboundPercent: number = 15;

  private dragStartY: number = 0;
  private dragStartX: number = 0;
  private dragStartProgress: number = 0;
  private moduleAnimationToken: number = 0;

  private readonly UNLOCK_DRAG_DISTANCE: number = 520;
  private readonly UNLOCK_COMPLETE_THRESHOLD: number = 0.34;
  private readonly LOCKSCREEN_EXIT_END_PROGRESS: number = 0.7;
  private readonly LOCKSCREEN_END_SCALE: number = 1.24;
  private readonly MODULE_TAP_MOVE_TOLERANCE: number = 12;
  // module 入场启动点：占解锁总时长的比例。
  // 例如 0.28 表示松手后动画跑到 28% 时，module 开始渐入和回弹，避免先空屏再突然弹出。
  private readonly MODULE_RELEASE_START_RATIO: number = 0.28;

  // Module reveal tuning.
  private readonly MODULE1_START_PROGRESS: number = 0;
  private readonly MODULE2_START_PROGRESS: number = 0.18;
  private readonly MODULE3_START_PROGRESS: number = 0.18;
  private readonly MODULE4_START_PROGRESS: number = 0.34;
  private readonly MODULE5_START_PROGRESS: number = 0.5;
  private readonly MODULE6_START_PROGRESS: number = 0.5;
  private readonly MODULE7_START_PROGRESS: number = 0.66;
  private readonly MODULE8_START_PROGRESS: number = 0.8;
  private readonly MODULE9_START_PROGRESS: number = 0.94;
  private readonly MODULE10_START_PROGRESS: number = 1.08;
  private readonly MODULE11_START_PROGRESS: number = 1.22;
  private readonly MODULE1_REVEAL_DURATION: number = 0.66;
  private readonly MODULE2_REVEAL_DURATION: number = 0.72;
  private readonly MODULE3_REVEAL_DURATION: number = 0.78;
  private readonly MODULE4_REVEAL_DURATION: number = 0.78;
  private readonly MODULE5_REVEAL_DURATION: number = 0.8;
  private readonly MODULE6_REVEAL_DURATION: number = 0.8;
  private readonly MODULE7_REVEAL_DURATION: number = 0.82;
  private readonly MODULE8_REVEAL_DURATION: number = 0.82;
  private readonly MODULE9_REVEAL_DURATION: number = 0.84;
  private readonly MODULE10_REVEAL_DURATION: number = 0.84;
  private readonly MODULE11_REVEAL_DURATION: number = 0.86;
  private readonly MODULE1_START_SCALE: number = 0.48;
  private readonly MODULE2_START_SCALE: number = 0.54;
  private readonly MODULE3_START_SCALE: number = 0.5;
  private readonly MODULE4_START_SCALE: number = 0.52;
  private readonly MODULE5_START_SCALE: number = 0.56;
  private readonly MODULE6_START_SCALE: number = 0.48;
  private readonly MODULE7_START_SCALE: number = 0.56;
  private readonly MODULE8_START_SCALE: number = 0.5;
  private readonly MODULE9_START_SCALE: number = 0.58;
  private readonly MODULE10_START_SCALE: number = 0.52;
  private readonly MODULE11_START_SCALE: number = 0.58;
  // module 透明度渐入时长系数，数值越大，module 从透明到完全显示越慢。
  private readonly MODULE_OPACITY_DURATION_RATIO: number = 1.35;
  // module 回弹入场第一段占比：先放大到“回弹幅度”指定的峰值，再自然回正。
  private readonly MODULE_REBOUND_FORWARD_RATIO: number = 0.56;
  // module 入场动画延迟系数：保留 module 之间的先后差异，但避免差距过大。
  private readonly MODULE_STAGGER_DELAY_RATIO: number = 1.08;
  // Negative moves all modules upward, positive moves them downward.
  private readonly MODULE_GLOBAL_OFFSET_Y: number = -24;
  private readonly MODULE1_OFFSET_X: number = 0;
  private readonly MODULE1_OFFSET_Y: number = 0;
  private readonly MODULE2_OFFSET_X: number = 0;
  private readonly MODULE2_OFFSET_Y: number = 0;
  private readonly MODULE3_OFFSET_X: number = 0;
  private readonly MODULE3_OFFSET_Y: number = 0;
  private readonly MODULE4_OFFSET_X: number = 0;
  private readonly MODULE4_OFFSET_Y: number = 0;
  private readonly MODULE5_OFFSET_X: number = 0;
  private readonly MODULE5_OFFSET_Y: number = 0;
  private readonly MODULE6_OFFSET_X: number = 0;
  private readonly MODULE6_OFFSET_Y: number = 0;
  private readonly MODULE7_OFFSET_X: number = 0;
  private readonly MODULE7_OFFSET_Y: number = 0;
  private readonly MODULE8_OFFSET_X: number = 0;
  private readonly MODULE8_OFFSET_Y: number = 0;
  private readonly MODULE9_OFFSET_X: number = 0;
  private readonly MODULE9_OFFSET_Y: number = 0;
  private readonly MODULE10_OFFSET_X: number = 0;
  private readonly MODULE10_OFFSET_Y: number = 0;
  private readonly MODULE11_OFFSET_X: number = 0;
  private readonly MODULE11_OFFSET_Y: number = 0;
  private readonly MODULE1_EXTRA_SCALE: number = 1;
  private readonly MODULE2_EXTRA_SCALE: number = 1;
  private readonly MODULE3_EXTRA_SCALE: number = 1;
  private readonly MODULE4_EXTRA_SCALE: number = 1;
  private readonly MODULE5_EXTRA_SCALE: number = 1;
  private readonly MODULE6_EXTRA_SCALE: number = 1;
  private readonly MODULE7_EXTRA_SCALE: number = 1;
  private readonly MODULE8_EXTRA_SCALE: number = 1;
  private readonly MODULE9_EXTRA_SCALE: number = 1;
  private readonly MODULE10_EXTRA_SCALE: number = 1;
  private readonly MODULE11_EXTRA_SCALE: number = 1;

  private clamp(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }

  private lerp(start: number, end: number, t: number): number {
    return start + (end - start) * t;
  }

  private easeOut(value: number, power: number = 2): number {
    const t = this.clamp(value, 0, 1);
    return 1 - Math.pow(1 - t, power);
  }

  private fullFrameWidth(): number {
    return Math.max(this.pageWidth, 1);
  }

  private fullFrameHeight(): number {
    return Math.max(this.pageHeight, 1);
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

  private primaryTouchX(event: TouchEvent): number {
    if (event.touches.length > 0) {
      return event.touches[0].windowX;
    }
    if (event.changedTouches.length > 0) {
      return event.changedTouches[0].windowX;
    }
    return this.dragStartX;
  }

  private isFullyUnlocked(): boolean {
    return this.progress >= 1;
  }

  private lockscreenExitProgress(): number {
    return this.clamp(this.progress / this.LOCKSCREEN_EXIT_END_PROGRESS, 0, 1);
  }

  private lockscreenScale(): number {
    return this.lerp(1, this.LOCKSCREEN_END_SCALE, Math.pow(this.lockscreenExitProgress(), 0.86));
  }

  private lockscreenOpacity(): number {
    if (this.isFullyUnlocked()) {
      return 0;
    }
    return 1 - Math.pow(this.lockscreenExitProgress(), 0.92);
  }

  private iconReboundScale(): number {
    return 1 + this.unlockIconReboundPercent / 100;
  }

  private totalUnlockDurationMs(): number {
    return Math.max(1, Math.floor(this.unlockToHomeDurationMs));
  }

  private moduleReleaseStartDelayMs(): number {
    return Math.max(0, Math.floor(this.totalUnlockDurationMs() * this.MODULE_RELEASE_START_RATIO));
  }

  private moduleTimelineDurationMs(): number {
    return Math.max(1, this.totalUnlockDurationMs() - this.moduleReleaseStartDelayMs());
  }

  private moduleTimelineEndProgress(): number {
    let endProgress = this.MODULE1_START_PROGRESS + this.MODULE1_REVEAL_DURATION;
    endProgress = Math.max(endProgress, this.MODULE2_START_PROGRESS + this.MODULE2_REVEAL_DURATION);
    endProgress = Math.max(endProgress, this.MODULE3_START_PROGRESS + this.MODULE3_REVEAL_DURATION);
    endProgress = Math.max(endProgress, this.MODULE4_START_PROGRESS + this.MODULE4_REVEAL_DURATION);
    endProgress = Math.max(endProgress, this.MODULE5_START_PROGRESS + this.MODULE5_REVEAL_DURATION);
    endProgress = Math.max(endProgress, this.MODULE6_START_PROGRESS + this.MODULE6_REVEAL_DURATION);
    endProgress = Math.max(endProgress, this.MODULE7_START_PROGRESS + this.MODULE7_REVEAL_DURATION);
    endProgress = Math.max(endProgress, this.MODULE8_START_PROGRESS + this.MODULE8_REVEAL_DURATION);
    endProgress = Math.max(endProgress, this.MODULE9_START_PROGRESS + this.MODULE9_REVEAL_DURATION);
    endProgress = Math.max(endProgress, this.MODULE10_START_PROGRESS + this.MODULE10_REVEAL_DURATION);
    return Math.max(endProgress, this.MODULE11_START_PROGRESS + this.MODULE11_REVEAL_DURATION);
  }

  private moduleEnterDelayMs(start: number): number {
    return Math.floor(
      this.moduleTimelineDurationMs() * start * this.MODULE_STAGGER_DELAY_RATIO /
        Math.max(this.moduleTimelineEndProgress(), 0.01)
    );
  }

  private moduleEnterDurationMs(durationRatio: number): number {
    return Math.max(
      1,
      Math.floor(this.moduleTimelineDurationMs() * durationRatio / Math.max(this.moduleTimelineEndProgress(), 0.01))
    );
  }

  private moduleReboundForwardDurationMs(durationMs: number): number {
    return Math.max(1, Math.floor(durationMs * this.MODULE_REBOUND_FORWARD_RATIO));
  }

  private moduleReboundReturnDurationMs(durationMs: number): number {
    return Math.max(1, durationMs - this.moduleReboundForwardDurationMs(durationMs));
  }

  private moduleOpacityDurationMs(durationMs: number): number {
    return Math.max(1, Math.floor(durationMs * this.MODULE_OPACITY_DURATION_RATIO));
  }

  private moduleSpringDamping(): number {
    const normalizedRebound = this.clamp(this.unlockIconReboundPercent / 30, 0, 1);
    return this.lerp(0.86, 0.52, normalizedRebound);
  }

  private resetModuleEntrance(): void {
    this.moduleProgress = 0;
    this.module1OpacityValue = 0;
    this.module2OpacityValue = 0;
    this.module3OpacityValue = 0;
    this.module4OpacityValue = 0;
    this.module5OpacityValue = 0;
    this.module6OpacityValue = 0;
    this.module7OpacityValue = 0;
    this.module8OpacityValue = 0;
    this.module9OpacityValue = 0;
    this.module10OpacityValue = 0;
    this.module11OpacityValue = 0;
    this.module1ScaleValue = this.MODULE1_START_SCALE;
    this.module2ScaleValue = this.MODULE2_START_SCALE;
    this.module3ScaleValue = this.MODULE3_START_SCALE;
    this.module4ScaleValue = this.MODULE4_START_SCALE;
    this.module5ScaleValue = this.MODULE5_START_SCALE;
    this.module6ScaleValue = this.MODULE6_START_SCALE;
    this.module7ScaleValue = this.MODULE7_START_SCALE;
    this.module8ScaleValue = this.MODULE8_START_SCALE;
    this.module9ScaleValue = this.MODULE9_START_SCALE;
    this.module10ScaleValue = this.MODULE10_START_SCALE;
    this.module11ScaleValue = this.MODULE11_START_SCALE;
  }

  private isUnlockedModuleTap(event: TouchEvent): boolean {
    if (this.dragStartProgress < 0.999 || this.progress < 0.999 || this.moduleProgress < 0.999) {
      return false;
    }

    const moveX = Math.abs(this.primaryTouchX(event) - this.dragStartX);
    const moveY = Math.abs(this.primaryTouchY(event) - this.dragStartY);
    return moveX <= this.MODULE_TAP_MOVE_TOLERANCE && moveY <= this.MODULE_TAP_MOVE_TOLERANCE;
  }

  private setModuleOpacity(index: number, value: number): void {
    if (index === 1) {
      this.module1OpacityValue = value;
    } else if (index === 2) {
      this.module2OpacityValue = value;
    } else if (index === 3) {
      this.module3OpacityValue = value;
    } else if (index === 4) {
      this.module4OpacityValue = value;
    } else if (index === 5) {
      this.module5OpacityValue = value;
    } else if (index === 6) {
      this.module6OpacityValue = value;
    } else if (index === 7) {
      this.module7OpacityValue = value;
    } else if (index === 8) {
      this.module8OpacityValue = value;
    } else if (index === 9) {
      this.module9OpacityValue = value;
    } else if (index === 10) {
      this.module10OpacityValue = value;
    } else {
      this.module11OpacityValue = value;
    }
  }

  private setModuleScale(index: number, value: number): void {
    if (index === 1) {
      this.module1ScaleValue = value;
    } else if (index === 2) {
      this.module2ScaleValue = value;
    } else if (index === 3) {
      this.module3ScaleValue = value;
    } else if (index === 4) {
      this.module4ScaleValue = value;
    } else if (index === 5) {
      this.module5ScaleValue = value;
    } else if (index === 6) {
      this.module6ScaleValue = value;
    } else if (index === 7) {
      this.module7ScaleValue = value;
    } else if (index === 8) {
      this.module8ScaleValue = value;
    } else if (index === 9) {
      this.module9ScaleValue = value;
    } else if (index === 10) {
      this.module10ScaleValue = value;
    } else {
      this.module11ScaleValue = value;
    }
  }

  private playSingleModuleEntrance(index: number, delayMs: number, durationMs: number): void {
    const token = this.moduleAnimationToken;
    setTimeout(() => {
      if (token !== this.moduleAnimationToken) {
        return;
      }

      const forwardDuration = this.moduleReboundForwardDurationMs(durationMs);
      const returnDuration = this.moduleReboundReturnDurationMs(durationMs);

      this.getUIContext().animateTo({
        duration: this.moduleOpacityDurationMs(durationMs),
        curve: curves.cubicBezierCurve(0.18, 0.62, 0.24, 1)
      }, () => {
        this.setModuleOpacity(index, 1);
      });

      this.getUIContext().animateTo({
        duration: forwardDuration,
        curve: curves.cubicBezierCurve(0.16, 0.92, 0.24, 1)
      }, () => {
        this.setModuleScale(index, this.iconReboundScale());
      });

      setTimeout(() => {
        if (token !== this.moduleAnimationToken) {
          return;
        }

        this.getUIContext().animateTo({
          duration: returnDuration,
          curve: curves.springMotion(0.24, this.moduleSpringDamping(), 0)
        }, () => {
          this.setModuleScale(index, 1);
        });
      }, forwardDuration);
    }, delayMs);
  }

  private playModuleEntrance(): void {
    this.moduleAnimationToken += 1;
    this.resetModuleEntrance();
    const token = this.moduleAnimationToken;

    this.playSingleModuleEntrance(
      1,
      this.moduleEnterDelayMs(this.MODULE1_START_PROGRESS),
      this.moduleEnterDurationMs(this.MODULE1_REVEAL_DURATION)
    );
    this.playSingleModuleEntrance(
      2,
      this.moduleEnterDelayMs(this.MODULE2_START_PROGRESS),
      this.moduleEnterDurationMs(this.MODULE2_REVEAL_DURATION)
    );
    this.playSingleModuleEntrance(
      3,
      this.moduleEnterDelayMs(this.MODULE3_START_PROGRESS),
      this.moduleEnterDurationMs(this.MODULE3_REVEAL_DURATION)
    );
    this.playSingleModuleEntrance(
      4,
      this.moduleEnterDelayMs(this.MODULE4_START_PROGRESS),
      this.moduleEnterDurationMs(this.MODULE4_REVEAL_DURATION)
    );
    this.playSingleModuleEntrance(
      5,
      this.moduleEnterDelayMs(this.MODULE5_START_PROGRESS),
      this.moduleEnterDurationMs(this.MODULE5_REVEAL_DURATION)
    );
    this.playSingleModuleEntrance(
      6,
      this.moduleEnterDelayMs(this.MODULE6_START_PROGRESS),
      this.moduleEnterDurationMs(this.MODULE6_REVEAL_DURATION)
    );
    this.playSingleModuleEntrance(
      7,
      this.moduleEnterDelayMs(this.MODULE7_START_PROGRESS),
      this.moduleEnterDurationMs(this.MODULE7_REVEAL_DURATION)
    );
    this.playSingleModuleEntrance(
      8,
      this.moduleEnterDelayMs(this.MODULE8_START_PROGRESS),
      this.moduleEnterDurationMs(this.MODULE8_REVEAL_DURATION)
    );
    this.playSingleModuleEntrance(
      9,
      this.moduleEnterDelayMs(this.MODULE9_START_PROGRESS),
      this.moduleEnterDurationMs(this.MODULE9_REVEAL_DURATION)
    );
    this.playSingleModuleEntrance(
      10,
      this.moduleEnterDelayMs(this.MODULE10_START_PROGRESS),
      this.moduleEnterDurationMs(this.MODULE10_REVEAL_DURATION)
    );
    this.playSingleModuleEntrance(
      11,
      this.moduleEnterDelayMs(this.MODULE11_START_PROGRESS),
      this.moduleEnterDurationMs(this.MODULE11_REVEAL_DURATION)
    );

    setTimeout(() => {
      if (token !== this.moduleAnimationToken) {
        return;
      }
      this.animating = false;
      this.moduleProgress = 1;
    }, this.moduleTimelineDurationMs());
  }

  private animateTo(target: number): void {
    this.animating = true;
    this.moduleAnimationToken += 1;
    const token = this.moduleAnimationToken;
    if (target >= 1) {
      this.resetModuleEntrance();
    }

    if (target >= 1) {
      setTimeout(() => {
        if (token !== this.moduleAnimationToken) {
          return;
        }
        this.playModuleEntrance();
      }, this.moduleReleaseStartDelayMs());
    }

    this.getUIContext().animateTo({
      duration: this.totalUnlockDurationMs(),
      curve: curves.cubicBezierCurve(0.2, 0.9, 0.2, 1),
      onFinish: () => {
        if (target < 1) {
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

  private handleTouch(event: TouchEvent): void {
    if (this.animating) {
      return;
    }

    if (event.type === TouchType.Down) {
      this.dragging = true;
      this.dragStartX = this.primaryTouchX(event);
      this.dragStartY = this.primaryTouchY(event);
      this.dragStartProgress = this.progress;
      return;
    }

    if (event.type === TouchType.Move && this.dragging) {
      const deltaY = this.dragStartY - this.primaryTouchY(event);
      const dragDampingRatio = Math.max(this.unlockDragFollowFactor, 0.01);
      const nextProgress = this.clamp(
        this.dragStartProgress + deltaY / (this.UNLOCK_DRAG_DISTANCE * dragDampingRatio),
        0,
        1
      );
      this.progress = nextProgress;
      if (this.dragStartProgress < 0.999) {
        this.moduleProgress = 0;
      } else {
        this.moduleProgress = nextProgress;
      }
      return;
    }

    if ((event.type === TouchType.Up || event.type === TouchType.Cancel) && this.dragging) {
      this.dragging = false;
      if (event.type === TouchType.Up && this.isUnlockedModuleTap(event)) {
        this.animateTo(0);
        return;
      }
      this.animateTo(this.progress >= this.UNLOCK_COMPLETE_THRESHOLD ? 1 : 0);
    }
  }

  build() {
    Stack() {
      Image($r('app.media.Background2'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.module1'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.module1OpacityValue)
        .scale({
          x: this.module1ScaleValue * this.MODULE1_EXTRA_SCALE,
          y: this.module1ScaleValue * this.MODULE1_EXTRA_SCALE
        })
        .translate({
          x: this.MODULE1_OFFSET_X,
          y: this.MODULE_GLOBAL_OFFSET_Y + this.MODULE1_OFFSET_Y
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.module2'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.module2OpacityValue)
        .scale({
          x: this.module2ScaleValue * this.MODULE2_EXTRA_SCALE,
          y: this.module2ScaleValue * this.MODULE2_EXTRA_SCALE
        })
        .translate({
          x: this.MODULE2_OFFSET_X,
          y: this.MODULE_GLOBAL_OFFSET_Y + this.MODULE2_OFFSET_Y
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.module3'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.module3OpacityValue)
        .scale({
          x: this.module3ScaleValue * this.MODULE3_EXTRA_SCALE,
          y: this.module3ScaleValue * this.MODULE3_EXTRA_SCALE
        })
        .translate({
          x: this.MODULE3_OFFSET_X,
          y: this.MODULE_GLOBAL_OFFSET_Y + this.MODULE3_OFFSET_Y
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.module4'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.module4OpacityValue)
        .scale({
          x: this.module4ScaleValue * this.MODULE4_EXTRA_SCALE,
          y: this.module4ScaleValue * this.MODULE4_EXTRA_SCALE
        })
        .translate({
          x: this.MODULE4_OFFSET_X,
          y: this.MODULE_GLOBAL_OFFSET_Y + this.MODULE4_OFFSET_Y
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.module5'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.module5OpacityValue)
        .scale({
          x: this.module5ScaleValue * this.MODULE5_EXTRA_SCALE,
          y: this.module5ScaleValue * this.MODULE5_EXTRA_SCALE
        })
        .translate({
          x: this.MODULE5_OFFSET_X,
          y: this.MODULE_GLOBAL_OFFSET_Y + this.MODULE5_OFFSET_Y
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.module6'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.module6OpacityValue)
        .scale({
          x: this.module6ScaleValue * this.MODULE6_EXTRA_SCALE,
          y: this.module6ScaleValue * this.MODULE6_EXTRA_SCALE
        })
        .translate({
          x: this.MODULE6_OFFSET_X,
          y: this.MODULE_GLOBAL_OFFSET_Y + this.MODULE6_OFFSET_Y
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.module7'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.module7OpacityValue)
        .scale({
          x: this.module7ScaleValue * this.MODULE7_EXTRA_SCALE,
          y: this.module7ScaleValue * this.MODULE7_EXTRA_SCALE
        })
        .translate({
          x: this.MODULE7_OFFSET_X,
          y: this.MODULE_GLOBAL_OFFSET_Y + this.MODULE7_OFFSET_Y
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.module8'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.module8OpacityValue)
        .scale({
          x: this.module8ScaleValue * this.MODULE8_EXTRA_SCALE,
          y: this.module8ScaleValue * this.MODULE8_EXTRA_SCALE
        })
        .translate({
          x: this.MODULE8_OFFSET_X,
          y: this.MODULE_GLOBAL_OFFSET_Y + this.MODULE8_OFFSET_Y
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.module9'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.module9OpacityValue)
        .scale({
          x: this.module9ScaleValue * this.MODULE9_EXTRA_SCALE,
          y: this.module9ScaleValue * this.MODULE9_EXTRA_SCALE
        })
        .translate({
          x: this.MODULE9_OFFSET_X,
          y: this.MODULE_GLOBAL_OFFSET_Y + this.MODULE9_OFFSET_Y
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.module10'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.module10OpacityValue)
        .scale({
          x: this.module10ScaleValue * this.MODULE10_EXTRA_SCALE,
          y: this.module10ScaleValue * this.MODULE10_EXTRA_SCALE
        })
        .translate({
          x: this.MODULE10_OFFSET_X,
          y: this.MODULE_GLOBAL_OFFSET_Y + this.MODULE10_OFFSET_Y
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.module11'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.module11OpacityValue)
        .scale({
          x: this.module11ScaleValue * this.MODULE11_EXTRA_SCALE,
          y: this.module11ScaleValue * this.MODULE11_EXTRA_SCALE
        })
        .translate({
          x: this.MODULE11_OFFSET_X,
          y: this.MODULE_GLOBAL_OFFSET_Y + this.MODULE11_OFFSET_Y
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.Background4'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.lockscreenOpacity())
        .scale({
          x: this.lockscreenScale(),
          y: this.lockscreenScale()
        })
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
