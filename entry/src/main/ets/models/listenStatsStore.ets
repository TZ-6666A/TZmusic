import { preferences } from '@kit.ArkData'
import { AppStorageV2 } from '@kit.ArkUI'

const LISTEN_STATS_STORE = 'listen_stats_store'
const KEY_TOTAL_SECONDS = 'total_seconds'
const KEY_TOTAL_MINUTES_LEGACY = 'total_minutes'
export const LISTEN_STATS_KEY = 'LISTEN_STATS_KEY'

// 全局响应式听歌统计状态，个人页与等级页绑定同一份数据
@ObservedV2
export class ListenStatsState {
  @Trace totalSeconds: number = 0
  @Trace loaded: boolean = false

  // 听歌分钟（向下取整），UI 与等级均以此为准
  get totalMinutes(): number {
    return Math.floor(this.totalSeconds / 60)
  }
}

export class ListenStatsStore {
  // 连接全局响应式状态（单例）
  static state(): ListenStatsState {
    return AppStorageV2.connect(ListenStatsState, LISTEN_STATS_KEY, () => new ListenStatsState())!
  }

  // 读取累计听歌秒数；兼容旧版本按分钟存储的数据
  static async getTotalSeconds(context: Context): Promise<number> {
    try {
      const prefs = await preferences.getPreferences(context, LISTEN_STATS_STORE)
      const secs = await prefs.get(KEY_TOTAL_SECONDS, -1)
      if (typeof secs === 'number' && secs >= 0) {
        return secs
      }
      // 旧数据迁移：total_minutes(分钟) → 秒
      const legacyMinutes = await prefs.get(KEY_TOTAL_MINUTES_LEGACY, 0)
      const minutes = typeof legacyMinutes === 'number' ? legacyMinutes : 0
      return minutes * 60
    } catch (err) {
      console.error('ListenStatsStore getTotalSeconds failed: ' + JSON.stringify(err))
      return 0
    }
  }

  static async getTotalMinutes(context: Context): Promise<number> {
    const secs = await ListenStatsStore.getTotalSeconds(context)
    return Math.floor(secs / 60)
  }

  // 首次进入时把磁盘历史数据加载进全局状态；已加载则直接返回
  static async ensureLoaded(context: Context): Promise<number> {
    const state = ListenStatsStore.state()
    if (state.loaded) {
      return state.totalSeconds
    }
    const value = await ListenStatsStore.getTotalSeconds(context)
    state.totalSeconds = value
    state.loaded = true
    return value
  }

  // 按秒累加并持久化（播放中高频调用）；以内存单例为基准累加，避免并发读改写竞态
  static async addSeconds(context: Context, seconds: number): Promise<number> {
    if (seconds <= 0) {
      return ListenStatsStore.state().totalSeconds
    }
    const state = ListenStatsStore.state()
    // 状态尚未从磁盘加载时，先读盘作为基准
    if (!state.loaded) {
      state.totalSeconds = await ListenStatsStore.getTotalSeconds(context)
      state.loaded = true
    }
    const next = state.totalSeconds + seconds
    const prefs = await preferences.getPreferences(context, LISTEN_STATS_STORE)
    await prefs.put(KEY_TOTAL_SECONDS, next)
    await prefs.flush()
    // 同步更新全局响应式状态，所有绑定页面自动刷新
    state.totalSeconds = next
    return next
  }

  // 兼容旧调用：按分钟累加
  static async addMinutes(context: Context, minutes: number): Promise<number> {
    if (minutes <= 0) {
      return ListenStatsStore.state().totalSeconds
    }
    return ListenStatsStore.addSeconds(context, minutes * 60)
  }
}
