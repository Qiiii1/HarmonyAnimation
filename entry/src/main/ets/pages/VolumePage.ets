import curves from '@ohos.curves';

@Entry
@Component
struct VolumePage {
  @State pageWidth: number = 1;
  @State pageHeight: number = 1;
  @State volumeProgress: number = 0.52;
  @State dragStartProgress: number = 0.52;
  @State dragStartWindowY: number = 0;
  @State activeProgress: number = 0;
  @State edgeMorphProgress: number = 0;
  @State edgeDirection: number = 0;
  @State widthShrinkProgress: number = 0;
  @State buttonTapCount: number = 0;
  @State buttonPulseProgress: number = 0;
  @State buttonPulseDirection: number = 0;
  @State buttonWidthPulseProgress: number = 0;
  @State buttonWidthPulseDirection: number = 0;
  @StorageLink('volumeButtonWidthPulseDurationMs') buttonWidthPulseDurationMs: number = 750;
  @StorageLink('volumeButtonWidthPulsePercent') buttonWidthPulsePercent: number = 15;
  @StorageLink('volumeInteractionWidthReboundPercent') interactionWidthReboundPercent: number = 15;
  @StorageLink('volumeInteractionWidthReboundDurationMs') interactionWidthReboundDurationMs: number = 750;
  @StorageLink('volumeInteractionDragDampingRatio') interactionDragDampingRatio: number = 1.0;

  private buttonWidthPulseToken: number = 0;

  // Volume slider tuning.
  // `TRACK_HEIGHT` controls the overall slider length.
  // `EDGE_TRIGGER_OVERFLOW` controls how much extra drag is needed after reaching the top/bottom before edge morph starts.
  private readonly CONTROL_BOTTOM: number = 170;
  private readonly CONTROL_OFFSET_X: number = 120;
  // Positive moves down, negative moves up.
  private readonly CONTROL_OFFSET_Y: number = -406;
  private readonly TRACK_TOUCH_COLOR: string = '#01000000';
  private readonly TRACK_WIDTH: number = 41;
  private readonly SHRUNK_TRACK_WIDTH: number = 10;
  private readonly TRACK_TOUCH_WIDTH: number = 92;
  // 放大/正常宽度状态下，点击一次 `+ / -` 就进入缩小状态。
  private readonly BUTTON_SHRINK_TRIGGER_COUNT: number = 1;
  private readonly TRACK_HEIGHT: number = 160;
  private readonly TRACK_RADIUS: number = 38;
  private readonly TRACK_RGB_HEX: string = '101010';
  private readonly TRACK_OPACITY: number = 0.70;
  private readonly TRACK_BACKDROP_BLUR: number = 74;
  private readonly TRACK_SHADOW_ALPHA: number = 0x20;
  private readonly TRACK_SHADOW_RADIUS: number = 20;
  private readonly TRACK_SHADOW_OFFSET_Y: number = 10;
  private readonly FILL_COLOR: string = '#FFFFFF';
  private readonly FILL_MIN_HEIGHT: number = 0;
  // 音量条现在主要调这 5 个参数：
  // 1. `buttonWidthPulseDurationMs`
  //    单次触发按键后，音量条从轻微外扩再收缩回原状态的总时长，单位毫秒。
  // 2. `interactionWidthReboundDurationMs`
  //    手指按压音量条，音量条向外扩展；松手后回弹回原宽度的时长，单位毫秒。
  // 3. `buttonWidthPulsePercent`
  //    按键调节时，音量条轻微外扩到收缩回原宽度的距离，单位百分比。
  // 4. `interactionWidthReboundPercent`
  //    滑动调节时，音量条松手后回弹回原宽度的幅度，单位百分比。
  // 5. `interactionDragDampingRatio`
  //    滑动调节时的跟手阻尼比；值越大越沉，值越小越跟手。
  // 缩小态恢复到正常宽度的时间，单位毫秒。
  private readonly RESTORE_WIDTH_DURATION_MS: number = 220;
  // 回弹幅度。
  // 控制按住音量条时会先放大多少。
  // 值越大，放大和松手后的回弹体感越明显；值越小，手感越克制。
  private readonly INTERACTION_REBOUND_AMPLITUDE: number = 0.05;
  // 松手后边缘形变收敛的弹簧阻尼。
  // 这个只控制极值状态下 edge morph 的收敛，不控制音量条宽度回弹时长。
  // 值越大越稳、晃动越少；值越小越弹、回弹感越明显。
  private readonly INTERACTION_RELEASE_SPRING_DAMPING: number = 0.86;
  private readonly EDGE_SQUEEZE_SCALE_X: number = 0.9;
  private readonly EDGE_STRETCH_SCALE_Y: number = 1.12;
  private readonly EDGE_SHIFT_Y: number = 16;
  private readonly EDGE_TRIGGER_OVERFLOW: number = 0.02;
  private readonly EDGE_OVERFLOW_RANGE: number = 0.14;
  private readonly BACKGROUND_DIM_OPACITY: number = 0.2;
  private readonly BUTTON_ROW_BOTTOM: number = 70;
  private readonly BUTTON_ROW_OFFSET_Y: number = 0;
  private readonly BUTTON_GAP: number = 150;
  private readonly BUTTON_TOUCH_SIZE: number = 72;
  private readonly BUTTON_FONT_SIZE: number = 34;
  private readonly BUTTON_VOLUME_STEP: number = 0.12;
  // 缩小状态下，点击 `+ / -` 按钮后，
  // 音量条先进入形变峰值所花的时间，单位毫秒。
  //小值120，基值250，大值400
  private readonly BUTTON_PULSE_PRESS_DURATION_MS: number = 400;
  // 缩小状态下，点击 `+ / -` 按钮后，
  // 音量条从形变峰值回弹恢复所花的时间，单位毫秒。
  // 小值260，基值400，大值600
  private readonly BUTTON_PULSE_REBOUND_DURATION_MS: number = 600;
  // 按钮点击时的回弹幅度。
  // `+` 按钮：
  // 1. `BUTTON_PLUS_PULSE_SCALE_Y` 控制上下扩张幅度，值越大越明显。
  // 2. `BUTTON_PLUS_PULSE_SCALE_X` 控制左右收缩幅度，值越小越明显。
  // `-` 按钮：
  // 1. `BUTTON_MINUS_PULSE_SCALE_Y` 控制上下内缩幅度，值越小越明显。
  // 2. `BUTTON_MINUS_PULSE_SCALE_X` 控制左右外扩幅度，值越大越明显。

  //回弹基准： x0.98，y1.04；小： x0.99，y1.02，大：x0.93，y1.1
  private readonly BUTTON_PLUS_PULSE_SCALE_X: number = 0.995;
  private readonly BUTTON_PLUS_PULSE_SCALE_Y: number = 1.015;
  //回弹基准： x1.02，y0.96；小： x1.01，y0.98，大：x1.08，y0.9
  private readonly BUTTON_MINUS_PULSE_SCALE_X: number = 1.005;
  private readonly BUTTON_MINUS_PULSE_SCALE_Y: number = 0.985;
  private readonly TOUCH_MOVE_THRESHOLD: number = 2;

  private clamp(value: number, min: number, max: number): number {
    return Math.min(max, Math.max(min, value));
  }

  private baseTrackWidth(): number {
    const baseWidth = this.lerp(this.TRACK_WIDTH, this.SHRUNK_TRACK_WIDTH, this.widthShrinkProgress);
    const activeWidthOffset = baseWidth * this.interactionWidthReboundPercent / 100 * this.activeProgress;
    return baseWidth + activeWidthOffset;
  }

  private currentTrackWidth(): number {
    return Math.max(
      this.baseTrackWidth() + this.buttonWidthPulseOffset(),
      2
    );
  }

  private buttonWidthPulseOffset(): number {
    const pulseDistance = this.baseTrackWidth() * this.buttonWidthPulsePercent / 100;
    if (this.buttonWidthPulseDirection > 0) {
      return pulseDistance * this.buttonWidthPulseProgress;
    }
    if (this.buttonWidthPulseDirection < 0) {
      return -pulseDistance * this.buttonWidthPulseProgress;
    }
    return 0;
  }

  private currentTrackRadius(): number {
    return Math.min(this.TRACK_RADIUS, this.currentTrackWidth() * 0.5);
  }

  private controlLeft(): number {
    return (this.pageWidth - this.TRACK_TOUCH_WIDTH) * 0.5 + this.CONTROL_OFFSET_X;
  }

  private controlTop(): number {
    return this.pageHeight - this.CONTROL_BOTTOM - this.TRACK_HEIGHT + this.CONTROL_OFFSET_Y + this.controlTranslateY();
  }

  private buttonRowWidth(): number {
    return this.BUTTON_TOUCH_SIZE * 2 + this.BUTTON_GAP;
  }

  private buttonRowLeft(): number {
    return (this.pageWidth - this.buttonRowWidth()) * 0.5;
  }

  private buttonRowTop(): number {
    return this.pageHeight - this.BUTTON_ROW_BOTTOM - this.BUTTON_TOUCH_SIZE + this.BUTTON_ROW_OFFSET_Y;
  }

  private trackVisualLeft(): number {
    return this.TRACK_TOUCH_WIDTH - this.currentTrackWidth();
  }

  private fillHeight(): number {
    return this.lerp(this.FILL_MIN_HEIGHT, this.TRACK_HEIGHT, this.volumeProgress);
  }

  private fillTop(): number {
    return this.TRACK_HEIGHT - this.fillHeight();
  }

  private fillShapeHeight(): number {
    return Math.max(this.fillHeight(), this.currentTrackRadius() * 2);
  }

  private fillShapeTop(): number {
    return this.fillHeight() - this.fillShapeHeight();
  }

  private fillFlatCapHeight(): number {
    return Math.max(this.fillHeight() - this.currentTrackRadius(), 0);
  }

  private lerp(start: number, end: number, t: number): number {
    return start + (end - start) * t;
  }

  private hexByte(value: number): string {
    const clamped = Math.round(this.clamp(value, 0, 255));
    const digits = '0123456789ABCDEF';
    return `${digits.charAt(Math.floor(clamped / 16))}${digits.charAt(clamped % 16)}`;
  }

  private trackColor(): string {
    return `#${this.hexByte(this.TRACK_OPACITY * 255)}${this.TRACK_RGB_HEX}`;
  }

  private trackShadowColor(): string {
    const activeFade = 1 - this.activeProgress * 0.92;
    return `#${this.hexByte(this.TRACK_SHADOW_ALPHA * activeFade)}000000`;
  }

  private trackShadowRadius(): number {
    return this.TRACK_SHADOW_RADIUS * (1 - this.activeProgress * 0.85);
  }

  private trackShadowOffsetY(): number {
    return this.TRACK_SHADOW_OFFSET_Y * (1 - this.activeProgress * 0.85);
  }

  private backgroundDimOpacity(): number {
    return this.BACKGROUND_DIM_OPACITY * this.activeProgress + 0.05 * this.edgeMorphProgress;
  }

  private controlScaleX(): number {
    const edgeScale = this.lerp(1, this.EDGE_SQUEEZE_SCALE_X, this.edgeMorphProgress);
    return edgeScale * this.buttonPulseScaleX();
  }

  private controlScaleY(): number {
    const activeScale = this.lerp(1, 1 + this.INTERACTION_REBOUND_AMPLITUDE, this.activeProgress);
    const edgeScale = this.lerp(1, this.EDGE_STRETCH_SCALE_Y, this.edgeMorphProgress);
    return activeScale * edgeScale * this.buttonPulseScaleY();
  }

  private buttonPulseScaleY(): number {
    if (this.buttonPulseDirection > 0) {
      return this.lerp(1, this.BUTTON_PLUS_PULSE_SCALE_Y, this.buttonPulseProgress);
    }
    if (this.buttonPulseDirection < 0) {
      return this.lerp(1, this.BUTTON_MINUS_PULSE_SCALE_Y, this.buttonPulseProgress);
    }
    return 1;
  }

  private buttonPulseScaleX(): number {
    if (this.buttonPulseDirection > 0) {
      return this.lerp(1, this.BUTTON_PLUS_PULSE_SCALE_X, this.buttonPulseProgress);
    }
    if (this.buttonPulseDirection < 0) {
      return this.lerp(1, this.BUTTON_MINUS_PULSE_SCALE_X, this.buttonPulseProgress);
    }
    return 1;
  }

  private controlTranslateY(): number {
    return this.edgeDirection * this.edgeMorphProgress * this.EDGE_SHIFT_Y;
  }

  private beginInteraction(): void {
    this.getUIContext().animateTo({
      duration: 180,
      curve: curves.cubicBezierCurve(0.2, 0.9, 0.2, 1)
    }, () => {
      this.activeProgress = 1;
    });
  }

  private endInteraction(): void {
    this.getUIContext().animateTo({
      duration: this.interactionWidthReboundDurationMs,
      curve: curves.cubicBezierCurve(0.22, 0.82, 0.2, 1)
    }, () => {
      this.activeProgress = 0;
    });

    this.getUIContext().animateTo({
      duration: this.interactionWidthReboundDurationMs,
      curve: curves.springMotion(0.2, this.INTERACTION_RELEASE_SPRING_DAMPING, 0)
    }, () => {
      this.edgeMorphProgress = 0;
    });
    this.edgeDirection = 0;
  }

  private updateEdgeMorph(rawProgress: number, offsetY: number): void {
    let direction = 0;
    if (offsetY < -0.5) {
      direction = -1;
    } else if (offsetY > 0.5) {
      direction = 1;
    }

    if (direction !== 0) {
      this.edgeDirection = direction;
    }

    const overflow = rawProgress > 1 ? rawProgress - 1 : rawProgress < 0 ? -rawProgress : 0;
    const effectiveOverflow = Math.max(overflow - this.EDGE_TRIGGER_OVERFLOW, 0);
    this.edgeMorphProgress = this.clamp(effectiveOverflow / this.EDGE_OVERFLOW_RANGE, 0, 1);
  }

  private triggerButtonPulse(direction: number): void {
    this.buttonPulseDirection = direction;
    this.buttonWidthPulseToken += 1;
    const pulseToken = this.buttonWidthPulseToken;
    const pulseDuration = Math.max(2, this.buttonWidthPulseDurationMs);
    const expandDuration = Math.max(1, Math.floor(pulseDuration * 0.38));
    const reboundDuration = Math.max(1, pulseDuration - expandDuration);

    this.buttonWidthPulseDirection = direction;
    this.buttonWidthPulseProgress = 0;
    this.getUIContext().animateTo({
      duration: expandDuration,
      curve: curves.cubicBezierCurve(0.24, 0.88, 0.24, 1),
      onFinish: () => {
        if (pulseToken !== this.buttonWidthPulseToken) {
          return;
        }
        this.getUIContext().animateTo({
          duration: reboundDuration,
          curve: curves.cubicBezierCurve(0.22, 0.82, 0.2, 1),
          onFinish: () => {
            if (pulseToken !== this.buttonWidthPulseToken) {
              return;
            }
            this.buttonWidthPulseProgress = 0;
            this.buttonWidthPulseDirection = 0;
          }
        }, () => {
          this.buttonWidthPulseProgress = 0;
        });
      }
    }, () => {
      this.buttonWidthPulseProgress = 1;
    });

    this.getUIContext().animateTo({
      duration: this.BUTTON_PULSE_PRESS_DURATION_MS,
      curve: curves.cubicBezierCurve(0.2, 0.9, 0.2, 1),
      onFinish: () => {
        this.getUIContext().animateTo({
          duration: this.BUTTON_PULSE_REBOUND_DURATION_MS,
          curve: curves.cubicBezierCurve(0.22, 0.82, 0.2, 1),
          onFinish: () => {
            this.buttonPulseDirection = 0;
          }
        }, () => {
          this.buttonPulseProgress = 0;
        });
      }
    }, () => {
      this.buttonPulseProgress = 1;
    });
  }

  private handleButtonStep(direction: number): void {
    this.buttonTapCount += 1;
    const nextProgress = this.clamp(this.volumeProgress + direction * this.BUTTON_VOLUME_STEP, 0, 1);
    this.triggerButtonPulse(direction);

    const shouldShrink = this.buttonTapCount >= this.BUTTON_SHRINK_TRIGGER_COUNT && this.widthShrinkProgress < 0.999;
    this.getUIContext().animateTo({
      duration: 180,
      curve: curves.cubicBezierCurve(0.2, 0.9, 0.2, 1)
    }, () => {
      this.volumeProgress = nextProgress;
      if (shouldShrink) {
        this.widthShrinkProgress = 1;
      }
    });
  }

  private restoreTrackWidth(): void {
    if (this.widthShrinkProgress < 0.001 && this.buttonTapCount === 0) {
      return;
    }

    this.buttonTapCount = 0;
    this.getUIContext().animateTo({
      duration: this.RESTORE_WIDTH_DURATION_MS,
      curve: curves.cubicBezierCurve(0.18, 0.9, 0.2, 1)
    }, () => {
      this.widthShrinkProgress = 0;
    });
  }

  private primaryTouchY(event: TouchEvent): number {
    if (event.touches.length > 0) {
      return event.touches[0].windowY;
    }
    if (event.changedTouches.length > 0) {
      return event.changedTouches[0].windowY;
    }
    return this.dragStartWindowY;
  }

  private handleTrackTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.restoreTrackWidth();
      this.beginInteraction();
      this.dragStartProgress = this.volumeProgress;
      this.dragStartWindowY = this.primaryTouchY(event);
      return;
    }

    if (event.type === TouchType.Move) {
      const currentY = this.primaryTouchY(event);
      const deltaY = currentY - this.dragStartWindowY;
      if (Math.abs(deltaY) > this.TOUCH_MOVE_THRESHOLD) {
        const dragDampingRatio = Math.max(this.interactionDragDampingRatio, 0.01);
        const rawProgress = this.dragStartProgress - deltaY / (this.TRACK_HEIGHT * dragDampingRatio);
        const nextProgress = this.clamp(rawProgress, 0, 1);
        this.volumeProgress = nextProgress;
        this.updateEdgeMorph(rawProgress, deltaY);
      }
      return;
    }

    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.endInteraction();
    }
  }

  build() {
    Stack() {
      Image($r('app.media.Background1'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .opacity(this.backgroundDimOpacity())
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Stack() {
        Column()
          .width(this.TRACK_TOUCH_WIDTH)
          .height(this.TRACK_HEIGHT)
          .backgroundColor(this.TRACK_TOUCH_COLOR)

        Stack() {
          Column()
            .width(this.currentTrackWidth())
            .height(this.TRACK_HEIGHT)
            .backgroundColor(this.trackColor())
            .backdropBlur(this.TRACK_BACKDROP_BLUR)
            .borderRadius(this.currentTrackRadius())
            .clip(true)

          if (this.fillHeight() > 0.5) {
            Stack() {
              Column()
                .width(this.currentTrackWidth())
                .height(this.fillShapeHeight())
                .backgroundColor(this.FILL_COLOR)
                .borderRadius(this.currentTrackRadius())
                .position({
                  x: 0,
                  y: this.fillShapeTop()
                })

              if (this.fillFlatCapHeight() > 0.5) {
                Column()
                  .width(this.currentTrackWidth())
                  .height(this.fillFlatCapHeight())
                  .backgroundColor(this.FILL_COLOR)
                  .position({
                    x: 0,
                    y: 0
                  })
        }
            }
              .width(this.currentTrackWidth())
              .height(this.fillHeight())
              .clip(true)
              .position({
                x: 0,
                y: this.fillTop()
              })
          }
        }
        .width(this.currentTrackWidth())
        .height(this.TRACK_HEIGHT)
        .borderRadius(this.currentTrackRadius())
        .clip(true)
        .shadow({
          radius: this.trackShadowRadius(),
          color: this.trackShadowColor(),
          offsetX: 0,
          offsetY: this.trackShadowOffsetY()
        })
        .position({
          x: this.trackVisualLeft(),
          y: 0
        })
      }
      .width(this.TRACK_TOUCH_WIDTH)
      .height(this.TRACK_HEIGHT)
      .clip(false)
      .scale({
        x: this.controlScaleX(),
        y: this.controlScaleY()
      })
      .onTouch((event) => {
        this.handleTrackTouch(event);
      })
      .position({
        x: this.controlLeft(),
        y: this.controlTop()
      })

      Row() {
        Stack() {
          Text('-')
            .fontSize(this.BUTTON_FONT_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor('#F5F5F5')
        }
        .width(this.BUTTON_TOUCH_SIZE)
        .height(this.BUTTON_TOUCH_SIZE)
        .onClick(() => {
          this.handleButtonStep(-1);
        })

        Stack() {
          Text('+')
            .fontSize(this.BUTTON_FONT_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor('#F5F5F5')
        }
        .width(this.BUTTON_TOUCH_SIZE)
        .height(this.BUTTON_TOUCH_SIZE)
        .margin({ left: this.BUTTON_GAP })
        .onClick(() => {
          this.handleButtonStep(1);
        })
      }
      .width(this.buttonRowWidth())
      .height(this.BUTTON_TOUCH_SIZE)
      .position({
        x: this.buttonRowLeft(),
        y: this.buttonRowTop()
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
