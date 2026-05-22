# uiautomator2 + ADB

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## uiautomator2

Python 封装的 Android UI 自动化库，通过 ADB 控制设备上的屏幕操作。

> [!IMPORTANT]
> 核心模式：等待→检查→点击→兜底 四步状态机 + monkey 包名监听启动验证 + DFS 全量 UI 遍历。

### 在 kaiboer 项目中的用法

**绕过开机引导**

1. 自动找到**跳过/下一步/完成**等按钮并点击
2. 处理多页面引导流程，每页等待并检查元素出现
3. 设置**超时和回退**机制，防止某个页面卡住整条流程
4. 引导完成后关闭功能设置提示弹窗，确认进入桌面

**WiFi 连接**

1. 打开 WiFi 设置界面
2. 在可用网络列表中**滚动**找到目标 SSID
3. 输入密码并连接
4. 验证分配到的 IP 地址

> [!WARNING]
> 当 UI 操作失败时，回退到 `cmd wifi` 命令连接。

**应用安装与生命周期**

- **启动**：通过 monkey 命令冷启动 app，不需要知道具体 activity 名
- **验证**：监听当前前台包名变化判断 app 是否成功启动
- **退出**：在应用内找到关闭/返回按钮并点击，检测是否回到桌面

**播放器控制**

- 通过 **Intent** 直接把本地音频文件路径传给 KBEPlayer（无需手动操作播放器界面）
- 通过系统 **Broadcast** 发 STOP/PLAY 指令控制播放
- 检查播放状态日志确认音频真实在输出

**UI 全量遍历**

1. `dump_hierarchy()` 获取当前页面 XML
2. 解析所有可点击和可滚动的元素
3. 用**深度优先搜索**递归进入每个子页面
4. 每个页面生成唯一签名去重
5. 输出结构化页面快照索引，记录元素列表和可达路径

───

## ADB（通过 subprocess 调用）

Android Debug Bridge，与安卓设备通信的命令行工具。

> [!IMPORTANT]
> 核心哲学：uiautomator2 是主方案，adb 是兜底。**每一步操作都应有 fallback**。

### 在 kaiboer 项目中的用法

**设备管理**

- 重启设备、恢复出厂设置
- 等待启动完成（检查 `sys.boot_completed` 和包管理器就绪）
- USB 优先连接，断开后自动切到网络 ADB

**系统信息采集**

- `adb shell getprop` 获取型号和 Android 版本
- `adb shell ip addr show wlan0` 获取 WiFi IP

**进程管理**

- `am force-stop` 强制杀进程
- `pm list packages` 验证应用已安装
- `getprop` 检查系统属性和 OTA 升级状态

**兜底方案**

| 主方案失败 | 兜底 |
|-----------|------|
| `(x, y).click()` 未生效 | `adb shell input tap x y` |
| 找元素失败 | `dump_hierarchy()` 打印所有可见文本辅助定位 |
| 连不上设备 | USB 自动切 IP 重试 |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 复用指南

### 1. 开机引导跳过通用流程

> [!TIP]
> 不是对特定页面写死逻辑，而是构建「等待→检查→点击→兜底」的**状态机**。新项目只需换 3 个东西：目标 package 名、按钮文本、adb input 坐标。

### 2. 应用启动验证模式

不依赖知道 activity 名，用 monkey 冷启动 + 包名监听判断成功。**新项目只需换 package_name 和等待时间**。

```python
device.shell(["monkey", "-p", pkg, "-c", "android.intent.category.LAUNCHER", "1"])
current = device.app_current()
assert pkg == current['package']
device.shell(["am", "force-stop", pkg])
```

### 3. UI 全量遍历 DFS 模式

1. dump 当前页面 XML → 解析所有 `clickable=true` 节点
2. 生成页面签名（节点文本+class 哈希）去重
3. 深度优先：点元素 → 递归新页面 → 回退 → 下一个
4. 输出结构化索引

**新项目只需换**：目标 package 名和模块定义。DFS 框架、签名生成逻辑不变。

### 4. ADB 兜底设计

> [!TIP]
> 每条 uiautomator2 操作旁放一个 adb 备选。连接层也应有 fallback（USB → IP）。这个设计哲学通用。

───

## 在 OpenClaw 中的集成

虾小丘（飞书文件助手）通过 OpenClaw 调度 Android 测试，分三层：

- **即时操作**：android_control 技能 — 在飞书发「截屏」「点击XX」→ 直接 adb 操作
- **视觉自动化**：Midscene 技能 — AI 看图识别元素，不需要知道元素 ID，适合混合应用和系统级 UI
- **完整框架**：pytest + uiautomator2 — 在 `~/Desktop/kaiboer-test-framework/` 跑全量回归，Allure 出报告

> [!NOTE]
> Midscene 优点是不需要写代码、自然语言操作；缺点是速度慢，复杂动态页面识别率不如手动定位。适用条件：设备开启 ADB 调试 + 手机安装 Midscene 辅助服务。
