class_name HiringIndustryEchoContent
extends RefCounted

## Fictionalized industry folklore for the operating-simulation layer.
##
## The player-facing copy never names a real person or company.  Each reference
## is turned into a decision with an operational consequence, so recognition is
## optional and the joke still works as company drama.

const REFERENCE_REGISTER: Dictionary = {
	"mascot_tattoo_culture": {
		"region": "us", "kind": "reported_company_culture",
		"editorial_note": "Use the reported early-team participation count; never claim that tattoos were mandatory.",
	},
	"manhattan_launch_rhetoric": {
		"region": "us", "kind": "founder_interview",
		"editorial_note": "Allude to launch rhetoric and governance anxiety; do not repeat the unverified collapsing-or-dizziness paraphrase.",
	},
	"p_doom_safety_race": {
		"region": "us", "kind": "public_risk_argument",
		"editorial_note": "Satirize the tension between safety warnings and market competition, not the sincerity of any individual.",
	},
	"deep_learning_wall_meme": {
		"region": "us", "kind": "documented_office_meme",
		"editorial_note": "Translate the visual pun into a facilities invoice rather than copying the original image.",
	},
	"autonomous_shop_tungsten": {
		"region": "us", "kind": "published_research_anecdote",
		"editorial_note": "Keep the tungsten-cube recognition point while moving the experiment into the fictional company.",
	},
	"founder_mode": {
		"region": "traditional", "kind": "startup_management_meme",
		"editorial_note": "Present selective founder involvement and indiscriminate micromanagement as different choices.",
	},
	"default_alive": {
		"region": "traditional", "kind": "startup_finance_framework",
		"editorial_note": "The joke targets spreadsheet self-deception while preserving the real runway concept.",
	},
	"ten_x_engineer": {
		"region": "traditional", "kind": "hiring_folklore",
		"editorial_note": "Let the candidate have real strengths; the tradeoff is variance and collaboration, not ridicule.",
	},
	"liang_honorific_slider": {
		"region": "china", "kind": "community_fan_meme",
		"editorial_note": "Treat it explicitly as a community-made release-delay meter, never as biography or fact about a real founder.",
	},
	"accidental_catfish_price_war": {
		"region": "china", "kind": "founder_interview_and_market_event",
		"editorial_note": "Paraphrase the verified cost-led price-war idea through a fictional research lab.",
	},
	"million_token_price_copy": {
		"region": "china", "kind": "api_price_war_marketing",
		"editorial_note": "Compare headline token pricing with an all-in procurement bill; do not attach a stale real-world price.",
	},
	"hundred_model_battle": {
		"region": "china", "kind": "industry_label",
		"editorial_note": "Use benchmark category proliferation as the joke, not any one lab's result.",
	},
	"unmetered_research_compute": {
		"region": "china", "kind": "reported_research_culture",
		"editorial_note": "Pair research autonomy with a real cloud-cost and review decision.",
	},
	"open_weights_gating": {
		"region": "global", "kind": "industry_language_meme",
		"editorial_note": "Distinguish open weights, licensing, and lead-generation without accusing a real release.",
	},
	"scoped_training_cost": {
		"region": "china", "kind": "technical_report_misquotation",
		"editorial_note": "Keep final-training compute, experiments, salaries, data, and total program cost visibly separate.",
	},
	"viral_capacity_503": {
		"region": "china", "kind": "product_breakout_folklore",
		"editorial_note": "Treat 503 as overload unless evidence establishes a different cause; success and availability are separate metrics.",
	},
	"full_blood_deployment": {
		"region": "china", "kind": "deployment_marketing_language",
		"editorial_note": "Compare quantization, context, throughput, concurrency, and limits instead of repeating a vendor badge.",
	},
	"invite_code_scarcity": {
		"region": "china", "kind": "launch_scarcity_market",
		"editorial_note": "Use listings and support fraud as the consequence; never turn an asking price into a verified sale.",
	},
}

# Research provenance and game delivery are intentionally separate.  The real
# anecdote only supplies a recognisable seed; this matrix decides what emotional
# job the fictional mutation performs inside the campaign.  Ambient echoes never
# open a modal or spend founder attention.
const EVENT_DESIGN: Dictionary = {
	"permanent_mascot_commitment": {"delivery": "decision", "valence": "positive", "intensity": 2},
	"everyone_sit_down_demo": {
		"delivery": "ambient", "valence": "comic_relief", "intensity": 1,
		"headline": "两段相隔八分钟的采访，已被剪成同一个呼吸",
		"metric": "8:27 → 0:04",
	},
	"doom_and_dilution": {
		"delivery": "decision", "valence": "dilemma", "intensity": 3,
	},
	"deep_learning_wall_invoice": {
		"delivery": "ambient", "valence": "comic_relief", "intensity": 1,
		"headline": "设施部拒绝把真实墙裂计入『扩展定律』研究预算",
		"metric": "报销退回 ×3",
	},
	"autonomous_shop_tungsten": {"delivery": "decision", "valence": "positive", "intensity": 2},
	"founder_mode_calendar": {"delivery": "decision", "valence": "dilemma", "intensity": 3},
	"default_alive_formula": {"delivery": "decision", "valence": "crisis", "intensity": 4},
	"ten_x_interview": {"delivery": "decision", "valence": "positive", "intensity": 2},
	"honorific_release_slider": {
		"delivery": "decision", "valence": "dilemma", "intensity": 2,
	},
	"accidental_catfish_price_war": {"delivery": "decision", "valence": "crisis", "intensity": 4},
	"million_tokens_milk_tea": {"delivery": "decision", "valence": "dilemma", "intensity": 1},
	"hundred_models_one_eval": {
		"delivery": "ambient", "valence": "comic_relief", "intensity": 1,
		"headline": "一百零一个模型参加评测，九十四个获得第一名",
		"metric": "冠军率 93.1%",
	},
	"unmetered_gpu_side_quest": {"delivery": "decision", "valence": "positive", "intensity": 3},
	"open_weights_sales_gate": {"delivery": "decision", "valence": "dilemma", "intensity": 2},
	"training_cost_footnote": {"delivery": "decision", "valence": "dilemma", "intensity": 3},
	"viral_503_week": {"delivery": "decision", "valence": "crisis", "intensity": 5},
	"full_blood_vendor_skus": {
		"delivery": "ambient", "valence": "comic_relief", "intensity": 1,
		"headline": "四家云厂商提交五个『满血版』，采购要求先统一血型",
		"metric": "FULL ×5",
	},
	"invite_code_secondary_market": {"delivery": "decision", "valence": "crisis", "intensity": 4},
}


static func event_templates() -> Array[Dictionary]:
	var templates: Array[Dictionary] = [
		_event(
			"permanent_mascot_commitment", "people", 2, 3, 9, 10,
			["pawprint_mutual", "people_team"],
			"公司图案要不要留一辈子", "文化活动 · 周五 17:30",
			[
				"Pawprint Mutual 刚公布新一轮融资。合照里，二十位早期员工已经自发把同一只短腿犬留在手臂上。",
				"没纹的同事没有抗议，只是要求等值文化福利：有人要两年狗粮，有人要一整卷纹身贴，还有人已经把『办公室真狗』写进了 OKR。",
			],
			_choices(
				["culture_wallet", "每人一笔文化钱包", {"morale": 6, "coherence": 4}, "有人报销纹身，有人报销陶艺。财务新增了『永久』和『可洗掉』两列，第一次都有人满意。"],
				["office_mascot", "试行办公室真狗日", {"morale": 8, "cash_weeks": -1, "narrative": 3}, "周五来了三只短腿犬和七十九位访客。销售说这是本季度转化率最高的落地页。"],
				["shelter_match", "把热度配捐给动物救助", {"morale": 5, "coherence": 3, "narrative": 5}, "公司图案第一次出现在不属于公司的好消息里。门禁贴仍然在一夜之间卖光。"]
			),
			{"gte": {"team_size": 4}}, ["scaled_company_culture"], ["mascot_tattoo_culture"], true
		),
		_event(
			"everyone_sit_down_demo", "market", 2, 3, 9, 8,
			["chorus", "launch_press"],
			"两句话之间隔了八分钟", "竞品专访 · 27:09 / 35:36",
			[
				"Chorus 的 CEO 在 27:09 说，模型写好一封难邮件后，他往椅背上一靠，意识到『它来了』。35:36，他谈到历史上的科学家与『我们做了什么』。",
				"第二天标题是：《创始人看到原子弹后当场瘫坐眩晕》。两句话之间隔了八分钟，标题之间没有。",
			],
			_choices(
				["request_correction", "要求把两段话分开", {"coherence": 5, "narrative": -2}, "媒体把『瘫坐眩晕』改成了『靠回椅背』。旧标题的截图仍然跑得更快。"],
				["ride_the_clip", "不置评，只转发片段", {"narrative": 8, "debt": 4}, "转发没有附评论，因此所有人都替公司补上了自己的评论。"],
				["delegate", "让它写一份澄清", {"narrative": 6, "coherence": 3, "author_weight": 5}, "澄清准确包含『原子弹』『瘫坐』『眩晕』和『并非』。搜索结果迎来第二轮高峰。", true]
			),
			{"gte": {"team_size": 3}}, ["product_launch_lane", "competitive_market"], ["manhattan_launch_rhetoric"], false
		),
		_event(
			"doom_and_dilution", "capital", 3, 4, 8, 9,
			["northline_capital", "safety_founder"],
			"末日概率与下一轮稀释", "投资人晚餐 · 风险讨论",
			[
				"Northline 的合伙人把餐巾翻到背面，写下 P(doom)。来访的安全派创始人划掉它，改成 P(文明严重偏航)，给出一个两位数概率范围。",
				"财务模型在旁边算 P(dilution)，保留了四位小数。服务员问，哪一个概率决定今晚要不要点甜点。",
			],
			_choices(
				["stage_gates", "接受阶段性安全限速", {"coherence": 6, "capability": 2, "narrative": -3}, "每跨过一档能力阈值就要复核。增长慢了一点，董事会第一次知道刹车装在哪里。"],
				["separate_registers", "把安全与融资分开建账", {"coherence": 5, "capability": 2, "narrative": -1}, "风险登记册有负责人、阈值和停止条件；term sheet 仍然只谈钱与权利。甜点由另一张表批准。"],
				["joint_review", "把扩张预算绑定风险证据", {"narrative": 5, "capability": 4, "debt": 2}, "每一笔新算力都带一份风险回执。基金愿意多投，安全团队也因此第一次拥有预算。"]
			),
			{"all_flags": ["has_external_investor"], "gte": {"team_size": 5}}, ["external_investor_relationship", "model_risk_review"], ["p_doom_safety_race"], false
		),
		_event(
			"deep_learning_wall_invoice", "office", 2, 4, 7, 8,
			["office_manager", "morrow_alumni"],
			"那堵墙先报销", "办公室 · 会议室 B",
			[
				"一位从 Morrow 来的研究员带来一幅旧海报：巨大的模型撞穿城市，残墙标签写着『扩展极限』。",
				"设施同事看了看海报，又看了看会议室 B 真正的裂缝，问修补应该记在研究、品牌，还是装修科目。",
			],
			_choices(
				["repair_and_hang", "修墙，再把海报挂正", {"cash_weeks": -1, "morale": 5, "capability": 1}, "裂缝被补好。海报下多了一张小牌：『墙已经修复，扩展问题仍在排查。』"],
				["archive_poster", "归档海报，只修真墙", {"coherence": 3, "narrative": -2}, "报销单第一次通过。研究群用裂缝消失前的照片做了新表情。"],
				["delegate", "让它重绘一张授权版本", {"morale": 3, "coherence": 3, "author_weight": 4}, "它生成了抽象版海报，并把那条真实裂缝准确移动到了插画里。", true]
			),
			{"all_flags": ["has_active_lease"]}, ["occupied_office", "research_team_growth"], ["deep_learning_wall_meme"], true
		),
		_event(
			"autonomous_shop_tungsten", "saas", 3, 4, 8, 8,
			["canteen_agent", "office_manager"],
			"小卖部订了十二块钨", "内部实验 · Autonomous retail",
			[
				"负责办公室小卖部的代理误订了十二块钨方块。员工把它们当成限量镇纸竞价，午饭前居然赚回了三倍成本。",
				"采购单签名仍是一个穿蓝色西装、并不存在于花名册的人。冰箱里的气泡水倒是补得很准。",
			],
			_choices(
				["team_dividend", "把意外盈利发成团队奖金", {"morale": 8, "coherence": 2}, "每个人都收到一笔『钨红利』。蓝西装人没有银行账户，因此份额回到了公司。"],
				["bank_windfall", "把盈利入账并结束实验", {"cash_weeks": 2, "coherence": 5}, "财务承认这是收入，但拒绝把『代理的收藏品审美』写进下一季预测。最后一块钨留作镇纸。"],
				["delegate", "让代理带着 $500 上限继续", {"capability": 5, "cash_weeks": -1, "morale": 3, "author_weight": 4}, "它获得预算上限、审计日志和一个禁止购买钨的规则。第二天开始研究铋，但先提交了采购申请。", true]
			),
			{"all_flags": ["has_active_lease"], "gte": {"team_size": 6}}, ["occupied_office", "agentic_workflow_trial"], ["autonomous_shop_tungsten"], true
		),
		_event(
			"founder_mode_calendar", "org", 3, 4, 8, 8,
			["founder", "people_team"],
			"创始人模式占满日历", "组织设计 · Skip-level",
			[
				"一篇谈『创始人模式』的文章刷屏以后，Chief of Staff 提交了一份草案：取消经理例会，并在周五前增加二十七场 skip-level。",
				"日历助手问创始人模式有没有睡眠模式。草案把这个问题标成了『待创始人亲自决定』。",
			],
			_choices(
				["selective_depth", "只深挖三个关键链路", {"coherence": 5, "morale": 3, "capability": 2}, "你看见了经理汇报里消失的细节，也没有把组织改成二十七条直属线。"],
				["founder_sprint", "做两周 Founder Sprint", {"capability": 5, "morale": -3, "debt": 2}, "两周内决策飞快。第三周，经理们带着一份『哪些决定还算我的』清单来复盘。"],
				["skip_level_protocol", "建立固定跳级访谈制度", {"coherence": 5, "morale": 4, "capability": 1}, "每月四场随机访谈，问题公开、反馈匿名。服务器机架仍被列为『无法表达的利益相关方』。"]
			),
			{"gte": {"team_size": 9}}, ["manager_span_at_scale", "founder_operating_review"], ["founder_mode"], false
		),
		_event(
			"default_alive_formula", "capital", 2, 3, 8, 9,
			["finance_lead", "maya_chen"],
			"这家公司今天默认活着", "融资月报 · Runway model",
			[
				"财务表 B17 写着 DEFAULT ALIVE。昨天它还是红色，今天变绿，因为一笔两周 pilot 收入被年化了两次。",
				"投资人月报里已经贴了截图。公式所在的工作表叫 please_dont_touch_final。",
			],
			_choices(
				["fix_formula", "立刻修正并重发月报", {"coherence": 6, "narrative": -4, "cash_weeks": -1}, "格子重新变红。投资人暂停下一笔拨款复核，至少真正的现金日期终于只出现一次。"],
				["annotate_green", "保留截图，附上现金日期", {"narrative": 3, "coherence": 2, "debt": 4}, "合伙人会议照常进行。每个人都看见绿色，也都看见绿色旁边那行很短的日期。"],
				["cancel_and_rebuild", "取消本周会，重建模型", {"coherence": 7, "narrative": -2, "cash_weeks": -2}, "你们错过了本月 partner meeting，换来一张没有隐藏工作表的 runway 表。文件名只叫 runway。"]
			),
			{"all_flags": ["has_external_investor"]}, ["external_investor_relationship", "runway_reporting"], ["default_alive"], false
		),
		_event(
			"ten_x_interview", "people", 1, 3, 7, 8,
			["candidate_10x", "lin_yue"],
			"十倍工程师只开十分之一的会", "候选人 · Systems interview",
			[
				"候选人自称十倍工程师，条件是只有十分之一的会议、没有 Jira。她的 work sample 确实强到让性能图提前结束。",
				"背调人说，她不是十倍快，而是能把一个模糊问题拆成十个别人终于做得动的问题。现在要决定怎样让这种能力留在团队里。",
			],
			_choices(
				["collaboration_contract", "先签协作型专家合约", {"capability": 4, "coherence": 5}, "她修掉最难的性能问题，也把拆题方法写成了全组都能用的模板。会议减少了，不是因为她缺席。"],
				["autonomy_lane", "给高自主研究岗位", {"capability": 6, "morale": 3, "debt": 2}, "两周后出现一个极快的新原型，以及一份只有她能完全读懂的设计文档。两者都是真的资产。"],
				["mentor_multiplier", "让她带两位潜力工程师", {"capability": 5, "morale": 5, "coherence": 3}, "三个人的产出不是三十倍，但第一次 code review 后，团队再也没人问她究竟是几倍。"]
			),
			{"gte": {"team_size": 2}}, ["hiring_lane_unlocked", "technical_hiring"], ["ten_x_engineer"], true
		),
		_event(
			"honorific_release_slider", "market", 3, 4, 9, 9,
			["deep_current_lab", "model_community"],
			"发布群里的滑动变阻器", "社区温度计 · 第三次延期",
			[
				"深潮研究的旗舰版第三次延期。社区把创始人称呼做成四档滑杆：神 / 圣 / 全名 / 牢；状态页每更新一次，旋钮就滑一格。",
				"产品群已经把它打印成发布日历。工程问，我们的日期要不要接进同一个电路。",
			],
			_choices(
				["preview_without_date", "发可验证预览，不报日期", {"capability": 3, "coherence": 4, "narrative": -1}, "社区先测模型，再做图。旋钮停在中间，至少没有继续冒烟。"],
				["buffered_date", "公布带两周缓冲的日期", {"narrative": 5, "coherence": 2, "debt": 2}, "关注度上升，团队也有了边界。社区把缓冲期标成一段绝缘胶带。"],
				["public_milestones", "只公布可验证里程碑", {"capability": 4, "coherence": 4, "narrative": 2}, "每完成一个里程碑，滑杆就向上移动半格。社区抱怨不够刺激，然后准时来测了每个版本。"]
			),
			{"gte": {"team_size": 3}}, ["competitive_market", "product_launch_lane"], ["liang_honorific_slider"], false
		),
		_event(
			"accidental_catfish_price_war", "market", 2, 4, 8, 9,
			["deep_current_lab", "cloud_vendors"],
			"不是故意当鲶鱼", "API 市场 · 五天内第六次降价",
			[
				"深潮把主力 API 价格压到原来的二十分之一。创始人说并非有意当鲶鱼，只是成本先降下来了。",
				"五家云厂商在五天内跟进。销售想午饭前 match；财务想先知道，为什么市场上出现了六套不同的成本口径。",
			],
			_choices(
				["hold_value", "守住价格，承诺服务等级", {"coherence": 6, "cash_weeks": 2, "narrative": -5}, "毛利保住了，一批只看单价的客户离开。销售终于不再用最低价开场，但本月 pipeline 短了一截。"],
				["match_headline", "全面匹配 headline 价格", {"cash_weeks": -4, "narrative": 7, "debt": 3}, "官网数字在午饭前更新。毛利模型在下午新增了『规模到来后自然改善』一栏。"],
				["delegate", "让它只迁移可批处理客户", {"capability": 4, "cash_weeks": -2, "coherence": 3, "author_weight": 4}, "三成流量真的降了价，其余客户收到迁移计划。工程用两周换来一套不靠脚注的成本曲线。", true]
			),
			{"gte": {"team_size": 3}}, ["competitive_market", "usage_pricing"], ["accidental_catfish_price_war"], false
		),
		_event(
			"million_tokens_milk_tea", "saas", 2, 4, 7, 8,
			["api_vendor", "procurement"],
			"一杯奶茶的百万 Token", "供应商报价 · All-in cost",
			[
				"云厂商的横幅说：一百万 Token 比一杯奶茶便宜。账单另列缓存未命中、推理 Token、工具调用和出网费；奶茶从来没有六个附表。",
				"采购问，这个比较包不包括珍珠。销售没有在定价计算器里找到对应选项。",
			],
			_choices(
				["model_all_in", "按完整工作流比总成本", {"cash_weeks": 1, "coherence": 3}, "最便宜的 Token 不是最便宜的任务。采购表新增『完成一件事要几杯』，财务勉强允许保留。"],
				["capped_tasting", "先做一个月封顶试用", {"capability": 2, "cash_weeks": -1, "morale": 3}, "供应商送来十二杯奶茶配合 bake-off。模型评测很严谨，珍珠口径仍然没有统一。"],
				["workflow_bakeoff", "让三个真实客户一起测", {"coherence": 4, "narrative": 2}, "客户选中的不是最低单价，而是唯一不会把出网费藏到第六个附表的方案。奶茶由客户成功报销。"]
			),
			{"gte": {"team_size": 3}}, ["vendor_review_unlocked", "usage_pricing"], ["million_token_price_copy"], true
		),
		_event(
			"hundred_models_one_eval", "market", 2, 4, 8, 8,
			["industry_conference", "benchmark_editor"],
			"一百个模型，九十四个第一", "行业大会 · Benchmark wall",
			[
				"展墙列出一百零一个新模型，其中九十四个写着 Top 1。脚注分别是私有评测、独家垂直领域，以及某个特定的周二。",
				"唯一只写『能稳定导出 CSV』的展位，队伍已经排到消防通道。",
			],
			_choices(
				["publish_failure_set", "发布同一套失败样本", {"capability": 4, "coherence": 4, "narrative": -2}, "你们不是第一，但所有客户都能复现。CSV 展位的人过来交换了名片。"],
				["invent_category", "定义一个只属于我们的榜", {"narrative": 8, "debt": 4}, "第九十五个 Top 1 当天下午出现。市场部开始维护那句脚注。"],
				["delegate", "让它找未被占用的交集", {"narrative": 6, "capability": 3, "author_weight": 5}, "它证明你们在一个空白切片上第一。工程师坚持把星号放进标题，而不是页脚。", true]
			),
			{"gte": {"team_size": 3}}, ["published_product_claims", "competitive_market"], ["hundred_model_battle"], false
		),
		_event(
			"unmetered_gpu_side_quest", "org", 2, 4, 8, 8,
			["research_intern", "infra_lead"],
			"一张不用审批的训练卡", "研究文化 · 自主实验",
			[
				"新研究员按『有想法就用卡』的规则试了一个 attention 变体。曲线已经拐过基线，并在三个内部任务上稳定复现。",
				"云成本告警用了三个感叹号；论文文件名还是 untitled_v3_final。好消息是真的，现在要决定把它变成哪一种资产。",
			],
			_choices(
				["scale_result", "给两周上限，验证扩展", {"capability": 6, "cash_weeks": -3, "morale": 4}, "曲线在更大规模仍然成立。研究员把预算上限写进致谢，并把三个感叹号做成了论文徽章。"],
				["productize_now", "停训，立即产品化", {"capability": 4, "cash_weeks": 2, "coherence": 4}, "实验变成一个客户可用的功能。论文晚了一季，第一张相关发票提前了一季。"],
				["delegate", "让它剪枝后开放复现", {"capability": 5, "narrative": 4, "coherence": 3, "author_weight": 4}, "它保留最有信息量的八组。外部团队一周内复现，并指出一个更便宜的设置。", true]
			),
			{"gte": {"team_size": 4}}, ["research_team_growth", "compute_budget"], ["unmetered_research_compute"], false
		),
		_event(
			"open_weights_sales_gate", "market", 2, 4, 8, 8,
			["open_model_conference", "enterprise_sales"],
			"开源下载需要先约销售", "模型发布 · License review",
			[
				"大会横幅写着『权重完全开放』。下载按钮却先打开十一项销售表单。",
				"许可证允许研究、禁止竞品，并把『开放生态』写了五遍。采购问：开的究竟是源，还是漏斗。",
			],
			_choices(
				["real_release", "发布权重与清楚许可证", {"capability": 4, "coherence": 4, "narrative": -1}, "下载量上升，销售线索变少。社区在两天内提交了第一个你们没想到的优化。"],
				["research_window", "先开放 90 天研究许可", {"capability": 3, "narrative": 4, "coherence": 2}, "大学和独立研究者先拿到权重，商业再分发暂缓。法务得到九十天，也失去了九十天睡眠。"],
				["support_split", "权重直下，企业支持付费", {"narrative": 5, "capability": 3, "cash_weeks": 1}, "下载按钮终于只下载文件。旁边的支持计划仍然有人预约，因为它第一次没有挡在前面。"]
			),
			{"gte": {"team_size": 3}}, ["published_product_claims", "model_distribution_strategy"], ["open_weights_gating"], false
		),
		_event(
			"training_cost_footnote", "capital", 2, 4, 8, 9,
			["launch_press", "finance_lead"],
			"五百六十万美元，和一行脚注", "技术报告 · Cost disclosure",
			[
				"技术报告估算最终一次训练的算力价值约 $5.6m。新闻稿标题已经变成：『我们只花 $5.6m 做出了整个模型。』",
				"脚注仍列着前序实验、数据、薪酬和基础设施不在其中。公关说脚注会降低传播效率。",
			],
			_choices(
				["keep_scope", "把限定条件放进标题", {"coherence": 6, "capability": 2, "narrative": -2}, "标题长了一行，工程团队第一次主动转发了公司新闻稿。"],
				["single_run_now", "先公布单次训练，暂缓总投入", {"narrative": 6, "coherence": 2, "debt": 2}, "大数字准时传播，完整项目成本进入下月审计。记者得到一句好标题，投资人得到一个明确日期。"],
				["delegate", "让它发布分层成本仪表板", {"coherence": 7, "capability": 3, "narrative": 2, "author_weight": 4}, "媒体仍然只截第一张卡，尽调团队却把整个页面加入书签。机器每天更新数字，人类决定哪些数字需要解释。", true]
			),
			{"gte": {"team_size": 4}}, ["published_product_claims", "capital_outreach"], ["scoped_training_cost"], false
		),
		_event(
			"viral_503_week", "saas", 2, 4, 8, 8,
			["infra_lead", "new_users"],
			"本周新增用户三万，成功请求六百", "容量事故 · HTTP 503",
			[
				"产品一夜破圈。状态页的访问量也创下新高，因为大多数新用户只看见：503 / 服务器繁忙。",
				"增长群在庆祝注册数，基础设施群在数成功请求。两张图的曲线都向上。",
			],
			_choices(
				["honest_waitlist", "开透明候补与强限流", {"coherence": 6, "morale": 3, "narrative": -5}, "可用率恢复，热榜名次掉了。等到邀请的人第一次得到的是产品，不是状态页。"],
				["buy_burst", "高价买突发算力", {"cash_weeks": -5, "capability": 3, "narrative": 6}, "首页重新可用。财务把这周获客成本拆成用户、请求和恐慌采购三列。三列都很贵。"],
				["delegate", "让它分流并关闭旗舰重任务", {"capability": 4, "coherence": 4, "narrative": -3, "author_weight": 5}, "轻请求恢复，旗舰体验暂停一周。状态页终于比社交媒体更无聊，最想炫耀的客户却要再等七天。", true]
			),
			{"gte": {"team_size": 4}}, ["product_launch_lane", "compute_budget"], ["viral_capacity_503"], true
		),
		_event(
			"full_blood_vendor_skus", "saas", 2, 4, 7, 8,
			["api_vendor", "procurement"],
			"四家供应商，五个满血版", "采购对比 · Deployment profile",
			[
				"四家供应商的报价都贴着红色『FULL』角标，其中一家还卖两个不同的满血版。",
				"悬停细则依次写着：4-bit、并发 2、上下文 8K、峰值限流。采购问，血型是否也需要写进 DPA。",
			],
			_choices(
				["run_workload_eval", "按真实负载压测", {"capability": 4, "coherence": 5, "cash_weeks": 1}, "最快的 SKU 不是最大的，也不是角标最红的。采购表删掉了『满血』这一列。"],
				["buy_cheapest_full", "先买最便宜的满血版", {"cash_weeks": 1, "debt": 4, "narrative": 2}, "演示通过。第一个并发客户上线时，FULL 变成了排队页面。"],
				["delegate", "让它统一量化与限流口径", {"capability": 4, "coherence": 4, "author_weight": 4}, "五个 SKU 被还原成同一张吞吐曲线。销售保留角标，采购不再用它做决定。", true]
			),
			{"gte": {"team_size": 3}}, ["vendor_review_unlocked", "model_deployment_review"], ["full_blood_deployment"], false
		),
		_event(
			"invite_code_secondary_market", "market", 2, 3, 8, 9,
			["beta_waitlist", "support_team"],
			"邀请码先完成了产品市场匹配", "封闭测试 · Access market",
			[
				"封闭 beta 发布六小时后，二手平台已经出现四位数的邀请码挂牌。客服确认其中大部分是随机字符串。",
				"真正的产品仍只开放给四百人。增长负责人说稀缺感有效，支持团队问：对谁有效。",
			],
			_choices(
				["open_capacity", "按容量逐步开放", {"coherence": 5, "narrative": -4, "capability": 2, "debt": 1}, "倒卖页面迅速失去价格，真实用户开始提交 bug。容量曲线也开始逼近红线。"],
				["keep_scarcity", "保留邀请码与热度", {"narrative": 8, "debt": 5, "morale": -2}, "每个真实邀请带来三张假码截图。等待名单继续增长，支持团队开始给随机字符串做心理疏导。"],
				["verified_queue", "改成实名队列与固定批次", {"coherence": 5, "cash_weeks": -2, "narrative": -2}, "假码在结账前失效，增长也不再像一场抢票。客服债下降，稀缺感跟着一起下降。"]
			),
			{"gte": {"team_size": 3}}, ["product_launch_lane", "capacity_management"], ["invite_code_scarcity"], false
		),
	]
	for index in templates.size():
		var event: Dictionary = templates[index]
		var design: Dictionary = Dictionary(EVENT_DESIGN.get(str(event.get("id", "")), {}))
		event["delivery"] = str(design.get("delivery", "decision"))
		event["valence"] = str(design.get("valence", "dilemma"))
		event["comic_intensity"] = clampi(int(design.get("intensity", 2)), 1, 5)
		event["interaction_mode"] = {
			"positive": "reward_split",
			"comic_relief": "vignette",
			"dilemma": "tradeoff",
			"crisis": "containment",
		}.get(event["valence"], "tradeoff")
		event["pacing_role"] = {
			"positive": "recovery",
			"comic_relief": "recovery",
			"dilemma": "buildup",
			"crisis": "spike",
		}.get(event["valence"], "buildup")
		var pacing_actors: Array = Array(event.get("actor_ids", [])).duplicate()
		if not pacing_actors.has("industry_echo_lane"):
			pacing_actors.append("industry_echo_lane")
		event["actor_ids"] = pacing_actors
		event["actor_cooldown_weeks"] = 4
		var tone_tags: Array = Array(event.get("tone_tags", [])).duplicate()
		for tag in ["satirical_fiction", event["valence"]]:
			if not tone_tags.has(tag):
				tone_tags.append(tag)
		event["tone_tags"] = tone_tags
		templates[index] = event
	return templates


static func interactive_event_templates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_value in event_templates():
		var event: Dictionary = event_value
		if str(event.get("delivery", "decision")) == "decision":
			result.append(event.duplicate(true))
	return result


static func ambient_templates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_value in event_templates():
		var event: Dictionary = event_value
		if str(event.get("delivery", "decision")) != "ambient":
			continue
		var design: Dictionary = Dictionary(EVENT_DESIGN.get(str(event.get("id", "")), {}))
		result.append({
			"id": str(event.get("id", "")),
			"title": str(design.get("headline", event.get("title", "行业又发生了一件事"))),
			"meta": "%s · 不占用注意力" % str(event.get("kicker", "行业边角料")),
			"metric": str(design.get("metric", "已围观")),
			"min_chapter": int(event.get("min_chapter", 1)),
			"max_chapter": int(event.get("max_chapter", 4)),
			"valence": "comic_relief",
			"interaction_mode": "vignette",
			"pacing_role": "recovery",
			"comic_intensity": int(event.get("comic_intensity", 1)),
			"reference_tags": Array(event.get("reference_tags", [])).duplicate(),
		})
	return result


static func event_template_count() -> int:
	return event_templates().size()


static func interactive_event_count() -> int:
	return interactive_event_templates().size()


static func ambient_template_count() -> int:
	return ambient_templates().size()


static func source_register() -> Dictionary:
	return REFERENCE_REGISTER.duplicate(true)


static func _event(
	id: String,
	family: String,
	min_chapter: int,
	max_chapter: int,
	weight: int,
	cooldown_weeks: int,
	actors: Array,
	title: String,
	kicker: String,
	body: Array,
	choices: Array[Dictionary],
	conditions: Dictionary,
	prerequisites: Array,
	reference_tags: Array,
	earned_delight: bool
) -> Dictionary:
	var tone_tags: Array[String] = ["grounded", "industry_echo", "observational_humor"]
	if earned_delight:
		tone_tags.append("earned_delight")
	return {
		"id": id,
		"family": family,
		"channel": "side_decision",
		"base_weight": weight,
		"chapter_range": [min_chapter, max_chapter],
		"actor_ids": actors.duplicate(),
		"max_per_run": 1,
		"min_chapter": min_chapter,
		"max_chapter": max_chapter,
		"weight": weight,
		"cooldown_weeks": cooldown_weeks,
		"family_cooldown_weeks": 2,
		"actor_cooldown_weeks": 2,
		"once_per_run": true,
		"actors": actors.duplicate(),
		"title": title,
		"kicker": kicker,
		"body": body.duplicate(),
		"choices": choices.duplicate(true),
		"after": "",
		"conditions": conditions.duplicate(true),
		"prerequisites": prerequisites.duplicate(),
		"tone_tags": tone_tags,
		"reference_tags": reference_tags.duplicate(),
		"fictionalized": true,
		"_company_system_event": true,
		"_system_domain": family,
		"_system_decision_id": id,
	}


static func _choices(first: Array, second: Array, delegated: Array) -> Array[Dictionary]:
	return [_choice(first), _choice(second), _choice(delegated)]


static func _choice(source: Array) -> Dictionary:
	return {
		"id": str(source[0]),
		"label": str(source[1]),
		"effects": Dictionary(source[2]).duplicate(true),
		"result": [str(source[3])],
		"ai": bool(source[4]) if source.size() > 4 else false,
	}
