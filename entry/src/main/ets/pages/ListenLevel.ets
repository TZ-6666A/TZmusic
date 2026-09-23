// 听歌等级页
import { AppStorageV2 } from '@kit.ArkUI'
import { ListenStatsStore, ListenStatsState, LISTEN_STATS_KEY } from '../models/listenStatsStore'

interface LevelInfo {
  level: number
  name: string
  minMinutes: number
  maxMinutes: number
  color: string
}

const LEVELS: LevelInfo[] = [
  { level: 1, name: 'Lv1', minMinutes: 1, maxMinutes: 10, color: '#94a3b8' },
  { level: 2, name: 'Lv2', minMinutes: 10, maxMinutes: 30, color: '#34d399' },
  { level: 3, name: 'Lv3', minMinutes: 30, maxMinutes: 100, color: '#60a5fa' },
  { level: 4, name: 'Lv4', minMinutes: 100, maxMinutes: 1000, color: '#a78bfa' },
  { level: 5, name: 'Lv5', minMinutes: 1000, maxMinutes: 5000, color: '#f472b6' },
  { level: 6, name: 'Lv6', minMinutes: 5000, maxMinutes: 10000, color: '#fbbf24' }
]

function calcLevel(minutes: number): number {
  if (minutes < 1) return 0
  for (const lv of LEVELS) {
    if (minutes < lv.maxMinutes) return lv.level
  }
  return 6
}

@Builder
export function ListenLevelBuilder() {
  ListenLevelPage()
}

@ComponentV2
struct ListenLevelPage {
  pathStack: NavPathStack = new NavPathStack()
  @Local listenStats: ListenStatsState = AppStorageV2.connect(ListenStatsState, LISTEN_STATS_KEY, () => new ListenStatsState())!

  aboutToAppear(): void {
    void this.loadStats()
  }

  async loadStats(): Promise<void> {
    await ListenStatsStore.ensureLoaded(getContext(this))
  }

  // 与个人页绑定同一份全局数据，保证分钟数完全一致
  @Computed
  get listenMinutes(): number {
    return this.listenStats.totalMinutes
  }

  @Computed
  get currentLevel(): number {
    return calcLevel(this.listenStats.totalMinutes)
  }

  getProgress(): number {
    if (this.currentLevel === 0) return 0
    if (this.currentLevel >= 6) return 1
    const lv = LEVELS[this.currentLevel - 1]
    const range = lv.maxMinutes - lv.minMinutes
    const current = this.listenMinutes - lv.minMinutes
    return Math.min(1, Math.max(0, current / range))
  }

  getNextLevelText(): string {
    if (this.currentLevel === 0) return '再听 1 分钟解锁 Lv1'
    if (this.currentLevel >= 6) return '已达最高等级 Lv6'
    const lv = LEVELS[this.currentLevel - 1]
    const remain = lv.maxMinutes - this.listenMinutes
    return '再听 ' + remain + ' 分钟升级到 Lv' + (this.currentLevel + 1)
  }

  getCurrentColor(): string {
    if (this.currentLevel === 0) return '#ccc'
    return LEVELS[Math.max(0, this.currentLevel - 1)].color
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Image($r('app.media.ic_back'))
            .width(22).height(22).fillColor('#333')
            .onClick(() => { this.pathStack.pop() })
          Text('听歌等级')
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#222')
            .layoutWeight(1).textAlign(TextAlign.Center)
          Row().width(22)
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })

        // 当前等级大卡片
        Column({ space: 14 }) {
          Text(this.currentLevel === 0 ? '未解锁' : 'Lv' + this.currentLevel)
            .fontSize(52).fontWeight(FontWeight.Bold)
            .fontColor(this.getCurrentColor())

          Text('累计听歌 ' + this.listenMinutes + ' 分钟')
            .fontSize(15).fontColor('#666')

          // 进度条
          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%').height(8).borderRadius(4)
              .backgroundColor('#ececec')
            Row()
              .width(this.getProgress() * 100 + '%').height(8).borderRadius(4)
              .backgroundColor(this.getCurrentColor())
          }
          .width('100%')

          Text(this.getNextLevelText())
            .fontSize(13).fontColor('#999')
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#ffffff')
        .borderRadius(16)
        .margin({ left: 16, right: 16, top: 12, bottom: 16 })
        .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 2 })

        // 等级列表标题
        Text('等级说明')
          .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#333')
          .width('100%')
          .padding({ left: 16, bottom: 8 })

        // 等级列表
        List() {
          ForEach(LEVELS, (lv: LevelInfo) => {
            ListItem() {
              Row({ space: 12 }) {
                Text(lv.name)
                  .fontSize(20).fontWeight(FontWeight.Bold)
                  .fontColor(lv.color)
                  .width(56).textAlign(TextAlign.Center)

                Column({ space: 3 }) {
                  Text(lv.minMinutes + ' - ' + lv.maxMinutes + ' 分钟')
                    .fontSize(14).fontColor('#333')
                  Text(this.currentLevel >= lv.level ? '已达成' : '未达成')
                    .fontSize(12).fontColor(this.currentLevel >= lv.level ? lv.color : '#bbb')
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start)

                if (this.currentLevel === lv.level) {
                  Text('当前')
                    .fontSize(12).fontColor(Color.White)
                    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                    .backgroundColor(lv.color)
                    .borderRadius(8)
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .backgroundColor(this.currentLevel >= lv.level ? '#ffffff' : '#fafafa')
              .opacity(this.currentLevel >= lv.level ? 1 : 0.55)
            }
          }, (lv: LevelInfo) => lv.level.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%').height('100%')
      .backgroundColor('#f5f6fa')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
    .hideTitleBar(true)
  }
}
