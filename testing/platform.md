# 测试平台 & 配置

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## fastapi + uvicorn

Python Web 框架，快速搭建测试用例管理平台。

> [!IMPORTANT]
> 不是重型系统，几百行代码搭一个够用的本地方案。浏览器打开即用，本地运行无需部署。

### 在 kaiboer 项目中的用法

- **用例管理**：470 条测试用例的增删改查、按模块/标签筛选/搜索
- **执行记录**：每次运行的结果、耗时、失败原因和设备信息
- **失败统计**：按模块和类型自动分类统计
- **手动录入**：支持手动录入结果和标记状态（通过/失败/阻塞/跳过）
- **计划模板**：保存常用用例组合，一键切换测试范围

───

## sqlite3

嵌入式本地数据库，无需安装服务端。

### 在 kaiboer 项目中的用法

- 测试用例表：从 Excel 导入的 470 条用例（ID、标题、步骤、预期结果）
- 执行记录表：每次运行的耗时、失败原因
- 设备快照表：型号、系统版本、IP
- 用例绑定表：用例 ID ↔ pytest nodeid 的映射关系

数据库文件保存在 artifacts 目录，**零配置**。

───

## pyyaml

Python 解析 YAML 配置文件的库。

> [!IMPORTANT]
> 运行时配置（设备/WiFi/APP）和测试计划（用例列表/分组）分开两份 YAML。

### 在 kaiboer 项目中的用法

- **device.yaml**：设备序列号、WiFi 信息、应用下载地址、UI 遍历参数、音频配置——一份文件包含全部运行时配置
- **automation.yaml**：人类可读的 ID 映射到 pytest nodeid，支持 run（一组用例）和 plan（多组 run 组合），按需灵活切换

───

## httpx

Python HTTP 客户端库（类似 requests，支持异步）。

### 在 kaiboer 项目中的用法

用 FastAPI 的 TestClient（底层是 httpx）写平台接口的单元测试。验证 API 返回的状态码和数据结构。不需要启动真实服务即可跑通。

───

## Excel 导入

用 Python 原生 zipfile + xml.etree 解析 XLSX，**不依赖第三方库**。

### 在 kaiboer 项目中的用法

1. `zipfile.ZipFile()` 打开 xlsx
2. 读取 `xl/sharedStrings.xml` 获取所有文本
3. 遍历 `xl/worksheets/sheet*.xml` 逐表解析
4. 通过 sharedStrings 索引还原为实际文本
5. 按模块分组写入 sqlite

原始文档 8 个工作表、470 条用例。平台刷新后用例库即可更新。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 复用指南

### 1. FastAPI + sqlite3 平台模板

> [!TIP]
> AREST 接口定义 → sqlite 存储 → 页面渲染 → uvicorn 启动 → conftest hooks 集成。**拷贝代码，换表结构和字段名**。

### 2. YAML 配置分离

```yaml
# device.yaml — 运行时配置
device: { serial, ip, adb_timeout }
wifi: { ssid, password, timeout }
apps: [{ name, url, package, launch_seconds }]
audio: { scan_roots, sample_count }

# automation.yaml — 测试计划
automations:
  first_boot:
    nodeid: "tests/test_skip_guide.py::TestSkipGuide::test_skip_guide"
runs:
  smoke: { cases: [first_boot, launcher_home] }
plans:
  full: { runs: [smoke, network, audio] }
```

新项目只需改 YAML 值，解析代码不变。

### 3. Excel 零依赖解析

> [!TIP]
> XLSX 本质是 ZIP 包，原生 zipfile + xml 即可解析，不需要 openpyxl。流程完全复用，只换文件名和工作表名。

### 4. pytest 集成模式

> [!TIP]
> 平台不依赖手动录入，pytest 跑完自动入库。

- `pytest_sessionstart` → 创建执行记录
- `pytest_runtest_makereport` → 每个用例结果写入 sqlite
- `pytest_sessionfinish` → 更新执行状态为完成

拷贝 hook 代码，替换 sqlite 表和字段名。
