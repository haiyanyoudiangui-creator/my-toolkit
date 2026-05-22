# 日志分析客服

## 做了什么

让虾小丘成为一个自动化的日志分析客服：
- SSH 连日志服务器 → 列出最新日志文件 → 等用户选择 → 下载到本地 → 8 步分析 → 输出报告 → 清理临时文件 → 存档到飞书云盘

## 核心思路

整个流程是一条标准化流水线，输入是 MAC 地址，输出是分析报告。每一步都有明确的输入/输出和失败处理。

### 8 步分析标准流程

1. **基本信息**：时间范围、行数、每小时分布 → 了解日志覆盖面和负载
2. **崩溃检查**：tombstone / FATAL / SIGSEGV / SIGABRT / ANR → 一类问题
3. **播放状态**：realStart / onCompletion / onError / onPositionChanged → 播放链
4. **NavBar/MediaSession**：session 状态切换（state 2=暂停 3=播放）→ UI层
5. **音频焦点**：requestAudioFocus / abandonAudioFocus → 焦点争夺
6. **网络流量**：netstats_wifi 首尾差值 → 是否真实在下载/播放
7. **系统资源**：perf_snapshot.txt（top/meminfo/procrank）→ 系统压力
8. **综合判断**：现象优先于日志结论，多维度交叉验证

### 两个分析陷阱

- **KeepAlive ≠ 在播放**：连接保活不代表在输出音频，必须结合 onPositionChanged + 流量 + notification
- **日志量极低可能被裁剪**：不要因为没日志就说「没问题」

### 缓存策略

- 下载到 `/tmp/analysis_logs/{MAC}/`
- 分析完立即删除解压目录，只保留 zip
- 总大小 > 1GB 时自动清理最旧的 zip

## 复用指南

### 新设备日志分析迁移

**只需要改**：
1. **服务器地址和路径** → 换 SSH 的主机和日志目录
2. **grep 关键词** → 换新设备的包名、错误关键字、播放状态标识
3. **文件结构** → 换 zip 内的文件名（logcat.txt / dmesg.txt 换别的）

**不需要改的**：
- 8 步分析流程框架
- 下载→解压→分析→清理的自动化流水线
- 缓存清理逻辑
- 分析陷阱提醒

### 通用日志分析关键词模板

```bash
# 自己替换成新设备的关键词
grep -i "CRASH_KEYWORD\|FATAL_KEYWORD\|ERROR_KEYWORD" logfile.txt
grep -i "PLAYBACK_START\|PLAYBACK_END\|PLAYBACK_ERROR" logfile.txt
grep "NETWORK_STATS" logfile.txt | head -1 && grep "NETWORK_STATS" logfile.txt | tail -1
```

### 本地缓存自动清理模板

```python
def auto_cleanup(cache_dir, max_mb):
    total = sum(f.stat().st_size for f in cache_dir.rglob("*") if f.is_file())
    if total > max_mb * 1024 * 1024:
        for f in sorted(cache_dir.rglob("*.zip"), key=lambda x: x.stat().st_mtime):
            f.unlink()
            if sum(...) <= max_mb * 1024 * 1024:
                break
```
