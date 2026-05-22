# Android 测试

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 做了什么

虾小丘通过 OpenClaw 调度三层 Android 测试：

- **即时操作**（android_control 技能）：飞书说「截屏」「点击XX」→ 直接 adb 操作
- **视觉自动化**（Midscene 技能）：说「测试 app 安装流程」→ AI 看图识别元素
- **完整框架**（pytest + uiautomator2）：本地全量回归，Allure 出报告

> [!IMPORTANT]
> 传统 uiautomator2 需要知道元素 ID 和 xpath；Midscene 直接看图找按钮，适合无法定位元素的混合应用和系统级 UI。

───

### Midscene vs 传统方式

- **传统**：resource-id / text / xpath — 快，但需要写代码，只适用标准 Android 应用
- **Midscene**：AI 截图识别 — 慢，但自然语言操作，适用混合应用和系统 UI

───

### 本地测试框架

虾小丘知道框架在 **`~/Desktop/kaiboer-test-framework/`**：

- **pytest**：运行器 + fixtures + hooks
- **uiautomator2**：设备 UI 操作
- **Allure**：分层报告（feature/story/step/attach）
- **引导开关**：`adb shell setprop persist.kbe.launcher.guide true`
- **DebugAPK**：`adb root → remount → push → reboot`

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 复用指南

> [!TIP]
> **新 Android 设备只需换**：包名、activity 名、按钮文本、设备序列号、WiFi 信息、应用下载地址。fixture 模式、Allure 报告结构、conftest hooks 完全复用。

### Midscene 集成条件

- 设备开启 ADB 调试
- 手机安装 Midscene 辅助服务
- 适用场景：无法通过传统方式定位元素时

- 优点：不需要写代码，接近人类操作
- 缺点：速度慢，复杂动态页面识别率不如手动定位
