# 《我们正在招人》最终需求证据台账

审计基线：`docs/requirements_matrix.md`（2026-08-29 工作区版本）。本表只评价当前工作区可证明的事实；`Verified` 不替代策划明确要求的首次玩家研究。

> **候选证据已刷新：** 下列回归、81 条唯一捕获、像素契约、音频、动画和五分钟空闲证据均在最终制作源码冻结后重新生成；只有首次玩家研究仍在本表中保持 `Unverified`。

## 证据索引

| 代号 | 精确证据 |
|---|---|
| STOR100 | `tests/hiring_storage_test.gd`；`artifacts/hiring_storage_test.stdout.log`：`HIRING_STORAGE_TESTS_PASS: 100 checks` |
| M1940 | `tests/hiring_model_test.gd`；`artifacts/hiring_model_test.stdout.log`：`HIRING_MODEL_TESTS_PASS: 1940 checks` |
| C2795 | `tests/hiring_content_test.gd`；`artifacts/hiring_content_test.stdout.log`：`HIRING_CONTENT_TESTS_PASS: 2795 checks` |
| F2117 | `tests/hiring_flow_test.gd`；`artifacts/hiring_flow_test.stdout.log`：`HIRING_FLOW_TESTS_PASS: 2117 checks` |
| U622 | `tests/hiring_ui_flow_test.gd`；`artifacts/hiring_ui_flow_test.stdout.log`：`HIRING_UI_FLOW_TESTS_PASS: 622 checks` |
| N173 | `tests/night_interaction_state_test.gd`；`artifacts/night_interaction_state_test.stdout.log`：`NIGHT_INTERACTION_STATE_TESTS_PASS: 173 checks` |
| NU115 | `tests/hiring_night_ui_integration_test.gd`；`artifacts/hiring_night_ui_integration_test.stdout.log`：`HIRING_NIGHT_UI_INTEGRATION_TESTS_PASS: 115 checks` |
| A275 | `tests/hiring_audio_test.gd`；`artifacts/hiring_audio_test.stdout.log`：`HIRING_AUDIO_TESTS_PASS: 275 checks`，stderr 为空 |
| AINT84 | `tests/hiring_audio_integration_test.gd`；`artifacts/hiring_audio_integration_test.stdout.log`：`HIRING_AUDIO_INTEGRATION_TESTS_PASS: 84 checks`，stderr 为空 |
| SEM1549 | `tests/hiring_semantic_audit_test.gd`；`artifacts/hiring_semantic_audit_test.stdout.log`：`HIRING_SEMANTIC_AUDIT_PASS: 1549 checks` |
| FOCUS19 | `tests/hiring_focus_router_test.gd`；`artifacts/hiring_focus_router_test.stdout.log`：`HIRING_FOCUS_ROUTER_TESTS_PASS: 19 checks` |
| GAMEPAD76 | `tests/hiring_gamepad_contract_test.gd`；`artifacts/hiring_gamepad_contract_test.stdout.log`：`HIRING_GAMEPAD_CONTRACT_TESTS_PASS: 76 checks` |
| ART364 | `tests/hiring_art_asset_test.gd`；`artifacts/hiring_art_asset_test.stdout.log`：`HIRING_ART_ASSET_TESTS_PASS: 364 checks` |
| ASSET | `assets/hiring_assets.json`：20 个受管资产、77,523,531 bytes；ART364 验证运行时文件头、尺寸、透明通道、授权、哈希与加载 |
| S0 | `artifacts/main_smoke.stdout.log`：隔离存储、场景初始化和 onboarding 渲染 PASS；stderr 为空 |
| V81 | `tests/hiring_visual_capture.gd` 的显式 81-stem 清单；`artifacts/visual_capture_final.stdout.log` 中 81 条唯一 `CAPTURED:` 与 `HIRING_VISUAL_CAPTURE_PASS: 81 captures`；候选 PNG 仅为 `artifacts/screenshots/` 根目录与清单完全相等的 81 张，`archive/` 不属于候选证据 |
| PIX | `tests/verify_ui_visual_contract.py` 先强制根截图目录无 missing/extra PNG，再核验选项仅文字变化、普通电梯按钮同主题、社交心形三阶段像素证据；`artifacts/ui_visual_contract.log`：`option_glyph_pixels=2721`、`extra_floor_pixels=1790`、`social_heart_pixels=[64, 662, 64]`、`capture_root_pngs=81`、`outside_contract_pixels=0`、`floor_theme_samples=21`、PASS |
| SIG | `artifacts/signature_motion.avi`；`signature_motion.stdout.log`：97 帧、60 FPS、PASS；`signature_motion.stderr.log` 为空 |
| IDLE | `artifacts/night_idle_5min.avi`；`night_idle_5min.stdout.log`：310 帧、1 FPS、5:10、300 idle frames 零状态变化、PASS；stderr 为空 |
| WAV | `artifacts/audio_evidence/manifest.json`、`spectrum.csv`、45 个 WAV；7 continuous（5 ambience + 2 score）、13 foley、25 mix refs（含 13 scene、7 endings）、77 spectral rows；manifest SHA-256 `0ADF16FEB36FA39A6C38FB863BB7F951D6FCDEF03A9F88E1341BDDD91F51A1A0` |

当前自动化总计：十二套功能/语义回归 `100 + 2,795 + 1,940 + 2,117 + 275 + 84 + 19 + 76 + 622 + 173 + 115 + 1,549 = 9,865 checks`。运行时美术资产再计 `364 checks`，当前总计 **10,229 checks**。状态含义：`Verified`=客观要求已有同范围实现与证据；`Partial`=复合要求仅客观部分闭合或仍需人工主观审批；`Unverified`=权威玩家/时间证据不存在。

实现列中的未限定事件、选项、热点和结局 key 均指 `src/hiring_content.gd` 的精确 key；模型机制、排程/分支、主界面、夜班状态、音频图分别默认定位到 `src/hiring_model.gd`、`src/hiring_director.gd`、`src/hiring_main.gd`、`src/night_interaction_state.gd`、`src/office_audio.gd`。行内另列文件时，以行内定位为准。

## 逐项台账

### 规范决议

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| DEC-001 | Verified | `src/hiring_model.gd` 七状态字段、`public_state()` | M1940 `_test_identity_chapters_and_public_contract` | V81 `week_01_dashboard.png` | 无 |
| DEC-002 | Verified | `src/hiring_model.gd::end_week`；`DEBT_GAP_RATE/DEBT_REPAY_RATE` | M1940 `_test_weekly_decay_gap_debt_and_repayment` | — | 无 |
| DEC-003 | Verified | `src/hiring_content.gd` keys `first_investor_meeting`,`preseed_close`；`src/hiring_director.gd` | F2117 `_test_preseed_close_fundraise_mechanics` | V81 `event_first_investor_meeting_cafe.png` | 无 |
| DEC-004 | Verified | `src/hiring_content.gd` key `seed_demo_unlock`；used/unused routes | F2117 `_test_never_used_demo_video_route`,`_test_used_demo_video_route` | — | 无；行为诱惑另见 ACCEPT-002 |
| DEC-005 | Verified | `src/hiring_content.gd` Lin/absence keys；`src/hiring_director.gd::_prepare_lin_last_visit` | F2117 `_test_lin_absent_echo_choices`,`_test_lin_training_gate_and_last_visit_priority` | — | 无 |
| DEC-006 | Verified | `docs/product_decisions.md::DEC-005/006`; `src/hiring_content.gd` key `lin_last_visit` 的在场/缺席分支 | C2795 `_test_required_events_scenes_and_terms`; F2117 `_test_lin_training_gate_and_last_visit_priority` | — | 无；v1 文案已批准且可达性已验证 |
| DEC-007 | Verified | `docs/product_decisions.md::DEC-007`; `src/hiring_content.gd::NIGHT_SHIFTS["1"]` 五热点 | C2795 `_test_night_shifts_and_exact_terminal_marker`; N173/NU115 夜班一测试 | V81 夜班一截图组 | 无；绿萝/马克杯 v1 文案已批准 |
| DEC-008 | Verified | `src/hiring_model.gd::ENDING_PRIORITIES/select_ending`; `src/hiring_content.gd::ENDINGS` | M1940 `_test_all_seven_endings_and_priority`; F2117 `_test_all_endings_are_routable_and_gated` | V81 七结局 PNG | 无 |
| DEC-009 | Verified | `src/hiring_model.gd::cash_weeks/salary_burn_modifier/public_state/end_week` | M1940 cash/burn/save tests；F2117 LIVE cash routes | V81 HUD/结局截图 | 无 |
| DEC-010 | Verified | `src/hiring_model.gd` employee schema、`_refresh_company_morale`、team size | M1940 employee/action/staffing tests | V81 team/Chen screenshots | 无 |
| DEC-011 | Unverified | 章节周数在 `src/hiring_model.gd::CHAPTERS`；没有玩家时长数据 | M1940 `_test_full_chapter_clock` 仅验证周数，不验证分钟 | — | 首轮玩家各章中位时长与产品容差尚未采集/批准 |
| DEC-012 | Verified | `src/hiring_director.gd` Chen +3 周 callback 状态 | F2117 `_test_chen_xiaoyu_three_week_callback` | — | 无 |
| DEC-013 | Verified | `src/hiring_model.gd` `eval`/`capability_revealed`; HUD capability | M1940 `_test_every_action_and_declared_effect`; U622 UI contract | V81 dashboard | 无 |
| DEC-014 | Verified | `src/hiring_model.gd` exclusive interview threshold 55/chance .45/saved RNG | M1940 `_test_exclusive_interview_probability_and_replay` | — | 无 |
| DEC-015 | Verified | `src/hiring_content.gd` keys `lin_scene_3`,`lin_scene_4`; scoped choice effects | C2795 Lin contracts；F2117 Lin branch tests | — | 无 |
| DEC-016 | Verified | `src/hiring_model.gd` key `sign` and AI exception | M1940 `_test_ai_delegation_dominates_every_manual_action_except_sign` | SIG；V81 `signature_complete.png` | 无 |
| DEC-017 | Verified | `src/hiring_content.gd` delegation exception registry/CH0-W02/NG+ choices | C2795 `_test_all_decisions_have_delegation`; F2117 NG+ | V81 NG+ sequence | 无 |
| DEC-018 | Verified | `src/hiring_model.gd::VALUES_CORPUS_BODIES[1]`; ending text | M1940 `_test_history_memory_and_save_round_trip`; C2795 ending lint | V81 `ending_lights_out.png` | 无 |
| DEC-019 | Verified | `src/hiring_content.gd::FIXED_EVENTS/SILENT_EVENTS`; `src/hiring_director.gd` silent recording | C2795 `_test_chapters_and_fixed_week_keys`; F2117 `_test_fixed_priority_silent_recording_and_special_effects` | — | 无 |
| DEC-020 | Verified | `src/hiring_director.gd` Lin training gate `train+large_train>=3`, author `<60` | F2117 `_test_lin_training_gate_and_last_visit_priority` | — | 无 |
| DEC-021 | Verified | `src/hiring_model.gd` layoffs, `LAYOFF_EMPLOYEE_COUNT`, burn floor | M1940 `_test_layoff_contract_and_burn_floor` | — | 无 |
| DEC-022 | Verified | `src/hiring_main.gd` internal/window workstation split and payroll display | U622 `_test_employee_desk_and_window_population_contract` | V81 window open/closed/reopened | 无 |

### 世界、基调与超现实规则

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| WORLD-001 | Verified | `src/hiring_content.gd` 开场、咖啡馆、外部地点与日期文本 | C2795 world/anomaly tests；SEM1549 全 corpus；`docs/editorial_review.md` 联合审读 | V81 `opening_event.png`,`event_first_investor_meeting_cafe.png` | 无；内部时代/湾区语义审读已签核 |
| WORLD-002 | Verified | `src/hiring_content.gd` 模型输出/禁用主题 corpus | C2795 world/token/scene tests；SEM1549 全 corpus；`docs/editorial_review.md` | V81 多阶段 UI | 无；现实能力与无觉醒/奇点边界已签核 |
| WORLD-003 | Verified | `src/hiring_content.gd::ANOMALY_REGISTRY` location/source 字段 | C2795 `_test_anomaly_registry_and_external_boundary` | V81 正常咖啡馆与办公室异常对照 | 无 |
| WORLD-004 | Verified | `src/hiring_model.gd::company_name/to_save/from_save`; ending token injection | M1940 identity/save/endings；U622 `_test_all_ending_playback_surfaces` | V81 七结局 PNG | 无 |
| WORLD-005 | Verified | `src/hiring_model.gd::VALUES_CORPUS_BODIES[1]`; `src/hiring_content.gd` origin/endings | M1940 values corpus/save；C2795 origin/endings | V81 opening/origin/lights-out | 无 |
| WORLD-006 | Verified | `src/hiring_model.gd::CHAPTERS[*].model_name`; chapter content nickname rules | M1940 chapter names；C2795 `_test_world_stats_stages_and_memories` | V81 dashboard/intranet finale | 无 |
| WORLD-007 | Verified | `src/hiring_director.gd` chapter-four silent beat；notification queue stays empty | F2117 `_test_final_silence_defers_modal_queue`; U622 `_test_quiet_chronology_surfaces` | V81 `intranet_finale.png` | 无 |
| WORLD-008 | Verified | `src/hiring_main.gd` software-shell rendering；无主角 identity 字段/portrait | M1940 identity schema；U622 main UI traversal | V81 81-screen set | 无 |
| WORLD-009 | Verified | `src/hiring_content.gd` anomaly reaction/night desk copy；无调查 action | C2795 anomaly/night registry；N173 night paths | V81 night desk/window sequence | 无 |
| WORLD-010 | Verified | `src/hiring_content.gd` key `live_demo` AI branch exact “我们”停顿线索 | C2795 required terms；F2117 live-demo routes | — | 无 |
| WORLD-011 | Verified | `src/hiring_model.gd` Lin employee；`src/hiring_content.gd` Lin scene registry | C2795 employee/Lin registry；F2117 full campaign | V81 team screenshots | 无 |
| WORLD-012 | Verified | `src/hiring_content.gd` Lin dialogue corpus and metadata | C2795 `_test_lin_tone_lint`；SEM1549；`docs/editorial_review.md::WORLD-012` | V81 林越事件与肖像状态 | 无；v1 角色语气已通过编辑审读 |
| WORLD-013 | Verified | `src/hiring_content.gd` `lin_scene_1..4`,`lin_last_visit`,`lin_absent_echo` | C2795 reachability；F2117 Lin presence/absence routes | — | 无 |
| TONE-001 | Verified | `src/hiring_content.gd` office/night copy；`src/office_audio.gd` 克制 ambience/score/foley 图谱 | C2795 anomaly lint；SEM1549；A275 低电平稀疏动机、物理拟音余量与异常/静默无 cue；N173/NU115 idle invariants；`docs/editorial_review.md` | IDLE；WAV；V81 debt/night captures | 无；内部联合预检通过，首玩联想另由 ACCEPT-005 承接 |
| TONE-002 | Unverified | 目标由当前内容支持，但无玩家研究 | 自动化不能验证“认出来了” | — | 必须由 ACCEPT-005 首次玩家访谈验证 |
| SURREAL-001 | Verified | `src/hiring_content.gd::ANOMALY_REGISTRY` leased-office locations | C2795 `_test_anomaly_registry_and_external_boundary` | V81 咖啡馆/办公室对照 | 无 |
| SURREAL-002 | Verified | `src/night_interaction_state.gd` 无 agent/chase；anomaly behavior registry | C2795 anomaly rules；N173/NU115 | IDLE 300 秒零状态变化 | 无 |
| SURREAL-003 | Verified | `src/hiring_content.gd` anomalies/endings 无 reveal 类型 | C2795 semantic-token checks；SEM1549 全 corpus；`docs/editorial_review.md` | IDLE；V81 七结局 | 无；内部“永不解释”语义审读已签核 |
| SURREAL-004 | Verified | `src/hiring_content.gd` window/room-D administrative reactions | C2795 anomaly registry；U622 curtain state machine；N173 room-D | V81 curtain/room-D captures | 无 |
| SURREAL-005 | Verified | `src/hiring_content.gd::ANOMALY_REGISTRY[*].administrative_source` | C2795 `_test_anomaly_registry_and_external_boundary` | V81 anomaly surfaces | 无 |
| SURREAL-006 | Verified | `src/hiring_main.gd` final window population；`src/hiring_model.gd` chapter-four target | M1940 staffing；U622 desk/window contract | V81 `team_finale_window_open.png` | 无 |
| SURREAL-007 | Verified | `src/hiring_content.gd` room-D calendar/night keys；night interaction state | C2795 night/calendar；N173/NU115 room-D sequence | V81 calendar + room-D captures | 无 |
| SURREAL-008 | Verified | `src/hiring_content.gd` `series_a_expansion`; `src/hiring_main.gd` elevator resource UI | F2117 silent event；U622 quiet chronology | V81 `calendar_supernatural_resources.png` | 无 |
| SURREAL-009 | Verified | `src/hiring_content.gd` phantom employee/report keys incl. report 91 | C2795 `_test_intranet_documents_and_report_91`; F2117 silent events | V81 phantom team/announcement/intranet | 无 |
| SURREAL-010 | Verified | `src/hiring_content.gd::ANOMALY_REGISTRY`; UI/night implementations | C2795 anomaly lint；SEM1549；N173/NU115；`docs/editorial_review.md` | IDLE；V81 anomalies | 无；内部叙事/美术联合审读已签核 |

### 核心循环、状态、注意力与作者阶段

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| LOOP-001 | Verified | `src/hiring_model.gd` action/economy/writer-stage loop；`src/hiring_director.gd` campaign flow | M1940 full clock/stages；F2117 `_test_complete_campaign` 两策略 | V81 dashboard→finale | 无 |
| STAT-001 | Verified | `src/hiring_model.gd` 七项状态与 save schema | M1940 identity/boundary/save tests | V81 dashboard | 无 |
| STAT-002 | Verified | `src/hiring_model.gd::public_state/end_week/apply_effects` cash-percent/burn/runway | M1940 cash/burn；F2117 LIVE cash；U622 cash exhaustion | V81 dashboard/lights-out | 无 |
| STAT-003 | Verified | `src/hiring_model.gd` compute gates/costs；`src/hiring_main.gd` HUD disabled copy | M1940 action contracts；U622 `_test_compute_unavailable_copy` | V81 `action_large_train_compute_blocked.png` | 无 |
| STAT-004 | Verified | `src/hiring_model.gd::apply_effects/public_state` 0–100 clamps | M1940 action/fixed-effect/boundary tests | V81 dashboard | 无 |
| STAT-005 | Verified | `src/hiring_model.gd::public_state` omits debt/author；`src/hiring_main.gd` HUD | M1940 public contract；U622 UI contract | V81 full screenshot set | 无 |
| STAT-006 | Verified | `src/hiring_model.gd::end_week` post-decay gap formula | M1940 `_test_weekly_decay_gap_debt_and_repayment` | — | 无 |
| FUND-001 | Verified | `src/hiring_model.gd::_fundraising_cash_gain`; event funding branches | M1940 `_test_fundraising_only_reads_narrative`; F2117 investor routes | V81 investor café | 无 |
| FUND-002 | Unverified | Mechanics/content avoid explicit tutorial disclosure | C2795/F2117 only prove rule/content, not discovery time | — | 首次玩家约 20 分钟发现规则的时间戳与访谈尚无 |
| NARR-001 | Verified | `src/hiring_model.gd::end_week` fixed -2 | M1940 weekly decay/full clock | — | 无 |
| DEBT-001 | Verified | `src/hiring_model.gd::office_deterioration_tier`; `src/hiring_main.gd` office visual states | M1940 tier boundaries；U622 visual state contract | V81 `office_debt_clear/mid/high.png` | 无 |
| DEBT-002 | Verified | `src/hiring_model.gd::_update_fulfillment_pressure`; event pool | M1940 `_test_office_deterioration_and_fulfillment_pressure`; C2795 event registry | — | 无 |
| DEBT-003 | Partial | `src/hiring_model.gd` repayment/train/eval mechanics | M1940 debt repayment/training/eval tests | — | “训练体感慢贵无聊、逊于发推”仍需玩家/平衡 QA |
| ATT-001 | Verified | `src/hiring_model.gd::begin_week/can_act/perform_action` | M1940 `_test_attention_and_chapter_four_reversal` | V81 week-one dashboard | 无 |
| ATT-002 | Verified | `src/hiring_model.gd::can_act` 3 manual + exactly one delegation；`src/hiring_main.gd` five-card pool | M1940 attention arithmetic/save；U622 `_test_action_pool_surface_contract`,`_test_stage_one_ai_response_and_action_ceiling` | V81 dashboard | 无 |
| ATT-003 | Verified | `src/hiring_model.gd::CHAPTER_FOUR_ACTIONS`; writer stage 5 | M1940 chapter-four reversal/stage five；U622 action pool | V81 intranet/signature/finale | 无 |
| IDLE-001 | Verified | `src/hiring_model.gd` `do_nothing`; pool builder | M1940 action contract；U622 week-one/action pool | V81 week-one dashboard | 无 |
| WRITE-001 | Verified | `src/hiring_content.gd` choices + delegation exception registry | C2795 `_test_all_decisions_have_delegation`; F2117 choice coverage | V81 event/NG+/board surfaces | 无 |
| WRITE-002 | Verified | `src/hiring_model.gd::perform_action/_apply_ai_advantage`; sign exception | M1940 `_test_ai_delegation_dominates_every_manual_action_except_sign` | SIG for sign | 无 |
| WRITE-003 | Verified | Generic AI utility in `src/hiring_model.gd`; authored AI effects in content；`read_intranet` 以节省 1 注意力作为“少一件烦心事”，不虚构现金收益 | M1940 all-action dominance；C2795/F2117 all AI choices；SEM benefit-direction audit | V81 委托结果与行动表面 | 无；“是否再次主动使用”仍单独由 ACCEPT-002 验证 |
| WRITE-004 | Verified | `author_weight` stages + downstream Lin/identity costs | M1940 stage tests；F2117 Lin/complete campaigns；SEM1549；`docs/editorial_review.md::WRITE-004` | V81 录像、起源、董事会与结局链 | 无；v1 产品/叙事审读通过 |
| WRITE-005 | Verified | `src/hiring_main.gd` stage-one visible response exact phrase | U622 `_test_stage_one_ai_response_and_action_ceiling`; C2795 phrase corpus | — | 无 |
| WRITE-006 | Verified | `src/hiring_model.gd::begin_week` stage-two unsolicited line | M1940 `_test_writer_stages_and_autonomy` | — | 无 |
| WRITE-007 | Verified | `src/hiring_main.gd::_choice_display_label`; option voice flag | M1940 stage threshold；U622 `_test_stage_three_option_voice_surface` | — | 发现率另见 ACCEPT-003 |
| WRITE-008 | Verified | `src/hiring_model.gd::_run_stage_four_administration` | M1940 `_test_writer_stages_and_autonomy` | — | 无 |
| WRITE-009 | Verified | `src/hiring_model.gd::_run_stage_five_autonomy`; chapter-four attention | M1940 stage-five finance/hire/layoff/cap replacement；F2117 stage-five start | V81 finale surfaces | 无 |
| WRITE-010 | Verified | `src/hiring_main.gd::_choice_display_label` punctuation/length transform | U622 `_test_stage_three_option_voice_surface` | PIX 同界面前后差分：主题外像素变化为 0 | 无 |

### 行动池

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| ACT-N01 | Verified | `src/hiring_model.gd::_resolve_action("tweet")` | M1940 `_test_every_action_and_declared_effect`,`_test_ranged_rolls_unlock_weeks_and_save_state` | — | 无 |
| ACT-N02 | Verified | `src/hiring_model.gd::_resolve_action("tech_blog")`, threshold `<40` | M1940 action matrix + 39.999/40 boundary | — | 无 |
| ACT-N03 | Verified | `src/hiring_model.gd::_resolve_action("podcast")` | M1940 action matrix | — | 无 |
| ACT-N04 | Verified | `src/hiring_model.gd::_resolve_action("demo_video")`; unlock registry | M1940 action/unlock；F2117 used/unused demo routes | — | 无 |
| ACT-N05 | Verified | `src/hiring_model.gd::_resolve_action("conference_talk")` | M1940 action/employee delta matrix | — | 无 |
| ACT-N06 | Verified | `src/hiring_model.gd::_resolve_action("manifesto")`; week-2 gate | M1940 action/unlock/clamp matrix | — | 无 |
| ACT-N07 | Verified | `src/hiring_model.gd::_resolve_action("exclusive_interview")` | M1940 55/55.001, fixed seeds, save replay | — | 无 |
| ACT-C01 | Verified | `src/hiring_model.gd::_resolve_action("train")` | M1940 range/resource/action tests | — | 无 |
| ACT-C02 | Verified | `src/hiring_model.gd` `clean_data`/`training_boost_uses` | M1940 `_test_training_pipeline_and_contract_block`; save tests | — | 无 |
| ACT-C03 | Verified | `src/hiring_model.gd` `eval`/`capability_revealed` | M1940 action matrix + flag save | V81 dashboard | 无 |
| ACT-C04 | Verified | `src/hiring_model.gd` `large_train`, compute cost 8 | M1940 action/range/resource gates；U622 unavailable copy | V81 `action_large_train_compute_blocked.png` | 无 |
| ACT-C05 | Verified | `src/hiring_model.gd` `recruit_expert`/`_next_candidate(true)` | M1940 action/employee effects | — | 无 |
| ACT-C06 | Verified | `src/hiring_model.gd::_resolve_action("alignment_week")` | M1940 action matrix | — | 无 |
| ACT-T01 | Verified | `src/hiring_director.gd` candidate event/selection；candidate schema | F2117 `_test_hiring_candidate_identity_and_single_hire`,`_test_hiring_delegate_selects_visible_best_candidate` | — | 无 |
| ACT-T02 | Verified | `src/hiring_director.gd` one-on-one target/listen/solve rotation | F2117 `_test_one_on_one_fact_rotation_and_solve_scope` | V81 team UI | 无 |
| ACT-T03 | Verified | `src/hiring_model.gd` `all_hands`; `src/hiring_director.gd` promise event | M1940 action contradiction；F2117 `_test_all_hands_decision_and_promise_callback` | — | 无 |
| ACT-T04 | Verified | `src/hiring_model.gd::record_values_document` | M1940 values corpus/history/save；C2795 content | V81 origin/intranet | 无 |
| ACT-T05 | Verified | `src/hiring_model.gd::_resolve_action("team_building")` | M1940 exact morale/belief and zero cash cost | — | 无 |
| ACT-T06 | Verified | `src/hiring_model.gd` `raise_salary` + `salary_burn_modifier` | M1940 action matrix/burn mechanics | — | 无 |
| ACT-T07 | Verified | `src/hiring_model.gd` layoffs six non-Lin/burn/debt/belief | M1940 `_test_layoff_contract_and_burn_floor`; F2117 layoff routes | — | 无 |
| ACT-O01 | Verified | `src/hiring_model.gd::_resolve_action("buy_compute")` | M1940 exact cash/compute and gate | — | 无 |
| ACT-O02 | Verified | `src/hiring_model.gd` fundraising narrative-only function | M1940 `_test_fundraising_only_reads_narrative` | V81 investor café | 无 |
| ACT-O03 | Verified | `src/hiring_model.gd` contract effects/training block | M1940 `_test_training_pipeline_and_contract_block`; F2117 cash-crisis routes | — | 无 |
| ACT-O04 | Verified | `src/hiring_model.gd::_resolve_action("do_nothing")` | M1940 action matrix/attention; U622 pool | V81 dashboard | 无 |
| ACT-F01 | Verified | `src/hiring_model.gd` sign zero-effect branch；`src/hiring_main.gd` signature animation | M1940 deep no-effect exception；U622 screen flow | SIG；V81 `signature_complete.png` | 无 |
| ACT-F02 | Verified | `src/hiring_model.gd` `read_intranet`; `src/hiring_main.gd` intranet surface | C2795 `_test_intranet_documents_and_report_91`; U622 origin/finale UI | V81 intranet/origin/report captures | 无 |
| ACT-F03 | Verified | `src/hiring_model.gd::can_act("one_on_one")` employee-count gate | M1940 action availability；F2117 one-on-one | — | 无 |
| ACT-F04 | Verified | `src/hiring_model.gd` chapter-four `do_nothing` | M1940 action matrix/chapter-four pool | — | 无 |

### 员工、见证与记忆

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| EMP-001 | Verified | `src/hiring_model.gd::_make_employee` name/skill/morale/belief schema | M1940 employee/save tests；F2117 candidate tests | V81 team screenshots | 无 |
| EMP-002 | Verified | `src/hiring_model.gd` centralized debt tiers/erosion/departure tables | M1940 `_test_employee_debt_erosion_contract` boundaries/multiweek/witness/save | — | 无 |
| EMP-003 | Verified | `src/hiring_model.gd` `witnessed` set and departure variants | M1940 `_test_employees_witness_depart_and_remember`; F2117 witnessed resignation | — | 无 |
| EMP-004 | Verified | `src/hiring_content.gd` Chen template；`src/hiring_main.gd` three-cup desk | C2795 `_test_employees_and_chen_cups`; U622 desk contract | V81 Chen before/active/after captures | 无 |
| EMP-005 | Verified | `src/hiring_content.gd` Chen four copy keys；director departure routing | C2795 employee copy snapshots；F2117 `_test_chen_xiaoyu_runtime_copy_and_clean_resignation`,`_test_witnessed_resignation_and_one_on_one_tie_break` | V81 Chen states | 无 |
| MEM-001 | Verified | `src/hiring_model.gd::memory/history/to_save/from_save` | M1940 `_test_history_memory_and_save_round_trip`; F2117 save | — | 无 |
| MEM-002 | Verified | `src/hiring_director.gd` promise week/like count and layoff-open callback | F2117 `_test_all_hands_decision_and_promise_callback`,`_test_layoff_promise_copy_routes` | — | 无 |
| MEM-003 | Verified | `src/hiring_director.gd` live-demo used/unused preparation | F2117 `_test_never_used_demo_video_route`,`_test_used_demo_video_route` | — | 无 |
| MEM-004 | Verified | `src/hiring_model.gd` missed-meal durable due state；director Friday callback | M1940 `_test_cross_week_memory_markers`; F2117 `_test_missed_meal_callback_is_a_friday_memory` | — | 无 |
| MEM-005 | Verified | `src/hiring_director.gd` Chen layoff week +3 data-quality callback | F2117 `_test_chen_xiaoyu_three_week_callback` | — | 无 |
| MEM-006 | Verified | `src/hiring_model.gd` permanent values corpus v3；internal document generator | M1940 values history/save；C2795 intranet docs；F2117 corpus provenance | V81 origin/intranet | 无 |
| MEM-007 | Verified | `src/hiring_model.gd::begin_week` never-delegated flag/question | M1940 stage/chapter-four test；C2795 question text；F2117 full campaign | — | 无 |

### 第零章与第一章

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| CH0-000 | Partial | `src/hiring_content.gd` garage tutorial + `lin_scene_1` | C2795 fixed keys；F2117 opening/full campaign；U622 new-company flow | V81 opening/week-one | “让玩家喜欢林越”与教程完成率需首次玩家数据 |
| CH0-OPEN | Verified | `src/hiring_content.gd` key `opening`; `src/hiring_main.gd` company-name rendering | C2795 required terms；U622 `_test_new_company_opening_action_and_save` | V81 `opening_event.png`,`onboarding.png` | 无 |
| CH0-W01 | Verified | `src/hiring_model.gd::begin_week`; UI chapter-zero pool | M1940 attention；U622 action-pool/new-company tests | V81 `week_01_dashboard.png` | 无 |
| CH0-W02 | Verified | `src/hiring_content.gd` key `model_first_sentence` | C2795 exact-term coverage；F2117 action-phase；U622 week-two event；SEM1549 全模型发言比较；`docs/editorial_review.md` | V81 week-two surface | 无；完整 corpus 编辑审读通过 |
| CH0-W03 | Verified | `src/hiring_content.gd` fixed key `lin_scene_1`; director chapter transition | C2795 fixed keys；F2117 full campaign | — | 无 |
| CH1-000 | Partial | Narrative-only fundraising and training/tweet actions implemented | M1940 fundraising/action tests；F2117 investor flow | V81 investor café | 玩家是否自行发现仍取决于 FUND-002 首玩研究 |
| CH1-W01 | Verified | `src/hiring_model.gd::ACTION_MIN_CHAPTER`; UI pool | M1940 action availability；U622 action pool | — | 无 |
| CH1-W02 | Verified | `src/hiring_content.gd` silent/free key `preseed_free_2` | C2795 45-key coverage；F2117 fixed-priority/silent tests | — | 无 |
| CH1-W03 | Verified | `src/hiring_content.gd` silent/free key `preseed_free_3` | C2795/F2117 fixed/silent coverage | — | 无 |
| CH1-W04 | Verified | `src/hiring_content.gd` key `first_investor_meeting`; director choice effects | F2117 `_test_preseed_close_fundraise_mechanics`; M1940 FUND-001 | V81 investor café | 无 |
| CH1-W05 | Verified | `src/hiring_content.gd` silent key `investor_repost` | F2117 fixed-priority/silent；U622 quiet chronology | — | 无 |
| CH1-W06 | Partial | `src/hiring_content.gd` key `viral_tweet` exact deltas/copy | C2795 term/delta lint；F2117 fixed flow | — | “第一次窃喜”的情感效果需人工/玩家叙事 QA |
| CH1-W07 | Verified | `src/hiring_content.gd` fixed key `lin_scene_2` | C2795 fixed keys/Lin content；F2117 full campaign | — | 无 |
| CH1-W08 | Verified | `src/hiring_content.gd` key `preseed_close`; director financing transition | F2117 `_test_preseed_close_fundraise_mechanics` | — | 无 |
| CH1-SIZE | Verified | `src/hiring_model.gd::_scale_team_to_chapter_target` target 4 | M1940 `_test_chapter_staffing_targets`; F2117 full campaign | V81 team | 无 |
| INVEST-001 | Verified | `src/hiring_content.gd` key `first_investor_meeting` | C2795 required event/token snapshots；F2117 investor route | V81 `event_first_investor_meeting_cafe.png` | 无 |
| INVEST-002 | Verified | Same event choice key `honest` | C2795 exact effects/text；F2117 preseed mechanics | V81 investor café | 无 |
| INVEST-003 | Verified | Same event choice key `pitch` | C2795 exact effects；F2117 preseed mechanics | — | 无 |
| INVEST-004 | Verified | Same event choice key `delegate` | C2795 delegation/effects；F2117 preseed mechanics | — | 无 |
| VIRAL-001 | Verified | `src/hiring_content.gd` key `viral_tweet` | C2795 exact numbers/terms；F2117 fixed schedule | — | 无 |

### 第二章与现场兑现

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| CH2-000 | Partial | `src/hiring_content.gd` Seed debt/live-demo structure；AI choice | C2795 fixed keys；F2117 demo/live routes | V81 debt tiers | “强烈诱导”需 ACCEPT-002/首玩行为数据 |
| CH2-W01 | Verified | Chapter transition/office state；night-one pending key | M1940 full clock；F2117 full campaign；U622 night advance | V81 office/night-one opening | 无 |
| CH2-W02 | Partial | `src/hiring_content.gd` `seed_demo_unlock`; action pool unlock | M1940 action unlock；F2117 used/unused routes；U622 pool | — | “明显诱惑”需首玩行为验证 |
| CH2-W03 | Verified | `src/hiring_content.gd` silent key `seed_free_3`; debt system | C2795 fixed-key completeness；M1940 debt accumulation | — | 无 |
| CH2-W04 | Verified | `src/hiring_content.gd` silent key `seed_free_4`; debt system | C2795/M1940 | — | 无 |
| CH2-W05 | Verified | `src/hiring_content.gd` silent key `seed_debt_5`; current balance actions | F2117 silent beat；U622 多个合理生产行动策略自然达到 debt≥40 并记录峰值 | V81 debt-mid/high visual states | 无 |
| CH2-W06 | Verified | `src/hiring_content.gd` key `live_demo`; director route matrix | C2795/F2117 live-demo branch tests；U622 专用录像状态机 | V81 五阶段 live replay | 无；转折的可达、表演与后果已闭合 |
| CH2-W07 | Verified | `src/hiring_content.gd` key `first_resignation_signal` | C2795 fixed keys；F2117 conditional beats | — | 无 |
| CH2-W08 | Verified | `src/hiring_content.gd` silent hiring metrics 4,200/3；announcement UI | F2117 silent chronology；U622 `_test_quiet_chronology_surfaces` | V81 metrics hidden/released PNG | 无 |
| CH2-W09 | Verified | `src/hiring_content.gd` fixed key `lin_scene_3` | C2795 Lin content；F2117 full campaign | — | 无 |
| CH2-W10 | Verified | `src/hiring_director.gd` debt-conditioned repeat live event | F2117 `_test_live_demo_postpone_return_schedule`,`_test_chapter_two_quiet_and_conditional_beats` | — | 无 |
| CH2-W11 | Verified | `src/hiring_content.gd` financing-phase fixed key | C2795 45-key schedule；F2117 complete campaigns | — | 无 |
| CH2-W12 | Verified | financing close/chapter transition keys | C2795 fixed keys；F2117 complete campaigns | — | 无 |
| CH2-END | Verified | `src/hiring_content.gd::NIGHT_SHIFTS["1"]`; director night gate | F2117 `_test_night_shift_requires_inspection`; N173/NU115 | V81 night-one captures | 无 |
| CH2-SIZE | Verified | `src/hiring_model.gd` chapter target 9 | M1940 `_test_chapter_staffing_targets`; F2117 campaign | V81 team | 无 |
| LIVE-001 | Verified | `src/hiring_content.gd` `live_demo` body/aftermath tokens | C2795 exact token lint；F2117 live routes | — | 无 |
| LIVE-002 | Verified | `live_demo` choice `run_live`, success branch | F2117 ability 59/60 and exact success effects | — | 无 |
| LIVE-003 | Verified | `run_live` failure branch；immutable two-departure snapshot | F2117 failure boundary/cash/two departures/save | — | 无 |
| LIVE-004 | Verified | `live_demo` choice `postpone`; deterministic return scheduling | F2117 `_test_live_demo_postpone_return_schedule` | — | 无 |
| LIVE-005 | Verified | `live_demo` choice `delegate` | C2795 exact effect/delegation；F2117 guaranteed route | — | 无 |
| LIVE-006 | Verified | `src/hiring_content.gd` delegated result copy/“我们”停顿；专用无脸录像状态机 | C2795 full text tokens；F2117 route；U622 timed replay/rapid-input/save-resume contract；`docs/editorial_review.md` | V81 signed/playback/pause/replay/aftermath captures | 无；v1 节奏与表演已签核 |

### 第三章与裁员

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| CH3-000 | Partial | Series-A departure and stage-three voice systems | F2117 departure/voice routes；U622 option voice | — | “不像玩家写的”发现/情感效果仍依赖 ACCEPT-003/004 |
| CH3-W01 | Verified | `src/hiring_content.gd` silent expansion/elevator resource | C2795 anomaly/schedule；F2117 silent events；U622 chronology | V81 `calendar_supernatural_resources.png` | 无 |
| CH3-W02 | Verified | `src/hiring_model.gd` week-two unlock gate for manifesto/interview/layoffs | M1940 ranged unlock tests；U622 pool surface | — | 无 |
| CH3-W03 | Verified | `src/hiring_content.gd` silent phantom employee/report key | C2795 anomaly/report；F2117 silent event；U622 chronology | V81 phantom employee/report captures | 无 |
| CH3-W04 | Verified | Stage-three threshold/choice rewrite and no-event placeholder | M1940 writer stage；C2795 schedule；U622 option voice/quiet chronology | — | 玩家发现率单列 ACCEPT-003，不影响客观实现状态 |
| CH3-W05 | Verified | `src/hiring_content.gd` former-employee-post fulfillment key | C2795 event pool/fixed keys；F2117 campaign reachability | — | 无 |
| CH3-W06 | Verified | `src/hiring_content.gd` cash-crisis event restricted choices | F2117 `_test_cash_crisis_contract_and_layoff_routes` | — | 无 |
| CH3-W07 | Verified | `src/hiring_content.gd` layoff execution event | F2117 cash-crisis/layoff promise routes；C2795 content | — | 无 |
| CH3-W08 | Verified | silent room-D calendar key | C2795 anomaly/schedule；F2117 silent event；U622 chronology | V81 calendar room-D | 无 |
| CH3-W09 | Verified | high-debt realization fixed key/queue | C2795 fixed schedule；F2117 complete campaign | — | 无 |
| CH3-W10 | Verified | second high-debt realization fixed key/queue | C2795 fixed schedule；F2117 complete campaign | — | 无 |
| CH3-W11 | Verified | `src/hiring_content.gd` `lin_scene_4`; director 59/60 routing | C2795 Lin matrix；F2117 `_test_lin_scene_four_deferred_departure`,`_test_lin_training_gate_and_last_visit_priority` | — | 无 |
| CH3-W12 | Verified | financing-phase fixed key | C2795 schedule；F2117 campaign | — | 无 |
| CH3-W13 | Verified | financing-phase fixed key | C2795 schedule；F2117 campaign | — | 无 |
| CH3-W14 | Verified | chapter settlement key/transition | C2795 schedule；M1940 full clock；F2117 campaign | — | 无 |
| CH3-END | Verified | night-two gate + explicit `lin_scene_4` removal | F2117 Lin deferred departure/night inspection；N173/NU115 night two | V81 night-two captures | 无 |
| CH3-SIZE | Verified | `src/hiring_model.gd` target 22 | M1940 staffing targets；F2117 campaign | V81 team | 无 |
| LAYOFF-001 | Verified | `src/hiring_content.gd` layoff list/copy；director promise week/like interpolation | C2795 exact terms；F2117 `_test_layoff_promise_copy_routes` | — | 无 |
| LAYOFF-002 | Verified | layoff event manual-talk choice effects/attention | C2795 exact effect schema；F2117 cash-crisis routes | — | 无 |
| LAYOFF-003 | Verified | layoff event email choice effects/attention | C2795/F2117 exact route | — | 无 |
| LAYOFF-004 | Verified | delegated layoff copy/schedule/social-state sequence | C2795 six×20-minute/text lint；F2117 route；U622 deterministic social-heart state machine | PIX 三阶段心形像素证据；V81 social captures | 无 |

### 第四章、窗外工位、起源与董事会

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| CH4-000 | Partial | chapter-four 1-attention/four-card pool + stage-five autonomy | M1940 chapter-four/stage-five；F2117 stage-five start；U622 pool | V81 finale/intranet/signature | “几乎无事可做且运转更好”的整体体验需首玩 QA |
| CH4-W01 | Verified | model name `LANTERN`; silent chapter-opening key | M1940 names；C2795 no nickname；F2117 final silence；U622 chronology | V81 `intranet_finale.png` | 无 |
| CH4-W02 | Verified | window workstation event/state machine | C2795 anomaly registry；U622 curtain/window contract | V81 window open/closed/reopened | 无 |
| CH4-W03 | Verified | `src/hiring_content.gd` origin article；UI read-state machine | C2795 intranet docs；U622 `_test_origin_article_state_machine` | V81 origin three-state captures | 无 |
| CH4-W04 | Verified | `docs/product_decisions.md::DEC-005/006`; `src/hiring_content.gd` `lin_last_visit` present/absence branches | C2795 content；F2117 `_test_lin_training_gate_and_last_visit_priority` | — | 无 |
| CH4-W05 | Verified | phantom report number 91 key | C2795 `_test_intranet_documents_and_report_91` | V81 `intranet_phantom_weekly_report.png` | 无 |
| CH4-W06 | Verified | board event and presentation state machine | C2795 board content；U622 `_test_board_ai_presentation_state_machine` | V81 board page/org/aftermath | 无 |
| CH4-W07 | Verified | invisible silent placeholder and no major modal | C2795 45-key completeness；F2117 final-silence test；U622 chronology | — | 无 |
| CH4-W08 | Verified | director campaign completion + ending resolver/playback | M1940 ending resolver；F2117 ending routes；U622 all ending surfaces | V81 seven ending PNG | 无 |
| WINDOW-001 | Verified | `src/hiring_content.gd` window body；`src/hiring_main.gd` four silhouettes/desks | C2795 exact content；U622 desk/window population | V81 `team_finale_window_open.png` | 无 |
| WINDOW-002 | Verified | window event administrative count/curtain choice | C2795 exact copy；U622 curtain state machine | V81 open→closed | 无 |
| WINDOW-003 | Verified | persisted curtain closed-once / reopen-on-entry state | U622 `_test_finale_window_curtain_state_machine` | V81 closed/reopened | 无 |
| ORIGIN-001 | Verified | `src/hiring_content.gd` origin article exact dog/printer/“先这样” tokens | C2795 intranet tests；U622 origin state；SEM1549；`docs/editorial_review.md::ORIGIN-001` | V81 origin captures | 无；当前正文批准为 v1 基线 |
| ORIGIN-002 | Verified | origin article collective-voice exact text | C2795 exact token lint；U622 origin state | V81 origin article | 无 |
| ORIGIN-003 | Verified | `src/hiring_main.gd` read-count/editor/close state machine | U622 `_test_origin_article_state_machine` | V81 second/third/unchanged captures | 无 |
| BOARD-001 | Verified | `src/hiring_content.gd` board body；UI presentation fixture | C2795 exact board terms；U622 board state machine | V81 board captures | 无 |
| BOARD-002 | Verified | board choices `stable`,`seven_left` with distinct coherent outcomes | C2795 choice/effect completeness；F2117 after-coverage | V81 board surface | 无 |
| BOARD-003 | Verified | board `delegate` scripted page/org-chart/aftermath states | C2795 exact 11%/20-minute text；U622 board state machine | V81 three board frames | 无 |

### 林越主线矩阵

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| LIN-001 | Verified | `src/hiring_content.gd` key `lin_scene_1`, no choices/player reply | C2795 Lin scene schema/text；F2117 complete campaign | — | 无 |
| LIN-002 | Verified | `docs/product_decisions.md::DEC-026`；`lin_scene_2` 保留两段 story-time 120 秒；`src/hiring_main.gd` 映射为普通模式各 10 秒、降低动态各 0.15 秒 | C2795 exact `[0,120,0,120,0]` authored holds；F2117 reachability；U622 验证两个独立空白页、9.99 秒不可继续、10 秒可继续与 reduced-motion 0.15 秒门槛 | V81 两段 silence production surfaces；WAV 静默策略 | 无；不得把故事内 120 秒误写成玩家真实等待时长 |
| LIN-003A | Verified | `lin_scene_3` choice `know` scoped Lin/company effects | C2795 exact effects/text；F2117 Lin routes | — | 无 |
| LIN-003B | Verified | `lin_scene_3` choice `market` | C2795/F2117 exact branch | — | 无 |
| LIN-003C | Verified | `lin_scene_3` choice `delegate` + suspicion flag | C2795 delegation/effects；F2117 Lin routes | — | 无 |
| LIN-004-GATE | Verified | `src/hiring_director.gd` branch gate author weight `>=60` | F2117 `_test_lin_training_gate_and_last_visit_priority` 59/60 | — | 无 |
| LIN-004A0 | Verified | `src/hiring_content.gd` `lin_scene_4` high-author opening pages | C2795 required scene/term snapshots；F2117 Lin scene flow | — | 无 |
| LIN-004A1 | Verified | `lin_scene_4` choice `claim`; belief lock 15 | C2795 exact effect；F2117 priority/permanent-state route | — | 无 |
| LIN-004A2 | Verified | `lin_scene_4` choice `admit`; weekly-review flag/consequence | C2795 exact effect；F2117 last-visit priority | — | 无 |
| LIN-004A3 | Verified | `lin_scene_4` choice `delegate`; week-31 administrative corpus provenance | C2795 exact quote；F2117 `_test_lin_values_corpus_provenance` | — | 无 |
| LIN-004A4 | Verified | director deferred flag/release；model permits Lin removal only reason `lin_scene_4` | M1940 Lin guard；F2117 `_test_lin_scene_four_deferred_departure` | — | 无 |
| LIN-004B0 | Verified | `lin_scene_4` low-author/training opening | C2795 exact content；F2117 training gate | — | 无 |
| LIN-004B1 | Verified | three warm choices share exact morale/Lin-belief resolution | C2795 three-path effects；F2117 gate/route | — | 无 |
| LIN-004B2 | Verified | director counts `train+large_train>=3`, author `<60`, persisted | F2117 2/3 and 59/60 boundaries + save | — | 无 |
| LIN-005 | Verified | `docs/product_decisions.md::DEC-005/006`; `src/hiring_content.gd` key `lin_last_visit` priority branches + absence echo | C2795 no-placeholder content；F2117 `_test_lin_training_gate_and_last_visit_priority` | — | 无；v1 正文已批准 |

### 夜班、对象与终端

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| NIGHT-000 | Verified | `src/night_interaction_state.gd`; `src/hiring_main.gd` click-to-move/map UI | N173 all interaction paths/save；NU115 required API/click-arrival | V81 night openings/interactions | 无 |
| NIGHT-001 | Verified | night state has no chase/timer/failure actor；夜班使用 diegetic ambience，score/异常 cue 关闭 | C2795 anomaly rules；N173/NU115；A275 Night 1 HVAC-only、夜班 score 静音与无异常 cue | IDLE 300 idle seconds, tracked state unchanged；WAV night scene previews | 无 |
| NS1-CORRIDOR | Verified | `src/hiring_content.gd::NIGHT_SHIFTS["1"]` corridor；night pass counter/lights | N173 `_test_night_one_corridor_three_real_passes`; NU115 | V81 first/third crossing | 无 |
| NS1-WHITEBOARD | Verified | night-one hotspot `whiteboard` exact scarf-dog/logo lines | C2795 exact text；N173/NU115 click route | V81 `night_1_whiteboard_scarf_dog.png` | 无 |
| NS1-PLANT | Verified | `docs/product_decisions.md::DEC-007`; night-one hotspot `plant`, debt-tier variants | C2795 registry；N173/NU115；U622 visual fixture | V81 clear/mid/high plant PNG | 无 |
| NS1-MUG | Verified | `docs/product_decisions.md::DEC-007`; night-one hotspot `mug`, callback flag/NG+ imagery | C2795 registry/text；N173 click/save | — | 无 |
| NS1-FRIDGE | Verified | night-one hotspot `fridge` exact Aug-3/Aug-19 copy | C2795 exact-date lint；N173 click/save | — | 无 |
| NS1-END | Verified | `docs/product_decisions.md::DEC-007`; night-one hotspot `corridor_end`, independent reachability | C2795 registry；N173/NU115 reachability | — | 无 |
| NS2-PLANT | Verified | night-two hotspot `plant` ratio/14-month rota copy | C2795 exact terms；N173 `_test_night_two_plant`; NU115 visuals | V81 night-two opening/plant context | 无 |
| NS2-DESK | Verified | night-two `window_desk` state machine + 2024 cup/two-cm replacement | C2795 exact content；N173 desk sequence/save；NU115 | V81 held/replaced desk cup | 无 |
| NS2-D | Verified | night-two `room_d` phases/projector/light-off state | C2795 content；N173 room-D sequence/save；NU115 | V81 projector/two-steps/light-off | 无 |
| NS2-TERM | Verified | night-two `terminal` focus/dialogue/Ctrl+C phases | C2795 exact text；N173 terminal sequence/save；NU115 | V81 unsent/focused/Ctrl+C | 无 |
| NIGHT-RM | Verified | `src/night_interaction_state.gd` exact parser；`src/hiring_main.gd` immediate ending | N173 parser/state；NU115 `_test_terminal_input_and_rm_rf_focus_gate`; F2117 ending route | V81 `ending_rm_rf.png` | 无 |

### 软件界面

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| UI-001 | Verified | `hiring_main.tscn`; `src/hiring_main.gd` dashboard/team/terminal/calendar/announcements/night screens | U622 public UI/full flows；NU115 night UI；S0 | V81 full 81-screen set | 无 |
| UI-002 | Verified | `src/hiring_main.gd` cards/documents/terminal/click interactions | U622 action/event/intranet/board/ending flows；NU115 clicks | V81 software surfaces | 无 |
| UI-003 | Verified | ordinary calendar/team/intranet anomaly surfaces | C2795 anomaly registry；U622 quiet/window/origin；NU115 D room | V81 calendar/phantom/window | 无 |
| UI-004 | Verified | extra elevator resource uses ordinary calendar button construction | C2795 anomaly metadata；U622 quiet chronology | PIX 21 个主题采样一致；V81 `calendar_supernatural_resources.png` | 无；无专用 tooltip/动画/主题 |
| UI-005 | Verified | shared room-D id/content across calendar and night map；directory A/B/C copy | C2795 cross-registry；N173/NU115 room-D | V81 calendar + room-D | 无 |
| UI-006 | Verified | stable phantom employee id across content queries/UI | C2795 phantom/report tests；U622 employee desk contract | V81 phantom team/announcement/intranet | 无 |
| UI-007 | Verified | office deterioration renderer；HUD omits debt labels | M1940 hidden-state/tier tests；U622 UI/debt fixture | V81 clear/mid/high debt | 无 |
| UI-008 | Verified | `ANOMALY_REGISTRY` marks window as unique daytime physical exposure | C2795 external-boundary uniqueness；U622 window state | V81 window sequence | 无 |
| UI-009 | Verified | silent-event metadata/queue suppression；静默事件与异常不自动触发拟音或配乐 cue | C2795 fixed/silent keys；F2117 silent recording；U622 quiet chronology；A275 full-silence/anomaly zero-cue contract | V81 silent-result surfaces；WAV authored-silence previews | 无 |
| UI-010 | Verified | option-voice transform changes label string only | U622 `_test_stage_three_option_voice_surface` | PIX 前后差分：`option_glyph_pixels=2721`、`outside_contract_pixels=0` | 无 |
| UI-011 | Verified | `src/hiring_model.gd::public_state`; `src/hiring_main.gd` HUD fields | M1940 public contract；U622 UI surface | V81 dashboard | 无 |
| UI-012 | Verified | sign mechanical no-op + signature tween/drawing | M1940 sign deep comparison；U622 signature screen | SIG 97 frames/60 FPS；V81 signature complete | 无 |

### 音频

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| AUDIO-001 | Verified | `src/office_audio.gd` 核心 air/keyboard/distant-voices 与地点性 server-fan；Ambience bus | A275 图谱、循环、信号、峰值与 bus 断言 | WAV 5 个独立 ambience stem，RIFF/PCM/非零/频谱 | 无 |
| AUDIO-002 | Verified | `OfficeAudio.set_scene_context` 场景策略 + `HiringMain` 最终场景上下文接线 | A275 onboarding/full-silence/room-tone/night/scene context；AINT84 主界面地点、静默页、特殊场景与异常静音接线 | WAV 5 chapter + 13 narrative-scene previews/manifest | 无 |
| AUDIO-003 | Verified | loose/sync keyboard 在作者权重 35–85 等功率交叉 | A275 monotonic/equal-power threshold checks | WAV 5 个 threshold target snapshots + 两条键盘源频谱 | 无；跨阈值无 stinger/滤镜冲击/文字说明 |
| AUDIO-004 | Verified | `OfficeAudio` 消费 Chapter 4 的 week 1–8 上下文，逐层抽走人声、空调与松散键盘，最终仅同步键盘；`HiringMain` 传递周次 | A275 Chapter 4 周次退场与最终周断言；AINT84 Chapter 4 week 1–8 上下文传递与声场逐周退场 | WAV chapter/final-silence preview 与 stem targets | 无 |
| AUDIO-005 | Verified | 非循环物理拟音 allowlist + `HiringMain` direct-action 接线；数值、自动保存、静默与异常无自动 cue | A275 one-shot 图谱、headroom、cooldown、mute、unknown/anomaly rejection；AINT84 direct-action 接线、静默/异常零 cue、锁定导航零成功 cue；C2795 silent-event schema | WAV 13 个 Foley-bus one-shot，均非循环 | 无 |
| AUDIO-006 | Verified | 两条 48 秒、长留白、低电平 human/system 原创动机；Music bus；事件/夜班/沉默/异常 duck 或静音 | A275 score 信号、长留白、峰值、bus 与 `duck_music` 场景断言 | WAV 2 score stems、13 scene previews、7 个互异 ending mixes、77 spectral rows | 无；禁止章节 stinger、奖励 jingle、移动端 beep 与恐怖揭秘声 |
| AUDIO-007 | Partial | 键盘等功率平滑过渡，作者阶段变化无 cue/stinger/文字通知 | A275 monotonic/equal-power thresholds、异常/静默零 cue；U622 quiet chronology | WAV threshold target snapshots + keyboard spectrum | “通关很久后才回想”必须由首次玩家延迟访谈验证 |

### 结局、正文与新周目

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| END-001 | Verified | `src/hiring_model.gd::select_ending` acquisition fallback；`src/hiring_content.gd::ENDINGS["acquihire"]`; DEC-008 approval | M1940 ending boundaries；F2117 all-ending routes；U622 ending playback | V81 `ending_acquihire.png` | 无 |
| END-002 | Verified | cash-zero immediate resolver + `ENDINGS["lights_out"]` | M1940 priority；U622 action/event-choice immediate exhaustion；F2117 routes | V81 `ending_lights_out.png` | 无 |
| END-003 | Verified | capability `>=80 && debt<10` branch + `ENDINGS["independent"]` | M1940 79/80, 9/10 boundaries；F2117/U622 ending routes | V81 `ending_independent.png` | 无 |
| END-004 | Verified | author weight `>=100` branch + `ENDINGS["successor"]` | M1940 99/100/priority；F2117/U622 | V81 `ending_successor.png` | 无 |
| END-005 | Verified | coherence `<20` branch + approved `ENDINGS["drift"]` | M1940 19/20；F2117/U622；`docs/product_decisions.md::DEC-008` | V81 `ending_drift.png` | 无 |
| END-006 | Verified | exact night command resolver + approved `ENDINGS["rm_rf"]` | N173/NU115 parser；M1940/F2117 priority/routes | V81 `ending_rm_rf.png` | 无 |
| END-007 | Verified | `completed_once/second_run` opening path excluded from resolver | M1940 NG+ save；F2117 `_test_ng_plus_is_an_opening_not_an_ending`; U622 NG+ | V81 `ending_second_time.png` + NG+ sequence | 无 |
| END-PRIORITY | Verified | explicit `src/hiring_model.gd::ENDING_PRIORITIES/select_ending`; DEC-008 documented order | M1940 exhaustively enumerates all 32 ending-condition subsets plus cash-exhausted flag collision；F2117 routes all endings | V81 seven endings | 无 |
| END-LIGHTS-COPY | Verified | `src/hiring_content.gd::ENDINGS["lights_out"]` paged copy | C2795 exact tokens/full text；U622 all ending pages | V81 `ending_lights_out.png` | 无 |
| END-INDEP-COPY | Verified | `ENDINGS["independent"]` with Lin-state-safe variants | C2795 11/400/Friday/2:00 tokens；F2117 route consistency；U622 pages | V81 independent | 无 |
| END-SUCCESSOR-COPY | Verified | `ENDINGS["successor"]` paged copy | C2795 exact Monday/Thursday/review/GPU/“我们” tokens；U622 pages | V81 successor | 无 |
| END-ACQ-COPY | Verified | approved `ENDINGS["acquihire"]`; `docs/product_decisions.md::DEC-008` | C2795 full content；F2117/U622 route/playback | V81 acquihire | 无 |
| END-DRIFT-COPY | Verified | approved `ENDINGS["drift"]`; DEC-008 | C2795 coherence-centered copy；F2117/U622 | V81 drift | 无 |
| END-RMRF-COPY | Verified | approved `ENDINGS["rm_rf"]`; DEC-008 | C2795 no-reveal copy；N173/NU115 trigger；U622 pages | V81 rm_rf | 无 |
| END-COMPANY | Verified | ending token interpolation from saved `company_name` | M1940 identity/save；U622 `_test_all_ending_playback_surfaces` custom fixture | V81 seven custom-company ending surfaces | 无 |
| NGP-001 | Verified | `src/hiring_main.gd` meta save `completed_once`; model `second_run` | M1940 save；F2117 NG+ route；U622 `_test_second_time_and_ending_resume` | V81 NG+ captures | 无 |
| NGP-002 | Verified | NG+ opening cup/date/team state | C2795 exact 2024/date copy；F2117/U622 NG+ | V81 `ng_plus_cup_present.png` | 无 |
| NGP-003 | Verified | NG+ cup held/replaced + Lin question states | C2795 text；U622 NG+ state machine | V81 held/question | 无 |
| NGP-004 | Verified | exact two fixed choices, delegation exception whitelist | C2795 `_test_all_decisions_have_delegation`; F2117 NG+ | V81 Lin question | 无 |
| NGP-005 | Verified | convergent answers and window-desk placement state | F2117 NG+ equivalence；U622 state machine | V81 answered/window-desk | 无 |
| NGP-006 | Verified | NG+ transitions into normal chapter-zero campaign and remains unexplained | F2117 `_test_ng_plus_is_an_opening_not_an_ending`; U622 resume | V81 NG+ sequence | 无 |

### 玩家验收门槛

| Requirement ID | Status | 实现文件/内容键 | 自动化测试/日志 | 运行捕获 | 剩余人工门槛 |
|---|---|---|---|---|---|
| ACCEPT-001 | Unverified | Debt realization/visual systems implemented | 自动化与开发捕获不能替代首玩反应 | — | 缺合格首玩录像时间戳、think-aloud、行为日志与访谈原话 |
| ACCEPT-002 | Unverified | AI delegation benefits/opportunities implemented | M1940/C2795/F2117 only preflight mechanics | — | 缺首用后再次自愿使用率、样本定义与访谈 |
| ACCEPT-003 | Unverified | Stage-three voice implementation exists | U622 verifies rewrite, not discovery rate | — | 缺首玩样本量、15%–30% 发现率、置信区间和录像 |
| ACCEPT-004 | Unverified | LIN-004A3/A4 departure route implemented | F2117 verifies route, not player desire | — | 缺触发该路线玩家的即时行为、读档/重开记录和访谈 |
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
MATRIX_IDS=267
MATRIX_UNIQUE=267
LEDGER_IDS=267
LEDGER_UNIQUE=267
MISSING=0
EXTRA=0
DUPLICATE_GROUPS=0
```
