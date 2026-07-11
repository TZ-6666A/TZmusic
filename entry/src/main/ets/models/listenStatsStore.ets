import { preferences } from '@kit.ArkData'

const LISTEN_STATS_STORE = 'listen_stats_store'
const KEY_TOTAL_MINUTES = 'total_minutes'

export class ListenStatsStore {
  static async getTotalMinutes(context: Context): Promise<number> {
    try {
      const prefs = await preferences.getPreferences(context, LISTEN_STATS_STORE)
      const value = await prefs.get(KEY_TOTAL_MINUTES, 0)
      return typeof value === 'number' ? value : 0
    } catch (err) {
      console.error('ListenStatsStore getTotalMinutes failed: ' + JSON.stringify(err))
      return 0
    }
  }

  static async addMinutes(context: Context, minutes: number): Promise<number> {
    if (minutes <= 0) {
      return ListenStatsStore.getTotalMinutes(context)
    }
    const prefs = await preferences.getPreferences(context, LISTEN_STATS_STORE)
    const current = await ListenStatsStore.getTotalMinutes(context)
    const next = current + minutes
    await prefs.put(KEY_TOTAL_MINUTES, next)
    await prefs.flush()
    return next
  }
}
