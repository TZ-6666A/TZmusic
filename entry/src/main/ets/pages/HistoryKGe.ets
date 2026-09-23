import { audio } from '@kit.AudioKit'
import { media } from '@kit.MediaKit'
import { fileIo } from '@kit.CoreFileKit'
import { promptAction } from '@kit.ArkUI'
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
  @Local selectMode: boolean = false
  @Local selectedIds: string[] = []
  private audioRenderer: audio.AudioRenderer | null = null
  private previewPlayer: media.AVPlayer | null = null
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
    if (this.previewPlayer) {
      try { this.previewPlayer.stop(); this.previewPlayer.release() } catch (err) { /* ignore */ }
      this.previewPlayer = null
    }
    if (this.audioRenderer) {
      try { this.audioRenderer.stop(); this.audioRenderer.release() } catch (err) { /* ignore */ }
      this.audioRenderer = null
    }
    if (this.playFd >= 0) {
      fileIo.closeSync(this.playFd)
      this.playFd = -1
    }
    this.playingId = ''
  }

  private playWav(item: KSongWork): void {
    try {
      const player = media.createAVPlayer()
      player.then((p: media.AVPlayer) => {
        p.on('stateChange', (state: string) => {
          if (state === 'initialized') p.prepare()
          else if (state === 'prepared') p.play()
          else if (state === 'completed' || state === 'error') this.releasePlayback()
        })
        p.url = 'file://' + item.filePath
        this.previewPlayer = p
        this.playingId = item.id
      }).catch((err: Error) => {
        console.error('HistoryKGe create player failed: ' + JSON.stringify(err))
        this.releasePlayback()
      })
    } catch (err) {
      this.releasePlayback()
    }
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
      if (stat.size <= 0) { this.releasePlayback(); return }
      if (item.filePath.endsWith('.wav')) {
        this.playWav(item)
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
        if (this.playFd < 0) return
        const readLength = fileIo.readSync(this.playFd, buffer)
        if (readLength <= 0) { this.scheduleReleasePlayback(); return }
        this.clearBufferTail(buffer, readLength)
        readSize += readLength
        if (readSize >= stat.size) { this.scheduleReleasePlayback() }
      })
      await renderer.start()
    } catch (err) {
      this.releasePlayback()
    }
  }

  async deleteWork(item: KSongWork): Promise<void> {
    try {
      if (this.playingId === item.id) this.releasePlayback()
      const removed = await KSongHistoryStore.remove(getContext(this), item.id)
      if (removed) {
        try { fileIo.unlinkSync(removed.filePath) } catch (err) { /* ignore */ }
      }
      this.works = this.works.filter((work: KSongWork) => work.id !== item.id)
    } catch (err) { /* ignore */ }
  }

  // ================= 多选删除 =================

  enterSelectMode(): void {
    this.selectMode = true
    this.selectedIds = []
  }

  exitSelectMode(): void {
    this.selectMode = false
    this.selectedIds = []
  }

  toggleSelect(id: string): void {
    const idx = this.selectedIds.indexOf(id)
    if (idx >= 0) {
      this.selectedIds.splice(idx, 1)
    } else {
      this.selectedIds.push(id)
    }
  }

  isSelected(id: string): boolean {
    return this.selectedIds.indexOf(id) >= 0
  }

  get isAllSelected(): boolean {
    return this.works.length > 0 && this.selectedIds.length === this.works.length
  }

  toggleSelectAll(): void {
    if (this.isAllSelected) {
      this.selectedIds = []
    } else {
      this.selectedIds = this.works.map((w: KSongWork) => w.id)
    }
  }

  async deleteSelected(): Promise<void> {
    if (this.selectedIds.length === 0) return
    const count = this.selectedIds.length
    for (const id of this.selectedIds) {
      const item = this.works.find((w: KSongWork) => w.id === id)
      if (item) {
        if (this.playingId === id) this.releasePlayback()
        const removed = await KSongHistoryStore.remove(getContext(this), id)
        if (removed) {
          try { fileIo.unlinkSync(removed.filePath) } catch (err) { /* ignore */ }
        }
      }
    }
    this.works = this.works.filter((w: KSongWork) => this.selectedIds.indexOf(w.id) < 0)
    this.selectedIds = []
    promptAction.showToast({ message: '已删除 ' + count + ' 个作品' })
    if (this.works.length === 0) {
      this.selectMode = false
    }
  }

  @Builder
  workItem(item: KSongWork) {
    Row({ space: 12 }) {
      if (this.selectMode) {
        // 复选框
        Row() {
          if (this.isSelected(item.id)) {
            Text('✓')
              .fontSize(14).fontColor(Color.White).fontWeight(FontWeight.Bold)
          }
        }
        .width(22).height(22).borderRadius(11)
        .borderWidth(this.isSelected(item.id) ? 0 : 1.5)
        .borderColor('#ccc')
        .backgroundColor(this.isSelected(item.id) ? '#ff5186' : Color.White)
        .justifyContent(FlexAlign.Center)
      }

      Image(item.img)
        .width(58).height(58).borderRadius(10)

      Column({ space: 5 }) {
        Text(item.songName)
          .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#222')
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.author + ' · ' + this.formatTime(item.duration) + ' · ' + this.formatDate(item.createdAt))
          .fontSize(12).fontColor('#999')
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)

      if (!this.selectMode) {
        Row() {
          if (this.playingId === item.id) {
            Row({ space: 4 }) {
              Row().width(4).height(15).borderRadius(2).backgroundColor(Color.White)
              Row().width(4).height(15).borderRadius(2).backgroundColor(Color.White)
            }
          } else {
            Image($r('app.media.ic_play'))
              .width(16).height(16).fillColor(Color.White)
          }
        }
        .width(36).height(36).borderRadius(18)
        .backgroundColor(this.playingId === item.id ? '#222' : '#ff5186')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.isSelected(item.id) ? '#fff0f5' : Color.White)
    .borderRadius(14)
    .onClick(() => {
      if (this.selectMode) {
        this.toggleSelect(item.id)
      } else {
        void this.playWork(item)
      }
    })
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row({ space: 12 }) {
          if (this.selectMode) {
            Text('取消')
              .fontSize(16).fontColor('#666')
              .onClick(() => { this.exitSelectMode() })
          } else {
            Image($r('app.media.ic_back'))
              .width(22).height(22).fillColor('#333')
              .onClick(() => {
                this.releasePlayback()
                this.pathStack.pop()
              })
          }

          if (this.selectMode) {
            Text('已选 ' + this.selectedIds.length + ' 项')
              .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#222')
              .layoutWeight(1)
            Text(this.isAllSelected ? '取消全选' : '全选')
              .fontSize(15).fontColor('#ff5186')
              .onClick(() => { this.toggleSelectAll() })
          } else {
            Text('历史K歌')
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#222')
              .layoutWeight(1)
            if (this.works.length > 0) {
              Text('管理')
                .fontSize(15).fontColor('#555')
                .onClick(() => { this.enterSelectMode() })
            }
          }
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .backgroundColor(Color.White)
        .shadow({ radius: 6, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 2 })

        if (this.works.length === 0) {
          Column({ space: 12 }) {
            Image($r('app.media.ic_music'))
              .width(70).height(70).fillColor('#dddddd')
            Text('还没有录过歌')
              .fontSize(17).fontColor('#999')
            Text('去 K歌 页面录一首，作品会出现在这里')
              .fontSize(13).fontColor('#bbbbbb')
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
        } else {
          List({ space: 10 }) {
            ForEach(this.works, (item: KSongWork) => {
              ListItem() {
                this.workItem(item)
              }
            }, (item: KSongWork) => item.id)
          }
          .layoutWeight(1)
          .padding({ left: 14, right: 14, top: 12, bottom: this.selectMode ? 80 : 12 })
          .scrollBar(BarState.Off)
        }

        // 多选模式底部删除栏
        if (this.selectMode && this.works.length > 0) {
          Row() {
            Button('删除')
              .width('100%').height(48)
              .backgroundColor(this.selectedIds.length > 0 ? '#ff4d62' : '#ddd')
              .fontColor(Color.White)
              .fontSize(16)
              .enabled(this.selectedIds.length > 0)
              .onClick(() => { void this.deleteSelected() })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 36 })
          .backgroundColor(Color.White)
          .border({ width: { top: 0.5 }, color: '#eee' })
        }
      }
      .width('100%').height('100%')
      .backgroundColor('#f7f8fb')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
    .hideTitleBar(true)
  }
}
