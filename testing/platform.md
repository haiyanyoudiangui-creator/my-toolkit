# 测试平台 & 配置

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## fastapi + uvicorn

> 💡 Python Web 框架，用来快速搭建测试用例管理平台。

───

### 在 kaiboer 项目中的用法

| 功能 | 说明 |
|------|------|
| **用例管理** | 470 条测试用例的增删改查、按模块/标签筛选、搜索 |
| **执行记录** | 记录每次执行的结果、耗时、失败原因和设备信息 |
| **失败统计** | 失败用例按模块和类型自动分类统计 |
| **手动录入** | 支持手动录入测试结果和标记状态（通过/失败/阻塞/跳过） |
| **计划模板** | 保存常用的用例组合，一键切换测试范围 |

浏览器打开即可访问，**本地运行无需部署**。

───

## sqlite3

> 💡 嵌入式本地数据库，无需安装服务端。

───

### 在 kaiboer 项目中的用法

| 表 | 内容 |
|------|------|
| 测试用例表 | 从 Excel 导入的 470 条用例（ID、标题、步骤、预期结果） |
| 执行记录表 | 每次运行的耗时、失败原因 |
| 设备快照表 | 型号、系统版本、IP |
| 用例绑定表 | 用例 ID ↔ pytest nodeid 的映射关系 |

数据库文件持久化保存在 artifacts 目录，**零配置**。

───

## pyyaml

> 💡 Python 解析 YAML 配置文件的库。

───

### 在 kaiboer 项目中的用法

| 文件 | 作用 |
|------|------|
| **device.yaml** | 设备配置中心：序列号、WiFi 信息、应用下载地址、UI 遍历参数、音频测试配置 |
| **automation.yaml** | 用例计划：人类可读的 ID 映射到 pytest nodeid，支持 run（一组用例）和 plan（多组 run 组合） |

一份文件包含全部运行时配置，按需灵活切换测试范围。

───

## httpx

> 💡 Python HTTP 客户端库（类似 requests，但支持异步）。

───

### 在 kaiboer 项目中的用法

| 用途 | 说明 |
|------|------|
| 平台接口测试 | 用 FastAPI 的 TestClient（底层是 httpx）写平台接口的单元测试 |
| 验证 | 检查用例查询/创建/更新等 API 返回的状态码和数据结构 |

不需要启动真实服务即可跑通接口测试。

───

## Excel 导入

> 💡 用 Python 原生 zipfile + xml.etree 解析 XLSX，**不依赖第三方库**。

───

### 在 kaiboer 项目中的用法

| 步骤 | 做什么 |
|------|--------|
| 1 | `zipfile.ZipFile()` 打开 xlsx |
| 2 | 读取 `xl/sharedStrings.xml` 获取所有文本单元格内容 |
| 3 | 遍历 `xl/worksheets/sheet*.xml` 逐表解析行数据 |
| 4 | 通过 sharedStrings 索引把数字 ID 还原为实际文本 |
| 5 | 按模块分组写入 sqlite，平台刷新后用例库即可更新 |

原始需求文档有 **8 个工作表、470 条用例**。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔄 复用指南

### 1. FastAPI + sqlite3 轻量平台模板

> 💡 不是搞重型系统，是几百行代码搭一个够用的本地方案。

| 组件 | 作用 |
|------|------|
| **FastAPI** | 定义 REST 接口（`/cases`、`/executions`、`/plans`） |
| **sqlite3** | 存用例、执行记录、绑定关系 |
| **Jinja2/原生 HTML** | 渲染页面 |
| **uvicorn** | 一键启动 |
| **conftest hooks** | pytest 结果自动写入平台 |

| 需要改 | 不需要动 |
|---------|---------|
| 数据库表结构（字段名、表数量） | API 路由框架、页面模板结构 |

### 2. YAML 配置分离模式

> 💡 运行时配置（设备/WiFi/APP）和测试计划（用例列表/分组）分开两份 YAML。

**device.yaml 模板**：
```yaml
device: { serial, ip, adb_timeout }
wifi: { ssid, password, timeout }
apps: [{ name, url, package, launch_seconds }]
ui_dump: { target_package, max_depth, module_definitions }
audio: { scan_roots, sample_count }
```

**automation.yaml 模板**：
```yaml
automations:
  first_boot:
    nodeid: "tests/test_skip_guide.py::TestSkipGuide::test_skip_guide"
    name: "恢复出厂后跳过开机引导并连接WiFi"
runs:
  smoke: { cases: [first_boot, launcher_home] }
plans:
  full: { runs: [smoke, network, audio] }
```

| 需要改 | 不需要动 |
|---------|---------|
| YAML 里的具体值 | 解析代码 |

### 3. Excel 零依赖解析导入

> 💡 XLSX 本质是 ZIP 包，原生工具即可解析，不需要 openpyxl。

| 需要改 | 不需要动 |
|---------|---------|
| Excel 文件名和工作表名 | 完整解析流程 |

### 4. pytest 集成模式

> 💡 测试平台不依赖手动录入结果，pytest 跑完自动入库。

| 集成点 | 做什么 |
|--------|--------|
| `pytest_sessionstart` | 创建执行记录 |
| `pytest_runtest_makereport` | 把每个用例结果写入 sqlite |
| `pytest_sessionfinish` | 更新执行状态为完成 |

**新项目**：拷贝 conftest 的 hook 代码，替换 sqlite 表和字段名。
