import { preferences } from '@kit.ArkData'

const PROFILE_STORE = 'user_profile_store'
const KEY_NICKNAME = 'nickname'
const KEY_SIGNATURE = 'signature'
const KEY_AVATAR_URI = 'avatar_uri'
const KEY_BG_URI = 'bg_uri'

export interface UserProfile {
  nickname: string
  signature: string
  avatarUri: string
  bgUri: string
}

// AppStorageV2 全局状态类，Mine 页和编辑页共享同一实例
// @ObservedV2 + @Trace 让属性变化能触发跨页面 UI 刷新
@ObservedV2
export class UserProfileState {
  @Trace nickname: string = UserProfileStore.DEFAULT_NICKNAME
  @Trace signature: string = UserProfileStore.DEFAULT_SIGNATURE
  @Trace avatarUri: string = ''
  @Trace bgUri: string = ''
  @Trace loaded: boolean = false
}

export class UserProfileStore {
  static readonly DEFAULT_NICKNAME = '音乐调味人生'
  static readonly DEFAULT_SIGNATURE = '用音乐记录生活的每一个瞬间'

  static async getProfile(context: Context): Promise<UserProfile> {
    try {
      const prefs = await preferences.getPreferences(context, PROFILE_STORE)
      const nickname = await prefs.get(KEY_NICKNAME, UserProfileStore.DEFAULT_NICKNAME)
      const signature = await prefs.get(KEY_SIGNATURE, UserProfileStore.DEFAULT_SIGNATURE)
      const avatarUri = await prefs.get(KEY_AVATAR_URI, '')
      const bgUri = await prefs.get(KEY_BG_URI, '')
      return {
        nickname: typeof nickname === 'string' ? nickname : UserProfileStore.DEFAULT_NICKNAME,
        signature: typeof signature === 'string' ? signature : UserProfileStore.DEFAULT_SIGNATURE,
        avatarUri: typeof avatarUri === 'string' ? avatarUri : '',
        bgUri: typeof bgUri === 'string' ? bgUri : ''
      }
    } catch (err) {
      console.error('UserProfileStore getProfile failed: ' + JSON.stringify(err))
      return {
        nickname: UserProfileStore.DEFAULT_NICKNAME,
        signature: UserProfileStore.DEFAULT_SIGNATURE,
        avatarUri: '',
        bgUri: ''
      }
    }
  }

  static async saveProfile(context: Context, profile: UserProfile): Promise<void> {
    const prefs = await preferences.getPreferences(context, PROFILE_STORE)
    await prefs.put(KEY_NICKNAME, profile.nickname)
    await prefs.put(KEY_SIGNATURE, profile.signature)
    await prefs.put(KEY_AVATAR_URI, profile.avatarUri)
    await prefs.put(KEY_BG_URI, profile.bgUri)
    await prefs.flush()
  }
}
