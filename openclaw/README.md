# OpenClaw 训练手册

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

飞书文件助手「虾小丘」的训练记录和使用方式。

> [!IMPORTANT]
> OpenClaw 是一个 AI Agent Gateway，架构分四层：飞书通道 → Gateway → Agent(DeepSeek) → 技能/工具。Agent 读取 IDENTITY/SOUL/USER/MEMORY 文件获取上下文，通过 Skills 执行操作。

───

## 架构

```text
飞书用户 ──→ 飞书通道 ──→ Gateway (WS) ──→ Agent (DeepSeek) ──→ 技能/工具
                                           ├── 知识库 (knowledge-base/)
                                           ├── 飞书索引 (feishu-index/)
                                           └── 记忆系统 (memory/ + 向量库)
```

- **Gateway**：WebSocket 服务，管理会话和路由
- **Agent**：AI 核心，加载 IDENTITY/SOUL/USER/MEMORY
- **Channel**：飞书（唯一通道），用户通过飞书 DM 交互
- **Skills**：13 个就绪技能（飞书文档/Android控制/Midscene/天气等）

───

## 文档索引

| 场景 | 文档 | 核心内容 |
|------|------|---------|
| 身份设定 | [identity.md](./identity.md) | 名字/性格/三件套模板 |
| 行为规范 | [behaviors.md](./behaviors.md) | 6条规则/客服视角/优先级 |
| 日志分析 | [log-analysis.md](./log-analysis.md) | SSH→8步分析→云盘归档 |
| 文档管理 | [feishu-docs.md](./feishu-docs.md) | FAQ/索引/开发汇总 |
| 设备诊断 | [device-diagnosis.md](./device-diagnosis.md) | MAC→日志→交叉验证 |
| 日常运维 | [daily-ops.md](./daily-ops.md) | 装APK/烧固件/抓包 |
| Android测试 | [android-testing.md](./android-testing.md) | pytest+uiautomator2+Midscene |
| 知识检索 | [knowledge.md](./knowledge.md) | 向量库/飞书索引/知识库 |
| 记忆系统 | [memory-system.md](./memory-system.md) | 每日日志/长期记忆/向量 |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 复用指南

### 适合 vs 不适合

- **适合**：AI 接入 IM 工具 / 训练专用助手 / 定时任务
- **不适合**：零散终端问答 / 纯编程任务 / 需要复杂 UI 操作

### 新项目搭建步骤

1. `npm i -g openclaw`
2. `openclaw onboard` 交互式配置
3. 写三件套：**IDENTITY.md**（谁）/ **SOUL.md**（怎么做事）/ **USER.md**（什么用户）
4. `openclaw channels login` 绑定通道
5. 知识库文件放到 **workspace/knowledge-base/**
6. **MEMORY.md** 写长期记忆，**memory/** 写每日日志
7. 通过 ClawHub 安装需要的技能
