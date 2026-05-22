# pytest 实战复盘：把测试框架做成 Android 真机自动化流水线

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

这篇不是 pytest API 手册，而是 kaiboer 项目里一次真实落地后的复盘。

项目的目标不是“能跑几个测试函数”，而是让测试人员可以用一条稳定命令驱动 Android 真机：

```bash
pytest type 'run' id 'local_audio_playback'
```

背后真正做的事是：读取 YAML 注册表、展开 case/run/plan、按业务顺序收集 pytest nodeid、连接 ADB 真机、执行 uiautomator2 操作、保存 Allure 附件、写入用例平台执行记录，并在失败时生成一份能直接发给 Codex 排查的摘要。

> [!IMPORTANT]
> 核心经验：把 pytest 当成“执行引擎”，把 YAML 当成“用例入口”，把 hook 当成“流水线控制点”，把 Allure 和本地 artifacts 当成“证据仓库”。

## 为什么不用文件名直接跑

早期最直接的方式是：

```bash
pytest tests/test_skip_guide.py::TestSkipGuide::test_skip_guide
```

这对开发者可以接受，但对日常测试不友好：

- nodeid 太长，容易输错。
- 一个业务流程通常由多个 pytest 用例组成。
- smoke、stress、full regression 需要不同组合。
- 真机测试失败后，需要保留执行顺序、设备状态和诊断证据。

所以项目把命令改成业务语义：

```bash
pytest type 'case' id 'file_manager_full_ui_dump' xml true
pytest type 'run' id 'launcher_home'
pytest type 'plan' id 'smoke_regression'
```

测试人员关心的是“跑哪个场景”，不是“哪个 Python 文件里的哪个函数”。

## 这条命令实际经过了什么

以这条命令为例：

```bash
pytest type 'plan' id 'smoke_regression'
```

执行链路如下：

1. `utils/automation_cli.py` 在 pytest 初始化前识别友好参数。
2. `type 'plan' id 'smoke_regression'` 被改写成隐藏参数 `--automation-type=plan --automation-id=smoke_regression`。
3. `tests/conftest.py` 读取 `config/automation.yaml`。
4. `plan` 展开成多个 `run`，`run` 再展开成多个 `case`。
5. 每个 `case` 通过注册表找到真实 pytest nodeid。
6. `pytest_collection_modifyitems` 过滤掉无关测试，只保留计划内用例。
7. 保留下来的用例按 YAML 顺序排序，保证执行顺序和业务流程一致。
8. fixture 创建设备连接，优先使用 USB serial，必要时按配置 fallback 到网络 ADB。
9. 用例执行时通过 Allure step/attach 保存关键证据。
10. `pytest_runtest_makereport` 和 `pytest_terminal_summary` 收集失败、UI trace、平台结果和摘要文件。

也就是说，pytest 仍然负责收集、执行、断言和报告，但业务入口已经从“测试函数”升级成了“自动化任务”。

## YAML 注册表是唯一入口

项目的任务定义集中在 `config/automation.yaml`：

- `automations`：单个自动化任务，绑定一个 pytest nodeid。
- `runs`：一组 automation，按配置顺序执行。
- `plans`：一组 run，适合日常回归、长耗时专项或完整回归。

例如当前项目已经拆出了这些层次：

```bash
pytest type 'case'
pytest type 'run'
pytest type 'plan'
```

常用计划包括：

- `smoke_regression`：日常功能 Smoke，覆盖首启、Launcher、输入输出、应用页和本地播放。
- `stress_regression`：长耗时 Stress，覆盖网络吞吐量和应用批量场景。
- `full_regression`：完整回归，把 Smoke 和 Stress 串起来。

这个设计最有价值的地方是：新增业务场景时，不需要教测试人员背 nodeid，只需要把新用例注册成一个有意义的 ID。

## case / run / plan 怎么拆

实战里我按“失败影响面”拆层级。

**case：最小可诊断单元**

一个 case 应该能独立说明一个问题，比如：

- `first_boot_setup`：恢复出厂后跳过引导并连接 WiFi。
- `home_launcher_audit`：dump Launcher 首页元素并检查遗漏。
- `file_manager_full_ui_dump`：按 APK/模块/页面分级保存文件管理 UI。
- `kbeplayer_folder_direct_playback`：用 ADB 直连 KBEPlayer 验证本地音频播放。

**run：业务流程组合**

run 适合表达一个功能域，例如：

- `launcher_home` = 首页元素审查 + 首页入口点击 Smoke。
- `local_audio_playback` = 文件管理器入口 Smoke + KBEPlayer 底层直连播放。
- `file_manager` = 音频目录 DFS 遍历 + 全页面元素 dump。

**plan：执行策略**

plan 适合表达“今天要跑什么”：

- 日常就跑 `smoke_regression`。
- 夜间或专项跑 `stress_regression`。
- 版本候选跑 `full_regression`。

> [!TIP]
> case 按诊断粒度拆，run 按功能域组合，plan 按执行策略编排。这样失败时既能快速定位，也能让执行入口保持简单。

## hook 才是 pytest 的实战价值

这个项目里 pytest 最重要的不是 `assert`，而是 hooks。

**`pytest_load_initial_conftests`**

在 pytest 真正解析参数前，把友好命令改写成隐藏参数：

```bash
pytest type 'run' id 'first_boot'
```

这样命令短，但内部仍然走 pytest 标准 option。

**`pytest_collection_modifyitems`**

按 YAML 展开的 nodeid 过滤测试集合，并重新排序。它解决的是“只跑我要的业务组合”。

**`pytest_runtest_makereport`**

每个阶段生成 report 后，把失败信息、UI trace 路径、Allure 结果和平台绑定信息挂进去。它解决的是“失败后证据不要丢”。

**`pytest_terminal_summary`**

测试结束后打印关键失败摘要，并写入：

```text
artifacts/failure_summaries/last_failure_summary.txt
```

这个文件很适合直接复制给 Codex 或同事排查，因为里面已经包含 nodeid、失败阶段、位置、原因、trace 尾部和 UI trace 路径。

## 真机自动化的重点不是点击，而是恢复现场

Android 真机测试最容易出问题的地方不是脚本语法，而是设备状态：

- ADB 是否在线。
- 当前前台应用是不是预期应用。
- 页面有没有加载稳定。
- 点击后是否跳到了系统弹窗、安装器或别的 App。
- 失败时有没有 UI XML、截图、logcat、dumpsys 证据。

所以项目把设备生命周期放进 fixture：

- `config` fixture 读取 `config/device.yaml`。
- `device` fixture 负责 USB serial 优先连接，必要时网络 ADB fallback。
- `reset_device` fixture 负责恢复出厂、等待 ADB 回来、等待 boot completed。

用例内部只关心业务动作，设备连接、失败上下文和清理动作由公共层处理。

## 日志要短，证据要全

真机自动化很容易把终端刷成一大团 XML、logcat、curl 输出。后期维护时，这种日志基本不可读。

kaiboer 项目采用的约定是：

- 终端实时日志一行只写一个动作或结果。
- 长 URL、长字典、多行诊断用 `utils/log_style.py` 压缩。
- 完整 UI XML、元素表、logcat、截图放 Allure 附件。
- 失败时终端只展示关键摘要，并写入 `last_failure_summary.txt`。

失败信息也尽量写成人能直接理解的格式：

```text
用例失败：连接 Android 设备
原因：配置的设备当前不在线，无法创建 uiautomator2 连接。
建议：确认 USB 线已连接、设备已开机并授权 ADB。
关键上下文：
- 配置 USB serial: ...
- adb devices -l stdout: ...
```

这比单纯抛一个 `AssertionError` 更适合现场排查。

## UI trace 是给未来的自己留路

文件管理和本地音频这些场景里，页面状态变化很复杂。只看失败行通常不够，需要知道“脚本点过哪些页面、每一步看到哪些元素”。

项目里的 UI trace 会把关键页面保存到 artifacts：

```text
artifacts/ui_xml_traces/<timestamp>_<case_id>/
artifacts/ui_full_dumps/<timestamp>_file_manager_full_ui_dump/
```

其中 `file_manager_full_ui_dump` 会进一步按层级保存：

```text
artifacts/ui_full_dumps/<timestamp>_file_manager_full_ui_dump/
  manifest.json
  indexes/pages.jsonl
  indexes/elements.csv
  indexes/edges.jsonl
  com.kaiboer.android.files/01_home/001_files_home/
```

这类证据的价值不只是在失败时排查，也能反过来补齐定位器、发现页面入口、建立 UI 覆盖地图。

## 和用例平台打通

`utils/case_platform/pytest_integration.py` 做了一个很实用的折中：平台记录是自动的，但不能影响 pytest 执行。

它在会话开始时：

- 初始化 SQLite。
- 同步 Excel 正式用例。
- 同步 YAML 自动化注册表。
- 创建一次 execution。
- 保存设备快照。

每个用例 report 生成时：

- 根据 nodeid 找到 automation id 和 case id。
- 写入状态、阶段、耗时、失败消息、trace 路径和 Allure 目录。
- 如果平台写入失败，只打 warning，不中断测试执行。

这条原则很重要：测试执行是主链路，平台记录是旁路。旁路失败不能让主链路变红。

## 实战命令清单

列出所有可执行任务：

```bash
pytest type 'case'
pytest type 'run'
pytest type 'plan'
```

跑日常 Smoke：

```bash
pytest type 'plan' id 'smoke_regression'
```

跑单个文件管理全量 dump：

```bash
pytest type 'case' id 'file_manager_full_ui_dump' xml true
```

跑本地音频播放链路：

```bash
pytest type 'run' id 'local_audio_playback'
```

生成 Allure 结果：

```bash
pytest type 'plan' id 'smoke_regression' --alluredir=./allure-results
allure serve ./allure-results
```

失败后优先看：

```text
artifacts/failure_summaries/last_failure_summary.txt
```

## 新项目怎么复用这套模式

如果要迁移到另一个项目，我会优先复用这些东西：

1. 保留 `automation.yaml` 的 `automations / runs / plans` 三层结构。
2. 保留友好 CLI，把 `type/id/detail/xml` 翻译成 pytest option。
3. 保留 `pytest_collection_modifyitems` 的过滤和排序逻辑。
4. 保留 `pytest_terminal_summary` 的失败摘要文件。
5. 保留“终端短日志 + Allure 完整附件 + artifacts 原始证据”的分工。

需要按项目替换的是：

- YAML 里的 nodeid、模块名、tags、预期结果。
- device fixture 的连接方式。
- UI trace 的保存内容和目录结构。
- 平台写入逻辑，如果没有平台，可以先只保留本地摘要。

## 最后的经验

pytest 本身很轻，但它的 hook、fixture、collection 机制足够把一个普通测试项目搭成自动化流水线。

这次 kaiboer 项目里真正有用的不是某个单独技巧，而是几个原则连起来：

- 对人暴露业务 ID，对 pytest 保留 nodeid。
- 对 YAML 维护执行编排，对代码维护测试动作。
- 对终端输出短结论，对 artifacts 保存完整证据。
- 对 smoke 追求快，对 stress 接受慢。
- 对平台写入保持旁路，不能反过来拖垮测试执行。

这套结构跑起来以后，pytest 就不只是测试框架了，它变成了 Android 真机自动化的调度入口。
