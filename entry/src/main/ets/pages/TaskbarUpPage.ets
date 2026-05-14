import curves from '@ohos.curves';
import {
  taskbarUpFollowerReleaseMultiplier,
  taskbarUpFollowerReleaseTranslateX,
  taskbarUpReleaseDurations,
  taskbarUpReleaseForwardControlY,
  taskbarUpReleaseInitialSlope
} from './TaskbarUpReleaseMotion';

@Entry
@Component
struct TaskbarUpPage {
  @State pageWidth: number = 1;
  @State pageHeight: number = 1;
  @State openProgress: number = 0;
  @State expanded: boolean = false;
  @State animating: boolean = false;
  @State closingRecents: boolean = false;
  @State pressedCardIndex: number = -1;
  @State edgeSnapOffsetX: number = 0;
  @State edgeDragRawOffsetX: number = 0;
  @State draggingVertical: boolean = false;
  @State leadCardReleaseProgress: number = 0;
  @State leadCardReleaseScaleValue: number = 1;
  @State leadCardTranslateAtRelease: number = 0;
  @State followerCardReleaseSegmentProgress: number = 0;
  @State followerCardReleaseReturning: boolean = false;
  // 可调参数：上滑时的阻尼比。
  // 控制手指上滑距离和动画实际推进距离的比值；值越大越沉，值越小越跟手。
  @StorageLink('taskbarUpSwipeDampingRatio') upSwipeDampingRatio: number = 1.5;
  // 可调参数：松手后首卡释放总时长。
  // 控制首卡从左侧预览位置入位、继续过冲、再回正的完整时长；值越大越慢。
  @StorageLink('taskbarUpLeadCardReleaseDurationMs') leadCardReleaseDurationMs: number = 1000;
  // 可调参数：回弹幅度，单位百分比。
  // 控制第一张卡片自动入场时，向右多走一小段再回正的距离；5 表示卡片宽度的 5%。
  @StorageLink('taskbarUpCardBounceOvershootX') cardBounceOvershootX: number = 5;

  private cardScroller: Scroller = new Scroller();
  private reboundAnimationToken: number = 0;
  private trackingEdgeTouch: boolean = false;
  private lastTouchWindowX: number = 0;
  private rowTouchStartWindowX: number = 0;
  private rowTouchStartWindowY: number = 0;
  private verticalDragStartY: number = 0;
  private verticalDragStartProgress: number = 0;
  private verticalDragLastTimeMs: number = 0;
  private verticalDragLeadCardTranslateX: number = 0;
  private verticalDragLeadCardVelocityPxPerMs: number = 0;
  private followerCardReleaseStartX: number = 0;

  private readonly CARD_COUNT: number = 4;
  private readonly INITIAL_CENTER_INDEX: number = 3;
  private readonly CARD_ORDER: number[] = [0, 1, 2, 3];

  // 页面动画参数。
  private readonly DURATION_MS: number = 1480;
  private readonly BACKGROUND_BLUR_MAX: number = 120;
  private readonly BACKGROUND_BLUR_CLOSE_END_PROGRESS: number = 0.86;
  private readonly BACKGROUND_DRAG_PREVIEW_BLUR_PROGRESS: number = 0.52;
  private readonly BACKGROUND_DIM_OPACITY: number = 0.16;
  private readonly BACKGROUND3_END_SCALE: number = 0.95;
  private readonly BACKGROUND3_END_RADIUS: number = 34;
  private readonly BACKGROUND3_SHADOW_RADIUS: number = 28;
  private readonly BACKGROUND3_SHADOW_ALPHA: string = '#33000000';

  // 底部上滑手势区参数。
  private readonly TRIGGER_TOUCH_WIDTH: number = 320;
  private readonly TRIGGER_TOUCH_HEIGHT: number = 220;
  private readonly TRIGGER_BOTTOM: number = 8;
  private readonly TRIGGER_OFFSET_X: number = 0;
  private readonly TRIGGER_OFFSET_Y: number = -30;
  private readonly TRIGGER_DRAG_DISTANCE: number = 470;
  private readonly TRIGGER_OPEN_THRESHOLD: number = 0.14;
  private readonly TRIGGER_CLOSE_THRESHOLD: number = 0.72;

  // 卡片区域参数。
  private readonly CARD_ROW_TOP: number = 118;
  private readonly CARD_ROW_OFFSET_X: number = 0;
  private readonly CARD_ROW_OFFSET_Y: number = -80;
  private readonly CARD_EDGE_INSET_OFFSET: number = 0;
  private readonly CARD_GAP: number = 18;
  private readonly CARD_WIDTH: number = 234;
  private readonly CARD_HEIGHT: number = 506;
  private readonly CARD_RADIUS: number = 34;
  private readonly CARD_ENTER_OFFSET_X: number = 190;
  private readonly CARD_ENTER_OFFSET_Y: number = 0;
  private readonly CARD_ENTER_STAGGER: number = 0.09;
  private readonly CARD_ENTER_DURATION: number = 0.72;
  private readonly LEAD_CARD_ENTER_DURATION_MULTIPLIER: number = 1.52;
  private readonly FOLLOW_CARD_ENTER_DURATION_MULTIPLIER: number = 0.82;
  private readonly FOLLOW_CARD_TRANSLATE_PROGRESS_MULTIPLIER: number = 1.58;
  private readonly FOLLOW_CARD_SCALE_PROGRESS_MULTIPLIER: number = 1.34;
  private readonly CARD_ENTER_BLUR_MAX: number = 18;
  private readonly CARD_ENTER_START_SCALE: number = 1.28;
  private readonly LEAD_CARD_ENTER_START_SCALE: number = 1.24;
  private readonly CARD_DRAG_PREVIEW_MAX_PROGRESS: number = 0.32;
  private readonly LEAD_CARD_DRAG_PREVIEW_VISIBLE_WIDTH: number = 56;
  private readonly FOLLOW_CARD_RELEASE_OVERSHOOT_FALLOFF: number = 0.58;
  private readonly LEAD_CARD_RELEASE_MIN_INITIAL_SLOPE: number = 0.35;
  private readonly LEAD_CARD_RELEASE_MAX_INITIAL_SLOPE: number = 2.4;
  private readonly LEAD_CARD_RELEASE_VELOCITY_BLEND: number = 0.62;
  private readonly LEAD_CARD_RELEASE_VELOCITY_STALE_MS: number = 72;
  private readonly LEAD_CARD_RELEASE_FORWARD_X1: number = 0.24;
  private readonly LEAD_CARD_RELEASE_FORWARD_X2: number = 0.66;
  private readonly LEAD_CARD_RELEASE_RETURN_X1: number = 0.38;
  private readonly LEAD_CARD_RELEASE_RETURN_X2: number = 0.82;
  private readonly LEAD_CARD_RELEASE_RETURN_Y2: number = 0.14;
  private readonly CARD_VIEWPORT_PADDING_Y: number = 92;
  private readonly CARD_TRANSLATE_SETTLE_END_PROGRESS: number = 0.32;
  private readonly LEAD_CARD_TRANSLATE_SETTLE_END_PROGRESS: number = 0.42;
  private readonly CARD_SCALE_SETTLE_END_PROGRESS: number = 0.32;
  private readonly LEAD_CARD_SCALE_HOLD_PROGRESS: number = 0.56;
  private readonly LEAD_CARD_SCALE_SETTLE_END_PROGRESS: number = 1.0;
  private readonly CARD_BOUNCE_FORWARD_DURATION_MS: number = 180;
  // 回弹时间，单位毫秒。
  // 控制卡片入场动画里，从过冲位置回到最终位置所花的时间；值越大，回弹阶段越长。
  private readonly CARD_BOUNCE_RETURN_DURATION_MS: number = 420;
  private readonly CARD_BOUNCE_OVERSHOOT_Y: number = 0;
  // 归位时间，单位毫秒。
  // 基线时长：1020，短时长：620，长时长：1420
  private readonly CARD_SETTLE_DURATION_MS: number = 1420;
  // 卡片横向滑动阻尼比。
  // 控制横向拖动卡片列表时，“手指滑动距离 : 卡片实际移动距离”的比值。
  private readonly CARD_DRAG_DAMPING_RATIO: number = 1.0;
  // 自动居中时的弹簧阻尼。
  // 这个只影响卡片自动吸附到中间时的回弹收敛，不影响用户手指拖动距离。
  private readonly CARD_SNAP_SPRING_DAMPING: number = 0.54;
  // 首次唤起回弹起始偏移。
  // 基线为154，小回弹为104，大回弹为204
  private readonly INITIAL_WAKE_SNAP_OFFSET: number = 204;
  private readonly INITIAL_WAKE_SNAP_DELAY_MS: number = 36;
  private readonly EDGE_DRAG_FOLLOW_RATIO: number = 0.72;
  private readonly EDGE_DRAG_MAX_OFFSET: number = 1912;
  private readonly BLANK_TAP_MOVE_TOLERANCE: number = 22;
  private readonly CARD_BLANK_TAP_HIT_SLOP: number = 10;
  private readonly CARD_PRESS_SCALE: number = 1.02;
  private readonly CARD_PRESS_IN_DURATION: number = 1015;
  private readonly CARD_PRESS_OUT_DURATION: number = 1200;

  // 卡片头部参数。
  // `CARD_HEADER_SAFE_TOP` 用来给卡片上方预留可见空间，
  // 这样把 icon 或 label 往上挪时就不会被裁剪掉。
  private readonly CARD_HEADER_SAFE_TOP: number = 64;
  private readonly CARD_ICON_SIZE: number = 28;
  private readonly CARD_ICON_RADIUS: number = 8;
  private readonly CARD_ICON_LEFT: number = 16;
  private readonly CARD_ICON_TOP: number = -39;
  private readonly CARD_LABEL_LEFT_GAP: number = 10;
  private readonly CARD_LABEL_OFFSET_X: number = 0;
  private readonly CARD_LABEL_OFFSET_Y: number = -35;
  private readonly CARD_LABEL_WIDTH: number = 130;
  private readonly CARD_LABEL_FONT_SIZE: number = 15;
  private readonly CARD_LABEL_COLOR: string = '#F7F7F7';

  // 卡片标题文字参数。
  private readonly CARD1_LABEL: string = '小红书';
  private readonly CARD2_LABEL: string = '滴滴出行';
  private readonly CARD3_LABEL: string = '淘宝';
  private readonly CARD4_LABEL: string = '快手';

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

  private cardBounceSplit(): number {
    const totalBounceDuration = Math.max(
      this.CARD_BOUNCE_FORWARD_DURATION_MS + this.CARD_BOUNCE_RETURN_DURATION_MS,
      1
    );
    return this.clamp(this.CARD_BOUNCE_FORWARD_DURATION_MS / totalBounceDuration, 0.05, 0.95);
  }

  private cardBounceOvershootPx(): number {
    return this.CARD_WIDTH * this.clamp(this.cardBounceOvershootX, 0, 100) / 100;
  }

  private cardReleaseOvershootMultiplier(index: number): number {
    return taskbarUpFollowerReleaseMultiplier(
      index,
      this.INITIAL_CENTER_INDEX,
      this.FOLLOW_CARD_RELEASE_OVERSHOOT_FALLOFF
    );
  }

  private cardBounceOvershootPxForIndex(index: number): number {
    return this.cardBounceOvershootPx() * this.cardReleaseOvershootMultiplier(index);
  }

  private followerCardReleaseTranslateX(index: number): number {
    return taskbarUpFollowerReleaseTranslateX(
      index,
      this.INITIAL_CENTER_INDEX,
      this.FOLLOW_CARD_RELEASE_OVERSHOOT_FALLOFF,
      this.followerCardReleaseStartX,
      this.cardBounceOvershootPx(),
      this.followerCardReleaseReturning,
      this.followerCardReleaseSegmentProgress
    );
  }

  private leadCardReleaseTotalDurationMs(): number {
    return Math.max(2, Math.floor(this.leadCardReleaseDurationMs));
  }

  private leadCardReleaseForwardDurationMs(): number {
    return taskbarUpReleaseDurations(
      this.leadCardReleaseTotalDurationMs(),
      this.cardBounceSplit()
    ).forwardMs;
  }

  private leadCardReleaseReturnDurationMs(): number {
    return taskbarUpReleaseDurations(
      this.leadCardReleaseTotalDurationMs(),
      this.cardBounceSplit()
    ).returnMs;
  }

  private playLeadCardReleaseMotion(
    activeToken: number,
    startX: number,
    overshootX: number,
    forwardDurationMs: number,
    returnDurationMs: number,
    initialSlope: number
  ): void {
    if (activeToken !== this.reboundAnimationToken) {
      return;
    }

    this.leadCardTranslateAtRelease = startX;
    this.followerCardReleaseReturning = false;
    this.followerCardReleaseSegmentProgress = 0;

    this.getUIContext().animateTo({
      duration: forwardDurationMs,
      curve: curves.cubicBezierCurve(
        this.LEAD_CARD_RELEASE_FORWARD_X1,
        taskbarUpReleaseForwardControlY(initialSlope, this.LEAD_CARD_RELEASE_FORWARD_X1),
        this.LEAD_CARD_RELEASE_FORWARD_X2,
        1
      ),
      onFinish: () => {
        if (activeToken !== this.reboundAnimationToken) {
          return;
        }

        this.leadCardTranslateAtRelease = overshootX;
        this.followerCardReleaseReturning = true;
        this.followerCardReleaseSegmentProgress = 0;

        this.getUIContext().animateTo({
          duration: returnDurationMs,
          curve: curves.cubicBezierCurve(
            this.LEAD_CARD_RELEASE_RETURN_X1,
            0,
            this.LEAD_CARD_RELEASE_RETURN_X2,
            this.LEAD_CARD_RELEASE_RETURN_Y2
          )
        }, () => {
          this.leadCardTranslateAtRelease = 0;
          this.followerCardReleaseSegmentProgress = 1;
        });
      }
    }, () => {
      this.leadCardTranslateAtRelease = overshootX;
      this.leadCardReleaseScaleValue = 1;
      this.followerCardReleaseSegmentProgress = 1;
    });
  }

  private currentLeadCardPreviewScale(): number {
    const scaleT = this.easeOut(
      this.clamp(this.openProgress, 0, 1),
      2.2
    );
    return this.lerp(this.LEAD_CARD_ENTER_START_SCALE, 1, scaleT);
  }

  private maxEdgeDragRawOffset(): number {
    return this.EDGE_DRAG_MAX_OFFSET / Math.max(this.EDGE_DRAG_FOLLOW_RATIO, 0.01);
  }

  private edgeDragVisualOffsetX(): number {
    return this.clamp(
      this.edgeDragRawOffsetX * this.EDGE_DRAG_FOLLOW_RATIO,
      -this.EDGE_DRAG_MAX_OFFSET,
      this.EDGE_DRAG_MAX_OFFSET
    );
  }

  private rowTranslateX(): number {
    return this.edgeSnapOffsetX + this.edgeDragVisualOffsetX();
  }

  private fullFrameWidth(): number {
    return Math.max(this.pageWidth, 1);
  }

  private fullFrameHeight(): number {
    return Math.max(this.pageHeight, 1);
  }

  private triggerTouchLeft(): number {
    return (this.pageWidth - this.TRIGGER_TOUCH_WIDTH) * 0.5 + this.TRIGGER_OFFSET_X;
  }

  private triggerTouchTop(): number {
    return this.pageHeight - this.TRIGGER_BOTTOM - this.TRIGGER_TOUCH_HEIGHT + this.TRIGGER_OFFSET_Y;
  }

  private cardPitch(): number {
    return this.CARD_WIDTH + this.CARD_GAP;
  }

  private cardEdgeInset(): number {
    return Math.max((this.pageWidth - this.CARD_WIDTH) * 0.5 + this.CARD_EDGE_INSET_OFFSET, 0);
  }

  private cardRowTop(): number {
    return this.CARD_ROW_TOP + this.CARD_ROW_OFFSET_Y;
  }

  private cardScrollWidth(): number {
    return this.fullFrameWidth();
  }

  private cardFrameHeight(): number {
    return this.CARD_HEADER_SAFE_TOP + this.CARD_HEIGHT;
  }

  private cardImageTop(): number {
    return this.CARD_HEADER_SAFE_TOP;
  }

  private headerIconTop(): number {
    return Math.max(this.CARD_HEADER_SAFE_TOP + this.CARD_ICON_TOP, 0);
  }

  private headerLabelLeft(): number {
    return this.CARD_ICON_LEFT + this.CARD_ICON_SIZE + this.CARD_LABEL_LEFT_GAP + this.CARD_LABEL_OFFSET_X;
  }

  private headerLabelTop(): number {
    return Math.max(this.CARD_HEADER_SAFE_TOP + this.CARD_LABEL_OFFSET_Y, 0);
  }

  private contentWidth(): number {
    return this.cardEdgeInset() * 2 + this.CARD_COUNT * this.CARD_WIDTH + (this.CARD_COUNT - 1) * this.CARD_GAP;
  }

  private maxScrollOffset(): number {
    return Math.max(this.contentWidth() - this.pageWidth, 0);
  }

  private centeredOffsetForIndex(index: number): number {
    const unclamped = this.CARD_EDGE_INSET_OFFSET + index * this.cardPitch();
    return this.clamp(unclamped, 0, this.maxScrollOffset());
  }

  private nearestCardIndex(offset: number): number {
    const raw = Math.round((offset - this.CARD_EDGE_INSET_OFFSET) / this.cardPitch());
    return this.clamp(raw, 0, this.CARD_COUNT - 1);
  }

  private backgroundBlur(): number {
    const progress = this.backgroundBlurProgress();
    return this.BACKGROUND_BLUR_MAX * Math.pow(progress, 1.35);
  }

  private backgroundBlurOpacity(): number {
    return Math.pow(this.backgroundBlurProgress(), 0.92);
  }

  private backgroundBlurProgress(): number {
    const progress = this.clamp(this.openProgress, 0, 1);
    if (this.animating && !this.expanded) {
      const closeT = this.clamp(
        (progress - this.BACKGROUND_BLUR_CLOSE_END_PROGRESS)
          / (1 - this.BACKGROUND_BLUR_CLOSE_END_PROGRESS),
        0,
        1
      );
      return this.easeOut(closeT, 2.2);
    }
    if (this.isDragPreviewActive()) {
      return this.lerp(
        0,
        this.BACKGROUND_DRAG_PREVIEW_BLUR_PROGRESS,
        this.easeOut(this.dragPreviewProgress(), 1.8)
      );
    }
    if (this.isReleaseFromClosedActive()) {
      const releaseFloor = this.lerp(
        this.BACKGROUND_DRAG_PREVIEW_BLUR_PROGRESS,
        1,
        this.easeOut(this.leadCardReleaseProgress, 1.65)
      );
      return Math.max(progress, releaseFloor);
    }
    return progress;
  }

  private backgroundDim(): number {
    return this.BACKGROUND_DIM_OPACITY * this.clamp(this.openProgress, 0, 1);
  }

  private background3Scale(): number {
    return this.lerp(1, this.BACKGROUND3_END_SCALE, this.clamp(this.openProgress, 0, 1));
  }

  private background3Radius(): number {
    return this.lerp(0, this.BACKGROUND3_END_RADIUS, this.clamp(this.openProgress, 0, 1));
  }

  private isDragPreviewActive(): boolean {
    return this.draggingVertical && !this.animating && this.verticalDragStartProgress <= 0.001;
  }

  private isReleaseFromClosedActive(): boolean {
    return !this.draggingVertical
      && this.expanded
      && this.verticalDragStartProgress <= 0.001
      && this.leadCardReleaseProgress < 0.999;
  }

  private dragPreviewProgress(): number {
    const rawProgress = this.clamp(this.openProgress, 0, 1);
    return this.clamp(rawProgress / Math.max(this.TRIGGER_OPEN_THRESHOLD, 0.01), 0, 1);
  }

  private cardAnimationProgress(): number {
    const rawProgress = this.clamp(this.openProgress, 0, 1);
    if (this.isDragPreviewActive()) {
      return this.lerp(0, this.CARD_DRAG_PREVIEW_MAX_PROGRESS, this.dragPreviewProgress());
    }
    return rawProgress;
  }

  private isOpeningFromClosedFlow(): boolean {
    return this.verticalDragStartProgress <= 0.001
      && (this.expanded || this.animating || this.draggingVertical);
  }

  private cardTranslateTimelineProgress(index: number): number {
    const rawProgress = this.cardAnimationProgress();
    if (index === this.INITIAL_CENTER_INDEX || this.isDragPreviewActive() || !this.isOpeningFromClosedFlow()) {
      return rawProgress;
    }
    return this.clamp(rawProgress * this.FOLLOW_CARD_TRANSLATE_PROGRESS_MULTIPLIER, 0, 1);
  }

  private cardScaleTimelineProgress(index: number): number {
    const rawProgress = this.cardAnimationProgress();
    if (index === this.INITIAL_CENTER_INDEX || this.isDragPreviewActive() || !this.isOpeningFromClosedFlow()) {
      return rawProgress;
    }
    return this.clamp(rawProgress * this.FOLLOW_CARD_SCALE_PROGRESS_MULTIPLIER, 0, 1);
  }

  private cardRenderTimelineProgress(index: number): number {
    return this.cardTranslateTimelineProgress(index);
  }

  private cardEnterProgress(index: number, timelineProgress: number = this.cardTranslateTimelineProgress(index)): number {
    const start = this.cardEnterStartProgress(index);
    const end = start + this.cardEnterDuration(index);
    return this.clamp((timelineProgress - start) / (end - start), 0, 1);
  }

  private cardEnterRank(index: number): number {
    return this.CARD_COUNT - 1 - index;
  }

  private cardEnterStartProgress(index: number): number {
    return 0.08 + this.cardEnterRank(index) * this.CARD_ENTER_STAGGER;
  }

  private cardEnterDuration(index: number): number {
    const sharedStartX = this.sharedCardAbsoluteStartX();
    const baseDistance = Math.max(0 - sharedStartX, 1);
    const currentDistance = Math.max(index * this.cardPitch() - sharedStartX, 1);
    const duration = this.CARD_ENTER_DURATION * (currentDistance / baseDistance);
    if (index === this.INITIAL_CENTER_INDEX) {
      return duration * this.LEAD_CARD_ENTER_DURATION_MULTIPLIER;
    }
    return duration * this.FOLLOW_CARD_ENTER_DURATION_MULTIPLIER;
  }

  private cardShouldRender(index: number): boolean {
    if (this.closingRecents) {
      return true;
    }
    if (this.isDragPreviewActive()) {
      return index === this.INITIAL_CENTER_INDEX;
    }
    if (this.isReleaseFromClosedActive()) {
      return true;
    }
    return this.cardRenderTimelineProgress(index) >= this.cardEnterStartProgress(index);
  }

  private cardExitProgress(index: number): number {
    const rawProgress = this.clamp(this.openProgress, 0, 1);
    if (index === this.INITIAL_CENTER_INDEX) {
      return rawProgress;
    }
    return this.clamp(rawProgress * this.FOLLOW_CARD_TRANSLATE_PROGRESS_MULTIPLIER, 0, 1);
  }

  private cardExitTranslateX(index: number): number {
    return this.lerp(
      this.cardHiddenStartX(index),
      0,
      this.easeOut(this.cardExitProgress(index), 2.35)
    );
  }

  private cardExitScale(index: number): number {
    const startScale = index === this.INITIAL_CENTER_INDEX
      ? this.LEAD_CARD_ENTER_START_SCALE
      : this.CARD_ENTER_START_SCALE;
    return this.lerp(
      startScale,
      1,
      this.easeOut(this.cardExitProgress(index), 2.45)
    );
  }

  private cardsAreEntering(): boolean {
    let finalEnterEnd = 0;
    for (let index = 0; index < this.CARD_COUNT; index += 1) {
      finalEnterEnd = Math.max(
        finalEnterEnd,
        this.cardEnterStartProgress(index) + this.cardEnterDuration(index)
      );
    }
    if (this.isDragPreviewActive()) {
      return true;
    }
    for (let index = 0; index < this.CARD_COUNT; index += 1) {
      if (this.cardRenderTimelineProgress(index) < finalEnterEnd) {
        return true;
      }
    }
    return false;
  }

  private cardZIndex(index: number): number {
    if (this.cardsAreEntering()) {
      return this.CARD_COUNT - index;
    }
    return 1;
  }

  private sharedCardAbsoluteStartX(): number {
    return -this.fullFrameWidth() - this.CARD_WIDTH - (this.CARD_COUNT - 1) * this.cardPitch();
  }

  private cardHiddenStartX(index: number): number {
    return this.sharedCardAbsoluteStartX() - index * this.cardPitch();
  }

  private leadCardPreviewTranslateX(): number {
    const centeredLeft = (this.fullFrameWidth() - this.CARD_WIDTH) * 0.5;
    const targetLeft = this.LEAD_CARD_DRAG_PREVIEW_VISIBLE_WIDTH - this.CARD_WIDTH;
    return targetLeft - centeredLeft;
  }

  private currentLeadCardPreviewTranslateX(): number {
    return this.lerp(
      this.cardHiddenStartX(this.INITIAL_CENTER_INDEX),
      this.leadCardPreviewTranslateX(),
      this.easeOut(this.dragPreviewProgress(), 2.15)
    );
  }

  private resetLeadCardDragVelocity(): void {
    this.verticalDragLastTimeMs = Date.now();
    this.verticalDragLeadCardTranslateX = this.currentLeadCardPreviewTranslateX();
    this.verticalDragLeadCardVelocityPxPerMs = 0;
  }

  private trackLeadCardDragVelocity(nextTranslateX: number): void {
    const now = Date.now();
    const elapsedMs = Math.max(now - this.verticalDragLastTimeMs, 1);
    const instantVelocity = (nextTranslateX - this.verticalDragLeadCardTranslateX) / elapsedMs;
    const blend = this.clamp(this.LEAD_CARD_RELEASE_VELOCITY_BLEND, 0, 1);
    this.verticalDragLeadCardVelocityPxPerMs = instantVelocity <= 0
      ? 0
      : this.lerp(this.verticalDragLeadCardVelocityPxPerMs, instantVelocity, blend);
    this.verticalDragLeadCardTranslateX = nextTranslateX;
    this.verticalDragLastTimeMs = now;
  }

  private currentLeadCardReleaseVelocityPxPerMs(): number {
    if (Date.now() - this.verticalDragLastTimeMs > this.LEAD_CARD_RELEASE_VELOCITY_STALE_MS) {
      return 0;
    }
    return this.verticalDragLeadCardVelocityPxPerMs;
  }

  private cardTranslateX(index: number): number {
    const isLeadCard = index === this.INITIAL_CENTER_INDEX;
    if (this.closingRecents) {
      return this.cardExitTranslateX(index);
    }

    if (isLeadCard && this.isDragPreviewActive()) {
      return this.currentLeadCardPreviewTranslateX();
    }

    if (this.isReleaseFromClosedActive() && isLeadCard) {
      return this.leadCardTranslateAtRelease;
    }

    if (this.isReleaseFromClosedActive() && !isLeadCard) {
      return this.followerCardReleaseTranslateX(index);
    }

    if (isLeadCard && this.expanded && this.verticalDragStartProgress <= 0.001 && this.openProgress >= 0.999) {
      return 0;
    }

    const enterT = isLeadCard
      ? this.cardEnterProgress(index)
      : this.cardEnterProgress(index, this.cardTranslateTimelineProgress(index));
    const settleEnd = Math.max(
      isLeadCard ? this.LEAD_CARD_TRANSLATE_SETTLE_END_PROGRESS : this.CARD_TRANSLATE_SETTLE_END_PROGRESS,
      0.01
    );
    if (enterT < settleEnd) {
      const settleT = this.easeOut(enterT / settleEnd, 2.35);
      return this.lerp(
        this.cardHiddenStartX(index),
        0,
        settleT
      );
    }
    const bounceSplit = this.cardBounceSplit();
    const bounceWindowT = this.clamp((enterT - settleEnd) / (1 - settleEnd), 0, 1);
    const bounceOvershootX = this.cardBounceOvershootPxForIndex(index);
    if (bounceWindowT < bounceSplit) {
      return this.lerp(
        0,
        bounceOvershootX,
        bounceWindowT / bounceSplit
      );
    }
    return this.lerp(
      bounceOvershootX,
      0,
      (bounceWindowT - bounceSplit) / (1 - bounceSplit)
    );
  }

  private cardSettleProgress(index: number): number {
    const enterT = this.cardEnterProgress(index);
    const isLeadCard = index === this.INITIAL_CENTER_INDEX;
    const settleEnd = Math.max(
      isLeadCard ? this.LEAD_CARD_TRANSLATE_SETTLE_END_PROGRESS : this.CARD_TRANSLATE_SETTLE_END_PROGRESS,
      0.01
    );
    return this.clamp(enterT / settleEnd, 0, 1);
  }

  private cardTranslateY(index: number): number {
    const enterT = this.cardEnterProgress(index, this.cardTranslateTimelineProgress(index));
    const bounceSplit = this.cardBounceSplit();
    if (enterT < bounceSplit) {
      return this.lerp(
        this.CARD_ENTER_OFFSET_Y,
        this.CARD_BOUNCE_OVERSHOOT_Y,
        enterT / bounceSplit
      );
    }
    return this.lerp(
      this.CARD_BOUNCE_OVERSHOOT_Y,
      0,
      (enterT - bounceSplit) / (1 - bounceSplit)
    );
  }

  private cardScale(index: number): number {
    const isLeadCard = index === this.INITIAL_CENTER_INDEX;
    const startScale = isLeadCard ? this.LEAD_CARD_ENTER_START_SCALE : this.CARD_ENTER_START_SCALE;
    if (this.closingRecents) {
      return this.cardExitScale(index);
    }

    if (isLeadCard && this.isDragPreviewActive()) {
      return this.currentLeadCardPreviewScale();
    }
    if (isLeadCard && this.isReleaseFromClosedActive()) {
      return this.leadCardReleaseScaleValue;
    }

    const enterT = isLeadCard
      ? this.cardEnterProgress(index)
      : this.cardEnterProgress(index, this.cardScaleTimelineProgress(index));
    if (isLeadCard) {
      const settleT = this.cardSettleProgress(index);
      if (settleT < this.LEAD_CARD_SCALE_HOLD_PROGRESS) {
        return startScale;
      }
      const scaleWindow = Math.max(
        this.LEAD_CARD_SCALE_SETTLE_END_PROGRESS - this.LEAD_CARD_SCALE_HOLD_PROGRESS,
        0.01
      );
      return this.lerp(
        startScale,
        1,
        this.easeOut((settleT - this.LEAD_CARD_SCALE_HOLD_PROGRESS) / scaleWindow, 2.45)
      );
    }
    const settleEnd = Math.max(this.CARD_SCALE_SETTLE_END_PROGRESS, 0.01);
    if (enterT < settleEnd) {
      return this.lerp(
        startScale,
        1,
        this.easeOut(enterT / settleEnd, 2.45)
      );
    }
    return 1;
  }

  private applyCardDragDamping(
    xOffset: number,
    yOffset: number,
    scrollSource: ScrollSource
  ): OffsetResult | void {
    if (scrollSource !== ScrollSource.DRAG && scrollSource !== ScrollSource.SCROLL_BAR) {
      return;
    }
    const dampingRatio = Math.max(this.CARD_DRAG_DAMPING_RATIO, 0.01);
    const dampedX = xOffset / dampingRatio;
    const currentOffset = this.cardScroller.currentOffset().xOffset;
    const maxOffset = this.maxScrollOffset();
    const maxRaw = this.maxEdgeDragRawOffset();

    if (this.edgeDragRawOffsetX > 0 && dampedX > 0) {
      const consumed = Math.min(this.edgeDragRawOffsetX, dampedX);
      this.edgeDragRawOffsetX -= consumed;
      return {
        xOffset: dampedX - consumed,
        yOffset
      };
    }

    if (this.edgeDragRawOffsetX < 0 && dampedX < 0) {
      const consumed = Math.min(-this.edgeDragRawOffsetX, -dampedX);
      this.edgeDragRawOffsetX += consumed;
      return {
        xOffset: dampedX + consumed,
        yOffset
      };
    }

    const nextOffset = currentOffset + dampedX;
    if (nextOffset < 0) {
      const overflow = -nextOffset;
      this.edgeDragRawOffsetX = this.clamp(this.edgeDragRawOffsetX + overflow, 0, maxRaw);
      return {
        xOffset: -currentOffset,
        yOffset
      };
    }

    if (nextOffset > maxOffset) {
      const overflow = nextOffset - maxOffset;
      this.edgeDragRawOffsetX = this.clamp(this.edgeDragRawOffsetX - overflow, -maxRaw, 0);
      return {
        xOffset: maxOffset - currentOffset,
        yOffset
      };
    }

    return {
      xOffset: dampedX,
      yOffset
    };
  }

  private currentTouchWindowX(event: TouchEvent): number | null {
    const touch = event.touches.length > 0
      ? event.touches[0]
      : (event.changedTouches.length > 0 ? event.changedTouches[0] : undefined);
    if (!touch) {
      return null;
    }
    return touch.windowX;
  }

  private currentTouchWindowY(event: TouchEvent): number | null {
    const touch = event.touches.length > 0
      ? event.touches[0]
      : (event.changedTouches.length > 0 ? event.changedTouches[0] : undefined);
    if (!touch) {
      return null;
    }
    return touch.windowY;
  }

  private handleEdgeDragMove(deltaX: number): void {
    if (!this.expanded) {
      return;
    }
    const currentOffset = this.cardScroller.currentOffset().xOffset;
    const leftEdge = currentOffset <= 0.5;
    const rightEdge = currentOffset >= this.maxScrollOffset() - 0.5;
    const maxRaw = this.maxEdgeDragRawOffset();
    const rawDelta = deltaX / Math.max(this.EDGE_DRAG_FOLLOW_RATIO, 0.01);

    if ((leftEdge || this.edgeDragRawOffsetX > 0) && deltaX > 0) {
      this.edgeDragRawOffsetX = this.clamp(this.edgeDragRawOffsetX + rawDelta, 0, maxRaw);
      return;
    }

    if ((rightEdge || this.edgeDragRawOffsetX < 0) && deltaX < 0) {
      this.edgeDragRawOffsetX = this.clamp(this.edgeDragRawOffsetX + rawDelta, -maxRaw, 0);
    }
  }

  private pointInsideCardArea(index: number, windowX: number, windowY: number): boolean {
    if (!this.cardShouldRender(index)) {
      return false;
    }

    const scrollOffsetX = this.cardScroller.currentOffset().xOffset;
    const cardLeft = this.CARD_ROW_OFFSET_X
      + this.rowTranslateX()
      + this.cardEdgeInset()
      + index * this.cardPitch()
      - scrollOffsetX
      + this.cardTranslateX(index)
      - this.CARD_BLANK_TAP_HIT_SLOP;
    const cardTop = this.cardRowTop()
      + this.cardTranslateY(index)
      - this.CARD_BLANK_TAP_HIT_SLOP;
    const cardRight = cardLeft + this.CARD_WIDTH + this.CARD_BLANK_TAP_HIT_SLOP * 2;
    const cardBottom = cardTop + this.cardFrameHeight() + this.CARD_BLANK_TAP_HIT_SLOP * 2;

    return windowX >= cardLeft
      && windowX <= cardRight
      && windowY >= cardTop
      && windowY <= cardBottom;
  }

  private pointInsideAnyCardArea(windowX: number, windowY: number): boolean {
    for (let index = 0; index < this.CARD_COUNT; index += 1) {
      if (this.pointInsideCardArea(index, windowX, windowY)) {
        return true;
      }
    }
    return false;
  }

  private maybeCloseFromBlankRowTap(event: TouchEvent): boolean {
    if (!this.expanded || this.animating || this.draggingVertical) {
      return false;
    }

    const touchX = this.currentTouchWindowX(event);
    const touchY = this.currentTouchWindowY(event);
    if (touchX === null || touchY === null) {
      return false;
    }

    const movedX = Math.abs(touchX - this.rowTouchStartWindowX);
    const movedY = Math.abs(touchY - this.rowTouchStartWindowY);
    if (movedX > this.BLANK_TAP_MOVE_TOLERANCE || movedY > this.BLANK_TAP_MOVE_TOLERANCE) {
      return false;
    }

    if (this.pointInsideAnyCardArea(touchX, touchY)) {
      return false;
    }

    this.pressedCardIndex = -1;
    this.animateRecentsTo(0);
    return true;
  }

  private handleRowTouch(event: TouchEvent): void {
    const touchX = this.currentTouchWindowX(event);
    const touchY = this.currentTouchWindowY(event);

    if (event.type === TouchType.Down) {
      if (touchX === null || touchY === null) {
        return;
      }
      this.trackingEdgeTouch = true;
      this.lastTouchWindowX = touchX;
      this.rowTouchStartWindowX = touchX;
      this.rowTouchStartWindowY = touchY;
      return;
    }

    if (event.type === TouchType.Move) {
      if (!this.trackingEdgeTouch || touchX === null) {
        return;
      }
      const deltaX = touchX - this.lastTouchWindowX;
      this.lastTouchWindowX = touchX;
      this.handleEdgeDragMove(deltaX);
      return;
    }

    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      const closedByBlankTap = event.type === TouchType.Up && this.maybeCloseFromBlankRowTap(event);
      this.trackingEdgeTouch = false;
      if (!closedByBlankTap) {
        this.releaseEdgeDragOffset();
      }
    }
  }

  private playRowRebound(
    direction: number,
    reboundDurationMs: number = this.CARD_BOUNCE_RETURN_DURATION_MS,
    reboundOffsetX: number = -1
  ): void {
    this.reboundAnimationToken += 1;
    const token = this.reboundAnimationToken;
    const forwardDuration = Math.max(1, Math.floor(reboundDurationMs * 0.42));
    const offsetX = reboundOffsetX >= 0 ? reboundOffsetX : this.cardBounceOvershootPx();

    this.edgeSnapOffsetX = 0;
    this.getUIContext().animateTo({
      duration: forwardDuration,
      curve: curves.cubicBezierCurve(0.2, 0.86, 0.24, 1)
    }, () => {
      this.edgeSnapOffsetX = direction * offsetX;
    });

    setTimeout(() => {
      if (token !== this.reboundAnimationToken) {
        return;
      }
      this.getUIContext().animateTo({
        duration: reboundDurationMs,
        curve: curves.springMotion(0.22, this.CARD_SNAP_SPRING_DAMPING, 0)
      }, () => {
        this.edgeSnapOffsetX = 0;
      });
    }, forwardDuration);
  }

  private releaseEdgeDragOffset(): void {
    if (Math.abs(this.edgeDragRawOffsetX) < 0.01) {
      this.edgeDragRawOffsetX = 0;
      return;
    }
    this.getUIContext().animateTo({
      duration: this.CARD_SETTLE_DURATION_MS,
      curve: curves.cubicBezierCurve(0.18, 0.88, 0.2, 1)
    }, () => {
      this.edgeDragRawOffsetX = 0;
    });
  }

  private cardPressScale(index: number): number {
    return this.pressedCardIndex === index ? this.CARD_PRESS_SCALE : 1;
  }

  private prepareInitialScroll(): void {
    if (this.pageWidth <= 1 || this.pageHeight <= 1) {
      return;
    }
    this.edgeSnapOffsetX = 0;
    this.edgeDragRawOffsetX = 0;
    this.cardScroller.scrollTo({
      xOffset: this.centeredOffsetForIndex(this.INITIAL_CENTER_INDEX),
      yOffset: 0,
      animation: false
    });
  }

  private playInitialWakeSnap(): void {
    setTimeout(() => {
      if (!this.expanded) {
        return;
      }
      this.cardScroller.scrollTo({
        xOffset: this.centeredOffsetForIndex(this.INITIAL_CENTER_INDEX),
        yOffset: 0,
        animation: {
          duration: this.CARD_SETTLE_DURATION_MS,
          curve: curves.cubicBezierCurve(0.18, 0.88, 0.2, 1)
        }
      });
    }, this.INITIAL_WAKE_SNAP_DELAY_MS);
  }

  private resetCardScrollToStart(): void {
    this.cardScroller.scrollTo({
      xOffset: 0,
      yOffset: 0,
      animation: false
    });
  }

  private scrollToCard(index: number, animated: boolean): void {
    this.cardScroller.scrollTo({
      xOffset: this.centeredOffsetForIndex(index),
      yOffset: 0,
      animation: animated ? {
        duration: this.CARD_SETTLE_DURATION_MS,
        curve: curves.cubicBezierCurve(0.18, 0.88, 0.2, 1)
      } : false
    });
  }

  private snapToNearestCard(): void {
    const offset = this.cardScroller.currentOffset().xOffset;
    const index = this.nearestCardIndex(offset);
    const target = this.centeredOffsetForIndex(index);
    if (Math.abs(target - offset) < 1) {
      return;
    }
    this.scrollToCard(index, true);
  }

  private setCardPressed(index: number, pressed: boolean): void {
    const nextIndex = pressed ? index : -1;
    if (this.pressedCardIndex === nextIndex) {
      return;
    }
    this.getUIContext().animateTo({
      duration: pressed ? this.CARD_PRESS_IN_DURATION : this.CARD_PRESS_OUT_DURATION,
      curve: pressed
        ? curves.cubicBezierCurve(0.22, 0.88, 0.22, 1)
        : curves.springMotion(0.2, 0.84, 0)
    }, () => {
      this.pressedCardIndex = nextIndex;
    });
  }

  private handleCardTouch(index: number, event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.setCardPressed(index, true);
      return;
    }
    if (event.type === TouchType.Move) {
      this.setCardPressed(index, false);
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.setCardPressed(index, false);
    }
  }

  private animateRecentsTo(target: number): void {
    if (this.animating || this.pageWidth <= 1 || this.pageHeight <= 1) {
      return;
    }

    this.animating = true;
    this.closingRecents = target <= 0.001;
    this.expanded = target > 0.001;
    const openingFromClosed = target > 0 && this.verticalDragStartProgress <= 0.001;

    if (target > 0) {
      this.prepareInitialScroll();
      if (openingFromClosed) {
        this.leadCardReleaseScaleValue = this.currentLeadCardPreviewScale();
        this.leadCardTranslateAtRelease = this.currentLeadCardPreviewTranslateX();
        this.followerCardReleaseStartX = this.leadCardTranslateAtRelease;
        this.followerCardReleaseReturning = false;
        this.followerCardReleaseSegmentProgress = 0;
        this.leadCardReleaseProgress = 0;
      }
    } else {
      this.reboundAnimationToken += 1;
      this.edgeSnapOffsetX = 0;
      this.edgeDragRawOffsetX = 0;
      this.leadCardReleaseProgress = 0;
      this.leadCardReleaseScaleValue = 1;
      this.leadCardTranslateAtRelease = 0;
      this.followerCardReleaseReturning = false;
      this.followerCardReleaseSegmentProgress = 0;
    }

    const openAnimationDuration = openingFromClosed
      ? Math.max(this.DURATION_MS, this.leadCardReleaseTotalDurationMs())
      : this.DURATION_MS;

    this.getUIContext().animateTo({
      duration: openAnimationDuration,
      curve: curves.cubicBezierCurve(0.2, 0.9, 0.2, 1),
      onFinish: () => {
        this.animating = false;
        if (target > 0) {
          this.closingRecents = false;
          this.leadCardTranslateAtRelease = 0;
          this.followerCardReleaseReturning = true;
          this.followerCardReleaseSegmentProgress = 1;
          this.leadCardReleaseProgress = 1;
          this.playInitialWakeSnap();
        } else {
          this.closingRecents = false;
          this.resetCardScrollToStart();
        }
      }
    }, () => {
      this.openProgress = target;
    });

    if (openingFromClosed) {
      this.reboundAnimationToken += 1;
      const token = this.reboundAnimationToken;
      const releaseStartX = this.leadCardTranslateAtRelease;
      const releaseOvershootX = this.cardBounceOvershootPx();
      const releaseForwardDuration = this.leadCardReleaseForwardDurationMs();
      const releaseReturnDuration = this.leadCardReleaseReturnDurationMs();
      const releaseInitialSlope = taskbarUpReleaseInitialSlope(
        this.currentLeadCardReleaseVelocityPxPerMs(),
        releaseOvershootX - releaseStartX,
        releaseForwardDuration,
        this.LEAD_CARD_RELEASE_MIN_INITIAL_SLOPE,
        this.LEAD_CARD_RELEASE_MAX_INITIAL_SLOPE
      );

      this.playLeadCardReleaseMotion(
        token,
        releaseStartX,
        releaseOvershootX,
        releaseForwardDuration,
        releaseReturnDuration,
        releaseInitialSlope
      );
    }
  }

  private handleTriggerTouch(event: TouchEvent): void {
    if (this.animating) {
      return;
    }

    const touchY = this.currentTouchWindowY(event);
    if (touchY === null) {
      return;
    }

    if (event.type === TouchType.Down) {
      this.draggingVertical = true;
      this.verticalDragStartY = touchY;
      this.verticalDragStartProgress = this.openProgress;
      this.resetLeadCardDragVelocity();
      if (this.verticalDragStartProgress <= 0.001) {
        this.prepareInitialScroll();
        this.leadCardReleaseProgress = 0;
        this.leadCardReleaseScaleValue = this.LEAD_CARD_ENTER_START_SCALE;
        this.leadCardTranslateAtRelease = this.cardHiddenStartX(this.INITIAL_CENTER_INDEX);
        this.resetLeadCardDragVelocity();
      }
      this.reboundAnimationToken += 1;
      this.edgeSnapOffsetX = 0;
      return;
    }

    if (event.type === TouchType.Move && this.draggingVertical) {
      const deltaY = this.verticalDragStartY - touchY;
      const rawProgress = this.verticalDragStartProgress
        + deltaY / (this.TRIGGER_DRAG_DISTANCE * Math.max(this.upSwipeDampingRatio, 0.01));
      const nextProgress = this.clamp(rawProgress, 0, 1);
      this.openProgress = nextProgress;
      if (this.verticalDragStartProgress <= 0.001) {
        this.trackLeadCardDragVelocity(this.currentLeadCardPreviewTranslateX());
      }
      this.expanded = nextProgress > 0.001;
      if (nextProgress <= 0.001) {
        this.edgeSnapOffsetX = 0;
        this.edgeDragRawOffsetX = 0;
      }
      return;
    }

    if ((event.type === TouchType.Up || event.type === TouchType.Cancel) && this.draggingVertical) {
      this.draggingVertical = false;
      const target = this.verticalDragStartProgress > 0.001
        ? (this.openProgress <= this.TRIGGER_CLOSE_THRESHOLD ? 0 : 1)
        : (this.openProgress >= this.TRIGGER_OPEN_THRESHOLD ? 1 : 0);
      this.animateRecentsTo(target);
    }
  }

  private handleBlankAreaTouch(event: TouchEvent): void {
    if (event.type !== TouchType.Up && event.type !== TouchType.Cancel) {
      return;
    }
    if (!this.expanded || this.animating || this.draggingVertical || this.trackingEdgeTouch) {
      return;
    }
    this.pressedCardIndex = -1;
    this.animateRecentsTo(0);
  }

  private orderedCardIndex(index: number): number {
    return this.CARD_ORDER[index];
  }

  private cardImage(index: number): ResourceStr {
    switch (this.orderedCardIndex(index)) {
      case 0:
        return $r('app.media.Card1');
      case 1:
        return $r('app.media.Card2');
      case 2:
        return $r('app.media.Card3');
      default:
        return $r('app.media.Card4');
    }
  }

  private iconImage(index: number): ResourceStr {
    switch (this.orderedCardIndex(index)) {
      case 0:
        return $r('app.media.icon1');
      case 1:
        return $r('app.media.icon2');
      case 2:
        return $r('app.media.icon3');
      default:
        return $r('app.media.icon4');
    }
  }

  private cardLabel(index: number): string {
    switch (this.orderedCardIndex(index)) {
      case 0:
        return this.CARD1_LABEL;
      case 1:
        return this.CARD2_LABEL;
      case 2:
        return this.CARD3_LABEL;
      default:
        return this.CARD4_LABEL;
    }
  }

  @Builder
  private buildCard(index: number) {
    Stack() {
      Stack() {
        Image(this.cardImage(index))
          .width(this.CARD_WIDTH)
          .height(this.CARD_HEIGHT)
          .objectFit(ImageFit.Cover)
          .borderRadius(this.CARD_RADIUS)
          .clip(true)
      }
      .width(this.CARD_WIDTH)
      .height(this.CARD_HEIGHT)
      .position({
        x: 0,
        y: this.cardImageTop()
      })

      Image(this.iconImage(index))
        .width(this.CARD_ICON_SIZE)
        .height(this.CARD_ICON_SIZE)
        .objectFit(ImageFit.Fill)
        .borderRadius(this.CARD_ICON_RADIUS)
        .clip(true)
        .position({
          x: this.CARD_ICON_LEFT,
          y: this.headerIconTop()
        })

      Text(this.cardLabel(index))
        .width(this.CARD_LABEL_WIDTH)
        .fontSize(this.CARD_LABEL_FONT_SIZE)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.CARD_LABEL_COLOR)
        .maxLines(1)
        .textAlign(TextAlign.Start)
        .position({
          x: this.headerLabelLeft(),
          y: this.headerLabelTop()
        })
    }
    .width(this.CARD_WIDTH)
    .height(this.cardFrameHeight())
    .clip(false)
    .zIndex(this.cardZIndex(index))
    .scale({
      x: this.cardScale(index) * this.cardPressScale(index),
      y: this.cardScale(index) * this.cardPressScale(index)
    })
    .translate({
      x: this.cardTranslateX(index),
      y: this.cardTranslateY(index)
    })
    .onTouch((event) => {
      this.handleCardTouch(index, event);
    })
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
        .blur(this.backgroundBlur())
        .opacity(this.backgroundBlurOpacity())
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
        .shadow({
          radius: this.BACKGROUND3_SHADOW_RADIUS * this.openProgress,
          color: this.BACKGROUND3_SHADOW_ALPHA,
          offsetX: 0,
          offsetY: 12 * this.openProgress
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.Background3'))
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .objectFit(ImageFit.Fill)
        .blur(this.backgroundBlur())
        .opacity(this.backgroundBlurOpacity())
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

      Column()
        .width(this.fullFrameWidth())
        .height(this.fullFrameHeight())
        .backgroundColor(Color.Black)
        .opacity(this.backgroundDim())
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      if (this.expanded) {
        Column()
          .width(this.fullFrameWidth())
          .height(this.fullFrameHeight())
          .backgroundColor('#01000000')
          .expandSafeArea(
            [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
            [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
          )
          .onTouch((event) => {
            this.handleBlankAreaTouch(event);
          })
      }

      Scroll(this.cardScroller) {
        Row({ space: this.CARD_GAP }) {
          ForEach([0, 1, 2, 3], (index: number) => {
            Stack() {
              if (this.cardShouldRender(index)) {
                this.buildCard(index);
              }
            }
            .width(this.CARD_WIDTH)
            .height(this.cardFrameHeight())
            .clip(false)
          }, (index: number) => `${index}`)
        }
        .padding({
          left: this.cardEdgeInset(),
          right: this.cardEdgeInset(),
          top: this.CARD_VIEWPORT_PADDING_Y,
          bottom: this.CARD_VIEWPORT_PADDING_Y
        })
      }
      .width(this.cardScrollWidth())
      .height(this.cardFrameHeight() + this.CARD_VIEWPORT_PADDING_Y * 2)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .onWillScroll((xOffset, yOffset, _scrollState, scrollSource) => {
        return this.applyCardDragDamping(xOffset, yOffset, scrollSource);
      })
      .onTouch((event) => {
        this.handleRowTouch(event);
      })
      .onScrollStop(() => {
        if (this.expanded) {
          this.releaseEdgeDragOffset();
          this.snapToNearestCard();
        }
      })
      .position({
        x: this.CARD_ROW_OFFSET_X,
        y: this.cardRowTop() - this.CARD_VIEWPORT_PADDING_Y
      })
      .translate({
        x: this.rowTranslateX(),
        y: 0
      })

      Stack()
      .width(this.TRIGGER_TOUCH_WIDTH)
      .height(this.TRIGGER_TOUCH_HEIGHT)
      .position({
        x: this.triggerTouchLeft(),
        y: this.triggerTouchTop()
      })
      .onTouch((event) => {
        this.handleTriggerTouch(event);
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
      this.prepareInitialScroll();
    })
  }
}
