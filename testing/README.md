# 测试工具

> 记录我在 kaiboer 项目中实际使用的测试相关工具。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 推荐阅读路线

| 顺序 | 文档 | 适合场景 |
|------|------|----------|
| 1 | [pytest 实战复盘](./pytest-practice.md) | 先理解 kaiboer 自动化测试整体设计：命令入口、YAML 编排、hook 流水线、证据沉淀 |
| 2 | [pytest + allure](./framework.md) | 再看 pytest、fixture、hooks 和 Allure 报告如何落地 |
| 3 | [uiautomator2 + ADB](./android.md) | 需要理解 Android 真机控制、UI 自动化和 ADB 兜底时阅读 |
| 4 | [测试平台 & 配置](./platform.md) | 关注用例平台、SQLite、Excel 导入和配置管理时阅读 |
| 5 | [辅助工具](./utility.md) | 排查网络、日志、JSON、媒体文件问题时按需查阅 |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 文档索引

| 分类 | 文档 | 核心内容 |
|------|------|----------|
| 实战分享 | [pytest 实战复盘](./pytest-practice.md) | Android 真机自动化流水线、case/run/plan 编排、失败证据设计 |
| 框架 & 报告 | [pytest + allure](./framework.md) | pytest 用例组织、fixture 生命周期、Allure 分层报告 |
| Android 自动化 | [uiautomator2 + ADB](./android.md) | 真机连接、UI 点击、ADB 命令、页面遍历 |
| 测试平台 & 配置 | [fastapi + sqlite3 + pyyaml + httpx + Excel 导入](./platform.md) | Web 用例平台、配置驱动、执行记录、Excel 同步 |
| 辅助工具 | [Wireshark + wrt-capture + requests + ripgrep + jq + ffmpeg + mediainfo](./utility.md) | 抓包、接口请求、日志搜索、JSON 处理、媒体校验 |
| 脚本 | [wrt-capture.sh 抓包脚本](./scripts/wrt-capture.sh) | OpenWRT 远程抓包并直传本地 |

## 常用入口

- 想快速了解整体设计：先看 [pytest 实战复盘](./pytest-practice.md)。
- 想照着搭测试框架：看 [pytest + allure](./framework.md) 的复用指南。
- 想排查 Android 真机问题：看 [uiautomator2 + ADB](./android.md)。
- 想扩展用例平台：看 [测试平台 & 配置](./platform.md)。
