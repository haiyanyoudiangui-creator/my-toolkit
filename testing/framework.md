# pytest + allure

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## pytest

> 💡 Python 测试框架，负责组织和运行测试用例。

───

### 在 kaiboer 项目中的用法

#### 📋 通过自定义 CLI 命令驱动测试

不直接跑测试文件，而是在终端用人类可读的方式选择用例：

```bash
pytest type 'run' id 'first_boot'
```

CLI 会把 **type**、**id** 翻译成对应的 pytest nodeid，从 **automation.yaml** 里找到要跑的用例集合。

#### 📋 用 fixtures 管理设备生命周期

| 级别 | 作用 |
|------|------|
| **session** | 整个测试会话共用一份 YAML 配置文件（设备序列号、WiFi、应用下载地址等） |
| **function** | 每个用例自动获取已连接的设备对象，用例结束时释放 |
| **专用** | 需要恢复出厂时有一个专门的 fixture，自动执行出厂重置并等待设备重新上线 |

#### 📋 用标记系统分类用例

定义了 **9 个自定义 mark**，按功能模块分类：

| 标记 | 模块 |
|------|------|
| `guide` | 开机引导 |
| `wifi` | WiFi 连接 |
| `home` | 主页 |
| `launcher` | Launcher |
| `app_install` | 应用安装 |
| `file_manager` | 文件管理 |
| `ui_dump` | UI 全量采集 |
| `audio` | 本地音频播放 |

#### 📋 用 conftest hooks 控制用例执行

| Hook | 作用 |
|------|------|
| `pytest_collection_modifyitems` | 用 YAML 计划过滤用例，只保留计划覆盖的，保持文件定义顺序 |
| `pytest_runtest_makereport` | 开启 stop-on-failure 后，一个用例失败就跳过剩余用例 |
| `pytest_terminal_summary` | 自动生成失败汇总：打印清晰的失败报告，保存到文件方便快速定位 |

───

## allure-pytest

> 💡 Allure 测试报告工具，把运行结果渲染成可交互的 HTML 报告。

───

### 在 kaiboer 项目中的用法

#### 📋 按 feature/story 分层组织报告

| 层级 | 内容示例 |
|------|---------|
| **feature 层** | 开机引导 / WiFi / UI Full Dump / 音频播放 |
| **story 层** | 跳过引导 / 下载吞吐量 / 文件管理页面采集 |

可以快速按模块**展开/折叠**，只看关心的部分。

#### 📋 关键步骤包裹在 step 里

每个重要操作都打 step 标签，报告里能看到**每一步的耗时和结果**：

- "模拟用户点击完成开机引导"
- "连接指定 WiFi"
- "下载并验证 App: xxx"

#### 📋 诊断信息作为附件嵌入

| 附件类型 | 内容 |
|---------|------|
| **TEXT** | WiFi 连接日志、UI 引导诊断摘要、应用下载结果 |
| **XML** | 失败时的页面 UI 层级状态 |

```bash
pytest --alluredir=./allure-results
allure serve ./allure-results
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔄 复用指南

### 1. YAML 驱动用例选择模式

> 💡 不直接跑文件名，用人类可读的 ID 映射到具体用例。

| 步骤 | 操作 |
|------|------|
| 1 | 创建 `automation.yaml`，定义 `automations`（用例名→nodeid 映射）和 `runs`/`plans`（用例分组） |
| 2 | 在 conftest 的 `pytest_collection_modifyitems` 里读取 YAML，按计划过滤和排运用例 |
| 3 | 用户只用 `pytest --case=smoke` 而不是 `pytest tests/test_xxx.py::TestXX::test_yy` |

| 需要改 | 不需要动 |
|---------|---------|
| YAML 里的 nodeid 路径、marker 名、分组逻辑 | conftest 的过滤框架、CLI 解析逻辑 |

### 2. conftest hooks 模板

> 💡 **pre**（拦截用例收集）+ **post**（汇总失败）= 零侵入自动化流水线。

| 可复用 hook | 新项目直接拷贝，替换 YAML 路径和 marker 映射表即可 |
|------------|--------------------------------------------------|
| `pytest_collection_modifyitems` | 按计划筛选/排运例 |
| `pytest_runtest_makereport` | 记录失败状态和附件路径 |
| `pytest_terminal_summary` | 打印格式化的失败汇总 |

### 3. Fixture 生命周期管理

> 💡 session 级放全局配置，function 级放资源对象（设备、连接等）。

```yaml
# config 文件里放：
device: { serial, ip, timeout }
wifi: { ssid, password }
apps: [{ name, url, package }]
```

**新项目**只需改 YAML，不改 fixture 代码。fixture 始终是「读取 YAML → 连接 → yield 对象 → 清理」这个模式。

### 4. Allure 报告组织

| 层级 | 填什么 |
|------|--------|
| **feature** | 产品的功能模块名（开机引导、WiFi、播放器…） |
| **story** | 具体的测试场景描述 |
| **step** | 包裹每一个对外部有影响的操作 |
| **attach** | 只放关键诊断文本/XML/截图，不放无关日志 |
