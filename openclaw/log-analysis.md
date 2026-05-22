# 日志分析客服

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 做了什么

虾小丘成为自动化日志分析客服：

```
SSH 连服务器 → 列出日志 → 等用户选 → 下载 → 8步分析 → 报告 → 清理 → 飞书云盘存档
```

> [!IMPORTANT]
> 整条流程是标准化流水线。输入 MAC 地址，输出分析报告。每一步都有明确的输入/输出和失败处理。

───

## 8 步分析标准流程

1. **基本信息**：时间范围、行数、每小时分布 — `head`/`tail`/`wc -l`
2. **崩溃检查**：`tombstone|FATAL|SIGSEGV|SIGABRT|ANR`
3. **播放状态**：`realStart|onCompletion|onError|onPositionChanged`
4. **NavBar/MediaSession**：`Switched to new media session`（state 2=暂停 3=播放）
5. **音频焦点**：`requestAudioFocus|abandonAudioFocus`
6. **网络流量**：`netstats_wifi_sample` 首尾差值
7. **系统资源**：`perf_snapshot.txt`（top/meminfo/procrank）
8. **综合判断**：现象优先于日志结论，多维度交叉验证

> [!WARNING]
> **陷阱 1**：KeepAlive ≠ 在播放。必须结合 onPositionChanged + WiFi流量 + notification 判断。**陷阱 2**：日志量极低可能被裁剪，异常低时段视为可能缺失。

### 缓存策略

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
