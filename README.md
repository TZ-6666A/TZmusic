# TZ Music

一款基于 **HarmonyOS** 开发的本地音乐应用，使用 ArkTS 与 ArkUI 构建。项目围绕音乐浏览、播放控制、K 歌录音与个人数据管理等场景实现，适合作为 HarmonyOS 客户端开发学习与实践项目。

## 功能概览

- 推荐大厅：展示推荐歌曲、歌手与音乐内容。
- 音乐播放：支持本地 Rawfile 音频播放、播放列表管理、上一首/下一首、进度拖动，以及顺序、随机和单曲循环模式。
- 后台播放：接入 AVSession，支持系统媒体控制、锁屏播放状态展示和后台音频任务。
- 收藏与歌单：管理喜欢的歌曲与当前播放列表。
- K 歌录音：申请麦克风权限后录制 PCM 音频，支持试听、重录、保存与历史记录查看。
- 歌曲评价：可添加、查看和删除歌曲评价。
- 个人中心：展示累计听歌时长、历史 K 歌记录、当前播放信息与登录状态。

## 技术栈

| 分类 | 技术 |
| --- | --- |
| UI 与语言 | ArkTS、ArkUI、Navigation、AppStorageV2 |
| 音频播放 | `AVPlayer`、`AVSession`、后台音频任务 |
| 录音与试听 | `AudioCapturer`、`AudioRenderer`、PCM |
| 本地数据 | Preferences、File I/O、Rawfile |
| 工程构建 | DevEco Studio、Hvigor、OHPM |

## 项目结构

```text
TZmusic/
├─ entry/
│  └─ src/main/
│     ├─ ets/
│     │  ├─ pages/       # 推荐、播放、K 歌、录音、个人中心等页面
│     │  ├─ models/      # 播放、收藏、评价、听歌时长等状态与存储
│     │  ├─ utils/       # AVPlayer 与 AVSession 管理
│     │  └─ data/        # 推荐歌曲和歌评数据
│     └─ resources/
│        ├─ base/media/  # 图片与图标资源
│        └─ rawfile/     # 本地音频资源
├─ build-profile.json5
└─ hvigorfile.ts
```

## 环境要求

- DevEco Studio
- HarmonyOS SDK：与项目配置中的 `6.0.2(22)` 保持兼容
- 真机调试建议使用 HarmonyOS 手机；K 歌录音功能需要授予麦克风权限

## 运行方式

1. 使用 DevEco Studio 打开本项目根目录。
2. 等待 OHPM 依赖同步与 SDK 配置完成。
3. 连接设备或启动模拟器。
4. 选择 `entry` 模块，点击运行即可安装调试。

也可以在 PowerShell 中构建：

```powershell
.\hvigorw.bat --mode module -p product=default assembleHap
```

构建产物通常位于：

```text
entry\build\default\outputs\default\entry-default-signed.hap
```

## 权限说明

| 权限 | 用途 |
| --- | --- |
| `ohos.permission.INTERNET` | 加载网络歌曲封面或音乐资源 |
| `ohos.permission.KEEP_BACKGROUND_RUNNING` | 保持后台音频播放 |
| `ohos.permission.MICROPHONE` | K 歌录音 |

## 说明

本项目中的歌曲、图片等资源仅用于学习与演示，请勿用于商业用途。
