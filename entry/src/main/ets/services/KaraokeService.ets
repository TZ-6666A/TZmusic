// K歌音频服务（简化版：单播放器驱动歌词 + 单声道麦克风录音 + WAV导出）
import { audio } from '@kit.AudioKit'
import { media } from '@kit.MediaKit'
import { fileIo } from '@kit.CoreFileKit'
import { SongItemType } from '../models/music'

export interface OpResult {
  ok: boolean
  msg: string
}

const SAMPLE_RATE = 44100
const CHANNELS = 1

export class KaraokeService {
  // ---- 播放器（原唱，驱动歌词进度；音量为0即清K）----
  private player: media.AVPlayer | null = null

  // ---- 录音采集 ----
  private micCapturer: audio.AudioCapturer | null = null
  private voicePath: string = ''
  private voiceFd: number = -1
  private micReadCallback: ((buffer: ArrayBuffer) => void) | null = null

  // ---- 业务状态 ----
  private song: SongItemType | null = null
  private context: Context | null = null
  private musicVolume: number = 0

  // ---- 对外状态 ----
  position: number = 0
  duration: number = 0
  isRecording: boolean = false
  isPlaying: boolean = false

  // ---- 页面回调 ----
  onStateChange: (() => void) | null = null

  private recordStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
    channels: audio.AudioChannel.CHANNEL_1,
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  }

  bindContext(context: Context): void {
    this.context = context
  }

  // ================= 播放器 =================

  async playSong(song: SongItemType): Promise<void> {
    this.song = song
    this.position = 0
    this.duration = 0
    this.isPlaying = false
    if (this.player) {
      try { await this.player.release() } catch (e) { /* ignore */ }
      this.player = null
    }
    const p = await media.createAVPlayer()
    p.on('stateChange', (state: string) => {
      if (state === 'initialized') {
        p.prepare()
      } else if (state === 'prepared') {
        p.setVolume(this.musicVolume)
        p.play()
      } else if (state === 'playing') {
        this.isPlaying = true
        if (this.onStateChange) this.onStateChange()
      } else if (state === 'paused') {
        this.isPlaying = false
        if (this.onStateChange) this.onStateChange()
      }
    })
    p.on('timeUpdate', (time: number) => {
      this.position = time
      if (this.onStateChange) this.onStateChange()
    })
    p.on('durationUpdate', (dur: number) => {
      this.duration = dur
      if (this.onStateChange) this.onStateChange()
    })
    // 播放源：优先 rawfile，其次 url
    const ctx = this.context
    if (song.rawFile && ctx) {
      try {
        const rawFd = await ctx.resourceManager.getRawFd(song.rawFile)
        p.fdSrc = { fd: rawFd.fd, offset: rawFd.offset, length: rawFd.length }
      } catch (e) {
        p.url = typeof song.url === 'string' ? song.url : ''
      }
    } else {
      p.url = typeof song.url === 'string' ? song.url : ''
    }
    this.player = p
  }

  async setMusicVolume(v: number): Promise<void> {
    this.musicVolume = v
    try {
      if (this.player) {
        await this.player.setVolume(v)
      }
    } catch (e) { /* ignore */ }
  }

  getMusicVolume(): number {
    return this.musicVolume
  }

  async seek(position: number): Promise<void> {
    this.position = position
    try {
      if (this.player && this.player.state === 'playing') {
        await this.player.seek(position)
      }
    } catch (e) { /* ignore */ }
  }

  async togglePlayPause(): Promise<void> {
    if (!this.player) return
    try {
      if (this.player.state === 'playing') {
        await this.player.pause()
      } else if (this.player.state === 'paused') {
        await this.player.play()
      }
    } catch (e) { /* ignore */ }
  }

  // ================= 录音 =================

  async startRecording(): Promise<OpResult> {
    if (this.isRecording) {
      return { ok: false, msg: '正在录音中' }
    }
    const ctx = this.context
    if (!ctx) {
      return { ok: false, msg: '服务未初始化' }
    }
    const stamp = Date.now()
    this.voicePath = ctx.filesDir + '/kge_voice_' + stamp + '.pcm'

    try {
      const vFile = fileIo.openSync(this.voicePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
      this.voiceFd = vFile.fd
    } catch (e) {
      return { ok: false, msg: '创建录音文件失败' }
    }

    try {
      const mic = await audio.createAudioCapturer({
        streamInfo: this.recordStreamInfo,
        capturerInfo: {
          source: audio.SourceType.SOURCE_TYPE_MIC,
          capturerFlags: 0
        }
      })
      this.micReadCallback = (buffer: ArrayBuffer): void => {
        if (this.voiceFd >= 0) {
          try {
            fileIo.writeSync(this.voiceFd, buffer)
          } catch (e) {
            console.error('Karaoke write voice failed: ' + JSON.stringify(e))
          }
        }
      }
      mic.on('readData', this.micReadCallback)
      await mic.start()
      this.micCapturer = mic
    } catch (e) {
      console.error('Karaoke mic start failed: ' + JSON.stringify(e))
      this.cleanupVoiceFile()
      return { ok: false, msg: '麦克风启动失败，请检查权限' }
    }

    this.isRecording = true
    if (this.onStateChange) this.onStateChange()
    return { ok: true, msg: '' }
  }

  private cleanupVoiceFile(): void {
    if (this.voiceFd >= 0) {
      fileIo.closeSync(this.voiceFd)
      this.voiceFd = -1
    }
    try {
      if (this.voicePath) {
        fileIo.unlinkSync(this.voicePath)
      }
    } catch (e) { /* ignore */ }
    this.voicePath = ''
  }

  async stopRecording(): Promise<string | null> {
    if (!this.isRecording) {
      return null
    }
    this.isRecording = false

    if (this.micCapturer) {
      try {
        if (this.micReadCallback) {
          this.micCapturer.off('readData', this.micReadCallback)
          this.micReadCallback = null
        }
        await this.micCapturer.stop()
        await this.micCapturer.release()
      } catch (e) {
        console.error('Karaoke stop mic failed: ' + JSON.stringify(e))
      }
      this.micCapturer = null
    }
    if (this.voiceFd >= 0) {
      fileIo.closeSync(this.voiceFd)
      this.voiceFd = -1
    }

    const ctx = this.context
    if (!ctx) {
      return null
    }
    const outPath = ctx.filesDir + '/kge_work_' + Date.now() + '.wav'
    let ok = false
    try {
      const voiceSize = fileIo.statSync(this.voicePath).size
      if (voiceSize <= 0) {
        console.warn('Karaoke voice file empty')
        return null
      }
      ok = this.wrapVoiceToWav(this.voicePath, outPath)
    } catch (e) {
      console.error('Karaoke stop/wrap failed: ' + JSON.stringify(e))
    }
    try {
      fileIo.unlinkSync(this.voicePath)
    } catch (e) { /* ignore */ }
    this.voicePath = ''
    if (this.onStateChange) this.onStateChange()
    return ok ? outPath : null
  }

  // ================= WAV 导出 =================

  private readPcmFile(path: string): Int16Array {
    const f = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY)
    try {
      const size = fileIo.statSync(path).size
      const buffer = new ArrayBuffer(size)
      fileIo.readSync(f.fd, buffer)
      return new Int16Array(buffer)
    } finally {
      fileIo.closeSync(f.fd)
    }
  }

  private wrapVoiceToWav(voicePath: string, outPath: string): boolean {
    try {
      const data = this.readPcmFile(voicePath)
      this.writeWav(outPath, data)
      return true
    } catch (e) {
      console.error('Karaoke wrap wav failed: ' + JSON.stringify(e))
      return false
    }
  }

  private writeWav(path: string, samples: Int16Array): void {
    const bits = 16
    const dataSize = samples.byteLength
    const byteRate = SAMPLE_RATE * CHANNELS * bits / 8
    const blockAlign = CHANNELS * bits / 8
    const header = new ArrayBuffer(44)
    const dv = new DataView(header)
    dv.setUint8(0, 0x52); dv.setUint8(1, 0x49); dv.setUint8(2, 0x46); dv.setUint8(3, 0x46)
    dv.setUint32(4, 36 + dataSize, true)
    dv.setUint8(8, 0x57); dv.setUint8(9, 0x41); dv.setUint8(10, 0x56); dv.setUint8(11, 0x45)
    dv.setUint8(12, 0x66); dv.setUint8(13, 0x6d); dv.setUint8(14, 0x74); dv.setUint8(15, 0x20)
    dv.setUint32(16, 16, true)
    dv.setUint16(20, 1, true)
    dv.setUint16(22, CHANNELS, true)
    dv.setUint32(24, SAMPLE_RATE, true)
    dv.setUint32(28, byteRate, true)
    dv.setUint16(32, blockAlign, true)
    dv.setUint16(34, bits, true)
    dv.setUint8(36, 0x64); dv.setUint8(37, 0x61); dv.setUint8(38, 0x74); dv.setUint8(39, 0x61)
    dv.setUint32(40, dataSize, true)

    const f = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC)
    try {
      fileIo.writeSync(f.fd, header)
      fileIo.writeSync(f.fd, samples.buffer)
    } finally {
      fileIo.closeSync(f.fd)
    }
  }

  // ================= 资源释放 =================

  async releaseAll(): Promise<void> {
    if (this.micCapturer) {
      try { await this.micCapturer.release() } catch (e) { /* ignore */ }
      this.micCapturer = null
    }
    if (this.voiceFd >= 0) {
      fileIo.closeSync(this.voiceFd)
      this.voiceFd = -1
    }
    try {
      await this.player?.release()
    } catch (e) { /* ignore */ }
    this.player = null
    this.isRecording = false
  }
}
