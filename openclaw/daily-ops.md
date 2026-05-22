# 日常运维

## 做了什么

虾小丘帮小辉辉完成日常的开发和测试运维任务：

| 任务 | 做法 |
|------|------|
| **安装 Kaiboer Home** | curl 内网服务器获取最新 APK → adb install 到手机 |
| **烧录固件** | 调用 `flash_device` 脚本刷 RK3568 设备 |
| **远程抓包** | 通过 `wrt-capture` SSH 管道抓 OpenWRT 路由器流量 |
| **翻 GitLab 代码** | Chrome CDP 方式登录 GitLab 浏览 kaiboer_dev 组仓库 |
| **OTA 管理** | 为 user 版本设备开 ADB（OTA 服务器 + 特殊账号） |

## 核心思路

### 脚本工具箱模式

把分散的运维操作封装成脚本，注册到 PATH：

```
~/skills/ → 各种功能脚本存放目录
~/.local/bin/ → PATH 注册
/usr/local/bin/ → 全局命令（wrt-capture, flash_device）
```

虾小丘不需要记住具体命令，只需要知道有哪些脚本和什么时候调用。

### Kaiboer Home 安装流程

```
用户说「安装 Kaiboer Home」
  → curl 内网服务器 192.168.10.200:6688 获取版本列表
  → 列出可选版本 → 等用户选择
  → curl 下载指定版本 APK
  → adb install -r -d 到已连接手机
  → 报告安装结果
```

### 固件烧录

`flash_device` 脚本支持：
- 默认 user 正式版 / `userdebug` 调试版
- 交互式选版本 / 指定设备序列号

### GitLab 代码浏览

内网 GitLab 不支持 basic auth，需要通过 Chrome CDP 方式登录：
1. `open -a Google\ Chrome --args --remote-debugging-port=18800`
2. CDP 操作自动填写账号密码
3. 通过 DOM 选择器定位项目列表
4. 浏览代码时确保只读

## 复用指南

### 脚本工具箱搭建方法

**3 步搭建**：

1. **创建脚本目录**：`mkdir -p ~/skills/[功能名]/scripts/`
2. **注册到 PATH**：`ln -s ~/skills/[功能名]/scripts/[脚本].sh /usr/local/bin/[命令名]`
3. **写进 MEMORY.md**：让 AI 知道有哪些脚本和触发条件

**脚本通用模板**：
```bash
#!/bin/bash
# [功能名称]
# 用法: [命令名] [参数]

# ---- 配置 ----
TARGET="[目标地址/设备]"

# ---- 依赖检查 ----
# 检查必需的命令是否存在

# ---- 交互获取参数 ----
# read/select 获取用户输入

# ---- 执行操作 ----
# 核心逻辑

# ---- 结果反馈 ----
# 成功/失败的清晰输出
```

### CI/CD 型操作模式

curl → 下载 → 安装/部署，这个模式可以迁移到任何部署场景：
- 换 URL 和文件类型：APK → IPA/EXE/DMG
- 换安装命令：`adb install` → `brew cask install` / `dpkg -i`
- 换验证方式：`adb` → 新平台的验证命令

**核心不变**：拉取版本列表 → 用户选择 → 下载 → 安装 → 验证。
