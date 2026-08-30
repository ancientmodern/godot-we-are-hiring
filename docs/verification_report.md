# 《我们正在招人》候选构建验证记录

> 验证日期：2026-08-29  
> 构建类型：本地 Godot 开发构建（非导出发行包）  
> 项目入口：`project.godot` → `hiring_main.tscn`  
> 结论边界：最终制作源码的自动化、实际渲染、像素、资产、音频、动画与空闲稳定性预检通过；真人首次玩家验收尚未执行

> **候选证据已刷新：** 本报告只引用制作源码冻结后生成的 canonical 日志；失败或过期的中间日志不作为候选证明。

267 项要求的逐条状态、精确证据和完整性检查见 [`requirement_evidence_ledger.md`](requirement_evidence_ledger.md)。

## 1. 验证环境

- Godot `4.7.2.stable.steam.ed1daf0bf`
- Windows，Steam Godot 工具版
- 实际渲染捕获：OpenGL 3.3 Compatibility，NVIDIA GeForce RTX 4080 SUPER
- 视觉基准分辨率：1280 × 720
- 捕获时使用 `--audio-driver Dummy`，避免测试退出时把桌面音频设备生命周期误报为游戏资源泄漏；音频规则另由专用 headless 测试验证

## 2. 自动化回归

| 范围 | 结果 | 日志 |
|---|---:|---|
| 原子存档、备份恢复与路径防护 | 100 checks PASS | `artifacts/hiring_storage_test.stdout.log` |
| 内容注册表、文案、异常边界与可达性 | 2,795 checks PASS | `artifacts/hiring_content_test.stdout.log` |
| 经营模型、行动、员工、存档与结局 | 1,940 checks PASS | `artifacts/hiring_model_test.stdout.log` |
| 45 周导演编排、林越历史、可见行动池与分支 | 2,117 checks PASS | `artifacts/hiring_flow_test.stdout.log` |
| 自适应环境声、稀疏配乐、物理拟音与场景静音 | 275 checks PASS | `artifacts/hiring_audio_test.stdout.log` |
| 主界面场景混音接线、直接操作拟音与异常静音 | 84 checks PASS | `artifacts/hiring_audio_integration_test.stdout.log` |
| 真实 UI → 导演 → 存档/结局恢复与原子设计契约 | 622 checks PASS | `artifacts/hiring_ui_flow_test.stdout.log` |
| 夜班对象状态机 | 173 checks PASS | `artifacts/night_interaction_state_test.stdout.log` |
| 夜班 UI、键盘/手柄焦点、移动、物件视觉与终端接入 | 115 checks PASS | `artifacts/hiring_night_ui_integration_test.stdout.log` |
| 全玩家文本、AI 路线和模型发言语义审计 | 1,549 checks PASS | `artifacts/hiring_semantic_audit_test.stdout.log` |
| 焦点路由 | 19 checks PASS | `artifacts/hiring_focus_router_test.stdout.log` |
| 主界面手柄全流程与安全取消边界 | 76 checks PASS | `artifacts/hiring_gamepad_contract_test.stdout.log` |
| **功能/语义小计** | **9,865 checks PASS** | 十二份 canonical 功能/语义日志 |
| 运行时美术资产、透明通道、尺寸与授权闭包 | 364 checks PASS | `artifacts/hiring_art_asset_test.stdout.log` |
| **总计** | **10,229 checks PASS** | 上述功能/语义小计 + 美术资产回归 |

十三份 canonical 回归日志（十二份功能/语义日志 + 美术资产日志）、主场景 smoke 与视觉捕获日志均重新扫描：`SCRIPT ERROR`、行首 `ERROR:` / `WARNING:`、orphan、RID/ObjectDB leak 命中数为 0；所有配对 stderr 为 0 bytes。UI、音频集成、手柄、夜班 UI 与视觉捕获使用进程唯一 `user://` 路径，smoke 使用 GUID 路径；均不读取或覆盖玩家正式 campaign/meta 文件。

## 3. 主场景与实际渲染

- 主场景 headless smoke exit 0，精确输出 `HIRING_MAIN_SMOKE_PASS: isolated storage, scene initialized, onboarding rendered`；日志 `artifacts/main_smoke.stdout.log`，stderr 为空。
- 实际桌面渲染器完成 **81 张、81 个唯一路径**的 1280×720 场景捕获，精确输出 `HIRING_VISUAL_CAPTURE_PASS: 81 captures`；日志 `artifacts/visual_capture_final.stdout.log`，stderr 为空。捕获器以 81 个显式 stem 为唯一清单，捕获前后归档根目录中的非清单 PNG，并在结束前验证根目录与本次捕获集合均与清单完全相等。
- 像素契约本次复跑通过：`option_glyph_pixels=2721`、`extra_floor_pixels=1790`、社交心形三阶段 `[64, 662, 64]`、`capture_root_pngs=81`、`outside_contract_pixels=0`、`floor_theme_samples=21`；根截图目录若出现任一额外 PNG 即失败。`artifacts/ui_visual_contract.log` 保存本次 canonical 像素差分基线。
- `assets/hiring_assets.json` 当前登记 **20 个受管资源、77,523,531 bytes**；`artifacts/hiring_art_asset_test.stdout.log` 的 364 checks PASS 证明受管资源文件头、尺寸、透明通道、授权、SHA-256 与运行时加载闭包，并覆盖原创插画、三档绿萝状态、应用图标、Noto Sans SC 与 Noto Serif SC 字体。
- 81 张清单捕获覆盖 onboarding、低人数/成熟办公室、设置/降低动态、行动资源门槛、长文/名单/公告分页、林越两段剧情内约两分钟（桌面演出各 10 秒）的静默、董事会、无脸会议录像、裁员社交心形、三杯工位、债的三档环境变化、两个夜班、Room D 三阶段、异常日历/工位/内网、NG+ 与七结局。2026-08-29 证据卫生复核将根目录中 3 张非清单旧原型截图 `intranet_finale.png`、`team_finale_window.png`、`night_shift.png` 移入 `artifacts/screenshots/archive/non_manifest/`；archive 仅用于可恢复追溯，不属于 V81 候选证据。

候选截图根目录：[`../artifacts/screenshots`](../artifacts/screenshots)（只读取根目录 81 张 PNG；`archive/` 不计入候选证据）

## 4. 动画、空闲与音频运行证据

- 签字动画使用 Godot Movie Maker 以 1280×720、固定 60 fps 录制：97 帧、1.6167 秒，exit 0；测试精确输出 90-frame timeline PASS。产物 `artifacts/signature_motion.avi`，日志 `artifacts/signature_motion.stdout.log`，SHA-256 `15EC3345D67611209051787A2AA784F3586B914FBAF7E9A754B9BA86D43FE96A`。
- 夜班一在无任何输入下以固定 1 fps 录制 310 帧、5 分 10 秒；核心模型、夜班交互、位置、目标与结果文本在第 0/300 个空闲帧深比较完全相同。产物 `artifacts/night_idle_5min.avi`，日志 `artifacts/night_idle_5min.stdout.log`，SHA-256 `858FE91239E39684255B27B9D4BD3EF677E2A9A7B61B4167BA6666004993F2B0`。
- 生产 `OfficeAudio` 实例导出 45 个 WAV：7 个连续 stem（5 个 12 秒 ambience + 2 个 48 秒稀疏 score）、13 个非循环物理拟音，以及 5 章、13 个叙事场景、7 个结局的 25 个诊断混音 reference。全部为 RIFF/WAVE、mono PCM16、22,050 Hz；两个刻意静音场景保持零信号，其余文件均有信号。manifest 引用无缺失/孤儿，七个结局得到七个不同 SHA-256，异常上下文自动拟音增量为 0。生成日志为 `artifacts/audio_evidence_generation.stdout.log`，复核日志为 `artifacts/audio_evidence_validation.log`，generation stderr 为 0 bytes；manifest SHA-256 `0ADF16FEB36FA39A6C38FB863BB7F951D6FCDEF03A9F88E1341BDDD91F51A1A0`。
- `artifacts/audio_evidence/spectrum.csv` 对 Ambience/Music bus 上的 7 个连续 stem 在 40–6,400 Hz 共 11 个频点记录 77 行 Goertzel 幅度、RMS 和 4 秒分析窗；score 分析窗从首个稀疏乐句开始。`manifest.json` 另记录 Foley bus、非循环标志、音量、章节阈值、场景静音、Night 1 HVAC-only、`rm_rf` 风扇停转和完整目标 dB。

## 5. 候选闭包与需求拓扑

- `artifacts/requirement_topology.log` 精确证明 267 项要求无 missing/extra/duplicate：`Verified=250`、`Partial=9`、`Unverified=8`。
- `tests/generate_candidate_manifest.py` 在本文档与台账定稿后最后运行；`artifacts/candidate_manifest.json` 与 `artifacts/candidate_manifest_generation.log` 是发行候选的权威文件清单和合并哈希，避免文档变更反向使清单过期。
- `artifacts/testlogs/art_refresh/` 等失败或中间尝试明确排除在候选证据之外。

## 6. 成熟内容边界

生产内容与首屏提示已覆盖裁员、倦怠、饮酒、融资/组织权力和作者性冲突。“成人向”在本项目中指成熟职场与伦理主题；当前构建不包含裸露、明确性行为、色情内容或写实暴力，也尚未获得任何地区的正式年龄评级。

## 7. 尚未关闭的证据门槛

`DEC-011`、`TONE-002`、`FUND-002` 与 `ACCEPT-001`–`ACCEPT-005` 仍为 **Unverified**；另有 9 项只因首次玩家体验/发现率/延迟回想而保持 **Partial**。自动测试、截图和开发者检查不能回答玩家是否自然理解债、是否第二次主动委托、是否以 15%–30% 的比例发现第三章文字变化、是否想挽回林越，以及通关后是否联想到自己的工作经历。

下一步必须由真实首次玩家按 [`player_test_protocol.md`](player_test_protocol.md) 试玩并保留录像、行为日志与访谈原话。首次玩家开始前只应阅读 README 的“运行”“操作”和“内容提示”，不要阅读创意圣经或本报告的剧透内容。
