# 辅助工具

## Wireshark + wrt-capture.sh

### Wireshark
**是什么**：图形化网络协议分析工具，支持实时抓包和事后分析。

**实际用法**：
- 实时抓取安卓设备端的 HTTP GET/POST 请求
- 具体场景：设备在播歌时在线搜索歌词，抓包找出设备向哪个 IP 发请求，再反查该 IP 对应的域名
- 帮助分析设备的网络行为和服务端依赖

### wrt-capture.sh
**是什么**：自己写的远程抓包脚本，解决设备端 Wireshark 无法直连的问题。

**实际用法**：
- 通过 SSH 免密登录 OpenWRT 路由器（192.168.6.1）
- 在路由器上运行 tcpdump，把原始 pcap 数据通过 SSH 管道直传到 Mac 本地
- 支持选抓包接口（any/br-lan/wan/ra0/rax0/eth0）
- 支持按设备 IP 过滤、排除 SSH(22) 和 DNS(53) 端口减少噪音
- 自动按日期创建文件夹、加时间戳命名，保存到桌面
- 抓包完成后统计文件大小和包数，支持一键用 Wireshark 打开分析
- 通过 `wrt-capture` 全局命令调用（做了 symlink 到 /usr/local/bin）

**脚本位置**：`~/my-toolkit/testing/scripts/wrt-capture.sh`

---

## requests

**是什么**：Python HTTP 请求库。

**实际用法**：
- 在 pytest 用例里发送 HTTP 请求做接口测试
- 验证后端 API 的响应状态码、返回数据结构和内容

---

## ripgrep

**是什么**：超快的文本搜索工具（比 grep 快很多）。

**实际用法**：
- 快速搜索 allure-results 目录下的测试日志和失败报告
- 在大量 JSON 文件里定位特定字段和错误信息

---

## jq

**是什么**：命令行 JSON 处理器，类似于 JSON 版的 sed。

**实际用法**：
- 处理和分析 API 返回的 JSON 响应
- 把多层嵌套的 JSON 拍平、按字段过滤、统计

---

## ffmpeg + mediainfo

### ffmpeg
**是什么**：命令行音视频编码/解码/转换工具。

**实际用法**：
- 读取设备输出的音频文件编码参数（采样率、声道数、位深等）
- 校验设备生成的音视频文件是否符合预期规格

### mediainfo
**是什么**：读取媒体文件元数据（编码格式、码率、分辨率等）。

**实际用法**：
- 与 ffmpeg 配合，快速查看音频/视频文件的详细编码信息
- 用来验证设备输出文件的编码参数是否正确

---

## 复用指南

### 1. SSH 管道远程抓包通用模式

**核心思想**：不在设备端存文件，通过 SSH 把 tcpdump 的 pcap 流直接传到 Mac 本地。

**通用公式**：
```bash
ssh user@remote_host "tcpdump -i interface -s 0 -U -w - filter" > local.pcap
```

**参数说明**：
- `-i interface`：抓哪个网口（any 抓全部）
- `-s 0`：完整包不截断
- `-U`：实时写入（不缓冲）
- `-w -`：输出到 stdout
- `filter`：BPF 过滤表达式（`host 192.168.x.x` 只抓特定IP，`not port 22 and not port 53` 排除 SSH 和 DNS）

**新场景迁移**：只需改 3 个参数：
1. 远程设备地址（SSH user@host）— 不一定要 OpenWRT，任何有 tcpdump 的设备都行
2. 网口名（any / eth0 / wlan0…）
3. 过滤规则（IP、端口黑名单）

**脚本模板**：`wrt-capture.sh` 可直接照搬，改开头 HOST= 变量和 INTERFACES 数组即可。

### 2. ripgrep + jq 日志分析流水线

**核心思想**：rg 快速定位 → jq 结构化处理 → 管道组合。

**搜索日志通用模式**：
```bash
# 搜索错误并统计出现次数
rg -c "ERROR|FATAL" allure-results/
# 搜索特定设备的所有日志条目
rg "D0:87:5C" logcat.txt | rg "onError|tombstone|SIGSEGV"
# 递归搜索 JSON 文件的特定字段
rg '"status":\s*"failed"' --type json
```

**JSON 处理通用模式**：
```bash
# 提取特定字段
jq '.testCases[] | {name: .name, status: .status}' results.json
# 过滤和统计
jq '[.[] | select(.status == "failed")] | length' results.json
# 拍平嵌套
jq '.cases[] | .name + " | " + .module' cases.json
```

**新项目**换 grep 关键词和 JSON 字段名即可。

### 3. ffmpeg + mediainfo 媒体文件校验

**通用校验流程**：
1. 获取源文件的参数作为基准：`mediainfo --Output=JSON source.mp3`
2. 分别检查编码格式、采样率、声道数、码率
3. 校验设备输出文件与源文件的参数是否一致（或是否符合预期转换）

**常用命令**：
```bash
# 查看编码详情
ffprobe -v quiet -print_format json -show_streams output.wav
# 提取关键参数
ffprobe -v error -show_entries stream=codec_name,sample_rate,channels,bit_rate -of default=noprint_wrappers=1 output.wav
# 快速查看元数据
mediainfo output.mp4
```

**新项目**只需换文件名和预期参数值。
