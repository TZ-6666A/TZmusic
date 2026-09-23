//音乐播放器页面
import { GlobalMusic } from "../models/globalMusic";
import { SongItemType } from "../models/music"
import { AppStorageV2 } from "@kit.ArkUI";
import { playerManager } from "../utils/AvPlayerManager";
import { FavoritesStore } from "../models/favoritesStore";

// 跳转页面入口函数
@Builder
export function PlayBuilder() {
  Play()
}

@ComponentV2
struct Play {
  @Local panelHeight: string = '0%'
  @Local panelOpacity: number = 0
  pathStack : NavPathStack = new NavPathStack();

  @Local
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', ()=> new GlobalMusic())!
  favStore: FavoritesStore = AppStorageV2.connect(FavoritesStore, 'FAVORITES_KEY', () => new FavoritesStore())!
  @Local rotateAngle: number = 0
  private rotateTimer: number = -1


  @Builder
  deleteButton(index: number) {
    Button('删除')
      .backgroundColor('#ec5c87')
      .fontColor('#fff')
      .width(80)
      .height('100%')
      .type(ButtonType.Normal)
      .onClick(() => {
        playerManager.removeSong(index)
        this.pathStack.pop()
      })

  }

  number2time(number: number) {
    const totalSeconds = Math.max(0, Math.floor(number / 1000))
    const minute = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
    const second = (totalSeconds % 60).toString().padStart(2, '0')
    return minute + ':' + second
  }

  aboutToAppear(): void {
    if (this.playState.isPlay) {
      this.startRotate()
    }
  }

  aboutToDisappear(): void {
    this.stopRotate()
  }

  @Monitor('playState.isPlay')
  onPlayChange(): void {
    if (this.playState.isPlay) {
      this.startRotate()
    } else {
      this.stopRotate()
    }
  }

  startRotate(): void {
    if (this.rotateTimer !== -1) {
      return
    }
    this.rotateTimer = setInterval(() => {
      this.rotateAngle = (this.rotateAngle + 2) % 360
    }, 50)
  }

  stopRotate(): void {
    if (this.rotateTimer !== -1) {
      clearInterval(this.rotateTimer)
      this.rotateTimer = -1
    }
  }

  @Builder
  emptyPlayer() {
    Column({ space: 18 }) {
      Blank()
        .layoutWeight(1)

      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(150)
          .height(150)
          .fill('#123936')
        Circle()
          .width(104)
          .height(104)
          .fill('#ffffff')
          .opacity(0.92)
        Image($r('app.media.ic_music'))
          .width(48)
          .height(48)
          .fillColor('#0f766e')
      }

      Text('暂无播放歌曲')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)

      Text('先去歌单里选择一首歌，再回到播放器查看播放状态')
        .fontSize(14)
        .fontColor('#cbd5d1')
        .textAlign(TextAlign.Center)
        .width('72%')
        .lineHeight(22)

      Row({ space: 8 }) {
        Image($r('app.media.ic_back'))
          .width(18)
          .height(18)
          .fillColor('#0f766e')
        Text('返回')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#0f766e')
      }
      .height(44)
      .padding({ left: 22, right: 22 })
      .backgroundColor(Color.White)
      .borderRadius(22)
      .onClick(() => {
        this.pathStack.pop()
      })

      Blank()
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#071312')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        // 播放
        Stack() {
          // 变色背景
          Image(this.playState.img)
            .width('100%')
            .height('100%')
            .blur(1000)
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

          // 内容
          Column() {
            Column() {
              // 图片
              Stack({ alignContent: Alignment.Top }) {
                Row() {
                  Row() {
                    Image(this.playState.img)
                      .width('70%')
                      .borderRadius(400)
                  }
                  .backgroundImage($r('app.media.ic_cd'))
                  .backgroundImageSize(ImageSize.Cover)
                  .justifyContent(FlexAlign.Center)
                  .width('100%')
                  .borderRadius(400)
                  .clip(true)
                  .aspectRatio(1)
                  .rotate({ angle: this.rotateAngle })
                }
                .margin({
                  top: 30
                })
                .width('84%')
                .constraintSize({ maxWidth: 300 })
                .aspectRatio(1)
                .justifyContent(FlexAlign.Center)
                .padding(12)
                // 唱针：播放时转到唱片上，暂停/未播放时移开
                Image($r('app.media.ic_stylus'))
                  .width(200)
                  .aspectRatio(1)
                  .rotate({
                    angle: this.playState.isPlay ? -28 : -55,
                    centerX: 100,
                    centerY: 30
                  })
                  .animation({
                    duration: 500,
                    curve: Curve.EaseInOut
                  })
              }
              .margin({ top: 20 })
              // 歌曲信息
              Column({ space: 8 }) {
                Text(this.playState.name)
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                Text(this.playState.author)
                  .fontSize(18)
                  .fontColor(Color.White)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              // 操作
              Row() {
                Badge({ value: '99+', style: { badgeSize: 12, badgeColor: '#45CCCCCC' } }) {
                  Image($r("app.media.ic_like"))
                    .fillColor(this.favStore.isLiked(this.playState.id || this.playState.url) ? '#ff4444' : Color.White)
                    .width(24)
                    .hitTestBehavior(HitTestMode.Block)
                    .onClick(() => {
                      const song: SongItemType = {
                        img: this.playState.img,
                        name: this.playState.name,
                        author: this.playState.author,
                        url: this.playState.url,
                        id: this.playState.id || this.playState.url
                      } as SongItemType
                      this.favStore.toggleLike(song)
                    })
                }

                Badge({ value: '10W', style: { badgeSize: 12, badgeColor: '#45cccccc' } }) {
                  Image($r("app.media.ic_comment_o"))
                    .fillColor(Color.White)
                    .width(18)
                }

                Badge({ value: 'hot', style: { badgeSize: 12, badgeColor: '#a8ff3131' } }) {
                  Image($r("app.media.ic_bells_o"))
                    .fillColor(Color.White)
                    .width(24)
                }

                Badge({ value: 'vip', style: { badgeSize: 12, badgeColor: '#b7efd371' } }) {
                  Image($r("app.media.ic_download_o"))
                    .fillColor(Color.White)
                    .width(24)
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)
              // 播放
              Column() {
                // 进度条
                Row({ space: 4 }) {
                  Text(this.number2time(this.playState.time))
                    .fontSize(12)
                    .fontColor(Color.White)
                  Slider({
                    value: this.playState.time,
                    min: 0,
                    max: Math.max(1, this.playState.duration),
                  })
                    .layoutWeight(1)
                    .blockColor(Color.White)
                    .selectedColor(Color.White)
                    .trackColor('#ccc5c5c5')
                    .trackThickness(2)
                    .onChange((value) => {
                      if (this.playState.duration > 0) {
                        playerManager.seekPlay(value)
                      }
                    })
                  Text(this.number2time(this.playState.duration))
                    .fontSize(12)
                    .fontColor(Color.White)
                }
                .width('100%')
                .padding(24)
                // 切换
                Row() {
                  if (this.playState.playMode === 'auto') {
                    Image($r('app.media.ic_auto'))
                      .fillColor(Color.White)
                      .width(30)
                      .onClick(() => {
                        this.playState.playMode = 'random'
                      })
                  } else if (this.playState.playMode === 'random') {
                    Image($r('app.media.ic_random'))
                      .fillColor(Color.White)
                      .width(30)
                      .onClick(() => {
                        this.playState.playMode = 'repeat'
                      })
                  } else if (this.playState.playMode === 'repeat') {
                    Image($r('app.media.ic_repeat'))
                      .fillColor(Color.White)
                      .width(30)
                      .onClick(() => {
                        this.playState.playMode = 'auto'
                      })
                  }

                  Image($r("app.media.ic_prev"))
                    .fillColor(Color.White)
                    .width(30)
                    .onClick(()=>{
                      playerManager.prevPlay()
                    })

                  // 播放按钮
                  Image(this.playState.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
                    .fillColor(Color.White)
                    .width(50)
                    .onClick(() => {
                      this.playState.isPlay ? playerManager.paused() : playerManager.singPlay(this.playState.playList[this.playState.playIndex])
                    })
                  // 下一首
                  Image($r('app.media.ic_next'))
                    .fillColor(Color.White)
                    .width(30)
                    .onClick(()=>{
                      playerManager.nextPlay()
                    })
                  // 播放列表
                  Image($r('app.media.ic_song_list'))
                    .fillColor(Color.White)
                    .width(30)
                    .onClick(() => {
                      this.panelHeight = '50%'
                      this.panelOpacity = 1
                    })
                }
                .width('100%')
                .padding({
                  bottom: 24
                })
                .justifyContent(FlexAlign.SpaceAround)
              }
              .width('100%')
            }
            .layoutWeight(1)
            .width('100%')
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)


        // 列表
        Column() {
          Column() {

          }
          .width('100%')
          .layoutWeight(1)
          .onClick(() => {
            this.panelHeight = '0%'
            this.panelOpacity = 0
          })

          Column() {
            Row() {
              Row() {
                Image($r("app.media.ic_play"))
                  .width(20)
                  .fillColor('#ff5186')
              }
              .width(50)
              .aspectRatio(1)
              .justifyContent(FlexAlign.Center)

              Row({ space: 8 }) {
                // 反引号 => 模板字符串 => 支持 ${ 变量 }
                Text(`播放列表(${this.playState.playList.length})`)
                  .fontColor(Color.White)
                  .fontSize(14)
              }
              .layoutWeight(1)

              Image($r('app.media.ic_close'))
                .fillColor('#ffa49a9a')
                .width(24)
                .height(24)
                .margin({ right: 16 })
                .onClick(() => {
                  this.panelHeight = '0%'
                  this.panelOpacity = 0
                })
            }
            .width('100%')
            .backgroundColor('#ff353333')
            .padding(8)
            .border({
              width: { bottom: 1 },
              color: '#12ec5c87'
            })
            .borderRadius({
              topLeft: 4,
              topRight: 4
            })

            // 播放列表
            List() {
              ForEach(this.playState.playList, (item: SongItemType, index: number) => {
                ListItem() {
                  Row() {
                    Row() {
                      Text((index + 1).toString())
                        .fontColor('#ffa49a9a')
                    }
                    .width(50)
                    .aspectRatio(1)
                    .justifyContent(FlexAlign.Center)

                    // 列表
                    Row({ space: 10 }) {
                      Column() {
                        Text(item.name)
                          .fontSize(14)
                          .fontColor('#ffa49a9a')
                        Text(item.author)
                          .fontSize(12)
                          .fontColor( Color.Gray)
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)
                      .justifyContent(FlexAlign.Center)
                    }
                    .layoutWeight(1)

                    Image($r('app.media.ic_more'))
                      .width(24)
                      .height(24)
                      .margin({ right: 16 })
                      .fillColor(Color.Gray)
                  }
                  .alignItems(VerticalAlign.Center)
                  .onClick(()=>{
                    playerManager.singPlay( item)
                  })
                }
                .swipeAction({
                  end: this.deleteButton(index)
                })
                .border({
                  width: { bottom: 1 },
                  color: '#12ec5c87'
                })
              })
            }
            .layoutWeight(1)
            .backgroundColor('#ff353333')

          }
          .height(400)
        }
        .height(this.panelHeight)
        .animation({
          duration: 300
        })
        .backgroundColor('#ff353333')
        .opacity(this.panelOpacity)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

        if (this.playState.playList.length === 0) {
          this.emptyPlayer()
        }

      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)

    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
    .hideTitleBar(true)  // 隐藏标题栏
  }
}
