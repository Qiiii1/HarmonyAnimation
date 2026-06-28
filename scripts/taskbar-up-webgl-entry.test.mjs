import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const configPagePath = path.resolve('entry/src/main/ets/pages/config/TaskbarUpConfigPage.ets');
const webglPagePath = path.resolve('entry/src/main/ets/pages/TaskbarUpWebGLPage.ets');
const mainPagesPath = path.resolve('entry/src/main/resources/base/profile/main_pages.json');
const rawfileHtmlPath = path.resolve('entry/src/main/resources/rawfile/taskbar_up_webgl.html');

const configSource = fs.readFileSync(configPagePath, 'utf8');
const mainPages = JSON.parse(fs.readFileSync(mainPagesPath, 'utf8'));

assert.ok(
  mainPages.src.includes('pages/TaskbarUpWebGLPage'),
  'main_pages should register the WebGL taskbar-up page'
);

assert.ok(
  configSource.includes('private openWebGLPreviewPage(): void'),
  'TaskbarUpConfigPage should expose a WebGL preview route method'
);
assert.ok(
  configSource.includes("url: 'pages/TaskbarUpWebGLPage'"),
  'TaskbarUpConfigPage should route to the WebGL preview page'
);
assert.ok(
  configSource.includes('this.buildWebGLPreviewButton()'),
  'TaskbarUpConfigPage should render the WebGL entry button'
);
assert.ok(
  configSource.includes("Text('WebGL 预览')"),
  'TaskbarUpConfigPage should label the new WebGL entry'
);

assert.ok(fs.existsSync(webglPagePath), 'TaskbarUpWebGLPage should exist');
const webglPageSource = fs.readFileSync(webglPagePath, 'utf8');
assert.ok(webglPageSource.includes("import webview from '@ohos.web.webview';"), 'WebGL page should use the Harmony Web controller');
assert.ok(webglPageSource.includes('struct TaskbarUpWebGLPage'), 'WebGL page should define a routable component');
assert.ok(webglPageSource.includes("'resource://rawfile/taskbar_up_webgl.html'"), 'WebGL page should load the local rawfile animation from the rawfile root like the reference');
assert.ok(webglPageSource.includes('Web({'), 'WebGL page should render a Web component');
assert.ok(
  webglPageSource.includes('.expandSafeArea(\n          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],\n          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]\n        )'),
  'WebGL page should expand the WebView itself through system and cutout safe areas'
);
assert.ok(!webglPageSource.includes("import util from '@ohos.util';"), 'WebGL page should not base64 encode rawfile assets natively by default');
assert.ok(!webglPageSource.includes('getRawFileContent'), 'WebGL page should rely on same-directory rawfile image paths instead of native PNG byte transfer');
assert.ok(!webglPageSource.includes('Base64Helper'), 'WebGL page should avoid native base64 asset injection that can stall texture initialization');
assert.ok(!webglPageSource.includes('TASKBAR_UP_ASSET_CHUNK_SIZE'), 'WebGL page should not stream rawfile images into WebView on page load');
assert.ok(!webglPageSource.includes('sendRawPngAsset'), 'WebGL page should not push PNG chunks into WebView by default');
assert.ok(!webglPageSource.includes('this.syncAssetsToWeb();'), 'WebGL page should not auto-inject base64 assets on page end');
assert.ok(!webglPageSource.includes('JSON.stringify(payload)'), 'WebGL page should avoid a single huge runJavaScript payload for all images');
assert.ok(
  !webglPageSource.includes('this.buildNativeMaterialPreview()'),
  'WebGL page should not mount an ArkUI-native overlay above the canvas because it prevents the reference WebGL interaction from receiving gestures'
);
assert.ok(
  !webglPageSource.includes('PanGesture({ fingers: 1, direction: PanDirection.All'),
  'WebGL page should not replace the reference pointer state machine with an ArkUI PanGesture'
);
assert.ok(!webglPageSource.includes('private buildTopBar'), 'WebGL page should not show a preview top bar over the native desktop animation');
assert.ok(!webglPageSource.includes("Text('返回')"), 'WebGL page should not overlay a visible back button on the native desktop preview');
assert.ok(!webglPageSource.includes("Text('WebGL 预览')"), 'WebGL page should not overlay a visible WebGL preview title on the native desktop preview');
assert.ok(!webglPageSource.includes('this.buildTopBar()'), 'WebGL page should render the WebView without additional ArkUI information chrome');

assert.ok(fs.existsSync(rawfileHtmlPath), 'WebGL rawfile HTML should exist');
const rawfileHtml = fs.readFileSync(rawfileHtmlPath, 'utf8');
const rawTextureMarker = 'window.TASKBAR_UP_WEBGL_RAW_TEXTURES = ';
const rawTextureStart = rawfileHtml.indexOf(rawTextureMarker) + rawTextureMarker.length;
const rawTextureEnd = rawfileHtml.indexOf(';\n</script>', rawTextureStart);
assert.ok(rawTextureStart >= rawTextureMarker.length && rawTextureEnd > rawTextureStart, 'WebGL rawfile should expose parseable inline raw texture data');
const rawTextures = JSON.parse(rawfileHtml.slice(rawTextureStart, rawTextureEnd));
const scheduleApplyMatch = rawfileHtml.match(/function scheduleApplyTaskbarUpAssetChunks\(\) \{([\s\S]*?)\n        \}/);
const scheduleApplyBody = scheduleApplyMatch ? scheduleApplyMatch[1] : '';
const loadTextureMatch = rawfileHtml.match(/function loadTexture\(entry, path, sourceImage, batchId\) \{([\s\S]*?)\n        \}/);
const loadTextureBody = loadTextureMatch ? loadTextureMatch[1] : '';
assert.ok(rawfileHtml.includes('<canvas id="glCanvas"'), 'WebGL rawfile should render through a canvas');
assert.ok(rawfileHtml.includes('id="fallbackStage"'), 'WebGL rawfile should keep a visible DOM fallback behind the canvas');
assert.ok(rawfileHtml.includes('id="webglStatus"'), 'WebGL rawfile should expose a status label instead of failing as a black screen');
assert.ok(rawfileHtml.includes('body.webgl-failed #webglStatus'), 'WebGL status should only become visible for failure diagnostics');
assert.ok(rawfileHtml.includes('display: none;') && rawfileHtml.includes('display: block;'), 'WebGL status should be hidden during the native desktop preview');
assert.ok(!rawfileHtml.includes('id="grabber"'), 'WebGL rawfile should not draw an extra gesture bar over the native desktop preview');
assert.ok(rawfileHtml.includes('getContext("webgl"'), 'WebGL rawfile should initialize WebGL locally');
assert.ok(rawfileHtml.includes('setWebGLStatus'), 'WebGL rawfile should report WebGL initialization/rendering state');
assert.ok(rawfileHtml.includes('hideWebGLCanvas'), 'WebGL rawfile should hide the canvas if WebGL cannot render');
assert.ok(rawfileHtml.includes('describeWebGLError'), 'WebGL rawfile should include the underlying error detail in its status');
assert.ok(rawfileHtml.includes('image.onerror'), 'WebGL rawfile should handle local asset loading failures visibly');
assert.ok(!rawfileHtml.includes('src="./assets/asset-data.js"'), 'WebGL rawfile should not depend on a secondary script load for texture data');
assert.ok(rawfileHtml.includes('window.TASKBAR_UP_WEBGL_RAW_TEXTURES'), 'WebGL rawfile should expose decoded raw WebGL texture payloads');
assert.ok(rawfileHtml.includes('window.setTaskbarUpAssets'), 'WebGL rawfile should accept native-injected asset data');
assert.ok(rawfileHtml.includes('window.setTaskbarUpAssetError'), 'WebGL rawfile should expose native asset injection errors');
assert.ok(rawfileHtml.includes('window.beginTaskbarUpAsset'), 'WebGL rawfile should receive native asset chunks');
assert.ok(rawfileHtml.includes('window.appendTaskbarUpAsset'), 'WebGL rawfile should append native asset chunks');
assert.ok(rawfileHtml.includes('window.applyTaskbarUpAssetChunks'), 'WebGL rawfile should assemble native asset chunks');
assert.ok(rawfileHtml.includes('TASKBAR_UP_REQUIRED_ASSET_IDS'), 'WebGL rawfile should know the complete native asset set');
assert.ok(rawfileHtml.includes('areTaskbarUpAssetChunksComplete'), 'WebGL rawfile should detect when all native asset chunks have arrived');
assert.ok(rawfileHtml.includes('scheduleApplyTaskbarUpAssetChunks'), 'WebGL rawfile should auto-apply assets after the final chunk arrives');
assert.ok(
  /appendTaskbarUpAsset[\s\S]*scheduleApplyTaskbarUpAssetChunks\(\)/.test(rawfileHtml),
  'WebGL rawfile should not get stuck waiting for a native apply call after card3 reaches 99%'
);
assert.ok(
  scheduleApplyBody.includes('applyTaskbarUpAssetChunks();'),
  'WebGL rawfile should synchronously apply assets after the final chunk instead of waiting at receive 100%'
);
assert.ok(
  !scheduleApplyBody.includes('setTimeout'),
  'WebGL rawfile should not depend on a timer to leave the receive 100% state'
);
assert.ok(rawfileHtml.includes('nativeAssetTransferActive'), 'WebGL rawfile should not show the old startup timeout while native asset chunks are still arriving');
assert.ok(rawfileHtml.includes('WebGL 等待素材处理'), 'WebGL rawfile should report that asset transfer/decode is still in progress instead of claiming a load timeout');
assert.ok(
  rawfileHtml.includes('usesInlineTextureAssets'),
  'WebGL rawfile should detect when the bundled inline textures make native asset transfer unnecessary'
);
assert.ok(
  rawfileHtml.includes('if (usesInlineTextureAssets()) {\n            nativeAssetTransferActive = false;\n            return;\n          }'),
  'WebGL rawfile should ignore stale native asset transfer calls when inline textures are available'
);
assert.ok(rawfileHtml.includes('let assetPaths'), 'WebGL rawfile should allow native asset paths to replace fallback rawfile paths');
assert.ok(rawfileHtml.includes('loadTexture('), 'WebGL rawfile should reload existing textures when injected assets arrive');
assert.ok(rawfileHtml.includes('document.body.classList.remove("webgl-failed")'), 'WebGL rawfile should recover the canvas after injected assets arrive');
assert.ok(rawfileHtml.includes('isInjectedAsset'), 'WebGL rawfile should only hard-fail image loading after injected data fails');
assert.ok(
  rawfileHtml.includes('function uploadRawTexture'),
  'WebGL rawfile should upload bundled RGBA texture bytes directly without browser image decoding'
);
assert.ok(
  rawfileHtml.includes('gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, raw.width, raw.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, rgbaBytes)'),
  'WebGL rawfile should pass raw texture dimensions and RGBA bytes to texImage2D'
);
assert.ok(
  rawfileHtml.includes('let bundledInlineAssetsActive = areRawTextureAssetSet(initialAssetPaths);'),
  'WebGL rawfile should remember that bundled textures are already decoded raw data'
);
assert.ok(
  rawfileHtml.includes('background2: createTexture(initialAssetPaths.background2, fallbackBackground2, initialTextureBatchId)') &&
    rawfileHtml.includes('background3: createTexture(initialAssetPaths.background3, fallbackBackground3, initialTextureBatchId)') &&
    rawfileHtml.includes('background2Soft: createTexture(initialAssetPaths.background2Soft, null, initialTextureBatchId)') &&
    rawfileHtml.includes('background3Soft: createTexture(initialAssetPaths.background3Soft, null, initialTextureBatchId)'),
  'WebGL rawfile should upload bundled sharp and soft background textures during initial texture creation'
);
assert.ok(rawfileHtml.includes('WebGL 素材装配中'), 'WebGL rawfile should move past the 100% receive state before assembling injected asset URLs');
assert.ok(rawfileHtml.includes('pendingTaskbarUpAssets'), 'WebGL rawfile should keep injected assets if they arrive before textures initialize');
assert.ok(rawfileHtml.includes('applyTaskbarUpAssetPaths'), 'WebGL rawfile should share one path-application flow for immediate and pending assets');
assert.ok(rawfileHtml.includes('flushPendingTaskbarUpAssets'), 'WebGL rawfile should flush pending injected assets after texture creation');
assert.ok(
  !rawfileHtml.includes('if (!textures) {\n            return;\n          }'),
  'WebGL rawfile should not leave the status stuck at asset assembly when textures are not ready yet'
);
assert.ok(!rawfileHtml.includes('atob(value.slice'), 'WebGL rawfile should not use the old unguarded base64 decode expression');
assert.ok(rawfileHtml.includes('recordTextureLoaded'), 'WebGL rawfile should report success only after textures decode and upload');
assert.ok(!rawfileHtml.includes('setWebGLStatus("WebGL 素材已注入")'), 'WebGL rawfile should not claim assets are ready before image decode');
assert.ok(
  rawfileHtml.includes('"rgba":"'),
  'WebGL rawfile should inline RGBA texture bytes instead of an image URL'
);
assert.ok(
  (rawfileHtml.match(/"rgba":"/g) || []).length >= 12,
  'WebGL rawfile should inline sharp backgrounds, soft backgrounds, four cards, and four app icon raw texture payloads'
);
assert.ok(
  !rawfileHtml.includes('<img id="fallbackBackground2" src="resource://rawfile/taskbar_up_webgl_background2.png"') &&
    !rawfileHtml.includes('<img id="fallbackBackground3" src="resource://rawfile/taskbar_up_webgl_background3.png"'),
  'WebGL fallback background images should not request rawfile during HTML parsing'
);
assert.ok(
  !rawfileHtml.includes('fallbackBackground2.src = assetPaths.background2;') &&
    !rawfileHtml.includes('fallbackBackground3.src = assetPaths.background3;'),
  'WebGL fallback background images should not assign src before loadTexture installs onload handlers'
);
assert.ok(
  loadTextureBody.indexOf('image.onload = upload;') >= 0 &&
    loadTextureBody.indexOf('image.src = path;') >= 0 &&
    loadTextureBody.indexOf('image.onload = upload;') < loadTextureBody.indexOf('image.src = path;'),
  'WebGL rawfile should install image load handlers before assigning src'
);
assert.ok(!rawfileHtml.includes('<img id="fallbackBackground2" src="taskbar_up_webgl_background2.png"'), 'WebGL fallback background2 image should not rely on a relative rawfile URL that can hang in Harmony WebView');
assert.ok(!rawfileHtml.includes('<img id="fallbackBackground3" src="taskbar_up_webgl_background3.png"'), 'WebGL fallback background3 image should not rely on a relative rawfile URL that can hang in Harmony WebView');
assert.ok(!rawfileHtml.includes('assets/preview/'), 'WebGL rawfile should not rely on nested preview asset paths');
assert.ok(
  rawfileHtml.length < 11000000,
  'WebGL rawfile should remain bounded even with the inline raw RGBA textures'
);
assert.ok(rawfileHtml.includes('markWebGLStarted'), 'WebGL rawfile should expose a guarded ready transition');
assert.ok(
  rawfileHtml.includes('if (!textures.background2.ready || !textures.background3.ready || !textures.background2Soft.ready || !textures.background3Soft.ready)'),
  'WebGL rawfile should not show an empty canvas before sharp and soft background textures are ready'
);
assert.ok(rawfileHtml.includes('initialTextureBatchId'), 'WebGL rawfile should track initial rawfile texture loading');
assert.ok(rawfileHtml.includes('background2: createTexture(initialAssetPaths.background2, fallbackBackground2, initialTextureBatchId)'), 'WebGL background2 texture should use the bundled raw texture during initial load');
assert.ok(rawfileHtml.includes('background3: createTexture(initialAssetPaths.background3, fallbackBackground3, initialTextureBatchId)'), 'WebGL background3 texture should use the bundled raw texture during initial load');
assert.ok(rawfileHtml.includes('background2Soft: createTexture(initialAssetPaths.background2Soft, null, initialTextureBatchId)'), 'WebGL background2 soft texture should use the bundled low-frequency raw texture during initial load');
assert.ok(rawfileHtml.includes('background3Soft: createTexture(initialAssetPaths.background3Soft, null, initialTextureBatchId)'), 'WebGL background3 soft texture should use the bundled low-frequency raw texture during initial load');
assert.ok(rawfileHtml.includes('素材加载超时，已切换到素材预览'), 'WebGL rawfile should fall back when textures never become ready');
assert.ok(rawfileHtml.includes('const ASSET_LOAD_TIMEOUT_MS = 12000'), 'WebGL rawfile should leave enough time for native asset injection and image decode before falling back');
assert.ok(rawfileHtml.includes('setTimeout(() => {'), 'WebGL rawfile should have a timeout fallback if rendering never starts');
assert.ok(
  !rawfileHtml.includes('nativeAssetTransferActive || textureLoadState.expected > 0'),
  'WebGL rawfile should not keep waiting forever just because a texture batch was started'
);
assert.ok(rawfileHtml.includes('uMaskSize'), 'WebGL shader should use a fragment-only mask uniform instead of reusing uSize');
assert.equal((rawfileHtml.match(/uniform vec2 uSize;/g) || []).length, 1, 'WebGL shader should avoid cross-stage uSize precision conflicts');
assert.equal((rawfileHtml.match(/uniform float uFly;/g) || []).length, 0, 'WebGL shader should avoid cross-stage uFly precision conflicts');
assert.ok(rawfileHtml.includes('uFlyShift') && rawfileHtml.includes('uFlyFade'), 'WebGL shader should use separate fly uniforms for vertex shift and fragment fade');
assert.ok(!rawfileHtml.includes('float fold = uBend * edge * verticalFalloff;'), 'Horizontal swipe should not create a hard center fold across the card');
assert.ok(!rawfileHtml.includes('vEdgeLight = clamp(0.5 + fold * 2.4'), 'Horizontal swipe should not apply split-card side lighting');
assert.ok(!rawfileHtml.includes('mix(0.86, 1.12, vEdgeLight)'), 'Horizontal swipe lighting should stay subtle instead of making one half abruptly bright and the other dim');
assert.ok(rawfileHtml.includes('float bendAbs = clamp(abs(uBend), 0.0, 1.0);'), 'WebGL shader should base horizontal deformation on a bounded bend magnitude');
assert.ok(rawfileHtml.includes('float sideCurve ='), 'WebGL shader should use a smooth side curve for horizontal card deformation');
assert.ok(rawfileHtml.includes('mix(0.96, 1.04, vEdgeLight)'), 'WebGL shader should keep horizontal swipe lighting within a narrow range');
assert.ok(rawfileHtml.includes('const meshBend ='), 'WebGL layout should send a softened bend value to the shader during horizontal swipe');
assert.ok(rawfileHtml.includes('uniform float uTiltY;'), 'WebGL shader should expose a Y-axis tilt uniform for the reference horizontal swipe perspective');
assert.ok(rawfileHtml.includes('uniform float uDepth;'), 'WebGL shader should expose card Z depth so horizontal swipe can move the card backward like the reference');
assert.ok(rawfileHtml.includes('uniform float uPerspective;'), 'WebGL shader should project tilted cards with a CSS-like perspective');
assert.ok(
  rawfileHtml.includes('float x3 = twistedX * cosY + twistZ * sinY;') &&
    rawfileHtml.includes('float z3 = uDepth + twistZ * cosY + twistedX * sinY;'),
  'WebGL shader should rotate card vertices around the Y axis instead of only warping the 2D quad'
);
assert.ok(rawfileHtml.includes('float perspectiveScale = uPerspective / max(120.0, uPerspective - z3);'), 'WebGL shader should apply perspective scaling from card depth');
assert.ok(rawfileHtml.includes('const tiltY = (-bendDir * bendDeg) * Math.PI / 180;'), 'WebGL layout should translate the reference activeRotY into shader tilt');
assert.ok(rawfileHtml.includes('const depth = -bendAmt * state.width * 0.16 * bendPower;'), 'WebGL layout should translate the reference bendZ into shader depth');
assert.ok(rawfileHtml.includes('width: 100vw;') && rawfileHtml.includes('height: 100dvh;'), 'WebGL rawfile should size the page to the full visual viewport');
assert.ok(rawfileHtml.includes('inset: 0;') && rawfileHtml.includes('width: 100%;') && rawfileHtml.includes('height: 100%;'), 'DOM fallback desktop backgrounds should fill the viewport without overscaling the layer container');
assert.ok(
  rawfileHtml.includes('background2: "resource://rawfile/taskbar_up_webgl_background2.png"') &&
    rawfileHtml.includes('background3: "resource://rawfile/taskbar_up_webgl_background3.png"'),
  'WebGL rawfile should use Background2 and Background3 as the taskbar-up desktop background layers'
);
assert.ok(
  rawfileHtml.indexOf('drawTaskbarBackgroundLayer(textures.background2') >= 0 &&
    rawfileHtml.indexOf('drawTaskbarBackgroundLayer(textures.background3') > rawfileHtml.indexOf('drawTaskbarBackgroundLayer(textures.background2'),
  'WebGL rawfile should draw Background3 after Background2 so Background3 is visually in front'
);
assert.ok(
  rawfileHtml.includes('const backgroundSoftMix = ease(p);'),
  'WebGL taskbar-up should gradually mix both background layers into a soft blurred state as recents opens'
);
assert.ok(
  rawfileHtml.includes('const background3Scale = mix(1, 0.95, p);'),
  'WebGL taskbar-up should gradually shrink the front Background3 layer as recents opens'
);
assert.ok(
  rawfileHtml.includes('"background2Soft":') &&
    rawfileHtml.includes('"background3Soft":'),
  'WebGL rawfile should inline low-frequency background textures for smooth native-like blur'
);
assert.ok(
  rawTextures.background2Soft.width <= 48 &&
    rawTextures.background3Soft.width <= 48,
  'WebGL soft background textures should be lower frequency for a stronger native-like blur'
);
assert.ok(
  rawfileHtml.includes('const backgroundSoftMix = ease(p);') &&
    rawfileHtml.includes('drawTaskbarBackgroundLayer(textures.background2, 1, 1 - backgroundSoftMix);') &&
    rawfileHtml.includes('drawTaskbarBackgroundLayer(textures.background2Soft, 1, backgroundSoftMix);') &&
    rawfileHtml.includes('drawTaskbarBackgroundLayer(textures.background3, background3Scale, 1 - backgroundSoftMix);') &&
    rawfileHtml.includes('drawTaskbarBackgroundLayer(textures.background3Soft, background3Scale, backgroundSoftMix);'),
  'WebGL taskbar-up should crossfade sharp backgrounds into soft low-frequency backgrounds while preserving layer order'
);
assert.ok(
  rawfileHtml.includes('function drawBackgroundScrim(alpha)') &&
    rawfileHtml.includes('const backgroundDimAlpha = mix(0, 0.5, ease(p));') &&
    rawfileHtml.includes('drawBackgroundScrim(backgroundDimAlpha);'),
  'WebGL taskbar-up should apply a black filter over the background in the triggered state'
);
assert.ok(
  !rawfileHtml.includes('uBlurRadius * vec2(1.0, 0.0)') &&
    !rawfileHtml.includes('uBlurRadius * vec2(-1.0, 0.0)'),
  'WebGL background blur should avoid sparse directional texture samples that create visible ghost copies'
);
assert.ok(rawfileHtml.includes('filter: saturate(1) brightness(1) blur(0px);'), 'DOM fallback desktop background should look like the native wallpaper instead of a dim debug layer');
assert.ok(rawfileHtml.includes('window.addEventListener("error"'), 'WebGL rawfile should recover from script errors visibly');
assert.ok(!/src=["']https?:\/\//.test(rawfileHtml), 'WebGL rawfile should not depend on remote scripts');
assert.ok(rawfileHtml.includes('body.webgl-failed .fallback-card'), 'WebGL rawfile should show cards immediately when the WebGL layer fails');
assert.ok(!rawfileHtml.includes('<div class="fallback-card"><img'), 'WebGL fallback cards should not show broken image icons');
assert.ok(!rawfileHtml.includes('resource://rawfile/taskbar_up_webgl/assets/'), 'WebGL nested assets should use relative rawfile paths');
assert.ok(rawfileHtml.includes('window.setTaskbarUpParams'), 'WebGL rawfile should accept native taskbar-up parameters');
assert.ok(rawfileHtml.includes('prgT: 0'), 'WebGL rawfile should keep the reference enter target state');
assert.ok(rawfileHtml.includes('idxT: cards.length - 1'), 'WebGL rawfile should keep the reference horizontal target index');
assert.ok(rawfileHtml.includes('bend: 0'), 'WebGL rawfile should keep the reference bend state');
assert.ok(rawfileHtml.includes('dragDX: 0') && rawfileHtml.includes('dragDY: 0'), 'WebGL rawfile should keep reference drag deltas');
assert.ok(rawfileHtml.includes('dismissCancel: null'), 'WebGL rawfile should support canceling an upward card dismiss');
assert.ok(rawfileHtml.includes('reflow: null'), 'WebGL rawfile should support live card reflow after dismiss');
assert.ok(rawfileHtml.includes('neighborShrink: 0'), 'WebGL rawfile should shrink neighboring cards during dismiss like the reference');
assert.ok(rawfileHtml.includes('mode = "undecided"'), 'WebGL rawfile should decide between horizontal pan and upward dismiss after recents are open');
assert.ok(rawfileHtml.includes('mode === "pan"') && rawfileHtml.includes('mode === "dismiss"'), 'WebGL rawfile should model the reference pan and dismiss modes');
assert.ok(
  rawfileHtml.includes('if (mode === "pan" && S.dragDY < -32 && Math.abs(S.dragDY) > Math.abs(S.dragDX) * 0.75)') &&
    rawfileHtml.includes('mode = "dismiss";'),
  'WebGL rawfile should recover an upward delete gesture even when early pointer sampling briefly chooses horizontal pan'
);
assert.ok(
  rawfileHtml.includes('hitCardIndex(clientX, clientY, allowFallback = true)') &&
    rawfileHtml.includes('const directHit = hitCardIndex(point.clientX, point.clientY, false);') &&
    rawfileHtml.includes('mode = "background-tap";') &&
    rawfileHtml.includes('S.prgT = 0;'),
  'WebGL rawfile should close recents when the user taps blank background space'
);
assert.ok(rawfileHtml.includes('frameDX') && rawfileHtml.includes('S.idxT - frameDX /'), 'WebGL rawfile should advance card index from per-frame horizontal movement');
assert.ok(rawfileHtml.includes('S.bend +='), 'WebGL rawfile should animate bend from drag and index velocity');
assert.ok(rawfileHtml.includes('cardSlots') && rawfileHtml.includes('cardSlotTargets'), 'WebGL rawfile should position cards with live slot and target slot arrays');
assert.ok(rawfileHtml.includes('cardGone'), 'WebGL rawfile should remove dismissed cards without changing texture order');
assert.ok(rawfileHtml.includes('function closeDismissedCard'), 'WebGL rawfile should close a card and reflow the remaining cards');
assert.ok(rawfileHtml.includes('FLY_REFLOW_AT'), 'WebGL rawfile should start reflow during the dismiss fly phase');
assert.ok(rawfileHtml.includes('uFold') && rawfileHtml.includes('uFly'), 'WebGL rawfile should expose fold/fly shader uniforms for upward dismiss');
assert.ok(
  rawfileHtml.includes('uniform float uTwist;') &&
    rawfileHtml.includes('gl.uniform1f(textureLocations.uTwist, twist || 0);') &&
    rawfileHtml.includes('float twistAngle = uTwist * p.y * 1.35;') &&
    rawfileHtml.includes('float twistZ = local.x * twistSin * 0.78;'),
  'WebGL upward dismiss should twist the card surface row-by-row into a native-like spiral'
);
assert.ok(
  rawfileHtml.includes('dismissTwist = soft(clamp((dismissT - 0.12) / 0.58, 0, 1)) * 2.7;') &&
    rawfileHtml.includes('twist: clamp(dismissTwist, 0, 2.7),'),
  'WebGL upward dismiss should ramp a strong twist value during card deletion'
);
assert.ok(
  !rawfileHtml.includes('dragTargetX'),
  'WebGL rawfile should not use the old threshold-only dragTargetX interaction'
);
assert.ok(rawfileHtml.includes('const cardMetadata = ['), 'WebGL rawfile should keep card icon and label metadata in card order');
for (const appLabel of ['小红书', '滴滴出行', '淘宝', '快手']) {
  assert.ok(rawfileHtml.includes(`label: "${appLabel}"`), `WebGL rawfile should expose the app label ${appLabel}`);
}
assert.ok(
  !rawfileHtml.includes('<div id="cardLabels"'),
  'WebGL rawfile should not render app labels through a DOM overlay because they cannot share the card mesh deformation'
);
assert.ok(
  !rawfileHtml.includes('function updateCardLabels(') && !rawfileHtml.includes('cardLabelElements['),
  'WebGL rawfile should not move app labels with independent CSS transforms'
);
assert.ok(
  rawfileHtml.includes('cardLeft = (card.x - card.width * card.scale * 0.5) / cssScaleX'),
  'WebGL card labels should align from the card left edge like the native recents layout'
);
assert.ok(
  rawfileHtml.includes('cardTop = (card.y - card.height * card.scale * 0.5) / cssScaleY'),
  'WebGL card labels should align from the card top edge like the native recents layout'
);
assert.ok(
  rawfileHtml.includes('uniform vec2 uParentSize;') && rawfileHtml.includes('uniform vec2 uLocalOffset;'),
  'WebGL textured shader should support child surfaces in the card parent coordinate system'
);
assert.ok(
  rawfileHtml.includes('gl.uniform2f(textureLocations.uParentSize, parentWidth, parentHeight);') &&
    rawfileHtml.includes('gl.uniform2f(textureLocations.uLocalOffset, localOffsetX, localOffsetY);'),
  'WebGL draw calls should pass parent card size and local label offset into the shader'
);
assert.ok(
  !rawfileHtml.includes('<img class="card-label-icon"'),
  'WebGL card label icons should not use DOM img elements because Harmony WebView can render them as broken images'
);
assert.ok(
  !rawfileHtml.includes('src="data:image/png;base64,'),
  'WebGL card label icons should not use data-url DOM images because Harmony WebView can render them as broken images'
);
assert.ok(
  !rawfileHtml.includes('src="taskbar_up_webgl_icon'),
  'WebGL card label icons should not use relative rawfile img paths because Harmony WebView can render them as broken images'
);
assert.ok(rawfileHtml.includes('"icons":['), 'WebGL rawfile should inline raw RGBA app icon textures');
assert.ok(
  rawfileHtml.includes('function createCardLabelTexture(meta, iconRaw)'),
  'WebGL rawfile should compose icon and tag text into a transparent WebGL label texture'
);
assert.ok(
  rawfileHtml.includes('labels: cardMetadata.map((meta, index) => createCardLabelTexture(meta, labelIconAssetPaths[index]))'),
  'WebGL rawfile should create one label texture per card from the card metadata and icon assets'
);
assert.ok(rawfileHtml.includes('function drawCardLabel(card, cssScaleX, cssScaleY)'), 'WebGL rawfile should draw card labels in WebGL');
assert.ok(rawfileHtml.includes('drawCardLabel(card, cssScaleX, cssScaleY);'), 'WebGL rawfile should draw each label on the same transformed surface as its card');
assert.ok(
  rawfileHtml.includes('card.rotation,\n            card.bend,\n            card.tiltY,\n            card.depth,'),
  'WebGL card labels should use the same rotation, bend, tilt, and depth as their cards'
);
assert.ok(
  rawfileHtml.includes('card.width,\n            card.height,\n            localOffsetX,\n            localOffsetY'),
  'WebGL card labels should be drawn with card parent dimensions and card-local offset so icon and tag deform with the card'
);
assert.ok(rawfileHtml.includes('localOffsetY,\n            card.twist'), 'WebGL card labels should inherit the deletion twist from the card surface');
assert.ok(rawfileHtml.includes('const LABEL_ICON_SIZE = 20;'), 'WebGL card label icons should be smaller and lighter above the cards');
assert.ok(rawfileHtml.includes('const LABEL_TEXT_SIZE = 15;'), 'WebGL card label text should be slightly smaller beside the icon');
assert.ok(rawfileHtml.includes('fillStyle = \"#ffffff\"'), 'WebGL card label text should be fully opaque white');
assert.ok(rawfileHtml.includes('const labelAlpha = card.alpha > 0.01 ? 1 : 0;'), 'WebGL card icon and tag should not be semi-transparent once their card is visible');
assert.ok(
  rawfileHtml.includes('if (radius <= 0.5) {\n              return 1.0;\n            }'),
  'WebGL transparent label textures should bypass the rounded-card mask so icon and tag are not rendered semi-transparent'
);
assert.ok(rawfileHtml.includes('const labelY = cardTop - 30 * S.prg;'), 'WebGL card labels should sit slightly lower above the card like the native reference');
assert.ok(
  rawfileHtml.includes('const dynamicGap = state.width * 0.70 - state.width * 0.045 * soft(panCurve);'),
  'WebGL recents cards should sit closer together with a native-like horizontal gap'
);
assert.ok(rawfileHtml.includes('state.width * 0.64') && rawfileHtml.includes('state.height * 0.68'), 'WebGL recents cards should be scaled closer to the native reference proportions');

const rootPreviewAssets = [
  ['Background2.png', 'taskbar_up_webgl_background2.png'],
  ['Background3.png', 'taskbar_up_webgl_background3.png'],
  ['Card1.png', 'taskbar_up_webgl_card1.png'],
  ['Card2.png', 'taskbar_up_webgl_card2.png'],
  ['Card3.png', 'taskbar_up_webgl_card3.png'],
  ['Card4.png', 'taskbar_up_webgl_card4.png'],
];

for (const [assetName, rootAssetName] of rootPreviewAssets) {
  assert.ok(
    rawfileHtml.includes(rootAssetName),
    `WebGL rawfile should use optimized root-level preview asset ${rootAssetName}`
  );
  assert.ok(
    fs.existsSync(path.join(path.dirname(rawfileHtmlPath), rootAssetName)),
    `WebGL rawfile root-level preview asset should exist locally: ${rootAssetName}`
  );
}

for (const iconName of ['icon1.png', 'icon2.png', 'icon3.png', 'icon4.png']) {
  const rootIconName = `taskbar_up_webgl_${iconName}`;
  assert.ok(rawfileHtml.includes(rootIconName), `WebGL rawfile should use root-level app icon asset ${rootIconName}`);
  assert.ok(
    fs.existsSync(path.join(path.dirname(rawfileHtmlPath), rootIconName)),
    `WebGL rawfile root-level app icon should exist locally: ${rootIconName}`
  );
}
