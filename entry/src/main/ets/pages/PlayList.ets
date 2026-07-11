//歌单详情页
import { SongItemType } from '../models/music'
import { AppStorageV2 } from '@kit.ArkUI'
import { playerManager } from '../utils/AvPlayerManager'
import { GlobalMusic } from '../models/globalMusic'

// 路由入口 builder
@Builder
export function PlayListBuilder() {
  PlayList()
}

@ComponentV2
struct PlayList {
  pathStack: NavPathStack = new NavPathStack()
  // 从导航参数接收歌单数据
  @Local img: string | Resource = ''
  @Local title: string = ''
  @Local accentColor: string = '#ffffff40'
  @Local songList: SongItemType[] = []
  // 当前播放状态
  @Local playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!

  build() {
    NavDestination() {
      Column() {
        // 顶部封面图
        Image(this.img)
          .width('100%')
          .height(220)
          .objectFit(ImageFit.Cover)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

        // 歌单信息卡片
        Column({ space: 10 }) {
          // 标题
          Text(this.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 标签行
          Row({ space: 8 }) {
            // 歌曲数量标签
            Text(`共 ${this.songList.length} 首歌曲`)
              .fontSize(12)
              .fontColor('#fff')
              .border({ width: 0.5, color: '#ffffff40', radius: 10 })
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })

            Text('超过10w播放')
              .fontSize(12)
              .fontColor('#fff')
              .border({ width: 0.5, color: '#ffffff40', radius: 10 })
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }
          .width('100%')

          // 播放全部按钮
          Row({ space: 8 }) {
            Image($r('app.media.ic_play'))
              .width(18)
              .height(18)
              .fillColor('#fff')
            Text('播放全部')
              .fontSize(15)
              .fontColor('#fff')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .height(42)
          .backgroundColor('#000')
          .borderRadius(20)
          .justifyContent(FlexAlign.Center)
          .border({ width: 1, color: this.accentColor, radius: 20 })
          .onClick(() => {
            if (this.songList.length > 0) {
              this.pathStack.pushPathByName('Play', null, false)
              playerManager.singPlay(this.songList[0])
            }
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })
        .backgroundColor('#000')
        .borderRadius({ topLeft: 16, topRight: 16 })
        .margin({ top: -16 })

        // 分割线
        Divider()
          .color(this.accentColor)
          .strokeWidth(1)
          .width('100%')

        // 歌曲列表
        List() {
          ForEach(this.songList, (item: SongItemType, index: number) => {
            ListItem() {
              Row() {
                // 序号
                Text((index + 1).toString())
                  .fontColor(index < 3 ? '#ff5186' : '#999')
                  .fontSize(14)
                  .width(36)
                  .textAlign(TextAlign.Center)

                // 歌曲封面
                Image(item.img)
                  .width(48)
                  .height(48)
                  .borderRadius(6)
                  .margin({ right: 10 })

                // 歌曲信息
                Column({ space: 4 }) {
                  Text(item.name)
                    .fontSize(15)
                    .fontColor(Color.White)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.author)
                    .fontSize(12)
                    .fontColor('#999')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                // 正在播放图标
                if (this.playState.url === item.url && this.playState.isPlay) {
                  Image($r('app.media.wave'))
                    .width(24)
                    .margin({ right: 10 })
                }

                // 更多按钮
                Image($r('app.media.ic_more'))
                  .width(20)
                  .height(20)
                  .fillColor('#999')
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .alignItems(VerticalAlign.Center)
              .onClick(() => {
                this.pathStack.pushPathByName('Play', null, false)
                playerManager.singPlay(item)
              })
            }
          })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor('#000')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      // 接收传入的歌单数据
      const p = context.pathInfo?.param as Record<string, Object>
      if (p) {
        this.img = (p['img'] as string | Resource) || ''
        this.title = (p['title'] as string) || ''
        this.accentColor = (p['top'] as string) || '#ffffff40'
        this.songList = (p['songs'] as SongItemType[]) || []
      }
    })
    .hideTitleBar(true)
  }
}
