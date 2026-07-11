//喜欢页 — 收藏的歌
import { SongItemType } from '../models/music'
import { AppStorageV2 } from '@kit.ArkUI'
import { FavoritesStore } from '../models/favoritesStore'
import { GlobalMusic } from '../models/globalMusic'
import { playerManager } from '../utils/AvPlayerManager'

@ComponentV2
export struct Liked {
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!
  @Local favStore: FavoritesStore = AppStorageV2.connect(FavoritesStore, 'FAVORITES_KEY', () => new FavoritesStore())!
  @Local playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!

  build() {
    Column() {
      // 标题
      Text('我 的 喜 欢')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#222')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })

      Text(this.favStore.likedSongs.length > 0 ?
        '共 ' + this.favStore.likedSongs.length + ' 首 · 每首都值得单曲循环' :
        '收藏你心动的旋律')
        .fontSize(13)
        .fontColor('#bbb')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 6, bottom: 12 })

      Divider()
        .strokeWidth(0.5)
        .color('#f0f0f0')

      // 空状态 或 歌曲列表
      if (this.favStore.likedSongs.length === 0) {
        Column({ space: 12 }) {
          Image($r('app.media.ic_like'))
            .width(72)
            .height(72)
            .fillColor('#eeeeee')
            .margin({ top: 24 })

          Text('还没有喜欢的歌')
            .fontSize(16)
            .fontColor('#bbb')

          Text('去发现页或播放器点击 ❤ 收藏吧')
            .fontSize(13)
            .fontColor('#ddd')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
      } else {
        List() {
          ForEach(this.favStore.likedSongs, (item: SongItemType, index: number) => {
            ListItem() {
              Row() {
                Text((index + 1).toString().padStart(2, '0'))
                  .fontColor(index < 3 ? '#ff5186' : '#ccc')
                  .fontSize(16)
                  .fontWeight(index < 3 ? FontWeight.Bold : FontWeight.Normal)
                  .width(36)
                  .textAlign(TextAlign.Center)

                Image(item.img)
                  .width(52)
                  .height(52)
                  .borderRadius(8)
                  .margin({ right: 12 })

                Column({ space: 4 }) {
                  Text(item.name)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#222')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.author)
                    .fontSize(12)
                    .fontColor('#aaa')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                if (this.playState.url === item.url && this.playState.isPlay) {
                  Image($r('app.media.wave'))
                    .width(22)
                    .margin({ right: 8 })
                }

                Image($r('app.media.ic_like'))
                  .width(22)
                  .height(22)
                  .fillColor('#ff5186')
                  .hitTestBehavior(HitTestMode.Block)
                  .onClick(() => {
                    this.favStore.toggleLike(item)
                  })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              .alignItems(VerticalAlign.Center)
              .border({
                width: { bottom: 0.5 },
                color: '#f5f5f5'
              })
              .onClick(() => {
                this.pathStack.pushPathByName('Play', null, false)
                playerManager.singPlay(item)
              })
            }
          })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .backgroundColor(Color.White)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
