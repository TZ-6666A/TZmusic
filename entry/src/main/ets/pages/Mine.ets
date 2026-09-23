import { preferences } from '@kit.ArkData'
import { AppStorageV2 } from '@kit.ArkUI'
import { ListenStatsStore, ListenStatsState, LISTEN_STATS_KEY } from '../models/listenStatsStore'
import { playerManager } from '../utils/AvPlayerManager'
import { GlobalMusic } from '../models/globalMusic'
import { ReviewStore } from '../models/reviewStore'
import { ReviewItem } from '../data/reviewData'
import { KSongHistoryStore } from '../models/kSongHistoryStore'
import { UserProfileStore, UserProfileState } from '../models/UserProfileStore'

const LOGIN_STORE = 'login_store'
const KEY_LOGGED_IN = 'is_logged_in'

@ComponentV2
export struct Mine {
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!
  @Local listenStats: ListenStatsState = AppStorageV2.connect(ListenStatsState, LISTEN_STATS_KEY, () => new ListenStatsState())!
  @Local kgeCount: number = 0
  @Local playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  @Local reviewStore: ReviewStore = AppStorageV2.connect(ReviewStore, 'REVIEW_KEY', () => new ReviewStore())!
  @Local profile: UserProfileState = AppStorageV2.connect(UserProfileState, 'USER_PROFILE', () => new UserProfileState())!

  aboutToAppear(): void {
    void this.loadStats()
    void this.loadProfile()
  }

  async loadProfile(force: boolean = false): Promise<void> {
    if (this.profile.loaded && !force) return
    const p = await UserProfileStore.getProfile(getContext(this))
    this.profile.nickname = p.nickname
    this.profile.signature = p.signature
    this.profile.avatarUri = p.avatarUri
    this.profile.bgUri = p.bgUri
    this.profile.loaded = true
  }

  async loadStats(): Promise<void> {
    await ListenStatsStore.ensureLoaded(getContext(this))
    const works = await KSongHistoryStore.getAll(getContext(this))
    this.kgeCount = works.length
  }

  // 与听歌等级页绑定同一份全局数据，保证分钟数完全一致
  @Computed
  get listenMinutes(): number {
    return this.listenStats.totalMinutes
  }

  // 等级随全局听歌分钟数自动计算
  @Computed
  get currentLevel(): number {
    const minutes = this.listenMinutes
    if (minutes < 1) return 0
    if (minutes < 10) return 1
    if (minutes < 30) return 2
    if (minutes < 100) return 3
    if (minutes < 1000) return 4
    if (minutes < 5000) return 5
    return 6
  }

  getLevelColor(): string {
    const colors: string[] = ['#ccc', '#94a3b8', '#34d399', '#60a5fa', '#a78bfa', '#f472b6', '#fbbf24']
    return colors[Math.min(6, Math.max(0, this.currentLevel))]
  }

  async logout(): Promise<void> {
    await playerManager.stopAndReset()
    const prefs = await preferences.getPreferences(getContext(this), LOGIN_STORE)
    await prefs.put(KEY_LOGGED_IN, false)
    await prefs.flush()
    this.pathStack.replacePathByName('Login', null, false)
  }

  // ================= 背景图 / 头像 =================

  @Builder
  bgLayer() {
    if (this.profile.bgUri) {
      Image(this.profile.bgUri)
        .width('100%')
        .aspectRatio(16 / 9)
        .objectFit(ImageFit.Cover)
        .onClick(() => { this.pathStack.pushPathByName('ProfileEdit', null, false) })
    } else {
      Image($r('app.media.beijingtu'))
        .width('100%')
        .aspectRatio(16 / 9)
        .objectFit(ImageFit.Cover)
        .onClick(() => { this.pathStack.pushPathByName('ProfileEdit', null, false) })
    }
  }

  @Builder
  avatarCircle() {
    if (this.profile.avatarUri) {
      Image(this.profile.avatarUri)
        .width(72).height(72)
        .borderRadius(36)
        .border({ width: 3, color: Color.White })
        .shadow({ radius: 12, color: '#55000000', offsetY: 4 })
        .objectFit(ImageFit.Cover)
        .onClick(() => { this.pathStack.pushPathByName('ProfileEdit', null, false) })
    } else {
      Image($r('app.media.touxiang'))
        .width(72).height(72)
        .borderRadius(36)
        .border({ width: 3, color: Color.White })
        .shadow({ radius: 12, color: '#55000000', offsetY: 4 })
        .objectFit(ImageFit.Cover)
        .onClick(() => { this.pathStack.pushPathByName('ProfileEdit', null, false) })
    }
  }

  // ================= 数据栏 =================

  @Builder
  statItem(value: string, label: string, onClick?: () => void) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#222')
      Text(label)
        .fontSize(12).fontColor('#999')
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => { if (onClick) onClick() })
  }

  @Builder
  statsCard() {
    Row() {
      this.statItem(this.listenMinutes.toString(), '听歌分钟', () => {
        this.pathStack.pushPathByName('ListenLevel', null, false)
      })
      Column()
        .width(0.5).height(36).backgroundColor('#eee')
      this.statItem(this.kgeCount.toString(), 'K歌作品')
      Column()
        .width(0.5).height(36).backgroundColor('#eee')
      this.statItem(this.reviewStore.reviews.length.toString(), '我的歌评')
    }
    .width('100%')
    .padding({ top: 18, bottom: 18 })
    .backgroundColor(Color.White)
    .borderRadius(16)
  }

  // ================= 功能入口卡片 =================

  @Builder
  menuCard(icon: Resource, title: string, desc: string, bgColor: string, action: () => void) {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(46).height(46)
          .fill(bgColor)
        Image(icon)
          .width(22).height(22)
          .fillColor(Color.White)
      }

      Column({ space: 4 }) {
        Text(title)
          .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#222')
        Text(desc)
          .fontSize(12).fontColor('#999')
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.ic_more'))
        .width(16).height(16)
        .fillColor('#ccc')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(Color.White)
    .borderRadius(16)
    .onClick(() => { action() })
  }

  // ================= 歌评卡片 =================

  @Builder
  reviewCard(item: ReviewItem, index: number) {
    Column() {
      Row({ space: 12 }) {
        Image(item.img)
          .width(50).height(50).borderRadius(10)

        Column({ space: 3 }) {
          Text(item.name)
            .fontSize(15).fontWeight(FontWeight.Medium).fontColor('#222')
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(item.author)
            .fontSize(12).fontColor('#999')
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start)

        Text('删除')
          .fontSize(12).fontColor('#ef4444')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#fff1f2')
          .borderRadius(12)
          .onClick(() => { this.reviewStore.deleteReview(index) })
      }
      .width('100%')

      Text(item.comment)
        .fontSize(13).fontColor('#666')
        .lineHeight(20)
        .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }

  build() {
    Scroll() {
      Column() {
        // 背景图（16:9）
        this.bgLayer()

        // 顶部个人信息（负 margin 上移叠加在背景图上）
        Row() {
          Column({ space: 6 }) {
            Row({ space: 8 }) {
              Text(this.profile.nickname)
                .fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.White)
              if (this.currentLevel > 0) {
                Text('Lv' + this.currentLevel)
                  .fontSize(11).fontColor(Color.White).fontWeight(FontWeight.Medium)
                  .padding({ left: 7, right: 7, top: 2, bottom: 2 })
                  .backgroundColor(this.getLevelColor())
                  .borderRadius(7)
              }
            }
            .alignItems(VerticalAlign.Center)
            Text(this.profile.signature)
              .fontSize(13).fontColor('rgba(255,255,255,0.75)')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          this.avatarCircle()
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 24 })
        .margin({ top: -100 })

        // 内容区（白色圆角卡片，下移到背景图下方）
        Column({ space: 14 }) {
          // 统计行（直接内联在 build 主体，确保响应式刷新与 Lv 徽章一致）
          Row() {
            Column({ space: 4 }) {
              Text(this.listenMinutes.toString())
                .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#222')
              Text('听歌分钟')
                .fontSize(12).fontColor('#999')
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
            .onClick(() => { this.pathStack.pushPathByName('ListenLevel', null, false) })

            Column()
              .width(0.5).height(36).backgroundColor('#eee')

            Column({ space: 4 }) {
              Text(this.kgeCount.toString())
                .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#222')
              Text('K歌作品')
                .fontSize(12).fontColor('#999')
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)

            Column()
              .width(0.5).height(36).backgroundColor('#eee')

            Column({ space: 4 }) {
              Text(this.reviewStore.reviews.length.toString())
                .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#222')
              Text('我的歌评')
                .fontSize(12).fontColor('#999')
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .padding({ top: 18, bottom: 18 })
          .backgroundColor(Color.White)
          .borderRadius(16)

          this.menuCard(
            $r('app.media.ic_play'),
            this.playState.name ? '正在播放' : '音乐播放器',
            this.playState.name ? (this.playState.author || '点击查看') : '查看当前歌曲和播放列表',
            '#ff5186',
            () => { this.pathStack.pushPathByName('Play', null, false) }
          )

          this.menuCard(
            $r('app.media.ic_music'),
            '历史K歌',
            '查看我录的歌',
            '#7c6ff5',
            () => { this.pathStack.pushPathByName('HistoryKGe', null, false) }
          )

          if (this.reviewStore.reviews.length > 0) {
            Column({ space: 10 }) {
              Row() {
                Text('歌曲评价')
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#222')
                  .layoutWeight(1)
                Text(this.reviewStore.reviews.length.toString() + ' 条')
                  .fontSize(12).fontColor('#999')
              }
              .width('100%')
              .padding({ left: 4, right: 4 })

              ForEach(this.reviewStore.reviews, (item: ReviewItem, index: number) => {
                this.reviewCard(item, index)
              }, (item: ReviewItem, index: number) => index.toString())
            }
            .width('100%')
            .margin({ top: 4 })
          }

          this.menuCard(
            $r('app.media.ic_more'),
            '添加歌评',
            '选择歌曲并发表评价',
            '#22c55e',
            () => { this.pathStack.pushPathByName('AddReview', null, false) }
          )

          Row() {
            Text('退出登录')
              .fontSize(15).fontColor('#ef4444')
              .layoutWeight(1).textAlign(TextAlign.Center)
          }
          .width('100%')
          .height(48)
          .backgroundColor('#fff1f2')
          .borderRadius(16)
          .onClick(() => { void this.logout() })

          Row().height(20)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 40 })
        .backgroundColor('#f5f6fa')
        .borderRadius({ topLeft: 24, topRight: 24 })
        .margin({ top: -16 })
      }
      .width('100%')
    }
    .width('100%').height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor('#f5f6fa')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean) => {
      if (isVisible) {
        void this.loadStats()
      }
    })
  }
}
