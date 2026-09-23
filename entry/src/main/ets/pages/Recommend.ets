//推荐页面（大厅页面）
import { AppStorageV2, promptAction } from '@kit.ArkUI';
import { SongItemType } from '../models/music'
import { playerManager } from '../utils/AvPlayerManager'
import { dailyRecommend as dailyRecommendData, recommendDailyType, recommendList as recommendListData, recommendListType, searchSongs as searchSongsData, swiperList as swiperListData } from '../data/recommendData'

@ComponentV2
  // export 导出，别的组件才可以导入去使用
  //推荐页的轮播组件
export struct Recommend {
  @Local searchValue: string = ''


  swiperList: Resource[] = swiperListData
  dailyRecommend: recommendDailyType[] = dailyRecommendData
  recommendList: recommendListType[] = recommendListData
  searchSongs: SongItemType[] = searchSongsData


  // 导航控制
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!

  //搜索歌曲原理
  findSongByKeyword(keyword: string): SongItemType | null {
    //trim:去空格  toLowerCase:变小写
    const value = keyword.trim().toLowerCase()
    if (!value) {
      return null
    }
    for (const playlist of this.dailyRecommend) {
      const matched = playlist.songs.find((song: SongItemType) => {
        //includes:查看歌名里面有没有包含用户输入的字
        return song.name.toLowerCase().includes(value)
      })
      if (matched) {
        return matched
      }
    }
    //推荐页面没找到，去备用歌库去找
    const matchedExtra = this.searchSongs.find((song: SongItemType) => {
      return song.name.toLowerCase().includes(value)
    })
    if (matchedExtra) {
      return matchedExtra
    }
    return null
  }

  searchAndPlay(): void {
    const keyword = this.searchValue.trim()
    if (!keyword) {
      promptAction.showToast({ message: '请输入歌名' })
      return
    }
    const song = this.findSongByKeyword(keyword)
    if (!song) {
      promptAction.showToast({ message: '暂无此歌曲版权，敬请期待' })
      return
    }
    //页面跳转，把这首歌交给播放器，让它开始播放。
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
        // 搜索区域（背景铺满整栏、左右贴边）
        Row() {
          Search({ value: this.searchValue, placeholder: '搜索歌曲' })
            .searchButton('搜索')
            .width('100%')
            .height(48)
            .backgroundColor('#f5f6fa')
            .placeholderColor('#817D83')
            .fontColor('#333')
            .borderRadius(16)
            .border({ width: 1, color: '#e0e0e0' })
            .onSubmit((value: string) => {
              this.searchValue = value
              this.searchAndPlay()
            })
            .onChange((value: string) => {
              this.searchValue = value
            })
        }
        .width('100%')
        .height(64)
        // 抵消外层 Column 的左右 10px padding，让搜索栏与屏幕同宽、左右贴边
        .margin({ left: -10, right: -10 })

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
        bottom: 60
      })
    }
    .width('100%')
   .height("100%") // Scroll 占满屏幕高度
    .scrollBar(BarState.Off) // 可选：隐藏垂直滚动条
    .edgeEffect(EdgeEffect.Spring)

  }
}
