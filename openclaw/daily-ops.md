# 日常运维

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 做了什么

虾小丘帮小辉辉完成日常开发和测试运维：

- **安装 Kaiboer Home**：curl 内网服务器获取 APK → adb install 到手机
- **烧录固件**：调用 `flash_device` 脚本刷 RK3568
- **远程抓包**：`wrt-capture` SSH 管道抓路由器流量
- **翻 GitLab 代码**：Chrome CDP 方式登录浏览 kaiboer_dev 仓库
- **OTA 管理**：为 user 版本设备开 ADB

> [!IMPORTANT]
> 所有运维操作封装成脚本，注册到 PATH。AI 只需知道**有哪些脚本**和**什么时候调用**，不需要记具体命令。

───

## 脚本工具箱模式

- `~/skills/` — 功能脚本存放
- `~/.local/bin/` — PATH 注册
- `/usr/local/bin/` — 全局命令（wrt-capture, flash_device）

### Kaiboer Home 安装流程

> 用户说「安装 Kaiboer Home」
> → curl 192.168.10.200:6688 获取版本列表
> → 列出可选版本 → 等用户选择
> → curl 下载 APK
> → adb install -r -d 到手机

### GitLab 代码浏览

> [!WARNING]
> 内网 GitLab 不支持 basic auth，需 Chrome CDP 登录。浏览代码确保**只读**。

1. `open -a Google\ Chrome --args --remote-debugging-port=18800`
2. CDP 自动填账号密码
3. DOM 选择器定位项目列表

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 复用指南

> [!TIP]
> **脚本工具箱 3 步搭建**：建目录 → symlink 到 `/usr/local/bin` → 写入 MEMORY.md 让 AI 知道。

```bash
#!/bin/bash
# [功能名称]
# 用法: [命令名] [参数]

# ---- 配置 ----
TARGET="[目标地址/设备]"

# ---- 依赖检查 ----
# 检查必需命令是否存在

# ---- 交互参数 ----
# read/select 获取输入

# ---- 执行 ----
# 核心逻辑

# ---- 反馈 ----
# 成功/失败的清晰输出
```

### CI/CD 型操作模式

**拉取列表 → 用户选择 → 下载 → 安装 → 验证**，这个模式可迁移到任何部署场景：

- APK → IPA/EXE/DMG
- `adb install` → `brew cask install`/`dpkg -i`
