# 知识检索

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 做了什么

虾小丘有三套知识检索体系：

- **知识库文件**：workspace/knowledge-base/（架构/Bug/FAQ/变更）
- **飞书索引**：本地索引，避免频繁调飞书 API
- **向量数据库**：Ollama + ChromaDB，195 文档块语义搜索

> [!IMPORTANT]
> 检索优先级：向量库 → 知识库文件 → 飞书索引 → 飞书 API。从快到慢、从本地到远程。

───

## 向量数据库架构

- **Ollama**（0.24.0）：本地 embedding 服务，运行 `nomic-embed-text`（274MB），转 768 维向量
- **ChromaDB**（1.5.9）：向量存储，持久化到本地文件
- **migrate.py**：读取 workspace/*.md → 按 ## 分块 → 向量化 → 存入 ChromaDB
- **query.py**：`python3 query.py "关键词"` → Top 5 相似块

### 使用时机

- 会话开始：`curl -s http://127.0.0.1:11434` 确认 Ollama 存活，否则 `ollama serve &`
- 写了新 memory：`migrate.py` 增量更新，已存在块不重复
- 用户问「还记得之前...」：`query.py` 语义搜索
- 心跳维护（2-3天一次）：`migrate.py` 同步索引

───

## 飞书索引

- **INDEX.md**：全量文件（标题、ID、类型、标签、摘要）
- **by-tag.md**：按标签分组
- **by-wiki.md**：按知识库分组

每天凌晨 cron 自动增量更新。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 复用指南

> [!TIP]
> **四层检索漏斗通用**。新项目先扔文档到向量库建索引 → 高频文档单独建本地索引 → API 兜底。

### 向量库搭建步骤

1. `brew install ollama`
2. `ollama pull nomic-embed-text`
3. `pip install chromadb`
4. 部署 migrate.py + query.py

```python
# migrate.py 核心
client = chromadb.PersistentClient(path="./chroma_data")
collection = client.get_or_create_collection("memory")
for chunk in split_by_headers(md_file):
    embedding = ollama.embed(model="nomic-embed-text", input=chunk.text)
    collection.add(ids=[chunk.hash], embeddings=[embedding], documents=[chunk.text])
```

```python
# query.py 核心
embedding = ollama.embed(model="nomic-embed-text", input=query)
results = collection.query(query_embeddings=[embedding], n_results=5)
if score > 0.75: print(f"[{score:.3f}] {doc[:200]}...")
```
