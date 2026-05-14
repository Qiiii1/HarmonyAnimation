interface SimplePageRouteOptions {
  url: string;
}

interface SceneItem {
  title: string;
  subtitle: string;
  url: string;
}

@Entry
@Component
struct ScenePage {
  private readonly PAGE_HORIZONTAL_PADDING: number = 20;
  private readonly PAGE_VERTICAL_PADDING: number = 28;
  private readonly PANEL_RADIUS: number = 32;
  private readonly PANEL_PADDING: number = 22;
  private readonly CARD_RADIUS: number = 24;
  private readonly CARD_HEIGHT: number = 74;
  private readonly CARD_GAP: number = 14;

  private readonly sceneItems: SceneItem[] = [
    {
      title: '参数总控台',
      subtitle: '统一管理音量条、多任务、解锁和下拉任务栏参数。',
      url: 'pages/config/AllConfigPage'
    },
    {
      title: '应用打开退出',
      subtitle: '桌面图标放大切入应用，可调整时长和关闭回弹。',
      url: 'pages/config/IndexConfigPage'
    },
    {
      title: '上滑多任务',
      subtitle: '多任务卡片唤起、居中与左右滑动预览。',
      url: 'pages/config/TaskbarUpConfigPage'
    },
    {
      title: '调节音量条',
      subtitle: '音量条拖拽、回弹与极值形变效果。',
      url: 'pages/config/VolumeConfigPage'
    },
    {
      title: '解锁进入桌面',
      subtitle: '锁屏上滑解锁，模块渐入放大出现。',
      url: 'pages/config/UnlockDesktopConfigPage'
    },
    {
      title: '下拉任务栏',
      subtitle: '控制中心下拉、模糊与模块跟手动画。',
      url: 'pages/config/TaskbarDownConfigPage'
    }
  ];

  private openSimplePage(url: string): void {
    try {
      const options: SimplePageRouteOptions = {
        url: url,
      };
      this.getUIContext().getRouter().pushUrl(options);
    } catch (_error) {
    }
  }

  @Builder
  private buildHeader() {
    Column({ space: 10 }) {
      Text('SCENE LAB')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#CCFFFFFF')
        .letterSpacing(2)

      Text('场景选择')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Text('选择一个动画场景，先调整参数，再进入预览。')
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#D6FFFFFF')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildSceneCard(item: SceneItem) {
    Button() {
      Row() {
        Column({ space: 6 }) {
          Text(item.title)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFFFF')

          Text(item.subtitle)
            .fontSize(12)
            .lineHeight(18)
            .fontColor('#CCFFFFFF')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('进入')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#F4F4F4')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#14FFFFFF')
          .borderRadius(999)
      }
      .width('100%')
      .height(this.CARD_HEIGHT)
      .padding({ left: 18, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(this.CARD_HEIGHT)
    .backgroundColor('#2410161D')
    .borderRadius(this.CARD_RADIUS)
    .border({
      width: 1,
      color: '#1FFFFFFF'
    })
    .onClick(() => {
      this.openSimplePage(item.url);
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
        .blur(26)
        .opacity(0.16)
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#78090C11')
        .expandSafeArea(
          [SafeAreaType.SYSTEM, SafeAreaType.CUTOUT],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]
        )

      Column() {
        Column({ space: 26 }) {
          this.buildHeader()

          Column({ space: this.CARD_GAP }) {
            ForEach(this.sceneItems, (item: SceneItem) => {
              this.buildSceneCard(item);
            }, (item: SceneItem) => item.url)
          }
          .width('100%')
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
