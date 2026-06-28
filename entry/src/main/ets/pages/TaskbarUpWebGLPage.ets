import webview from '@ohos.web.webview';

@Entry
@Component
struct TaskbarUpWebGLPage {
  @StorageLink('taskbarUpSwipeDampingRatio') upSwipeDampingRatio: number = 1.5;
  @StorageLink('taskbarUpLeadCardReleaseDurationMs') leadCardReleaseDurationMs: number = 1000;
  @StorageLink('taskbarUpCardBounceOvershootX') cardBounceOvershootX: number = 5;

  private readonly controller: webview.WebviewController = new webview.WebviewController();

  private parameterScript(): string {
    return `window.setTaskbarUpParams && window.setTaskbarUpParams({ durationMs: ${this.leadCardReleaseDurationMs}, dampingRatio: ${this.upSwipeDampingRatio}, reboundPercent: ${this.cardBounceOvershootX} });`;
  }

  private syncParametersToWeb(): void {
    this.controller.runJavaScript(this.parameterScript())
      .then(() => {
      })
      .catch(() => {
      });
  }

  build() {
    Stack() {
      Web({ src: 'resource://rawfile/taskbar_up_webgl.html', controller: this.controller })
        .width('100%')
        .height('100%')
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .imageAccess(true)
        .onlineImageAccess(false)
        .onPageEnd(() => {
          this.syncParametersToWeb();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .expandSafeArea(
      [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
      [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
    )
  }
}
