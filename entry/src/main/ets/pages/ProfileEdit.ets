import { picker } from '@kit.CoreFileKit'
import { AppStorageV2 } from '@kit.ArkUI'
import { UserProfileStore, UserProfile, UserProfileState } from '../models/UserProfileStore'

@Builder
export function ProfileEditBuilder() {
  ProfileEdit()
}

@ComponentV2
export struct ProfileEdit {
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!
  @Local profile: UserProfileState = AppStorageV2.connect(UserProfileState, 'USER_PROFILE', () => new UserProfileState())!
  @Local nickname: string = UserProfileStore.DEFAULT_NICKNAME
  @Local signature: string = UserProfileStore.DEFAULT_SIGNATURE
  @Local avatarUri: string = ''
  @Local bgUri: string = ''
  @Local saving: boolean = false

  aboutToAppear(): void {
    void this.loadProfile()
  }

  async loadProfile(): Promise<void> {
    // 优先从全局状态读（Mine 页已加载过），否则从持久化读
    if (this.profile.loaded) {
      this.nickname = this.profile.nickname
      this.signature = this.profile.signature
      this.avatarUri = this.profile.avatarUri
      this.bgUri = this.profile.bgUri
    } else {
      const p = await UserProfileStore.getProfile(getContext(this))
      this.nickname = p.nickname
      this.signature = p.signature
      this.avatarUri = p.avatarUri
      this.bgUri = p.bgUri
    }
  }

  async pickImage(): Promise<string> {
    try {
      const photoPicker = new picker.PhotoViewPicker()
      const selectRequest = new picker.PhotoSelectOptions()
      selectRequest.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE
      selectRequest.maxSelectNumber = 1
      const result = await photoPicker.select(selectRequest)
      if (result.photoUris && result.photoUris.length > 0) {
        return result.photoUris[0]
      }
    } catch (err) {
      console.error('pickImage failed: ' + JSON.stringify(err))
    }
    return ''
  }

  async onChangeAvatar(): Promise<void> {
    const uri = await this.pickImage()
    if (uri) {
      this.avatarUri = uri
    }
  }

  async onChangeBg(): Promise<void> {
    const uri = await this.pickImage()
    if (uri) {
      this.bgUri = uri
    }
  }

  async onSave(): Promise<void> {
    if (this.saving) return
    this.saving = true
    const finalNickname = this.nickname.trim() || UserProfileStore.DEFAULT_NICKNAME
    const finalSignature = this.signature.trim() || UserProfileStore.DEFAULT_SIGNATURE
    const profile: UserProfile = {
      nickname: finalNickname,
      signature: finalSignature,
      avatarUri: this.avatarUri,
      bgUri: this.bgUri
    }
    await UserProfileStore.saveProfile(getContext(this), profile)
    // 更新全局状态，Mine 页自动响应
    this.profile.nickname = finalNickname
    this.profile.signature = finalSignature
    this.profile.avatarUri = this.avatarUri
    this.profile.bgUri = this.bgUri
    this.profile.loaded = true
    this.saving = false
    this.pathStack.pop()
  }

  @Builder
  avatarImage() {
    if (this.avatarUri) {
      Image(this.avatarUri)
        .width(88).height(88)
        .borderRadius(44)
        .border({ width: 3, color: Color.White })
        .objectFit(ImageFit.Cover)
        .onClick(() => { void this.onChangeAvatar() })
    } else {
      Image($r('app.media.touxiang'))
        .width(88).height(88)
        .borderRadius(44)
        .border({ width: 3, color: Color.White })
        .objectFit(ImageFit.Cover)
        .onClick(() => { void this.onChangeAvatar() })
    }
  }

  @Builder
  bgImage() {
    if (this.bgUri) {
      Image(this.bgUri)
        .width('100%').height(220)
        .objectFit(ImageFit.Cover)
    } else {
      Image($r('app.media.beijingtu'))
        .width('100%').height(220)
        .objectFit(ImageFit.Cover)
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        Row() {
          Image($r('app.media.ic_back'))
            .width(22).height(22).fillColor('#333')
            .onClick(() => { this.pathStack.pop() })
          Text('编辑资料')
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#222')
            .layoutWeight(1).textAlign(TextAlign.Center)
          Row().width(22)
        }
        .width('100%')
        .height(52)
        .padding({ left: 16, right: 16 })
        .backgroundColor(Color.White)

        Scroll() {
          Column({ space: 16 }) {
            // 背景图 + 更换按钮
            Stack({ alignContent: Alignment.BottomEnd }) {
              this.bgImage()
              Text('更换背景')
                .fontSize(12).fontColor(Color.White)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('rgba(0,0,0,0.45)')
                .borderRadius(16)
                .margin({ right: 16, bottom: 16 })
                .onClick(() => { void this.onChangeBg() })
            }
            .width('100%')
            .borderRadius(16)
            .clip(true)

            // 头像（负 margin 上移叠加在背景图上）
            Column({ space: 8 }) {
              this.avatarImage()
              Text('点击更换头像')
                .fontSize(12).fontColor('#999')
            }
            .alignItems(HorizontalAlign.Center)
            .margin({ top: -44, bottom: 4 })

            // 表单卡片
            Column({ space: 16 }) {
              // 昵称
              Column({ space: 8 }) {
                Text('昵称')
                  .fontSize(14).fontColor('#666').fontWeight(FontWeight.Medium)
                  .margin({ left: 4 })
                Row() {
                  TextInput({ text: this.nickname, placeholder: '请输入昵称' })
                    .fontSize(15).fontColor('#222')
                    .layoutWeight(1)
                    .backgroundColor(Color.Transparent)
                    .height(48)
                    .padding({ left: 14, right: 14 })
                    .maxLength(20)
                    .onChange((value: string) => { this.nickname = value })
                }
                .width('100%')
                .height(48)
                .backgroundColor('#f7f8fa')
                .borderRadius(12)
              }
              .width('100%')

              // 个性签名
              Column({ space: 8 }) {
                Text('个性签名')
                  .fontSize(14).fontColor('#666').fontWeight(FontWeight.Medium)
                  .margin({ left: 4 })
                TextArea({ text: this.signature, placeholder: '介绍一下自己吧' })
                  .fontSize(15).fontColor('#222')
                  .width('100%')
                  .backgroundColor('#f7f8fa')
                  .borderRadius(12)
                  .height(90)
                  .padding(14)
                  .maxLength(50)
                  .onChange((value: string) => { this.signature = value })
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 10, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 2 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 20 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        // 保存按钮
        Button(this.saving ? '保存中...' : '保存')
          .width('100%')
          .height(50)
          .fontSize(16).fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor('#ff5186')
          .borderRadius(25)
          .enabled(!this.saving)
          .margin({ left: 16, right: 16, bottom: 20 })
          .shadow({ radius: 12, color: 'rgba(255,81,134,0.35)', offsetX: 0, offsetY: 4 })
          .onClick(() => { void this.onSave() })
      }
      .width('100%').height('100%')
      .backgroundColor('#f5f6fa')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
    .hideBackButton(true)
  }
}
