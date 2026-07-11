interface SingerDetailParams {
  img?: string | Resource
  name?: string
  title?: string
  count?: string
  bio?: string
  tags?: string[]
}

@Builder
export function SingerDetailBuilder() {
  SingerDetail()
}

@ComponentV2
struct SingerDetail {
  pathStack: NavPathStack = new NavPathStack()
  @Local img: string | Resource = ''
  @Local name: string = '热门歌手'
  @Local title: string = ''
  @Local count: string = '0'
  @Local bio: string = ''
  @Local tags: string[] = []

  getSingerName(title: string): string {
    if (!title) {
      return '热门歌手'
    }
    const index = title.indexOf(':')
    if (index > 0) {
      return title.substring(0, index)
    }
    return title.split(' ')[0] || '热门歌手'
  }

  getSingerBio(name: string, fallback: string): string {
    if (name === '周杰伦') {
      return '周杰伦是华语流行音乐中极具代表性的唱作人，作品融合 R&B、说唱、古典、中国风等元素，旋律辨识度高，编曲想象力强。从青春叙事到东方意象，他把流行音乐做出鲜明个人标签，也影响了后来大量华语创作者。'
    }
    if (name === '林俊杰') {
      return '林俊杰以稳定唱功、细腻转音和高完成度旋律著称，兼具创作、制作与现场演唱能力。他的作品常在抒情、电子和流行摇滚之间切换，情绪推进清晰，副歌记忆点强，是华语乐坛长期保持影响力的实力唱作人。'
    }
    if (name === '孙燕姿') {
      return '孙燕姿的声音清澈直接，兼具少年感和故事感。她的歌曲常以克制的编曲承载真实情绪，表达孤独、成长、告别与勇气。独特音色让她在华语女声中辨识度极高，也成为许多人青春记忆里的重要名字。'
    }
    if (name === '薛之谦') {
      return '薛之谦擅长用戏剧化叙事包装情歌，把自嘲、遗憾、拉扯和深情放进旋律里。他的作品副歌爆发力强，歌词画面感明显，常能击中大众情绪。舞台之外，他也凭借鲜明表达方式形成了稳定的个人风格。'
    }
    if (name === '李荣浩') {
      return '李荣浩是创作辨识度很强的唱作人，常独立完成词曲、编曲和制作。他的音乐不依赖复杂堆叠，更重视节奏、留白和生活化表达。冷静的唱腔配合市井感歌词，让他的作品有独特的都市叙事气质。'
    }
    if (name === '鞠婧祎') {
      return '鞠婧祎从偶像舞台走向影视与音乐多栖发展，形象风格精致，舞台表达偏甜美和视觉化。她的作品常结合古风、流行和唱跳元素，适合年轻化传播场景，也让个人标签在音乐与影视之间持续延展。'
    }
    if (name === '许嵩') {
      return '许嵩是华语网络音乐时代成长起来的代表唱作人，长期保持独立创作习惯。作品常把古典意象、青春记忆和现实观察放进歌词里，旋律温和但有态度。他的音乐带有鲜明文字感和个人审美。'
    }
    if (name === '颜中人') {
      return '颜中人的声音带有沙哑质感，适合深夜、失眠和情绪治愈类场景。他的歌曲更强调氛围和共情，常用低饱和度的旋律表达遗憾、陪伴和释怀。对喜欢慢歌和情绪歌的用户来说，辨识度比较明显。'
    }
    return fallback || '这位歌手在平台热度较高，作品风格鲜明，适合在推荐页继续探索。'
  }

  getSingerTags(name: string): string[] {
    if (name === '周杰伦') return ['国风', '唱作']
    if (name === '林俊杰') return ['高音', '唱作']
    if (name === '孙燕姿') return ['治愈', '清澈声线']
    if (name === '薛之谦') return ['情歌', '叙事感']
    if (name === '李荣浩') return ['都市', '词曲创作']
    if (name === '鞠婧祎') return ['唱跳', '古风']
    if (name === '许嵩') return ['独立创作', '青春']
    if (name === '颜中人') return ['深夜', '治愈']
    return ['华语', '流行']
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Column() {
          Image(this.img)
            .width('100%')
            .aspectRatio(1)
            .objectFit(ImageFit.Cover)
            .borderRadius({ bottomLeft: 24, bottomRight: 24 })
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

          Column({ space: 12 }) {
            Text(this.name)
              .fontSize(27)
              .fontWeight(FontWeight.Bold)
              .fontColor('#222')
              .textAlign(TextAlign.Center)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')

            Flex({ justifyContent: FlexAlign.Center, wrap: FlexWrap.Wrap }) {
              Text(this.count + ' 热度')
                .fontSize(12)
                .fontColor('#ff5186')
                .fontWeight(FontWeight.Medium)
                .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                .backgroundColor('#fff1f6')
                .border({ width: 1, color: '#ffd3e2' })
                .borderRadius(18)
                .margin({ right: 8, bottom: 6 })

              ForEach(this.tags, (tag: string) => {
                Text(tag)
                  .fontSize(12)
                  .fontColor('#ff5186')
                  .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                  .backgroundColor('#fff1f6')
                  .border({ width: 1, color: '#ffd3e2' })
                  .borderRadius(18)
                  .margin({ right: 8, bottom: 6 })
              })
            }
            .width('100%')

            Text('歌手简介')
              .fontSize(21)
              .fontWeight(FontWeight.Bold)
              .fontColor('#222')
              .width('100%')

            Text(this.bio)
              .fontSize(15)
              .fontColor('#666')
              .lineHeight(25)
              .width('100%')

            Button('返回')
              .width('100%')
              .height(46)
              .fontSize(15)
              .fontColor('#333')
              .backgroundColor('#f1f1f1')
              .borderRadius(16)
              .margin({ top: 10 })
              .onClick(() => {
                this.pathStack.pop()
              })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 18, right: 18, top: 8, bottom: 32 })
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 22, topRight: 22 })
          .margin({ top: -28 })
        }
        .width('100%')
        .height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
        .backgroundColor(Color.White)
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      const p = context.pathInfo?.param as SingerDetailParams
      if (p) {
        this.img = p.img || ''
        this.title = p.title || ''
        this.name = p.name || this.getSingerName(this.title)
        this.count = p.count || '0'
        this.bio = p.bio || this.getSingerBio(this.name, this.title)
        this.tags = p.tags || this.getSingerTags(this.name)
      }
    })
  }
}
