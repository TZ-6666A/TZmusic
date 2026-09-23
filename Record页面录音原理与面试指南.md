# TZmusic：Record 页面录音原理与面试指南

> 对应项目：`D:\HarmonyProject\TZmusic`  
> 核心页面：`entry/src/main/ets/pages/Record.ets`

## 1. 先用一句话讲清楚

这个项目的录音功能使用 HarmonyOS `AudioCapturer` 从麦克风持续取得 **44.1 kHz、单声道、16 位小端 PCM 裸音频**，对每一块 PCM 数据做简单增益后写入应用沙箱中的 `.pcm` 文件；停止录音后把歌曲信息、文件路径、时长等元数据保存到 Preferences；试听时再使用参数完全一致的 `AudioRenderer` 读取 PCM 文件并播放。

它不是“录完直接得到 MP3”，也没有把人声与歌曲伴奏混音。

## 2. 页面从哪里进入

入口在 `KGe.ets`。

用户点击歌曲列表中的一首歌后，执行：

```ts
this.pathStack.pushPathByName('Record', { song: item } as RecordParams, false)
```

这里通过 Navigation 把完整的 `SongItemType` 传给名为 `Record` 的页面。`Record` 页面已在 `route_map.json` 中注册，构建函数是 `RecordBuilder`。

页面的 `.onReady()` 从路由参数中取得歌曲，并把歌词按换行符拆成数组：

```ts
this.song = p.song
this.lyricLines = p.song.lyrics ? p.song.lyrics.split('\n') : ['暂无歌词']
```

因此，Record 页面负责显示歌曲封面、歌名、歌手、歌词，同时完成录制和试听。

## 3. Record 页的核心对象

### 3.1 状态变量

| 变量 | 含义 |
|---|---|
| `recordState` | 录音状态：`0` 准备、`1` 录制中、`2` 录制完成 |
| `isPlaying` | 是否正在试听录音 |
| `recordSeconds` | 已录制秒数，用定时器每秒累加 |
| `errorText` | 权限、启动、空文件、试听失败等提示 |
| `dotVisible` | 控制录音状态小红点每 500 ms 闪烁 |
| `recordPath` | 当前 PCM 文件在应用沙箱内的路径 |
| `recordFd` | 录音文件描述符，写文件时使用 |
| `playFd` | 试听文件描述符，读文件时使用 |

`recordState` 与 `isPlaying` 分开保存，是因为“录制完成”状态下仍可能处于“正在试听”或“未试听”两种情况。

### 3.2 音频对象

| 对象 | 作用 |
|---|---|
| `AudioCapturer` | 从麦克风采集 PCM 数据 |
| `AudioRenderer` | 把 PCM 数据送到系统音频输出 |
| `playerManager` | 暂停项目原本正在播放的歌曲，避免与录音/试听抢占或混响 |

### 3.3 音频格式

录制与播放共同使用以下 `audioStreamInfo`：

```ts
samplingRate: SAMPLE_RATE_44100  // 每秒 44100 个采样点
channels: CHANNEL_1              // 单声道
sampleFormat: SAMPLE_FORMAT_S16LE // 每个采样 16 bit，小端序
encodingType: ENCODING_TYPE_RAW  // 未压缩的原始 PCM
```

理论数据量约为：

```text
44100 × 1 声道 × 16 bit ÷ 8 = 88200 Byte/s
```

即约 86.1 KiB/s，一分钟约 5.05 MiB（不计文件系统差异）。PCM 文件没有 MP3/AAC 那样的压缩，也通常没有描述格式的文件头，所以播放方必须提前知道并使用完全一致的采样率、声道数和采样格式。

## 4. 完整录音流程

```text
K歌列表点击歌曲
      ↓
进入 Record，接收歌曲与歌词
      ↓
点击“开始录制”
      ↓
暂停全局音乐播放
      ↓
动态申请 MICROPHONE 权限
      ↓
在 filesDir 创建 record_时间戳.pcm
      ↓
创建 AudioCapturer，并监听 readData
      ↓
AudioCapturer.start()
      ↓
麦克风 PCM 数据块 → 增益处理 → writeSync 写入文件
      ↓
点击“停止录制”
      ↓
停止并释放 Capturer → 关闭文件描述符
      ↓
检查文件大小是否大于 0
      ↓
状态变为“录制完成”并保存历史元数据
      ↓
可以试听、重录，或去“历史K歌”再次播放/删除
```

### 4.1 权限为什么要配置两次

静态声明在 `entry/src/main/module.json5`：

```json5
{
  "name": "ohos.permission.MICROPHONE",
  "reason": "$string:microphone_permission_reason",
  "usedScene": {
    "abilities": ["EntryAbility"],
    "when": "inuse"
  }
}
```

开始录音时还要动态申请：

```ts
const atManager = abilityAccessCtrl.createAtManager()
const grantStatus = await atManager.requestPermissionsFromUser(
  getContext(this), ['ohos.permission.MICROPHONE']
)
```

静态声明说明应用需要什么权限及使用场景；动态申请让用户在运行时做决定。用户拒绝后，页面显示“麦克风权限未开启，无法录音”，并且不会继续创建采集器。

### 4.2 文件创建

页面出现时生成文件路径：

```ts
context.filesDir + '/record_' + Date.now() + '.pcm'
```

`filesDir` 是应用沙箱私有目录，不是用户公共的“下载”或“音乐”目录。其他应用通常不能直接访问，卸载应用时数据也会被清除。

开始录音时用 `CREATE | READ_WRITE` 打开文件，并保存 `fd`：

```ts
const file = fileIo.openSync(this.recordPath,
  fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE)
this.recordFd = file.fd
```

### 4.3 创建采集器与持续写入

录音源指定为麦克风：

```ts
source: audio.SourceType.SOURCE_TYPE_MIC
```

创建 `AudioCapturer` 后注册 `readData` 回调：

```ts
capturer.on('readData', (buffer: ArrayBuffer) => {
  if (this.recordFd >= 0) {
    const boostedBuffer = this.boostPcmBuffer(buffer)
    fileIo.writeSync(this.recordFd, boostedBuffer)
  }
})
```

这段代码是录音功能的核心：系统不断把麦克风采集到的一块块二进制 PCM 数据交给回调，页面处理后立即追加写入文件。

### 4.4 PCM 增益算法

`boostPcmBuffer()` 把 `ArrayBuffer` 按 `Int16Array` 解释，先找到当前数据块中的最大绝对采样值 `peak`，再计算：

```text
gain = min(14000 / peak, 60)
输出采样 = 输入采样 × gain
```

最后把结果限制在 16 位有符号整数范围 `[-32768, 32767]`，避免数值溢出。

特殊处理：

- `peak < 20`：认为这一块非常接近静音，整块写成 0，避免把底噪放大。
- 最大增益限制为 60 倍：防止极弱输入导致无限放大。
- 输出做上下限裁剪：避免 Int16 溢出。

这是一种“按数据块自动增益/归一化”的简化方案，优点是代码简单、声音偏小时更容易听见；缺点是不同数据块的增益可能变化，可能造成音量抽动、底噪变化或削波失真。生产级方案通常会采用平滑 AGC、降噪、限幅器，或系统提供的音频处理能力。

### 4.5 停止录音

`stopRecording()` 的顺序是：

1. 停止计时和闪烁定时器。
2. `AudioCapturer.stop()` 停止采集。
3. `release()` 释放麦克风与系统音频资源。
4. 关闭 `recordFd`，确保文件写入结束。
5. 用 `statSync()` 检查文件大小。
6. 文件非空则设置 `recordState = 2`。
7. 把作品元数据写入历史记录。

检查空文件可以避免把“成功创建但没有采集到任何数据”的文件当成有效作品。

## 5. 为什么停止后会自动出现在历史K歌

停止成功后调用：

```ts
KSongHistoryStore.add(context, {
  id,
  songName,
  author,
  img,
  filePath,
  duration,
  createdAt
})
```

`KSongHistoryStore` 使用 ArkData `preferences`，将 `KSongWork[]` 序列化成 JSON 字符串，保存到：

```text
Preferences 名称：ksong_history_store
键：works
```

这里必须区分两类数据：

- PCM 音频本体：保存在 `filesDir` 的 `.pcm` 文件中。
- 作品元数据：保存在 Preferences 中，包括文件路径、歌名、作者、时长、创建时间等。

这是典型的“大文件落磁盘、轻量索引存键值数据库”的设计。Preferences 中只保存路径，不保存音频二进制，避免序列化大文件和键值存储膨胀。

历史页加载时读取 Preferences 列表；删除作品时先删除列表项，再调用 `unlinkSync()` 删除对应 PCM 文件，避免只删记录却遗留音频文件。

## 6. 试听是如何实现的

试听没有使用 `AVPlayer`，原因是当前文件是无文件头的 RAW PCM，项目直接用底层的 `AudioRenderer` 推送数据。

流程如下：

1. 暂停全局音乐播放器。
2. 检查 PCM 文件非空。
3. 以只读方式打开文件，得到 `playFd`。
4. 使用与录音完全相同的 `audioStreamInfo` 创建 `AudioRenderer`。
5. 在 `writeData` 回调中，从文件读取数据填入 Renderer 提供的缓冲区。
6. 读取结束后停止播放并释放资源。

核心方向与录音正好相反：

```text
录音：麦克风 → AudioCapturer → buffer → 文件
试听：文件 → buffer → AudioRenderer → 扬声器/耳机
```

当文件最后一次读取不足一个完整缓冲区时，`clearBufferTail()` 把剩余部分填 0。如果不清零，缓冲区尾部可能残留旧数据，造成结尾杂音。

`scheduleStopPlayback()` 延迟约 60 ms 再停止，是为了避免直接在 `writeData` 回调内部释放 Renderer，降低回调重入或资源状态冲突的风险。

## 7. 生命周期与资源释放

页面离开时 `aboutToDisappear()` 调用 `releaseAll()`，负责：

- 清理两个定时器；
- 释放 `AudioRenderer`；
- 关闭试听文件；
- 释放 `AudioCapturer`；
- 关闭录音文件；
- 重置播放状态。

音频对象、文件描述符和定时器都属于必须显式清理的资源。如果不释放，可能出现麦克风长期占用、文件句柄泄漏、页面离开后仍计时、再次进入无法录音等问题。

项目还在开始录音和开始试听之前调用 `playerManager.paused()`，避免背景音乐与录音/试听同时工作。但这也说明当前 K 歌功能只录人声，不会自动将原歌曲作为伴奏混入最终 PCM。

## 8. “重录”实际做了什么

`resetRecording()`：

- 停止试听并释放播放资源；
- 把状态恢复为准备录制；
- 时长清零；
- 生成一个新的 PCM 文件路径。

注意：停止录音时，上一条作品已经写入历史记录。点击“重录”不会删除刚才已经保存的 PCM 文件和历史元数据，而是创建一条新录音。这与用户直觉中的“用新录音覆盖刚才那条”并不完全一致，是当前实现可优化的地方。

## 9. 当前实现的优点

- 权限申请、采集、存储、回放、历史管理形成完整闭环。
- 录音和播放使用同一套 PCM 参数，避免格式不匹配。
- 对空文件做检查，错误状态能反馈给 UI。
- 页面退出和异常分支都考虑了资源释放。
- 音频本体与元数据分开保存，结构清晰。
- 文件尾部补零，处理了流式播放中的边界问题。
- 录制/试听前暂停全局播放器，减少音频资源冲突。

## 10. 当前实现的不足与优化方向

### 10.1 不是完整意义上的 K 歌混音

当前只采集麦克风，没有播放并混入歌曲伴奏。若要实现真正 K 歌作品，需要：

- 录制时同步播放伴奏；
- 处理耳返与声学回声消除；
- 对齐人声和伴奏的时间轴；
- 离线或实时混音；
- 编码导出 AAC/MP3 等通用格式。

### 10.2 PCM 占空间且兼容性弱

RAW PCM 文件大、无格式头，离开本项目后无法自动判断音频参数。可以在录制结束后编码为 AAC/M4A，或至少封装成 WAV（添加文件头），便于分享和用通用播放器播放。

### 10.3 UI 时长并非精确音频时长

`recordSeconds` 由 JavaScript 定时器每秒加一。页面调度延迟、后台切换等可能导致显示时长与真实采样时长有偏差。

PCM 的精确时长可由文件大小计算：

```text
duration = fileSize / (44100 × 1 × 2)
```

### 10.4 同步文件 I/O 位于音频回调

`readData` 中直接 `writeSync()` 简单直观，但同步磁盘写入可能阻塞实时回调。更稳妥的方案是缓冲队列加异步/工作线程写入，并设计背压策略。

### 10.5 增益按块突变

每个 PCM 块独立求峰值和增益，可能造成“泵动感”。可使用带 attack/release 的平滑 AGC、噪声门和 limiter。

### 10.6 重录会保留旧作品

如果产品语义是覆盖，应在重录时删除上一条历史记录及 PCM 文件，或把保存动作延迟到用户点击“确认保存”。

### 10.7 状态可以用枚举代替魔法数字

目前 `0/1/2` 可改为：

```ts
enum RecordState {
  READY,
  RECORDING,
  COMPLETED
}
```

可读性和类型安全更好，也更方便扩展 PAUSED、ERROR 等状态。

## 11. 面试时的 60 秒回答

“项目的 K 歌录音页面基于 HarmonyOS AudioKit 实现。进入页面时通过 Navigation 接收歌曲信息和歌词，开始录音前先暂停全局播放器并动态申请麦克风权限。录音格式统一为 44.1 kHz、单声道、16 位小端 RAW PCM，使用 AudioCapturer 的 readData 回调持续获取音频缓冲区。我对每块 PCM 做了带阈值和最大倍数限制的增益处理，然后通过文件描述符写到应用 filesDir。停止时先停采集器、释放资源、关闭文件，再检查文件非空，并把文件路径、歌名、时长等元数据用 Preferences 保存到历史记录。试听时使用相同参数的 AudioRenderer，在 writeData 回调里从 PCM 文件读取并填充缓冲区。页面退出、异常和播放结束时都会关闭文件描述符、释放 Capturer/Renderer 和清理定时器。这个版本的不足是只录人声，没有做人声与伴奏混音，而且 RAW PCM 占空间，后续可以增加同步伴奏、音轨对齐、混音和 AAC 编码。” 

## 12. 高频面试追问与回答

### Q1：为什么录制和播放参数必须一致？

RAW PCM 没有文件头记录格式。若录音是 44.1 kHz、单声道、S16LE，播放却按双声道或其他采样率解释，就会出现速度、音调、声道和数据边界错误。

### Q2：为什么不用 AVPlayer 播放录音？

AVPlayer 更适合带容器和编码信息的媒体文件，例如 MP3、M4A。当前是无文件头 RAW PCM，因此用 AudioRenderer 按已知格式直接推流更合适。

### Q3：如何判断录音时长？

当前 UI 用定时器统计近似时长。更准确的方式是根据 PCM 文件字节数、采样率、声道数和每采样字节数计算。本项目参数下每秒 88200 字节。

### Q4：为什么保存文件路径而不把音频存进 Preferences？

Preferences 适合小型键值配置和轻量 JSON，不适合存大量二进制。音频放文件系统，Preferences 只存索引元数据，读取、删除和扩展都更合理。

### Q5：怎样避免录音资源泄漏？

成功、异常、页面离开三个路径都要停止并释放 AudioCapturer/AudioRenderer，关闭文件描述符，清理定时器。资源释放函数应尽量幂等，重复调用也不会出错。

### Q6：增益为什么要裁剪到 `[-32768, 32767]`？

因为 S16LE 的每个采样是 16 位有符号整数。乘增益后超出范围会溢出并产生严重失真，所以需要饱和裁剪；但频繁触顶仍会削波，因此生产方案还应使用 limiter 或更平滑的增益控制。

### Q7：项目是否录入了歌曲伴奏？

没有。开始录音前还会暂停全局播放器，因此保存的是麦克风人声。歌词只是 UI 展示。实现真正 K 歌需要同步播放伴奏并进行延迟补偿、轨道对齐与混音。

### Q8：如何把 PCM 分享给其他应用？

应先封装成 WAV，或编码为 AAC/MP3 等通用格式；同时通过系统文件选择器、媒体库或受控 URI 暴露文件，而不是直接暴露应用私有沙箱路径。

## 13. 阅读源码时抓住这 8 个位置

1. `KGe.ets`：点击歌曲并把参数导航到 Record。
2. `Record.ets / audioStreamInfo`：决定 PCM 格式。
3. `Record.ets / startRecording()`：权限、建文件、创建 Capturer、写数据。
4. `Record.ets / boostPcmBuffer()`：PCM 增益和裁剪。
5. `Record.ets / stopRecording()`：停止、校验并保存历史。
6. `Record.ets / playRecording()`：创建 Renderer 并流式读文件。
7. `kSongHistoryStore.ets`：用 Preferences 保存作品元数据。
8. `HistoryKGe.ets`：历史作品回放和“元数据 + PCM 文件”联合删除。

## 14. 最后记忆口诀

```text
权限 → 建文件 → Capturer采集 → PCM增益 → 写文件
停止 → 释放资源 → 验空 → Preferences存索引
试听 → 读PCM → Renderer播放 → 结束释放
删除 → 删索引 + 删音频文件
```

