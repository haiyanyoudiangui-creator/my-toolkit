# pytest + allure

## pytest

Python 测试框架，负责组织和运行测试用例。

### 在 kaiboer 项目中的用法

#### 通过自定义 CLI 命令驱动测试

不直接跑测试文件，而是在终端用人类可读的方式选择用例：

```
pytest type 'run' id 'first_boot'
```

CLI 会把 `type`、`id` 翻译成对应的 pytest nodeid，从 `automation.yaml` 里找到要跑的用例集合。

#### 用 fixtures 管理设备生命周期

- 整个测试会话共用一份 YAML 配置文件（设备序列号、WiFi、应用下载地址等）
- 每个用例自动获取已连接的设备对象，用例结束时释放
- 需要恢复出厂时有一个专门的 fixture，自动执行出厂重置并等待设备重新上线

#### 用标记系统分类用例

定义了 9 个自定义 mark，按功能模块分类：

- `guide` — 开机引导
- `wifi` — WiFi 连接
- `home` — 主页
- `launcher` — Launcher
- `app_install` — 应用安装
- `file_manager` — 文件管理
- `ui_dump` — UI 全量采集
- `audio` — 本地音频播放

#### 用 conftest hooks 控制用例执行

- **用 YAML 计划过滤用例**：收集到的所有用例会和 `automation.yaml` 里的计划对比，只保留计划覆盖的用例，并保持文件定义顺序
- **失败即时中断**：开启 stop-on-failure 后，一个用例失败就跳过剩余用例
- **自动生成失败汇总**：测试结束后打印清晰的失败报告，并保存到文件，方便快速定位

---

## allure-pytest

Allure 测试报告工具，把运行结果渲染成可交互的 HTML 报告。

### 在 kaiboer 项目中的用法

#### 按 feature/story 分层组织报告

报告按功能模块分层展示：

- **feature 层**（开机引导 / WiFi / UI Full Dump / 音频播放等）
- **story 层**（跳过引导 / 下载吞吐量 / 文件管理页面采集等）

可以快速按模块展开/折叠，只看关心的部分。

#### 关键步骤包裹在 step 里

每个重要操作都打 step 标签，报告里能看到每一步的耗时和结果，比如：

- "模拟用户点击完成开机引导"
- "连接指定 WiFi"
- "下载并验证 App: xxx"

#### 诊断信息作为附件嵌入

- WiFi 连接日志、UI 完成引导的诊断摘要、应用下载结果等关键文本，作为 TEXT 附件贴在对应步骤下
- 失败时的 XML 页面状态也附在报告里，直接可看当时界面

---

## 报告生成命令

```bash
pytest --alluredir=./allure-results
allure serve ./allure-results
```
