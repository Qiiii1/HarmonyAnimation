export interface TaskbarUpPresetItem {
  label: string;
  // 实验类型，用来区分时间轴、回弹轴、阻尼轴和交互验证。
  type: string;
  // 松手后首卡从预览位置入位、过冲、回正的总时长，单位 ms，对应 taskbarUpLeadCardReleaseDurationMs。
  durationMs: number;
  // 上滑触发时的阻尼比，对应 taskbarUpSwipeDampingRatio。
  dampingRatio: number;
  // 首卡自动入场时向右过冲再回正的幅度，单位为卡片宽度百分比，对应 taskbarUpCardBounceOvershootX。
  reboundPercent: number;
}

export interface VolumePresetItem {
  label: string;
  // 实验类型，用来区分阻尼轴、回弹轴和交互验证。
  type: string;
  // 滑动调节音量时的阻尼比，对应 volumeInteractionDragDampingRatio。
  dampingRatio: number;
  // 手指按压音量条后宽度回弹幅度，单位为当前宽度百分比，对应 volumeInteractionWidthReboundPercent。
  reboundPercent: number;
}

export interface TaskbarDownPresetItem {
  label: string;
  // 实验类型，用来区分时间轴、回弹轴、阻尼轴和交互验证。
  type: string;
  // Control Module 分层入场的总时长，单位 ms，对应 taskbarDownModuleEnterDurationMs。
  durationMs: number;
  // 下拉触发背景模糊和模块入场时的阻尼比，对应 taskbarDownOpenDragDampingRatio。
  dampingRatio: number;
  // 模块入场时多向下移动再回正的距离，单位为屏幕高度百分比，对应 taskbarDownModuleReboundPercent。
  reboundPercent: number;
}

export interface UnlockDesktopPresetItem {
  label: string;
  // 实验类型，用来区分时间轴、回弹轴、阻尼轴和交互验证。
  type: string;
  // 从触发解锁到进入桌面的动效总时长，单位 ms，对应 unlockToHomeDurationMs。
  durationMs: number;
  // 上划解锁时的阻尼比，对应 unlockDragFollowFactor；值越大越不跟手。
  dampingRatio: number;
  // 桌面模块出现时放大再回正的幅度，单位百分比，对应 unlockIconReboundPercent。
  reboundPercent: number;
}

export interface IndexPresetItem {
  label: string;
  // 实验类型，用来区分时长轴、回弹轴和交互验证。
  type: string;
  // 应用打开/退出完整阶段总时长，单位 ms，对应 indexOpenAnimationDurationMs。
  durationMs: number;
  // icon 缩回后的回弹幅度，单位百分比，对应 indexIconReboundPercent。
  reboundPercent: number;
}

export const TASKBAR_UP_PRESETS: TaskbarUpPresetItem[] = [
  { label: 'Z01', type: '单因素-时间轴', durationMs: 600, dampingRatio: 0.9, reboundPercent: 5 },
  { label: 'Z02', type: '单因素-时间轴', durationMs: 800, dampingRatio: 0.9, reboundPercent: 5 },
  { label: 'Z03', type: '单因素-时间轴', durationMs: 1000, dampingRatio: 0.9, reboundPercent: 5 },
  { label: 'Z04', type: '单因素-时间轴', durationMs: 1200, dampingRatio: 0.9, reboundPercent: 5 },
  { label: 'Z05', type: '单因素-时间轴', durationMs: 1500, dampingRatio: 0.9, reboundPercent: 5 },
  { label: 'Z06', type: '单因素-回弹轴', durationMs: 1000, dampingRatio: 0.9, reboundPercent: 0 },
  { label: 'Z07', type: '单因素-回弹轴', durationMs: 1000, dampingRatio: 0.9, reboundPercent: 2 },
  { label: 'Z08', type: '单因素-回弹轴', durationMs: 1000, dampingRatio: 0.9, reboundPercent: 5 },
  { label: 'Z09', type: '单因素-回弹轴', durationMs: 1000, dampingRatio: 0.9, reboundPercent: 7 },
  { label: 'Z10', type: '单因素-回弹轴', durationMs: 1000, dampingRatio: 0.9, reboundPercent: 10 },
  { label: 'Z11', type: '单因素-阻尼轴', durationMs: 1000, dampingRatio: 0.5, reboundPercent: 5 },
  { label: 'Z12', type: '单因素-阻尼轴', durationMs: 1000, dampingRatio: 0.7, reboundPercent: 5 },
  { label: 'Z13', type: '单因素-阻尼轴', durationMs: 1000, dampingRatio: 0.9, reboundPercent: 5 },
  { label: 'Z14', type: '单因素-阻尼轴', durationMs: 1000, dampingRatio: 1.2, reboundPercent: 5 },
  { label: 'Z15', type: '单因素-阻尼轴', durationMs: 1000, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z16', type: '交互验证', durationMs: 600, dampingRatio: 0.9, reboundPercent: 0 },
  { label: 'Z17', type: '交互验证', durationMs: 600, dampingRatio: 0.9, reboundPercent: 10 },
  { label: 'Z18', type: '交互验证', durationMs: 1500, dampingRatio: 0.9, reboundPercent: 0 },
  { label: 'Z19', type: '交互验证', durationMs: 1500, dampingRatio: 0.9, reboundPercent: 10 },
  { label: 'Z20', type: '交互验证', durationMs: 600, dampingRatio: 0.5, reboundPercent: 5 },
  { label: 'Z21', type: '交互验证', durationMs: 600, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z22', type: '交互验证', durationMs: 1500, dampingRatio: 0.5, reboundPercent: 5 },
  { label: 'Z23', type: '交互验证', durationMs: 1500, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z24', type: '交互验证', durationMs: 1000, dampingRatio: 0.5, reboundPercent: 0 },
  { label: 'Z25', type: '交互验证', durationMs: 1000, dampingRatio: 0.5, reboundPercent: 10 },
  { label: 'Z26', type: '交互验证', durationMs: 1000, dampingRatio: 1.5, reboundPercent: 0 },
  { label: 'Z27', type: '交互验证', durationMs: 1000, dampingRatio: 1.5, reboundPercent: 10 },
  { label: 'Z28', type: '极端点-低低低', durationMs: 600, dampingRatio: 0.5, reboundPercent: 0 },
  { label: 'Z29', type: '极端点-高高高', durationMs: 1500, dampingRatio: 1.5, reboundPercent: 10 },
  { label: 'Z30', type: '中心点重复', durationMs: 1000, dampingRatio: 0.9, reboundPercent: 5 }
];

export const VOLUME_PRESETS: VolumePresetItem[] = [
  { label: 'Z01', type: '单因素-阻尼比轴', dampingRatio: 0.5, reboundPercent: 15 },
  { label: 'Z02', type: '单因素-阻尼比轴', dampingRatio: 0.7, reboundPercent: 15 },
  { label: 'Z03', type: '单因素-阻尼比轴', dampingRatio: 1, reboundPercent: 15 },
  { label: 'Z04', type: '单因素-阻尼比轴', dampingRatio: 1.2, reboundPercent: 15 },
  { label: 'Z05', type: '单因素-阻尼比轴', dampingRatio: 1.5, reboundPercent: 15 },
  { label: 'Z06', type: '单因素-回弹轴', dampingRatio: 1, reboundPercent: 0 },
  { label: 'Z07', type: '单因素-回弹轴', dampingRatio: 1, reboundPercent: 8 },
  { label: 'Z08', type: '单因素-回弹轴', dampingRatio: 1, reboundPercent: 22 },
  { label: 'Z09', type: '单因素-回弹轴', dampingRatio: 1, reboundPercent: 30 },
  { label: 'Z10', type: '交互验证-低低', dampingRatio: 0.5, reboundPercent: 0 },
  { label: 'Z11', type: '交互验证-低高', dampingRatio: 0.5, reboundPercent: 30 },
  { label: 'Z12', type: '交互验证-高低', dampingRatio: 1.5, reboundPercent: 0 },
  { label: 'Z13', type: '交互验证-高高', dampingRatio: 1.5, reboundPercent: 30 },
  { label: 'Z14', type: '补充-中低', dampingRatio: 0.7, reboundPercent: 8 },
  { label: 'Z15', type: '补充-中高', dampingRatio: 1.2, reboundPercent: 22 },
  { label: 'Z16', type: '中心点重复', dampingRatio: 1, reboundPercent: 15 }
];

export const TASKBAR_DOWN_PRESETS: TaskbarDownPresetItem[] = [
  { label: 'Z01', type: '单因素-时间轴', durationMs: 300, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z02', type: '单因素-时间轴', durationMs: 600, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z03', type: '单因素-时间轴', durationMs: 900, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z04', type: '单因素-时间轴', durationMs: 1200, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z05', type: '单因素-时间轴', durationMs: 1500, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z06', type: '单因素-回弹轴', durationMs: 900, dampingRatio: 1.5, reboundPercent: 0 },
  { label: 'Z07', type: '单因素-回弹轴', durationMs: 900, dampingRatio: 1.5, reboundPercent: 3 },
  { label: 'Z08', type: '单因素-回弹轴', durationMs: 900, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z09', type: '单因素-回弹轴', durationMs: 900, dampingRatio: 1.5, reboundPercent: 10 },
  { label: 'Z10', type: '单因素-回弹轴', durationMs: 900, dampingRatio: 1.5, reboundPercent: 15 },
  { label: 'Z11', type: '单因素-阻尼轴', durationMs: 900, dampingRatio: 0.5, reboundPercent: 5 },
  { label: 'Z12', type: '单因素-阻尼轴', durationMs: 900, dampingRatio: 1, reboundPercent: 5 },
  { label: 'Z13', type: '单因素-阻尼轴', durationMs: 900, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z14', type: '单因素-阻尼轴', durationMs: 900, dampingRatio: 2, reboundPercent: 5 },
  { label: 'Z15', type: '单因素-阻尼轴', durationMs: 900, dampingRatio: 2.5, reboundPercent: 5 },
  { label: 'Z16', type: '交互验证', durationMs: 300, dampingRatio: 1.5, reboundPercent: 0 },
  { label: 'Z17', type: '交互验证', durationMs: 300, dampingRatio: 1.5, reboundPercent: 15 },
  { label: 'Z18', type: '交互验证', durationMs: 1500, dampingRatio: 1.5, reboundPercent: 0 },
  { label: 'Z19', type: '交互验证', durationMs: 1500, dampingRatio: 1.5, reboundPercent: 15 },
  { label: 'Z20', type: '交互验证', durationMs: 300, dampingRatio: 0.5, reboundPercent: 5 },
  { label: 'Z21', type: '交互验证', durationMs: 300, dampingRatio: 2.5, reboundPercent: 5 },
  { label: 'Z22', type: '交互验证', durationMs: 1500, dampingRatio: 0.5, reboundPercent: 5 },
  { label: 'Z23', type: '交互验证', durationMs: 1500, dampingRatio: 2.5, reboundPercent: 5 },
  { label: 'Z24', type: '交互验证', durationMs: 900, dampingRatio: 0.5, reboundPercent: 0 },
  { label: 'Z25', type: '交互验证', durationMs: 900, dampingRatio: 0.5, reboundPercent: 15 },
  { label: 'Z26', type: '交互验证', durationMs: 900, dampingRatio: 2.5, reboundPercent: 0 },
  { label: 'Z27', type: '交互验证', durationMs: 900, dampingRatio: 2.5, reboundPercent: 15 },
  { label: 'Z28', type: '极端点-低低低', durationMs: 300, dampingRatio: 0.5, reboundPercent: 0 },
  { label: 'Z29', type: '极端点-高高高', durationMs: 1500, dampingRatio: 2.5, reboundPercent: 15 },
  { label: 'Z30', type: '中心点重复', durationMs: 900, dampingRatio: 1.5, reboundPercent: 5 }
];

export const UNLOCK_DESKTOP_PRESETS: UnlockDesktopPresetItem[] = [
  { label: 'Z01', type: '单因素-时间轴', durationMs: 300, dampingRatio: 0.8, reboundPercent: 5 },
  { label: 'Z02', type: '单因素-时间轴', durationMs: 450, dampingRatio: 0.8, reboundPercent: 5 },
  { label: 'Z03', type: '单因素-时间轴', durationMs: 600, dampingRatio: 0.8, reboundPercent: 5 },
  { label: 'Z04', type: '单因素-时间轴', durationMs: 750, dampingRatio: 0.8, reboundPercent: 5 },
  { label: 'Z05', type: '单因素-时间轴', durationMs: 900, dampingRatio: 0.8, reboundPercent: 5 },
  { label: 'Z06', type: '单因素-回弹轴', durationMs: 600, dampingRatio: 0.8, reboundPercent: 0 },
  { label: 'Z07', type: '单因素-回弹轴', durationMs: 600, dampingRatio: 0.8, reboundPercent: 3 },
  { label: 'Z08', type: '单因素-回弹轴', durationMs: 600, dampingRatio: 0.8, reboundPercent: 5 },
  { label: 'Z09', type: '单因素-回弹轴', durationMs: 600, dampingRatio: 0.8, reboundPercent: 10 },
  { label: 'Z10', type: '单因素-回弹轴', durationMs: 600, dampingRatio: 0.8, reboundPercent: 15 },
  { label: 'Z11', type: '单因素-阻尼轴', durationMs: 600, dampingRatio: 0.3, reboundPercent: 5 },
  { label: 'Z12', type: '单因素-阻尼轴', durationMs: 600, dampingRatio: 0.5, reboundPercent: 5 },
  { label: 'Z13', type: '单因素-阻尼轴', durationMs: 600, dampingRatio: 0.8, reboundPercent: 5 },
  { label: 'Z14', type: '单因素-阻尼轴', durationMs: 600, dampingRatio: 1.1, reboundPercent: 5 },
  { label: 'Z15', type: '单因素-阻尼轴', durationMs: 600, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z16', type: '交互验证', durationMs: 300, dampingRatio: 0.8, reboundPercent: 0 },
  { label: 'Z17', type: '交互验证', durationMs: 300, dampingRatio: 0.8, reboundPercent: 15 },
  { label: 'Z18', type: '交互验证', durationMs: 900, dampingRatio: 0.8, reboundPercent: 0 },
  { label: 'Z19', type: '交互验证', durationMs: 900, dampingRatio: 0.8, reboundPercent: 15 },
  { label: 'Z20', type: '交互验证', durationMs: 300, dampingRatio: 0.3, reboundPercent: 5 },
  { label: 'Z21', type: '交互验证', durationMs: 300, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z22', type: '交互验证', durationMs: 900, dampingRatio: 0.3, reboundPercent: 5 },
  { label: 'Z23', type: '交互验证', durationMs: 900, dampingRatio: 1.5, reboundPercent: 5 },
  { label: 'Z24', type: '交互验证', durationMs: 600, dampingRatio: 0.3, reboundPercent: 0 },
  { label: 'Z25', type: '交互验证', durationMs: 600, dampingRatio: 0.3, reboundPercent: 15 },
  { label: 'Z26', type: '交互验证', durationMs: 600, dampingRatio: 1.5, reboundPercent: 0 },
  { label: 'Z27', type: '交互验证', durationMs: 600, dampingRatio: 1.5, reboundPercent: 15 },
  { label: 'Z28', type: '极端点-低低低', durationMs: 300, dampingRatio: 0.3, reboundPercent: 0 },
  { label: 'Z29', type: '极端点-高高高', durationMs: 900, dampingRatio: 1.5, reboundPercent: 15 },
  { label: 'Z30', type: '中心点重复', durationMs: 600, dampingRatio: 0.8, reboundPercent: 5 }
];

export const INDEX_PRESETS: IndexPresetItem[] = [
  { label: 'Z01', type: '单因素-时长轴', durationMs: 75, reboundPercent: 10 },
  { label: 'Z02', type: '单因素-时长轴', durationMs: 150, reboundPercent: 10 },
  { label: 'Z03', type: '单因素-时长轴', durationMs: 220, reboundPercent: 10 },
  { label: 'Z04', type: '单因素-时长轴', durationMs: 280, reboundPercent: 10 },
  { label: 'Z05', type: '单因素-时长轴', durationMs: 350, reboundPercent: 10 },
  { label: 'Z06', type: '单因素-回弹轴', durationMs: 220, reboundPercent: 0 },
  { label: 'Z07', type: '单因素-回弹轴', durationMs: 220, reboundPercent: 5 },
  { label: 'Z08', type: '单因素-回弹轴', durationMs: 220, reboundPercent: 15 },
  { label: 'Z09', type: '单因素-回弹轴', durationMs: 220, reboundPercent: 20 },
  { label: 'Z10', type: '交互验证-低低', durationMs: 75, reboundPercent: 0 },
  { label: 'Z11', type: '交互验证-低高', durationMs: 75, reboundPercent: 20 },
  { label: 'Z12', type: '交互验证-高低', durationMs: 350, reboundPercent: 0 },
  { label: 'Z13', type: '交互验证-高高', durationMs: 350, reboundPercent: 20 },
  { label: 'Z14', type: '补充-中低', durationMs: 150, reboundPercent: 5 },
  { label: 'Z15', type: '补充-中高', durationMs: 280, reboundPercent: 15 },
  { label: 'Z16', type: '中心点重复', durationMs: 220, reboundPercent: 10 }
];
