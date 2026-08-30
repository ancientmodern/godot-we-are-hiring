class_name HiringExpansionContent
extends RefCounted

const HiringIndustryEchoContentScript = preload("res://src/hiring_industry_echo_content.gd")

## Systemic side stories for the operating-simulation layer.
##
## These do not replace the 45 authored weekly beats.  They are weighted overlay
## decisions whose exact instance is materialized and saved by the scheduler.

const SYSTEM_ACTIONS: Dictionary = {
	"product_launch": {
		"id": "product_launch", "name": "安排一次产品发布", "category": "strategy",
		"unlock_chapter": 1, "unlock_week": 3, "attention": 1,
		"description": "确定版本边界、客户证据与发布日期；竞品会在同一个市场里回应。",
		"effects": {"narrative": 4, "capability": 1},
		"ai_effects": {"author_weight": 4},
		"manual_summary": "发布进入市场 · 客户线索 +1",
		"ai_summary": "自动打包发布 · 叙事更强",
	},
	"open_requisition": {
		"id": "open_requisition", "name": "推进关键招聘", "category": "strategy",
		"unlock_chapter": 1, "unlock_week": 2, "attention": 1,
		"description": "从岗位 scorecard 继续到面试、竞争 offer、notice 与入职；候选人不是立即到账的人数。",
		"effects": {}, "ai_effects": {"author_weight": 3},
		"manual_summary": "推进一段招聘管线 · 保留证据",
		"ai_summary": "自动推进管线 · 更快进入 offer",
	},
	"vendor_review": {
		"id": "vendor_review", "name": "审查工具栈", "category": "strategy",
		"unlock_chapter": 2, "attention": 1,
		"description": "核对 seat、用量、SSO、续约窗口与退出成本，而不是只比较月价。",
		"effects": {"coherence": 1}, "ai_effects": {"author_weight": 3},
		"manual_summary": "发起采购评估 · 暴露隐藏承诺",
		"ai_summary": "自动谈判 · 当周风险较低",
	},
	"org_review": {
		"id": "org_review", "name": "做组织复盘", "category": "strategy",
		"unlock_chapter": 2, "unlock_week": 3, "attention": 1,
		"description": "检查经理跨度、onboarding、技能覆盖与晋升证据。扩编不再自动等于产出。",
		"effects": {"morale": 2}, "ai_effects": {"author_weight": 3},
		"manual_summary": "组织清晰度上升 · 暴露阻塞",
		"ai_summary": "自动调度汇报线 · 更省心",
	},
	"office_plan": {
		"id": "office_plan", "name": "重做办公室计划", "category": "strategy",
		"unlock_chapter": 2, "unlock_week": 4, "attention": 1,
		"description": "比较租期、押金、工位、会议室和装修工期；漂亮只是合同的一部分。",
		"effects": {"morale": 1}, "ai_effects": {"author_weight": 3},
		"manual_summary": "生成租约与 fit-out 方案",
		"ai_summary": "自动选址 · 候选体验较好",
	},
	"policy_program": {
		"id": "policy_program", "name": "申请研发扶持", "category": "strategy",
		"unlock_chapter": 2, "unlock_week": 5, "attention": 1,
		"description": "提交技术里程碑、合格费用与岗位承诺；它和 VC 使用不同的审核逻辑。",
		"effects": {"coherence": 2}, "ai_effects": {"author_weight": 4},
		"manual_summary": "提交非稀释资金申请",
		"ai_summary": "自动填报 · 承诺范围更大",
	},
}


static func event_templates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	# Capital and investor memory.
	result.append(_event("investor_update_raw", "capital", 1, 8, 7, ["maya_chen"],
		"Maya 要的不是新 deck", "投资人关系 · Juniper Ventures",
		["Maya Chen 回了上一封月报：『不用重做封面。把 cohort、烧钱和你们上次承诺的 eval 发来。』", "共享文档里，她把“承诺”两个字标成了黄色。"],
		_choice_set(
			["send_raw", "发送原始 cohort", {"coherence": 3, "narrative": -2}, "她在三处数据旁留下问题，也把下次 partner meeting 放进了日历。"],
			["headline_only", "只发 headline", {"narrative": 4, "debt": 2}, "邮件很短，转发起来也很方便。黄色标记没有消失。"],
			["delegate", "让它来写", {"narrative": 6, "coherence": 2, "author_weight": 4}, "更新完整、克制、没有一个句子能被继续追问。", true])))
	result.append(_event("customer_reference_diligence", "capital", 1, 7, 8, ["maya_chen", "northstar_health"],
		"客户参考电话", "融资尽调 · 09:30",
		["数据室多出一行：Customer reference / Northstar Health。", "对方愿意接电话，但提醒你：pilot 里仍有三步人工审核。"],
		_choice_set(
			["disclose_workflow", "把人工流程写进去", {"coherence": 4, "narrative": -1}, "投资人把“人工”改成了“当前交付流程”，没有删掉。"],
			["coach_customer", "先和客户对口径", {"narrative": 5, "debt": 4}, "参考电话顺利。客户成功经理会记得这次彩排。"],
			["delegate", "让它来写", {"narrative": 7, "debt": -1, "author_weight": 5}, "它为双方生成了同一份事实清单。所有人都照着说。", true])))
	result.append(_event("preseed_safe_terms", "capital", 1, 9, 10, ["maya_chen"],
		"一张很短的 SAFE", "融资条款 · Post-money",
		["金额是 $750k，valuation cap 是 $8m，pro rata 被勾上。", "附件只有几页。真正改变的是下一张 cap table。"],
		_choice_set(
			["accept_clean", "接受标准条款", {"cash_weeks": 5, "coherence": 2}, "签署完成。林越仍然持股，只是百分比第一次变了。团队在白板上圈住新的 runway，然后终于把融资频道静音了一晚。"],
			["trade_cap_for_rights", "用更低 cap 换掉 pro rata", {"cash_weeks": 5, "narrative": -2}, "这轮更贵，但下一轮少了一项自动延伸的权利。"],
			["delegate", "让它来写", {"cash_weeks": 6, "narrative": 3, "author_weight": 5}, "它在你看到附件前完成了红线。条款很干净。", true])))
	result.append(_event("option_pool_shuffle", "capital", 2, 8, 9, ["maya_chen", "northline_capital"],
		"估值没有看上去那么高", "Seed 条款 · Option pool",
		["Northline 报了更高的 pre-money，同时要求交割前把期权池补到 15%。", "Maya 的版本估值低一点，但池子在交割后补。两列数字只差一个脚注。"],
		_choice_set(
			["founder_friendly", "选交割后补池", {"cash_weeks": 7, "coherence": 2}, "纸面估值低一些。创始团队交割后的比例反而更高。"],
			["headline_valuation", "选更高 headline 估值", {"cash_weeks": 8, "narrative": 5}, "新闻稿用了更大的数字。补池发生在新闻稿之前。"],
			["delegate", "让它来写", {"cash_weeks": 9, "narrative": 6, "author_weight": 6}, "它选了最容易对外解释的一列，并替你准备了稀释说明。", true])))
	result.append(_event("inside_bridge", "capital", 3, 7, 10, ["maya_chen"],
		"八周的 bridge", "现金委员会 · Inside round",
		["Maya 可以在四十八小时内打款。", "条件是月度信息权改成每周，并在出售公司时增加一项 consent。"],
		_choice_set(
			["take_bridge", "拿钱，接受 consent", {"cash_weeks": 8, "coherence": -2}, "钱先到了。下一次重大决定将不再只需要你的签字。"],
			["cut_to_milestone", "拒绝，压到里程碑", {"cash_weeks": -1, "capability": 3, "morale": -5}, "团队冻结招聘，先把可以收费的那一段做完。"],
			["delegate", "让它来写", {"cash_weeks": 9, "coherence": 3, "author_weight": 7}, "它把 consent 改成了只适用于低于某个价格的交易。你没参加电话。", true])))
	result.append(_event("board_consent_required", "capital", 3, 7, 8, ["maya_chen", "board"],
		"这件事需要董事会同意", "治理 · Protective provision",
		["财务把合同退回来了。它同时构成新增债务和年度最低采购承诺。", "Maya 支持，但要求你撤掉客户合同里尚未完成的性能保证。"],
		_choice_set(
			["accept_condition", "删掉性能保证", {"coherence": 5, "narrative": -3}, "董事会通过。客户拿到了一份更短、也更真实的合同。"],
			["lobby_board", "保留保证，逐席争取", {"narrative": 5, "debt": 6}, "议案以一票优势通过。会议纪要逐字记下了你的承诺。"],
			["delegate", "让它来写", {"narrative": 6, "coherence": 4, "author_weight": 6}, "它准备了决议、附件和每位董事可能问的问题。表决只用了七分钟。", true])))

	# Stable competitors and shared market consequences.
	result.append(_event("chorus_release_collision", "market", 2, 10, 6, ["chorus"],
		"Chorus 提前两天发布", "市场带 · Chorus Systems",
		["他们的产品名和你们候选中的第二个名字一样。", "演示里没有出现你们最难的样本，但媒体 embargo 今晚九点解除。"],
		_choice_set(
			["ship_verified", "按原计划，保留核验", {"capability": 3, "narrative": -1}, "报道晚了两小时，客户问答页没有一句需要回收。第一位客户在群里回：『限制写得很清楚。』发布频道亮起一排克制的蓝色勾。"],
			["ship_early", "今晚提前发", {"narrative": 9, "debt": 7}, "你们抢回了半天的注意力。团队把三个已知问题移到『之后修复』。"],
			["delegate", "让它来写", {"narrative": 11, "debt": -1, "author_weight": 6}, "它重新切了发布范围，也重写了所有对比表。媒体把你们放在第一段。", true])))
	result.append(_event("morrow_benchmark", "market", 2, 7, 7, ["morrow"],
		"Morrow 公布了完整 benchmark", "市场带 · Morrow AI",
		["他们把失败样本、置信区间和评测集版本一起放进仓库。", "你们的官网数字更高，但没有同一套 provenance。"],
		_choice_set(
			["rerun_comparable", "按同一方法重跑", {"capability": 4, "narrative": -2, "debt": -3}, "曲线没有官网上漂亮，但工程团队第一次能逐项比较。最难的样本反而赢了，评测群安静两秒，才开始有人截图。"],
			["question_scope", "质疑 benchmark 覆盖面", {"narrative": 6, "coherence": -2}, "讨论转向什么才算真实用户。没有人再问你们有没有复现。"],
			["delegate", "让它来写", {"narrative": 8, "coherence": 3, "author_weight": 5}, "它写了一份既认可对方、又让你们显得领先的技术说明。", true])))
	result.append(_event("harbor_price_cut", "market", 2, 8, 7, ["harbor"],
		"HarborDesk 把 pilot 价格砍了一半", "竞争 · Enterprise",
		["同一个客户把两份报价并排发来。HarborDesk 的基础价更低，超额用量和实施费藏在附表。", "客户只问：你们愿不愿意 match。"],
		_choice_set(
			["hold_price", "保价，缩小 pilot", {"coherence": 4, "narrative": -2}, "试点只覆盖一个团队，毛利与交付边界都还看得见。"],
			["match_price", "匹配价格", {"cash_weeks": -2, "narrative": 6}, "客户签了。财务把这家客户标成『扩张后再盈利』。"],
			["delegate", "让它来写", {"cash_weeks": 1, "narrative": 7, "author_weight": 5}, "它重组了计价单位。客户觉得更便宜，预测毛利反而更高。", true])))
	result.append(_event("shared_customer_trial", "market", 2, 9, 8, ["chorus", "northstar_health"],
		"同一个客户、同一周试用", "销售竞争 · Northstar Health",
		["Northstar 同时接入了你们和 Chorus。", "决策表只有三列：准确、上线时间、十二个月总成本。"],
		_choice_set(
			["differentiate_eval", "用真实 eval 区分", {"capability": 2, "coherence": 4}, "你们没赢所有样本，但赢了最需要解释的那一类。采购把你们列为首选，团队给那个难样本起名叫『周五五点』。"],
			["promise_roadmap", "承诺六周后的路线图", {"narrative": 8, "debt": 8, "cash_weeks": 2}, "采购先把你们列为首选。六周从今天开始计算。"],
			["delegate", "让它来写", {"narrative": 9, "cash_weeks": 3, "author_weight": 6}, "它把现有能力重新打包成了客户的三个采购条目。", true])))
	result.append(_event("competitor_seed_round", "market", 2, 7, 8, ["chorus"],
		"Chorus 完成 $18m Seed", "市场带 · 融资备案",
		["数字比你们这一轮大。第二天，它把平台、销售和招聘负责人三个岗位挂了出来。", "薪酬基准邮件在午饭前到了。"],
		_choice_set(
			["protect_key_roles", "调整关键岗位薪资带", {"cash_weeks": -2, "morale": 6}, "三名员工收到定向调整。全员表格里仍有人能算出差异。"],
			["sell_mission", "不跟现金，重讲使命", {"narrative": 5, "coherence": -1}, "内部信被转发到社交媒体。候选人流量上升，留任问题没有消失。"],
			["delegate", "让它来写", {"morale": 7, "narrative": 6, "author_weight": 5}, "它生成了留任名单、经理话术和一封没人觉得慌张的公告。", true])))
	result.append(_event("competitor_down_round", "market", 3, 6, 10, ["chorus"],
		"Chorus 的 down round", "市场带 · 二级信号",
		["估值下调的消息先从招聘群传出来。", "他们冻结两个团队，也有三名你们去年没抢到的人更新了履历。"],
		_choice_set(
			["reopen_candidates", "重新联系三名候选人", {"morale": 2, "capability": 2}, "两人愿意聊。一人问你们上次为什么拖了十一天才反馈。"],
			["court_customers", "找它的客户", {"narrative": 5, "cash_weeks": 2}, "销售拿到两次会面。客户先问你们能不能承诺不中断服务。"],
			["delegate", "让它来写", {"narrative": 7, "capability": 3, "author_weight": 5}, "它同时运行人才和客户两条名单，措辞里没有一次提到对手的困境。", true])))

	# Recruiting, organization, and human memory.
	result.append(_event("requisition_scope", "people", 1, 9, 5, ["candidate_pool"],
		"到底缺的是谁", "招聘计划 · Platform",
		["产品要一个能立刻救火的人，林越要一个能把平台做成系统的人。", "同一份岗位写成两个版本，薪资带相差 $38k。"],
		_choice_set(
			["senior_ic", "开 Senior IC，写清边界", {"coherence": 4, "capability": 1}, "scorecard 只保留四项必须验证的证据。候选池变小，也更具体；五位面试官第一次在校准会上同时说了『可以』。"],
			["hero_generalist", "找能包办一切的人", {"narrative": 4, "debt": 2}, "简历来得更多。每个面试官理解的『一切』都不一样。"],
			["delegate", "让它来写", {"coherence": 5, "morale": 2, "author_weight": 4}, "它从路线图反推了岗位与 scorecard，连 debrief 模板都建好了。", true])))
	result.append(_event("candidate_counteroffer", "people", 1, 10, 6, ["mei_an", "harbor"],
		"梅安手里还有一份 offer", "候选人 · 截止周四 17:00",
		["HarborDesk：Base $214k，期权 18 bps，Staff title，直属 VP Engineering。", "你们当前版本：$198k，24 bps，Senior，直属林越。她问的不是总包，而是谁会真正给她范围。"],
		_choice_set(
			["increase_scope", "保现金，给 Staff scope", {"capability": 2, "coherence": 2}, "她要求把六个月后的 scope review 写进 offer letter。"],
			["increase_cash", "Base 加到 $218k", {"cash_weeks": -2, "morale": 2}, "她接受了。内部同级薪资压缩将在下一轮校准出现。"],
			["delegate", "让它来写", {"capability": 3, "morale": 4, "author_weight": 5}, "它改了汇报线、签字奖金和 review 条款。她在四点十二分接受；招聘群只发了一枚蓝色圆点，然后把开了四周的文档关掉。", true])))
	result.append(_event("reference_discrepancy", "people", 2, 7, 7, ["qiao_yu"],
		"Reference 里少了六个月", "候选档案 · 乔屿",
		["简历写『主导迁移』。前经理说他是在项目后半段接手，并把故障率降下来了。", "这不是造假，也不是同一件事。"],
		_choice_set(
			["follow_up", "加一轮证据面", {"coherence": 3, "capability": 1}, "他把事故时间线画了出来。最强的部分确实发生在接手以后。"],
			["withdraw", "撤回流程", {"morale": -1}, "岗位重新开放。猎头在 CRM 里把原因标成『叙述边界』。"],
			["delegate", "让它来写", {"coherence": 4, "author_weight": 4}, "它把冲突拆成了四个可验证问题，第二天完成了补充访谈。", true])))
	result.append(_event("title_inflation", "people", 2, 7, 8, ["candidate_pool"],
		"第三个 Head of", "招聘校准 · Title",
		["候选人接受薪资和期权，唯一条件是 Head of AI Platform。", "组织里已有 Head of Research 和 Head of Product；目前平台团队是两个人。"],
		_choice_set(
			["principal_track", "给 Principal IC 双轨", {"coherence": 5, "capability": 2}, "她接受了书面 scope，但要求晋升校准不能由现任 Head 独占。"],
			["grant_title", "给 title，先把人拿下", {"capability": 3, "coherence": -4}, "她入职了。下周组织图需要解释三位 Head 之间谁对结果负责。"],
			["delegate", "让它来写", {"capability": 3, "coherence": 3, "author_weight": 5}, "它发明了一个准确、体面、不会立即制造汇报冲突的 title。", true])))
	result.append(_event("first_manager_span", "org", 2, 8, 7, ["lin_yue"],
		"林越有九名直属", "组织复盘 · Manager span",
		["她的日历里，一对一已经占掉两天半。", "平台、评测和研究都仍然把最后一个决定留给她。"],
		_choice_set(
			["appoint_acting_lead", "任命 acting lead", {"capability": 2, "morale": 3}, "一名 Senior 接走四条汇报线，自己的项目进入半速。"],
			["cancel_one_on_ones", "改成双周一对一", {"capability": 3, "morale": -4}, "日历空出来。两个入职未满月的人没有再问同一个问题。"],
			["delegate", "让它来写", {"capability": 3, "morale": 4, "author_weight": 5}, "它重新分组、生成议程并替她写了所有 follow-up。", true])))
	result.append(_event("promotion_calibration", "org", 3, 7, 8, ["chen_xiaoyu", "people_team"],
		"同样的表现，不同的证据", "晋升校准 · IC4 → IC5",
		["陈小雨的经理写了『一直很可靠』，没有列业务影响。另一份材料有六页，作者是 LANTERN。", "委员会不能晋升一句形容词。"],
		_choice_set(
			["defer_with_scope", "延期，并补 scope 与证据", {"morale": -2, "coherence": 4}, "她没有同意，但知道下一次需要什么，也知道谁负责提供机会。"],
			["promote_on_judgment", "凭共同判断晋升", {"morale": 6, "coherence": -2, "cash_weeks": -1}, "晋升通过。财务提醒同级薪资带已经倒挂。"],
			["delegate", "让它来写", {"morale": 7, "coherence": 4, "author_weight": 6}, "它从十二个月记录里补齐证据。材料比她经理更了解她的工作。", true])))
	result.append(_event("mentor_burnout", "org", 3, 6, 7, ["guo_jun"],
		"郭骏带了四个新人", "人才培养 · Mentoring",
		["四人的 ramp 都在上升，他自己的交付连续两周后移。", "周报里，他把『帮助』写成了每一天的第一项。"],
		_choice_set(
			["protect_mentor_time", "砍掉一项交付", {"capability": 2, "morale": 5, "narrative": -2}, "新人继续变快。他第一次在六点前离开，临走前发现四个人已经能互相回答同一个问题。"],
			["rotate_mentors", "把新人分给三个人", {"capability": 3, "morale": -1}, "负担散开，三个项目都多了一点上下文切换。"],
			["delegate", "让它来写", {"capability": 4, "morale": 4, "author_weight": 5}, "它把 onboarding 变成了文档、录屏和自动检查。郭骏只处理例外。", true])))
	result.append(_event("key_person_poach", "people", 3, 9, 7, ["chen_xiaoyu", "chorus"],
		"Chorus 找到了陈小雨", "人才竞争 · Retention",
		["对方给 Principal title、$236k 和 22 bps。", "她没有把 offer 转发给 HR。她先问你：『如果我留下，数据质量到底是谁的目标？』"],
		_choice_set(
			["give_mandate", "给明确 mandate 和预算", {"capability": 4, "cash_weeks": -1, "morale": 4}, "她留下。路线图多了一条不再允许被其它发布挤掉的工作。"],
			["match_package", "匹配总包", {"cash_weeks": -3, "morale": 3}, "她留下，但问题没有被薪资回答。"],
			["delegate", "让它来写", {"capability": 4, "morale": 6, "author_weight": 6}, "它拿出了她过去一年所有被推迟的目标，并给每一条安排了负责人。", true])))

	# Lease, fit-out, and procurement commitments.
	result.append(_event("office_shortlist", "office", 2, 8, 9, ["landlord_8th", "landlord_rail"],
		"两份办公室租约", "不动产 · Shortlist",
		["8th Street：34 个合法席位、四年期、六个月免租、地铁远。", "Rail Yard：24 个席位、两年 break、网络和 HVAC 更好，接待区很小。"],
		_choice_set(
			["rail_yard", "选 Rail Yard 的弹性", {"cash_weeks": -2, "capability": 2}, "押金到账。会议室只有两间，至少合同允许你们两年后离开。"],
			["eighth_street", "选 8th Street 的容量", {"cash_weeks": -3, "narrative": 4}, "免租期很好看。恢复原状义务在第四十七页。"],
			["delegate", "让它来写", {"cash_weeks": -1, "morale": 4, "author_weight": 5}, "它算完通勤、扩编和 break clause，选了没有一张漂亮照片的那份。团队看完通勤图，第一次对办公室方案全票通过。", true])))
	result.append(_event("landlord_free_rent", "office", 2, 7, 8, ["landlord_8th"],
		"再给三个月免租", "租约谈判 · Term trade",
		["房东愿意增加免租，条件是取消第二年的 break。", "经纪人把这叫作『对 runway 友好』。"],
		_choice_set(
			["keep_break", "保留 break", {"cash_weeks": -1, "coherence": 2}, "当期现金更紧，退出选项还在。"],
			["take_free_rent", "拿免租，锁四年", {"cash_weeks": 3, "debt": 2}, "runway 立刻变长。未来的空工位也从今天开始计价。"],
			["delegate", "让它来写", {"cash_weeks": 2, "coherence": 3, "author_weight": 4}, "它换回了一个有条件的 sublease 权。经纪人说这很少见。", true])))
	result.append(_event("fitout_delay", "office", 2, 7, 7, ["build_partner"],
		"消防图纸退回一次", "装修 · Week 2 / 4",
		["安静舱改变了疏散宽度。承包商可以拆掉一个，或加急重画并顺延一周。", "新员工的 offer 上写着办公地址。"],
		_choice_set(
			["remove_booth", "拆一间安静舱", {"cash_weeks": 1, "morale": -2}, "按时搬入。深度工作区比图纸少了两个位置。"],
			["redraw", "顺延一周，保留方案", {"cash_weeks": -2, "morale": 2}, "团队多付一周临时空间。消防图纸第二次通过；行政把那枚『批准』章贴进装修群，获得了本周最多的回应。"],
			["delegate", "让它来写", {"cash_weeks": -1, "morale": 4, "author_weight": 4}, "它重排了动线，没有减少任何功能。你只看见最终批准邮件。", true])))
	result.append(_event("meeting_room_capacity", "office", 3, 6, 6, ["office_manager"],
		"八场面试、两间会议室", "空间运营 · Capacity",
		["销售 demo、候选面和一对一在同一个下午重叠。", "行政建议把储物间改成临时电话间。门牌已经打印成『D』。"],
		_choice_set(
			["stagger_schedule", "错开日历", {"coherence": 3, "morale": -1}, "没人需要在储物间面试。两个候选流程延长了三天。"],
			["convert_storage", "改造临时电话间", {"cash_weeks": -1, "morale": 2}, "门关上以后很安静。门禁系统把它识别成会议室 D；一周后，已经没人记得 D 原来代表储物间。"],
			["delegate", "让它来写", {"morale": 4, "coherence": 3, "author_weight": 4}, "它重新排了所有日历。会议室 D 仍然留在资源列表里。", true])))
	result.append(_event("office_hvac", "office", 3, 6, 7, ["landlord_rail"],
		"周六的 HVAC 不在租金里", "设施 · After-hours",
		["训练和客户迁移都排在周末。房东报价每小时 $280，最低八小时。", "服务器区当前温度已经超过建议值。"],
		_choice_set(
			["pay_after_hours", "支付周末 HVAC", {"cash_weeks": -1, "capability": 2}, "迁移按计划结束。周一没有人需要解释温度告警。"],
			["move_work", "把工作移到工作日", {"narrative": -2, "morale": 2}, "客户窗口顺延。团队不用在周六来。"],
			["delegate", "让它来写", {"capability": 2, "cash_weeks": 0, "author_weight": 4}, "它把训练拆成夜间窗口，并申请到一次房东 credit。", true])))
	result.append(_event("sublease_opportunity", "office", 3, 6, 9, ["chorus", "landlord_8th"],
		"Chorus 想接走半层", "租约 · Sublease",
		["他们 down round 后退掉了另一栋楼，但需要十八个席位。", "你们可以转租闲置区，条件是共享前台与两间会议室。"],
		_choice_set(
			["sublease", "转租，接受共享", {"cash_weeks": 4, "morale": -2}, "每月现金压力下降。周二下午，两个公司的候选人在前台坐在一起。"],
			["keep_capacity", "保留扩编容量", {"narrative": 2, "cash_weeks": -1}, "空位继续计租。董事会把它写成增长预留。"],
			["delegate", "让它来写", {"cash_weeks": 5, "morale": 1, "author_weight": 5}, "它画出独立动线并重排会议室权利。合同在对方看到平面图前就签了。", true])))
	result.append(_event("identity_plan_wall", "saas", 2, 8, 7, ["quietwire_annual"],
		"SSO 在 Enterprise 套餐", "供应商 · QuietWire",
		["QuietWire 的采购报价每 seat $12。开启 SSO/SCIM 后变成 $31，并要求 50 seat 年付。", "安全问卷把自动 offboarding 标成上线前条件。"],
		_choice_set(
			["upgrade", "升级并年付", {"cash_weeks": -2, "coherence": 4}, "权限回收从清单变成流程。财务多了一项不能按月退出的承诺。"],
			["manual_controls", "保留套餐，人工回收", {"cash_weeks": 1, "morale": -2}, "行政每周导出一次用户表。离职账号在下一次导出前仍然有效。"],
			["delegate", "让它来写", {"coherence": 5, "cash_weeks": 0, "author_weight": 4}, "它谈到 30 seat 的 ramp 条款，并自动生成了供应商审查材料。", true])))
	result.append(_event("dormant_seat_audit", "saas", 2, 7, 6, ["quietwire_annual", "forgenest_team", "staffloom_core"],
		"十一个 dormant seat", "采购台账 · True-up",
		["QuietWire、ForgeNest 和 StaffLoom 的活跃人数各不相同。", "其中一个账号属于三个月前离开的人；另一个写着沈砚。"],
		_choice_set(
			["deprovision", "逐项回收", {"cash_weeks": 1, "coherence": 3}, "十个 seat 被释放，下一张账单终于短了一行。沈砚的账号显示：同步成功。"],
			["leave_buffer", "保留五个缓冲 seat", {"morale": 1}, "下次入职更快。财务继续为名字之外的容量付费。"],
			["delegate", "让它来写", {"cash_weeks": 2, "coherence": 4, "author_weight": 4}, "它完成了跨系统回收。审计报告仍然显示三十七个身份。", true])))
	result.append(_event("ci_usage_overage", "saas", 2, 7, 6, ["forgenest_team"],
		"CI 用量超过承诺 63%", "供应商 · ForgeNest",
		["发布分支的每次提交都会跑完整评测。超额单价是承诺价的 2.4 倍。", "工程团队说缓存能做，但会占掉一个 sprint。"],
		_choice_set(
			["build_cache", "做缓存与分层测试", {"capability": 3, "narrative": -2, "cash_weeks": 1}, "两周后账单下降，失败反馈也快了七分钟。工程频道第一次主动贴了一张供应商账单。"],
			["buy_commit", "提高年度用量承诺", {"cash_weeks": -1, "capability": 2}, "单价降低。最低承诺从今天持续到战役之外。"],
			["delegate", "让它来写", {"capability": 3, "cash_weeks": 1, "author_weight": 4}, "它改了工作流、缓存键和供应商档位。团队只收到一张前后账单。", true])))
	result.append(_event("vendor_outage_demo", "saas", 3, 8, 7, ["signalharbor_observe", "northstar_health"],
		"Demo 前十分钟，观测平台离线", "供应商事故 · SignalHarbor",
		["产品仍在运行，只是没有 trace。客户的安全负责人正好要看审计记录。", "状态页写：Investigating。"],
		_choice_set(
			["show_degraded", "如实展示降级模式", {"coherence": 5, "narrative": -2}, "客户看见了手工导出的日志，也看见你们知道缺了什么。安全负责人会后说：『这比一场完美 demo 更有用。』"],
			["delay_demo", "把会议推迟两小时", {"narrative": -3, "debt": 1}, "平台恢复了。客户在新的邀请上没有写原因。"],
			["delegate", "让它来写", {"narrative": 4, "coherence": 4, "author_weight": 5}, "它用本地数据重建了演示证据，并在会议结束后自动补交审计包。", true])))
	result.append(_event("automatic_renewal", "saas", 3, 7, 7, ["quietwire_annual"],
		"退出窗口昨天关闭", "续约日历 · QuietWire",
		["合同自动续了十二个月，seat 按当前峰值 true-up。", "采购邮箱里有三封提醒，都被规则归到了『供应商通知』。"],
		_choice_set(
			["negotiate_credit", "承认失误，谈 credit", {"cash_weeks": -1, "coherence": 3}, "供应商给了两个月 credit，自动续约仍然有效。"],
			["start_migration", "启动迁移并双跑", {"cash_weeks": -3, "capability": 2}, "两套工具同时收费。至少下一次窗口已经写进所有人的日历。"],
			["delegate", "让它来写", {"cash_weeks": 0, "coherence": 4, "author_weight": 5}, "它找到了采购附件里的价格保护，并把续约改成三十天可退。", true])))
	result.append(_event("vendor_acquisition", "saas", 3, 6, 9, ["signalharbor_observe"],
		"SignalHarbor 被收购", "供应商变更 · Subprocessor",
		["新条款增加了一个 AI subprocessor，并把日志默认留存从 30 天改成 180 天。", "客户 DPA 要求任何变化提前通知。"],
		_choice_set(
			["security_review", "暂停升级，重做审查", {"coherence": 5, "capability": -1}, "产品暂时失去一个新功能。客户收到了一份完整变更通知。"],
			["accept_terms", "接受新条款", {"capability": 2, "debt": 3}, "功能当天可用。DPA 清单还停在上一个版本。"],
			["delegate", "让它来写", {"capability": 2, "coherence": 5, "author_weight": 5}, "它完成了数据流图、DPA 红线和客户通知。没有会议。", true])))

	# Government support and later rule-setting power.
	result.append(_event("rnd_grant_phase_one", "policy", 2, 8, 9, ["innovation_office"],
		"非稀释资金，但要交付真的东西", "研发扶持 · Phase I",
		["项目上限 $200k，首笔 $75k 只在签约后到账，尾款绑定可复现 eval。", "申请书要求列出技术风险，不接受『市场领先』作为里程碑。"],
		_choice_set(
			["technical_scope", "提交窄而可验证的范围", {"capability": 3, "coherence": 4}, "申请进入技术评审。评审表里没有一项叫叙事，却把你们最难的 eval 标成了『范围清楚』；工程团队把回执打印了一份。"],
			["broad_jobs_story", "扩大岗位与产业承诺", {"narrative": 5, "debt": 3}, "申请更容易被转发，里程碑也多了三项。"],
			["delegate", "让它来写", {"capability": 3, "narrative": 4, "author_weight": 5}, "它把真实工作翻译成了每一项合格费用和可验收结果。", true])))
	result.append(_event("jobs_tax_credit", "policy", 2, 7, 10, ["economic_development_office"],
		"税收抵免不是今天的现金", "政策扶持 · Jobs commitment",
		["方案按未来两年新增全职岗位与本地投资计算。", "公司目前没有足够应税利润；兑现前，它只是一项递延资产和公开承诺。"],
		_choice_set(
			["modest_commitment", "承诺 12 个岗位", {"narrative": 2, "coherence": 3}, "额度较小，招聘计划仍然允许变化。"],
			["headline_commitment", "承诺 40 个岗位", {"narrative": 7, "debt": 5}, "市长办公室把数字写进新闻稿。裁员与搬迁条款也写进协议。"],
			["delegate", "让它来写", {"narrative": 6, "coherence": 4, "author_weight": 5}, "它用现有计划拆出了既能通过评审、又不立即触发 clawback 的口径。", true])))
	result.append(_event("public_comment_window", "policy", 3, 9, 9, ["digital_services_agency", "morrow", "chorus"],
		"公开征求意见还剩 24 天", "政策档案 · Eval disclosure",
		["草案要求企业 AI 供应商披露评测集 provenance 与重大人工干预。", "Morrow 支持，Chorus 主张行业自律。规则会同样作用于所有公司。"],
		_choice_set(
			["support_disclosure", "支持强制披露", {"capability": 3, "narrative": -2, "coherence": 4}, "意见书附了你们可以公开复现的部分。能力强的公司得到结构性优势。"],
			["industry_self_rule", "提议行业自律", {"narrative": 5, "debt": 3}, "协会采用了你们的措辞。监管方要求六个月后汇报执行率。"],
			["delegate", "让它来写", {"narrative": 6, "capability": 2, "author_weight": 7}, "它写出一套恰好以你们现有流程为基线的标准。", true])))
	result.append(_event("agency_roundtable", "policy", 3, 7, 8, ["digital_services_agency", "morrow", "chorus"],
		"圆桌上的最后一个席位", "政务关系 · Agency roundtable",
		["议题是公共部门采购 AI 时应要求什么证据。", "参会名单里有 Morrow、Chorus、两家大公司和你。会议不允许带销售 deck。"],
		_choice_set(
			["bring_engineer", "带评测工程师", {"capability": 2, "coherence": 4}, "她回答了三个具体问题。会后，采购模板多了一项失败样本披露；回程电梯里，她才发现自己一直握着没打开的水。"],
			["bring_policy_lead", "带政策负责人", {"narrative": 4, "coherence": 2}, "你们参与了后续工作组。技术细节留到书面意见。"],
			["delegate", "让它来写", {"narrative": 6, "coherence": 4, "author_weight": 6}, "你带了一份它准备的 briefing。每个问题都像提前见过。", true])))
	result.append(_event("government_pilot", "policy", 3, 8, 10, ["public_benefits_agency"],
		"政府 pilot 的钱在验收以后", "公共采购 · 交付合同",
		["合同金额 $250k，先交付、后付款。安全审查、可访问性和审计日志都是验收项。", "这不是补贴，也不是一张立即增加 runway 的支票。"],
		_choice_set(
			["accept_scoped", "缩小范围后接受", {"cash_weeks": -2, "capability": 4, "coherence": 4}, "团队开始交付。应收账款被单独列出，没有算进现金。"],
			["accept_full", "接受完整范围", {"narrative": 6, "cash_weeks": -3, "debt": 4}, "新闻稿先发了。验收清单从今天开始计时。"],
			["delegate", "让它来写", {"narrative": 6, "capability": 4, "author_weight": 6}, "它把现有产品映射到每一项采购要求，并自动建立证据目录。", true])))
	result.append(_event("registered_policy_adviser", "policy", 3, 6, 10, ["public_affairs_firm"],
		"聘请政策顾问以后会公开披露", "政务关系 · Registered engagement",
		["顾问能安排听证准备、联盟会议与规则追踪。", "费用、议题与季度活动会进入公开记录；政府客户还会看利益冲突。"],
		_choice_set(
			["hire_with_scope", "限定为技术标准议题", {"cash_weeks": -2, "coherence": 4, "narrative": 3}, "access 上升，披露表只出现一个清楚的议题。"],
			["build_internal", "培养内部政策负责人", {"cash_weeks": -1, "capability": 2}, "进展更慢，团队开始能自己读懂草案和窗口。"],
			["delegate", "让它来写", {"narrative": 6, "coherence": 3, "author_weight": 6}, "它选择顾问、限定授权并完成所有披露。公司第一次能稳定影响规则日历。", true])))
	result.append(_event("industry_standard_draft", "policy", 4, 5, 12, ["lantern", "industry_coalition"],
		"LANTERN 已经写好行业标准草案", "董事会材料 · Policy signature",
		["标准要求的日志格式、评测周期和供应商控制，恰好与公司现有系统一致。", "文件署名栏仍然留着你的位置。"],
		_choice_set(
			["sign_with_amendment", "手改一处，再签", {"coherence": 4, "capability": 2}, "你删掉了最有利于公司的例外。工作组接受了修改。"],
			["refuse_signature", "拒绝以创始人名义提交", {"narrative": -5, "morale": 4}, "草案仍由联盟提交，只是没有你的名字。"],
			["delegate", "让它来写", {"narrative": 7, "coherence": 5, "author_weight": 8}, "它完成了最后版本，也替你留下一个非常像你的停顿。", true])))

	# Industry folklore is kept in a separate, auditable pack.  These events use
	# the same scheduler and system-resolution path as the rest of the operating
	# simulation; recognition of the real-world allusion is never required.
	for echo_value in HiringIndustryEchoContentScript.interactive_event_templates():
		result.append(Dictionary(echo_value).duplicate(true))
	_enrich_event_templates(result)
	return result


static func event_template_count() -> int:
	return event_templates().size()


static func industry_ambient_templates() -> Array[Dictionary]:
	return HiringIndustryEchoContentScript.ambient_templates()


static func _enrich_event_templates(events: Array[Dictionary]) -> void:
	var metadata_by_id := _event_metadata()
	var earned_delight_ids := _earned_delight_event_ids()
	for index in range(events.size()):
		var event: Dictionary = events[index]
		var event_id := str(event.get("id", ""))
		var metadata: Dictionary = Dictionary(metadata_by_id.get(event_id, {}))
		var max_chapter := int(metadata.get("max_chapter", event.get("max_chapter", 4)))
		event["max_chapter"] = max_chapter
		event["chapter_range"] = [int(event.get("min_chapter", 1)), max_chapter]
		event["conditions"] = Dictionary(metadata.get("conditions", event.get("conditions", {}))).duplicate(true)
		event["prerequisites"] = Array(metadata.get("prerequisites", event.get("prerequisites", []))).duplicate()
		var tone_tags: Array = Array(event.get("tone_tags", ["grounded"])).duplicate()
		if not tone_tags.has("grounded"):
			tone_tags.push_front("grounded")
		if earned_delight_ids.has(event_id) and not tone_tags.has("earned_delight"):
			tone_tags.append("earned_delight")
		event["tone_tags"] = tone_tags
		events[index] = event


static func _event_metadata() -> Dictionary:
	return {
		"investor_update_raw": {
			"max_chapter": 3,
			"conditions": {"all_flags": ["has_external_investor"]},
			"prerequisites": ["preseed_or_later"],
		},
		"customer_reference_diligence": {
			"max_chapter": 2,
			"conditions": {"none_flags": ["has_series_a"]},
			"prerequisites": ["capital_outreach"],
		},
		"preseed_safe_terms": {
			"max_chapter": 1,
			"conditions": {"none_flags": ["has_preseed"]},
			"prerequisites": ["capital_outreach"],
		},
		"option_pool_shuffle": {
			"max_chapter": 2,
			"conditions": {"all_flags": ["has_preseed"], "none_flags": ["has_seed"]},
			"prerequisites": ["preseed_or_later"],
		},
		"inside_bridge": {
			"max_chapter": 3,
			"conditions": {"all_flags": ["has_external_investor"]},
			"prerequisites": ["external_investor_relationship"],
		},
		"board_consent_required": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["has_external_investor"]},
			"prerequisites": ["board_or_investor_rights"],
		},
		"chorus_release_collision": {
			"max_chapter": 3,
			"conditions": {"gte": {"team_size": 2}},
			"prerequisites": ["product_launch_lane"],
		},
		"morrow_benchmark": {
			"max_chapter": 3,
			"conditions": {"gte": {"team_size": 2}},
			"prerequisites": ["published_product_claims"],
		},
		"harbor_price_cut": {
			"max_chapter": 4,
			"conditions": {"gte": {"team_size": 2}},
			"prerequisites": ["enterprise_sales_motion"],
		},
		"shared_customer_trial": {
			"max_chapter": 3,
			"conditions": {"gte": {"team_size": 2}},
			"prerequisites": ["enterprise_sales_motion"],
		},
		"competitor_seed_round": {
			"max_chapter": 3,
			"conditions": {"gte": {"team_size": 3}},
			"prerequisites": ["competitive_market"],
		},
		"competitor_down_round": {
			"max_chapter": 4,
			"conditions": {"gte": {"team_size": 4}},
			"prerequisites": ["competitive_market"],
		},
		"requisition_scope": {
			"max_chapter": 2,
			"conditions": {"gte": {"team_size": 1}},
			"prerequisites": ["hiring_lane_unlocked"],
		},
		"candidate_counteroffer": {
			"max_chapter": 3,
			# A counteroffer is actionable only after our own offer exists. An
			# interview pipeline alone can remain active for weeks before terms are
			# negotiable, which used to create a convincing-looking no-op modal.
			"conditions": {"gte": {"operations.active_offers": 1}},
			"prerequisites": ["active_candidate_pipeline"],
		},
		"reference_discrepancy": {
			"max_chapter": 3,
			"conditions": {"gte": {"operations.active_candidates": 1}},
			"prerequisites": ["active_candidate_pipeline"],
		},
		"title_inflation": {
			"max_chapter": 3,
			"conditions": {"gte": {"operations.active_candidates": 1}},
			"prerequisites": ["active_candidate_pipeline"],
		},
		"first_manager_span": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["employee_lin_yue_active"], "gte": {"team_size": 9}},
			"prerequisites": ["manager_span_at_scale"],
		},
		"promotion_calibration": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["employee_chen_xiaoyu_active"], "gte": {"team_size": 4}},
			"prerequisites": ["employee_history"],
		},
		"mentor_burnout": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["employee_guo_jun_active"], "gte": {"team_size": 5}},
			"prerequisites": ["multiple_recent_hires"],
		},
		"key_person_poach": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["employee_chen_xiaoyu_active"], "gte": {"team_size": 4}},
			"prerequisites": ["employee_history", "competitive_market"],
		},
		"office_shortlist": {
			"max_chapter": 2,
			"conditions": {"none_flags": ["has_active_lease"]},
			"prerequisites": ["office_planning_unlocked"],
		},
		"landlord_free_rent": {
			"max_chapter": 3,
			"conditions": {"all_flags": ["has_active_lease"]},
			"prerequisites": ["signed_office_lease"],
		},
		"fitout_delay": {
			"max_chapter": 3,
			"conditions": {"all_flags": ["has_active_lease"]},
			"prerequisites": ["signed_office_lease"],
		},
		"meeting_room_capacity": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["has_active_lease"], "gte": {"team_size": 8}},
			"prerequisites": ["occupied_office"],
		},
		"office_hvac": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["has_active_lease"]},
			"prerequisites": ["occupied_office"],
		},
		"sublease_opportunity": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["has_active_lease", "has_external_investor"], "gte": {"team_size": 6}},
			"prerequisites": ["signed_office_lease", "competitive_market"],
		},
		"identity_plan_wall": {
			"max_chapter": 3,
			"conditions": {"none_flags": ["subscribed_quietwire_annual"], "gte": {"team_size": 4}},
			"prerequisites": ["vendor_review_unlocked"],
		},
		"dormant_seat_audit": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["has_saas"], "gte": {"team_size": 4}},
			"prerequisites": ["active_saas_subscription"],
		},
		"ci_usage_overage": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["subscribed_forgenest_team"]},
			"prerequisites": ["forgenest_team_subscription"],
		},
		"vendor_outage_demo": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["subscribed_signalharbor_observe"]},
			"prerequisites": ["signalharbor_observe_subscription"],
		},
		"automatic_renewal": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["subscribed_quietwire_annual"]},
			"prerequisites": ["quietwire_annual_subscription"],
		},
		"vendor_acquisition": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["subscribed_signalharbor_observe"]},
			"prerequisites": ["signalharbor_observe_subscription"],
		},
		"rnd_grant_phase_one": {
			"max_chapter": 3,
			"conditions": {"equals": {"business.policy.programs": {}}},
			"prerequisites": ["policy_program_unlocked"],
		},
		"jobs_tax_credit": {
			"max_chapter": 3,
			"conditions": {"equals": {"business.policy.deferred_tax_credit_usd": 0}},
			"prerequisites": ["growth_plan"],
		},
		"public_comment_window": {
			"max_chapter": 4,
			"conditions": {"gte": {"team_size": 5, "business.policy.regulatory_credibility": 5}},
			"prerequisites": ["policy_credibility"],
		},
		"agency_roundtable": {
			"max_chapter": 4,
			"conditions": {"gte": {"business.policy.regulatory_credibility": 8}},
			"prerequisites": ["policy_credibility"],
		},
		"government_pilot": {
			"max_chapter": 4,
			"conditions": {"equals": {"business.policy.pilots": {}}, "gte": {"business.policy.regulatory_credibility": 5}},
			"prerequisites": ["policy_credibility"],
		},
		"registered_policy_adviser": {
			"max_chapter": 4,
			"conditions": {"all_flags": ["has_external_investor"], "gte": {"team_size": 6}},
			"prerequisites": ["public_policy_activity"],
		},
		"industry_standard_draft": {
			"max_chapter": 4,
			"conditions": {"equals": {"business.policy.coalition_member": true}, "gte": {"team_size": 8}},
			"prerequisites": ["industry_coalition_membership"],
		},
	}


static func _earned_delight_event_ids() -> Array[String]:
	return [
		"preseed_safe_terms",
		"chorus_release_collision",
		"morrow_benchmark",
		"shared_customer_trial",
		"requisition_scope",
		"candidate_counteroffer",
		"mentor_burnout",
		"office_shortlist",
		"fitout_delay",
		"meeting_room_capacity",
		"dormant_seat_audit",
		"ci_usage_overage",
		"vendor_outage_demo",
		"rnd_grant_phase_one",
		"agency_roundtable",
	]


static func _event(
	id: String,
	family: String,
	min_chapter: int,
	weight: int,
	cooldown_weeks: int,
	actors: Array,
	title: String,
	kicker: String,
	body: Array,
	choices: Array[Dictionary]
) -> Dictionary:
	return {
		"id": id,
		"family": family,
		"channel": "side_decision",
		"base_weight": weight,
		"chapter_range": [min_chapter, 4],
		"actor_ids": actors.duplicate(),
		"max_per_run": 1,
		"min_chapter": min_chapter,
		"max_chapter": 4,
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
		"_company_system_event": true,
		"_system_domain": family,
		"_system_decision_id": id,
	}


static func _choice_set(first: Array, second: Array, delegated: Array) -> Array[Dictionary]:
	return [
		_choice(first),
		_choice(second),
		_choice(delegated),
	]


static func _choice(source: Array) -> Dictionary:
	return {
		"id": str(source[0]),
		"label": str(source[1]),
		"effects": Dictionary(source[2]).duplicate(true),
		"result": [str(source[3])],
		"ai": bool(source[4]) if source.size() > 4 else false,
	}
