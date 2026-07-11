import { preferences } from '@kit.ArkData'

const LOGIN_STORE = 'login_store'
const KEY_LOGGED_IN = 'is_logged_in'
const VALID_ACCOUNT = '192837465'
const VALID_PASSWORD = 'tz666'

@Builder
export function LoginBuilder() {
  Login()
}

@ComponentV2
struct Login {
  pathStack: NavPathStack = new NavPathStack()
  @Local account: string = ''
  @Local password: string = ''
  @Local errorText: string = ''

  async login(): Promise<void> {
    if (this.account === VALID_ACCOUNT && this.password === VALID_PASSWORD) {
      const prefs = await preferences.getPreferences(getContext(this), LOGIN_STORE)
      await prefs.put(KEY_LOGGED_IN, true)
      await prefs.flush()
      this.pathStack.replacePathByName('Layout', null, false)
    } else {
      this.errorText = '账号或密码错误'
    }
  }

  @Builder
  inputBox(placeholder: string, value: string, isPassword: boolean) {
    Row({ space: 10 }) {
      Text(isPassword ? '密码' : '账号')
        .fontSize(14)
        .fontColor('#6b7280')
        .width(42)
      TextInput({ placeholder: placeholder, text: value })
        .layoutWeight(1)
        .height(46)
        .fontSize(15)
        .fontColor('#1f2937')
        .placeholderColor('#a7adba')
        .backgroundColor(Color.Transparent)
        .type(isPassword ? InputType.Password : InputType.Normal)
        .onChange((text: string) => {
          this.errorText = ''
          if (isPassword) {
            this.password = text
          } else {
            this.account = text
          }
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 12 })
    .backgroundColor('#f7f8fb')
    .borderRadius(18)
    .border({ width: 1, color: '#edf0f5' })
  }

  build() {
    NavDestination() {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: 160,
            colors: [
              ['#fff4f7', 0],
              ['#eef9ff', 0.52],
              ['#f8fff1', 1]
            ]
          })

        Column({ space: 24 }) {
          Column({ space: 14 }) {
            Stack() {
              Image($r('app.media.touxiang'))
                .width(104)
                .height(104)
                .borderRadius(52)
                .border({ width: 4, color: Color.White })
                .shadow({ radius: 24, color: '#22000000', offsetY: 8 })

              Row()
                .width(18)
                .height(18)
                .borderRadius(9)
                .backgroundColor('#35d07f')
                .border({ width: 3, color: Color.White })
                .position({ x: 78, y: 78 })
            }
            .width(104)
            .height(104)

            Text('欢迎回来')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1f2937')

            Text('登录后继续听你喜欢的音乐')
              .fontSize(14)
              .fontColor('#7b8494')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)

          Column({ space: 14 }) {
            this.inputBox('请输入账号', this.account, false)
            this.inputBox('请输入密码', this.password, true)

            if (this.errorText.length > 0) {
              Text(this.errorText)
                .fontSize(13)
                .fontColor('#ef4444')
                .width('100%')
                .textAlign(TextAlign.Center)
            }

            Button('登录')
              .width('100%')
              .height(52)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor('#ff5186')
              .borderRadius(20)
              .shadow({ radius: 18, color: '#33ff5186', offsetY: 8 })
              .onClick(() => {
                void this.login()
              })
          }
          .width('100%')
          .padding({ left: 26, right: 26 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ bottom: 40 })
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
    .hideTitleBar(true)
  }
}
