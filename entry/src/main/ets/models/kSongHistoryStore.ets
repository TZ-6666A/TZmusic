import { preferences } from '@kit.ArkData'

const KSONG_STORE = 'ksong_history_store'
const KEY_WORKS = 'works'

export interface KSongWork {
  id: string
  songName: string
  author: string
  img: string
  filePath: string
  duration: number
  createdAt: number
}

export class KSongHistoryStore {
  static async getAll(context: Context): Promise<KSongWork[]> {
    try {
      const prefs = await preferences.getPreferences(context, KSONG_STORE)
      const value = await prefs.get(KEY_WORKS, '[]')
      const json = typeof value === 'string' ? value : '[]'
      return JSON.parse(json) as KSongWork[]
    } catch (err) {
      console.error('KSongHistoryStore getAll failed: ' + JSON.stringify(err))
      return []
    }
  }

  static async add(context: Context, work: KSongWork): Promise<void> {
    const prefs = await preferences.getPreferences(context, KSONG_STORE)
    const works = await KSongHistoryStore.getAll(context)
    works.unshift(work)
    await prefs.put(KEY_WORKS, JSON.stringify(works))
    await prefs.flush()
  }

  static async remove(context: Context, id: string): Promise<KSongWork | null> {
    const prefs = await preferences.getPreferences(context, KSONG_STORE)
    const works = await KSongHistoryStore.getAll(context)
    const target = works.find((item: KSongWork) => item.id === id) || null
    const nextWorks = works.filter((item: KSongWork) => item.id !== id)
    await prefs.put(KEY_WORKS, JSON.stringify(nextWorks))
    await prefs.flush()
    return target
  }
}
