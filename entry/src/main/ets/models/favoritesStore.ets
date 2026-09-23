// 收藏/喜欢 共享状态（Preferences 持久化）
import { SongItemType } from './music'
import { preferences } from '@kit.ArkData'

const STORE_NAME = 'favorites_store'
const KEY_LIKED = 'liked_songs'

@ObservedV2
export class FavoritesStore {
  @Trace likedSongs: SongItemType[] = []
  @Trace likedIds: string[] = []
  private prefs?: preferences.Preferences
  private ready: boolean = false

  // 初始化：从磁盘读取收藏数据（EntryAbility 中调用一次）
  async init(context: Context): Promise<void> {
    if (this.ready) return
    try {
      this.prefs = await preferences.getPreferences(context, STORE_NAME)
      const value = await this.prefs.get(KEY_LIKED, '[]')
      const jsonStr = typeof value === 'string' ? value : '[]'
      const songs: SongItemType[] = JSON.parse(jsonStr)
      this.likedSongs = songs
      this.refreshLikedIds()
      this.ready = true
    } catch (err) {
      console.error('FavoritesStore init failed:', JSON.stringify(err))
      this.likedSongs = []
      this.likedIds = []
      this.ready = true
    }
  }

  // 是否已收藏
  isLiked(id: string): boolean {
    if (!id) return false
    return this.likedIds.indexOf(id) >= 0
  }

  // 切换收藏状态
  toggleLike(song: SongItemType): void {
    const songId: string = song.id || (song.url as string)
    if (!songId) return
    const idx = this.likedIds.indexOf(songId)
    if (idx >= 0) {
      this.likedIds.splice(idx, 1)
      this.likedSongs.splice(idx, 1)
    } else {
      const stored: SongItemType = {
        img: song.img,
        name: song.name,
        author: song.author,
        url: song.url,
        id: songId,
        lyrics: song.lyrics,
        rawFile: song.rawFile
      }
      this.likedIds.push(songId)
      this.likedSongs.push(stored)
    }
    void this.save()
  }

  private refreshLikedIds(): void {
    this.likedIds = this.likedSongs.map((song: SongItemType) => (song.id || song.url) as string)
  }

  // 持久化到磁盘
  private async save(): Promise<void> {
    if (!this.prefs) return
    try {
      await this.prefs.put(KEY_LIKED, JSON.stringify(this.likedSongs))
      await this.prefs.flush()
    } catch (err) {
      console.error('FavoritesStore save failed:', JSON.stringify(err))
    }
  }
}
