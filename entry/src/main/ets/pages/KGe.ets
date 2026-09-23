//K歌选歌列表加入口
import { SongItemType } from '../models/music'
import { AppStorageV2 } from '@kit.ArkUI'
import { GlobalMusic } from '../models/globalMusic'
import { image } from '@kit.ImageKit'
import effectKit from '@ohos.effectKit'

interface RecordParams {
  song: SongItemType
}

@ComponentV2
export struct KGe {
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!
  @Local playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  @Local bannerColor: string = '#ff5186'

  songList: SongItemType[] = [
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/0.jpg',
      name: '直到世界的尽头',
      author: 'WANDS',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/0.m4a',
      id: '0000',
      lyrics: '大都会に 僕はもう一人で\n投げ捨てられた 空きカンのようだ\n互いのすべてを 知りつくすまでが\n愛ならば いっそ 永久に眠ろうか\n世界が終わるまでは 離れる事もない\nそう願っていた 幾千の夜と\n戻らない時だけが 何故輝いては\nやつれ切った 心までも 壊す\nはかなき想い このTragedy Night\nそして人は こたえを求めて\nかけがえのない 何かを失う\n欲望だらけの 街じゃ 夜空の\n星屑も 僕らを 灯せない\n世界が終わる前に 聞かせておくれよ\n満開の花が 似合いのCatastrophe\n誰もが望みながら 永遠を信じない\nなのに きっと 明日を夢見てる\nはかなき日々と このTragedy Night\n世界が終わるまでは 離れる事もない\nそう願っていた 幾千の夜と\n戻らない時だけが 何故輝いては\nやつれ切った 心までも 壊す\nはかなき想い このTragedy Night'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/1.jpg',
      name: '画',
      author: '赵磊',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/1.mp3',
      id: '0001',
      lyrics: '为寂寞的夜空画上一个月亮\n把我画在那月亮下面歌唱\n为冷清的房子画上一扇大窗\n再画上一张床\n画一个姑娘陪着我\n再画个花边的被窝\n画上灶炉与柴火\n我们一起生来一起活\n画一群鸟儿围着我\n再画上绿岭和青坡\n画上宁静与祥和\n雨点儿在稻田上飘落\n画上有你能用手触到的彩虹\n画中有我决定不灭的星空\n画上弯曲无尽平坦的小路\n尽头的人家梦已入\n画上母亲安详的姿势\n还有橡皮能擦去的争执\n画上四季都不愁的粮食\n悠闲的人从没心事\n我没有擦去争吵的橡皮\n只有一支画着孤独的笔\n那夜空的月也不再亮\n只有个忧郁的孩子在唱'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/2.jpg',
      name: 'Sweet Dreams',
      author: 'TPaul Sax / Eurythmics',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/2.mp3',
      id: '0002',
      lyrics: 'Sweet dreams are made of this\nWho am I to disagree\nI travel the world and the seven seas\nEverybody\'s looking for something\nSome of them want to use you\nSome of them want to get used by you\nSome of them want to abuse you\nSome of them want to be abused\nSweet dreams are made of this\nWho am I to disagree\nI travel the world and the seven seas\nEverybody\'s looking for something\nHold your head up\nKeep your head up moving on\nHold your head up moving on\nSome of them want to use you\nSome of them want to get used by you\nSome of them want to abuse you\nSome of them want to be abused\nSweet dreams are made of this\nWho am I to disagree\nI travel the world and the seven seas\nEverybody\'s looking for something'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/3.jpg',
      name: '奢香夫人',
      author: '凤凰传奇',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/3.m4a',
      id: '0003',
      lyrics: '落脚河上面崖对崖\n威宁草海荞花盛开\n谁把月亮挂天上\n照得想说的话 流成海\n流成海\n越过绵绵的高山 越过无尽的沧海\n如果期待依然在 总是春暖到花开\n请你轻轻留下来 让梦卷走这尘埃\n香飘在书厢之外 奏响美丽的天籁\n不等三更过天晓白 奢香夫人赶月归来\n她把日光画心上 照得漆黑的夜 亮堂堂\n亮堂堂\n乌蒙山连着山外山 月光洒下了响水滩\n有没有人能告诉我 可是苍天对你在呼唤\n一座山翻过一条河 千山万水永不寂寞\n你来过年华被传说 百里杜鹃不凋落\n乌蒙山连着山外山 月光洒下了响水滩\n有没有人能告诉我 可是苍天对你在呼唤\n一座山翻过一条河 走过千山万水永不寂寞\n你来过年华被传说 百里杜鹃不凋落'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/4.jpg',
      name: '空心',
      author: '光泽',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/4.mp3',
      id: '0004',
      lyrics: '热爱曾是唯一的信仰\n相互凝望让对方捆绑\n在那时候简单的好傻\n却又空前绝后快乐啊\n直到现实狠狠推一把\n跌到浑身是伤疤\n你在欲望面前投降\n我在伤痛后面成长\n终于知道爱都有翅膀\n怎么拥抱它终究要飞翔\n漆黑空心也想被释放\n奈何思念比恨更顽强\n有个怀抱暖得像张床\n有份善良微笑多晴朗\n有一张唇美丽又疯狂\n为何爱谁心都空荡荡\n当我听说你与他散场\n狼狈回家带着伤\n朋友都说那是惩罚\n我的心却多么痛啊\n虽然知道爱都有翅膀\n因为太爱所以会原谅\n漆黑空心也想被释放\n奈何思念比恨更顽强\n无法割舍就别怕感伤\n我也嫌我对你太滚烫\n深爱就像一种命一样\n没有任何方法能阻挡\n就算知道爱都有翅膀\n还是愿意让你停靠在我肩膀\n你也不用把我当作家\n把我当成一棵树吧',
      lyricTimestamps: [15.6, 22.3, 29.1, 36.1, 41.8, 48.6, 55.3, 62.3, 73.8, 80.6, 87.6, 94.3, 104.6, 111.6, 118.3, 125.3, 130.8, 137.8, 144.6, 151.1, 162.8, 169.8, 176.8, 183.6, 189.6, 196.3, 203.3, 210.3, 216.6, 224.8, 231.8, 238.8],
      accompanyRawFile: 'kongxin_accomp.mp3'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/5.jpg',
      name: '反转地球',
      author: '潘玮柏',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/5.mp3',
      id: '0005',
      lyrics: 'Bow wow wow 让我看到你双手\n对抗地心引力一起反转地球\nBow wow wow 现在不适合啰嗦\n适者生存不然请你离开这节奏\nBow wow wow 让我看到你点头\n跟着我的音乐一起跳舞准没错\nBow wow wow 现在不适合闪躲\n正面出击看我怎么反转地球\n睁开双眼看穿地球\n赤裸裸的一片天空\n我摊开双手接受所有最原始的节奏\n有没有感到心情放松\n有没有感到细胞跳动\n节奏的变化身体的摆动\n让你全身放松\n现在起不能罗嗦\n踏进我的领域之中\n频率太震撼\n你的心脏正在此起彼落\n跟着我走跟着我做\n跟我点头摆动双手\n世界的一切的转动\n连结到我的音乐\n紧跟着我的脚步在走\n让世界 turn around dance around everybody have some fun\n别想压抑我们音乐世界的转动\n没有对或错我只想潜入这节奏\n音乐没有自由仿佛坠进了黑洞\n现在跟着我们创造新世纪的秩序\nBow wow wow 让我看到你双手\n推开地心引力一起反转地球\nBow wow wow 现在不适合罗嗦\n试着选择不然请你离开这节奏\nBow wow wow 让我看到你点头\n跟着我的音乐一起跳舞准没错\nBow wow wow 现在不适合闪躲\n正面出击看我怎么反转地球'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/6.jpg',
      name: 'No.9',
      author: 'T-ara',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/6.m4a',
      id: '0006',
      lyrics: '있잖아요 나 지금 너무 아프거든요\n너만이 날 웃게 하는\n너만이 날 울게 하는\n넌 나의 턱시도 가면 날 지켜준 히어로\n날 떠난 그대 미워요\n네가 필요해 넘버나인 넘버나인\n나를 떠나지 말아요\n날 잊었나요 넘버나인 넘버나인\n그대 없는 나 밤에 잠도 못 자요\n아 나 너무 아파서 그래요\n내 맘 다 가져간 그대는 어디 있나요\n돌아와요 넘버나인\n자꾸 날 들었다 놨다 하지 말아요\n자꾸 나 들렸다 놨다 힘이 드네요\n무화과꽃도 피게 만들었던\n그때 있잖아요\nI\'m addict I\'m addict\n또 눈을 감았다 뜨면 여기 나 혼자 있어\nI\'m in the dark in the dark\n네가 필요해 넘버나인 넘버나인\n나를 떠나지 말아요\n날 잊었나요 넘버나인 넘버나인\n그대 없는 나 밤에 잠도 못 자요\n아 나 너무 아파서 그래요\n내 맘 다 가져간 그대는 어디 있나요\n돌아와요 넘버나인'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/7.jpg',
      name: '孤独',
      author: 'G.E.M.邓紫棋',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/7.m4a',
      id: '0007',
      lyrics: '又是另一个夜 雨飘的夜\n在一条喧闹后的街 我望着月亮\n忘了是雨还是泪水突然滑过脸上\n心喃喃自语 我却又听不见\n白天 我总笑容满面\n为什么每夜 我总辗转难眠\n自律和压抑 到底如何分辨\n说要做自己 却不敢对自己正眼\n原来孤独 是灯光下 所有人都对我佩服\n但月光下 却一直害怕自己退步\n原来孤独 是想哭却又不想瞩目\n是努力融入 但你还常常感觉自己格格不入\n是不想辜负了期待 你却又感觉束缚\n唯一的安抚 是知道世界之大\n这一刻和你一样 感到孤独的 无数\n皎洁的月光 请洁净我\n洗净年月泼的墨\n熄灭我吞下的烟火\n我从小到大 凡事都要做到第一位\n再艰难咬着牙 再累我不流一滴泪\n我有着强迫症的意志力 天赋不能浪费\n这世界告诉你 成功要靠自己\n什么叫做成功我却不知道定义\n我已经变得热可炙手\n但优秀还是没有为我带来自由\n原来孤独 是感觉自己是那蓝天下的枯树\n站在高处 伤口得自己捂住 无处哭诉\n虽然我坚强但是我也偶尔无助\n每当我祈祷上帝说努力了就好\n但面对世界我只感觉自己瘦小'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/8.jpg',
      name: 'Lose Control',
      author: 'Hedley',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/8.m4a',
      id: '0008',
      lyrics: 'Can I make a little toast\nCan we get a little close\nCan I get an amen\nCan I get a hell yeah\nSomebody give me a beat\nLet me see you on your feet\nSomebody save your man\nI don\'t give a god damn\nI wanna be a freak\nCatch me if you can\nI don\'t think you understand where we\'re going\nWhen you feel it and you know\nWhen this shit\'s about to blow\nAnd it hits you\nIn my body in my bones\nDrop the beat and free my soul\nWhen I hear that rock and roll\nOh my God I lose control\nLa la la la oh oh oh\nI had to let it go\nOh my God I lose control\nLike a shot to the face\nNow you got a little taste\nGet up stand up\nShake your butt to the bass\nWhen you break it down\nThey\'re gonna love the sound\nEverybody just stop\nAnd bring it back around\nCatch me if you can\nI don\'t think you understand where we\'re going\nWhen you feel it and you know\nWhen this shit\'s about to blow\nAnd it hits you\nIn my body in my bones\nDrop the beat and free my soul\nWhen I hear that rock and roll\nOh my God I lose control'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/9.jpg',
      name: '倩女幽魂',
      author: '张国荣',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/9.m4a',
      id: '0009',
      lyrics: '人生路 美梦似路长\n路里风霜 风霜扑面干\n红尘里 美梦有几多方向\n找痴痴梦幻中心爱\n路随人茫茫\n人生是 美梦与热望\n梦里依稀 依稀有泪光\n何从何去 去觅我心中方向\n风仿佛在梦中轻叹\n路和人茫茫\n人间路 快乐少年郎\n路里崎岖 崎岖不见阳光\n泥尘里 快乐有几多方向\n一丝丝梦幻般风雨\n路随人茫茫\n丝丝梦幻般风雨\n路随人茫茫'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/10.jpg',
      name: '北京北京',
      author: '汪峰',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/10.m4a',
      id: '0010',
      lyrics: '当我走在这里的每一条街道\n我的心似乎从来都不能平静\n除了发动机的轰鸣和电气之音\n我似乎听到了他烛骨般的心跳\n我在这里欢笑 我在这里哭泣\n我在这里活着 也在这死去\n我在这里祈祷 我在这里迷惘\n我在这里寻找 也在这失去\n北京 北京\n咖啡馆与广场有三个街区\n就像霓虹灯到月亮的距离\n人们在挣扎中相互告慰和拥抱\n寻找着追逐着奄奄一息的碎梦\n我们在这儿欢笑 我们在这儿哭泣\n我们在这儿活着 也在这儿死去\n我们在这儿祈祷 我们在这儿迷惘\n我们在这儿寻找 也在这儿失去\n如果有一天我不得不离去\n我希望人们把我埋在这里\n在这我能感觉到我的存在\n在这有太多让我眷恋的东西\n我在这里欢笑 我在这里哭泣\n我在这里活着 也在这死去\n我在这里祈祷 我在这里迷惘\n我在这里寻找 也在这失去\n北京 北京'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/11.jpg',
      name: '苦笑',
      author: '汪苏泷',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/11.mp3',
      id: '0011',
      lyrics: '分手之后 你的温柔\n就分开 我把车窗偷偷摇下来\n看不见你脸上点点悲哀\n后照镜里反射我的无奈\n你不明白\n还等待 我还在原地傻傻的等待\n所有情绪在我脸上发呆\n突然间他影子出现太快\n故事精彩\n你说他对你温柔疼爱\n我想我是学不来\n怪我 没把爱说出来\n我苦笑着释怀 你给的伤害\n你苦笑着等待 已没有未来\n故事花开花败 都有人去猜\n你用优雅姿态 说你不会回来\n我的爱 从没有离开\n可惜两人相爱 总会有无奈\n你的爱很慷慨 分享的愉快\n原谅我只能挥手说拜拜'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/12.jpg',
      name: '一生所爱',
      author: '卢冠廷 / 莫文蔚',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/12.m4a',
      id: '0012',
      lyrics: '从前现在过去了再不来\n红红落叶长埋尘土内\n开始终结总是没变改\n天边的你飘泊白云外\n苦海翻起爱恨\n在世间难逃避命运\n相亲竟不可接近\n或我应该相信是缘分\n情人别后永远再不来\n无言独坐放眼尘世外\n鲜花总会凋谢\n但会再开\n一生所爱隐约\n在白云外\n苦海翻起爱恨\n在世间难逃避命运\n相亲竟不可接近\n或我应该相信是缘分'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/13.jpg',
      name: '月半小夜曲',
      author: '李克勤',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/13.mp3',
      id: '0013',
      lyrics: '仍然倚在失眠夜 望天边星宿\n仍然听见小提琴 如泣似诉再挑逗\n为何只剩一弯月 留在我的天空\n这晚以后音讯隔绝\n人如天上的明月 是不可拥有\n情如曲过只遗留 无可挽救再分别\n为何只是失望 填密我的空虚\n这晚夜没有吻别\n仍在说永久 想不到是借口\n从未意会要分手\n但我的心每分每刻 仍然被她占有\n她似这月儿 仍然是不开口\n提琴独奏独奏着 明月半倚深秋\n我的牵挂 我的渴望 直至以后\n仍然倚在失眠夜 望天边星宿\n仍然听见小提琴 如泣似诉再挑逗\n为何只剩一弯月 留在我的天空\n这晚以后音讯隔绝\n人如天上的明月 是不可拥有\n情如曲过只遗留 无可挽救再分别\n为何只是失望 填密我的空虚\n这晚夜没有吻别\n仍在说永久 想不到是借口\n从未意会要分手\n但我的心每分每刻 仍然被她占有\n她似这月儿 仍然是不开口\n提琴独奏独奏着 明月半倚深秋\n我的牵挂 我的渴望 直至以后'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/14.jpg',
      name: 'Rolling in the Deep',
      author: 'Adele',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/14.m4a',
      id: '0014',
      lyrics: 'There\'s a fire starting in my heart\nReaching a fever pitch and it\'s bringing me out the dark\nFinally I can see you crystal clear\nGo ahead and sell me out and I\'ll lay your ship bare\nSee how I\'ll leave with every piece of you\nDon\'t underestimate the things that I will do\nThere\'s a fire starting in my heart\nReaching a fever pitch and it\'s bringing me out the dark\nThe scars of your love remind me of us\nThey keep me thinking that we almost had it all\nThe scars of your love they leave me breathless\nI can\'t help feeling\nWe could have had it all\nRolling in the deep\nYou had my heart inside of your hand\nAnd you played it to the beat\nBaby I have no story to be told\nBut I\'ve heard one on you and I\'m gonna make your head burn\nThink of me in the depths of your despair\nMaking a home down there cause mine sure won\'t be shared\nThe scars of your love remind me of us\nThey keep me thinking that we almost had it all\nThe scars of your love they leave me breathless\nI can\'t help feeling\nWe could have had it all\nRolling in the deep\nYou had my heart inside of your hand\nAnd you played it to the beat\nWe could have had it all\nRolling in the deep\nYou had my heart inside of your hand\nBut you played it with a beating\nThrow your soul through every open door\nCount your blessings to find what you look for\nTurn my sorrow into treasured gold\nYou pay me back in kind and reap just what you sow\nWe could have had it all\nWe could have had it all\nWe could have had it all\nRolling in the deep\nYou had my heart inside of your hand\nAnd you played it to the beat'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/15.jpg',
      name: '海阔天空',
      author: 'Beyond',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/15.m4a',
      id: '0015',
      lyrics: '今天我 寒夜里看雪飘过\n怀着冷却了的心窝漂远方\n风雨里追赶 雾里分不清影踪\n天空海阔你与我 可会变（谁没在变）\n多少次 迎着冷眼与嘲笑\n从没有放弃过心中的理想\n一刹那恍惚 若有所失的感觉\n不知不觉已变淡 心里爱（谁明白我）\n原谅我这一生不羁放纵爱自由\n也会怕有一天会跌倒\n背弃了理想 谁人都可以\n哪会怕有一天只你共我\n仍然自由自我 永远高唱我歌 走遍千里\n原谅我这一生不羁放纵爱自由\n也会怕有一天会跌倒\n背弃了理想 谁人都可以\n哪会怕有一天只你共我'
    }
  ]

  aboutToAppear(): void {
    void this.extractBannerColor()
  }

  async extractBannerColor(): Promise<void> {
    try {
      const context = getContext(this)
      const fileData = await context.resourceManager.getMediaContent($r('app.media.kge_banner'))
      const imageSource = image.createImageSource(fileData.buffer)
      const pixelMap = await imageSource.createPixelMap()
      effectKit.createColorPicker(pixelMap, (err: Error, colorPicker: effectKit.ColorPicker) => {
        if (err || !colorPicker) return
        const c = colorPicker.getMainColorSync()
        this.bannerColor = '#' +
          c.red.toString(16).padStart(2, '0') +
          c.green.toString(16).padStart(2, '0') +
          c.blue.toString(16).padStart(2, '0')
      })
    } catch (e) {
      console.error('extractBannerColor error: ' + JSON.stringify(e))
    }
  }

  build() {
    Scroll() {
      Column() {
        // 顶部 K歌 banner（红色径向渐变渲染 + 粉色外发光）
        Image($r('app.media.kge_banner'))
          .width('100%')
          .height(200)
          .objectFit(ImageFit.Contain)
          .radialGradient({
            center: ['50%', '50%'],
            radius: 220,
            colors: [['#ff5186', 0], ['#c9184a', 0.55], ['#6a040f', 1]]
          })
          .borderRadius(20)
          .shadow({ radius: 16, color: 'rgba(255,81,134,0.35)', offsetX: 0, offsetY: 4 })

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
      .padding({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .linearGradient({
      angle: 180,
      colors: [[this.bannerColor + '33', 0], [this.bannerColor + '11', 0.3], ['#ffffff', 0.55]]
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
