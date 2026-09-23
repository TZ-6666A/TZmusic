// K歌录音页（清K模式：原唱静音驱动歌词 + 原始单声道录音逻辑）
import { fileIo } from '@kit.CoreFileKit'
import { abilityAccessCtrl } from '@kit.AbilityKit'
import { audio } from '@kit.AudioKit'
import { media } from '@kit.MediaKit'
import { SongItemType } from '../models/music'
import { playerManager } from '../utils/AvPlayerManager'
import { KSongHistoryStore } from '../models/kSongHistoryStore'

interface RecordParams {
  song: SongItemType
}

@Builder
export function RecordBuilder() {
  RecordPage()
}

@ComponentV2
struct RecordPage {
  pathStack: NavPathStack = new NavPathStack()
  @Local song: SongItemType = { img: '', name: '', author: '', url: '', id: '' } as SongItemType
  @Local lyricLines: string[] = []
  @Local playPosition: number = 0
  @Local duration: number = 0
  @Local musicVolume: number = 20
  @Local isPlaying: boolean = false
  @Local currentLine: number = 0
  @Local showSheet: boolean = false
  @Local recordState: number = 0          // 0 准备 / 1 录制中 / 2 录制完成
  @Local recordSeconds: number = 0
  @Local dotVisible: boolean = true
  @Local isPreviewPlaying: boolean = false
  @Local errorText: string = ''

  // ---- 原唱播放器（静音驱动歌词）----
  private bgPlayer: media.AVPlayer | null = null

  // ---- 原始录音逻辑 ----
  private audioCapturer: audio.AudioCapturer | null = null
  private audioRenderer: audio.AudioRenderer | null = null
  private recordPath: string = ''
  private recordFd: number = -1
  private playFd: number = -1
  private timerId: number = -1
  private dotTimerId: number = -1
  private lyricScroller: Scroller = new Scroller()
  private lastLine: number = -1

  private audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
    channels: audio.AudioChannel.CHANNEL_1,
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  }
  private audioCapturerInfo: audio.AudioCapturerInfo = {
    source: audio.SourceType.SOURCE_TYPE_MIC,
    capturerFlags: 0
  }
  private audioRendererInfo: audio.AudioRendererInfo = {
    usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
    rendererFlags: 0
  }

  aboutToAppear(): void {
    const context = getContext(this)
    this.recordPath = context.filesDir + '/record_' + Date.now() + '.pcm'
  }

  aboutToDisappear(): void {
    this.releaseAll()
  }

  releaseAll(): void {
    this.stopTimers()
    this.releasePlayback()
    if (this.audioCapturer) {
      try { this.audioCapturer.release() } catch (e) { /* ignore */ }
      this.audioCapturer = null
    }
    if (this.recordFd >= 0) {
      fileIo.closeSync(this.recordFd)
      this.recordFd = -1
    }
    if (this.bgPlayer) {
      try { this.bgPlayer.release() } catch (e) { /* ignore */ }
      this.bgPlayer = null
    }
    this.isPlaying = false
  }

  releasePlayback(): void {
    if (this.audioRenderer) {
      try { this.audioRenderer.release() } catch (e) { /* ignore */ }
      this.audioRenderer = null
    }
    if (this.playFd >= 0) {
      fileIo.closeSync(this.playFd)
      this.playFd = -1
    }
    this.isPreviewPlaying = false
  }

  stopTimers(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
    if (this.dotTimerId >= 0) {
      clearInterval(this.dotTimerId)
      this.dotTimerId = -1
    }
  }

  formatTime(seconds: number): string {
    if (seconds < 0) seconds = 0
    const m = Math.floor(seconds / 60)
    const s = Math.floor(seconds % 60)
    return m.toString().padStart(2, '0') + ':' + s.toString().padStart(2, '0')
  }

  // ================= 原唱播放（静音驱动歌词）=================

  async startBgPlayer(): Promise<void> {
    playerManager.paused()
    if (this.bgPlayer) {
      try { await this.bgPlayer.release() } catch (e) { /* ignore */ }
      this.bgPlayer = null
    }
    const p = await media.createAVPlayer()
    p.on('stateChange', (state: string) => {
      if (state === 'initialized') p.prepare()
      else if (state === 'prepared') { p.setVolume(this.musicVolume / 100); p.play() }
      else if (state === 'playing') this.isPlaying = true
      else if (state === 'paused') this.isPlaying = false
    })
    p.on('timeUpdate', (time: number) => {
      this.playPosition = time
      this.updateCurrentLine()
    })
    p.on('durationUpdate', (dur: number) => {
      this.duration = dur
    })
    const ctx = getContext(this)
    if (this.song.rawFile) {
      try {
        const rawFd = await ctx.resourceManager.getRawFd(this.song.rawFile)
        p.fdSrc = { fd: rawFd.fd, offset: rawFd.offset, length: rawFd.length }
      } catch (e) {
        p.url = typeof this.song.url === 'string' ? this.song.url : ''
      }
    } else {
      p.url = typeof this.song.url === 'string' ? this.song.url : ''
    }
    this.bgPlayer = p
  }

  async toggleBgPlay(): Promise<void> {
    if (!this.bgPlayer) return
    try {
      if (this.bgPlayer.state === 'playing') {
        await this.bgPlayer.pause()
      } else if (this.bgPlayer.state === 'paused') {
        await this.bgPlayer.play()
      }
    } catch (e) { /* ignore */ }
  }

  async seekBg(value: number): Promise<void> {
    this.playPosition = value
    try {
      if (this.bgPlayer && this.bgPlayer.state === 'playing') {
        await this.bgPlayer.seek(value)
      }
    } catch (e) { /* ignore */ }
  }

  async setBgVolume(value: number): Promise<void> {
    this.musicVolume = value
    try {
      if (this.bgPlayer) {
        await this.bgPlayer.setVolume(value / 100)
      }
    } catch (e) { /* ignore */ }
  }

  // ================= 歌词高亮 =================

  updateCurrentLine(): void {
    if (this.lyricLines.length === 0) return
    const posSec = this.playPosition / 1000
    const durSec = this.duration / 1000
    let line = 0
    const timestamps = this.song.lyricTimestamps
    if (timestamps && timestamps.length === this.lyricLines.length && durSec > 0) {
      for (let i = 0; i < timestamps.length; i++) {
        if (timestamps[i] <= posSec) line = i
        else break
      }
    } else if (durSec > 0) {
      const weights: number[] = this.lyricLines.map((l: string) => Math.max(2, l.trim().length))
      const total: number = weights.reduce((a: number, b: number) => a + b, 0)
      let acc = 0
      line = weights.length - 1
      for (let i = 0; i < weights.length; i++) {
        acc += weights[i] / total * durSec
        if (posSec < acc) { line = i; break }
      }
    }
    if (line >= this.lyricLines.length) line = this.lyricLines.length - 1
    if (line < 0) line = 0
    this.currentLine = line
    if (line !== this.lastLine) {
      this.lastLine = line
      this.lyricScroller.scrollToIndex(line, true, ScrollAlign.CENTER)
    }
  }

  // ================= 原始录音逻辑 =================

  boostPcmBuffer(buffer: ArrayBuffer): ArrayBuffer {
    const input = new Int16Array(buffer)
    const output = new Int16Array(input.length)
    let peak = 0
    for (let i = 0; i < input.length; i++) {
      const value = Math.abs(input[i])
      if (value > peak) peak = value
    }
    if (peak < 20) {
      output.fill(0)
      return output.buffer
    }
    if (peak === 0) return buffer
    const gain = Math.min(14000 / peak, 60)
    for (let i = 0; i < input.length; i++) {
      let value = Math.round(input[i] * gain)
      if (value > 32767) value = 32767
      else if (value < -32768) value = -32768
      output[i] = value
    }
    return output.buffer
  }

  clearBufferTail(buffer: ArrayBuffer, start: number): void {
    if (start < buffer.byteLength) {
      const data = new Uint8Array(buffer)
      data.fill(0, start)
    }
  }

  scheduleStopPlayback(): void {
    setTimeout(() => {
      void this.stopPlayback()
    }, 60)
  }

  resetRecording(): void {
    this.releasePlayback()
    this.recordState = 0
    this.recordSeconds = 0
    this.isPreviewPlaying = false
    this.errorText = ''
    this.recordPath = getContext(this).filesDir + '/record_' + Date.now() + '.pcm'
  }

  async startRecording(): Promise<void> {
    try {
      this.releasePlayback()
      this.errorText = '正在请求麦克风权限...'

      const atManager = abilityAccessCtrl.createAtManager()
      const grantStatus = await atManager.requestPermissionsFromUser(
        getContext(this), ['ohos.permission.MICROPHONE']
      )
      if (grantStatus.authResults[0] !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.errorText = '麦克风权限未开启，无法录音'
        return
      }

      this.recordSeconds = 0
      this.errorText = '正在启动录音...'
      const file = fileIo.openSync(this.recordPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
      this.recordFd = file.fd

      const capturer = await audio.createAudioCapturer({
        streamInfo: this.audioStreamInfo,
        capturerInfo: this.audioCapturerInfo
      })
      capturer.on('readData', (buffer: ArrayBuffer) => {
        if (this.recordFd >= 0) {
          const boostedBuffer = this.boostPcmBuffer(buffer)
          fileIo.writeSync(this.recordFd, boostedBuffer)
        }
      })
      await capturer.start()
      this.audioCapturer = capturer
      this.recordState = 1
      this.errorText = ''

      this.timerId = setInterval(() => {
        this.recordSeconds++
      }, 1000)

      this.dotTimerId = setInterval(() => {
        this.dotVisible = !this.dotVisible
      }, 500)
    } catch (e) {
      this.stopTimers()
      if (this.audioCapturer) {
        try { await this.audioCapturer.release() } catch (err) { /* ignore */ }
        this.audioCapturer = null
      }
      if (this.recordFd >= 0) {
        fileIo.closeSync(this.recordFd)
        this.recordFd = -1
      }
      this.errorText = '录音启动失败，请检查麦克风权限'
      this.recordState = 0
    }
  }

  async stopRecording(): Promise<void> {
    try {
      this.stopTimers()
      this.dotVisible = true
      if (this.audioCapturer) {
        await this.audioCapturer.stop()
        await this.audioCapturer.release()
        this.audioCapturer = null
      }
      if (this.recordFd >= 0) {
        fileIo.closeSync(this.recordFd)
        this.recordFd = -1
      }
      const stat = fileIo.statSync(this.recordPath)
      if (stat.size <= 0) {
        this.recordState = 0
        this.errorText = '没有录到声音，请重新录制'
        return
      }
      this.recordState = 2
      this.errorText = ''
      await KSongHistoryStore.add(getContext(this), {
        id: Date.now().toString(),
        songName: this.song.name,
        author: this.song.author,
        img: typeof this.song.img === 'string' ? this.song.img : '',
        filePath: this.recordPath,
        duration: this.recordSeconds,
        createdAt: Date.now()
      })
    } catch (e) {
      this.errorText = '停止录音失败，请重试'
    }
  }

  async playRecording(): Promise<void> {
    try {
      this.releasePlayback()
      const stat = fileIo.statSync(this.recordPath)
      if (stat.size <= 0) return
      this.isPreviewPlaying = true
      this.errorText = ''

      const file = fileIo.openSync(this.recordPath, fileIo.OpenMode.READ_ONLY)
      this.playFd = file.fd
      const renderer = await audio.createAudioRenderer({
        streamInfo: this.audioStreamInfo,
        rendererInfo: this.audioRendererInfo
      })
      this.audioRenderer = renderer
      let readSize = 0
      renderer.on('writeData', (buffer: ArrayBuffer) => {
        if (this.playFd < 0) return
        const readLength = fileIo.readSync(this.playFd, buffer)
        if (readLength <= 0) {
          this.scheduleStopPlayback()
          return
        }
        this.clearBufferTail(buffer, readLength)
        readSize += readLength
        if (readSize >= stat.size) {
          this.scheduleStopPlayback()
        }
      })
      await renderer.start()
    } catch (e) {
      this.errorText = '试听失败，请重新录制'
      this.releasePlayback()
    }
  }

  async stopPlayback(): Promise<void> {
    if (this.audioRenderer) {
      try { await this.audioRenderer.stop(); await this.audioRenderer.release() } catch (e) { /* ignore */ }
      this.audioRenderer = null
    }
    if (this.playFd >= 0) {
      fileIo.closeSync(this.playFd)
      this.playFd = -1
    }
    this.isPreviewPlaying = false
  }

  // ================= 页面主体 =================

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Text('K歌')
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor(Color.White)
            .width('100%')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 30 })

        // 歌曲信息
        Row({ space: 14 }) {
          Image(this.song.img)
            .width(60).height(60).borderRadius(12)
            .shadow({ radius: 8, color: 'rgba(0,0,0,0.35)', offsetX: 0, offsetY: 2 })
          Column({ space: 5 }) {
            Text(this.song.name)
              .fontSize(19).fontWeight(FontWeight.Bold).fontColor('#fff')
              .maxLines(1)
            Text(this.song.author)
              .fontSize(13).fontColor('#aaa')
            Row({ space: 7 }) {
              Row()
                .width(8).height(8).borderRadius(4)
                .backgroundColor(this.recordState === 1 ? '#ff4d62' : '#46e6a0')
                .opacity(this.recordState === 1 ? (this.dotVisible ? 1 : 0.28) : 1)
              Text(this.recordState === 1 ? '录制中' : '清K中')
                .fontSize(10).fontColor('#fff')
            }
            .padding({ left: 8, right: 10, top: 3, bottom: 3 })
            .backgroundColor('#33ff5186')
            .borderRadius(8)
            .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 10 })

        // 歌词区
        List({ scroller: this.lyricScroller, space: 6 }) {
          ForEach(this.lyricLines, (line: string, index: number) => {
            ListItem() {
              Text(line.trim() || ' ')
                .fontSize(this.currentLine === index ? 20 : 15)
                .fontWeight(this.currentLine === index ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.currentLine === index ? '#ffffff' : '#666')
                .textShadow(this.currentLine === index ? {
                  radius: 12,
                  color: 'rgba(255,255,255,0.18)',
                  offsetX: 0,
                  offsetY: 0
                } : { radius: 0, color: Color.Transparent, offsetX: 0, offsetY: 0 })
                .lineHeight(28)
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding({ top: 6, bottom: 6 })
            }
          }, (line: string, index: number) => index.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .padding({ top: 40, bottom: 40, left: 20, right: 20 })

        // 进度条 + 播放暂停
        Row({ space: 8 }) {
          Button() {
            if (this.isPlaying) {
              Row({ space: 3 }) {
                Row().width(3).height(14).borderRadius(1).backgroundColor(Color.White)
                Row().width(3).height(14).borderRadius(1).backgroundColor(Color.White)
              }
            } else {
              Text('▶').fontSize(12).fontColor('#fff').margin({ left: 2 })
            }
          }
          .width(32).height(32).borderRadius(16)
          .backgroundColor('#2a2a2a')
          .onClick(() => { void this.toggleBgPlay() })

          Text(this.formatTime(Math.floor(this.playPosition / 1000)))
            .fontSize(12).fontColor('#888').width(42).textAlign(TextAlign.Center)

          Slider({
            value: this.playPosition,
            min: 0,
            max: this.duration > 0 ? this.duration : 1,
            step: 1
          })
            .layoutWeight(1)
            .trackColor('#333')
            .selectedColor('#ff5186')
            .blockColor('#ff5186')
            .onChange((value: number, mode: SliderChangeMode) => {
              if (mode === SliderChangeMode.Moving || mode === SliderChangeMode.End) {
                void this.seekBg(value)
              }
            })

          Text(this.formatTime(Math.floor(this.duration / 1000)))
            .fontSize(12).fontColor('#888').width(42).textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 6 })

        // 状态提示
        if (this.recordState === 1) {
          Row({ space: 6 }) {
            Row().width(8).height(8).borderRadius(4).backgroundColor('#ff4d62')
            Text('正在录制 ' + this.formatTime(this.recordSeconds))
              .fontSize(12).fontColor('#aaa')
          }
          .width('100%').justifyContent(FlexAlign.Center)
          .padding({ top: 4, bottom: 4 })
        } else if (this.recordState === 2) {
          Row({ space: 10 }) {
            Text(this.isPreviewPlaying ? '正在试听' : '作品已保存')
              .fontSize(12).fontColor('#888').layoutWeight(1)
            Text(this.isPreviewPlaying ? '停止' : '试听')
              .fontSize(13).fontColor('#ff5186')
              .onClick(() => {
                if (this.isPreviewPlaying) { void this.stopPlayback() }
                else { void this.playRecording() }
              })
            Text('重录')
              .fontSize(13).fontColor('#888')
              .onClick(() => { this.resetRecording() })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 4, bottom: 4 })
        } else {
          Text('点击录制，唱出你的版本')
            .fontSize(12).fontColor('#666')
            .width('100%').textAlign(TextAlign.Center)
            .padding({ top: 4, bottom: 4 })
        }

        // 底部三按钮：音量 / 录制 / 文件
        Row() {
          Column({ space: 6 }) {
            Image($r('app.media.ic_volume'))
              .width(24).height(24).fillColor('#ccc')
            Text('音量').fontSize(11).fontColor('#888')
          }
          .layoutWeight(1).justifyContent(FlexAlign.Center)
          .onClick(() => { this.showSheet = true })

          Column({ space: 6 }) {
            Stack({ alignContent: Alignment.Center }) {
              Row()
                .width(76).height(76).borderRadius(38)
                .backgroundColor('rgba(255,81,134,0.12)')
              Button() {
                if (this.recordState === 1) {
                  Row({ space: 3 }) {
                    Row().width(4).height(18).borderRadius(1).backgroundColor(Color.White)
                    Row().width(4).height(18).borderRadius(1).backgroundColor(Color.White)
                  }
                } else if (this.recordState === 2 && this.isPreviewPlaying) {
                  Row({ space: 3 }) {
                    Row().width(4).height(18).borderRadius(1).backgroundColor(Color.White)
                    Row().width(4).height(18).borderRadius(1).backgroundColor(Color.White)
                  }
                } else {
                  Text('●').fontSize(20).fontColor('#fff')
                }
              }
              .width(60).height(60).borderRadius(30)
              .backgroundColor('#ff5186')
              .padding(0)
              .shadow({ radius: 16, color: 'rgba(255,81,134,0.4)', offsetX: 0, offsetY: 4 })
            }
            Text(this.recordState === 1 ? '停止' : (this.recordState === 2 ? (this.isPreviewPlaying ? '停听' : '试听') : '录制'))
              .fontSize(11).fontColor('#888')
          }
          .layoutWeight(1).justifyContent(FlexAlign.Center)
          .onClick(() => {
            if (this.recordState === 0) { void this.startRecording() }
            else if (this.recordState === 1) { void this.stopRecording() }
            else if (this.isPreviewPlaying) { void this.stopPlayback() }
            else { void this.playRecording() }
          })

          Column({ space: 6 }) {
            Image($r('app.media.ic_file'))
              .width(24).height(24).fillColor('#ccc')
            Text('文件').fontSize(11).fontColor('#888')
          }
          .layoutWeight(1).justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.pathStack.pushPathByName('HistoryKGe', new Object(), false)
          })
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 36 })
      }
      .width('100%').height('100%')
      .backgroundColor('#131313')
      .radialGradient({
        center: ['50%', '22%'],
        radius: 450,
        colors: [['#262626', 0], ['#131313', 1]]
      })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      const p = context.pathInfo?.param as RecordParams
      if (p) {
        this.song = p.song
        this.lyricLines = p.song.lyrics ? p.song.lyrics.split('\n') : ['暂无歌词']
      }
      void this.startBgPlayer()
    })
    .hideTitleBar(true)
    .bindSheet($$this.showSheet, this.volumeSheet(), {
      height: 220,
      dragBar: true,
      backgroundColor: '#2a2a2a'
    })
  }

  @Builder
  volumeSheet() {
    Column({ space: 16 }) {
      Text('原唱音量')
        .fontSize(16).fontWeight(FontWeight.Medium).fontColor('#fff')
        .margin({ top: 16 })
      Row({ space: 12 }) {
        Text('静音').fontSize(12).fontColor('#888')
        Slider({
          value: this.musicVolume,
          min: 0,
          max: 100,
          step: 1
        })
          .layoutWeight(1)
          .trackColor('#444')
          .selectedColor('#ff5186')
          .blockColor('#ff5186')
          .onChange((value: number, mode: SliderChangeMode) => {
            if (mode === SliderChangeMode.Moving || mode === SliderChangeMode.End) {
              void this.setBgVolume(value)
            }
          })
        Text('跟唱').fontSize(12).fontColor('#888')
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
      Text(this.musicVolume === 0 ? '当前：纯清K（原唱静音，只走歌词）' : '当前：原唱音量 ' + this.musicVolume + '%（可跟唱）')
        .fontSize(12).fontColor('#666')
    }
    .width('100%').height('100%')
  }
}
