# 知识检索

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 做了什么

虾小丘有三套知识检索体系：

| 体系 | 用途 | 数据规模 |
|------|------|---------|
| **知识库文件** | workspace/knowledge-base/ 下 markdown 文件（架构/Bug/FAQ/变更/总结） | 积累中 |
| **飞书索引** | 本地索引避免频繁调飞书 API | 全量飞书文档 |
| **向量数据库** | Ollama + ChromaDB 语义搜索 | 195 个文档块 |

───

## 核心思路

### 检索优先级

> 💡 从快到慢、从本地到远程。

```
用户提问
  → 1️⃣ 查向量库（语义搜索） → 相似度 > 0.75 直接引用
  → 2️⃣ 读知识库文件 → 精准匹配
  → 3️⃣ 查飞书本地索引 → 找文档 ID
  → 4️⃣ 调飞书 API → 全局搜索兜底
```

───

### 向量数据库架构

| 组件 | 版本 | 说明 |
|------|------|------|
| **Ollama** | 0.24.0 | 本地 embedding 服务，`ollama serve` 后台运行 |
| **nomic-embed-text** | 274MB | 将文本转为 768 维向量 |
| **ChromaDB** | 1.5.9 | 向量存储，持久化到本地文件 |

### 索引脚本

| 文件 | 用途 | 命令 |
|------|------|------|
| `migrate.py` | 读取 workspace/*.md → 按 ## 分块 → 向量化 → 存入 ChromaDB | `python3 migrate.py` |
| `query.py` | 语义搜索，返回 Top 5 | `python3 query.py "关键词"` |

### 使用时机

| 场景 | 操作 |
|------|------|
| 会话开始 | `curl -s http://127.0.0.1:11434` 确认 Ollama 存活，否则 `ollama serve &` |
| 写了新 memory 后 | `migrate.py` 增量更新（已存在的不会重复添加） |
| 用户问「还记得之前...」 | `query.py "关键词"` 语义搜索 |
| 心跳维护（2-3天一次） | `migrate.py` 同步索引 |

───

### 飞书索引结构

| 文件 | 内容 |
|------|------|
| **INDEX.md** | 全量文件，每条含标题、ID、类型、标签、更新时间、一句话摘要 |
| **by-tag.md** | 按标签分组，快速按主题查找 |
| **by-wiki.md** | 按知识库分组 |
| **metadata.json** | 最后扫描时间、统计信息 |

每天凌晨通过 cron 任务自动增量更新。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔄 复用指南

### 向量数据库搭建步骤

| 步骤 | 命令 |
|------|------|
| 1 | `brew install ollama` |
| 2 | `ollama pull nomic-embed-text` |
| 3 | `pip install chromadb` |
| 4 | 部署 migrate.py + query.py |

**migrate.py 核心逻辑**：
```python
import chromadb
from ollama import embed

client = chromadb.PersistentClient(path="./chroma_data")
collection = client.get_or_create_collection("memory")

for md_file in workspace.glob("**/*.md"):
    for chunk in split_by_headers(md_file):
        if chunk_hash not in existing_hashes:
            embedding = ollama.embed(model="nomic-embed-text", input=chunk.text)
            collection.add(ids=[chunk.hash], embeddings=[embedding], documents=[chunk.text])
```

**query.py 核心逻辑**：
```python
embedding = ollama.embed(model="nomic-embed-text", input=query)
results = collection.query(query_embeddings=[embedding], n_results=5)
for doc, score in zip(results["documents"][0], results["distances"][0]):
    if score > 0.75:
        print(f"[{score:.3f}] {doc[:200]}...")
```

### 检索优先级策略

> 💡「向量库 → 知识库文件 → 本地索引 → API」四层漏斗适用于任何文档检索场景。

| 步骤 | 做什么 |
|------|------|
| 1 | 先扔现有文档/FAQ 到向量库建立基础索引 |
| 2 | 高频文档单独建本地索引（减少向量库查询） |
| 3 | API 作为最后兜底 |
