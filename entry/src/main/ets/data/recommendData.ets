import { SongItemType } from '../models/music'

export interface recommendDailyType {
  img: string | Resource  // 图片
  title: string // 简介文字
  top:string    // 标题背景色
  bottom: string // 简介背景色
  songs: SongItemType[]  // 歌单歌曲列表
}

//热门歌手数据接口
export interface recommendListType {
  img: string| Resource
  name?: string
  title: string
  count:string
  bio?: string
  tags?: string[]
  works?: string[]
}

// 轮播图数据
export const swiperList: Resource[] = [
  $r('app.media.lunbotu1'),
  $r('app.media.lunbotu2'),
  $r('app.media.lunbotu3'),
  $r('app.media.lunbotu4'),
  $r('app.media.lunbotu5'),
]
// 每日推荐数据
export const dailyRecommend: recommendDailyType[] = [
  {
    img: $r('app.media.fengmian2'),
    title: '生活忙忙碌碌，不妨静下心来享受一会极致的救赎',
    top: '#5b9bd5',
    bottom: '#ba627fa3',
    songs: [
      {
        img: $r("app.media.shenghuo1"),
        name: '宏伟计划（The Grand Plan）',
        author: 'Wonders of Earth（地球奇观）',
        url: 'shenghuo1.mp3',
        rawFile: 'shenghuo1.mp3',
        id: '0018'
      },
      {
        img: $r("app.media.shenghuo2"),
        name: 'Moment of Peace',
        author: '米奇猫',
        url: 'shenghuo2.mp3',
        rawFile: 'shenghuo2.mp3',
        id: '0019'
      },
      {
        img: $r("app.media.shenghuo3"),
        name: 'Silent Horizon',
        author: 'Mason Reed',
        url: 'shenghuo3.mp3',
        rawFile: 'shenghuo3.mp3',
        id: '0031'
      },
      {
        img: $r("app.media.shenghuo4"),
        name: 'Broken Starlight',
        author: 'Emma Collins',
        url: 'shenghuo4.mp3',
        rawFile: 'shenghuo4.mp3',
        id: '0032'
      },
      {
        img: $r("app.media.shenghuo5"),
        name: 'Golden Waves',
        author: 'Jack Harrison',
        url: 'shenghuo5.mp3',
        rawFile: 'shenghuo5.mp3',
        id: '0033'
      },
      {
        img: $r("app.media.shenghuo6"),
        name: 'Dream Beyond Time',
        author: 'Chloe Morgan',
        url: 'shenghuo6.mp3',
        rawFile: 'shenghuo6.mp3',
        id: '0034'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/2.jpg',
        name: 'Sweet Dreams',
        author: 'TPaul Sax / Eurythmics',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/2.mp3',
        id: '0002'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/8.jpg',
        name: 'Lose Control',
        author: 'Hedley',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/8.m4a',
        id: '0008'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/14.jpg',
        name: 'Rolling in the Deep',
        author: 'Adele',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/14.m4a',
        id: '0014'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/6.jpg',
        name: 'No.9',
        author: 'T-ara',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/6.m4a',
        id: '0006'
      },

    ]
  },
  {
    img: $r('app.media.fengmian1'),
    title: '打游戏必备，游戏专属bgm,让你可以大杀四方',
    top: '#666666',
    bottom: '#382e2f',
    songs: [
      {
        img: $r("app.media.youxi1"),
        name: 'Jungle Waves',
        author: 'DIMMYSAD',
        url: 'youxi1.mp3',
        rawFile: 'youxi1.mp3',
        id: '0017'
      },
      {
        img: $r("app.media.youxi2"),
        name: 'Dark Cyberpunk',
        author: 'FreeMusicLab',
        url: 'youxi2.mp3',
        rawFile: 'youxi2.mp3',
        id: '0020'
      },
      {
        img: $r("app.media.youxi3"),
        name: 'Deep Abstract Ambient_Snowcap',
        author: 'ummbrella',
        url: 'youxi3.mp3',
        rawFile: 'youxi3.mp3',
        id: '0021'
      },
      {
        img: $r("app.media.youxi4"),
        name: 'EONA',
        author: 'Rockot',
        url: 'youxi4.mp3',
        rawFile: 'youxi4.mp3',
        id: '0022'
      },
      {
        img: $r("app.media.youxi5"),
        name: 'Jungle Waves',
        author: 'DIMMYSAD',
        url: 'youxi5.mp3',
        rawFile: 'youxi5.mp3',
        id: '0023'
      },
      {
        img: $r("app.media.youxi6"),
        name: 'Stylish Deep',
        author: 'NverAvetyan',
        url: 'youxi6.mp3',
        rawFile: 'youxi6.mp3',
        id: '0024'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/5.jpg',
        name: '反转地球',
        author: '潘玮柏',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/5.mp3',
        id: '0005'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/3.jpg',
        name: '奢香夫人',
        author: '凤凰传奇',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/3.m4a',
        id: '0003'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/10.jpg',
        name: '北京北京',
        author: '汪峰',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/10.m4a',
        id: '0010'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/15.jpg',
        name: '海阔天空',
        author: 'Beyond',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/15.m4a',
        id: '0015'
      }
    ]
  },
  {
    img: $r('app.media.fengmian3'),
    title: '夏天专属bgm，给你炎热的夏季加点清爽感',
    top: '#4caf84',
    bottom: '#174847',
    songs: [
      {
        img: $r("app.media.xiatian1"),
        name: 'Water | Afro-pop Music',
        author: 'kontraa',
        url: 'xiatian1.mp3',
        rawFile: 'xiatian1.mp3',
        id: '0016'
      },
      {
        img: $r("app.media.xiatian2"),
        name: 'Crystal Nightfall',
        author: 'Ryan Mitchell',
        url: 'xiatian2.mp3',
        rawFile: 'xiatian2.mp3',
        id: '0035'
      },
      {
        img: $r("app.media.xiatian3"),
        name: 'Velvet Skies',
        author: 'Isabella Moore',
        url: 'xiatian3.mp3',
        rawFile: 'xiatian3.mp3',
        id: '0036'
      },
      {
        img: $r("app.media.xiatian4"),
        name: 'Whispers Of Tomorrow',
        author: 'Mia Anderson',
        url: 'xiatian4.mp3',
        rawFile: 'xiatian4.mp3',
        id: '0037'
      },
      {
        img: $r("app.media.xiatian5"),
        name: 'Summer Without You',
        author: 'Caleb Wilson',
        url: 'xiatian5.mp3',
        rawFile: 'xiatian5.mp3',
        id: '0038'
      },
      {
        img: $r("app.media.xiatian6"),
        name: 'Infinite Memories',
        author: 'Grace Parker',
        url: 'xiatian6.mp3',
        rawFile: 'xiatian6.mp3',
        id: '0039'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/4.jpg',
        name: '空心',
        author: '光泽',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/4.mp3',
        id: '0004'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/11.jpg',
        name: '苦笑',
        author: '汪苏泷',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/11.mp3',
        id: '0011'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/13.jpg',
        name: '月半小夜曲',
        author: '李克勤',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/13.mp3',
        id: '0013'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/12.jpg',
        name: '一生所爱',
        author: '卢冠廷 / 莫文蔚',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/12.m4a',
        id: '0012'
      },
     
    ]
  },
  {
    img: $r('app.media.fengmian4'),
    title: '每个人都是自己的超级英雄，不要因为一些事情没做好就诋毁自己',
    top: '#806ad8',
    bottom: '#3f350798',
    songs: [
      {
        img: $r("app.media.chaoji1"),
        name: 'Midnight Echoes',
        author: 'Olivia Carter',
        url: 'chaoji1.mp3',
        rawFile: 'chaoji1.mp3',
        id: '0025'
      },
      {
        img: $r("app.media.chaoji2"),
        name: 'Lost In The Sky',
        author: 'Ethan Walker',
        url: 'chaoji2.mp3',
        rawFile: 'chaoji2.mp3',
        id: '0026'
      },
      {
        img: $r("app.media.chaoji3"),
        name: 'Midnight Echoes',
        author: 'Ava Mitchell',
        url: 'chaoji3.mp3',
        rawFile: 'chaoji3.mp3',
        id: '0027'
      },
      {
        img: $r("app.media.chaoji4"),
        name: 'Ocean Of Dreams',
        author: 'Liam Parker',
        url: 'chaoji4.mp3',
        rawFile: 'chaoji4.mp3',
        id: '0028'
      },
      {
        img: $r("app.media.chaoji5"),
        name: 'Fading Memories',
        author: 'Sophia Bennett',
        url: 'chaoji5.mp3',
        rawFile: 'chaoji5.mp3',
        id: '0029'
      },
      {
        img: $r("app.media.chaoji6"),
        name: 'Electric Sunrise',
        author: 'Noah Anderson',
        url: 'chaoji6.mp3',
        rawFile: 'chaoji6.mp3',
        id: '0030'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/0.jpg',
        name: '直到世界的尽头',
        author: 'WANDS',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/0.m4a',
        id: '0000'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/1.jpg',
        name: '画',
        author: '赵雷',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/1.mp3',
        id: '0001'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/7.jpg',
        name: '孤独',
        author: 'G.E.M.邓紫棋',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/7.m4a',
        id: '0007'
      },
      {
        img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/9.jpg',
        name: '倩女幽魂',
        author: '张国荣',
        url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/9.m4a',
        id: '0009'
      },

    ]
  }
]
// 热门歌手数据
export const recommendList: recommendListType[] = [
  {
    img: $r('app.media.zhoujielun'),
    title: '周杰伦:开创国风，定义华语乐坛时代',
    count: '1770.9万'
  },
  {
    img: $r('app.media.linjunjie'),
    title: '林俊杰:行走CD，高音旋律全能唱作人',
    count: '1236.1万'
  },
  {
    img: $r('app.media.sunyanzi'),
    title: '孙燕姿:治愈声线，纯粹乐坛清流天后',
    count: '1086.3万'
  },
  {
    img: $r('app.media.xueziqian'),
    title: '薛之谦:段子藏深情，苦情歌常驻王者',
    count: '1386.3万'
  },
  {
    img: $r('app.media.lironghao'),
    title: '李荣浩:一人包办词曲，市井情歌叙述者',
    count: '1362.8万'
  },
  {
    img: $r('app.media.jujingyi'),
    title: '鞠婧祎:偶像转型演员，唱跳古装兼备',
    count: '962.8万'
  },
  {
    img: $r('app.media.xusong'),
    title: '许嵩:青春网络歌神，词曲自有风骨',
    count: '1062.8万'
  },
  {
    img: $r('app.media.yanzhongren'),
    title: '颜中人:沙哑感冒嗓，深夜治愈情歌代表',
    count: '1162.8万'
  }
]

export const searchSongs: SongItemType[] = [
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/0.jpg',
    name: '直到世界的尽头',
    author: 'WANDS',
    url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/0.m4a',
    id: '0000'
  },
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/1.jpg',
    name: '画',
    author: '赵磊',
    url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/1.mp3',
    id: '0001'
  },
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/2.jpg',
    name: 'Sweet Dreams',
    author: 'TPaul Sax / Eurythmics',
    url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/2.mp3',
    id: '0002'
  },
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/3.jpg',
    name: '奢香夫人',
    author: '凤凰传奇',
    url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/3.m4a',
    id: '0003'
  },
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/4.jpg',
    name: '空心',
    author: '光泽',
    url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/4.mp3',
    id: '0004'
  },
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/5.jpg',
    name: '反转地球',
    author: '潘玮柏',
    url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/5.mp3',
    id: '0005'
  },
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/8.jpg',
    name: 'Lose Control',
    author: 'Hedley',
    url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/8.m4a',
    id: '0008'
  },
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/11.jpg',
    name: '苦笑',
    author: '汪苏泷',
    url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/11.mp3',
    id: '0011'
  },
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/13.jpg',
    name: '月半小夜曲',
    author: '李克勤',
    url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/13.mp3',
    id: '0013'
  }
]
