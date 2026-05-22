# 记忆系统

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 做了什么

虾小丘有三层记忆，实现从短期到长期持久化：

- **短期**：`memory/YYYY-MM-DD.md` — 每天做了什么、对话摘要
- **长期**：`MEMORY.md` — 提炼后的核心知识、行为规范、已分析问题
- **向量**：ChromaDB（195 文档块）— 语义搜索入口

> [!IMPORTANT]
> 会话启动加载：SOUL.md + USER.md → 昨天+今天的 daily memory → 主会话额外加 MEMORY.md。**AI 不信任「我记住了」，必须写文件**。

───

### 三层协作

- 用户说了值得记的事 → 追加今天 daily memory
- 重要决策/教训 → 同步写入 MEMORY.md（不常写，只存精华）
- 写了新 memory → `migrate.py` 增量更新向量索引

───

### 心跳维护（每 30 分钟一次）

**轻量检查**（大多数心跳）：

- Ollama 存活？`curl -s http://127.0.0.1:11434`，挂了就 `ollama serve &`
- 无紧急事项 → 回复 `HEARTBEAT_OK`

**深度维护**（2-3 天一次）：

- 回顾 daily memory → 提炼更新 MEMORY.md
- 清理过时配置
- 运行 `migrate.py` 同步向量索引

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 复用指南

> [!TIP]
> 三层记忆模型适用于任何需要长期记忆的 AI 助手。

```
memory/YYYY-MM-DD.md (天)
     ↓ 提炼
MEMORY.md (永久)
     ↓ 索引
向量数据库 (可搜索)
```

### 文件结构

```
workspace/
├── MEMORY.md              # 长期记忆
├── memory/
│   ├── YYYY-MM-DD.md      # 每日短期记忆
│   └── heartbeat-state.json
└── vector_db/
    ├── migrate.py / query.py
    └── chroma_data/
```

### 短期记忆模板

```markdown
# YYYY-MM-DD
## 做了什么
- [记录交互和操作]
## 新学到的
- [新知识/配置]
## 待跟进
- [未解决问题]
```

### 长期记忆模板

```markdown
# MEMORY.md
## 用户 — [信息、偏好]
## 基础设施 — [服务器、设备]
## 已分析问题 — [编号：描述→根因→结论]
## 行为规范 — [核心规则]
```

### 心跳模板（HEARTBEAT.md）

```markdown
每次心跳：
- [ ] Ollama 存活
- [ ] 磁盘空间

深度维护（2-3天）：
- [deep] 审查 daily memory → 更新 MEMORY.md
- [deep] 运行向量索引同步
```
