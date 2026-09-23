//播放模式（真正负责播放音乐）
import { media } from '@kit.MediaKit'
import { fileIo } from '@kit.CoreFileKit'
import { GlobalMusic } from '../models/globalMusic'
import { SongItemType } from '../models/music'
import { AppStorageV2 } from '@kit.ArkUI'
import { sessionManager } from './AvSessionManager'
import { ListenStatsStore } from '../models/listenStatsStore'

class AvPlayerManager {
  // 播放器
  player: media.AVPlayer | null = null
  // 共享播放数据
  currentSong: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!

  private statsContext: Context | null = null
  //上个统计听歌节点
  private lastListenTick: number = 0
  private lastSessionSyncTick: number = 0
  private isRecreatingPlayer: boolean = false

  private listenBufferMs: number = 0
  // 播放中每隔多少毫秒持久化一次听歌时长（5 秒），兼顾写入频率与防丢失
  private static readonly FLUSH_INTERVAL_MS: number = 5000
  // 缓存 rawfile 的文件描述符，避免重复获取
  private rawFileCache: Map<string, media.AVFileDescriptor> = new Map()
  // 保持 RawFileDescriptor 引用，防止 fd 被 GC 回收
  private rawFdStore: Map<string, object> = new Map()

  //给权限去找对于歌曲的资源
  bindContext(context: Context): void {
    this.statsContext = context
  }

  //统计播放时长（由 timeUpdate 高频调用）
  private collectListenTime(): void {
    if (!this.statsContext || !this.currentSong.isPlay) {
      this.lastListenTick = Date.now()
      return
    }
    const now = Date.now()
    if (this.lastListenTick === 0) {
      this.lastListenTick = now
      return
    }
    const diff = now - this.lastListenTick
    this.lastListenTick = now
    if (diff <= 0 || diff > 10000) {
      return
    }
    this.listenBufferMs += diff
    // 每满 5 秒落盘一次，最多只丢不足 5 秒的零头
    while (this.listenBufferMs >= AvPlayerManager.FLUSH_INTERVAL_MS) {
      this.listenBufferMs -= AvPlayerManager.FLUSH_INTERVAL_MS
      void ListenStatsStore.addSeconds(this.statsContext,
        Math.round(AvPlayerManager.FLUSH_INTERVAL_MS / 1000))
    }
  }

  // 把不足 5 秒的零头按秒结算写盘（暂停/切歌/退出/切后台时调用），避免重启丢失
  flushListenTime(): void {
    if (!this.statsContext) {
      return
    }
    const secs = Math.floor(this.listenBufferMs / 1000)
    if (secs > 0) {
      this.listenBufferMs -= secs * 1000
      void ListenStatsStore.addSeconds(this.statsContext, secs)
    }
  }

  //播放器里播放列表里的歌曲
  private getCurrentSong(): SongItemType | null {
    if (this.currentSong.playList.length === 0) {
      return null
    }
    if (this.currentSong.playIndex < 0 || this.currentSong.playIndex >= this.currentSong.playList.length) {
      this.currentSong.playIndex = 0
    }
    return this.currentSong.playList[this.currentSong.playIndex]
  }

  // 定义方法 创建播放器 + 监听播放器的状态
  async init() {
    if (this.player) {
      return
    }
    this.player = await media.createAVPlayer()

    //播放相关设置以及错误汇报
    this.player.on('stateChange', (state) => {
      //initialized初始化（紫色单词是系统自带的）
      if (state === 'initialized') {
        this.player?.prepare()
      } else if (state === 'prepared') {
        this.player?.play()
        this.currentSong.isPlay = true
        this.lastListenTick = Date.now()
      } else if (state === 'completed') {
        this.flushListenTime()
        this.nextPlay(true) // 自动下一首
      }else if (state === 'released'){
        this.flushListenTime()
        if (!this.isRecreatingPlayer) {
          this.currentSong.reset()
        }
      } else if (state === 'error') {
        console.error('AvPlayerManager: player state error, url=' + (this.player?.url ?? ''))
        this.currentSong.isPlay = false
      }
    })


    // 时间变化（durationUpdate是系统自带的，duration是自己起的名字）
    //player.on 当成一句大白话:“给播放器注册一个监听器,只要某件事发生,就自动执行后面的代码
    this.player.on('durationUpdate', (duration) => {
      this.currentSong.duration = duration
      const song = this.getCurrentSong()
      if (song) {
        sessionManager.setAVMetadata(song)
      }
    })

    //上下核心区别：上管歌曲总时长，下管理当前播放的歌曲时长
    this.player.on('timeUpdate', (time) => {
      this.currentSong.time = time
      this.collectListenTime()
      this.syncSessionState()
    })
  }

  private syncSessionState(force: boolean = false): void {
    const now = Date.now()
    if (!force && now - this.lastSessionSyncTick < 1000) {
      return
    }
    this.lastSessionSyncTick = now
    sessionManager.setAVPlayBackState()
  }

  private async recreatePlayer(): Promise<void> {
    this.isRecreatingPlayer = true
    this.flushListenTime()
    try {
      await this.player?.release()
    } catch (e) {
      console.error('AvPlayerManager: release failed while recreating player', JSON.stringify(e))
    } finally {
      this.player = null
      this.isRecreatingPlayer = false
    }
    await this.init()
  }


  // 播放歌曲 → 设置播放资源
  async singPlay(song?: SongItemType | null) {
    if (!song || (!song.url && !song.rawFile)) {
      return
    }
    // 防御检查：如果播放器不存在或已释放，重新初始化
    if (!this.player || this.player.state === 'released' || this.player.state === 'error') {
      await this.recreatePlayer()
    }
    //申请长时任务
    void sessionManager.startBackgroundTask()
    this.syncSessionState(true)
    // 是否在列表 → some 检查数组里面的数据是否满足条件 → 只要有一个满足 some 返回 true（some里面的语句表示条件）
    const inList = this.currentSong.playList.some(item => item.id === song.id)
    if (inList) {
      // 在列表里面 → 是否是正在播放的 → 用 id 比较更可靠（url 可能是 string 或 Resource）
      if (this.currentSong.id === song.id) {
        this.player?.play()
        this.currentSong.isPlay = true
      } else {
        // 设置新的索引 → 切歌
        this.currentSong.playIndex = this.currentSong.playList.findIndex(item => item.id === song.id)
        // 切歌
        await this.changeSong()
      }
    } else {
      // 不在列表里面 → 添加到列表 + 切换歌曲
      this.currentSong.playList.unshift(song)
      this.currentSong.playIndex = 0
      // 切换歌曲
      await this.changeSong()
    }
  }

  // 通过 getRawFd 获取文件描述符，AVPlayer 需要 fd + offset + length 才能定位 rawfile 数据
  //rawfile 资源封装成 AVFileDescriptor,通过 fd offset length 让播放器能读本地音频
  private async prepareRawFile(rawFileName: string): Promise<media.AVFileDescriptor | null> {
   //has返回bool,get可以把对应东西取出来
    if (this.rawFileCache.has(rawFileName)) {
      return this.rawFileCache.get(rawFileName)!
    }
    const ctx = this.statsContext
    if (!ctx) {
      console.error('AvPlayerManager: statsContext is null, cannot play rawfile')
      return null
    }
    try {
      const rawFd = await ctx.resourceManager.getRawFd(rawFileName)
      const fdSrc: media.AVFileDescriptor = {
        fd: rawFd.fd,
        offset: rawFd.offset,
        length: rawFd.length
      }
      this.rawFdStore.set(rawFileName, rawFd)  // 保持引用防止 fd 被 GC
      this.rawFileCache.set(rawFileName, fdSrc)
      return fdSrc
    } catch (e) {
      console.error('AvPlayerManager: getRawFd failed, try copy to temp: ' + rawFileName, JSON.stringify(e))
    }
    // 方式二：fallback → 复制到临时目录再用 fd:// 打开
    try {
      const content = await ctx.resourceManager.getRawFileContent(rawFileName)
      const tempPath = ctx.tempDir + '/audio_' + rawFileName
      const file = fileIo.openSync(tempPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC)
      // 注意：必须指定 offset = content.byteOffset，否则可能写入多余数据
      fileIo.writeSync(file.fd, content.buffer, { offset: content.byteOffset, length: content.byteLength })
      fileIo.closeSync(file)
      const fdFile = fileIo.openSync(tempPath, fileIo.OpenMode.READ_ONLY)
      const fdSrc: media.AVFileDescriptor = {
        fd: fdFile.fd,
        //临时文件是干净的,从头开始,偏移量就是0,资源包里的 rawfile 才需要用真实的 offset
        offset: 0,
        length: fileIo.statSync(tempPath).size
      }
      this.rawFdStore.set(rawFileName, fdFile)
      this.rawFileCache.set(rawFileName, fdSrc)
      return fdSrc
    } catch (e2) {
      console.error('AvPlayerManager: failed to extract rawfile ' + rawFileName, JSON.stringify(e2))
      return null
    }
  }

  // 切换歌曲 → 重新播放器
  async changeSong() {
    const song = this.getCurrentSong()
    if (!song) {
      //reset 大白话就是把播放器恢复到初始状态,准备重新播放另一首歌
      this.currentSong.reset()
      return
    }
    try {
      this.flushListenTime()
      await this.player?.reset()
      this.currentSong.duration = 0
      this.currentSong.time = 0
      this.currentSong.img = song.img as string
      this.currentSong.name = song.name
      this.currentSong.author = song.author
      this.currentSong.id = song.id
      this.currentSong.url = typeof song.url === 'string' ? song.url : ''
      // 设置播放源：rawFile 有值 → 解压 rawfile 到临时目录再用文件路径播放
      if (song.rawFile) {
        const fdSrc = await this.prepareRawFile(song.rawFile)
        if (fdSrc) {
          this.player!.fdSrc = fdSrc
        } else {
          console.error('AvPlayerManager: could not prepare rawfile, fallback to url')
          this.player!.url = this.currentSong.url
        }
      } else {
        this.player!.url = this.currentSong.url
      }

    } catch (e) {
      console.error('AvPlayerManager: changeSong error', JSON.stringify(e))
      // 如果切换失败，尝试重新初始化播放器后重试
      await this.recreatePlayer()
      if (song.rawFile) {
        const fdSrc = await this.prepareRawFile(song.rawFile)
        if (fdSrc) {
          this.player!.fdSrc = fdSrc
        }
      } else if (typeof song.url === 'string') {
        this.player!.url = song.url
      }
    }
  }

  // 跳转进度 seek
  seekPlay(value: number) {
    this.player?.seek(value)
  }

  // 暂停
  paused() {
    this.flushListenTime()
    this.player?.pause()
    this.currentSong.isPlay = false
    sessionManager.setAVPlayBackState()
    void sessionManager.stopBackgroundTask()
  }

  // 上一首
  prevPlay () {
    if (this.currentSong.playList.length === 0) {
      this.currentSong.isPlay = false
      sessionManager.setAVPlayBackState()
      return
    }
    //随机(random)
    if (this.currentSong.playMode === 'random') {
      // 随机
      this.currentSong.playIndex = Math.floor(Math.random() * this.currentSong.playList.length)
    } else {
      this.currentSong.playIndex--
      if (this.currentSong.playIndex < 0) {
        // 去最后一首
        this.currentSong.playIndex = this.currentSong.playList.length - 1
      }
    }
    this.singPlay(this.getCurrentSong())
  }

  // 下一首: 根据播放模式计算索引 播放 → if
  // 真的重复播放 → 播放模式为 repeat 并且 播放器自动下一首 → completed → 传入一个数据表示是自动的
  // 随机 → 计算随机索引
  // 列表 → ++
  nextPlay(autoNextPlay?: boolean) {
    if (this.currentSong.playList.length === 0) {
      this.currentSong.isPlay = false
      sessionManager.setAVPlayBackState()
      return
    }
    //当前歌曲播完并且系统准备切歌，则播放当前歌曲
    if (this.currentSong.playMode === 'repeat' && autoNextPlay) {
      this.currentSong.playIndex = this.currentSong.playIndex
    } else if (this.currentSong.playMode === 'random') {
      // 随机
      // Math.random() [0-1) 随机小数
      this.currentSong.playIndex = Math.floor(Math.random() * this.currentSong.playList.length)
    } else {
      // 列表
      this.currentSong.playIndex++
      if (this.currentSong.playIndex >= this.currentSong.playList.length) {
        // 去第一首
        this.currentSong.playIndex = 0
      }
    }
    this.singPlay(this.getCurrentSong())
  }

  // 列表移除歌曲
  removeSong (index: number) {
    if (index < 0 || index >= this.currentSong.playList.length) {
      return
    }
    if (index === this.currentSong.playIndex) {
      // 删除的是正在播放的
      if (this.currentSong.playList.length > 1) {
        // 列表里面有多首歌
        this.currentSong.playList.splice(index, 1)
        // 播放索引如果大于等于了长度，回第一首播放
        if (this.currentSong.playIndex >= this.currentSong.playList.length) {
          this.currentSong.playIndex = 0
        }
        this.singPlay(this.currentSong.playList[this.currentSong.playIndex])
      } else {
        // 列表里面只有一首歌
        this.player?.reset()
        this.currentSong.reset()
      }
    } else {
      // 删除的不是正在播放的歌曲
      if (index < this.currentSong.playIndex) {
        // 要删除的在播放的前面
        this.currentSong.playIndex--
      }
      // 移除 → 删除的索引，删除个数
      this.currentSong.playList.splice(index, 1)
    }
  }
  // 释放播放器 和 播放数据
  async release () {
    this.flushListenTime()
    await this.player?.release()
    this.player = null
  }
  //release 偏向资源释放, stop and reset 偏向播放器停止和状态重置,
  async stopAndReset(): Promise<void> {
    this.flushListenTime()
    try {
      await this.player?.reset()
    } catch (e) {
      console.error('AvPlayerManager: stop reset error', JSON.stringify(e))
    }
    this.currentSong.reset()
    sessionManager.setAVPlayBackState()
    void sessionManager.stopBackgroundTask()
  }
}


export const playerManager: AvPlayerManager = new AvPlayerManager()
