# 《我们正在招人》 / *We're Hiring*

> 开发归档：本文保留原 README 的完整测试命令与实现说明，包含大量剧透，不作为公开项目首页。

[English](README.md) | **简体中文**

一款以当代湾区 AI 创业公司为舞台的单机经营叙事游戏。你在雨夜桌面上的公司档案里分配每周注意力、训练模型、维持融资叙事、处理团队事件，也可以把工作交给越来越能干的内部模型；人物戏会离开档案，直接发生在办公室、咖啡馆和会议室。

这不是怪物收集或战斗游戏。当前版本是一套可从开局推进到结局的 Godot 4 开发构建，包含五章、45 个经营周、固定与动态事件、夜班场景、分支结局、自动存档和通关后的新周目开场。经营层现已包含具名竞品、真实 USD 账本与股权结构、投资人/政策项目、候选人招聘链、组织培养、办公室租装和 SaaS 采购；这些系统会在同一个周循环里相互影响。

> 首次试玩请只阅读本页的“运行”和“操作”部分。`we-are-hiring-creative-bible.md` 与 `docs/` 包含完整剧透，会破坏关键体验测试。

## 运行

需要 Godot 4.7 或兼容的 Godot 4.x 桌面版。Windows 用户可以直接双击 [`run_game.bat`](run_game.bat)；它会依次查找 `GODOT_EXE` 环境变量、常见 Steam 安装位置以及 PATH 中的 `godot4`/`godot`。

### 从 Godot 编辑器运行

1. 在 Steam 启动 **Godot Engine**。
2. 在项目管理器选择 **Import**，打开仓库根目录下的 `project.godot`。
3. 等待首次资源导入完成。
4. 按 **F5** 或右上角“运行项目”按钮启动主场景。

### 从 PowerShell 直接运行

```powershell
Set-Location '<path-to-this-repository>'
$GodotExe = '<path-to-godot-executable>'
& $GodotExe --path .
```

游戏会在本机 `user://` 目录自动保存进度；标题页出现“继续”后可恢复。存档不上传网络。

## 操作

鼠标、键盘与手柄均可完成主流程；键盘提供最快的直接快捷键。

| 场景 | 操作 |
|---|---|
| 通用 | 鼠标左键交互；`F1`/手柄 `Start` 打开设置与辅助；`F11` 切换全屏；`M` 开关全部声音；设置中可启用“降低动态效果” |
| 每周档案 | `↑/↓` 或 `W/S` 选择行动；`1`–`5` 快速选择；`Enter/Space` 亲自处理；`L` 让模型处理；`E` 结束本周。手柄为 D-pad / `A` / `X` / `Y` |
| 侧栏 | `T` 团队；反引号 `` ` `` 终端；`C` 日历；`A` 公告；`I` 内网；`Esc` 返回仪表盘 |
| 事件与选择 | `Enter/Space/E` 翻页；选项出现后按 `1`–`9` 选择；手柄用 D-pad 移动唯一焦点、`A` 确认。`B` 只关闭可逆覆盖层或返回工具页，不会替你选择或推进剧情 |
| 夜班 | 点击热点先移动，到达后交互；也可用方向键/WASD 或手柄 D-pad 选物件、`E`/`A` 交互；多步物件需再次操作；满足离开条件后按 `E`；夜班二终端聚焦后可按 `Ctrl+C`，或用手柄 `X` 执行同一中断；精确命令仍可键盘输入 |
| 结局 | `Enter/Space` 翻页或进入下一步 |

界面里的“亲自处理”和“让它来写”不是难度选项：它们是游戏最核心的取舍。首玩时建议按直觉选择，不要先查攻略。

## 内容提示

本作尚未获得任何地区的正式年龄评级。“成人向”指职场与伦理主题，而不是色情内容。游戏涉及：

- 融资压力、组织操控与失去掌控感；
- 裁员、离职、工作倦怠和公司失败；
- 轻度心理不安、身份/作者性的模糊；
- 简短饮酒提及，以及具有破坏意味的终端命令。

当前版本不包含裸露、明确性行为、色情内容或写实暴力。

## 开发检查

在 PowerShell 中运行：

```powershell
Set-Location '<path-to-this-repository>'
$GodotExe = '<path-to-godot-executable>'
$PythonExe = (Get-Command python).Source

# 原子保存、备份恢复、损坏诊断与路径隔离
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_storage_test.gd

# 章节、行动、事件、夜班对象、文档与结局内容注册表
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_content_test.gd

# 资源循环、员工状态、作者权重、存档与结局优先级
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_model_test.gd

# 45 周战役编排、事件唯一性、NG+ 与存档往返
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_flow_test.gd

# USD 账本、SAFE/priced round/cap table、竞品、投资人及政策项目
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_business_system_test.gd

# 具名候选人招聘链、组织、办公室、装修、SaaS 与人员成本
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_operations_system_test.gd

# 随机经营事件的 cooldown、pity、actor memory、materialized queue 与确定性存档
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_event_scheduler_test.gd

# 39 个经营事件、七个 family 与六张策略行动卡的内容契约
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_expansion_content_test.gd

# 招聘入职、期权、融资稀释、系统事件和嵌套存档的端到端纵向切片
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_expansion_integration_test.gd

# 场景环境声、稀疏 human/system 配乐、物理拟音、作者权重交叉淡化与静默契约
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_audio_test.gd

# 真实主界面音频接线：地点、静默页、第四章逐周退场、直接操作拟音与 anomaly 无提示
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_audio_integration_test.gd

# 手柄/键盘共用的唯一焦点、2x2 选项网格与跨页面焦点恢复
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_focus_router_test.gd

# 真实主界面手柄回放：开局、周循环、事件、设置、夜班终端与安全取消
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_gamepad_contract_test.gd

# UI → 导演层 → 存档 → 延迟事件 → 夜班 → 下一章的公开流程
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_ui_flow_test.gd

# UI 阅读面、控件互斥、安全边距与小字/禁用态颜色对比
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_ui_readability_contract_test.gd

# 夜班一/二对象的多步状态、越级拒绝与中途存档
& $GodotExe --headless --path . --quit-after 5000 --script tests/night_interaction_state_test.gd

# 夜班状态机接入真实 UI、移动、终端焦点与存档恢复
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_night_ui_integration_test.gd

# 对全部玩家可见语料、AI 效用、异常行政表面和歧义词做封闭清单审计
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_semantic_audit_test.gd

# 267 项需求与逐条证据账本保持唯一、一一对应、同序
& $PythonExe tests/verify_requirement_topology.py

# 美术、字体与许可证的精确闭包、SHA-256、尺寸、透明通道和文件类型
& $PythonExe tests/verify_hiring_assets.py

# Godot 导入后逐项绕过缓存加载纹理与字体，并核对尺寸、透明通道和中文字符
& $GodotExe --headless --path . --quit-after 5000 --script tests/hiring_art_asset_test.gd

# 冻结清单驱动的运行依赖与完整源码/测试/文档 SHA-256
& $PythonExe tests/generate_candidate_manifest.py

# 主项目解析与短烟雾测试；GUID 路径会在读取 meta 前归一化并拒绝正式档案别名
$SmokeId = [guid]::NewGuid().ToString('N')
& $GodotExe --headless --path . --quit-after 120 -- `
  -- `
  "--hiring-save-path=user://we_are_hiring_smoke_$SmokeId.json" `
  "--hiring-meta-path=user://we_are_hiring_smoke_meta_$SmokeId.json" `
  --hiring-smoke-test
```

`--quit-after` 只是防止失败时无限运行的上限，不代表成功。上述每条 Godot 命令还必须退出码为 0、打印对应的 `*_PASS` 标记，并且日志中没有 `SCRIPT ERROR`、`ERROR`、`WARNING` 或资源泄漏；主场景烟雾测试的精确成功标记是 `HIRING_MAIN_SMOKE_PASS: isolated storage, scene initialized, onboarding rendered`。

视觉捕获需要实际渲染器，不能使用 `--headless`：

```powershell
& $GodotExe --audio-driver Dummy --path . --resolution 1280x720 --quit-after 5000 --script tests/hiring_visual_capture.gd
& $PythonExe tests/verify_ui_visual_contract.py
```

截图会写入 `artifacts/screenshots/`；捕获成功必须同时具备 81 条 `CAPTURED:`、81 个唯一输出路径和 `HIRING_VISUAL_CAPTURE_PASS: 81 captures`，不能用目录内 PNG 总数代替。像素核验除证明阶段三只改选项文字、电梯异常按钮复用普通主题、裁员社交状态产生局部动画外，还会验证 Dashboard/Team 的 38 个实体阅读面采样、14 个侧栏遮盖采样、7 个精确面板边界，以及设置遮罩对底层亮度、高光和纹理的衰减。

需要生成可听/可复核证据时：

```powershell
# ambience、稀疏 score、物理 one-shot 与关键叙事场景混音证据
& $GodotExe --headless --path . --script tests/hiring_audio_evidence.gd
& .\tests\verify_audio_evidence.ps1

# 真实 60 fps 签字动画；外层 quit-after 是防止失败时无限写盘的第二道保险
& $GodotExe --path . --resolution 1280x720 --audio-driver Dummy `
  --write-movie artifacts/signature_motion.avi --fixed-fps 60 --disable-vsync `
  --quit-after 180 --script tests/hiring_signature_motion_capture.gd

# 五分钟无输入夜班证据，以 1 fps 时间线录制 300 秒并深比较状态
& $GodotExe --path . --resolution 1280x720 --audio-driver Dummy `
  --write-movie artifacts/night_idle_5min.avi --fixed-fps 1 --disable-vsync `
  --quit-after 420 --script tests/hiring_night_idle_capture.gd
```

音频产物写入 `artifacts/audio_evidence/`；两段 AVI、生成日志和 SHA-256 验证记录写入 `artifacts/`。

## 验收状态

自动测试只能证明规则和内容可运行，不能证明叙事体验成立。创意圣经规定的五项首次玩家验收目前仍然**未验证**；发布前须按 [`docs/player_test_protocol.md`](docs/player_test_protocol.md) 收集真人首玩录像、行为日志和访谈原话。

项目的公司经营系统设计与实现边界见 [`docs/company_systems_design.md`](docs/company_systems_design.md)，完整需求追踪见 [`docs/requirements_matrix.md`](docs/requirements_matrix.md)，267 项逐条状态与证据见 [`docs/requirement_evidence_ledger.md`](docs/requirement_evidence_ledger.md)，已裁决的产品口径见 [`docs/product_decisions.md`](docs/product_decisions.md)，视觉系统与原创资产边界见 [`docs/art_direction.md`](docs/art_direction.md)，内部叙事签核见 [`docs/editorial_review.md`](docs/editorial_review.md)，原候选构建的机器验证记录见 [`docs/verification_report.md`](docs/verification_report.md)。

## 项目定位

《我们正在招人》的角色、公司、文本、系统、视觉与程序化声音均为本项目原创。它是一款以实体公司档案、真实场景与少量叙事软件界面构成的经营游戏，不使用或仿制任何现有游戏的角色、名称、布局、图标、音乐或素材。

## 源码与资产

仓库使用 Git LFS 管理 PNG、字体以及未来可能加入的音频/录像资源。克隆后请运行 `git lfs install` 与 `git lfs pull`，再由 Godot 完成首次导入。`.godot/`、`artifacts/`、本地导出包和测试日志均为可再生成内容，不进入版本历史。

两款 Noto SC 字体分别附带 OFL 1.1 许可证。项目代码、文本与原创美术的开源许可证尚未确定；在根目录加入正式 `LICENSE` 之前，公开可见不等同于获得复制、修改或再分发授权。
