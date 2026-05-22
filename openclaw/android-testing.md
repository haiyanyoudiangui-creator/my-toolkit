# Android 测试

## 做了什么

虾小丘通过 OpenClaw 调度 Android 设备自动化测试：
- 基础 UI 操作 → 通过 `android_control` / `android-control-2` 技能
- 视觉驱动自动化 → 通过 Midscene（`midscene-android-automation` 技能）
- 完整自动化框架 → 结合 pytest + uiautomator2 + Allure（本地测试框架）

## 核心思路

### 三层测试体系

| 层级 | 工具 | 使用方式 |
|------|------|---------|
| **即时操作** | android_control 技能 | 飞书里说「截屏」「点击XX」→ OpenClaw 直接 adb 操作 |
| **视觉自动化** | Midscene 技能 | 说「测试 app 安装流程」→ AI 看图识别元素并操作 |
| **完整框架** | pytest + uiautomator2 | 本地跑全量回归，Allure 出报告 |

### Midscene 视觉驱动

与传统 uiautomator2 的区别：
- **传统方式**：需要知道元素的 resource-id、text、xpath
- **Midscene 方式**：说「点击屏幕上的播放按钮」→ AI 看图找到按钮位置 → 点击

适用场景：无法定位到 DOM/accessibility 元素的混合应用或系统级 UI。

### 本地测试框架集成

虾小丘知道测试框架在 `~/Desktop/kaiboer-test-framework/`：
- 工具链：pytest + uiautomator2 + Allure
- 引导开关：`adb shell setprop persist.kbe.launcher.guide true`
- DebugAPK 装载流程：adb root → remount → push → reboot

## 复用指南

### 新 Android 设备测试迁移

**只需换**：
1. 包名和 activity 名
2. 页面元素文本（按钮名、页面标识）
3. 配置文件里的设备序列号、WiFi 信息、应用下载地址

**不需要换的**：
- pytest 的 fixture 管理设备生命周期的模式
- uiautomator2 的连接、点击、dump、swipe 基础操作
- Allure 的 feature/story/step 分层报告结构
- conftest hooks（用例过滤、失败汇总）

### Midscene 视觉自动化集成

**适用条件**：
- 设备开启了 ADB 调试
- 手机上安装了 Midscene 的辅助服务
- 场景是页面元素无法通过传统方式定位的

**集成步骤**：
1. 在 OpenClaw workspace/skills/ 安装 `midscene-android-automation`
2. 确保手机 ADB 已连接
3. 用自然语言描述操作：「打开设置 → 找到 WiFi → 点击连接」

**优缺点**：
- 优点：不需要写代码，不需要知道元素 ID，接近人类操作方式
- 缺点：速度比传统方式慢（需要截图+AI识别），对复杂动态页面的识别率不如手动定位
