# 辅助工具

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Wireshark + wrt-capture.sh

───

### Wireshark

图形化网络协议分析工具，支持实时抓包和事后分析。

**实际用法**：实时抓取安卓设备 HTTP 请求。设备播歌时在线搜索歌词 → 抓包找设备向哪个 IP 发请求 → 反查该 IP 对应域名 → 分析设备的网络行为和服务端依赖。

───

### wrt-capture.sh

自己写的远程抓包脚本，通过 SSH 管道把路由器上的 tcpdump 流量直传 Mac 本地。

**实际用法**：

1. SSH 免密登录 OpenWRT 路由器
2. 在路由器上运行 tcpdump
3. pcap 数据通过 SSH 管道直传到 Mac 本地
4. 选接口（any/br-lan/wan/ra0/rax0/eth0）
5. 按设备 IP 过滤，排除 SSH(22) 和 DNS(53) 减少噪音
6. 自动按日期创建文件夹、加时间戳命名，保存到桌面
7. 抓包完成统计文件大小和包数，一键用 Wireshark 打开

📂 **脚本位置**：`~/my-toolkit/testing/scripts/wrt-capture.sh`，通过 `wrt-capture` 全局命令调用（symlink 到 `/usr/local/bin`）。

───

## requests

Python HTTP 请求库。在 pytest 用例里发送 HTTP 请求做接口测试，验证后端 API 的响应状态码、返回数据结构和内容。

───

## ripgrep

超快的文本搜索工具（比 grep 快很多）。

```bash
rg "ERROR" allure-results/                          # 搜索测试日志
rg '"status":\s*"failed"' --type json               # 定位 JSON 字段
rg "MAC地址" logcat.txt | rg "onError"              # 找特定设备日志
```

───

## jq

命令行 JSON 处理器。

```bash
jq '.testCases[] | {name, status}' results.json              # 提取字段
jq '[.[] | select(.status == "failed")] | length'            # 过滤统计
jq '.cases[] | .name + " | " + .module'                      # 拍平嵌套
```

───

## ffmpeg + mediainfo

### ffmpeg

命令行音视频编码/解码/转换工具。

```bash
ffprobe -v error -show_entries stream=codec_name,sample_rate,channels,bit_rate output.wav
ffprobe -v quiet -print_format json -show_streams output.wav
```

### mediainfo

读取媒体文件元数据（编码格式、码率、分辨率等）。与 ffmpeg 配合，验证设备输出文件的编码参数是否正确。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 复用指南

### 1. SSH 管道远程抓包

> [!TIP]
> 不在设备端存文件，tcpdump pcap 流通过 SSH 直接传 Mac 本地。**脚本模板可直接照搬**，改开头 `HOST=` 和 `INTERFACES` 数组。

```bash
ssh user@remote_host "tcpdump -i interface -s 0 -U -w - filter" > local.pcap
```

| 参数 | 含义 |
|------|------|
| `-i interface` | 抓哪个网口（any 抓全部） |
| `-s 0` | 完整包不截断 |
| `-U` | 实时写入不缓冲 |
| `-w -` | 输出到 stdout |
| `filter` | 如 `host 192.168.x.x and not port 22 and not port 53` |

不限于 OpenWRT，任何有 tcpdump 的设备都行。

### 2. ripgrep + jq 日志分析流水线

> [!TIP]
> rg 快速定位 → jq 结构化处理 → 管道组合。**只需换 grep 关键词和 JSON 字段名**。

### 3. ffmpeg/mediainfo 媒体文件校验

1. `mediainfo --Output=JSON source.mp3` 获取基准参数
2. `ffprobe` 提取设备输出文件的编码信息
3. 对比校验采样率、声道数、码率、编码格式

**新项目只需换文件名和预期参数值**。
