import {
  TASKBAR_UP_PRESETS,
  TASKBAR_UP_SAB_PARAMETERS,
  SabParameterItem,
  TaskbarUpPresetItem,
  formatSabParameterText
} from './ExperimentPresetData';

interface TaskbarUpPreviewRouteOptions {
  url: string;
}

@Entry
@Component
struct TaskbarUpConfigPage {
  @StorageLink('taskbarUpSwipeDampingRatio') upSwipeDampingRatio: number = 1.5;
  @StorageLink('taskbarUpLeadCardReleaseDurationMs') leadCardReleaseDurationMs: number = 1000;
  @StorageLink('taskbarUpCardBounceOvershootX') cardBounceOvershootX: number = 5;
  @State selectedPresetLabel: string = '';
  @State selectedSabParameterKey: string = '';

  private readonly PAGE_HORIZONTAL_PADDING: number = 20;
  private readonly PAGE_VERTICAL_PADDING: number = 28;
  private readonly PANEL_RADIUS: number = 32;
  private readonly PANEL_PADDING: number = 22;
  private readonly PRESET_GAP: number = 6;
  private readonly PRESET_HEIGHT: number = 34;
  private readonly PRESET_BUTTON_WIDTH: number = 42;
  private readonly presets: TaskbarUpPresetItem[] = TASKBAR_UP_PRESETS;
  private readonly sabParameters: SabParameterItem[] = TASKBAR_UP_SAB_PARAMETERS;

  private isSelected(current: number, value: number): boolean {
    return Math.abs(current - value) < 0.001;
  }

  private presetMatchesCurrentValue(preset: TaskbarUpPresetItem): boolean {
    return this.isSelected(this.leadCardReleaseDurationMs, preset.durationMs)
      && this.isSelected(this.upSwipeDampingRatio, preset.dampingRatio)
      && this.isSelected(this.cardBounceOvershootX, preset.reboundPercent);
  }

  private isPresetSelected(preset: TaskbarUpPresetItem): boolean {
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

  private sabParameterKey(parameter: SabParameterItem): string {
    return `${parameter.mark}-${parameter.name}`;
  }

  private sabParameterMatchesCurrentValue(parameter: SabParameterItem): boolean {
    return this.isSelected(this.leadCardReleaseDurationMs, parameter.durationMs)
      && this.isSelected(this.upSwipeDampingRatio, parameter.dampingRatio)
      && this.isSelected(this.cardBounceOvershootX, parameter.reboundPercent);
  }

  private currentSabParameterKey(): string {
    for (let index = 0; index < this.sabParameters.length; index += 1) {
      if (this.sabParameterMatchesCurrentValue(this.sabParameters[index])) {
        return this.sabParameterKey(this.sabParameters[index]);
      }
    }
    return '';
  }

  private isSabParameterSelected(parameter: SabParameterItem): boolean {
    if (this.selectedSabParameterKey.length > 0) {
      return this.selectedSabParameterKey === this.sabParameterKey(parameter);
    }
    return this.selectedPresetLabel.length === 0 && this.sabParameterMatchesCurrentValue(parameter);
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

  private presetSummary(preset: TaskbarUpPresetItem): string {
    return `${preset.type} / 时长 ${preset.durationMs}ms / 阻尼 ${preset.dampingRatio} / 回弹 ${preset.reboundPercent}%`;
  }

  private currentParameterText(): string {
    return `时长 ${this.leadCardReleaseDurationMs}ms / 阻尼 ${this.upSwipeDampingRatio} / 回弹 ${this.cardBounceOvershootX}%`;
  }

  private sabParameterSummary(parameter: SabParameterItem): string {
    return formatSabParameterText(parameter);
  }

  private applyPreset(preset: TaskbarUpPresetItem): void {
    this.selectedPresetLabel = preset.label;
    this.selectedSabParameterKey = '';
    this.leadCardReleaseDurationMs = preset.durationMs;
    this.upSwipeDampingRatio = preset.dampingRatio;
    this.cardBounceOvershootX = preset.reboundPercent;
  }

  private applySabParameter(parameter: SabParameterItem): void {
    this.selectedPresetLabel = '';
    this.selectedSabParameterKey = this.sabParameterKey(parameter);
    this.leadCardReleaseDurationMs = parameter.durationMs;
    this.upSwipeDampingRatio = parameter.dampingRatio;
    this.cardBounceOvershootX = parameter.reboundPercent;
  }

  aboutToAppear(): void {
    this.selectedPresetLabel = this.currentPresetLabel();
    this.selectedSabParameterKey = this.selectedPresetLabel.length > 0 ? '' : this.currentSabParameterKey();
  }

  private openPreviewPage(): void {
    try {
      const options: TaskbarUpPreviewRouteOptions = {
        url: 'pages/TaskbarUpPage',
      };
      this.getUIContext().getRouter().pushUrl(options);
    } catch (_error) {
    }
  }

  @Builder
  private buildHeader() {
    Column({ space: 10 }) {
      Text('RECENTS')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#CCFFFFFF')
        .letterSpacing(2)

      Text('上滑多任务参数')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Text('点击实验档位后，会同时应用首卡释放总时长、上滑阻尼和首卡回弹。')
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#D6FFFFFF')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildPresetButton(preset: TaskbarUpPresetItem) {
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
      ForEach(this.presets, (preset: TaskbarUpPresetItem) => {
        this.buildPresetButton(preset)
      }, (preset: TaskbarUpPresetItem) => preset.label)
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
  private buildSabParameterRow(parameter: SabParameterItem) {
    Row() {
      Column({ space: 2 }) {
        Text(parameter.mark)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isSabParameterSelected(parameter) ? '#101820' : '#FFFFFFFF')

        Text(parameter.name)
          .fontSize(10)
          .fontColor(this.isSabParameterSelected(parameter) ? '#80101820' : '#BFFFFFFF')
      }
      .width(58)
      .alignItems(HorizontalAlign.Start)

      Text(this.sabParameterSummary(parameter))
        .fontSize(12)
        .fontColor(this.isSabParameterSelected(parameter) ? '#101820' : '#E6FFFFFF')
        .lineHeight(17)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .backgroundColor(this.isSabParameterSelected(parameter) ? '#F2FFFFFF' : '#12FFFFFF')
    .borderRadius(14)
    .onClick(() => {
      this.applySabParameter(parameter);
    })
    .gesture(
      TapGesture({ count: 1 })
        .onAction(() => {
          this.applySabParameter(parameter);
        })
    )
  }

  @Builder
  private buildSabParameterColumn() {
    Column({ space: 7 }) {
      Row() {
        Text('新增参数')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFFFF')

        Text('S/A/B标')
          .fontSize(12)
          .fontColor('#CCFFFFFF')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      ForEach(this.sabParameters, (parameter: SabParameterItem) => {
        this.buildSabParameterRow(parameter)
      }, (parameter: SabParameterItem) => `${parameter.mark}-${parameter.name}`)
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#16FFFFFF')
    .borderRadius(20)
    .border({
      width: 1,
      color: '#1FFFFFFF'
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
        Scroll() {
          Column({ space: 24 }) {
            this.buildHeader()
            this.buildPresetList()
            this.buildPresetDetail()
            this.buildSabParameterColumn()
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
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
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
