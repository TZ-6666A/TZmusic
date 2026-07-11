//广告页面
// 跳转页面入口函数
import { preferences } from '@kit.ArkData'

const LOGIN_STORE = 'login_store'
const KEY_LOGGED_IN = 'is_logged_in'

@Builder
export function StartBuilder() {
  Start()
}

@Component
struct Start {
  //控制跳转的对象
  pathStack: NavPathStack = new NavPathStack()

  async goNext(): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(getContext(this), LOGIN_STORE)
      const loggedIn = await prefs.get(KEY_LOGGED_IN, false) as boolean
      this.pathStack.replacePathByName(loggedIn ? 'Layout' : 'Login', null, false)
    } catch (err) {
      this.pathStack.replacePathByName('Login', null, false)
    }
  }
  // 过3秒钟自动跳转到 Layout → Start 页面打开计时 3秒后跳转
  aboutToAppear(): void { // 生命周期
    setTimeout(() => {
      // replacePathByName   不支持返回
      void this.goNext()
    }, 3000) // 毫秒为单位 1000毫秒 = 1秒
  }

  build() {
    NavDestination() {
      // Button('点击跳转到 Layout ')
      //   .onClick(() => {
      //     this.pageStack.pushPathByName("Layout", null, false)
      //   })
      Stack({ alignContent: Alignment.TopEnd }) {
        Image($r('app.media.guanggaoye'))
          .width('100%')
          .height('100%')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        Button('跳过')
          .backgroundColor(Color.Grey)
          .margin(15)
          .onClick(() => {
            //replacePathByName   不支持返回
            void this.goNext()
            // this.pageStack.pushPathByName("Layout", null, false)  pushPathByname  支持返回
          })
      }
    }
    // .title('广告页')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}
