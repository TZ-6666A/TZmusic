//推荐页面
import { AppStorageV2, promptAction } from '@kit.ArkUI';
import { SongItemType } from '../models/music'
import { playerManager } from '../utils/AvPlayerManager'
import { dailyRecommend as dailyRecommendData, recommendDailyType, recommendList as recommendListData, recommendListType, searchSongs as searchSongsData, swiperList as swiperListData } from '../data/recommendData'

@Component
  // export 导出，别的组件才可以导入去使用
  //推荐页的轮播组件
export struct Recommend {
  @State searchValue: string = ''


  swiperList: Resource[] = swiperListData
  dailyRecommend: recommendDailyType[] = dailyRecommendData
  recommendList: recommendListType[] = recommendListData
  searchSongs: SongItemType[] = searchSongsData


  // 导航控制
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!

  findSongByKeyword(keyword: string): SongItemType | null {
    const value = keyword.trim().toLowerCase()
    if (!value) {
      return null
    }
    for (const playlist of this.dailyRecommend) {
      const matched = playlist.songs.find((song: SongItemType) => {
        return song.name.toLowerCase().includes(value)
      })
      if (matched) {
        return matched
      }
    }
    const matchedExtra = this.searchSongs.find((song: SongItemType) => {
      return song.name.toLowerCase().includes(value)
    })
    if (matchedExtra) {
      return matchedExtra
    }
    return null
  }

  searchAndPlay(): void {
    const song = this.findSongByKeyword(this.searchValue)
    if (!song) {
      promptAction.showToast({ message: '暂无此歌曲版权，敬请期待' })
      return
    }
    this.pathStack.pushPathByName('Play', null, false)
    void playerManager.singPlay(song)
  }

  //标题模板
  @Builder
  titleBuilder(title: string) {
    Row() {
      Text(title)
        .fontColor(Color.Black)
        .fontWeight(700)
        .layoutWeight(1)
      Image($r('app.media.ic_more'))
        .width(22)
        .fillColor(Color.Black)
    }
    .width('100%')
    .height(40)
  }

  build() {
    Scroll() { // 新增：外层包裹垂直滚动容器
      Column({ space: 10 }) {
        // 搜索区域
        Row() {
          Image($r('app.media.ic_code'))
            .width(20)
            .fillColor('#817D83')
          TextInput({ placeholder: '搜索歌曲', text: this.searchValue })
            .placeholderColor('#817D83')
            .padding({ left: 5 })
            .fontColor('#999')
            .layoutWeight(1)
            .onChange((value: string) => {
              this.searchValue = value
            })
            .onSubmit(() => {
              this.searchAndPlay()
            })
          Image($r('app.media.ic_search'))
            .width(22)
            .fillColor('#817D83')
            .onClick(() => {
              this.searchAndPlay()
            })
        }
        .width('100%')
        .backgroundColor('#2D2B29')
        .border({ radius: 20 })
        .padding({ left: 8, right: 8 })

        // 轮播图区域
        Swiper() {
          ForEach(this.swiperList, (item: Resource) => {
            Image(item)
              .width('100%')
              .border({ radius: 10 })
          })
        }
        .autoPlay(true)

        // 每日推荐区域
        this.titleBuilder('歌单推荐')
        List() {
          ForEach(this.dailyRecommend, (item: recommendDailyType) => {
            ListItem() {
              Column() {
                Image(item.img)
                  .width(200)
                  .height(180)
                Text(item.title)
                  .width('100%')
                  .backgroundColor(item.bottom)
                  .padding(5)
                  .fontSize(14)
                  .fontColor('#fff')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('40%')
              .border({ radius: 10 })
              .margin({ right: 10 })
              .clip(true)
            }
            .onClick(() => {
              this.pathStack.pushPathByName('PlayList', item, false)
            })
          })
        }
        .listDirection(Axis.Horizontal)
        .height(230)
        .scrollBar(BarState.Off)

        // 热门歌手区域
        this.titleBuilder('热门歌手')
        List() {
          ForEach(this.recommendList, (item: recommendListType) => {
            ListItem() {
              Column() {
                Stack({ alignContent: Alignment.TopStart }) {
                  Image(item.img)
                    .width('100%')
                    .height(100)
                    .border({ radius: 8 })
                  Text(item.count)
                    .fontColor(Color.White)
                    .fontSize(12)
                    .fontWeight(700)
                    .margin(5)
                }


                Text(item.title)
                  .fontColor(Color.Black)
                  .fontSize(14)
                  .width('100%')
                  .padding(5)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('30%')
              .margin({ right: 10 })
            }
            .onClick(() => {
              this.pathStack.pushPathByName('SingerDetail', item, false)
            })
          })
        }
        .listDirection(Axis.Horizontal)
        .height(150)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      // 移除了原Column的 .height('100%')，让高度随内容撑开
      .padding({
        left: 10,
        right: 10,
        top: 5,
        bottom: 5
      })
    }
    .width('100%')
   .height("100%") // Scroll 占满屏幕高度
    .scrollBar(BarState.Off) // 可选：隐藏垂直滚动条
    .edgeEffect(EdgeEffect.Spring)

  }
}
