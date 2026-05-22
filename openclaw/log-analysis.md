# 日志分析客服

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 做了什么

让虾小丘成为一个自动化的日志分析客服：

```
SSH 连服务器 → 列出最新日志 → 等用户选择 → 下载 → 8步分析 → 报告 → 清理 → 飞书云盘存档
```

───

## 核心思路

> 💡 整个流程是一条标准化流水线，输入是 MAC 地址，输出是分析报告。每一步都有明确的输入/输出和失败处理。

───

### 8 步分析标准流程

| 步骤 | 检查内容 | grep 关键词 |
|------|---------|------------|
| 1 | **基本信息**：时间范围、行数、每小时分布 | `head` / `tail` / `wc -l` |
| 2 | **崩溃检查** | `tombstone\|FATAL\|SIGSEGV\|SIGABRT\|ANR` |
| 3 | **播放状态** | `realStart\|onCompletion\|onError\|onPositionChanged` |
| 4 | **NavBar/MediaSession** | `Switched to new media session`（state 2=暂停 3=播放） |
| 5 | **音频焦点** | `requestAudioFocus\|abandonAudioFocus` |
| 6 | **网络流量** | `netstats_wifi_sample` 首尾差值 |
| 7 | **系统资源** | `perf_snapshot.txt`（top/meminfo/procrank） |
| 8 | **综合判断** | 现象优先于日志结论，多维度交叉验证 |

───

### ⚠️ 两个分析陷阱

| 陷阱 | 真相 | 正确做法 |
|------|------|---------|
| **KeepAlive ≠ 在播放** | 连接保活不代表输出音频 | 结合 `onPositionChanged` + WiFi流量 + notification 判断 |
| **日志裁剪被误判** | 日志量极低不等于没问题 | 检查每小时日志量分布，异常低的时段视为可能裁剪 |

───

### 📋 缓存策略

| 操作 | 规则 |
|------|------|
| 下载路径 | `/tmp/analysis_logs/{MAC}/` |
| 清理 | 分析完**立即删除解压目录**，只保留 zip |
| 自动清理 | 总大小 > 1GB 时按最旧优先逐个删除 zip |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔄 复用指南

### 新设备只需换三个东西

| 需要改 | 不需要动 |
|---------|---------|
| SSH 服务器地址和日志目录路径 | 8 步分析流程框架 |
| grep 关键词（设备特定的包名、错误标识） | 下载→解压→分析→清理的自动化流水线 |
| zip 内的文件名（如 logcat.txt → 新日志文件名） | 缓存清理逻辑、分析陷阱提醒 |

### 通用日志分析关键词模板

```bash
# 替换关键词适配新设备
grep -i "CRASH_KEYWORD\|FATAL_KEYWORD\|ERROR_KEYWORD" logfile.txt
grep -i "PLAYBACK_START\|PLAYBACK_END\|PLAYBACK_ERROR" logfile.txt
grep "NETWORK_STATS" logfile.txt | head -1 && grep "NETWORK_STATS" logfile.txt | tail -1
```

### 缓存清理逻辑

```python
def auto_cleanup(cache_dir, max_mb):
    total = sum(f.stat().st_size for f in cache_dir.rglob("*") if f.is_file())
    if total > max_mb * 1024 * 1024:
        for f in sorted(cache_dir.rglob("*.zip"), key=lambda x: x.stat().st_mtime):
            f.unlink()
            if sum(...) <= max_mb * 1024 * 1024:
                break
```
