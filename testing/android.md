# uiautomator2 + ADB

## uiautomator2

Python 封装的 Android UI 自动化库，通过 ADB 控制设备上的屏幕操作。

### 在 kaiboer 项目中的用法

#### 绕过开机引导

- 自动找到"跳过""下一步""完成"等按钮并点击
- 处理多页面引导流程，每页等待并检查元素出现
- 设置超时和回退机制，防止某个页面卡住整条流程
- 引导完成后关闭功能设置提示弹窗，最终确认进入桌面

#### WiFi 连接

- 打开 WiFi 设置界面
- 在可用网络列表中滚动找到目标 SSID
- 输入密码并连接
- 验证分配到的 IP 地址，确认连接成功
- 备选方案：当 UI 操作失败时，回退到 `cmd wifi` 命令连接

#### 应用安装与生命周期

- 通过 monkey 命令冷启动 app（不需要知道具体 activity 名）
- 监听当前前台包名变化判断 app 是否成功启动
- 在应用内找到退出/关闭/返回按钮并点击
- 检测应用是否回到桌面

#### 播放器控制

- 直接通过 Intent 把本地音频文件路径传给 KBEPlayer 播放（无需手动操作播放器界面）
- 通过系统广播发 STOP/PLAY 指令控制播放
- 检查播放状态日志确认音频真实在输出

#### UI 全量遍历

- 逐页 dump 当前屏幕的 XML 元素层级
- 找到所有可点击和可滚动的元素
- 用深度优先搜索递归进入每个子页面
- 每个页面生成唯一的签名避免重复
- 最终输出结构化的页面快照索引，记录每个页面的元素列表和可达路径

---

## ADB（通过 subprocess 调用）

Android Debug Bridge，与安卓设备通信的命令行工具。

### 在 kaiboer 项目中的用法

#### 设备管理

- 重启设备、恢复出厂设置
- 等待设备启动完成（检查 `sys.boot_completed` 和包管理器就绪）
- 连接时 USB 优先，USB 断开后自动切到网络 ADB

#### 系统信息采集

- 获取设备型号和 Android 版本号
- 读取 WiFi 接口的 IP 地址
- 生成设备快照用于测试报告追溯

#### 进程管理

- 通过 `am force-stop` 强制杀进程
- 通过 `pm list packages` 验证应用是否已安装
- 通过 `getprop` 检查系统属性和 ota 升级状态

#### 兜底方案

- 当 uiautomator2 的点击操作返回成功但实际未生效时，用 `adb input tap` 代替
- 当需要直操作屏幕坐标而 uiautomator2 无法定位到对应元素时，手动传入坐标点击

---

## 复用指南

### 1. 开机引导跳过通用流程

**核心思想**：不是对特定页面写死点击逻辑，而是构建一个「等待→检查→点击→兜底」的状态机。

**通用流程**：
1. 检测当前是否在引导页面（通过特定文本或 package 判断）
2. 找到可点击的「跳过/下一步/同意/完成」按钮
3. 点击后等待新页面出现，超时则重试
4. 如果 UI 操作失败，回退到 `adb shell input tap x y`
5. 引导循环直到进入桌面（package = launcher）

**新项目迁移**：换 3 个东西搞定 — 目标 package 名、各页面按钮文本、adb input 坐标。

### 2. 应用启动验证模式

**核心思想**：不依赖知道 activity 名，用 monkey 冷启动 + 包名监听判断成功。

**通用代码模式**：
```python
# 启动
device.shell(["monkey", "-p", package_name, "-c", "android.intent.category.LAUNCHER", "1"])
# 验证
time.sleep(等待时间)
current = device.app_current()
assert package_name == current['package']
# 退出
device.shell(["am", "force-stop", package_name])
```

**新项目**只需换 package_name 和等待时间。

### 3. UI 全量遍历 DFS 模式

**核心思想**：dump 当前页面 XML → 找到所有可点击元素 → 逐个点击 → 回退 → 换下一个。

**通用框架**：
1. `dump_hierarchy()` 获取当前页面 XML
2. 解析所有 `clickable=true` 的节点
3. 给每个页面生成签名（节点文本+class哈希），去重
4. 深度优先：点一个元素 → 递归探索新页面 → 回退 → 点下一个
5. 输出结构化索引：页面签名、路径、元素列表

**新项目**只需换目标 package 名和模块定义（哪些页面属于哪个模块）。

### 4. ADB 兜底设计哲学

**核心思想**：uiautomator2 是主方案，adb 是备选。每一步操作都应有 fallback。

**永远生效的兜底**：
- `(x, y).click()` 失败 → `adb shell input tap x y`
- 找元素失败 → `dump_hierarchy()` 打印所有可见文本，辅助定位
- 连不上设备 → USB 自动切 IP 重试
