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
      ['S标', '基准参数', '900ms', '5%', '1', 900, 5, 1],
      ['A标', '参数1', '750ms', '0.8%', '0.7', 750, 0.8, 0.7],
      ['A标', '参数2', '1180ms', '7%', '0.75', 1180, 7, 0.75],
      ['B标', '参数1', '500ms', '8%', '1.5', 500, 8, 1.5],
      ['B标', '参数2', '1500ms', '10%', '0.3', 1500, 10, 0.3],
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
      ['S标', '基准参数', '默认', '17.65%', '1.08', 0, 17.65, 1.08],
      ['A标', '参数1', '默认', '9%', '0.9', 0, 9, 0.9],
      ['A标', '参数2', '默认', '12%', '1.2', 0, 12, 1.2],
      ['B标', '参数1', '默认', '14.9%', '0.6', 0, 14.9, 0.6],
      ['B标', '参数2', '默认', '14.9%', '1.5', 0, 14.9, 1.5],
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
      ['S标', '基准参数', '1000ms', '0%', '0.5', 1000, 0, 0.5],
      ['A标', '参数1', '650ms', '2%', '0.8', 650, 2, 0.8],
      ['A标', '参数2', '1450ms', '1%', '1.2', 1450, 1, 1.2],
      ['B标', '参数1', '400ms', '3%', '0.8', 400, 3, 0.8],
      ['B标', '参数2', '550ms', '6%', '0.8', 550, 6, 0.8],
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
      ['S标', '基准参数', '300ms', '13.42%', '0.3', 300, 13.42, 0.3],
      ['A标', '参数1', '630ms', '4.5%', '0.6', 630, 4.5, 0.6],
      ['A标', '参数2', '750ms', '6.5%', '0.9', 750, 6.5, 0.9],
      ['B标', '参数1', '800ms', '3.5%', '0.9', 800, 3.5, 0.9],
      ['B标', '参数2', '890ms', '4.5%', '1', 890, 4.5, 1],
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
      ['S标', '基准参数', '300ms', '10%', '不适用', 300, 10, 0],
      ['A标', '参数1', '250ms', '10.2%', '不适用', 250, 10.2, 0],
      ['A标', '参数2', '380ms', '15%', '不适用', 380, 15, 0],
      ['B标', '参数1', '200ms', '15%', '不适用', 200, 15, 0],
      ['B标', '参数2', '400ms', '20%', '不适用', 400, 20, 0],
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
