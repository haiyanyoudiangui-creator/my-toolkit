# 知识检索

## 做了什么

虾小丘有三套知识检索体系：

| 体系 | 用途 | 数据规模 |
|------|------|---------|
| **知识库文件** | workspace/knowledge-base/ 下 5 个 markdown 文件，记录架构/Bug/FAQ/变更/总结 | 长期积累 |
| **飞书索引** | feishu-index/ 下本地索引，避免频繁调飞书 API | 全量飞书文档 |
| **向量数据库** | Ollama + ChromaDB，195 个文档块，语义搜索历史记忆 | 所有 memory + 知识库 |

## 核心思路

### 检索优先级

```
用户提问
  → 1. 查向量库（语义搜索） → 相似度 > 0.75 直接引用
  → 2. 读知识库文件 → 精准匹配
  → 3. 查飞书本地索引 → 找文档 ID
  → 4. 调飞书 API → 全局搜索
```

从快到慢、从本地到远程。

### 向量数据库搭建

- **Ollama**：本地 embedding 服务，运行 `nomic-embed-text` 模型（274MB），将文本转为 768 维向量
- **ChromaDB**：向量存储，持久化到本地文件
- **索引脚本**：`migrate.py` 读取 workspace 下的 markdown 文件 → 按 ## 标题分块 → 向量化 → 存入 ChromaDB → 已存在的块不重复添加
- **查询脚本**：`query.py "关键词"` → 返回 Top 5 相似块

### 飞书索引系统

本地维护三份索引：
- **INDEX.md**：全量文件，每条含标题、ID、类型、标签、更新时间、一句话摘要
- **by-tag.md**：按标签分组，快速按主题查找
- **by-wiki.md**：按知识库分组

每天凌晨自动增量更新（通过 cron 任务）。

## 复用指南

### 向量数据库搭建步骤

**3 步搭建**：

1. **安装 Ollama**：`brew install ollama` → `ollama pull nomic-embed-text`
2. **安装 ChromaDB**：`pip install chromadb`
3. **部署脚本**：
```bash
# 创建向量库目录
mkdir -p ~/.openclaw/vector_db/
# 放两个脚本：migrate.py（索引更新）和 query.py（查询）
```

**脚本模板**：
```python
# migrate.py 的核心逻辑
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

**query.py 的核心逻辑**：
```python
embedding = ollama.embed(model="nomic-embed-text", input=query)
results = collection.query(query_embeddings=[embedding], n_results=5)
for doc, score in zip(results["documents"][0], results["distances"][0]):
    if score > 0.75:
        print(f"[{score:.3f}] {doc[:200]}...")
```

### 检索优先级策略通用

这个「向量库 → 知识库文件 → 本地索引 → API」的四层检索漏斗适用于任何需要文档检索的 AI 助手场景。

**迁移步骤**：
1. 先扔现有的文档/FAQ 到向量库建立基础索引
2. 高频文档单独建本地索引（减少向量库查询）
3. API 作为最后兜底
