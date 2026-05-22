# OpenClaw 训练手册

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

> 💡 飞书文件助手「虾小丘」的训练记录和使用方式。

───

## 架构概览

```
飞书用户 ──→ 飞书通道 ──→ Gateway (WS) ──→ Agent (DeepSeek) ──→ 技能/工具
                                           ├── 知识库 (knowledge-base/)
                                           ├── 飞书索引 (feishu-index/)
                                           └── 记忆系统 (memory/ + 向量库)
```

| 组件 | 作用 |
|------|------|
| **Gateway** | WebSocket 服务，管理会话和路由 |
| **Agent** | AI 核心，读取 IDENTITY/SOUL/USER/MEMORY 文件获取上下文 |
| **Channel** | 飞书（当前唯一通道），用户通过飞书 DM 与助手交互 |
| **Skills** | 13 个就绪技能（飞书文档/Android控制/Midscene/天气等） |

───

## 文档索引

| 场景 | 文档 | 核心内容 |
|------|------|---------|
| 身份设定 | [identity.md](./identity.md) | 名字/性格/沟通风格/身份三件套 |
| 行为规范 | [behaviors.md](./behaviors.md) | 6条硬规则/客服视角/优先级体系 |
| 日志分析 | [log-analysis.md](./log-analysis.md) | SSH下载→8步分析→云盘归档 |
| 文档管理 | [feishu-docs.md](./feishu-docs.md) | FAQ维护/索引系统/开发汇总 |
| 设备诊断 | [device-diagnosis.md](./device-diagnosis.md) | MAC→日志→交叉验证→报告 |
| 日常运维 | [daily-ops.md](./daily-ops.md) | 装APK/烧固件/抓包/GitLab |
| Android测试 | [android-testing.md](./android-testing.md) | pytest+uiautomator2+Midscene |
| 知识检索 | [knowledge.md](./knowledge.md) | 向量库/飞书索引/知识库 |
| 记忆系统 | [memory-system.md](./memory-system.md) | 每日日志/长期记忆/向量搜索 |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔄 复用指南

### 什么时候适合用 OpenClaw？

| 适合 | 不适合 |
|------|--------|
| 把 AI 接入即时通讯工具（飞书、微信、Telegram 等） | 零散的终端问答（用 opencode/Claude Code 更合适） |
| 有固定工作领域，训练专门的 AI 助手（客服、日志分析、文档管理） | 纯编程任务（coding-agent 可调度，但不如直接用 IDE 工具） |
| 需要定时任务（每日汇总、索引更新、打卡提醒） | 需要复杂 UI 操作的场景 |

### 新项目搭建步骤

| 步骤 | 命令/操作 |
|------|----------|
| 1 | `npm i -g openclaw` 安装 |
| 2 | `openclaw onboard` 交互式配置通道、模型、身份 |
| 3 | 配置三件套：**IDENTITY.md**（谁）/ **SOUL.md**（怎么做事）/ **USER.md**（什么用户） |
| 4 | `openclaw channels login` 绑定飞书/Telegram/Discord 等 |
| 5 | 把项目相关的 FAQ、架构文档放到 **workspace/knowledge-base/** |
| 6 | **MEMORY.md** 写长期记忆，**memory/** 写每日日志 |
| 7 | 通过 ClawHub 安装需要的技能 |
