# Android 测试

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 做了什么

虾小丘通过 OpenClaw 调度 Android 设备自动化测试：

| 层级 | 工具 | 使用方式 |
|------|------|---------|
| **即时操作** | android_control 技能 | 飞书里说「截屏」「点击XX」→ 直接 adb 操作 |
| **视觉自动化** | Midscene 技能 | 说「测试 app 安装流程」→ AI 看图识别元素并操作 |
| **完整框架** | pytest + uiautomator2 | 本地跑全量回归，Allure 出报告 |

───

## 核心思路

### Midscene 视觉驱动 vs 传统方式

> 💡 传统方式需要知道元素 ID/文本/xpath，Midscene 直接看图找按钮。

| 对比 | 传统 uiautomator2 | Midscene |
|------|------------------|----------|
| 定位方式 | resource-id / text / xpath | AI 截图识别 |
| 适用场景 | 标准 Android 应用 | 混合应用、系统级 UI、无法定位元素时 |
| 速度 | 快 | 慢（需截图+AI识别） |
| 上手难度 | 需要写代码 | 自然语言描述即可 |

### 本地测试框架

虾小丘知道测试框架在 **`~/Desktop/kaiboer-test-framework/`**：

| 组件 | 说明 |
|------|------|
| **pytest** | 测试运行器 + fixtures + hooks |
| **uiautomator2** | 设备 UI 操作 |
| **Allure** | 分层报告（feature/story/step/attach） |
| **引导开关** | `adb shell setprop persist.kbe.launcher.guide true` |
| **DebugAPK 装载** | `adb root → remount → push → reboot` |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔄 复用指南

### 新 Android 设备测试迁移

| 需要改 | 不需要动 |
|---------|---------|
| 包名和 activity 名 | pytest 的 fixture 管理设备生命周期模式 |
| 页面元素文本（按钮名、页面标识） | uiautomator2 的连接/点击/dump/swipe 基础操作 |
| 配置文件里的设备序列号、WiFi、应用下载地址 | Allure 的 feature/story/step 分层报告结构 |
| - | conftest hooks（用例过滤、失败汇总） |

### Midscene 集成条件

| 条件 | 说明 |
|------|------|
| 设备开启 ADB 调试 | 必须 |
| 手机安装 Midscene 辅助服务 | 必须 |
| 场景是无法通过传统方式定位元素时使用 | 推荐 |

| 优点 | 缺点 |
|------|------|
| 不需要写代码，不需要知道元素 ID | 速度比传统方式慢 |
| 接近人类操作方式 | 对复杂动态页面的识别率不如手动定位 |
