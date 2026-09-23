//相当于全局变量
//整个播放器的歌曲状态
import { SongItemType } from "./music"

@ObservedV2
export class GlobalMusic {
  @Trace img: string = ""  // 音乐封面
  @Trace  name: string = ""  // 音乐名称
  @Trace author: string = ""  // 作者
  @Trace id: string = ""  // 当前歌曲 id
  @Trace url: string = ""  // 当前播放链接
  @Trace  time: number = 0  // 播放时间
  @Trace duration: number = 0  // 音乐的播放时长

  // 歌曲列表
  @Trace playIndex: number = 0    // 当前播放的索引
  @Trace playList: SongItemType[] = []    // 播放列表


  /// 播放和暂停
  @Trace isPlay: boolean = false  // 播放的状态

  // 播放模式
  @Trace playMode: 'auto' | 'random' | 'repeat' = 'auto'

  // 重置数据
  reset () {
    this.img = ''
    this.name = ''
    this.author = ''
    this.id = ''
    this.url = ''
    this.time = 0
    this.duration = 0
    this.playIndex = 0
    this.playList = []
    this.isPlay = false
    this.playMode = 'auto'
  }

}
