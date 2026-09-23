//规范歌单的格式
//一首歌的状态
export interface SongItemType {
  img: string|Resource
  name: string
  author: string
  url: string |Resource
  id: string
  lyrics?: string  // 歌词，用 \n 分隔每行
  rawFile?: string  // rawfile 文件名（本地音频文件），有值时自动解压到临时目录播放
  accompanyUrl?: string  // 纯伴奏音源（K歌用），缺省时回退到 url
  accompanyRawFile?: string  // 纯伴奏本地 rawfile 文件名，优先级高于 accompanyUrl
  lyricTimestamps?: number[]  // 每行歌词的起始时间（秒），用于精确高亮；缺省时按字符数加权均分
}