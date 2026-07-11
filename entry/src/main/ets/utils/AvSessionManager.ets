//保证退出后台app不会被杀死＋状态栏显示及app控制
import { avSession } from '@kit.AVSessionKit'
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager'
import { wantAgent } from '@kit.AbilityKit';
import { GlobalMusic } from '../models/globalMusic';
import { AppStorageV2 } from '@kit.ArkUI';
import { SongItemType } from '../models/music';
import { playerManager } from './AvPlayerManager';

class AvSessionManager {
 session:avSession.AVSession|null=null
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY',()=>new GlobalMusic())!

  async init(content: Context) {
    this.session = await avSession.createAVSession(content, 'bgPlay', 'audio')
    this.registerEvent()
 }
  // 申请长时任务
  async startBackgroundTask () {
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
    backgroundTaskManager.startBackgroundRunning(getContext(),backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK,want)
  }

  //设置元数据
  setAVMetadata (song?: SongItemType | null) {
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

  // 设置播放状态
  setAVPlayBackState () {
    this.session?.setAVPlaybackState({
      state: this.playState.isPlay ? avSession.PlaybackState.PLAYBACK_STATE_PLAY: avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
      speed: 1,
      position: {
        elapsedTime:this.playState.time,  //歌曲播放时间
        updateTime:new Date().getTime()    //系统时间
      },
      duration: this.playState.duration

    })
  }

  // 注册事件
  registerEvent () {
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
  async destroy () {
    await this.session?.destroy()
  }
}

export const sessionManager: AvSessionManager = new AvSessionManager()
