//下面的导航页
import { Liked } from "./Liked"
import { KGe } from "./KGe"
import { Mine } from "./Mine"
import { Recommend } from "./Recommend"
import { playerManager } from "../utils/AvPlayerManager"

interface TabClass {
  text: string
  icon: ResourceStr
}

// 跳转页面入口函数
@Builder
export function LayoutBuilder() {
  Layout()
}

@ComponentV2
struct Layout {
  @Local currentIndex: number = 0
  // 控制跳转的对象
  pathStack: NavPathStack = new NavPathStack()
  tabData: TabClass[] = [
    {text: '大厅', icon: $r('app.media.dhzhuye')},
    {text: 'K歌', icon: $r('app.media.dhkge')},
    {text: '喜欢', icon: $r('app.media.dhxihuan')},
    {text: '个人', icon: $r('app.media.dhwode')}
  ]

  aboutToAppear(): void {
    playerManager.bindContext(getContext(this))
  }

  @Builder tabBuilder (item: TabClass,index: number) {
    Column({ space: 1}) {
     //图标颜色
      Image(item.icon)
        .width(24)
        .fillColor(this.currentIndex === index ? '#85e85a5f' : '#ff639caa')
      Text(item.text)
        .fontSize(14)
        .fontColor(this.currentIndex === index ? '#ffaa63a9' :'#000000')
    }
  }

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End }) {
        //Foreach连续生成四个页面
        ForEach(this.tabData, (item: TabClass, index: number) => {
          TabContent() {
            if (index === 0) {
              Recommend()
            } else if (index === 1) {
              KGe()
            } else if (index === 2) {
              Liked()
            } else if (index === 3) {
              Mine()
            }
          }
          .tabBar(this.tabBuilder(item, index)) // 自定义导航栏 → @Builder
          //上面这个的背景色
          .backgroundColor("#56ededed")

          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        })
      }
      //导航页的背景图
      .backgroundColor(Color.White)
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    //.title('布局页')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}
