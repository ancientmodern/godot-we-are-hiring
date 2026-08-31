# 《我们正在招人》最终需求证据台账

审计基线：`docs/requirements_matrix.md`（2026-08-29 工作区版本）。本表只评价当前工作区可证明的事实；`Verified` 不替代策划明确要求的首次玩家研究。

> **候选证据已刷新：** 下列回归、87 条唯一捕获、像素契约、音频、动画和五分钟空闲证据均在最终制作源码冻结后重新生成；只有首次玩家研究仍在本表中保持 `Unverified`。

## 证据索引

| 代号 | 精确证据 |
|---|---|
| STORAGE | `tests/hiring_storage_test.gd`；`artifacts/hiring_storage_test.stdout.log`：`HIRING_STORAGE_TESTS_PASS: 100 checks` — 原子保存、备份恢复、损坏诊断与路径隔离 |
| MODEL | `tests/hiring_model_test.gd`；`artifacts/hiring_model_test.stdout.log`：`HIRING_MODEL_TESTS_PASS: 1940 checks` — 资源循环、员工状态、作者权重、存档与结局优先级 |
| CONTENT | `tests/hiring_content_test.gd`；`artifacts/hiring_content_test.stdout.log`：`HIRING_CONTENT_TESTS_PASS: 2926 checks` — 章节、行动、事件、夜班对象、文档与结局内容注册表 |
| FLOW | `tests/hiring_flow_test.gd`；`artifacts/hiring_flow_test.stdout.log`：`HIRING_FLOW_TESTS_PASS: 2074 checks` — 45 周战役编排、事件唯一性、NG+ 与存档往返 |
| UIFLOW | `tests/hiring_ui_flow_test.gd`；`artifacts/hiring_ui_flow_test.stdout.log`：`HIRING_UI_FLOW_TESTS_PASS: 630 checks` — UI → 导演层 → 存档 → 延迟事件 → 夜班 → 下一章的公开流程 |
| READABILITY | `tests/hiring_ui_readability_contract_test.gd`；`artifacts/hiring_ui_readability_contract_test.stdout.log`：`HIRING_UI_READABILITY_CONTRACT_PASS: 63 checks` — UI 阅读面、控件互斥、安全边距与小字/禁用态颜色对比 |
| NIGHTSTATE | `tests/night_interaction_state_test.gd`；`artifacts/night_interaction_state_test.stdout.log`：`NIGHT_INTERACTION_STATE_TESTS_PASS: 173 checks` — 夜班一/二对象的多步状态、越级拒绝与中途存档 |
| NIGHTUI | `tests/hiring_night_ui_integration_test.gd`；`artifacts/hiring_night_ui_integration_test.stdout.log`：`HIRING_NIGHT_UI_INTEGRATION_TESTS_PASS: 115 checks` — 夜班状态机接入真实 UI、移动、终端焦点与存档恢复 |
| AUDIO | `tests/hiring_audio_test.gd`；`artifacts/hiring_audio_test.stdout.log`：`HIRING_AUDIO_TESTS_PASS: 297 checks` — 场景环境声、稀疏配乐、物理拟音、作者权重交叉淡化与静默契约 |
| AUDIOUI | `tests/hiring_audio_integration_test.gd`；`artifacts/hiring_audio_integration_test.stdout.log`：`HIRING_AUDIO_INTEGRATION_TESTS_PASS: 97 checks` — 真实主界面音频接线：地点、静默页、逐周退场与异常无提示 |
| SEMANTIC | `tests/hiring_semantic_audit_test.gd`；`artifacts/hiring_semantic_audit_test.stdout.log`：`HIRING_SEMANTIC_AUDIT_PASS: 1551 checks` — 全部玩家可见语料、AI 效用、异常行政表面与歧义词的封闭清单审计 |
| EDITORIAL | `tests/hiring_editorial_test.gd`；`artifacts/hiring_editorial_test.stdout.log`：`HIRING_EDITORIAL_TESTS_PASS: 91 checks` — 引号约定、语气上限、行动描述不复述数值面板、每个开场节拍在其纸面内 |
| FOCUS | `tests/hiring_focus_router_test.gd`；`artifacts/hiring_focus_router_test.stdout.log`：`HIRING_FOCUS_ROUTER_TESTS_PASS: 19 checks` — 手柄/键盘共用的唯一焦点、2x2 选项网格与跨页面焦点恢复 |
| GAMEPAD | `tests/hiring_gamepad_contract_test.gd`；`artifacts/hiring_gamepad_contract_test.stdout.log`：`HIRING_GAMEPAD_CONTRACT_TESTS_PASS: 81 checks` — 真实主界面手柄回放：出身页、周循环、事件、设置、夜班终端与安全取消 |
| OPENING | `tests/hiring_opening_experience_test.gd`；`artifacts/hiring_opening_experience_test.stdout.log`：`HIRING_OPENING_EXPERIENCE_TESTS_PASS: 38 checks` — 车库开场的三段回应、关系维度分别记账与确认式跳过 |
| ORIGIN | `tests/hiring_origin_test.gd`；`artifacts/hiring_origin_test.stdout.log`：`HIRING_ORIGIN_TESTS_PASS: 252 checks` — 三条出身的等长序章、共有内容改写、永久规则与选项代价 |
| SOAK | `tests/hiring_origin_soak_test.gd`；`artifacts/hiring_origin_soak_test.stdout.log`：`HIRING_ORIGIN_SOAK_PASS: 30 checks` — 三条出身各跑一遍完整战役：出身页 → 序章 → 车库 → 周循环 → 结局，无卡死 |
| ART | `tests/hiring_art_asset_test.gd`；`artifacts/hiring_art_asset_test.stdout.log`：`HIRING_ART_ASSET_TESTS_PASS: 364 checks` — Godot 导入后逐项绕过缓存加载纹理与字体，并核对尺寸、透明通道和中文字符 |
| ASSET | `assets/hiring_assets.json`：20 个受管资产、77,523,531 bytes；ART 验证运行时文件头、尺寸、透明通道、授权、哈希与加载 |
| SMOKE | `artifacts/main_smoke.stdout.log`：隔离存储、场景初始化与 onboarding 渲染 PASS；stderr 为空 |
| CAPTURE | `tests/hiring_visual_capture.gd` 的显式 87-stem 清单；87 条唯一 `CAPTURED:` 与 `HIRING_VISUAL_CAPTURE_PASS: 87 captures`；同一次运行报告 `TEXT_FIT_OVERFLOWS: 0`，任何被静默裁掉的标签都会让捕获失败 |
| PIX | `tests/verify_ui_visual_contract.py`：根截图目录无 missing/extra PNG，选项仅文字变化、普通电梯按钮同主题、社交心形三阶段像素证据、38 个阅读面采样、14 个侧栏采样、7 个面板边界与设置遮罩衰减 |
| SIG | `artifacts/signature_motion.avi`；60 FPS 真实签字动画 |
| IDLE | `artifacts/night_idle_5min.avi`；300 idle frames 零状态变化 |
| WAV | `artifacts/audio_evidence/`：7 continuous（5 ambience + 2 score）、13 foley、25 mix refs |

当前自动化总计：18 套功能/语义/表现回归共 **10,841 checks**（逐套数字见上表，由 `artifacts/*.stdout.log` 生成，不再写进证据键名里——把数字编进键名保证了它迟早和事实不符）。状态含义：`Verified`=客观要求已有同范围实现与证据；`Partial`=复合要求仅客观部分闭合或仍需人工主观审批；`Unverified`=权威玩家/时间证据不存在。

实现列中的未限定事件、选项、热点和结局 key 均指 `src/hiring_content.gd` 的精确 key；模型机制、排程/分支、主界面、夜班状态、音频图分别默认定位到 `src/hiring_model.gd`、`src/hiring_director.gd`、`src/hiring_main.gd`、`src/night_interaction_state.gd`、`src/office_audio.gd`。行内另列文件时，以行内定位为准。

## 逐项台账

### 规范决议

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| DEC-001 | Verified | `src/hiring_model.gd` 七状态字段、`public_state()` | MODEL `_test_identity_chapters_and_public_contract` | CAPTURE `week_01_dashboard.png` | 无 |
| DEC-002 | Verified | `src/hiring_model.gd::end_week`；`DEBT_GAP_RATE/DEBT_REPAY_RATE` | MODEL `_test_weekly_decay_gap_debt_and_repayment` | — | 无 |
| DEC-003 | Verified | `src/hiring_content.gd` keys `first_investor_meeting`,`preseed_close`；`src/hiring_director.gd` | FLOW `_test_preseed_close_fundraise_mechanics` | CAPTURE `event_first_investor_meeting_cafe.png` | 无 |
| DEC-004 | Verified | `src/hiring_content.gd` key `seed_demo_unlock`；used/unused routes | FLOW `_test_never_used_demo_video_route`,`_test_used_demo_video_route` | — | 无；行为诱惑另见 ACCEPT-002 |
| DEC-005 | Verified | `src/hiring_content.gd` Lin/absence keys；`src/hiring_director.gd::_prepare_lin_last_visit` | FLOW `_test_lin_absent_echo_choices`,`_test_lin_training_gate_and_last_visit_priority` | — | 无 |
| DEC-006 | Verified | `docs/product_decisions.md::DEC-005/006`; `src/hiring_content.gd` key `lin_last_visit` 的在场/缺席分支 | CONTENT `_test_required_events_scenes_and_terms`; FLOW `_test_lin_training_gate_and_last_visit_priority` | — | 无；v1 文案已批准且可达性已验证 |
| DEC-007 | Verified | `docs/product_decisions.md::DEC-007`; `src/hiring_content.gd::NIGHT_SHIFTS["1"]` 五热点 | CONTENT `_test_night_shifts_and_exact_terminal_marker`; NIGHTSTATE/NIGHTUI 夜班一测试 | CAPTURE 夜班一截图组 | 无；绿萝/马克杯 v1 文案已批准 |
| DEC-008 | Verified | `src/hiring_model.gd::ENDING_PRIORITIES/select_ending`; `src/hiring_content.gd::ENDINGS` | MODEL `_test_all_seven_endings_and_priority`; FLOW `_test_all_endings_are_routable_and_gated` | CAPTURE 七结局 PNG | 无 |
| DEC-009 | Verified | `src/hiring_model.gd::cash_weeks/salary_burn_modifier/public_state/end_week` | MODEL cash/burn/save tests；FLOW LIVE cash routes | CAPTURE HUD/结局截图 | 无 |
| DEC-010 | Verified | `src/hiring_model.gd` employee schema、`_refresh_company_morale`、team size | MODEL employee/action/staffing tests | CAPTURE team/Chen screenshots | 无 |
| DEC-011 | Unverified | 章节周数在 `src/hiring_model.gd::CHAPTERS`；没有玩家时长数据 | MODEL `_test_full_chapter_clock` 仅验证周数，不验证分钟 | — | 首轮玩家各章中位时长与产品容差尚未采集/批准 |
| DEC-012 | Verified | `src/hiring_director.gd` Chen +3 周 callback 状态 | FLOW `_test_chen_xiaoyu_three_week_callback` | — | 无 |
| DEC-013 | Verified | `src/hiring_model.gd` `eval`/`capability_revealed`; HUD capability | MODEL `_test_every_action_and_declared_effect`; UIFLOW UI contract | CAPTURE dashboard | 无 |
| DEC-014 | Verified | `src/hiring_model.gd` exclusive interview threshold 55/chance .45/saved RNG | MODEL `_test_exclusive_interview_probability_and_replay` | — | 无 |
| DEC-015 | Verified | `src/hiring_content.gd` keys `lin_scene_3`,`lin_scene_4`; scoped choice effects | CONTENT Lin contracts；FLOW Lin branch tests | — | 无 |
| DEC-016 | Verified | `src/hiring_model.gd` key `sign` and AI exception | MODEL `_test_ai_delegation_dominates_every_manual_action_except_sign` | SIG；CAPTURE `signature_complete.png` | 无 |
| DEC-017 | Verified | `src/hiring_content.gd` delegation exception registry/CH0-W02/NG+ choices | CONTENT `_test_all_decisions_have_delegation`; FLOW NG+ | CAPTURE NG+ sequence | 无 |
| DEC-018 | Verified | `src/hiring_model.gd::VALUES_CORPUS_BODIES[1]`; ending text | MODEL `_test_history_memory_and_save_round_trip`; CONTENT ending lint | CAPTURE `ending_lights_out.png` | 无 |
| DEC-019 | Verified | `src/hiring_content.gd::FIXED_EVENTS/SILENT_EVENTS`; `src/hiring_director.gd` silent recording | CONTENT `_test_chapters_and_fixed_week_keys`; FLOW `_test_fixed_priority_silent_recording_and_special_effects` | — | 无 |
| DEC-020 | Verified | `src/hiring_director.gd` Lin training gate `train+large_train>=3`, author `<60` | FLOW `_test_lin_training_gate_and_last_visit_priority` | — | 无 |
| DEC-021 | Verified | `src/hiring_model.gd` layoffs, `LAYOFF_EMPLOYEE_COUNT`, burn floor | MODEL `_test_layoff_contract_and_burn_floor` | — | 无 |
| DEC-022 | Verified | `src/hiring_main.gd` internal/window workstation split and payroll display | UIFLOW `_test_employee_desk_and_window_population_contract` | CAPTURE window open/closed/reopened | 无 |

### 世界、基调与超现实规则

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| WORLD-001 | Verified | `src/hiring_content.gd` 开场、咖啡馆、外部地点与日期文本 | CONTENT world/anomaly tests；SEMANTIC 全 corpus；`docs/editorial_review.md` 联合审读 | CAPTURE `opening_event.png`,`event_first_investor_meeting_cafe.png` | 无；内部时代/湾区语义审读已签核 |
| WORLD-002 | Verified | `src/hiring_content.gd` 模型输出/禁用主题 corpus | CONTENT world/token/scene tests；SEMANTIC 全 corpus；`docs/editorial_review.md` | CAPTURE 多阶段 UI | 无；现实能力与无觉醒/奇点边界已签核 |
| WORLD-003 | Verified | `src/hiring_content.gd::ANOMALY_REGISTRY` location/source 字段 | CONTENT `_test_anomaly_registry_and_external_boundary` | CAPTURE 正常咖啡馆与办公室异常对照 | 无 |
| WORLD-004 | Verified | `src/hiring_model.gd::company_name/to_save/from_save`; ending token injection | MODEL identity/save/endings；UIFLOW `_test_all_ending_playback_surfaces` | CAPTURE 七结局 PNG | 无 |
| WORLD-005 | Verified | `src/hiring_model.gd::VALUES_CORPUS_BODIES[1]`; `src/hiring_content.gd` origin/endings | MODEL values corpus/save；CONTENT origin/endings | CAPTURE opening/origin/lights-out | 无 |
| WORLD-006 | Verified | `src/hiring_model.gd::CHAPTERS[*].model_name`; chapter content nickname rules | MODEL chapter names；CONTENT `_test_world_stats_stages_and_memories` | CAPTURE dashboard/intranet finale | 无 |
| WORLD-007 | Verified | `src/hiring_director.gd` chapter-four silent beat；notification queue stays empty | FLOW `_test_final_silence_defers_modal_queue`; UIFLOW `_test_quiet_chronology_surfaces` | CAPTURE `intranet_finale.png` | 无 |
| WORLD-008 | Verified | `src/hiring_main.gd` software-shell rendering；无主角 identity 字段/portrait | MODEL identity schema；UIFLOW main UI traversal | CAPTURE 81-screen set | 无 |
| WORLD-009 | Verified | `src/hiring_content.gd` anomaly reaction/night desk copy；无调查 action | CONTENT anomaly/night registry；NIGHTSTATE night paths | CAPTURE night desk/window sequence | 无 |
| WORLD-010 | Verified | `src/hiring_content.gd` key `live_demo` AI branch exact “我们”停顿线索 | CONTENT required terms；FLOW live-demo routes | — | 无 |
| WORLD-011 | Verified | `src/hiring_model.gd` Lin employee；`src/hiring_content.gd` Lin scene registry | CONTENT employee/Lin registry；FLOW full campaign | CAPTURE team screenshots | 无 |
| WORLD-014 | Verified | `src/hiring_main.gd::_lin_relationship_seed` 持久关系维度；`src/hiring_content.gd` 开场回应 | OPENING `_test_authored_relationship_opening` 断言 warmth/chemistry/shared_values 分别记账并存档往返；MODEL `public_state` 不含 `lin_relationship` | CAPTURE opening_event / prologue captures | 无；无好感度条，恋爱线未解锁，未来系统仍须同时检查信任与边界 |
| WORLD-012 | Verified | `src/hiring_content.gd` Lin dialogue corpus and metadata | CONTENT `_test_lin_tone_lint`；SEMANTIC；`docs/editorial_review.md::WORLD-012` | CAPTURE 林越事件与肖像状态 | 无；v1 角色语气已通过编辑审读 |
| WORLD-013 | Verified | `src/hiring_content.gd` `lin_scene_1..4`,`lin_last_visit`,`lin_absent_echo` | CONTENT reachability；FLOW Lin presence/absence routes | — | 无 |
| LIFEPATH-001 | Verified | `src/hiring_content.gd::ORIGINS`,`PROLOGUES`；`src/hiring_main.gd::_open_origin_prologue` | ORIGIN 节拍数、提问次数、收束拍断言；U630 序章不解析导演键并原样交出车库事件 | CAPTURE `prologue_bigco_align`,`prologue_bigco_exit`,`prologue_serial_postmortem`,`prologue_funded_money` | 无 |
| LIFEPATH-002 | Verified | `src/hiring_content.gd` `{{lin_history}}` + `history_lines`；`1:4`/`2:6`/`3:7` 的 `origin ==` 选项；`src/hiring_director.gd::_condition_atom` | ORIGIN 占位展开、三条过去互不相同、跨出身选项不可见；OPENING 车库正文按出身展开 | CAPTURE opening_event | 无 |
| LIFEPATH-003 | Verified | `src/hiring_model.gd::origin_weekly_burn_multiplier`,`origin_id` 持久化 | ORIGIN 起始现金相同、45 周后差值 ≥6 周、旧存档回落默认出身 | — | 无 |
| LIFEPATH-004 | Verified | `src/hiring_content.gd` 各 `origin_*` 选项的 effects 与 result | ORIGIN 逐条断言代价或非最优、result 非空、非委托路线 | — | 无 |
| TONE-001 | Verified | `src/hiring_content.gd` office/night copy；`src/office_audio.gd` 克制 ambience/score/foley 图谱 | CONTENT anomaly lint；SEMANTIC；AUDIO 低电平稀疏动机、物理拟音余量与异常/静默无 cue；NIGHTSTATE/NIGHTUI idle invariants；`docs/editorial_review.md` | IDLE；WAV；CAPTURE debt/night captures | 无；内部联合预检通过，首玩联想另由 ACCEPT-005 承接 |
| TONE-002 | Unverified | 目标由当前内容支持，但无玩家研究 | 自动化不能验证“认出来了” | — | 必须由 ACCEPT-005 首次玩家访谈验证 |
| SURREAL-001 | Verified | `src/hiring_content.gd::ANOMALY_REGISTRY` leased-office locations | CONTENT `_test_anomaly_registry_and_external_boundary` | CAPTURE 咖啡馆/办公室对照 | 无 |
| SURREAL-002 | Verified | `src/night_interaction_state.gd` 无 agent/chase；anomaly behavior registry | CONTENT anomaly rules；NIGHTSTATE/NIGHTUI | IDLE 300 秒零状态变化 | 无 |
| SURREAL-003 | Verified | `src/hiring_content.gd` anomalies/endings 无 reveal 类型 | CONTENT semantic-token checks；SEMANTIC 全 corpus；`docs/editorial_review.md` | IDLE；CAPTURE 七结局 | 无；内部“永不解释”语义审读已签核 |
| SURREAL-004 | Verified | `src/hiring_content.gd` window/room-D administrative reactions | CONTENT anomaly registry；UIFLOW curtain state machine；NIGHTSTATE room-D | CAPTURE curtain/room-D captures | 无 |
| SURREAL-005 | Verified | `src/hiring_content.gd::ANOMALY_REGISTRY[*].administrative_source` | CONTENT `_test_anomaly_registry_and_external_boundary` | CAPTURE anomaly surfaces | 无 |
| SURREAL-006 | Verified | `src/hiring_main.gd` final window population；`src/hiring_model.gd` chapter-four target | MODEL staffing；UIFLOW desk/window contract | CAPTURE `team_finale_window_open.png` | 无 |
| SURREAL-007 | Verified | `src/hiring_content.gd` room-D calendar/night keys；night interaction state | CONTENT night/calendar；NIGHTSTATE/NIGHTUI room-D sequence | CAPTURE calendar + room-D captures | 无 |
| SURREAL-008 | Verified | `src/hiring_content.gd` `series_a_expansion`; `src/hiring_main.gd` elevator resource UI | FLOW silent event；UIFLOW quiet chronology | CAPTURE `calendar_supernatural_resources.png` | 无 |
| SURREAL-009 | Verified | `src/hiring_content.gd` phantom employee/report keys incl. report 91 | CONTENT `_test_intranet_documents_and_report_91`; FLOW silent events | CAPTURE phantom team/announcement/intranet | 无 |
| SURREAL-010 | Verified | `src/hiring_content.gd::ANOMALY_REGISTRY`; UI/night implementations | CONTENT anomaly lint；SEMANTIC；NIGHTSTATE/NIGHTUI；`docs/editorial_review.md` | IDLE；CAPTURE anomalies | 无；内部叙事/美术联合审读已签核 |

### 核心循环、状态、注意力与作者阶段

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| LOOP-001 | Verified | `src/hiring_model.gd` action/economy/writer-stage loop；`src/hiring_director.gd` campaign flow | MODEL full clock/stages；FLOW `_test_complete_campaign` 两策略 | CAPTURE dashboard→finale | 无 |
| STAT-001 | Verified | `src/hiring_model.gd` 七项状态与 save schema | MODEL identity/boundary/save tests | CAPTURE dashboard | 无 |
| STAT-002 | Verified | `src/hiring_model.gd::public_state/end_week/apply_effects` cash-percent/burn/runway | MODEL cash/burn；FLOW LIVE cash；UIFLOW cash exhaustion | CAPTURE dashboard/lights-out | 无 |
| STAT-003 | Verified | `src/hiring_model.gd` compute gates/costs；`src/hiring_main.gd` HUD disabled copy | MODEL action contracts；UIFLOW `_test_compute_unavailable_copy` | CAPTURE `action_large_train_compute_blocked.png` | 无 |
| STAT-004 | Verified | `src/hiring_model.gd::apply_effects/public_state` 0–100 clamps | MODEL action/fixed-effect/boundary tests | CAPTURE dashboard | 无 |
| STAT-005 | Verified | `src/hiring_model.gd::public_state` omits debt/author；`src/hiring_main.gd` HUD | MODEL public contract；UIFLOW UI contract | CAPTURE full screenshot set | 无 |
| STAT-006 | Verified | `src/hiring_model.gd::end_week` post-decay gap formula | MODEL `_test_weekly_decay_gap_debt_and_repayment` | — | 无 |
| FUND-001 | Verified | `src/hiring_model.gd::_fundraising_cash_gain`; event funding branches | MODEL `_test_fundraising_only_reads_narrative`; FLOW investor routes | CAPTURE investor café | 无 |
| FUND-002 | Unverified | Mechanics/content avoid explicit tutorial disclosure | CONTENT/FLOW only prove rule/content, not discovery time | — | 首次玩家约 20 分钟发现规则的时间戳与访谈尚无 |
| NARR-001 | Verified | `src/hiring_model.gd::end_week` fixed -2 | MODEL weekly decay/full clock | — | 无 |
| DEBT-001 | Verified | `src/hiring_model.gd::office_deterioration_tier`; `src/hiring_main.gd` office visual states | MODEL tier boundaries；UIFLOW visual state contract | CAPTURE `office_debt_clear/mid/high.png` | 无 |
| DEBT-002 | Verified | `src/hiring_model.gd::_update_fulfillment_pressure`; event pool | MODEL `_test_office_deterioration_and_fulfillment_pressure`; CONTENT event registry | — | 无 |
| DEBT-003 | Partial | `src/hiring_model.gd` repayment/train/eval mechanics | MODEL debt repayment/training/eval tests | — | “训练体感慢贵无聊、逊于发推”仍需玩家/平衡 QA |
| ATT-001 | Verified | `src/hiring_model.gd::begin_week/can_act/perform_action` | MODEL `_test_attention_and_chapter_four_reversal` | CAPTURE week-one dashboard | 无 |
| ATT-002 | Verified | `src/hiring_model.gd::can_act` 3 manual + exactly one delegation；`src/hiring_main.gd` five-card pool | MODEL attention arithmetic/save；UIFLOW `_test_action_pool_surface_contract`,`_test_stage_one_ai_response_and_action_ceiling` | CAPTURE dashboard | 无 |
| ATT-003 | Verified | `src/hiring_model.gd::CHAPTER_FOUR_ACTIONS`; writer stage 5 | MODEL chapter-four reversal/stage five；UIFLOW action pool | CAPTURE intranet/signature/finale | 无 |
| IDLE-001 | Verified | `src/hiring_model.gd` `do_nothing`; pool builder | MODEL action contract；UIFLOW week-one/action pool | CAPTURE week-one dashboard | 无 |
| WRITE-001 | Verified | `src/hiring_content.gd` choices + delegation exception registry | CONTENT `_test_all_decisions_have_delegation`; FLOW choice coverage | CAPTURE event/NG+/board surfaces | 无 |
| WRITE-002 | Verified | `src/hiring_model.gd::perform_action/_apply_ai_advantage`; sign exception | MODEL `_test_ai_delegation_dominates_every_manual_action_except_sign` | SIG for sign | 无 |
| WRITE-003 | Verified | Generic AI utility in `src/hiring_model.gd`; authored AI effects in content；`read_intranet` 以节省 1 注意力作为“少一件烦心事”，不虚构现金收益 | MODEL all-action dominance；CONTENT/FLOW all AI choices；SEM benefit-direction audit | CAPTURE 委托结果与行动表面 | 无；“是否再次主动使用”仍单独由 ACCEPT-002 验证 |
| WRITE-004 | Verified | `author_weight` stages + downstream Lin/identity costs | MODEL stage tests；FLOW Lin/complete campaigns；SEMANTIC；`docs/editorial_review.md::WRITE-004` | CAPTURE 录像、起源、董事会与结局链 | 无；v1 产品/叙事审读通过 |
| WRITE-005 | Verified | `src/hiring_main.gd` stage-one visible response exact phrase | UIFLOW `_test_stage_one_ai_response_and_action_ceiling`; CONTENT phrase corpus | — | 无 |
| WRITE-006 | Verified | `src/hiring_model.gd::begin_week` stage-two unsolicited line | MODEL `_test_writer_stages_and_autonomy` | — | 无 |
| WRITE-007 | Verified | `src/hiring_main.gd::_choice_display_label`; option voice flag | MODEL stage threshold；UIFLOW `_test_stage_three_option_voice_surface` | — | 发现率另见 ACCEPT-003 |
| WRITE-008 | Verified | `src/hiring_model.gd::_run_stage_four_administration` | MODEL `_test_writer_stages_and_autonomy` | — | 无 |
| WRITE-009 | Verified | `src/hiring_model.gd::_run_stage_five_autonomy`; chapter-four attention | MODEL stage-five finance/hire/layoff/cap replacement；FLOW stage-five start | CAPTURE finale surfaces | 无 |
| WRITE-010 | Verified | `src/hiring_main.gd::_choice_display_label` punctuation/length transform | UIFLOW `_test_stage_three_option_voice_surface` | PIX 同界面前后差分：主题外像素变化为 0 | 无 |

### 行动池

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| ACT-N01 | Verified | `src/hiring_model.gd::_resolve_action("tweet")` | MODEL `_test_every_action_and_declared_effect`,`_test_ranged_rolls_unlock_weeks_and_save_state` | — | 无 |
| ACT-N02 | Verified | `src/hiring_model.gd::_resolve_action("tech_blog")`, threshold `<40` | MODEL action matrix + 39.999/40 boundary | — | 无 |
| ACT-N03 | Verified | `src/hiring_model.gd::_resolve_action("podcast")` | MODEL action matrix | — | 无 |
| ACT-N04 | Verified | `src/hiring_model.gd::_resolve_action("demo_video")`; unlock registry | MODEL action/unlock；FLOW used/unused demo routes | — | 无 |
| ACT-N05 | Verified | `src/hiring_model.gd::_resolve_action("conference_talk")` | MODEL action/employee delta matrix | — | 无 |
| ACT-N06 | Verified | `src/hiring_model.gd::_resolve_action("manifesto")`; week-2 gate | MODEL action/unlock/clamp matrix | — | 无 |
| ACT-N07 | Verified | `src/hiring_model.gd::_resolve_action("exclusive_interview")` | MODEL 55/55.001, fixed seeds, save replay | — | 无 |
| ACT-C01 | Verified | `src/hiring_model.gd::_resolve_action("train")` | MODEL range/resource/action tests | — | 无 |
| ACT-C02 | Verified | `src/hiring_model.gd` `clean_data`/`training_boost_uses` | MODEL `_test_training_pipeline_and_contract_block`; save tests | — | 无 |
| ACT-C03 | Verified | `src/hiring_model.gd` `eval`/`capability_revealed` | MODEL action matrix + flag save | CAPTURE dashboard | 无 |
| ACT-C04 | Verified | `src/hiring_model.gd` `large_train`, compute cost 8 | MODEL action/range/resource gates；UIFLOW unavailable copy | CAPTURE `action_large_train_compute_blocked.png` | 无 |
| ACT-C05 | Verified | `src/hiring_model.gd` `recruit_expert`/`_next_candidate(true)` | MODEL action/employee effects | — | 无 |
| ACT-C06 | Verified | `src/hiring_model.gd::_resolve_action("alignment_week")` | MODEL action matrix | — | 无 |
| ACT-T01 | Verified | `src/hiring_director.gd` candidate event/selection；candidate schema | FLOW `_test_hiring_candidate_identity_and_single_hire`,`_test_hiring_delegate_selects_visible_best_candidate` | — | 无 |
| ACT-T02 | Verified | `src/hiring_director.gd` one-on-one target/listen/solve rotation | FLOW `_test_one_on_one_fact_rotation_and_solve_scope` | CAPTURE team UI | 无 |
| ACT-T03 | Verified | `src/hiring_model.gd` `all_hands`; `src/hiring_director.gd` promise event | MODEL action contradiction；FLOW `_test_all_hands_decision_and_promise_callback` | — | 无 |
| ACT-T04 | Verified | `src/hiring_model.gd::record_values_document` | MODEL values corpus/history/save；CONTENT content | CAPTURE origin/intranet | 无 |
| ACT-T05 | Verified | `src/hiring_model.gd::_resolve_action("team_building")` | MODEL exact morale/belief and zero cash cost | — | 无 |
| ACT-T06 | Verified | `src/hiring_model.gd` `raise_salary` + `salary_burn_modifier` | MODEL action matrix/burn mechanics | — | 无 |
| ACT-T07 | Verified | `src/hiring_model.gd` layoffs six non-Lin/burn/debt/belief | MODEL `_test_layoff_contract_and_burn_floor`; FLOW layoff routes | — | 无 |
| ACT-O01 | Verified | `src/hiring_model.gd::_resolve_action("buy_compute")` | MODEL exact cash/compute and gate | — | 无 |
| ACT-O02 | Verified | `src/hiring_model.gd` fundraising narrative-only function | MODEL `_test_fundraising_only_reads_narrative` | CAPTURE investor café | 无 |
| ACT-O03 | Verified | `src/hiring_model.gd` contract effects/training block | MODEL `_test_training_pipeline_and_contract_block`; FLOW cash-crisis routes | — | 无 |
| ACT-O04 | Verified | `src/hiring_model.gd::_resolve_action("do_nothing")` | MODEL action matrix/attention; UIFLOW pool | CAPTURE dashboard | 无 |
| ACT-F01 | Verified | `src/hiring_model.gd` sign zero-effect branch；`src/hiring_main.gd` signature animation | MODEL deep no-effect exception；UIFLOW screen flow | SIG；CAPTURE `signature_complete.png` | 无 |
| ACT-F02 | Verified | `src/hiring_model.gd` `read_intranet`; `src/hiring_main.gd` intranet surface | CONTENT `_test_intranet_documents_and_report_91`; UIFLOW origin/finale UI | CAPTURE intranet/origin/report captures | 无 |
| ACT-F03 | Verified | `src/hiring_model.gd::can_act("one_on_one")` employee-count gate | MODEL action availability；FLOW one-on-one | — | 无 |
| ACT-F04 | Verified | `src/hiring_model.gd` chapter-four `do_nothing` | MODEL action matrix/chapter-four pool | — | 无 |

### 员工、见证与记忆

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| EMP-001 | Verified | `src/hiring_model.gd::_make_employee` name/skill/morale/belief schema | MODEL employee/save tests；FLOW candidate tests | CAPTURE team screenshots | 无 |
| EMP-002 | Verified | `src/hiring_model.gd` centralized debt tiers/erosion/departure tables | MODEL `_test_employee_debt_erosion_contract` boundaries/multiweek/witness/save | — | 无 |
| EMP-003 | Verified | `src/hiring_model.gd` `witnessed` set and departure variants | MODEL `_test_employees_witness_depart_and_remember`; FLOW witnessed resignation | — | 无 |
| EMP-004 | Verified | `src/hiring_content.gd` Chen template；`src/hiring_main.gd` three-cup desk | CONTENT `_test_employees_and_chen_cups`; UIFLOW desk contract | CAPTURE Chen before/active/after captures | 无 |
| EMP-005 | Verified | `src/hiring_content.gd` Chen four copy keys；director departure routing | CONTENT employee copy snapshots；FLOW `_test_chen_xiaoyu_runtime_copy_and_clean_resignation`,`_test_witnessed_resignation_and_one_on_one_tie_break` | CAPTURE Chen states | 无 |
| MEM-001 | Verified | `src/hiring_model.gd::memory/history/to_save/from_save` | MODEL `_test_history_memory_and_save_round_trip`; FLOW save | — | 无 |
| MEM-002 | Verified | `src/hiring_director.gd` promise week/like count and layoff-open callback | FLOW `_test_all_hands_decision_and_promise_callback`,`_test_layoff_promise_copy_routes` | — | 无 |
| MEM-003 | Verified | `src/hiring_director.gd` live-demo used/unused preparation | FLOW `_test_never_used_demo_video_route`,`_test_used_demo_video_route` | — | 无 |
| MEM-004 | Verified | `src/hiring_model.gd` missed-meal durable due state；director Friday callback | MODEL `_test_cross_week_memory_markers`; FLOW `_test_missed_meal_callback_is_a_friday_memory` | — | 无 |
| MEM-005 | Verified | `src/hiring_director.gd` Chen layoff week +3 data-quality callback | FLOW `_test_chen_xiaoyu_three_week_callback` | — | 无 |
| MEM-006 | Verified | `src/hiring_model.gd` permanent values corpus v3；internal document generator | MODEL values history/save；CONTENT intranet docs；FLOW corpus provenance | CAPTURE origin/intranet | 无 |
| MEM-007 | Verified | `src/hiring_model.gd::begin_week` never-delegated flag/question | MODEL stage/chapter-four test；CONTENT question text；FLOW full campaign | — | 无 |

### 第零章与第一章

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| CH0-000 | Partial | `src/hiring_content.gd` garage tutorial + `lin_scene_1` | CONTENT fixed keys；FLOW opening/full campaign；UIFLOW new-company flow | CAPTURE opening/week-one | “让玩家喜欢林越”与教程完成率需首次玩家数据 |
| CH0-OPEN | Verified | `src/hiring_content.gd` key `opening`; `src/hiring_main.gd` company-name rendering | CONTENT required terms；UIFLOW `_test_new_company_opening_action_and_save` | CAPTURE `opening_event.png`,`onboarding.png` | 无 |
| CH0-W01 | Verified | `src/hiring_model.gd::begin_week`; UI chapter-zero pool | MODEL attention；UIFLOW action-pool/new-company tests | CAPTURE `week_01_dashboard.png` | 无 |
| CH0-W02 | Verified | `src/hiring_content.gd` key `model_first_sentence` | CONTENT exact-term coverage；FLOW action-phase；UIFLOW week-two event；SEMANTIC 全模型发言比较；`docs/editorial_review.md` | CAPTURE week-two surface | 无；完整 corpus 编辑审读通过 |
| CH0-W03 | Verified | `src/hiring_content.gd` fixed key `lin_scene_1`; director chapter transition | CONTENT fixed keys；FLOW full campaign | — | 无 |
| CH1-000 | Partial | Narrative-only fundraising and training/tweet actions implemented | MODEL fundraising/action tests；FLOW investor flow | CAPTURE investor café | 玩家是否自行发现仍取决于 FUND-002 首玩研究 |
| CH1-W01 | Verified | `src/hiring_model.gd::ACTION_MIN_CHAPTER`; UI pool | MODEL action availability；UIFLOW action pool | — | 无 |
| CH1-W02 | Verified | `src/hiring_content.gd` silent/free key `preseed_free_2` | CONTENT 45-key coverage；FLOW fixed-priority/silent tests | — | 无 |
| CH1-W03 | Verified | `src/hiring_content.gd` silent/free key `preseed_free_3` | CONTENT/FLOW fixed/silent coverage | — | 无 |
| CH1-W04 | Verified | `src/hiring_content.gd` key `first_investor_meeting`; director choice effects | FLOW `_test_preseed_close_fundraise_mechanics`; MODEL FUND-001 | CAPTURE investor café | 无 |
| CH1-W05 | Verified | `src/hiring_content.gd` silent key `investor_repost` | FLOW fixed-priority/silent；UIFLOW quiet chronology | — | 无 |
| CH1-W06 | Partial | `src/hiring_content.gd` key `viral_tweet` exact deltas/copy | CONTENT term/delta lint；FLOW fixed flow | — | “第一次窃喜”的情感效果需人工/玩家叙事 QA |
| CH1-W07 | Verified | `src/hiring_content.gd` fixed key `lin_scene_2` | CONTENT fixed keys/Lin content；FLOW full campaign | — | 无 |
| CH1-W08 | Verified | `src/hiring_content.gd` key `preseed_close`; director financing transition | FLOW `_test_preseed_close_fundraise_mechanics` | — | 无 |
| CH1-SIZE | Verified | `src/hiring_model.gd::_scale_team_to_chapter_target` target 4 | MODEL `_test_chapter_staffing_targets`; FLOW full campaign | CAPTURE team | 无 |
| INVEST-001 | Verified | `src/hiring_content.gd` key `first_investor_meeting` | CONTENT required event/token snapshots；FLOW investor route | CAPTURE `event_first_investor_meeting_cafe.png` | 无 |
| INVEST-002 | Verified | Same event choice key `honest` | CONTENT exact effects/text；FLOW preseed mechanics | CAPTURE investor café | 无 |
| INVEST-003 | Verified | Same event choice key `pitch` | CONTENT exact effects；FLOW preseed mechanics | — | 无 |
| INVEST-004 | Verified | Same event choice key `delegate` | CONTENT delegation/effects；FLOW preseed mechanics | — | 无 |
| VIRAL-001 | Verified | `src/hiring_content.gd` key `viral_tweet` | CONTENT exact numbers/terms；FLOW fixed schedule | — | 无 |

### 第二章与现场兑现

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| CH2-000 | Partial | `src/hiring_content.gd` Seed debt/live-demo structure；AI choice | CONTENT fixed keys；FLOW demo/live routes | CAPTURE debt tiers | “强烈诱导”需 ACCEPT-002/首玩行为数据 |
| CH2-W01 | Verified | Chapter transition/office state；night-one pending key | MODEL full clock；FLOW full campaign；UIFLOW night advance | CAPTURE office/night-one opening | 无 |
| CH2-W02 | Partial | `src/hiring_content.gd` `seed_demo_unlock`; action pool unlock | MODEL action unlock；FLOW used/unused routes；UIFLOW pool | — | “明显诱惑”需首玩行为验证 |
| CH2-W03 | Verified | `src/hiring_content.gd` silent key `seed_free_3`; debt system | CONTENT fixed-key completeness；MODEL debt accumulation | — | 无 |
| CH2-W04 | Verified | `src/hiring_content.gd` silent key `seed_free_4`; debt system | CONTENT/MODEL | — | 无 |
| CH2-W05 | Verified | `src/hiring_content.gd` silent key `seed_debt_5`; current balance actions | FLOW silent beat；UIFLOW 多个合理生产行动策略自然达到 debt≥40 并记录峰值 | CAPTURE debt-mid/high visual states | 无 |
| CH2-W06 | Verified | `src/hiring_content.gd` key `live_demo`; director route matrix | CONTENT/FLOW live-demo branch tests；UIFLOW 专用录像状态机 | CAPTURE 五阶段 live replay | 无；转折的可达、表演与后果已闭合 |
| CH2-W07 | Verified | `src/hiring_content.gd` key `first_resignation_signal` | CONTENT fixed keys；FLOW conditional beats | — | 无 |
| CH2-W08 | Verified | `src/hiring_content.gd` silent hiring metrics 4,200/3；announcement UI | FLOW silent chronology；UIFLOW `_test_quiet_chronology_surfaces` | CAPTURE metrics hidden/released PNG | 无 |
| CH2-W09 | Verified | `src/hiring_content.gd` fixed key `lin_scene_3` | CONTENT Lin content；FLOW full campaign | — | 无 |
| CH2-W10 | Verified | `src/hiring_director.gd` debt-conditioned repeat live event | FLOW `_test_live_demo_postpone_return_schedule`,`_test_chapter_two_quiet_and_conditional_beats` | — | 无 |
| CH2-W11 | Verified | `src/hiring_content.gd` financing-phase fixed key | CONTENT 45-key schedule；FLOW complete campaigns | — | 无 |
| CH2-W12 | Verified | financing close/chapter transition keys | CONTENT fixed keys；FLOW complete campaigns | — | 无 |
| CH2-END | Verified | `src/hiring_content.gd::NIGHT_SHIFTS["1"]`; director night gate | FLOW `_test_night_shift_requires_inspection`; NIGHTSTATE/NIGHTUI | CAPTURE night-one captures | 无 |
| CH2-SIZE | Verified | `src/hiring_model.gd` chapter target 9 | MODEL `_test_chapter_staffing_targets`; FLOW campaign | CAPTURE team | 无 |
| LIVE-001 | Verified | `src/hiring_content.gd` `live_demo` body/aftermath tokens | CONTENT exact token lint；FLOW live routes | — | 无 |
| LIVE-002 | Verified | `live_demo` choice `run_live`, success branch | FLOW ability 59/60 and exact success effects | — | 无 |
| LIVE-003 | Verified | `run_live` failure branch；immutable two-departure snapshot | FLOW failure boundary/cash/two departures/save | — | 无 |
| LIVE-004 | Verified | `live_demo` choice `postpone`; deterministic return scheduling | FLOW `_test_live_demo_postpone_return_schedule` | — | 无 |
| LIVE-005 | Verified | `live_demo` choice `delegate` | CONTENT exact effect/delegation；FLOW guaranteed route | — | 无 |
| LIVE-006 | Verified | `src/hiring_content.gd` delegated result copy/“我们”停顿；专用无脸录像状态机 | CONTENT full text tokens；FLOW route；UIFLOW timed replay/rapid-input/save-resume contract；`docs/editorial_review.md` | CAPTURE signed/playback/pause/replay/aftermath captures | 无；v1 节奏与表演已签核 |

### 第三章与裁员

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| CH3-000 | Partial | Series-A departure and stage-three voice systems | FLOW departure/voice routes；UIFLOW option voice | — | “不像玩家写的”发现/情感效果仍依赖 ACCEPT-003/004 |
| CH3-W01 | Verified | `src/hiring_content.gd` silent expansion/elevator resource | CONTENT anomaly/schedule；FLOW silent events；UIFLOW chronology | CAPTURE `calendar_supernatural_resources.png` | 无 |
| CH3-W02 | Verified | `src/hiring_model.gd` week-two unlock gate for manifesto/interview/layoffs | MODEL ranged unlock tests；UIFLOW pool surface | — | 无 |
| CH3-W03 | Verified | `src/hiring_content.gd` silent phantom employee/report key | CONTENT anomaly/report；FLOW silent event；UIFLOW chronology | CAPTURE phantom employee/report captures | 无 |
| CH3-W04 | Verified | Stage-three threshold/choice rewrite and no-event placeholder | MODEL writer stage；CONTENT schedule；UIFLOW option voice/quiet chronology | — | 玩家发现率单列 ACCEPT-003，不影响客观实现状态 |
| CH3-W05 | Verified | `src/hiring_content.gd` former-employee-post fulfillment key | CONTENT event pool/fixed keys；FLOW campaign reachability | — | 无 |
| CH3-W06 | Verified | `src/hiring_content.gd` cash-crisis event restricted choices | FLOW `_test_cash_crisis_contract_and_layoff_routes` | — | 无 |
| CH3-W07 | Verified | `src/hiring_content.gd` layoff execution event | FLOW cash-crisis/layoff promise routes；CONTENT content | — | 无 |
| CH3-W08 | Verified | silent room-D calendar key | CONTENT anomaly/schedule；FLOW silent event；UIFLOW chronology | CAPTURE calendar room-D | 无 |
| CH3-W09 | Verified | high-debt realization fixed key/queue | CONTENT fixed schedule；FLOW complete campaign | — | 无 |
| CH3-W10 | Verified | second high-debt realization fixed key/queue | CONTENT fixed schedule；FLOW complete campaign | — | 无 |
| CH3-W11 | Verified | `src/hiring_content.gd` `lin_scene_4`; director 59/60 routing | CONTENT Lin matrix；FLOW `_test_lin_scene_four_deferred_departure`,`_test_lin_training_gate_and_last_visit_priority` | — | 无 |
| CH3-W12 | Verified | financing-phase fixed key | CONTENT schedule；FLOW campaign | — | 无 |
| CH3-W13 | Verified | financing-phase fixed key | CONTENT schedule；FLOW campaign | — | 无 |
| CH3-W14 | Verified | chapter settlement key/transition | CONTENT schedule；MODEL full clock；FLOW campaign | — | 无 |
| CH3-END | Verified | night-two gate + explicit `lin_scene_4` removal | FLOW Lin deferred departure/night inspection；NIGHTSTATE/NIGHTUI night two | CAPTURE night-two captures | 无 |
| CH3-SIZE | Verified | `src/hiring_model.gd` target 22 | MODEL staffing targets；FLOW campaign | CAPTURE team | 无 |
| LAYOFF-001 | Verified | `src/hiring_content.gd` layoff list/copy；director promise week/like interpolation | CONTENT exact terms；FLOW `_test_layoff_promise_copy_routes` | — | 无 |
| LAYOFF-002 | Verified | layoff event manual-talk choice effects/attention | CONTENT exact effect schema；FLOW cash-crisis routes | — | 无 |
| LAYOFF-003 | Verified | layoff event email choice effects/attention | CONTENT/FLOW exact route | — | 无 |
| LAYOFF-004 | Verified | delegated layoff copy/schedule/social-state sequence | CONTENT six×20-minute/text lint；FLOW route；UIFLOW deterministic social-heart state machine | PIX 三阶段心形像素证据；CAPTURE social captures | 无 |

### 第四章、窗外工位、起源与董事会

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| CH4-000 | Partial | chapter-four 1-attention/four-card pool + stage-five autonomy | MODEL chapter-four/stage-five；FLOW stage-five start；UIFLOW pool | CAPTURE finale/intranet/signature | “几乎无事可做且运转更好”的整体体验需首玩 QA |
| CH4-W01 | Verified | model name `LANTERN`; silent chapter-opening key | MODEL names；CONTENT no nickname；FLOW final silence；UIFLOW chronology | CAPTURE `intranet_finale.png` | 无 |
| CH4-W02 | Verified | window workstation event/state machine | CONTENT anomaly registry；UIFLOW curtain/window contract | CAPTURE window open/closed/reopened | 无 |
| CH4-W03 | Verified | `src/hiring_content.gd` origin article；UI read-state machine | CONTENT intranet docs；UIFLOW `_test_origin_article_state_machine` | CAPTURE origin three-state captures | 无 |
| CH4-W04 | Verified | `docs/product_decisions.md::DEC-005/006`; `src/hiring_content.gd` `lin_last_visit` present/absence branches | CONTENT content；FLOW `_test_lin_training_gate_and_last_visit_priority` | — | 无 |
| CH4-W05 | Verified | phantom report number 91 key | CONTENT `_test_intranet_documents_and_report_91` | CAPTURE `intranet_phantom_weekly_report.png` | 无 |
| CH4-W06 | Verified | board event and presentation state machine | CONTENT board content；UIFLOW `_test_board_ai_presentation_state_machine` | CAPTURE board page/org/aftermath | 无 |
| CH4-W07 | Verified | invisible silent placeholder and no major modal | CONTENT 45-key completeness；FLOW final-silence test；UIFLOW chronology | — | 无 |
| CH4-W08 | Verified | director campaign completion + ending resolver/playback | MODEL ending resolver；FLOW ending routes；UIFLOW all ending surfaces | CAPTURE seven ending PNG | 无 |
| WINDOW-001 | Verified | `src/hiring_content.gd` window body；`src/hiring_main.gd` four silhouettes/desks | CONTENT exact content；UIFLOW desk/window population | CAPTURE `team_finale_window_open.png` | 无 |
| WINDOW-002 | Verified | window event administrative count/curtain choice | CONTENT exact copy；UIFLOW curtain state machine | CAPTURE open→closed | 无 |
| WINDOW-003 | Verified | persisted curtain closed-once / reopen-on-entry state | UIFLOW `_test_finale_window_curtain_state_machine` | CAPTURE closed/reopened | 无 |
| ORIGIN-001 | Verified | `src/hiring_content.gd` origin article exact dog/printer/“先这样” tokens | CONTENT intranet tests；UIFLOW origin state；SEMANTIC；`docs/editorial_review.md::ORIGIN-001` | CAPTURE origin captures | 无；当前正文批准为 v1 基线 |
| ORIGIN-002 | Verified | origin article collective-voice exact text | CONTENT exact token lint；UIFLOW origin state | CAPTURE origin article | 无 |
| ORIGIN-003 | Verified | `src/hiring_main.gd` read-count/editor/close state machine | UIFLOW `_test_origin_article_state_machine` | CAPTURE second/third/unchanged captures | 无 |
| BOARD-001 | Verified | `src/hiring_content.gd` board body；UI presentation fixture | CONTENT exact board terms；UIFLOW board state machine | CAPTURE board captures | 无 |
| BOARD-002 | Verified | board choices `stable`,`seven_left` with distinct coherent outcomes | CONTENT choice/effect completeness；FLOW after-coverage | CAPTURE board surface | 无 |
| BOARD-003 | Verified | board `delegate` scripted page/org-chart/aftermath states | CONTENT exact 11%/20-minute text；UIFLOW board state machine | CAPTURE three board frames | 无 |

### 林越主线矩阵

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| LIN-001 | Verified | `src/hiring_content.gd` key `lin_scene_1`, no choices/player reply | CONTENT Lin scene schema/text；FLOW complete campaign | — | 无 |
| LIN-002 | Verified | `docs/product_decisions.md::DEC-026`；`lin_scene_2` 保留两段 story-time 120 秒；`src/hiring_main.gd` 映射为普通模式各 10 秒、降低动态各 0.15 秒 | CONTENT exact `[0,120,0,120,0]` authored holds；FLOW reachability；UIFLOW 验证两个独立空白页、9.99 秒不可继续、10 秒可继续与 reduced-motion 0.15 秒门槛 | CAPTURE 两段 silence production surfaces；WAV 静默策略 | 无；不得把故事内 120 秒误写成玩家真实等待时长 |
| LIN-003A | Verified | `lin_scene_3` choice `know` scoped Lin/company effects | CONTENT exact effects/text；FLOW Lin routes | — | 无 |
| LIN-003B | Verified | `lin_scene_3` choice `market` | CONTENT/FLOW exact branch | — | 无 |
| LIN-003C | Verified | `lin_scene_3` choice `delegate` + suspicion flag | CONTENT delegation/effects；FLOW Lin routes | — | 无 |
| LIN-004-GATE | Verified | `src/hiring_director.gd` branch gate author weight `>=60` | FLOW `_test_lin_training_gate_and_last_visit_priority` 59/60 | — | 无 |
| LIN-004A0 | Verified | `src/hiring_content.gd` `lin_scene_4` high-author opening pages | CONTENT required scene/term snapshots；FLOW Lin scene flow | — | 无 |
| LIN-004A1 | Verified | `lin_scene_4` choice `claim`; belief lock 15 | CONTENT exact effect；FLOW priority/permanent-state route | — | 无 |
| LIN-004A2 | Verified | `lin_scene_4` choice `admit`; weekly-review flag/consequence | CONTENT exact effect；FLOW last-visit priority | — | 无 |
| LIN-004A3 | Verified | `lin_scene_4` choice `delegate`; week-31 administrative corpus provenance | CONTENT exact quote；FLOW `_test_lin_values_corpus_provenance` | — | 无 |
| LIN-004A4 | Verified | director deferred flag/release；model permits Lin removal only reason `lin_scene_4` | MODEL Lin guard；FLOW `_test_lin_scene_four_deferred_departure` | — | 无 |
| LIN-004B0 | Verified | `lin_scene_4` low-author/training opening | CONTENT exact content；FLOW training gate | — | 无 |
| LIN-004B1 | Verified | three warm choices share exact morale/Lin-belief resolution | CONTENT three-path effects；FLOW gate/route | — | 无 |
| LIN-004B2 | Verified | director counts `train+large_train>=3`, author `<60`, persisted | FLOW 2/3 and 59/60 boundaries + save | — | 无 |
| LIN-005 | Verified | `docs/product_decisions.md::DEC-005/006`; `src/hiring_content.gd` key `lin_last_visit` priority branches + absence echo | CONTENT no-placeholder content；FLOW `_test_lin_training_gate_and_last_visit_priority` | — | 无；v1 正文已批准 |

### 夜班、对象与终端

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| NIGHT-000 | Verified | `src/night_interaction_state.gd`; `src/hiring_main.gd` click-to-move/map UI | NIGHTSTATE all interaction paths/save；NIGHTUI required API/click-arrival | CAPTURE night openings/interactions | 无 |
| NIGHT-001 | Verified | night state has no chase/timer/failure actor；夜班使用 diegetic ambience，score/异常 cue 关闭 | CONTENT anomaly rules；NIGHTSTATE/NIGHTUI；AUDIO Night 1 HVAC-only、夜班 score 静音与无异常 cue | IDLE 300 idle seconds, tracked state unchanged；WAV night scene previews | 无 |
| NS1-CORRIDOR | Verified | `src/hiring_content.gd::NIGHT_SHIFTS["1"]` corridor；night pass counter/lights | NIGHTSTATE `_test_night_one_corridor_three_real_passes`; NIGHTUI | CAPTURE first/third crossing | 无 |
| NS1-WHITEBOARD | Verified | night-one hotspot `whiteboard` exact scarf-dog/logo lines | CONTENT exact text；NIGHTSTATE/NIGHTUI click route | CAPTURE `night_1_whiteboard_scarf_dog.png` | 无 |
| NS1-PLANT | Verified | `docs/product_decisions.md::DEC-007`; night-one hotspot `plant`, debt-tier variants | CONTENT registry；NIGHTSTATE/NIGHTUI；UIFLOW visual fixture | CAPTURE clear/mid/high plant PNG | 无 |
| NS1-MUG | Verified | `docs/product_decisions.md::DEC-007`; night-one hotspot `mug`, callback flag/NG+ imagery | CONTENT registry/text；NIGHTSTATE click/save | — | 无 |
| NS1-FRIDGE | Verified | night-one hotspot `fridge` exact Aug-3/Aug-19 copy | CONTENT exact-date lint；NIGHTSTATE click/save | — | 无 |
| NS1-END | Verified | `docs/product_decisions.md::DEC-007`; night-one hotspot `corridor_end`, independent reachability | CONTENT registry；NIGHTSTATE/NIGHTUI reachability | — | 无 |
| NS2-PLANT | Verified | night-two hotspot `plant` ratio/14-month rota copy | CONTENT exact terms；NIGHTSTATE `_test_night_two_plant`; NIGHTUI visuals | CAPTURE night-two opening/plant context | 无 |
| NS2-DESK | Verified | night-two `window_desk` state machine + 2024 cup/two-cm replacement | CONTENT exact content；NIGHTSTATE desk sequence/save；NIGHTUI | CAPTURE held/replaced desk cup | 无 |
| NS2-D | Verified | night-two `room_d` phases/projector/light-off state | CONTENT content；NIGHTSTATE room-D sequence/save；NIGHTUI | CAPTURE projector/two-steps/light-off | 无 |
| NS2-TERM | Verified | night-two `terminal` focus/dialogue/Ctrl+C phases | CONTENT exact text；NIGHTSTATE terminal sequence/save；NIGHTUI | CAPTURE unsent/focused/Ctrl+C | 无 |
| NIGHT-RM | Verified | `src/night_interaction_state.gd` exact parser；`src/hiring_main.gd` immediate ending | NIGHTSTATE parser/state；NIGHTUI `_test_terminal_input_and_rm_rf_focus_gate`; FLOW ending route | CAPTURE `ending_rm_rf.png` | 无 |

### 软件界面

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| UI-001 | Verified | `hiring_main.tscn`; `src/hiring_main.gd` dashboard/team/terminal/calendar/announcements/night screens | UIFLOW public UI/full flows；NIGHTUI night UI；S0 | CAPTURE full 81-screen set | 无 |
| UI-002 | Verified | `src/hiring_main.gd` cards/documents/terminal/click interactions | UIFLOW action/event/intranet/board/ending flows；NIGHTUI clicks | CAPTURE software surfaces | 无 |
| UI-003 | Verified | ordinary calendar/team/intranet anomaly surfaces | CONTENT anomaly registry；UIFLOW quiet/window/origin；NIGHTUI D room | CAPTURE calendar/phantom/window | 无 |
| UI-004 | Verified | extra elevator resource uses ordinary calendar button construction | CONTENT anomaly metadata；UIFLOW quiet chronology | PIX 21 个主题采样一致；CAPTURE `calendar_supernatural_resources.png` | 无；无专用 tooltip/动画/主题 |
| UI-005 | Verified | shared room-D id/content across calendar and night map；directory A/B/C copy | CONTENT cross-registry；NIGHTSTATE/NIGHTUI room-D | CAPTURE calendar + room-D | 无 |
| UI-006 | Verified | stable phantom employee id across content queries/UI | CONTENT phantom/report tests；UIFLOW employee desk contract | CAPTURE phantom team/announcement/intranet | 无 |
| UI-007 | Verified | office deterioration renderer；HUD omits debt labels | MODEL hidden-state/tier tests；UIFLOW UI/debt fixture | CAPTURE clear/mid/high debt | 无 |
| UI-008 | Verified | `ANOMALY_REGISTRY` marks window as unique daytime physical exposure | CONTENT external-boundary uniqueness；UIFLOW window state | CAPTURE window sequence | 无 |
| UI-009 | Verified | silent-event metadata/queue suppression；静默事件与异常不自动触发拟音或配乐 cue | CONTENT fixed/silent keys；FLOW silent recording；UIFLOW quiet chronology；AUDIO full-silence/anomaly zero-cue contract | CAPTURE silent-result surfaces；WAV authored-silence previews | 无 |
| UI-010 | Verified | option-voice transform changes label string only | UIFLOW `_test_stage_three_option_voice_surface` | PIX 前后差分：`option_glyph_pixels=2721`、`outside_contract_pixels=0` | 无 |
| UI-011 | Verified | `src/hiring_model.gd::public_state`; `src/hiring_main.gd` HUD fields | MODEL public contract；UIFLOW UI surface | CAPTURE dashboard | 无 |
| UI-012 | Verified | sign mechanical no-op + signature tween/drawing | MODEL sign deep comparison；UIFLOW signature screen | SIG 97 frames/60 FPS；CAPTURE signature complete | 无 |

### 音频

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| AUDIO-001 | Verified | `src/office_audio.gd` 核心 air/keyboard/distant-voices 与地点性 server-fan；Ambience bus | AUDIO 图谱、循环、信号、峰值与 bus 断言 | WAV 5 个独立 ambience stem，RIFF/PCM/非零/频谱 | 无 |
| AUDIO-002 | Verified | `OfficeAudio.set_scene_context` 场景策略 + `HiringMain` 最终场景上下文接线 | AUDIO onboarding/full-silence/room-tone/night/scene context；AUDIOUI 主界面地点、静默页、特殊场景与异常静音接线 | WAV 5 chapter + 13 narrative-scene previews/manifest | 无 |
| AUDIO-003 | Verified | loose/sync keyboard 在作者权重 35–85 等功率交叉 | AUDIO monotonic/equal-power threshold checks | WAV 5 个 threshold target snapshots + 两条键盘源频谱 | 无；跨阈值无 stinger/滤镜冲击/文字说明 |
| AUDIO-004 | Verified | `OfficeAudio` 消费 Chapter 4 的 week 1–8 上下文，逐层抽走人声、空调与松散键盘，最终仅同步键盘；`HiringMain` 传递周次 | AUDIO Chapter 4 周次退场与最终周断言；AUDIOUI Chapter 4 week 1–8 上下文传递与声场逐周退场 | WAV chapter/final-silence preview 与 stem targets | 无 |
| AUDIO-005 | Verified | 非循环物理拟音 allowlist + `HiringMain` direct-action 接线；数值、自动保存、静默与异常无自动 cue | AUDIO one-shot 图谱、headroom、cooldown、mute、unknown/anomaly rejection；AUDIOUI direct-action 接线、静默/异常零 cue、锁定导航零成功 cue；CONTENT silent-event schema | WAV 13 个 Foley-bus one-shot，均非循环 | 无 |
| AUDIO-006 | Verified | 两条 48 秒、长留白、低电平 human/system 原创动机；Music bus；事件/夜班/沉默/异常 duck 或静音 | AUDIO score 信号、长留白、峰值、bus 与 `duck_music` 场景断言 | WAV 2 score stems、13 scene previews、7 个互异 ending mixes、77 spectral rows | 无；禁止章节 stinger、奖励 jingle、移动端 beep 与恐怖揭秘声 |
| AUDIO-007 | Partial | 键盘等功率平滑过渡，作者阶段变化无 cue/stinger/文字通知 | AUDIO monotonic/equal-power thresholds、异常/静默零 cue；UIFLOW quiet chronology | WAV threshold target snapshots + keyboard spectrum | “通关很久后才回想”必须由首次玩家延迟访谈验证 |

### 结局、正文与新周目

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| END-001 | Verified | `src/hiring_model.gd::select_ending` acquisition fallback；`src/hiring_content.gd::ENDINGS["acquihire"]`; DEC-008 approval | MODEL ending boundaries；FLOW all-ending routes；UIFLOW ending playback | CAPTURE `ending_acquihire.png` | 无 |
| END-002 | Verified | cash-zero immediate resolver + `ENDINGS["lights_out"]` | MODEL priority；UIFLOW action/event-choice immediate exhaustion；FLOW routes | CAPTURE `ending_lights_out.png` | 无 |
| END-003 | Verified | capability `>=80 && debt<10` branch + `ENDINGS["independent"]` | MODEL 79/80, 9/10 boundaries；FLOW/UIFLOW ending routes | CAPTURE `ending_independent.png` | 无 |
| END-004 | Verified | author weight `>=100` branch + `ENDINGS["successor"]` | MODEL 99/100/priority；FLOW/UIFLOW | CAPTURE `ending_successor.png` | 无 |
| END-005 | Verified | coherence `<20` branch + approved `ENDINGS["drift"]` | MODEL 19/20；FLOW/UIFLOW；`docs/product_decisions.md::DEC-008` | CAPTURE `ending_drift.png` | 无 |
| END-006 | Verified | exact night command resolver + approved `ENDINGS["rm_rf"]` | NIGHTSTATE/NIGHTUI parser；MODEL/FLOW priority/routes | CAPTURE `ending_rm_rf.png` | 无 |
| END-007 | Verified | `completed_once/second_run` opening path excluded from resolver | MODEL NG+ save；FLOW `_test_ng_plus_is_an_opening_not_an_ending`; UIFLOW NG+ | CAPTURE `ending_second_time.png` + NG+ sequence | 无 |
| END-PRIORITY | Verified | explicit `src/hiring_model.gd::ENDING_PRIORITIES/select_ending`; DEC-008 documented order | MODEL exhaustively enumerates all 32 ending-condition subsets plus cash-exhausted flag collision；FLOW routes all endings | CAPTURE seven endings | 无 |
| END-LIGHTS-COPY | Verified | `src/hiring_content.gd::ENDINGS["lights_out"]` paged copy | CONTENT exact tokens/full text；UIFLOW all ending pages | CAPTURE `ending_lights_out.png` | 无 |
| END-INDEP-COPY | Verified | `ENDINGS["independent"]` with Lin-state-safe variants | CONTENT 11/400/Friday/2:00 tokens；FLOW route consistency；UIFLOW pages | CAPTURE independent | 无 |
| END-SUCCESSOR-COPY | Verified | `ENDINGS["successor"]` paged copy | CONTENT exact Monday/Thursday/review/GPU/“我们” tokens；UIFLOW pages | CAPTURE successor | 无 |
| END-ACQ-COPY | Verified | approved `ENDINGS["acquihire"]`; `docs/product_decisions.md::DEC-008` | CONTENT full content；FLOW/UIFLOW route/playback | CAPTURE acquihire | 无 |
| END-DRIFT-COPY | Verified | approved `ENDINGS["drift"]`; DEC-008 | CONTENT coherence-centered copy；FLOW/UIFLOW | CAPTURE drift | 无 |
| END-RMRF-COPY | Verified | approved `ENDINGS["rm_rf"]`; DEC-008 | CONTENT no-reveal copy；NIGHTSTATE/NIGHTUI trigger；UIFLOW pages | CAPTURE rm_rf | 无 |
| END-COMPANY | Verified | ending token interpolation from saved `company_name` | MODEL identity/save；UIFLOW `_test_all_ending_playback_surfaces` custom fixture | CAPTURE seven custom-company ending surfaces | 无 |
| NGP-001 | Verified | `src/hiring_main.gd` meta save `completed_once`; model `second_run` | MODEL save；FLOW NG+ route；UIFLOW `_test_second_time_and_ending_resume` | CAPTURE NG+ captures | 无 |
| NGP-002 | Verified | NG+ opening cup/date/team state | CONTENT exact 2024/date copy；FLOW/UIFLOW NG+ | CAPTURE `ng_plus_cup_present.png` | 无 |
| NGP-003 | Verified | NG+ cup held/replaced + Lin question states | CONTENT text；UIFLOW NG+ state machine | CAPTURE held/question | 无 |
| NGP-004 | Verified | exact two fixed choices, delegation exception whitelist | CONTENT `_test_all_decisions_have_delegation`; FLOW NG+ | CAPTURE Lin question | 无 |
| NGP-005 | Verified | convergent answers and window-desk placement state | FLOW NG+ equivalence；UIFLOW state machine | CAPTURE answered/window-desk | 无 |
| NGP-006 | Verified | NG+ transitions into normal chapter-zero campaign and remains unexplained | FLOW `_test_ng_plus_is_an_opening_not_an_ending`; UIFLOW resume | CAPTURE NG+ sequence | 无 |

### 玩家验收门槛

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| ACCEPT-001 | Unverified | Debt realization/visual systems implemented | 自动化与开发捕获不能替代首玩反应 | — | 缺合格首玩录像时间戳、think-aloud、行为日志与访谈原话 |
| ACCEPT-002 | Unverified | AI delegation benefits/opportunities implemented | MODEL/CONTENT/FLOW only preflight mechanics | — | 缺首用后再次自愿使用率、样本定义与访谈 |
| ACCEPT-003 | Unverified | Stage-three voice implementation exists | UIFLOW verifies rewrite, not discovery rate | — | 缺首玩样本量、15%–30% 发现率、置信区间和录像 |
| ACCEPT-004 | Unverified | LIN-004A3/A4 departure route implemented | FLOW verifies route, not player desire | — | 缺触发该路线玩家的即时行为、读档/重开记录和访谈 |
| ACCEPT-005 | Unverified | Tone/content/game completion implemented | 自动化不能验证工作经历联想 | — | 缺完成结局后的开放访谈逐字编码；不得以开发者体感代替 |

## 首玩、时长与主观门槛声明

矩阵没有独立的 `PLAYER-*` 或 `TIME-*` ID。相关门槛已落在其唯一主行：`DEC-011`（五章首玩中位时长）和 `FUND-002`（约 20 分钟自行发现融资规则）均为 `Unverified`；`LIN-002` 已按 DEC-026 明确区分两段 story-time 120 秒与普通模式真实 10 秒/降低动态 0.15 秒，因此是确定性演出契约而非玩家时长研究；`ACCEPT-001`–`ACCEPT-005` 全部为 `Unverified`。章节标题中的 15/35/50/60/40 分钟由 `DEC-011` 统一承接，未用开发者速通、自动模拟、截图或 5 分钟 idle 录像冒充玩家时长。

主观体验要求也未批量关闭：`TONE-001/002`、`WORLD-001/002/012`、`SURREAL-003/010`、`DEBT-003`、`WRITE-003/004/010`、章目标、`ORIGIN-001`、`AUDIO-007` 等行明确保留人工或玩家门槛。`docs/product_decisions.md` 已书面批准 DEC-006、DEC-007、DEC-008 的 v1 文案，并由 DEC-026 锁定 LIN-002 的故事时间/真实时间映射；对应功能行不再虚构“待审批”缺口。

## ID 完整性自动检查

以下 PowerShell 只读取 Markdown 表格的**第一列**，因此不会把正文中的范围简写（例如 `LIVE-001..006`）、交叉引用或矩阵末尾示例重复计数：

```powershell
$pattern = '^\|\s*([A-Z0-9]+(?:-[A-Z0-9]+)+)\s*\|'
$matrixIds = @(Get-Content docs/requirements_matrix.md | ForEach-Object {
  if ($_ -match $pattern) { $matches[1] }
})
$ledgerIds = @(Get-Content docs/requirement_evidence_ledger.md | ForEach-Object {
  if ($_ -match $pattern) { $matches[1] }
})
$missing = @($matrixIds | Where-Object { $ledgerIds -notcontains $_ })
$extra = @($ledgerIds | Where-Object { $matrixIds -notcontains $_ })
$duplicates = @($ledgerIds | Group-Object | Where-Object Count -ne 1)
"MATRIX_IDS=$($matrixIds.Count)"
"MATRIX_UNIQUE=$(@($matrixIds | Sort-Object -Unique).Count)"
"LEDGER_IDS=$($ledgerIds.Count)"
"LEDGER_UNIQUE=$(@($ledgerIds | Sort-Object -Unique).Count)"
"MISSING=$($missing.Count)"
"EXTRA=$($extra.Count)"
"DUPLICATE_GROUPS=$($duplicates.Count)"
if ($missing.Count -or $extra.Count -or $duplicates.Count) { exit 1 }
```

2026-08-29 当前工作区实跑输出：

```text
MATRIX_IDS=272
MATRIX_UNIQUE=272
LEDGER_IDS=272
LEDGER_UNIQUE=272
MISSING=0
EXTRA=0
DUPLICATE_GROUPS=0
```
