# 辅助工具

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Wireshark + wrt-capture.sh

───

### Wireshark

> 💡 图形化网络协议分析工具，支持实时抓包和事后分析。

**实际用法**：

| 场景 | 做什么 |
|------|--------|
| 实时抓取安卓设备 HTTP 请求 | 设备播歌时在线搜索歌词 → 抓包找设备向哪个 IP 发请求 → 反查该 IP 对应域名 |
| 分析设备网络行为 | 找出设备依赖哪些外部服务和接口 |

───

### wrt-capture.sh

> 💡 自己写的远程抓包脚本，通过 SSH 管道把路由器上的 tcpdump 流量直传 Mac 本地。

**实际用法**：

| 步骤 | 做什么 |
|------|--------|
| 1 | SSH 免密登录 OpenWRT 路由器 |
| 2 | 在路由器上运行 tcpdump |
| 3 | pcap 数据通过 SSH 管道直传到 Mac 本地 |
| 4 | 选接口（any/br-lan/wan/ra0/rax0/eth0） |
| 5 | 按设备 IP 过滤，排除 SSH(22) 和 DNS(53) 减少噪音 |
| 6 | 自动按日期创建文件夹、加时间戳命名，保存到桌面 |
| 7 | 抓包完成统计文件大小和包数，一键用 Wireshark 打开 |

📂 **脚本位置**：`~/my-toolkit/testing/scripts/wrt-capture.sh`

通过 `wrt-capture` 全局命令调用（symlink 到 `/usr/local/bin`）。

───

## requests

> 💡 Python HTTP 请求库。

**实际用法**：

| 场景 | 做什么 |
|------|--------|
| pytest 用例内发 HTTP 请求 | 验证后端 API 的响应状态码、返回数据结构和内容 |

───

## ripgrep

> 💡 超快的文本搜索工具（比 grep 快很多）。

**实际用法**：

| 场景 | 命令 |
|------|------|
| 搜索测试日志 | `rg "ERROR" allure-results/` |
| 定位 JSON 字段 | `rg '"status":\s*"failed"' --type json` |
| 找特定设备日志 | `rg "MAC地址" logcat.txt \| rg "onError"` |

───

## jq

> 💡 命令行 JSON 处理器，类似于 JSON 版的 sed。

**实际用法**：

| 场景 | 命令 |
|------|------|
| 提取字段 | `jq '.testCases[] \| {name, status}' results.json` |
| 过滤统计 | `jq '[.[] \| select(.status == "failed")] \| length'` |
| 拍平嵌套 | `jq '.cases[] \| .name + " \| " + .module'` |

───

## ffmpeg + mediainfo

───

### ffmpeg

> 💡 命令行音视频编码/解码/转换工具。

**实际用法**：

| 场景 | 命令 |
|------|------|
| 提取编码参数 | `ffprobe -v error -show_entries stream=codec_name,sample_rate,channels,bit_rate output.wav` |
| 查看详情 | `ffprobe -v quiet -print_format json -show_streams output.wav` |

───

### mediainfo

> 💡 读取媒体文件元数据（编码格式、码率、分辨率等）。

**实际用法**：

- 快速查看音频/视频文件的详细编码信息
- 用来验证设备输出文件的编码参数是否正确

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔄 复用指南

### 1. SSH 管道远程抓包通用模式

> 💡 不在设备端存文件，通过 SSH 把 tcpdump 的 pcap 流直接传到 Mac 本地。

**通用公式**：
```bash
ssh user@remote_host "tcpdump -i interface -s 0 -U -w - filter" > local.pcap
```

| 参数 | 含义 |
|------|------|
| `-i interface` | 抓哪个网口（any 抓全部） |
| `-s 0` | 完整包不截断 |
| `-U` | 实时写入（不缓冲） |
| `-w -` | 输出到 stdout |
| `filter` | BPF 过滤（`host 192.168.x.x` 只抓特定IP；`not port 22 and not port 53` 排除 SSH+DNS） |

| 需要改 | 不需要动 |
|---------|---------|
| 远程设备地址（SSH user@host）、网口名、过滤规则 | 整体脚本框架 |

📂 **脚本模板**：`wrt-capture.sh` 可直接照搬，改开头 `HOST=` 变量和 `INTERFACES` 数组即可。

### 2. ripgrep + jq 日志分析流水线

> 💡 **rg 快速定位 → jq 结构化处理 → 管道组合**。

| 套路 | 模式 |
|------|------|
| 搜索错误并统计 | `rg -c "ERROR\|FATAL" logs/` |
| 搜索设备 + 过滤 | `rg "DEVICE_ID" log.txt \| rg "KEYWORD"` |
| JSON 提取 | `jq '.field' data.json` |
| JSON 过滤 | `jq 'select(.status=="failed")'` |

| 需要改 | 不需要动 |
|---------|---------|
| grep 关键词、JSON 字段名 | rg/jq 的命令范式 |

### 3. ffmpeg + mediainfo 媒体文件校验

> 💡 获取源文件参数作为基准 → 分别检查设备输出文件的编码格式、采样率、声道数、码率 → 与预期对比。

| 步骤 | 命令 |
|------|------|
| 1. 获取基准 | `mediainfo --Output=JSON source.mp3` |
| 2. 提取输出文件参数 | `ffprobe -print_format json -show_streams output.wav` |
| 3. 对比校验 | 编码格式 / 采样率 / 声道数 / 码率 是否一致 |

| 需要改 | 不需要动 |
|---------|---------|
| 文件名和预期参数值 | 整个校验流程 |
