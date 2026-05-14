@Entry
@Component
struct Index {
  @State pageWidth: number = 1;
  @State pageHeight: number = 1;
  @State animating: boolean = false;
  @State expanded: boolean = false;
  @State backgroundProgress: number = 0;
  @State iconDrawOpacity: number = 1;
  @State appDrawLeft: number = 0;
  @State appDrawTop: number = 0;
  @State appDrawWidth: number = 56;
  @State appDrawHeight: number = 56;
  @State appDrawRadius: number = 14;
  @StorageLink('indexOpenAnimationDurationMs') openAnimationDurationMs: number = 220;
  @StorageLink('indexIconReboundPercent') iconReboundPercent: number = 10;

  private animationToken: number = 0;
  private animationStartTime: number = 0;
  private animationOpening: boolean = true;
  private iconReboundStartTime: number = 0;

  // 底部红色正方形的位置和大小。
  private readonly ICON_SIZE: number = 56;
  private readonly ICON_BOTTOM: number = 118;
  // icon 位置调节：X 轴偏移，负数向左，正数向右。
  private readonly ICON_OFFSET_X: number = -47;
  // icon 位置调节：Y 轴偏移，负数向上，正数向下。
  private readonly ICON_OFFSET_Y: number = -105;
  private readonly ICON_RADIUS: number = 14;
  private readonly ICON_LABEL_TEXT: string = '小红书';
  private readonly ICON_LABEL_EXTRA_WIDTH: number = 28;
  // icon 和下方文字之间的间距。数值越大，文字离 icon 越远。
  private readonly ICON_LABEL_GAP: number = 4;
  private readonly ICON_LABEL_FONT_SIZE: number = 12;
  private readonly ICON_RED_COLOR: string = '#FF2442';
  // icon 渐隐只发生在容器放大进度的前半程：打开时 1 -> 0，关闭时 0 -> 1。
  private readonly ICON_FADE_DURATION_RATIO: number = 0.5;
  // app 放大过程中使用的夸张圆角；前半程放大到这个圆角，后半程再逐渐回到 0。
  private readonly APP_MID_RADIUS: number = 46;
  // 完成时设为 0 可以保证 app2 真正全覆盖屏幕；放大过程中仍然有圆角。
  private readonly APP_RADIUS: number = 0;
  // app2 图片本身是屏幕等大图，最终容器必须和屏幕同尺寸，避免图片被过度放大。
  private readonly APP_FINAL_OVERFILL: number = 0;
  // app2 最终位置的 Y 轴修正。负数向上移动，用来抵消安全区导致的整体偏下。
  private readonly APP_FINAL_OFFSET_Y: number = -36;
  // 打开/关闭 app 的完整阶段总时长，单位毫秒。
  // 打开时：整个放大过程等于该时长；关闭时：缩回主动画 + icon 回弹合计等于该时长。
  // 具体总时长由 `openAnimationDurationMs` 控制。
  // 打开/关闭 app 的速度曲线强度。当前是“前面快，后面慢”；数值越大，结尾越慢。
  private readonly MAIN_EASE_OUT_POWER: number = 1.85;
  // 关闭总时长中分给 icon 回弹的比例；例如 0.32 表示关闭总时长的 32% 用于最后的回弹。
  private readonly ICON_REBOUND_DURATION_RATIO: number = 0.32;
  // 关闭后 icon 向内缩的幅度由 `iconReboundPercent` 控制，10 表示缩到原来的 90%。
  private readonly ANIMATION_FRAME_MS: number = 16;

  private fullFrameWidth(): number {
    return Math.max(this.pageWidth, 1);
  }

  private fullFrameHeight(): number {
    return Math.max(this.pageHeight, 1);
  }

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

  private easeInOut(value: number): number {
    const t = this.clamp(value, 0, 1);
    return t * t * (3 - 2 * t);
  }

  private iconCenterX(): number {
    return this.iconLeft() + this.ICON_SIZE * 0.5;
  }

  private iconCenterY(): number {
    return this.iconTop() + this.ICON_SIZE * 0.5;
  }

  private iconLeft(): number {
    return (this.pageWidth - this.ICON_SIZE) / 2 + this.ICON_OFFSET_X;
  }

  private iconTop(): number {
    return this.pageHeight - this.ICON_BOTTOM - this.ICON_SIZE + this.ICON_OFFSET_Y;
  }

  private iconLabelWidth(): number {
    return Math.max(this.ICON_SIZE + this.ICON_LABEL_EXTRA_WIDTH, 72);
  }

  private iconLabelLeft(): number {
    return this.iconCenterX() - this.iconLabelWidth() * 0.5;
  }

  private iconLabelTop(): number {
    return this.iconTop() + this.ICON_SIZE + this.ICON_LABEL_GAP;
  }

  private finalAppFrameWidth(): number {
    return this.fullFrameWidth() + this.APP_FINAL_OVERFILL * 2;
  }

  private finalAppFrameHeight(): number {
    return this.fullFrameHeight() + this.APP_FINAL_OVERFILL * 2;
  }

  private finalAppFrameLeft(): number {
    return -this.APP_FINAL_OVERFILL;
  }

  private finalAppFrameTop(): number {
    return -this.APP_FINAL_OVERFILL + this.APP_FINAL_OFFSET_Y;
  }

  private setAppFrame(left: number, top: number, width: number, height: number, radius: number): void {
    this.appDrawLeft = left;
    this.appDrawTop = top;
    this.appDrawWidth = width;
    this.appDrawHeight = height;
    this.appDrawRadius = radius;
  }

  private setCollapsedIconScale(scale: number): void {
    const width = this.ICON_SIZE * scale;
    const height = this.ICON_SIZE * scale;
    this.setAppFrame(
      this.iconCenterX() - width * 0.5,
      this.iconCenterY() - height * 0.5,
      width,
      height,
      this.ICON_RADIUS * scale
    );
  }

  private syncCollapsedFrame(): void {
    this.setAppFrame(this.iconLeft(), this.iconTop(), this.ICON_SIZE, this.ICON_SIZE, this.ICON_RADIUS);
    this.iconDrawOpacity = 1;
    this.backgroundProgress = 0;
  }

  private syncExpandedFrame(): void {
    this.setAppFrame(this.finalAppFrameLeft(), this.finalAppFrameTop(), this.finalAppFrameWidth(), this.finalAppFrameHeight(), this.APP_RADIUS);
    this.iconDrawOpacity = 0;
    this.backgroundProgress = 1;
  }

  private iconForeVisualSize(): number {
    return Math.min(this.appDrawWidth, this.appDrawHeight);
  }

  private labelOpacity(): number {
    return 1 - this.easeOut(this.clamp(this.backgroundProgress / 0.18, 0, 1), 1.8);
  }

  private backgroundBlurAmount(): number {
    return 30 * this.backgroundProgress;
  }

  private backgroundDimOpacity(): number {
    return 0.18 * this.backgroundProgress;
  }

  private iconOpacityByProgress(progress: number): number {
    const fadeProgress = this.clamp(progress / this.ICON_FADE_DURATION_RATIO, 0, 1);
    return 1 - this.easeInOut(fadeProgress);
  }

  private appRadiusByProgress(progress: number): number {
    if (progress < 0.5) {
      return this.lerp(this.ICON_RADIUS, this.APP_MID_RADIUS, this.easeInOut(progress / 0.5));
    }

    return this.lerp(this.APP_MID_RADIUS, this.APP_RADIUS, this.easeInOut((progress - 0.5) / 0.5));
  }

  private applyAnimationProgress(frameProgress: number, fadeProgress: number): void {
    this.setAppFrame(
      this.lerp(this.iconLeft(), this.finalAppFrameLeft(), frameProgress),
      this.lerp(this.iconTop(), this.finalAppFrameTop(), frameProgress),
      this.lerp(this.ICON_SIZE, this.finalAppFrameWidth(), frameProgress),
      this.lerp(this.ICON_SIZE, this.finalAppFrameHeight(), frameProgress),
      this.appRadiusByProgress(frameProgress)
    );
    this.backgroundProgress = fadeProgress;
    this.iconDrawOpacity = this.iconOpacityByProgress(frameProgress);
  }

  private iconReboundScaleByProgress(progress: number): number {
    const minScale = 1 - this.clamp(this.iconReboundPercent, 0, 90) / 100;
    if (progress < 0.5) {
      return this.lerp(1, minScale, this.easeOut(progress / 0.5, 2));
    }

    return this.lerp(minScale, 1, this.easeOut((progress - 0.5) / 0.5, 2));
  }

  private totalStageDurationMs(): number {
    return Math.max(1, Math.floor(this.openAnimationDurationMs));
  }

  private iconReboundDurationMs(): number {
    const totalDuration = this.totalStageDurationMs();
    if (this.iconReboundPercent <= 0 || totalDuration <= 1) {
      return 0;
    }

    const duration = Math.floor(totalDuration * this.ICON_REBOUND_DURATION_RATIO);
    return this.clamp(Math.max(1, duration), 1, totalDuration - 1);
  }

  private progressAnimationDurationMs(): number {
    if (this.animationOpening) {
      return this.totalStageDurationMs();
    }
    return Math.max(1, this.totalStageDurationMs() - this.iconReboundDurationMs());
  }

  private startProgressAnimation(opening: boolean): void {
    this.animationToken += 1;
    this.animationStartTime = Date.now();
    this.animationOpening = opening;
    this.runProgressAnimation(this.animationToken);
  }

  private runProgressAnimation(activeToken: number): void {
    if (activeToken !== this.animationToken) {
      return;
    }

    const elapsed: number = Date.now() - this.animationStartTime;
    const rawProgress: number = this.clamp(elapsed / this.progressAnimationDurationMs(), 0, 1);
    const easedProgress: number = this.easeOut(rawProgress, this.MAIN_EASE_OUT_POWER);
    const frameProgress: number = this.animationOpening ? easedProgress : 1 - easedProgress;
    const fadeProgress: number = this.animationOpening ? rawProgress : 1 - rawProgress;
    this.applyAnimationProgress(frameProgress, fadeProgress);

    if (rawProgress < 1) {
      setTimeout(() => {
        this.runProgressAnimation(activeToken);
      }, this.ANIMATION_FRAME_MS);
      return;
    }

    if (this.animationOpening) {
      this.syncExpandedFrame();
      this.animating = false;
    } else {
      this.syncCollapsedFrame();
      this.startIconReboundAnimation();
    }
  }

  private startIconReboundAnimation(): void {
    if (this.iconReboundDurationMs() <= 0) {
      this.syncCollapsedFrame();
      this.animating = false;
      return;
    }

    this.animationToken += 1;
    this.iconReboundStartTime = Date.now();
    this.runIconReboundAnimation(this.animationToken);
  }

  private runIconReboundAnimation(activeToken: number): void {
    if (activeToken !== this.animationToken) {
      return;
    }

    const elapsed: number = Date.now() - this.iconReboundStartTime;
    const rawProgress: number = this.clamp(elapsed / this.iconReboundDurationMs(), 0, 1);
    this.setCollapsedIconScale(this.iconReboundScaleByProgress(rawProgress));

    if (rawProgress < 1) {
      setTimeout(() => {
        this.runIconReboundAnimation(activeToken);
      }, this.ANIMATION_FRAME_MS);
      return;
    }

    this.syncCollapsedFrame();
    this.animating = false;
  }

  private toggle(): void {
    if (this.animating || this.pageWidth <= 1 || this.pageHeight <= 1) {
      return;
    }

    this.animating = true;
    const opening = !this.expanded;
    this.expanded = opening;
    if (opening) {
      this.playOpenAnimation();
    } else {
      this.playCloseAnimation();
    }
  }

  private playOpenAnimation(): void {
    this.syncCollapsedFrame();
    this.startProgressAnimation(true);
  }

  private playCloseAnimation(): void {
    this.syncExpandedFrame();
    this.startProgressAnimation(false);
  }

  build() {
    Stack() {
      Image($r('app.media.Background1'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.Background1'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .blur(this.backgroundBlurAmount())
        .opacity(this.backgroundProgress)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Column()
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .backgroundColor(Color.Black)
        .opacity(this.backgroundDimOpacity())
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      if (this.labelOpacity() > 0.001) {
        Text(this.ICON_LABEL_TEXT)
          .width(this.iconLabelWidth())
          .fontSize(this.ICON_LABEL_FONT_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor('#F5F5F5')
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .opacity(this.labelOpacity())
          .shadow({
            radius: 8,
            color: '#66000000',
            offsetX: 0,
            offsetY: 2
          })
          .position({
            x: this.iconLabelLeft(),
            y: this.iconLabelTop()
          })
      }

      Stack() {
        Image($r('app.media.app2'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
          .borderRadius(this.appDrawRadius)
          .clip(true)

        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(this.ICON_RED_COLOR)

          Image($r('app.media.iconFore'))
            .width(this.iconForeVisualSize())
            .height(this.iconForeVisualSize())
            .objectFit(ImageFit.Contain)
        }
        .width('100%')
        .height('100%')
        .opacity(this.iconDrawOpacity)
      }
      .width(this.appDrawWidth)
      .height(this.appDrawHeight)
      .borderRadius(this.appDrawRadius)
      .clip(true)
      .position({
        x: this.appDrawLeft,
        y: this.appDrawTop
      })
      .expandSafeArea(
        [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
        [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
      )
      .zIndex(1)
      .onClick(() => {
        this.toggle();
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
      let sizeChanged = false;
      if (!Number.isNaN(nextW) && nextW > 0) {
        this.pageWidth = nextW;
        sizeChanged = true;
      }
      if (!Number.isNaN(nextH) && nextH > 0) {
        this.pageHeight = nextH;
        sizeChanged = true;
      }
      if (sizeChanged && !this.animating) {
        if (this.expanded) {
          this.syncExpandedFrame();
        } else {
          this.syncCollapsedFrame();
        }
      }
    })
  }
}
