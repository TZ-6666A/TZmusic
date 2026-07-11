import { preferences } from '@kit.ArkData'
import { AppStorageV2 } from '@kit.ArkUI'
import { ListenStatsStore } from '../models/listenStatsStore'
import { playerManager } from '../utils/AvPlayerManager'
import { GlobalMusic } from '../models/globalMusic'
import { ReviewStore } from '../models/reviewStore'
import { ReviewItem } from '../data/reviewData'

const LOGIN_STORE = 'login_store'
const KEY_LOGGED_IN = 'is_logged_in'

@ComponentV2
export struct Mine {
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!
  @Local listenMinutes: number = 0
  @Local playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  @Local reviewStore: ReviewStore = AppStorageV2.connect(ReviewStore, 'REVIEW_KEY', () => new ReviewStore())!

  aboutToAppear(): void {
    void this.loadListenMinutes()
  }

  async loadListenMinutes(): Promise<void> {
    this.listenMinutes = await ListenStatsStore.getTotalMinutes(getContext(this))
  }

  async logout(): Promise<void> {
    await playerManager.stopAndReset()
    const prefs = await preferences.getPreferences(getContext(this), LOGIN_STORE)
    await prefs.put(KEY_LOGGED_IN, false)
    await prefs.flush()
    this.pathStack.replacePathByName('Login', null, false)
  }

  @Builder
  actionRow(title: string, desc: string, danger: boolean) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(danger ? '#ef4444' : '#222')
        .layoutWeight(1)
      Text(desc)
        .fontSize(12)
        .fontColor(danger ? '#ef4444' : '#999')
      if (!danger) {
        Image($r('app.media.ic_more'))
          .width(18)
          .height(18)
          .fillColor('#bbb')
      }
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .backgroundColor(danger ? '#fff1f2' : '#f8f8f8')
    .borderRadius(14)
    .onClick(() => {
      if (danger) {
        void this.logout()
      } else {
        this.pathStack.pushPathByName('HistoryKGe', null, false)
      }
    })
  }

  @Builder
  playerEntry() {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(48)
          .height(48)
          .fill('#ffe4ec')
        Circle()
          .width(34)
          .height(34)
          .fill('#ff5186')
        Image($r('app.media.ic_play'))
          .width(16)
          .height(16)
          .fillColor(Color.White)
      }

      Column({ space: 5 }) {
        Text(this.playState.name ? '正在播放' : '音乐播放器')
          .fontSize(12)
          .fontColor('#999')
        Text(this.playState.name || '进入播放器')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.playState.author || '查看当前歌曲和播放列表')
          .fontSize(12)
          .fontColor('#999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.ic_more'))
        .width(18)
        .height(18)
        .fillColor('#bbb')
    }
    .width('100%')
    .height(76)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#f8f8f8')
    .borderRadius(14)
    .onClick(() => {
      this.pathStack.pushPathByName('Play', null, false)
    })
  }

  @Builder
  addReviewRow() {
    Row() {
      Text('添加歌评')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#222')
        .layoutWeight(1)
      Text('选择歌曲并发表评价')
        .fontSize(12)
        .fontColor('#999')
      Image($r('app.media.ic_more'))
        .width(18)
        .height(18)
        .fillColor('#bbb')
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#f8f8f8')
    .borderRadius(14)
    .onClick(() => {
      this.pathStack.pushPathByName('AddReview', null, false)
    })
  }

  build() {
    Scroll() {
      Column() {
        Image($r('app.media.beijingtu'))
          .width('100%')
          .height(300)
          .objectFit(ImageFit.Cover)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

        Column() {
          Image($r('app.media.touxiang'))
            .width(80)
            .height(80)
            .border({ width: 3, color: Color.White })
            .alignSelf(ItemAlign.End)
            .margin({ right: 18, top: -65 })

          Text('音乐调味人生')
            .fontSize(13)
            .fontColor('#ff292020')
            .alignSelf(ItemAlign.End)
            .margin({ right: 16, top: 3 })

          Divider()
            .strokeWidth(0.5)
            .color('#eeeeee')
            .margin({ top: 20, left: 18, right: 18 })

          Column({ space: 10 }) {
            Row() {
              Column({ space: 4 }) {
                Text('累计听歌时长')
                  .fontSize(15)
                  .fontColor('#666')
                Text(this.listenMinutes.toString() + ' 分钟')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#222')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Image($r('app.media.ic_music'))
                .width(30)
                .height(30)
                .fillColor('#ff5186')
                .hitTestBehavior(HitTestMode.Block)
                .onClick(() => {
                  void this.loadListenMinutes()
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .backgroundColor('#fff4f8')
            .borderRadius(14)

            this.playerEntry()

            this.actionRow('历史K歌', '查看我录的歌', false)
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 14, bottom: 4 })

          Text('歌曲评价')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')
            .margin({ left: 18, top: 16, bottom: 12 })

          ForEach(this.reviewStore.reviews, (item: ReviewItem, index: number) => {
            Column() {
              Row({ space: 12 }) {
                Image(item.img)
                  .width(52)
                  .height(52)
                  .borderRadius(8)

                Column({ space: 4 }) {
                  Text(item.name)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#222')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.author)
                    .fontSize(12)
                    .fontColor('#999')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Text('删除')
                  .fontSize(12)
                  .fontColor('#ef4444')
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .backgroundColor('#fff1f2')
                  .borderRadius(14)
                  .onClick(() => {
                    this.reviewStore.deleteReview(index)
                  })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 8 })

              Text(item.comment)
                .fontSize(13)
                .fontColor('#666')
                .lineHeight(20)
                .padding({ left: 16, right: 16, bottom: 12 })

              Divider()
                .strokeWidth(0.5)
                .color('#f0f0f0')
                .margin({ left: 16, right: 16 })
            }
          })

          Row().height(28)

          Column() {
            this.addReviewRow()

            Row().height(10)

            this.actionRow('退出登录', '返回登录页', true)
          }
          .width('100%')
          .padding({ left: 18, right: 18, bottom: 24 })
        }
        .width('100%')
        .backgroundColor(Color.White)
        .padding({ bottom: 24 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
