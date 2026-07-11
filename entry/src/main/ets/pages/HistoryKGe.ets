import { audio } from '@kit.AudioKit'
import { fileIo } from '@kit.CoreFileKit'
import { KSongHistoryStore, KSongWork } from '../models/kSongHistoryStore'
import { playerManager } from '../utils/AvPlayerManager'

@Builder
export function HistoryKGeBuilder() {
  HistoryKGe()
}

@ComponentV2
struct HistoryKGe {
  pathStack: NavPathStack = new NavPathStack()
  @Local works: KSongWork[] = []
  @Local playingId: string = ''
  private audioRenderer: audio.AudioRenderer | null = null
  private playFd: number = -1
  private audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
    channels: audio.AudioChannel.CHANNEL_1,
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  }
  private audioRendererInfo: audio.AudioRendererInfo = {
    usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
    rendererFlags: 0
  }

  aboutToAppear(): void {
    void this.loadWorks()
  }

  aboutToDisappear(): void {
    this.releasePlayback()
  }

  async loadWorks(): Promise<void> {
    this.works = await KSongHistoryStore.getAll(getContext(this))
  }

  formatTime(seconds: number): string {
    const m = Math.floor(seconds / 60)
    const s = Math.floor(seconds % 60)
    return m.toString().padStart(2, '0') + ':' + s.toString().padStart(2, '0')
  }

  formatDate(time: number): string {
    const date = new Date(time)
    return date.getFullYear().toString() + '-' +
      (date.getMonth() + 1).toString().padStart(2, '0') + '-' +
      date.getDate().toString().padStart(2, '0')
  }

  clearBufferTail(buffer: ArrayBuffer, start: number): void {
    if (start < buffer.byteLength) {
      const data = new Uint8Array(buffer)
      data.fill(0, start)
    }
  }

  scheduleReleasePlayback(): void {
    setTimeout(() => {
      this.releasePlayback()
    }, 60)
  }

  releasePlayback(): void {
    if (this.audioRenderer) {
      this.audioRenderer.stop()
      this.audioRenderer.release()
      this.audioRenderer = null
    }
    if (this.playFd >= 0) {
      fileIo.closeSync(this.playFd)
      this.playFd = -1
    }
    this.playingId = ''
  }

  async playWork(item: KSongWork): Promise<void> {
    if (this.playingId === item.id) {
      this.releasePlayback()
      return
    }

    try {
      playerManager.paused()
      this.releasePlayback()

      const stat = fileIo.statSync(item.filePath)
      if (stat.size <= 0) {
        console.error('history record file is empty: ' + item.filePath)
        this.releasePlayback()
        return
      }
      const file = fileIo.openSync(item.filePath, fileIo.OpenMode.READ_ONLY)
      this.playFd = file.fd
      this.playingId = item.id

      const renderer = await audio.createAudioRenderer({
        streamInfo: this.audioStreamInfo,
        rendererInfo: this.audioRendererInfo
      })
      this.audioRenderer = renderer
      let readSize = 0
      renderer.on('writeData', (buffer: ArrayBuffer) => {
        if (this.playFd < 0) {
          return
        }
        const readLength = fileIo.readSync(this.playFd, buffer)
        if (readLength <= 0) {
          this.scheduleReleasePlayback()
          return
        }
        this.clearBufferTail(buffer, readLength)
        readSize += readLength
        if (readSize >= stat.size) {
          this.scheduleReleasePlayback()
        }
      })
      await renderer.start()
    } catch (err) {
      console.error('HistoryKGe open failed: ' + JSON.stringify(err))
      this.releasePlayback()
    }
  }

  async deleteWork(item: KSongWork): Promise<void> {
    try {
      if (this.playingId === item.id) {
        this.releasePlayback()
      }
      const removed = await KSongHistoryStore.remove(getContext(this), item.id)
      if (removed) {
        try {
          fileIo.unlinkSync(removed.filePath)
        } catch (err) {
          console.error('HistoryKGe delete file failed: ' + JSON.stringify(err))
        }
      }
      this.works = this.works.filter((work: KSongWork) => work.id !== item.id)
    } catch (err) {
      console.error('HistoryKGe delete failed: ' + JSON.stringify(err))
    }
  }

  @Builder
  deleteButton(item: KSongWork) {
    Button('删除')
      .backgroundColor('#ff4d62')
      .fontColor(Color.White)
      .width(74)
      .height('100%')
      .type(ButtonType.Normal)
      .onClick(() => {
        void this.deleteWork(item)
      })
  }

  @Builder
  workItem(item: KSongWork) {
    Row({ space: 12 }) {
      Image(item.img)
        .width(58)
        .height(58)
        .borderRadius(10)

      Column({ space: 5 }) {
        Text(item.songName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#222')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.author + ' · ' + this.formatTime(item.duration) + ' · ' + this.formatDate(item.createdAt))
          .fontSize(12)
          .fontColor('#999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row() {
        if (this.playingId === item.id) {
          Row({ space: 4 }) {
            Row()
              .width(4)
              .height(15)
              .borderRadius(2)
              .backgroundColor(Color.White)
            Row()
              .width(4)
              .height(15)
              .borderRadius(2)
              .backgroundColor(Color.White)
          }
        } else {
          Image($r('app.media.ic_play'))
            .width(16)
            .height(16)
            .fillColor(Color.White)
        }
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor(this.playingId === item.id ? '#222' : '#ff5186')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius(14)
    .onClick(() => {
      void this.playWork(item)
    })
  }

  build() {
    NavDestination() {
      Column() {
        Row({ space: 12 }) {
          Image($r('app.media.ic_back'))
            .width(22)
            .height(22)
            .fillColor('#222')
            .onClick(() => {
              this.releasePlayback()
              this.pathStack.pop()
            })
          Text('历史K歌')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222')
            .layoutWeight(1)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor(Color.White)

        if (this.works.length === 0) {
          Column({ space: 12 }) {
            Image($r('app.media.ic_music'))
              .width(70)
              .height(70)
              .fillColor('#dddddd')
            Text('还没有录过歌')
              .fontSize(17)
              .fontColor('#999')
            Text('去 K歌 页面录一首，作品会出现在这里')
              .fontSize(13)
              .fontColor('#bbbbbb')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 10 }) {
            ForEach(this.works, (item: KSongWork) => {
          ListItem() {
            this.workItem(item)
          }
          .swipeAction({
            end: this.deleteButton(item)
          })
        }, (item: KSongWork) => item.id)
      }
          .layoutWeight(1)
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f7f8fb')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
    .hideTitleBar(true)
  }
}

