//规范歌单的
export interface SongItemType {
  img: string|Resource
  name: string
  author: string
  url: string |Resource
  id: string
  lyrics?: string  // 歌词，用 \n 分隔每行
  rawFile?: string  // rawfile 文件名（本地音频文件），有值时自动解压到临时目录播放
}