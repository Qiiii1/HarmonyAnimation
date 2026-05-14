import curves from '@ohos.curves';

@Entry
@Component
struct TaskbarDownPage {
  @State pageWidth: number = 1;
  @State pageHeight: number = 1;
  @State progress: number = 0;
  @State module1Progress: number = 0;
  @State module2Progress: number = 0;
  @State module3Progress: number = 0;
  @State module4Progress: number = 0;
  @State module5Progress: number = 0;
  @State modulePostOpenFollowOffsetY: number = 0;
  @State dragging: boolean = false;
  @State animating: boolean = false;
  @StorageLink('taskbarDownOpenDragDampingRatio') openDragDampingRatio: number = 1.5;
  @StorageLink('taskbarDownModuleEnterDurationMs') moduleEnterTotalDurationMs: number = 750;
  // 模块入场回弹幅度，单位为屏幕高度百分比；2 表示屏幕高度的 2%。
  @StorageLink('taskbarDownModuleReboundPercent') moduleReboundPercent: number = 2;

  private dragStartY: number = 0;
  private dragStartProgress: number = 0;
  private closeDragProgress: number = 1;
  private dragMode: number = 0;
  private moduleAnimationToken: number = 0;

  // Pull-down tuning.
  private readonly PULL_TRIGGER_HEIGHT: number = 190;
  private readonly PANEL_DRAG_DISTANCE: number = 520;
  private readonly PANEL_OPEN_THRESHOLD: number = 0.14;
  private readonly PANEL_CLOSE_THRESHOLD: number = 0.82;
  private readonly DRAG_MODE_OPEN: number = 1;
  private readonly DRAG_MODE_CLOSE: number = 2;
  private readonly DRAG_MODE_OPEN_FOLLOW: number = 3;
  private readonly POST_OPEN_DIRECTION_THRESHOLD: number = 6;
  private readonly BACKGROUND_STAGE_DURATION_MS: number = 120;
  // 主动画时长，单位毫秒。
  // 控制整个下拉打开/上滑收回控制栏的动画时长；值越大越慢，值越小越快。
  private readonly PANEL_DURATION_MS: number = 760;
  private readonly MODULE_POST_OPEN_FOLLOW_FACTOR: number = 0.34;
  private readonly MODULE_POST_OPEN_FOLLOW_MAX_OFFSET_Y: number = 140;
  private readonly MODULE1_POST_OPEN_FOLLOW_FACTOR: number = 0.9;
  private readonly MODULE2_POST_OPEN_FOLLOW_FACTOR: number = 1.0;
  private readonly MODULE3_POST_OPEN_FOLLOW_FACTOR: number = 1.08;
  private readonly MODULE4_POST_OPEN_FOLLOW_FACTOR: number = 1.16;
  private readonly MODULE5_POST_OPEN_FOLLOW_FACTOR: number = 1.24;

  // Background tuning.
  private readonly BACKGROUND_BLUR_MAX: number = 148;
  private readonly BACKGROUND_BLUR_OPACITY: number = 1;
  private readonly BACKGROUND_BLACK_WASH_OPACITY: number = 0.22;
  private readonly BACKGROUND_EFFECT_END_PROGRESS: number = 0.54;
  private readonly BACKGROUND3_END_SCALE: number = 0.94;
  private readonly BACKGROUND3_END_RADIUS: number = 28;
  private readonly BACKGROUND_BLUR_OVERSCAN_SCALE: number = 1.05;

  // Module motion tuning.
  private readonly MODULE_OPEN_SPLIT: number = 0.76;
  private readonly MODULE_OPEN_START_OFFSET_Y: number = -20;
  // module 入场时额外冲过最终位置的进度量。
  // 入场动画会从 0 直接走到 1 + 这个值，再回到 1；值越大，回弹过程越明显。
  private readonly MODULE_REBOUND_PROGRESS: number = 0.18;
  private readonly MODULE_REBOUND_RETURN_DURATION_MS: number = 280;
  private readonly MODULE_START_SCALE: number = 0.965;
  // 缩放回弹幅度。
  // 控制模块松手后会放大到多大再回到正常大小；值越大，缩放回弹越明显。
  private readonly MODULE_PEAK_SCALE: number = 1.014;
  private readonly MODULE_GLOBAL_OFFSET_Y: number = 0;

  // Sequential reveal tuning.
  private readonly MODULE1_START_PROGRESS: number = 0.00;
  private readonly MODULE2_START_PROGRESS: number = 0.02;
  private readonly MODULE3_START_PROGRESS: number = 0.04;
  private readonly MODULE4_START_PROGRESS: number = 0.06;
  private readonly MODULE5_START_PROGRESS: number = 0.08;
  private readonly MODULE1_REVEAL_DURATION: number = 0.24;
  private readonly MODULE2_REVEAL_DURATION: number = 0.24;
  private readonly MODULE3_REVEAL_DURATION: number = 0.24;
  private readonly MODULE4_REVEAL_DURATION: number = 0.24;
  private readonly MODULE5_REVEAL_DURATION: number = 0.24;
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
  private readonly MODULE1_EXTRA_SCALE: number = 1;
  private readonly MODULE2_EXTRA_SCALE: number = 1;
  private readonly MODULE3_EXTRA_SCALE: number = 1;
  private readonly MODULE4_EXTRA_SCALE: number = 1;
  private readonly MODULE5_EXTRA_SCALE: number = 1;

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

  private moduleReboundOffsetY(): number {
    return this.fullFrameHeight() * this.moduleReboundPercent / 100;
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

  private backgroundBlurOpacity(): number {
    const t = this.backgroundEffectProgress();
    return Math.pow(t, 0.8) * this.BACKGROUND_BLUR_OPACITY;
  }

  private backgroundBlurAmount(): number {
    return this.BACKGROUND_BLUR_MAX * this.backgroundEffectProgress();
  }

  private backgroundBlackWashOpacity(): number {
    const t = this.backgroundEffectProgress();
    return Math.pow(t, 0.72) * this.BACKGROUND_BLACK_WASH_OPACITY;
  }

  private backgroundBlurLayerScale(): number {
    return this.lerp(1, this.BACKGROUND_BLUR_OVERSCAN_SCALE, this.backgroundEffectProgress());
  }

  private backgroundEffectProgress(): number {
    const t = this.clamp(this.progress / this.BACKGROUND_EFFECT_END_PROGRESS, 0, 1);
    const smoothT = t * t * (3 - 2 * t);
    return this.lerp(t, smoothT, 0.45);
  }

  private background3Scale(): number {
    return this.lerp(1, this.BACKGROUND3_END_SCALE, this.progress);
  }

  private background3Radius(): number {
    return this.lerp(0, this.BACKGROUND3_END_RADIUS, this.progress);
  }

  private modulesFullyOpen(): boolean {
    return this.module1Progress >= 0.999
      && this.module2Progress >= 0.999
      && this.module3Progress >= 0.999
      && this.module4Progress >= 0.999
      && this.module5Progress >= 0.999;
  }

  private moduleOpenDelayMs(index: number): number {
    switch (index) {
      case 1:
        return this.MODULE1_START_PROGRESS * this.moduleEnterTotalDurationMs;
      case 2:
        return this.MODULE2_START_PROGRESS * this.moduleEnterTotalDurationMs;
      case 3:
        return this.MODULE3_START_PROGRESS * this.moduleEnterTotalDurationMs;
      case 4:
        return this.MODULE4_START_PROGRESS * this.moduleEnterTotalDurationMs;
      default:
        return this.MODULE5_START_PROGRESS * this.moduleEnterTotalDurationMs;
    }
  }

  private moduleOpenDurationMs(index: number): number {
    switch (index) {
      case 1:
        return this.MODULE1_REVEAL_DURATION * this.moduleEnterTotalDurationMs;
      case 2:
        return this.MODULE2_REVEAL_DURATION * this.moduleEnterTotalDurationMs;
      case 3:
        return this.MODULE3_REVEAL_DURATION * this.moduleEnterTotalDurationMs;
      case 4:
        return this.MODULE4_REVEAL_DURATION * this.moduleEnterTotalDurationMs;
      default:
        return this.MODULE5_REVEAL_DURATION * this.moduleEnterTotalDurationMs;
    }
  }

  private setModuleProgress(index: number, value: number): void {
    switch (index) {
      case 1:
        this.module1Progress = value;
        return;
      case 2:
        this.module2Progress = value;
        return;
      case 3:
        this.module3Progress = value;
        return;
      case 4:
        this.module4Progress = value;
        return;
      default:
        this.module5Progress = value;
        return;
    }
  }

  private canStartDrag(startY: number): boolean {
    return this.modulesFullyOpen() || this.progress > 0.001 || startY <= this.PULL_TRIGGER_HEIGHT;
  }

  private easedModuleRevealProgress(progress: number): number {
    const t = this.clamp(progress, 0, 1);
    return t * t * (3 - 2 * t);
  }

  private moduleOpacity(progress: number): number {
    if (progress >= 0.999) {
      return 1;
    }
    const t = this.clamp(progress, 0, 1);
    return 1 - Math.pow(1 - t, 2.3);
  }

  private moduleScale(progress: number, extraScale: number): number {
    const revealT = this.easedModuleRevealProgress(progress);
    if (revealT < this.MODULE_OPEN_SPLIT) {
      return this.lerp(
        this.MODULE_START_SCALE,
        this.MODULE_PEAK_SCALE,
        revealT / this.MODULE_OPEN_SPLIT
      ) * extraScale;
    }
    return this.lerp(
      this.MODULE_PEAK_SCALE,
      1,
      (revealT - this.MODULE_OPEN_SPLIT) / (1 - this.MODULE_OPEN_SPLIT)
    ) * extraScale;
  }

  private moduleTranslateY(
    progress: number,
    extraOffsetY: number,
    postOpenFollowFactor: number
  ): number {
    const revealT = this.easedModuleRevealProgress(this.clamp(progress, 0, 1));
    const motionY = this.lerp(this.MODULE_OPEN_START_OFFSET_Y, 0, revealT);
    const reboundT = this.clamp(
      (progress - 1) / Math.max(this.MODULE_REBOUND_PROGRESS, 0.01),
      0,
      1
    );
    const reboundY = this.moduleReboundOffsetY() * reboundT;
    return this.MODULE_GLOBAL_OFFSET_Y
      + extraOffsetY
      + motionY
      + reboundY
      + this.modulePostOpenFollowOffsetY * postOpenFollowFactor;
  }

  private openTriggerDistance(): number {
    return Math.max(
      (this.PANEL_OPEN_THRESHOLD - this.dragStartProgress)
        * this.PANEL_DRAG_DISTANCE
        * this.openDragDampingRatio,
      0
    );
  }

  private updatePostOpenModuleFollow(deltaY: number): void {
    const extraPull = Math.max(deltaY - this.openTriggerDistance(), 0);
    this.modulePostOpenFollowOffsetY = this.clamp(
      extraPull * this.MODULE_POST_OPEN_FOLLOW_FACTOR,
      0,
      this.MODULE_POST_OPEN_FOLLOW_MAX_OFFSET_Y
    );
  }

  private releasePostOpenModuleFollow(): void {
    if (this.modulePostOpenFollowOffsetY <= 0.001) {
      this.modulePostOpenFollowOffsetY = 0;
      return;
    }
    this.getUIContext().animateTo({
      duration: 220,
      curve: curves.cubicBezierCurve(0.22, 0.82, 0.2, 1)
    }, () => {
      this.modulePostOpenFollowOffsetY = 0;
    });
  }

  private animateBackgroundTo(target: number, onFinish?: () => void): void {
    this.animating = true;
    this.getUIContext().animateTo({
      duration: this.BACKGROUND_STAGE_DURATION_MS,
      curve: curves.cubicBezierCurve(0.2, 0.9, 0.2, 1),
      onFinish: () => {
        if (onFinish) {
          onFinish();
          return;
        }
        this.animating = false;
      }
    }, () => {
      this.progress = target;
    });
  }

  private animateModulesTo(target: number, onFinish?: () => void): void {
    this.moduleAnimationToken += 1;
    const animationToken = this.moduleAnimationToken;
    if (target <= 0) {
      let finishedCount = 0;
      for (let index = 1; index <= 5; index += 1) {
        this.getUIContext().animateTo({
          duration: this.PANEL_DURATION_MS,
          curve: curves.cubicBezierCurve(0.18, 0.88, 0.22, 1),
          onFinish: () => {
            if (animationToken !== this.moduleAnimationToken) {
              return;
            }
            finishedCount += 1;
            if (finishedCount >= 5) {
              if (onFinish) {
                onFinish();
                return;
              }
              this.animating = false;
            }
          }
        }, () => {
          this.setModuleProgress(index, 0);
        });
      }
      return;
    }

    let finishedCount = 0;
    for (let index = 1; index <= 5; index += 1) {
      const delayMs = this.moduleOpenDelayMs(index);
      const durationMs = this.moduleOpenDurationMs(index);
      setTimeout(() => {
        if (animationToken !== this.moduleAnimationToken) {
          return;
        }
        this.getUIContext().animateTo({
          duration: durationMs,
          curve: curves.cubicBezierCurve(0.18, 0.88, 0.22, 1),
          onFinish: () => {
            if (animationToken !== this.moduleAnimationToken) {
              return;
            }
            this.getUIContext().animateTo({
              duration: this.MODULE_REBOUND_RETURN_DURATION_MS,
              curve: curves.cubicBezierCurve(0.2, 0.84, 0.2, 1),
              onFinish: () => {
                if (animationToken !== this.moduleAnimationToken) {
                  return;
                }
                finishedCount += 1;
                if (finishedCount >= 5) {
                  if (onFinish) {
                    onFinish();
                    return;
                  }
                  this.animating = false;
                }
              }
            }, () => {
              this.setModuleProgress(index, 1);
            });
          }
        }, () => {
          this.setModuleProgress(index, 1 + this.MODULE_REBOUND_PROGRESS);
        });
      }, delayMs);
    }
  }

  private animateOpenSequence(): void {
    this.dragMode = this.DRAG_MODE_OPEN_FOLLOW;
    this.animateBackgroundTo(1, () => {
      this.animateModulesTo(1, () => {
        this.animating = false;
      });
    });
  }

  private animateCloseSequence(): void {
    this.dragging = false;
    this.dragMode = 0;
    this.modulePostOpenFollowOffsetY = 0;
    this.animating = true;
    let finishedCount = 0;
    const handleFinish = () => {
      finishedCount += 1;
      if (finishedCount >= 2) {
        this.animating = false;
      }
    };

    this.animateModulesTo(0, () => {
      handleFinish();
    });

    this.getUIContext().animateTo({
      duration: this.PANEL_DURATION_MS,
      curve: curves.cubicBezierCurve(0.18, 0.88, 0.22, 1),
      onFinish: () => {
        handleFinish();
      }
    }, () => {
      this.progress = 0;
    });
  }

  private animateBackgroundBackToClosed(): void {
    this.dragging = false;
    this.dragMode = 0;
    this.modulePostOpenFollowOffsetY = 0;
    this.animateBackgroundTo(0, () => {
      this.animating = false;
    });
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
      this.dragStartY = startY;
      this.dragStartProgress = this.progress;
      this.closeDragProgress = 1;
      this.modulePostOpenFollowOffsetY = 0;
      this.dragMode = this.modulesFullyOpen() ? 0 : this.DRAG_MODE_OPEN;
      return;
    }

    if (event.type === TouchType.Move && this.dragging) {
      const deltaY = this.primaryTouchY(event) - this.dragStartY;

      if (this.dragMode === 0 && this.modulesFullyOpen()) {
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
        if (nextProgress >= this.PANEL_OPEN_THRESHOLD) {
          this.animateOpenSequence();
        }
        return;
      }

      if (this.dragMode === this.DRAG_MODE_OPEN_FOLLOW) {
        this.updatePostOpenModuleFollow(deltaY);
        return;
      }

      if (this.dragMode === this.DRAG_MODE_CLOSE) {
        const nextCloseProgress = this.clamp(1 + deltaY / this.PANEL_DRAG_DISTANCE, 0, 1);
        this.closeDragProgress = nextCloseProgress;
        if (nextCloseProgress <= this.PANEL_CLOSE_THRESHOLD) {
          this.animateCloseSequence();
        }
      }
      return;
    }

    if ((event.type === TouchType.Up || event.type === TouchType.Cancel) && this.dragging) {
      this.dragging = false;
      if (this.dragMode === this.DRAG_MODE_OPEN) {
        if (this.progress >= this.PANEL_OPEN_THRESHOLD) {
          this.animateOpenSequence();
        } else {
          this.animateBackgroundBackToClosed();
        }
      } else if (this.dragMode === this.DRAG_MODE_OPEN_FOLLOW) {
        this.releasePostOpenModuleFollow();
      } else if (this.dragMode === this.DRAG_MODE_CLOSE) {
        if (this.closeDragProgress <= this.PANEL_CLOSE_THRESHOLD) {
          this.animateCloseSequence();
        }
      }
      this.dragMode = 0;
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

      Image($r('app.media.Background2'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .blur(this.backgroundBlurAmount())
        .opacity(this.backgroundBlurOpacity())
        .scale({
          x: this.backgroundBlurLayerScale(),
          y: this.backgroundBlurLayerScale()
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.Background3'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .scale({
          x: this.background3Scale(),
          y: this.background3Scale()
        })
        .borderRadius(this.background3Radius())
        .clip(true)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.Background3'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .blur(this.backgroundBlurAmount())
        .opacity(this.backgroundBlurOpacity())
        .scale({
          x: this.background3Scale() * this.backgroundBlurLayerScale(),
          y: this.background3Scale() * this.backgroundBlurLayerScale()
        })
        .borderRadius(this.background3Radius())
        .clip(true)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Column()
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .backgroundColor(Color.Black)
        .opacity(this.backgroundBlackWashOpacity())
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.ControlModule1'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.moduleOpacity(this.module1Progress))
        .scale({
          x: this.moduleScale(this.module1Progress, this.MODULE1_EXTRA_SCALE),
          y: this.moduleScale(this.module1Progress, this.MODULE1_EXTRA_SCALE)
        })
        .translate({
          x: this.MODULE1_OFFSET_X,
          y: this.moduleTranslateY(
            this.module1Progress,
            this.MODULE1_OFFSET_Y,
            this.MODULE1_POST_OPEN_FOLLOW_FACTOR
          )
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.ControlModule2'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.moduleOpacity(this.module2Progress))
        .scale({
          x: this.moduleScale(this.module2Progress, this.MODULE2_EXTRA_SCALE),
          y: this.moduleScale(this.module2Progress, this.MODULE2_EXTRA_SCALE)
        })
        .translate({
          x: this.MODULE2_OFFSET_X,
          y: this.moduleTranslateY(
            this.module2Progress,
            this.MODULE2_OFFSET_Y,
            this.MODULE2_POST_OPEN_FOLLOW_FACTOR
          )
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.ControlModule3'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.moduleOpacity(this.module3Progress))
        .scale({
          x: this.moduleScale(this.module3Progress, this.MODULE3_EXTRA_SCALE),
          y: this.moduleScale(this.module3Progress, this.MODULE3_EXTRA_SCALE)
        })
        .translate({
          x: this.MODULE3_OFFSET_X,
          y: this.moduleTranslateY(
            this.module3Progress,
            this.MODULE3_OFFSET_Y,
            this.MODULE3_POST_OPEN_FOLLOW_FACTOR
          )
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.ControlModule4'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.moduleOpacity(this.module4Progress))
        .scale({
          x: this.moduleScale(this.module4Progress, this.MODULE4_EXTRA_SCALE),
          y: this.moduleScale(this.module4Progress, this.MODULE4_EXTRA_SCALE)
        })
        .translate({
          x: this.MODULE4_OFFSET_X,
          y: this.moduleTranslateY(
            this.module4Progress,
            this.MODULE4_OFFSET_Y,
            this.MODULE4_POST_OPEN_FOLLOW_FACTOR
          )
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.ControlModule5'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .opacity(this.moduleOpacity(this.module5Progress))
        .scale({
          x: this.moduleScale(this.module5Progress, this.MODULE5_EXTRA_SCALE),
          y: this.moduleScale(this.module5Progress, this.MODULE5_EXTRA_SCALE)
        })
        .translate({
          x: this.MODULE5_OFFSET_X,
          y: this.moduleTranslateY(
            this.module5Progress,
            this.MODULE5_OFFSET_Y,
            this.MODULE5_POST_OPEN_FOLLOW_FACTOR
          )
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

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
