# 日志分析客服

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 做了什么

虾小丘成为自动化日志分析客服：

> SSH 连服务器 → 列出日志 → 等用户选 → 下载 → 8 步分析 → 报告 → 清理 → 飞书云盘存档

> [!IMPORTANT]
> 整条流程是标准化流水线。输入 MAC 地址，输出分析报告。每一步都有明确的输入/输出和失败处理。

───

## 诊断交互流程

> 1. 用户发 MAC 后 4 位（如 D0:87:80）
> 2. SSH 连服务器 → `ls -1t` 按时间倒序列出该设备所有日志 zip
> 3. **只返回文件名**，不做额外分析
> 4. 等用户说「分析 xxx.zip」
> 5. 下载 → 解压 → 8 步分析 → 输出报告
> 6. 删除解压目录（只保留 zip）
> 7. 可选：保存到飞书云盘

───

## 多维度交叉验证

诊断不止看报错日志，需要多维度交叉验证，不全信单一指标：

- **播放状态**：`realStart` / `onCompletion` / `onError` — 播放链是否完整
- **UI 状态**：NavBar session state（1/2/3）— 界面是否在播放状态
- **网络流量**：`netstats_wifi` 首尾差值 — 是否真的在拉流
- **音频焦点**：`requestAudioFocus` / `abandonAudioFocus` — 有无被其他 app 抢占
- **系统资源**：`perf_snapshot` top / meminfo — 是否卡顿或内存不足

───

## 8 步分析标准流程

1. **基本信息**：时间范围、行数、每小时分布 — `head` / `tail` / `wc -l`
2. **崩溃检查**：`tombstone|FATAL|SIGSEGV|SIGABRT|ANR`
3. **播放状态**：`realStart|onCompletion|onError|onPositionChanged`
4. **NavBar/MediaSession**：`Switched to new media session`（state 2=暂停 3=播放）
5. **音频焦点**：`requestAudioFocus|abandonAudioFocus`
6. **网络流量**：`netstats_wifi_sample` 首尾差值
7. **系统资源**：`perf_snapshot.txt`（top/meminfo/procrank）
8. **综合判断**：现象优先于日志结论，多维度交叉验证

> [!WARNING]
> **陷阱 1**：KeepAlive ≠ 在播放。必须结合 onPositionChanged + WiFi 流量 + notification 判断。
> **陷阱 2**：日志量极低可能被裁剪，异常低时段视为可能缺失。不要因为没日志就说「没问题」。

───

## 已分析的典型问题

| # | 问题 | 根因层 |
|---|------|--------|
| 1 | 封面解码故障 → UI 卡顿 | 应用层（BitmapFactory） |
| 2 | WebRTC SIGSEGV 崩溃 | C++ 层（libjingle） |
| 3 | 继电器咔咔响 + 播放断断续续 | 驱动层（USB Audio HAL） |
| 4 | 音量条拖拽中断播放 | 跨进程同步问题 |
| 5 | session 切换 UI 残留 | 时序竞态条件 |

───

## 缓存策略

- 下载到 `/tmp/analysis_logs/{MAC}/`
- 分析完**立即删除解压目录**，只保留 zip
- 总大小 > 1GB 时按最旧优先自动清理

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 复用指南

> [!TIP]
> **新设备只需换 3 个东西**：SSH 服务器地址/路径、grep 关键词、zip 内文件名。8 步流程框架、缓存逻辑、陷阱提醒完全复用。

```bash
# 替换关键词适配新设备
grep -i "NEW_CRASH_KEYWORD|NEW_ERROR_KEYWORD" logfile.txt
grep -i "NEW_PLAYBACK_START|NEW_PLAYBACK_ERROR" logfile.txt
```

### 新设备诊断迁移

四步交互流程（MAC→列表→选择→分析）和交叉验证思路完全复用。新项目直接填维度表，维度越多验证越准：

```markdown
## 验证维度
- [维度1]：[数据来源] — [正常/异常标准]
- [维度2]：[数据来源] — [正常/异常标准]

## 分析陷阱
- [陷阱]：[原因和规避方式]
```
