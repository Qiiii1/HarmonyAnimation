import {
  INDEX_PRESETS,
  INDEX_SAB_PARAMETERS,
  IndexPresetItem,
  SabParameterItem,
  formatSabParameterText
} from './ExperimentPresetData';
import {
  TASKBAR_DOWN_PRESETS,
  TASKBAR_DOWN_SAB_PARAMETERS,
  TaskbarDownPresetItem
} from './ExperimentPresetData';
import {
  TASKBAR_UP_PRESETS,
  TASKBAR_UP_SAB_PARAMETERS,
  TaskbarUpPresetItem
} from './ExperimentPresetData';
import {
  UNLOCK_DESKTOP_PRESETS,
  UNLOCK_DESKTOP_SAB_PARAMETERS,
  UnlockDesktopPresetItem
} from './ExperimentPresetData';
import {
  VOLUME_PRESETS,
  VOLUME_SAB_PARAMETERS,
  VolumePresetItem
} from './ExperimentPresetData';

interface AllConfigRouteOptions {
  url: string;
}

@Entry
@Component
struct AllConfigPage {
  @StorageLink('indexOpenAnimationDurationMs') indexOpenDurationMs: number = 220;
  @StorageLink('indexIconReboundPercent') indexReboundPercent: number = 10;
  @StorageLink('volumeButtonWidthPulsePercent') volumeButtonPercent: number = 15;
  @StorageLink('volumeInteractionWidthReboundPercent') volumeInteractionPercent: number = 15;
  @StorageLink('volumeInteractionDragDampingRatio') volumeDampingRatio: number = 1.0;
  @StorageLink('taskbarUpSwipeDampingRatio') taskbarUpDampingRatio: number = 1.5;
  @StorageLink('taskbarUpLeadCardReleaseDurationMs') taskbarUpReleaseDurationMs: number = 1000;
  @StorageLink('taskbarUpCardBounceOvershootX') taskbarUpBounceOvershootX: number = 5;
  @StorageLink('unlockDragFollowFactor') unlockFollowFactor: number = 1.5;
  @StorageLink('unlockToHomeDurationMs') unlockDurationMs: number = 750;
  @StorageLink('unlockIconReboundPercent') unlockReboundPercent: number = 15;
  @StorageLink('taskbarDownOpenDragDampingRatio') taskbarDownDampingRatio: number = 1.5;
  @StorageLink('taskbarDownModuleEnterDurationMs') taskbarDownEnterDurationMs: number = 750;
  @StorageLink('taskbarDownModuleReboundPercent') taskbarDownReboundPercent: number = 2;
  @State selectedIndexPresetLabel: string = '';
  @State selectedVolumePresetLabel: string = '';
  @State selectedTaskbarUpPresetLabel: string = '';
  @State selectedUnlockPresetLabel: string = '';
  @State selectedTaskbarDownPresetLabel: string = '';
  @State selectedIndexSabParameterKey: string = '';
  @State selectedVolumeSabParameterKey: string = '';
  @State selectedTaskbarUpSabParameterKey: string = '';
  @State selectedUnlockSabParameterKey: string = '';
  @State selectedTaskbarDownSabParameterKey: string = '';

  private readonly PAGE_HORIZONTAL_PADDING: number = 18;
  private readonly PAGE_VERTICAL_PADDING: number = 24;
  private readonly PANEL_RADIUS: number = 32;
  private readonly PANEL_PADDING: number = 20;
  private readonly SECTION_RADIUS: number = 26;
  private readonly SECTION_GAP: number = 18;
  private readonly PRESET_GAP: number = 6;
  private readonly PRESET_HEIGHT: number = 34;
  private readonly PRESET_BUTTON_WIDTH: number = 42;
  private readonly indexPresets: IndexPresetItem[] = INDEX_PRESETS;
  private readonly volumePresets: VolumePresetItem[] = VOLUME_PRESETS;
  private readonly taskbarUpPresets: TaskbarUpPresetItem[] = TASKBAR_UP_PRESETS;
  private readonly unlockPresets: UnlockDesktopPresetItem[] = UNLOCK_DESKTOP_PRESETS;
  private readonly taskbarDownPresets: TaskbarDownPresetItem[] = TASKBAR_DOWN_PRESETS;
  private readonly indexSabParameters: SabParameterItem[] = INDEX_SAB_PARAMETERS;
  private readonly volumeSabParameters: SabParameterItem[] = VOLUME_SAB_PARAMETERS;
  private readonly taskbarUpSabParameters: SabParameterItem[] = TASKBAR_UP_SAB_PARAMETERS;
  private readonly unlockSabParameters: SabParameterItem[] = UNLOCK_DESKTOP_SAB_PARAMETERS;
  private readonly taskbarDownSabParameters: SabParameterItem[] = TASKBAR_DOWN_SAB_PARAMETERS;

  private isSelected(current: number, value: number): boolean {
    return Math.abs(current - value) < 0.001;
  }

  private indexPresetMatchesCurrentValue(preset: IndexPresetItem): boolean {
    return this.isSelected(this.indexOpenDurationMs, preset.durationMs)
      && this.isSelected(this.indexReboundPercent, preset.reboundPercent);
  }

  private isIndexPresetSelected(preset: IndexPresetItem): boolean {
    if (this.selectedIndexPresetLabel.length > 0) {
      return this.selectedIndexPresetLabel === preset.label;
    }
    return this.indexPresetMatchesCurrentValue(preset);
  }

  private volumePresetMatchesCurrentValue(preset: VolumePresetItem): boolean {
    return this.isSelected(this.volumeDampingRatio, preset.dampingRatio)
      && this.isSelected(this.volumeInteractionPercent, preset.reboundPercent)
      && this.isSelected(this.volumeButtonPercent, preset.reboundPercent);
  }

  private isVolumePresetSelected(preset: VolumePresetItem): boolean {
    if (this.selectedVolumePresetLabel.length > 0) {
      return this.selectedVolumePresetLabel === preset.label;
    }
    return this.volumePresetMatchesCurrentValue(preset);
  }

  private taskbarUpPresetMatchesCurrentValue(preset: TaskbarUpPresetItem): boolean {
    return this.isSelected(this.taskbarUpReleaseDurationMs, preset.durationMs)
      && this.isSelected(this.taskbarUpDampingRatio, preset.dampingRatio)
      && this.isSelected(this.taskbarUpBounceOvershootX, preset.reboundPercent);
  }

  private isTaskbarUpPresetSelected(preset: TaskbarUpPresetItem): boolean {
    if (this.selectedTaskbarUpPresetLabel.length > 0) {
      return this.selectedTaskbarUpPresetLabel === preset.label;
    }
    return this.taskbarUpPresetMatchesCurrentValue(preset);
  }

  private unlockPresetMatchesCurrentValue(preset: UnlockDesktopPresetItem): boolean {
    return this.isSelected(this.unlockDurationMs, preset.durationMs)
      && this.isSelected(this.unlockFollowFactor, preset.dampingRatio)
      && this.isSelected(this.unlockReboundPercent, preset.reboundPercent);
  }

  private isUnlockPresetSelected(preset: UnlockDesktopPresetItem): boolean {
    if (this.selectedUnlockPresetLabel.length > 0) {
      return this.selectedUnlockPresetLabel === preset.label;
    }
    return this.unlockPresetMatchesCurrentValue(preset);
  }

  private taskbarDownPresetMatchesCurrentValue(preset: TaskbarDownPresetItem): boolean {
    return this.isSelected(this.taskbarDownEnterDurationMs, preset.durationMs)
      && this.isSelected(this.taskbarDownDampingRatio, preset.dampingRatio)
      && this.isSelected(this.taskbarDownReboundPercent, preset.reboundPercent);
  }

  private isTaskbarDownPresetSelected(preset: TaskbarDownPresetItem): boolean {
    if (this.selectedTaskbarDownPresetLabel.length > 0) {
      return this.selectedTaskbarDownPresetLabel === preset.label;
    }
    return this.taskbarDownPresetMatchesCurrentValue(preset);
  }

  private currentIndexPresetLabel(): string {
    for (let index = 0; index < this.indexPresets.length; index += 1) {
      if (this.indexPresetMatchesCurrentValue(this.indexPresets[index])) {
        return this.indexPresets[index].label;
      }
    }
    return '';
  }

  private currentVolumePresetLabel(): string {
    for (let index = 0; index < this.volumePresets.length; index += 1) {
      if (this.volumePresetMatchesCurrentValue(this.volumePresets[index])) {
        return this.volumePresets[index].label;
      }
    }
    return '';
  }

  private currentTaskbarUpPresetLabel(): string {
    for (let index = 0; index < this.taskbarUpPresets.length; index += 1) {
      if (this.taskbarUpPresetMatchesCurrentValue(this.taskbarUpPresets[index])) {
        return this.taskbarUpPresets[index].label;
      }
    }
    return '';
  }

  private currentUnlockPresetLabel(): string {
    for (let index = 0; index < this.unlockPresets.length; index += 1) {
      if (this.unlockPresetMatchesCurrentValue(this.unlockPresets[index])) {
        return this.unlockPresets[index].label;
      }
    }
    return '';
  }

  private currentTaskbarDownPresetLabel(): string {
    for (let index = 0; index < this.taskbarDownPresets.length; index += 1) {
      if (this.taskbarDownPresetMatchesCurrentValue(this.taskbarDownPresets[index])) {
        return this.taskbarDownPresets[index].label;
      }
    }
    return '';
  }

  private sabParameterKey(parameter: SabParameterItem): string {
    return `${parameter.mark}-${parameter.name}`;
  }

  private indexSabParameterMatchesCurrentValue(parameter: SabParameterItem): boolean {
    return this.isSelected(this.indexOpenDurationMs, parameter.durationMs)
      && this.isSelected(this.indexReboundPercent, parameter.reboundPercent);
  }

  private volumeSabParameterMatchesCurrentValue(parameter: SabParameterItem): boolean {
    return this.isSelected(this.volumeDampingRatio, parameter.dampingRatio)
      && this.isSelected(this.volumeInteractionPercent, parameter.reboundPercent)
      && this.isSelected(this.volumeButtonPercent, parameter.reboundPercent);
  }

  private taskbarUpSabParameterMatchesCurrentValue(parameter: SabParameterItem): boolean {
    return this.isSelected(this.taskbarUpReleaseDurationMs, parameter.durationMs)
      && this.isSelected(this.taskbarUpDampingRatio, parameter.dampingRatio)
      && this.isSelected(this.taskbarUpBounceOvershootX, parameter.reboundPercent);
  }

  private unlockSabParameterMatchesCurrentValue(parameter: SabParameterItem): boolean {
    return this.isSelected(this.unlockDurationMs, parameter.durationMs)
      && this.isSelected(this.unlockFollowFactor, parameter.dampingRatio)
      && this.isSelected(this.unlockReboundPercent, parameter.reboundPercent);
  }

  private taskbarDownSabParameterMatchesCurrentValue(parameter: SabParameterItem): boolean {
    return this.isSelected(this.taskbarDownEnterDurationMs, parameter.durationMs)
      && this.isSelected(this.taskbarDownDampingRatio, parameter.dampingRatio)
      && this.isSelected(this.taskbarDownReboundPercent, parameter.reboundPercent);
  }

  private currentIndexSabParameterKey(): string {
    for (let index = 0; index < this.indexSabParameters.length; index += 1) {
      if (this.indexSabParameterMatchesCurrentValue(this.indexSabParameters[index])) {
        return this.sabParameterKey(this.indexSabParameters[index]);
      }
    }
    return '';
  }

  private currentVolumeSabParameterKey(): string {
    for (let index = 0; index < this.volumeSabParameters.length; index += 1) {
      if (this.volumeSabParameterMatchesCurrentValue(this.volumeSabParameters[index])) {
        return this.sabParameterKey(this.volumeSabParameters[index]);
      }
    }
    return '';
  }

  private currentTaskbarUpSabParameterKey(): string {
    for (let index = 0; index < this.taskbarUpSabParameters.length; index += 1) {
      if (this.taskbarUpSabParameterMatchesCurrentValue(this.taskbarUpSabParameters[index])) {
        return this.sabParameterKey(this.taskbarUpSabParameters[index]);
      }
    }
    return '';
  }

  private currentUnlockSabParameterKey(): string {
    for (let index = 0; index < this.unlockSabParameters.length; index += 1) {
      if (this.unlockSabParameterMatchesCurrentValue(this.unlockSabParameters[index])) {
        return this.sabParameterKey(this.unlockSabParameters[index]);
      }
    }
    return '';
  }

  private currentTaskbarDownSabParameterKey(): string {
    for (let index = 0; index < this.taskbarDownSabParameters.length; index += 1) {
      if (this.taskbarDownSabParameterMatchesCurrentValue(this.taskbarDownSabParameters[index])) {
        return this.sabParameterKey(this.taskbarDownSabParameters[index]);
      }
    }
    return '';
  }

  private activeIndexPresetLabel(): string {
    if (this.selectedIndexPresetLabel.length > 0) {
      return this.selectedIndexPresetLabel;
    }
    const currentLabel = this.currentIndexPresetLabel();
    if (currentLabel.length > 0) {
      return currentLabel;
    }
    return '自定义';
  }

  private activeVolumePresetLabel(): string {
    if (this.selectedVolumePresetLabel.length > 0) {
      return this.selectedVolumePresetLabel;
    }
    const currentLabel = this.currentVolumePresetLabel();
    if (currentLabel.length > 0) {
      return currentLabel;
    }
    return '自定义';
  }

  private activeTaskbarUpPresetLabel(): string {
    if (this.selectedTaskbarUpPresetLabel.length > 0) {
      return this.selectedTaskbarUpPresetLabel;
    }
    const currentLabel = this.currentTaskbarUpPresetLabel();
    if (currentLabel.length > 0) {
      return currentLabel;
    }
    return '自定义';
  }

  private activeUnlockPresetLabel(): string {
    if (this.selectedUnlockPresetLabel.length > 0) {
      return this.selectedUnlockPresetLabel;
    }
    const currentLabel = this.currentUnlockPresetLabel();
    if (currentLabel.length > 0) {
      return currentLabel;
    }
    return '自定义';
  }

  private activeTaskbarDownPresetLabel(): string {
    if (this.selectedTaskbarDownPresetLabel.length > 0) {
      return this.selectedTaskbarDownPresetLabel;
    }
    const currentLabel = this.currentTaskbarDownPresetLabel();
    if (currentLabel.length > 0) {
      return currentLabel;
    }
    return '自定义';
  }

  private activeIndexPresetType(): string {
    const label = this.activeIndexPresetLabel();
    for (let index = 0; index < this.indexPresets.length; index += 1) {
      if (this.indexPresets[index].label === label) {
        return this.indexPresets[index].type;
      }
    }
    return '当前参数';
  }

  private activeVolumePresetType(): string {
    const label = this.activeVolumePresetLabel();
    for (let index = 0; index < this.volumePresets.length; index += 1) {
      if (this.volumePresets[index].label === label) {
        return this.volumePresets[index].type;
      }
    }
    return '当前参数';
  }

  private activeTaskbarUpPresetType(): string {
    const label = this.activeTaskbarUpPresetLabel();
    for (let index = 0; index < this.taskbarUpPresets.length; index += 1) {
      if (this.taskbarUpPresets[index].label === label) {
        return this.taskbarUpPresets[index].type;
      }
    }
    return '当前参数';
  }

  private activeUnlockPresetType(): string {
    const label = this.activeUnlockPresetLabel();
    for (let index = 0; index < this.unlockPresets.length; index += 1) {
      if (this.unlockPresets[index].label === label) {
        return this.unlockPresets[index].type;
      }
    }
    return '当前参数';
  }

  private activeTaskbarDownPresetType(): string {
    const label = this.activeTaskbarDownPresetLabel();
    for (let index = 0; index < this.taskbarDownPresets.length; index += 1) {
      if (this.taskbarDownPresets[index].label === label) {
        return this.taskbarDownPresets[index].type;
      }
    }
    return '当前参数';
  }

  private applyIndexPreset(preset: IndexPresetItem): void {
    this.selectedIndexPresetLabel = preset.label;
    this.selectedIndexSabParameterKey = '';
    this.indexOpenDurationMs = preset.durationMs;
    this.indexReboundPercent = preset.reboundPercent;
  }

  private applyVolumePreset(preset: VolumePresetItem): void {
    this.selectedVolumePresetLabel = preset.label;
    this.selectedVolumeSabParameterKey = '';
    this.volumeDampingRatio = preset.dampingRatio;
    this.volumeInteractionPercent = preset.reboundPercent;
    this.volumeButtonPercent = preset.reboundPercent;
  }

  private applyTaskbarUpPreset(preset: TaskbarUpPresetItem): void {
    this.selectedTaskbarUpPresetLabel = preset.label;
    this.selectedTaskbarUpSabParameterKey = '';
    this.taskbarUpReleaseDurationMs = preset.durationMs;
    this.taskbarUpDampingRatio = preset.dampingRatio;
    this.taskbarUpBounceOvershootX = preset.reboundPercent;
  }

  private applyUnlockPreset(preset: UnlockDesktopPresetItem): void {
    this.selectedUnlockPresetLabel = preset.label;
    this.selectedUnlockSabParameterKey = '';
    this.unlockDurationMs = preset.durationMs;
    this.unlockFollowFactor = preset.dampingRatio;
    this.unlockReboundPercent = preset.reboundPercent;
  }

  private applyTaskbarDownPreset(preset: TaskbarDownPresetItem): void {
    this.selectedTaskbarDownPresetLabel = preset.label;
    this.selectedTaskbarDownSabParameterKey = '';
    this.taskbarDownEnterDurationMs = preset.durationMs;
    this.taskbarDownDampingRatio = preset.dampingRatio;
    this.taskbarDownReboundPercent = preset.reboundPercent;
  }

  private applySabParameter(sceneKey: string, parameter: SabParameterItem): void {
    if (sceneKey === 'index') {
      this.selectedIndexPresetLabel = '';
      this.selectedIndexSabParameterKey = this.sabParameterKey(parameter);
      this.indexOpenDurationMs = parameter.durationMs;
      this.indexReboundPercent = parameter.reboundPercent;
      return;
    }
    if (sceneKey === 'volume') {
      this.selectedVolumePresetLabel = '';
      this.selectedVolumeSabParameterKey = this.sabParameterKey(parameter);
      this.volumeDampingRatio = parameter.dampingRatio;
      this.volumeInteractionPercent = parameter.reboundPercent;
      this.volumeButtonPercent = parameter.reboundPercent;
      return;
    }
    if (sceneKey === 'taskbarUp') {
      this.selectedTaskbarUpPresetLabel = '';
      this.selectedTaskbarUpSabParameterKey = this.sabParameterKey(parameter);
      this.taskbarUpReleaseDurationMs = parameter.durationMs;
      this.taskbarUpDampingRatio = parameter.dampingRatio;
      this.taskbarUpBounceOvershootX = parameter.reboundPercent;
      return;
    }
    if (sceneKey === 'unlock') {
      this.selectedUnlockPresetLabel = '';
      this.selectedUnlockSabParameterKey = this.sabParameterKey(parameter);
      this.unlockDurationMs = parameter.durationMs;
      this.unlockFollowFactor = parameter.dampingRatio;
      this.unlockReboundPercent = parameter.reboundPercent;
      return;
    }
    if (sceneKey === 'taskbarDown') {
      this.selectedTaskbarDownPresetLabel = '';
      this.selectedTaskbarDownSabParameterKey = this.sabParameterKey(parameter);
      this.taskbarDownEnterDurationMs = parameter.durationMs;
      this.taskbarDownDampingRatio = parameter.dampingRatio;
      this.taskbarDownReboundPercent = parameter.reboundPercent;
    }
  }

  aboutToAppear(): void {
    this.selectedIndexPresetLabel = this.currentIndexPresetLabel();
    this.selectedVolumePresetLabel = this.currentVolumePresetLabel();
    this.selectedTaskbarUpPresetLabel = this.currentTaskbarUpPresetLabel();
    this.selectedUnlockPresetLabel = this.currentUnlockPresetLabel();
    this.selectedTaskbarDownPresetLabel = this.currentTaskbarDownPresetLabel();
    this.selectedIndexSabParameterKey = this.selectedIndexPresetLabel.length > 0 ? '' : this.currentIndexSabParameterKey();
    this.selectedVolumeSabParameterKey = this.selectedVolumePresetLabel.length > 0 ? '' : this.currentVolumeSabParameterKey();
    this.selectedTaskbarUpSabParameterKey = this.selectedTaskbarUpPresetLabel.length > 0 ? '' : this.currentTaskbarUpSabParameterKey();
    this.selectedUnlockSabParameterKey = this.selectedUnlockPresetLabel.length > 0 ? '' : this.currentUnlockSabParameterKey();
    this.selectedTaskbarDownSabParameterKey = this.selectedTaskbarDownPresetLabel.length > 0 ? '' : this.currentTaskbarDownSabParameterKey();
  }

  private indexSummary(preset: IndexPresetItem): string {
    return `${preset.type} / 总时长 ${preset.durationMs}ms / 回弹 ${preset.reboundPercent}%`;
  }

  private indexParameterText(): string {
    return `总时长 ${this.indexOpenDurationMs}ms / 回弹 ${this.indexReboundPercent}%`;
  }

  private volumeSummary(preset: VolumePresetItem): string {
    return `${preset.type} / 阻尼 ${preset.dampingRatio} / 回弹 ${preset.reboundPercent}%`;
  }

  private volumeParameterText(): string {
    return `阻尼 ${this.volumeDampingRatio} / 滑动回弹 ${this.volumeInteractionPercent}% / 按键回弹 ${this.volumeButtonPercent}%`;
  }

  private taskbarUpSummary(preset: TaskbarUpPresetItem): string {
    return `${preset.type} / 时长 ${preset.durationMs}ms / 阻尼 ${preset.dampingRatio} / 回弹 ${preset.reboundPercent}%`;
  }

  private taskbarUpParameterText(): string {
    return `时长 ${this.taskbarUpReleaseDurationMs}ms / 阻尼 ${this.taskbarUpDampingRatio} / 回弹 ${this.taskbarUpBounceOvershootX}%`;
  }

  private unlockSummary(preset: UnlockDesktopPresetItem): string {
    return `${preset.type} / 时长 ${preset.durationMs}ms / 阻尼 ${preset.dampingRatio} / 回弹 ${preset.reboundPercent}%`;
  }

  private unlockParameterText(): string {
    return `时长 ${this.unlockDurationMs}ms / 阻尼 ${this.unlockFollowFactor} / 回弹 ${this.unlockReboundPercent}%`;
  }

  private taskbarDownSummary(preset: TaskbarDownPresetItem): string {
    return `${preset.type} / 时长 ${preset.durationMs}ms / 阻尼 ${preset.dampingRatio} / 回弹 ${preset.reboundPercent}%`;
  }

  private taskbarDownParameterText(): string {
    return `时长 ${this.taskbarDownEnterDurationMs}ms / 阻尼 ${this.taskbarDownDampingRatio} / 回弹 ${this.taskbarDownReboundPercent}%`;
  }

  private sabParameterSummary(parameter: SabParameterItem): string {
    return formatSabParameterText(parameter);
  }

  private selectedSabParameterKey(sceneKey: string): string {
    if (sceneKey === 'index') {
      return this.selectedIndexSabParameterKey;
    }
    if (sceneKey === 'volume') {
      return this.selectedVolumeSabParameterKey;
    }
    if (sceneKey === 'taskbarUp') {
      return this.selectedTaskbarUpSabParameterKey;
    }
    if (sceneKey === 'unlock') {
      return this.selectedUnlockSabParameterKey;
    }
    if (sceneKey === 'taskbarDown') {
      return this.selectedTaskbarDownSabParameterKey;
    }
    return '';
  }

  private isSabParameterSelected(sceneKey: string, parameter: SabParameterItem): boolean {
    return this.selectedSabParameterKey(sceneKey) === this.sabParameterKey(parameter);
  }

  private openPage(url: string): void {
    try {
      const options: AllConfigRouteOptions = {
        url: url,
      };
      this.getUIContext().getRouter().pushUrl(options);
    } catch (_error) {
    }
  }

  @Builder
  private buildHeader() {
    Column({ space: 10 }) {
      Text('PARAMETER HUB')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#CCFFFFFF')
        .letterSpacing(2)

      Text('参数总控台')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Text('按实验档位统一写入一组参数，修改后直接进入对应预览。')
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#D6FFFFFF')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildSectionHeader(title: string, subtitle: string, url: string) {
    Row() {
      Column({ space: 5 }) {
        Text(title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFFFF')

        Text(subtitle)
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#CCFFFFFF')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button() {
        Text('预览')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#101820')
      }
      .height(38)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F2FFFFFF')
      .borderRadius(999)
      .onClick(() => {
        this.openPage(url);
      })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private buildIndexPresetButton(preset: IndexPresetItem) {
    Stack() {
      Text(preset.label)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isIndexPresetSelected(preset) ? '#101820' : '#F5F7FA')
    }
    .width(this.PRESET_BUTTON_WIDTH)
    .height(this.PRESET_HEIGHT)
    .backgroundColor(this.isIndexPresetSelected(preset) ? '#F2FFFFFF' : '#18FFFFFF')
    .borderRadius(15)
    .border({
      width: 1,
      color: this.isIndexPresetSelected(preset) ? '#CCFFFFFF' : '#22FFFFFF'
    })
    .margin({ right: this.PRESET_GAP, bottom: this.PRESET_GAP })
    .onClick(() => {
      this.applyIndexPreset(preset);
    })
    .gesture(
      TapGesture({ count: 1 })
        .onAction(() => {
          this.applyIndexPreset(preset);
        })
    )
  }

  @Builder
  private buildVolumePresetButton(preset: VolumePresetItem) {
    Stack() {
      Text(preset.label)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isVolumePresetSelected(preset) ? '#101820' : '#F5F7FA')
    }
    .width(this.PRESET_BUTTON_WIDTH)
    .height(this.PRESET_HEIGHT)
    .backgroundColor(this.isVolumePresetSelected(preset) ? '#F2FFFFFF' : '#18FFFFFF')
    .borderRadius(15)
    .border({
      width: 1,
      color: this.isVolumePresetSelected(preset) ? '#CCFFFFFF' : '#22FFFFFF'
    })
    .margin({ right: this.PRESET_GAP, bottom: this.PRESET_GAP })
    .onClick(() => {
      this.applyVolumePreset(preset);
    })
    .gesture(
      TapGesture({ count: 1 })
        .onAction(() => {
          this.applyVolumePreset(preset);
        })
    )
  }

  @Builder
  private buildTaskbarUpPresetButton(preset: TaskbarUpPresetItem) {
    Stack() {
      Text(preset.label)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isTaskbarUpPresetSelected(preset) ? '#101820' : '#F5F7FA')
    }
    .width(this.PRESET_BUTTON_WIDTH)
    .height(this.PRESET_HEIGHT)
    .backgroundColor(this.isTaskbarUpPresetSelected(preset) ? '#F2FFFFFF' : '#18FFFFFF')
    .borderRadius(15)
    .border({
      width: 1,
      color: this.isTaskbarUpPresetSelected(preset) ? '#CCFFFFFF' : '#22FFFFFF'
    })
    .margin({ right: this.PRESET_GAP, bottom: this.PRESET_GAP })
    .onClick(() => {
      this.applyTaskbarUpPreset(preset);
    })
    .gesture(
      TapGesture({ count: 1 })
        .onAction(() => {
          this.applyTaskbarUpPreset(preset);
        })
    )
  }

  @Builder
  private buildUnlockPresetButton(preset: UnlockDesktopPresetItem) {
    Stack() {
      Text(preset.label)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isUnlockPresetSelected(preset) ? '#101820' : '#F5F7FA')
    }
    .width(this.PRESET_BUTTON_WIDTH)
    .height(this.PRESET_HEIGHT)
    .backgroundColor(this.isUnlockPresetSelected(preset) ? '#F2FFFFFF' : '#18FFFFFF')
    .borderRadius(15)
    .border({
      width: 1,
      color: this.isUnlockPresetSelected(preset) ? '#CCFFFFFF' : '#22FFFFFF'
    })
    .margin({ right: this.PRESET_GAP, bottom: this.PRESET_GAP })
    .onClick(() => {
      this.applyUnlockPreset(preset);
    })
    .gesture(
      TapGesture({ count: 1 })
        .onAction(() => {
          this.applyUnlockPreset(preset);
        })
    )
  }

  @Builder
  private buildTaskbarDownPresetButton(preset: TaskbarDownPresetItem) {
    Stack() {
      Text(preset.label)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isTaskbarDownPresetSelected(preset) ? '#101820' : '#F5F7FA')
    }
    .width(this.PRESET_BUTTON_WIDTH)
    .height(this.PRESET_HEIGHT)
    .backgroundColor(this.isTaskbarDownPresetSelected(preset) ? '#F2FFFFFF' : '#18FFFFFF')
    .borderRadius(15)
    .border({
      width: 1,
      color: this.isTaskbarDownPresetSelected(preset) ? '#CCFFFFFF' : '#22FFFFFF'
    })
    .margin({ right: this.PRESET_GAP, bottom: this.PRESET_GAP })
    .onClick(() => {
      this.applyTaskbarDownPreset(preset);
    })
    .gesture(
      TapGesture({ count: 1 })
        .onAction(() => {
          this.applyTaskbarDownPreset(preset);
        })
    )
  }

  @Builder
  private buildSabParameterRow(sceneKey: string, parameter: SabParameterItem) {
    Row() {
      Column({ space: 2 }) {
        Text(parameter.mark)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isSabParameterSelected(sceneKey, parameter) ? '#101820' : '#FFFFFFFF')

        Text(parameter.name)
          .fontSize(9)
          .fontColor(this.isSabParameterSelected(sceneKey, parameter) ? '#80101820' : '#BFFFFFFF')
      }
      .width(54)
      .alignItems(HorizontalAlign.Start)

      Text(this.sabParameterSummary(parameter))
        .fontSize(11)
        .fontColor(this.isSabParameterSelected(sceneKey, parameter) ? '#101820' : '#E6FFFFFF')
        .lineHeight(16)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 9, right: 9, top: 5, bottom: 5 })
    .backgroundColor(this.isSabParameterSelected(sceneKey, parameter) ? '#F2FFFFFF' : '#10FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      this.applySabParameter(sceneKey, parameter);
    })
    .gesture(
      TapGesture({ count: 1 })
        .onAction(() => {
          this.applySabParameter(sceneKey, parameter);
        })
    )
  }

  @Builder
  private buildSabParameterColumn(sceneKey: string, sabParameters: SabParameterItem[]) {
    Column({ space: 6 }) {
      Row() {
        Text('新增参数')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFFFF')

        Text('S/A/B标')
          .fontSize(11)
          .fontColor('#CCFFFFFF')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      ForEach(sabParameters, (parameter: SabParameterItem) => {
        this.buildSabParameterRow(sceneKey, parameter)
      }, (parameter: SabParameterItem) => `${parameter.mark}-${parameter.name}`)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#12FFFFFF')
    .borderRadius(16)
    .border({
      width: 1,
      color: '#1AFFFFFF'
    })
  }

  @Builder
  private buildPresetDetail(
    label: string,
    type: string,
    parameterText: string,
    sceneKey: string,
    sabParameters: SabParameterItem[]
  ) {
    Column({ space: 8 }) {
      Row() {
        Text(label)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFFFF')

        Text(type)
          .fontSize(12)
          .fontColor('#CCFFFFFF')
          .maxLines(1)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Text(parameterText)
        .fontSize(13)
        .fontColor('#F2FFFFFF')
        .lineHeight(20)

      this.buildSabParameterColumn(sceneKey, sabParameters)
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#18FFFFFF')
    .borderRadius(20)
    .border({
      width: 1,
      color: '#1FFFFFFF'
    })
  }

  @Builder
  private buildIndexSection() {
    Column({ space: this.PRESET_GAP }) {
      this.buildSectionHeader('应用打开退出', 'S5 档位：打开/关闭总时长 + icon 回弹幅度。', 'pages/Index')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.indexPresets, (preset: IndexPresetItem) => {
          this.buildIndexPresetButton(preset)
        }, (preset: IndexPresetItem) => `index-${preset.label}`)
      }
      .width('100%')

      this.buildPresetDetail(this.activeIndexPresetLabel(), this.activeIndexPresetType(), this.indexParameterText(), 'index', this.indexSabParameters)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#25212730')
    .backdropBlur(20)
    .borderRadius(this.SECTION_RADIUS)
    .border({
      width: 1,
      color: '#22FFFFFF'
    })
  }

  @Builder
  private buildVolumeSection() {
    Column({ space: this.PRESET_GAP }) {
      this.buildSectionHeader('音量条', 'S2 档位：滑动阻尼 + 回弹幅度，时长保持默认。', 'pages/VolumePage')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.volumePresets, (preset: VolumePresetItem) => {
          this.buildVolumePresetButton(preset)
        }, (preset: VolumePresetItem) => `volume-${preset.label}`)
      }
      .width('100%')

      this.buildPresetDetail(this.activeVolumePresetLabel(), this.activeVolumePresetType(), this.volumeParameterText(), 'volume', this.volumeSabParameters)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#25212730')
    .backdropBlur(20)
    .borderRadius(this.SECTION_RADIUS)
    .border({
      width: 1,
      color: '#22FFFFFF'
    })
  }

  @Builder
  private buildTaskbarUpSection() {
    Column({ space: this.PRESET_GAP }) {
      this.buildSectionHeader('上滑多任务', 'S1 档位：首卡释放总时长 + 上滑阻尼 + 首卡回弹。', 'pages/TaskbarUpPage')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.taskbarUpPresets, (preset: TaskbarUpPresetItem) => {
          this.buildTaskbarUpPresetButton(preset)
        }, (preset: TaskbarUpPresetItem) => `taskbar-up-${preset.label}`)
      }
      .width('100%')

      this.buildPresetDetail(this.activeTaskbarUpPresetLabel(), this.activeTaskbarUpPresetType(), this.taskbarUpParameterText(), 'taskbarUp', this.taskbarUpSabParameters)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#25212730')
    .backdropBlur(20)
    .borderRadius(this.SECTION_RADIUS)
    .border({
      width: 1,
      color: '#22FFFFFF'
    })
  }

  @Builder
  private buildUnlockSection() {
    Column({ space: this.PRESET_GAP }) {
      this.buildSectionHeader('解锁桌面', 'S4 档位：解锁时长 + 上划阻尼 + 模块回弹。', 'pages/UnlockDesktopPage')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.unlockPresets, (preset: UnlockDesktopPresetItem) => {
          this.buildUnlockPresetButton(preset)
        }, (preset: UnlockDesktopPresetItem) => `unlock-${preset.label}`)
      }
      .width('100%')

      this.buildPresetDetail(this.activeUnlockPresetLabel(), this.activeUnlockPresetType(), this.unlockParameterText(), 'unlock', this.unlockSabParameters)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#25212730')
    .backdropBlur(20)
    .borderRadius(this.SECTION_RADIUS)
    .border({
      width: 1,
      color: '#22FFFFFF'
    })
  }

  @Builder
  private buildTaskbarDownSection() {
    Column({ space: this.PRESET_GAP }) {
      this.buildSectionHeader('下拉任务栏', 'S3 档位：模块入场时长 + 下拉阻尼 + 模块回弹。', 'pages/TaskbarDownPage')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.taskbarDownPresets, (preset: TaskbarDownPresetItem) => {
          this.buildTaskbarDownPresetButton(preset)
        }, (preset: TaskbarDownPresetItem) => `taskbar-down-${preset.label}`)
      }
      .width('100%')

      this.buildPresetDetail(this.activeTaskbarDownPresetLabel(), this.activeTaskbarDownPresetType(), this.taskbarDownParameterText(), 'taskbarDown', this.taskbarDownSabParameters)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#25212730')
    .backdropBlur(20)
    .borderRadius(this.SECTION_RADIUS)
    .border({
      width: 1,
      color: '#22FFFFFF'
    })
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
        .blur(34)
        .opacity(0.24)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#82070A0F')
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Column() {
        Column({ space: 22 }) {
          this.buildHeader()

          Scroll() {
            Column({ space: this.SECTION_GAP }) {
              this.buildIndexSection()
              this.buildVolumeSection()
              this.buildTaskbarUpSection()
              this.buildUnlockSection()
              this.buildTaskbarDownSection()
            }
            .width('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
        .padding(this.PANEL_PADDING)
        .backgroundColor('#30212730')
        .backdropBlur(30)
        .borderRadius(this.PANEL_RADIUS)
        .border({
          width: 1,
          color: '#26FFFFFF'
        })
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
