# 测试平台 & 配置

## fastapi + uvicorn

**是什么**：Python Web 框架，用来快速搭建测试用例管理平台。

**在 kaiboer 项目中的用法**：
- 搭建了一个本地的测试用例管理 Web 平台（浏览器打开即可访问）
- 470 条测试用例的增删改查、按模块/标签筛选、搜索
- 记录每次执行的结果、耗时、失败原因和设备信息
- 失败用例按模块和类型自动分类统计
- 支持手动录入测试结果和标记状态（通过/失败/阻塞/跳过）
- 计划模板管理，可以保存常用的用例组合

## sqlite3

**是什么**：嵌入式本地数据库，无需安装服务端。

**在 kaiboer 项目中的用法**：
- 存储从 Excel 导入的 470 条用例（用例ID、标题、步骤、预期结果等）
- 记录每次执行的运行结果和设备快照（型号、系统版本、IP）
- 用例绑定关系表（用例ID ↔ pytest nodeid 映射）
- 数据库文件持久化保存在 artifacts 目录，无需额外配置

## pyyaml

**是什么**：Python 解析 YAML 配置文件的库。

**在 kaiboer 项目中的用法**：
- **device.yaml**：设备配置中心，一份文件包含设备序列号、WiFi 信息、应用下载地址、UI遍历参数、音频测试配置等全部运行时配置
- **automation.yaml**：用例计划，用人类可读的 ID 映射到 pytest 的 nodeid，支持 run（一组用例）和 plan（多组 run 组合），按需灵活切换测试范围

## httpx

**是什么**：Python HTTP 客户端库（类似 requests，但支持异步）。

**在 kaiboer 项目中的用法**：
- 用 FastAPI 的 TestClient（底层是 httpx）写平台接口的单元测试
- 验证用例查询/创建/更新等 API 返回的状态码和数据结构
- 不需要启动真实服务即可跑通接口测试

## Excel 导入

**是什么**：把 Excel 测试用例表导入到本地数据库。

**在 kaiboer 项目中的用法**：
- 原始需求文档是一个有 8 个工作表的 XLSX，含 470 条用例
- 用 Python 原生 zipfile + xml.etree 解析（不依赖 openpyxl 等第三方库）
- 自动识别表头、提取步骤文本、按模块分组导入 sqlite
- 平台刷新后用例库即可更新，无需手动录入

---

## 复用指南

### 1. FastAPI + sqlite3 轻量用例管理平台

**核心思想**：不是搞一个重型测试管理系统，而是几百行代码搭一个够用的本地方案。

**通用模板五件套**：
1. FastAPI 定义 REST 接口（/cases, /executions, /plans）
2. sqlite3 存用例、执行记录、绑定关系
3. Jinja2/原生 HTML 模板渲染页面
4. uvicorn 一键启动
5. conftest hooks 把 pytest 结果自动写入平台

**新项目迁移**：换数据库表结构（字段名/表数量），API 路由和页面模板参考原代码。

### 2. YAML 配置分离模式

**核心思想**：运行时配置（设备/WiFi/APP）和测试计划（用例列表/分组）分开两份 YAML。

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

**新项目**只需改 YAML 值，不用改解析代码。

### 3. Excel 零依赖解析导入

**核心思想**：XLSX 本质是 ZIP 包，用原生 zipfile + xml.etree 即可解析，不需要 openpyxl。

**通用流程**：
1. `zipfile.ZipFile()` 打开 xlsx
2. 读取 `xl/sharedStrings.xml` 获取所有文本单元格内容
3. 遍历 `xl/worksheets/sheet*.xml` 逐表解析行数据
4. 通过 sharedStrings 索引把数字 ID 还原为实际文本
5. 按表头和模块分类写入 sqlite

**新项目**只需换 Excel 文件名和工作表名，解析逻辑完全复用。

### 4. pytest 集成模式

**核心思想**：测试平台不依赖手动录入结果，pytest 跑完自动入库。

**集成方法**：
- conftest 的 `pytest_sessionstart` 创建执行记录
- `pytest_runtest_makereport` 把每个用例结果写入 sqlite
- `pytest_sessionfinish` 更新执行状态为完成
- 平台读取 sqlite 即可展示最新结果

**新项目**：拷贝 conftest 的 hook 代码，替换 sqlite 表和字段名。
