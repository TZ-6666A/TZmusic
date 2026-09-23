//评论添加页面
import { AppStorageV2, promptAction } from '@kit.ArkUI'
import { ReviewStore } from '../models/reviewStore'
import { ReviewItem, reviewSongs } from '../data/reviewData'

@Builder
export function AddReviewBuilder() {
  AddReview()
}

@ComponentV2
struct AddReview {
  pathStack: NavPathStack = new NavPathStack()
  @Local reviewStore: ReviewStore = AppStorageV2.connect(ReviewStore, 'REVIEW_KEY', () => new ReviewStore())!
  @Local selectedIndex: number = 0
  @Local inputText: string = ''

  //发布评论函数
  publish(): void {
    const text = this.inputText.trim()
    if (!text) {
      promptAction.showToast({ message: '请先输入歌评内容' })
      return
    }
    this.reviewStore.addReview(reviewSongs[this.selectedIndex], text)
    this.inputText = ''
    promptAction.showToast({ message: '歌评发表成功' })
    this.pathStack.pop()
  }

  @Builder
  songCard(item: ReviewItem, index: number) {
    Column({ space: 8 }) {
      Image(item.img)
        .width(118)
        .height(118)
        .objectFit(ImageFit.Cover)
        .borderRadius(12)

      Text(item.name)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.selectedIndex === index ? '#ff5186' : '#222')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Text(item.author)
        .fontSize(12)
        .fontColor('#999')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .width(142)
    .padding(12)
    .backgroundColor(this.selectedIndex === index ? '#fff1f6' : '#f8f8f8')
    .border({
      width: this.selectedIndex === index ? 1 : 0,
      color: this.selectedIndex === index ? '#ffd3e2' : '#f8f8f8'
    })
    .borderRadius(16)
    .onClick(() => {
      this.selectedIndex = index
    })
  }

  build() {
    NavDestination() {
      Column() {
        Text('添加歌评')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222')
          .width('100%')
          .padding({ left: 18, right: 18, top: 18, bottom: 12 })

        List({ space: 12 }) {
          ForEach(reviewSongs, (item: ReviewItem, index: number) => {
            ListItem() {
              this.songCard(item, index)
            }
          })
        }
        .width('100%')
        .height(190)
        .padding({ left: 18, right: 18 })
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)

        Column({ space: 14 }) {
          Text('评价歌曲')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222')
            .width('100%')

          Text(reviewSongs[this.selectedIndex].name + ' - ' + reviewSongs[this.selectedIndex].author)
            .fontSize(13)
            .fontColor('#999')
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          TextArea({ placeholder: '写下你对这首歌的评价...', text: this.inputText })
            .width('100%')
            .height(150)
            .fontSize(15)
            .fontColor('#333')
            .placeholderColor('#aaa')
            .backgroundColor('#f8f8f8')
            .borderRadius(14)
            .padding(12)
            .onChange((value: string) => {
              this.inputText = value
            })

          Button('发表歌评')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor('#ff5186')
            .borderRadius(16)
            .onClick(() => {
              this.publish()
            })

          Button('返回')
            .width('100%')
            .height(46)
            .fontSize(15)
            .fontColor('#333')
            .backgroundColor('#f1f1f1')
            .borderRadius(16)
            .onClick(() => {
              this.pathStack.pop()
            })
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 18, right: 18, top: 18, bottom: 24 })
        .backgroundColor(Color.White)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
    //
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}
