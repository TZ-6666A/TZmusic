//保证退出后台app不会被杀死＋状态栏显示及app控制
//负责让系统控制你的播放器
import { avSession } from '@kit.AVSessionKit'
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager'
import { wantAgent } from '@kit.AbilityKit';
import { GlobalMusic } from '../models/globalMusic';
import { AppStorageV2 } from '@kit.ArkUI';
import { SongItemType } from '../models/music';
import { playerManager } from './AvPlayerManager';

class AvSessionManager {
  session: avSession.AVSession | null = null
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  private context: Context | null = null
  private backgroundRunning: boolean = false

  async init(content: Context) {
    this.context = content
    this.session = await avSession.createAVSession(content, 'bgPlay', 'audio')
    this.registerEvent()
  }

  // 申请长时任务（后台可以放歌）
  async startBackgroundTask() {
    if (!this.context || this.backgroundRunning) {
      return
    }
    try {
      let wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: "com.yuzi.myapplication",
            abilityName: "EntryAbility"
          }
        ],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      };
      const want = await wantAgent.getWantAgent(wantAgentInfo)
      await backgroundTaskManager.startBackgroundRunning(this.context, backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, want)
      this.backgroundRunning = true
    } catch (err) {
      console.error('AvSessionManager startBackgroundTask failed: ' + JSON.stringify(err))
    }
  }

  // 取消长时任务（暂停/停止时调用，释放后台保活）
  async stopBackgroundTask() {
    if (!this.context || !this.backgroundRunning) {
      return
    }
    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context)
      this.backgroundRunning = false
    } catch (err) {
      console.error('AvSessionManager stopBackgroundTask failed: ' + JSON.stringify(err))
    }
  }

  //设置元数据（使得手机状态栏/锁屏可以显示显示歌曲信息）
  setAVMetadata(song?: SongItemType | null) {
    if (!song) {
      return
    }
    this.session?.setAVMetadata({
      assetId: song.id,
      title: song.name,
      mediaImage: song.img as string,
      artist: song.author,
      duration: this.playState.duration
    })
  }

  // 设置播放状态（鸿蒙手机系统暂停/播放/上下一曲）
  setAVPlayBackState() {
    this.session?.setAVPlaybackState({
      state: this.playState.isPlay ? avSession.PlaybackState.PLAYBACK_STATE_PLAY : avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
      speed: 1,
      position: {
        elapsedTime: this.playState.time,
        updateTime: new Date().getTime()
      },
      duration: this.playState.duration
    })
  }

  // 注册事件
  registerEvent() {
    this.session?.on('play', () => {
      if (this.playState.playList.length === 0) {
        return
      }
      if (this.playState.playIndex < 0 || this.playState.playIndex >= this.playState.playList.length) {
        this.playState.playIndex = 0
      }
      playerManager.singPlay(this.playState.playList[this.playState.playIndex])
    })
    this.session?.on('pause', () => {
      playerManager.paused()
    })
    this.session?.on('playPrevious', () => {
      playerManager.prevPlay()
    })
    this.session?.on('playNext', () => {
      playerManager.nextPlay()
    })
    this.session?.on('seek', (value: number) => {
      playerManager.seekPlay(value)
    })
    this.session?.activate()
  }

  // 注销会话
  async destroy() {
    await this.stopBackgroundTask()
    await this.session?.destroy()
    this.session = null
  }
}

export const sessionManager: AvSessionManager = new AvSessionManager()
