import { fileIo } from '@kit.CoreFileKit'
import { abilityAccessCtrl } from '@kit.AbilityKit'
import { audio } from '@kit.AudioKit'
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
  @Local recordState: number = 0
  @Local isPlaying: boolean = false
  @Local recordSeconds: number = 0
  @Local dotVisible: boolean = true
  @Local errorText: string = ''
  private audioCapturer: audio.AudioCapturer | null = null
  private audioRenderer: audio.AudioRenderer | null = null
  private recordPath: string = ''
  private recordFd: number = -1
  private playFd: number = -1
  private timerId: number = -1
  private dotTimerId: number = -1
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
      this.audioCapturer.release()
      this.audioCapturer = null
    }
    if (this.recordFd >= 0) {
      fileIo.closeSync(this.recordFd)
      this.recordFd = -1
    }
    this.isPlaying = false
  }

  releasePlayback(): void {
    if (this.audioRenderer) {
      this.audioRenderer.release()
      this.audioRenderer = null
    }
    if (this.playFd >= 0) {
      fileIo.closeSync(this.playFd)
      this.playFd = -1
    }
    this.isPlaying = false
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
    const m = Math.floor(seconds / 60)
    const s = Math.floor(seconds % 60)
    return m.toString().padStart(2, '0') + ':' + s.toString().padStart(2, '0')
  }

  statusTitle(): string {
    if (this.recordState === 1) {
      return '正在录制'
    }
    if (this.isPlaying) {
      return '正在试听'
    }
    if (this.recordState === 2) {
      return '录制完成'
    }
    return '准备开唱'
  }

  statusDesc(): string {
    if (this.errorText) {
      return this.errorText
    }
    if (this.recordState === 1) {
      return '保持节奏，唱出你的版本'
    }
    if (this.isPlaying) {
      return '正在播放刚才录下的声音'
    }
    if (this.recordState === 2) {
      return '可以试听，也可以重新录制'
    }
    return '戴上耳机，点击下方按钮开始录制'
  }

  primaryLabel(): string {
    if (this.recordState === 0) {
      return '开始录制'
    }
    if (this.recordState === 1) {
      return '停止录制'
    }
    return this.isPlaying ? '停止试听' : '试听作品'
  }

  resetRecording(): void {
    this.releasePlayback()
    this.recordState = 0
    this.recordSeconds = 0
    this.isPlaying = false
    this.errorText = ''
    this.recordPath = getContext(this).filesDir + '/record_' + Date.now() + '.pcm'
  }

  boostPcmBuffer(buffer: ArrayBuffer): ArrayBuffer {
    const input = new Int16Array(buffer)
    const output = new Int16Array(input.length)
    let peak = 0
    for (let i = 0; i < input.length; i++) {
      const value = Math.abs(input[i])
      if (value > peak) {
        peak = value
      }
    }
    if (peak < 20) {
      output.fill(0)
      return output.buffer
    }
    if (peak === 0) {
      return buffer
    }
    const gain = Math.min(14000 / peak, 60)
    for (let i = 0; i < input.length; i++) {
      let value = Math.round(input[i] * gain)
      if (value > 32767) {
        value = 32767
      } else if (value < -32768) {
        value = -32768
      }
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

  @Builder
  pauseMark(size: number) {
    Row({ space: 5 }) {
      Row()
        .width(size / 4)
        .height(size)
        .borderRadius(size / 8)
        .backgroundColor(Color.White)
      Row()
        .width(size / 4)
        .height(size)
        .borderRadius(size / 8)
        .backgroundColor(Color.White)
    }
  }

  @Builder
  primaryIcon() {
    if (this.recordState === 1 || this.isPlaying) {
      this.pauseMark(24)
    } else {
      Image($r('app.media.ic_play'))
        .width(28)
        .height(28)
        .fillColor(Color.White)
        .margin({ left: 4 })
    }
  }

  @Builder
  lyricPanel() {
    if (this.lyricLines.length > 0 && !(this.lyricLines.length === 1 && this.lyricLines[0] === '暂无歌词')) {
      List() {
        ForEach(this.lyricLines, (line: string) => {
          ListItem() {
            Text(line.trim() || ' ')
              .fontSize(16)
              .lineHeight(30)
              .fontColor(line.trim() ? '#e8e8e8' : '#777')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 4, bottom: 4 })
          }
        }, (line: string, index: number) => index.toString())
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({ left: 24, right: 24, top: 12, bottom: 12 })
    } else {
      Column({ space: 10 }) {
        Image($r('app.media.ic_music'))
          .width(42)
          .height(42)
          .fillColor('#5d6575')
        Text('暂无歌词')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#c9ced8')
        Text('跟随伴奏，唱出你的版本')
          .fontSize(13)
          .fontColor('#747b8b')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
  }

  build() {
    NavDestination() {
      Column() {
        Stack({ alignContent: Alignment.Top }) {
          Image(this.song.img)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .opacity(0.24)

          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#d80b0d14')

          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_back'))
                  .width(20)
                  .height(20)
                  .fillColor(Color.White)
              }
              .width(40)
              .height(40)
              .borderRadius(20)
              .backgroundColor('#26ffffff')
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.releaseAll()
                this.pathStack.pop()
              })

              Text('K歌录音')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)

              Row().width(40).height(40)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12 })

            Row({ space: 14 }) {
              Image(this.song.img)
                .width(72)
                .height(72)
                .borderRadius(16)
                .border({ width: 1, color: '#33ffffff' })
                .shadow({ radius: 16, color: '#55000000', offsetY: 8 })

              Column({ space: 6 }) {
                Text(this.song.name)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.song.author)
                  .fontSize(14)
                  .fontColor('#bfc4d0')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Row({ space: 7 }) {
                  Row()
                    .width(8)
                    .height(8)
                    .borderRadius(4)
                    .backgroundColor(this.recordState === 1 ? '#ff4d62' : '#46e6a0')
                    .opacity(this.recordState === 1 ? (this.dotVisible ? 1 : 0.28) : 1)
                  Text(this.statusTitle())
                    .fontSize(12)
                    .fontColor('#eef1f7')
                }
                .padding({ left: 10, right: 12, top: 5, bottom: 5 })
                .backgroundColor('#24ffffff')
                .borderRadius(14)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 24, bottom: 16 })

            Column({ space: 6 }) {
              Text(this.formatTime(this.recordSeconds))
                .fontSize(54)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text(this.statusDesc())
                .fontSize(14)
                .fontColor('#b8becb')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ top: 8, bottom: 12 })

            Column() {
              this.lyricPanel()
            }
            .width('100%')
            .layoutWeight(1)
            .margin({ left: 14, right: 14 })
            .backgroundColor('#33000000')
            .border({ width: 1, color: '#14ffffff' })
            .borderRadius(18)

            Column({ space: 16 }) {
              Row() {
                if (this.recordState === 2) {
                  Column({ space: 7 }) {
                    Row() {
                      Image($r('app.media.ic_repeat'))
                        .width(22)
                        .height(22)
                        .fillColor('#d7dbe5')
                    }
                    .width(52)
                    .height(52)
                    .borderRadius(26)
                    .backgroundColor('#24ffffff')
                    .justifyContent(FlexAlign.Center)
                    .onClick(() => {
                      this.resetRecording()
                    })
                    Text('重录')
                      .fontSize(12)
                      .fontColor('#aab1c1')
                  }
                  .width(82)
                } else {
                  Column().width(82)
                }

                Column({ space: 9 }) {
                  Button() {
                    this.primaryIcon()
                  }
                  .width(78)
                  .height(78)
                  .borderRadius(39)
                  .backgroundColor(this.recordState === 1 ? '#ff3d54' : '#ff5186')
                  .shadow({ radius: 24, color: this.recordState === 1 ? '#55ff3d54' : '#55ff5186', offsetY: 8 })
                  .onClick(() => {
                    if (this.recordState === 0) {
                      void this.startRecording()
                    } else if (this.recordState === 1) {
                      void this.stopRecording()
                    } else if (this.isPlaying) {
                      this.stopPlayback()
                    } else {
                      void this.playRecording()
                    }
                  })

                  Text(this.primaryLabel())
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#eef1f7')
                }
                .layoutWeight(1)

                if (this.recordState === 2) {
                  Column({ space: 7 }) {
                    Row() {
                      Image($r('app.media.ic_music'))
                        .width(22)
                        .height(22)
                        .fillColor('#d7dbe5')
                    }
                    .width(52)
                    .height(52)
                    .borderRadius(26)
                    .backgroundColor('#24ffffff')
                    .justifyContent(FlexAlign.Center)
                    Text('已保存')
                      .fontSize(12)
                      .fontColor('#aab1c1')
                  }
                  .width(82)
                } else {
                  Column().width(82)
                }
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              Row({ space: 8 }) {
                Text('录音会自动保存到历史K歌')
                  .fontSize(12)
                  .fontColor('#7d8494')
              }
              .justifyContent(FlexAlign.Center)
              .width('100%')
            }
            .width('100%')
            .padding({ left: 18, right: 18, top: 18, bottom: 24 })
            .backgroundColor('#cc11131c')
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          }
          .width('100%')
          .height('100%')
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#090b12')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      const p = context.pathInfo?.param as RecordParams
      if (p) {
        this.song = p.song
        if (p.song.lyrics) {
          this.lyricLines = p.song.lyrics.split('\n')
        } else {
          this.lyricLines = ['暂无歌词']
        }
      }
    })
    .hideTitleBar(true)
  }

  async startRecording(): Promise<void> {
    try {
      playerManager.paused()
      this.releasePlayback()
      this.errorText = '正在请求麦克风权限...'

      const atManager = abilityAccessCtrl.createAtManager()
      const grantStatus = await atManager.requestPermissionsFromUser(
        getContext(this), ['ohos.permission.MICROPHONE']
      )
      if (grantStatus.authResults[0] !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.error('record permission denied')
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
      console.error('record start failed: ' + JSON.stringify(e))
      this.stopTimers()
      if (this.audioCapturer) {
        await this.audioCapturer.release()
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
        console.error('record file is empty after stop: ' + this.recordPath)
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
        img: this.song.img as string,
        filePath: this.recordPath,
        duration: this.recordSeconds,
        createdAt: Date.now()
      })
    } catch (e) {
      console.error('record stop failed: ' + JSON.stringify(e))
      this.errorText = '停止录音失败，请重试'
    }
  }

  async playRecording(): Promise<void> {
    try {
      playerManager.paused()
      this.releasePlayback()

      const stat = fileIo.statSync(this.recordPath)
      if (stat.size <= 0) {
        console.error('record file is empty: ' + this.recordPath)
        return
      }
      this.isPlaying = true
      this.errorText = ''
      console.info('Playing pcm record: size=' + stat.size + ', path=' + this.recordPath)

      const file = fileIo.openSync(this.recordPath, fileIo.OpenMode.READ_ONLY)
      this.playFd = file.fd
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
      console.error('play record failed: ' + JSON.stringify(e))
      this.errorText = '试听失败，请重新录制'
      this.releasePlayback()
    }
  }

  async stopPlayback(): Promise<void> {
    if (this.audioRenderer) {
      await this.audioRenderer.stop()
      await this.audioRenderer.release()
      this.audioRenderer = null
    }
    if (this.playFd >= 0) {
      fileIo.closeSync(this.playFd)
      this.playFd = -1
    }
    this.isPlaying = false
  }
}


