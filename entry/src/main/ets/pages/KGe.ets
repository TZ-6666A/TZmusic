//K歌页面
import { SongItemType } from '../models/music'
import { AppStorageV2 } from '@kit.ArkUI'
import { GlobalMusic } from '../models/globalMusic'

interface RecordParams {
  song: SongItemType
}

@ComponentV2
export struct KGe {
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!
  @Local playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!

  songList: SongItemType[] = [
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/0.jpg',
      name: '直到世界的尽头',
      author: 'WANDS',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/0.m4a',
      id: '0000',
      lyrics: '大都会に 僕はもう一人で\n投げ捨てられた 空き缶のようだ\n互いのすべてを 知りつくすまでが\n愛ならば いっそ 永久に眠ろうか\n世界が終わるまでは 離れる事もない\nそう願っていた 幾千の夜と'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/1.jpg',
      name: '画',
      author: '赵磊',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/1.mp3',
      id: '0001',
      lyrics: '我把你画成花 未开的一朵花\n再把思念一点一滴画成雨落下\n每当我不在 请记得我的爱\n就在同一天空之下遥远地灌溉\n等待秋去春来 等待一次花开'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/2.jpg',
      name: 'Sweet Dreams',
      author: 'TPaul Sax / Eurythmics',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/2.mp3',
      id: '0002',
      lyrics: 'Sweet dreams are made of this\nWho am I to disagree\nTravel the world and the seven seas\nEverybody is looking for something\nSome of them want to use you'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/3.jpg',
      name: '奢香夫人',
      author: '凤凰传奇',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/3.m4a',
      id: '0003',
      lyrics: '越过绵绵的高山 越过无尽的沧海\n如果期待依然在 总是春暖到花开\n请你轻轻留下来 让梦卷走这尘埃\n香飘在书厢之外 奏响美丽的天籁'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/4.jpg',
      name: '空心',
      author: '光泽',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/4.mp3',
      id: '0004',
      lyrics: '你设的陷阱 我竟然陷了进去\n你不说一句 我竟然没有原因\n我竟然相信 你的一字一句\n多可笑的剧情 还演得那么用心'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/5.jpg',
      name: '反转地球',
      author: '潘玮柏',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/5.mp3',
      id: '0005',
      lyrics: 'Bow wow wow 让我看到你双手\n推开地心引力一起反转地球\nBow wow wow 现在不适合啰嗦\n适者生存不然请你离开这节奏'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/6.jpg',
      name: 'No.9',
      author: 'T-ara',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/6.m4a',
      id: '0006',
      lyrics: 'Number nine 你是我世界的中心\nNumber nine 只想把你捧在手心\n数到九 就会来到我身边\n像梦一样 甜蜜的你的告白'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/7.jpg',
      name: '孤独',
      author: 'G.E.M.邓紫棋',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/7.m4a',
      id: '0007',
      lyrics: '当世界只剩下我一个人\n孤独的感觉像世界末日来临\n一个人呼吸 一个人流泪\n一个人的世界 不需要谁'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/8.jpg',
      name: 'Lose Control',
      author: 'Hedley',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/8.m4a',
      id: '0008',
      lyrics: 'I lose control\nWhen I see you standing there\nI lose control\nCan\'t help myself but stare'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/9.jpg',
      name: '倩女幽魂',
      author: '张国荣',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/9.m4a',
      id: '0009',
      lyrics: '人生路 美梦似路长\n路里风霜 风霜扑面干\n红尘里 美梦有几多方向\n找痴痴梦幻中心爱 路随人茫茫'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/10.jpg',
      name: '北京北京',
      author: '汪峰',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/10.m4a',
      id: '0010',
      lyrics: '当我走在这里的每一条街道\n我的心似乎从来都不能平静\n除了发动机的轰鸣和电气之音\n我似乎听到了它烛骨般的心跳'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/11.jpg',
      name: '苦笑',
      author: '汪苏泷',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/11.mp3',
      id: '0011',
      lyrics: '原来这就是曲终人散的寂寞\n我还想等你什么\n原来这就是爱到深处的结果\n我却只能苦笑着'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/12.jpg',
      name: '一生所爱',
      author: '卢冠廷 / 莫文蔚',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/12.m4a',
      id: '0012',
      lyrics: '从前现在过去了再不来\n红红落叶长埋尘土内\n开始终结总是没变改\n天边的你飘泊白云外'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/13.jpg',
      name: '月半小夜曲',
      author: '李克勤',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/13.mp3',
      id: '0013',
      lyrics: '仍然倚在失眠夜 望天边星宿\n仍然听见小提琴 如泣似诉再挑逗\n为何只剩一弯月 留在我的天空\n这晚夜没有吻别'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/14.jpg',
      name: 'Rolling in the Deep',
      author: 'Adele',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/14.m4a',
      id: '0014',
      lyrics: 'There\'s a fire starting in my heart\nReaching a fever pitch\nAnd it\'s bringing me out the dark\nFinally I can see you crystal clear'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/15.jpg',
      name: '海阔天空',
      author: 'Beyond',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/15.m4a',
      id: '0015',
      lyrics: '今天我 寒夜里看雪飘过\n怀着冷却了的心窝漂远方\n风雨里追赶 雾里分不清影踪\n天空海阔你与我 可会变'
    }
  ]

  build() {
    Scroll() {
      Column() {
        // 顶部 K歌 banner
        Image($r('app.media.kge_banner'))
          .width('100%')
          .height(200)
          .objectFit(ImageFit.Contain)
          .backgroundColor('#f5f5f5')
          .borderRadius(20)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

        // 歌曲列表
        ForEach(this.songList, (item: SongItemType, index: number) => {
          Row() {
            // 序号
            Text((index + 1).toString().padStart(2, '0'))
              .fontColor(index < 3 ? '#ff5186' : '#bbb')
              .fontSize(16)
              .fontWeight(index < 3 ? FontWeight.Bold : FontWeight.Normal)
              .width(36)
              .textAlign(TextAlign.Center)

            // 歌曲封面
            Image(item.img)
              .width(52)
              .height(52)
              .borderRadius(8)
              .margin({ right: 12 })

            // 歌曲信息
            Column({ space: 4 }) {
              Text(item.name)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#222')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(item.author)
                .fontSize(12)
                .fontColor('#aaa')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            // 正在播放
            if (this.playState.url === item.url && this.playState.isPlay) {
              Image($r('app.media.wave'))
                .width(22)
                .margin({ right: 8 })
            }

            // K歌图标
            Image($r('app.media.ic_more'))
              .width(18)
              .height(18)
              .fillColor('#ccc')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .alignItems(VerticalAlign.Center)
          .border({
            width: { bottom: 0.5 },
            color: '#f0f0f0'
          })
          .onClick(() => {
            this.pathStack.pushPathByName('Record', { song: item } as RecordParams, false)
          })
        })

        // 底部留白
        Row().height(20)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(Color.White)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
