import { VOLUME_PRESETS, VolumePresetItem } from './ExperimentPresetData';

interface VolumePreviewRouteOptions {
  url: string;
}

@Entry
@Component
struct VolumeConfigPage {
  @StorageLink('volumeButtonWidthPulsePercent') buttonWidthPulsePercent: number = 15;
  @StorageLink('volumeInteractionWidthReboundPercent') interactionWidthReboundPercent: number = 15;
  @StorageLink('volumeInteractionDragDampingRatio') interactionDragDampingRatio: number = 1.0;
  @State selectedPresetLabel: string = '';

  private readonly PAGE_HORIZONTAL_PADDING: number = 20;
  private readonly PAGE_VERTICAL_PADDING: number = 28;
  private readonly PANEL_RADIUS: number = 32;
  private readonly PANEL_PADDING: number = 22;
  private readonly PRESET_GAP: number = 6;
  private readonly PRESET_HEIGHT: number = 34;
  private readonly PRESET_BUTTON_WIDTH: number = 42;
  private readonly presets: VolumePresetItem[] = VOLUME_PRESETS;

  private isSelected(current: number, value: number): boolean {
    return Math.abs(current - value) < 0.001;
  }

  private presetMatchesCurrentValue(preset: VolumePresetItem): boolean {
    return this.isSelected(this.interactionDragDampingRatio, preset.dampingRatio)
      && this.isSelected(this.interactionWidthReboundPercent, preset.reboundPercent)
      && this.isSelected(this.buttonWidthPulsePercent, preset.reboundPercent);
  }

  private isPresetSelected(preset: VolumePresetItem): boolean {
    if (this.selectedPresetLabel.length > 0) {
      return this.selectedPresetLabel === preset.label;
    }
    return this.presetMatchesCurrentValue(preset);
  }

  private currentPresetLabel(): string {
    for (let index = 0; index < this.presets.length; index += 1) {
      if (this.presetMatchesCurrentValue(this.presets[index])) {
        return this.presets[index].label;
      }
    }
    return '';
  }

  private activePresetLabel(): string {
    if (this.selectedPresetLabel.length > 0) {
      return this.selectedPresetLabel;
    }
    const currentLabel = this.currentPresetLabel();
    if (currentLabel.length > 0) {
      return currentLabel;
    }
    return '自定义';
  }

  private activePresetType(): string {
    const label = this.activePresetLabel();
    for (let index = 0; index < this.presets.length; index += 1) {
      if (this.presets[index].label === label) {
        return this.presets[index].type;
      }
    }
    return '当前参数';
  }

  private presetSummary(preset: VolumePresetItem): string {
    return `${preset.type} / 阻尼 ${preset.dampingRatio} / 回弹 ${preset.reboundPercent}%`;
  }

  private currentParameterText(): string {
    return `阻尼 ${this.interactionDragDampingRatio} / 滑动回弹 ${this.interactionWidthReboundPercent}% / 按键回弹 ${this.buttonWidthPulsePercent}%`;
  }

  private applyPreset(preset: VolumePresetItem): void {
    this.selectedPresetLabel = preset.label;
    this.interactionDragDampingRatio = preset.dampingRatio;
    this.interactionWidthReboundPercent = preset.reboundPercent;
    this.buttonWidthPulsePercent = preset.reboundPercent;
  }

  aboutToAppear(): void {
    this.selectedPresetLabel = this.currentPresetLabel();
  }

  private openPreviewPage(): void {
    try {
      const options: VolumePreviewRouteOptions = {
        url: 'pages/VolumePage',
      };
      this.getUIContext().getRouter().pushUrl(options);
    } catch (_error) {
    }
  }

  @Builder
  private buildHeader() {
    Column({ space: 10 }) {
      Text('VOLUME')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#CCFFFFFF')
        .letterSpacing(2)

      Text('音量条参数')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Text('点击实验档位后，会应用滑动阻尼和回弹幅度；S2 未给时长，时长保持当前代码默认值。')
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#D6FFFFFF')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildPresetButton(preset: VolumePresetItem) {
    Stack() {
      Text(preset.label)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isPresetSelected(preset) ? '#101820' : '#F5F7FA')
    }
    .width(this.PRESET_BUTTON_WIDTH)
    .height(this.PRESET_HEIGHT)
    .backgroundColor(this.isPresetSelected(preset) ? '#F2FFFFFF' : '#18FFFFFF')
    .borderRadius(15)
    .border({
      width: 1,
      color: this.isPresetSelected(preset) ? '#CCFFFFFF' : '#22FFFFFF'
    })
    .margin({ right: this.PRESET_GAP, bottom: this.PRESET_GAP })
    .onClick(() => {
      this.applyPreset(preset);
    })
    .gesture(
      TapGesture({ count: 1 })
        .onAction(() => {
          this.applyPreset(preset);
        })
    )
  }

  @Builder
  private buildPresetList() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.presets, (preset: VolumePresetItem) => {
        this.buildPresetButton(preset)
      }, (preset: VolumePresetItem) => preset.label)
    }
    .width('100%')
  }

  @Builder
  private buildPresetDetail() {
    Column({ space: 10 }) {
      Row() {
        Text(this.activePresetLabel())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFFFF')

        Text(this.activePresetType())
          .fontSize(13)
          .fontColor('#CCFFFFFF')
          .maxLines(1)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Text(this.currentParameterText())
        .fontSize(15)
        .fontColor('#F2FFFFFF')
        .lineHeight(22)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1EFFFFFF')
    .borderRadius(22)
    .border({
      width: 1,
      color: '#20FFFFFF'
    })
  }

  @Builder
  private buildPreviewButton() {
    Stack() {
      Text('进入预览')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#101820')
    }
    .width('100%')
    .height(54)
    .backgroundColor('#F2FFFFFF')
    .borderRadius(20)
    .onClick(() => {
      this.openPreviewPage();
    })
    .gesture(
      TapGesture({ count: 1 })
        .onAction(() => {
          this.openPreviewPage();
        })
    )
  }

  build() {
    Stack() {
      Image($r('app.media.Background2'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Image($r('app.media.Background2'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
        .blur(32)
        .opacity(0.22)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#76080B10')
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Column() {
        Column({ space: 24 }) {
          this.buildHeader()
          this.buildPresetList()
          this.buildPresetDetail()
          this.buildPreviewButton()
        }
        .width('100%')
        .padding(this.PANEL_PADDING)
        .backgroundColor('#33212730')
        .backdropBlur(30)
        .borderRadius(this.PANEL_RADIUS)
        .border({
          width: 1,
          color: '#26FFFFFF'
        })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding({
        left: this.PAGE_HORIZONTAL_PADDING,
        right: this.PAGE_HORIZONTAL_PADDING,
        top: this.PAGE_VERTICAL_PADDING,
        bottom: this.PAGE_VERTICAL_PADDING
      })
      .expandSafeArea(
        [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
        [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
      )
    }
    .width('100%')
    .height('100%')
    .expandSafeArea(
      [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
      [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
    )
  }
}
