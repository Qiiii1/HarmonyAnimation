import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const presetDataPath = path.resolve('entry/src/main/ets/pages/config/ExperimentPresetData.ets');
const allConfigPath = path.resolve('entry/src/main/ets/pages/config/AllConfigPage.ets');

const sceneExpectations = [
  {
    constant: 'TASKBAR_UP_SAB_PARAMETERS',
    page: 'TaskbarUpConfigPage.ets',
    importName: 'TASKBAR_UP_SAB_PARAMETERS',
    values: [
      ['S标', '基准参数', '1015ms', '4%', '1', 1015, 4, 1],
      ['A标', '参数1', '980ms', '5%', '0.8', 980, 5, 0.8],
      ['A标', '参数2', '1050ms', '3%', '1.2', 1050, 3, 1.2],
      ['B标', '参数1', '1600ms', '8%', '1.5', 1600, 8, 1.5],
      ['B标', '参数2', '1800ms', '10%', '1.5', 1800, 10, 1.5],
    ],
    assignments: [
      'this.leadCardReleaseDurationMs = parameter.durationMs;',
      'this.upSwipeDampingRatio = parameter.dampingRatio;',
      'this.cardBounceOvershootX = parameter.reboundPercent;',
    ],
  },
  {
    constant: 'VOLUME_SAB_PARAMETERS',
    page: 'VolumeConfigPage.ets',
    importName: 'VOLUME_SAB_PARAMETERS',
    values: [
      ['S标', '基准参数', '默认', '14.9%', '0.9', 0, 14.9, 0.9],
      ['A标', '参数1', '默认', '14.9%', '0.7', 0, 14.9, 0.7],
      ['A标', '参数2', '默认', '14.9%', '1.2', 0, 14.9, 1.2],
      ['B标', '参数1', '默认', '14.9%', '0.5', 0, 14.9, 0.5],
      ['B标', '参数2', '默认', '14.9%', '0.4', 0, 14.9, 0.4],
    ],
    assignments: [
      'this.interactionDragDampingRatio = parameter.dampingRatio;',
      'this.interactionWidthReboundPercent = parameter.reboundPercent;',
      'this.buttonWidthPulsePercent = parameter.reboundPercent;',
    ],
  },
  {
    constant: 'TASKBAR_DOWN_SAB_PARAMETERS',
    page: 'TaskbarDownConfigPage.ets',
    importName: 'TASKBAR_DOWN_SAB_PARAMETERS',
    values: [
      ['S标', '基准参数', '934ms', '0%', '1.5', 934, 0, 1.5],
      ['A标', '参数1', '818ms', '5%', '0.7', 818, 5, 0.7],
      ['A标', '参数2', '1071ms', '1%', '1.5', 1071, 1, 1.5],
      ['B标', '参数1', '500ms', '12%', '0.8', 500, 12, 0.8],
      ['B标', '参数2', '700ms', '15%', '0.8', 700, 15, 0.8],
    ],
    assignments: [
      'this.moduleEnterTotalDurationMs = parameter.durationMs;',
      'this.openDragDampingRatio = parameter.dampingRatio;',
      'this.moduleReboundPercent = parameter.reboundPercent;',
    ],
  },
  {
    constant: 'UNLOCK_DESKTOP_SAB_PARAMETERS',
    page: 'UnlockDesktopConfigPage.ets',
    importName: 'UNLOCK_DESKTOP_SAB_PARAMETERS',
    values: [
      ['S标', '基准参数', '587ms', '8.6%', '0.5', 587, 8.6, 0.5],
      ['A标', '参数1', '350ms', '3.5%', '0.3', 350, 3.5, 0.3],
      ['A标', '参数2', '750ms', '12%', '1.2', 750, 12, 1.2],
      ['B标', '参数1', '900ms', '15%', '1.4', 900, 15, 1.4],
      ['B标', '参数2', '1100ms', '16%', '1.6', 1100, 16, 1.6],
    ],
    assignments: [
      'this.unlockToHomeDurationMs = parameter.durationMs;',
      'this.unlockDragFollowFactor = parameter.dampingRatio;',
      'this.unlockIconReboundPercent = parameter.reboundPercent;',
    ],
  },
  {
    constant: 'INDEX_SAB_PARAMETERS',
    page: 'IndexConfigPage.ets',
    importName: 'INDEX_SAB_PARAMETERS',
    values: [
      ['S标', '基准参数', '246ms', '13.8%', '不适用', 246, 13.8, 0],
      ['A标', '参数1', '195ms', '12%', '不适用', 195, 12, 0],
      ['A标', '参数2', '300ms', '15%', '不适用', 300, 15, 0],
      ['B标', '参数1', '100ms', '18%', '不适用', 100, 18, 0],
      ['B标', '参数2', '80ms', '20%', '不适用', 80, 20, 0],
    ],
    assignments: [
      'this.openAnimationDurationMs = parameter.durationMs;',
      'this.iconReboundPercent = parameter.reboundPercent;',
    ],
  },
];

const presetSource = fs.readFileSync(presetDataPath, 'utf8');
const allConfigSource = fs.readFileSync(allConfigPath, 'utf8');

assert.match(presetSource, /export interface SabParameterItem/, 'SAB parameter interface should be exported');
assert.match(presetSource, /formatSabParameterText/, 'SAB parameter formatter should be exported');

for (const scene of sceneExpectations) {
  assert.ok(
    presetSource.includes(`export const ${scene.constant}: SabParameterItem[] = [`),
    `${scene.constant} should be exported from preset data`
  );

  for (const [mark, name, duration, rebound, damping, durationMs, reboundPercent, dampingRatio] of scene.values) {
    assert.ok(
      presetSource.includes(
        `{ mark: '${mark}', name: '${name}', duration: '${duration}', rebound: '${rebound}', damping: '${damping}', durationMs: ${durationMs}, reboundPercent: ${reboundPercent}, dampingRatio: ${dampingRatio} }`
      ),
      `${scene.constant} should include ${mark} ${name} from the spreadsheet`
    );
  }

  const pagePath = path.resolve('entry/src/main/ets/pages/config', scene.page);
  const pageSource = fs.readFileSync(pagePath, 'utf8');
  assert.ok(pageSource.includes(scene.importName), `${scene.page} should import ${scene.importName}`);
  assert.ok(pageSource.includes('private readonly sabParameters: SabParameterItem[]'), `${scene.page} should keep SAB rows`);
  assert.ok(pageSource.includes("Text('新增参数')"), `${scene.page} should label the new parameter column`);
  assert.ok(pageSource.includes("Text('S/A/B标')"), `${scene.page} should identify the SAB marker column`);
  assert.ok(pageSource.includes('this.buildSabParameterColumn()'), `${scene.page} should render the SAB column`);
  assert.ok(pageSource.includes('@State selectedSabParameterKey'), `${scene.page} should track the selected SAB row`);
  assert.ok(pageSource.includes('private applySabParameter(parameter: SabParameterItem): void'), `${scene.page} should apply SAB rows`);
  assert.ok(pageSource.includes('this.selectedPresetLabel = \'\';'), `${scene.page} should clear Z preset selection when SAB is selected`);
  assert.ok(pageSource.includes('this.applySabParameter(parameter);'), `${scene.page} should apply SAB rows from row click/tap`);
  assert.ok(pageSource.includes('Scroll() {'), `${scene.page} should wrap the parameter panel in a Scroll`);
  assert.ok(pageSource.includes('.scrollable(ScrollDirection.Vertical)'), `${scene.page} should allow vertical scrolling`);
  assert.ok(pageSource.includes('.scrollBar(BarState.Off)'), `${scene.page} should keep the current hidden scrollbar style`);
  assert.ok(!pageSource.includes('.justifyContent(FlexAlign.Center)'), `${scene.page} should not center a tall non-scrollable panel`);

  for (const assignment of scene.assignments) {
    assert.ok(pageSource.includes(assignment), `${scene.page} should update preview storage via: ${assignment}`);
  }
}

for (const scene of sceneExpectations) {
  assert.ok(allConfigSource.includes(scene.importName), `AllConfigPage should import ${scene.importName}`);
}
assert.ok(allConfigSource.includes('sabParameters: SabParameterItem[]'), 'AllConfigPage should render SAB parameter rows');
assert.ok(allConfigSource.includes("Text('新增参数')"), 'AllConfigPage should label the new parameter column');
assert.ok(allConfigSource.includes("Text('S/A/B标')"), 'AllConfigPage should identify the SAB marker column');
assert.ok(allConfigSource.includes('@State selectedIndexSabParameterKey'), 'AllConfigPage should track selected index SAB row');
assert.ok(allConfigSource.includes('@State selectedVolumeSabParameterKey'), 'AllConfigPage should track selected volume SAB row');
assert.ok(allConfigSource.includes('@State selectedTaskbarUpSabParameterKey'), 'AllConfigPage should track selected recents SAB row');
assert.ok(allConfigSource.includes('@State selectedUnlockSabParameterKey'), 'AllConfigPage should track selected unlock SAB row');
assert.ok(allConfigSource.includes('@State selectedTaskbarDownSabParameterKey'), 'AllConfigPage should track selected control center SAB row');
assert.ok(allConfigSource.includes('this.applySabParameter(sceneKey, parameter);'), 'AllConfigPage SAB rows should be clickable');
assert.ok(allConfigSource.includes("sceneKey === 'index'"), 'AllConfigPage should dispatch index SAB rows');
assert.ok(allConfigSource.includes("sceneKey === 'volume'"), 'AllConfigPage should dispatch volume SAB rows');
assert.ok(allConfigSource.includes("sceneKey === 'taskbarUp'"), 'AllConfigPage should dispatch recents SAB rows');
assert.ok(allConfigSource.includes("sceneKey === 'unlock'"), 'AllConfigPage should dispatch unlock SAB rows');
assert.ok(allConfigSource.includes("sceneKey === 'taskbarDown'"), 'AllConfigPage should dispatch control center SAB rows');
