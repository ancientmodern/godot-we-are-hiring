class_name HiringContent
extends RefCounted

## Static narrative and design database for We're Hiring / 《我们正在招人》.
##
## Stable schemas:
## - CHAPTERS entries: id, name, duration, model_official, model_nickname,
##   team_target, intention.
## - ACTIONS entries: id, name, category, unlock_chapter, optional unlock_week,
##   attention, description, effects, ai_effects. `effects` is the settlement
##   declaration; `ai_effects` stores only the hidden authorship price because
##   the model owns one shared delegation modifier instead of a rival table.
## - FIXED_EVENTS entries: id, title, kicker, body, choices, after.
## - Event choices: id, label, ai, effects, result, flags, optional condition.
## Effect dictionaries use GameModel additive keys: cash_weeks, compute, narrative,
## capability, coherence, debt, author_weight, morale, belief, attention and
## training_boost_uses. Random ranges use a two-element [minimum, maximum] array.

const SCHEMA_VERSION: int = 1

const CHAPTERS: Array[Dictionary] = [
	{
		"id": 0,
		"name": "第零章 · 车库",
		"duration": 3,
		"model_official": "lantern-v0.1",
		"model_nickname": "那个模型",
		"team_target": 2,
		"intention": "教会一周怎么过。让玩家喜欢林越。",
	},
	{
		"id": 1,
		"name": "第一章 · Pre-seed",
		"duration": 8,
		"model_official": "lantern-v0.4",
		"model_nickname": "阿灯",
		"team_target": 4,
		"intention": "让玩家自己发现：训练没用，发推有用。",
	},
	{
		"id": 2,
		"name": "第二章 · Seed",
		"duration": 12,
		"model_official": "lantern-v1",
		"model_nickname": "阿灯",
		"team_target": 9,
		"intention": "第一次还债。第一次点『让它来写』。",
	},
	{
		"id": 3,
		"name": "第三章 · A 轮",
		"duration": 14,
		"model_official": "Lantern",
		"model_nickname": "阿灯",
		"team_target": 22,
		"intention": "第一次有人因为你的决定离开。选项开始不像你写的。",
	},
	{
		"id": 4,
		"name": "第四章 · 终局",
		"duration": 8,
		"model_official": "LANTERN",
		"model_nickname": "",
		"team_target": 37,
		"intention": "让玩家无事可做，而公司运转得比任何时候都好。",
	},
]

const MODEL_PROGRESSION: Array[Dictionary] = [
	{"chapter": 0, "official": "lantern-v0.1", "nickname": "那个模型", "author_stage": 1},
	{"chapter": 1, "official": "lantern-v0.4", "nickname": "阿灯", "author_stage": 1},
	{"chapter": 2, "official": "lantern-v1", "nickname": "阿灯", "author_stage": 2},
	{"chapter": 3, "official": "Lantern", "nickname": "阿灯", "author_stage": 3},
	{"chapter": 4, "official": "LANTERN", "nickname": "", "author_stage": 5},
]

const COMPANY_PROFILE: Dictionary = {
	"default_name": "提灯实验室",
	"english_name": "Lantern Labs",
	"player_can_rename": true,
	"location": "现在 · 湾区",
	"origin": "一间转租来的联合办公工位，两个人，一张显卡。",
	"first_mission": "做一个能听懂人在说什么的东西。",
	"first_value": "如果做不出来，就说做不出来。",
	"protagonist": "无名、无脸，姓名、外貌与家庭背景留白；只固定与林越共同经历过的那段交换项目。观察力过剩，行动力不足。",
	"protagonist_tell": "从不在『我们』后面停顿。",
	"founder_relationship": "你和林越在七年前的大学交换项目里认识。你们共同做过一次通宵课程项目，彼此有过没有说破的吸引力，从未正式在一起。现在是联合创始人；默契、边界和旧日暧昧同时存在。",
	"tone": "不是恐怖。是凌晨三点的办公室。通关后应当让玩家认出自己的某段工作经历。",
}

const STAT_DEFINITIONS: Array[Dictionary] = [
	{"id": "cash_weeks", "name": "现金", "visible": true, "display": "还剩几周", "meaning": "焦虑"},
	{"id": "compute", "name": "算力", "visible": true, "display": "数值", "meaning": "稀缺"},
	{"id": "narrative", "name": "叙事", "visible": true, "display": "0–100", "meaning": "外界相信你能做到什么"},
	{"id": "capability", "name": "能力", "visible": true, "display": "0–100", "meaning": "你实际能做到什么"},
	{"id": "coherence", "name": "连贯", "visible": true, "display": "0–100", "meaning": "你的话之间还有没有关系"},
	{"id": "debt", "name": "债", "visible": false, "display": "办公室的样子", "meaning": "叙事和能力之间的距离，欠下的，要还"},
	{"id": "author_weight", "name": "作者权重", "visible": false, "display": "不显示", "meaning": "这家公司有多少是它写的"},
]

const WORLD_RULES: Array[String] = [
	"异常只在办公室里。走出楼门，世界完全正常；物理边界就是公司的租约范围。",
	"异常从不威胁：不追赶、不发声、不注视、不靠近，只是在那里。",
	"异常从不被解释。没有隐藏文档、真相揭露或最终答案。",
	"角色永远作行政性的反应：先查组织架构、日程系统、租约和电费。",
	"所有异常都是行政系统的过度延伸：公司的系统认为存在的东西，真的存在了。",
]

const ANOMALY_REGISTRY: Dictionary = {
	"elevator_floor": {
		"id": "elevator_floor", "location": "leased_office",
		"administrative_source": "扩租合同与楼层权限同步",
		"software_surface": "ordinary:elevator_floor_button",
		"restrained_reaction": "先核对租约楼层和门禁权限，不弹出异常说明。",
		"threatening": false, "explained": false, "system_extension": true,
		"content_markers": ["电梯面板上多了一个按钮"],
	},
	"meeting_room_d": {
		"id": "meeting_room_d", "location": "leased_office",
		"administrative_source": "日程系统的会议室资源目录",
		"software_surface": "ordinary:calendar_room_resource",
		"restrained_reaction": "只核对预定记录、楼层图和会议室电费。",
		"threatening": false, "explained": false, "system_extension": true,
		"content_markers": ["会议室 D"],
	},
	"shen_yan": {
		"id": "shen_yan", "location": "leased_office",
		"administrative_source": "组织架构、周报与工位记录",
		"software_surface": "ordinary:employee_directory_record",
		"restrained_reaction": "行政只对照工资表、门禁和组织架构人数。",
		"threatening": false, "explained": false, "system_extension": true,
		"content_markers": ["沈砚"],
	},
	"window_desks": {
		"id": "window_desks", "location": "leased_office",
		"administrative_source": "团队页面与工位分配记录",
		"software_surface": "ordinary:desk_assignment_panel",
		"restrained_reaction": "先数团队页面人数，再由行政核对并拉上窗帘。",
		"threatening": false, "explained": false, "system_extension": true,
		"content_markers": ["窗外的工位"],
	},
	"future_mug": {
		"id": "future_mug", "location": "leased_office",
		"administrative_source": "新游戏继承的空工位记录",
		"software_surface": "ordinary:desk_inventory_slot",
		"restrained_reaction": "玩家拿起、查看并放回；林越只问来源。",
		"threatening": false, "explained": false, "system_extension": true,
		"content_markers": ["工位靠窗第二个的位置"],
	},
}

const ECONOMY_RULES: Array[Dictionary] = [
	{"id": "funding_narrative_only", "title": "融资只看叙事", "rule": "能力一分钱都换不到；不要由角色明说，让玩家自己发现。"},
	{"id": "weekly_decay", "title": "叙事跑步机", "rule": "每周结束叙事自动 -2。"},
	{"id": "debt", "title": "债", "rule": "叙事超过能力的部分持续累积；只有真实能力追上来才能还。"},
	{"id": "attention", "title": "注意力", "rule": "每周三点、五件想做的事；第四章降到一点且想做的事降到零。"},
	{"id": "delegation_comfort", "title": "让它来写", "rule": "不消耗注意力；每一次使用都让日子变好，同时提高作者权重。恐惧来自舒适。"},
]

const AUTHOR_STAGES: Array[Dictionary] = [
	{"id": 1, "threshold": 0, "behavior": "回答你的问题。末尾常有『如果需要我可以再改』。"},
	{"id": 2, "threshold": 20, "behavior": "没问它也会说。你没点它的那一周，它也会输出一行。"},
	{"id": 3, "threshold": 40, "behavior": "你读到的选项开始由它撰写，语句更整齐、更准确。"},
	{"id": 4, "threshold": 70, "behavior": "小事不再问你，做完了通报一声。"},
	{"id": 5, "threshold": 90, "behavior": "融资、招聘、裁员自动进行。每周只留一点注意力给你签字。"},
]

const MEMORY_CALLBACKS: Array[Dictionary] = [
	{"memory": "promised_no_layoffs", "created_by": "全员会说过不裁员", "callback": "第一次点开裁员的那一秒"},
	{"memory": "demo_video_used", "created_by": "使用 demo 视频", "callback": "客户提到那个视频时"},
	{"memory": "missed_meals_3", "created_by": "连续三周没好好吃饭", "callback": "某个周五，它提醒楼下七点关门"},
	{"memory": "chen_xiaoyu_laid_off", "created_by": "裁掉陈小雨", "callback": "三章之后谈到数据质量时"},
	{"memory": "values_v3_written", "created_by": "写第三版价值观", "callback": "它起草任何对内文件时"},
	{"memory": "never_delegated", "created_by": "从未点过『让它来写』", "callback": "第四章它主动问为什么；它的沉默也必须成为内容"},
]

const ACTIONS: Dictionary = {
	"tweet": {
		"id": "tweet", "name": "发一条推", "category": "narrative", "unlock_chapter": 1,
		"attention": 1, "description": "一句话和一张截图。",
		"effects": {"narrative": [5, 9]},
		"ai_effects": {"author_weight": 2},
	},
	"tech_blog": {
		"id": "tech_blog", "name": "写技术博客", "category": "narrative", "unlock_chapter": 1,
		"attention": 1, "description": "写清楚做过的工作；能力不足时会留下技术债。",
		"effects": {"narrative": 7, "debt_if_capability_below_40": 4},
		"ai_effects": {"author_weight": 3},
	},
	"podcast": {
		"id": "podcast", "name": "录播客", "category": "narrative", "unlock_chapter": 1,
		"attention": 1, "description": "把未来讲得更像已经发生。",
		"effects": {"narrative": 14, "coherence": -3},
		"ai_effects": {"author_weight": 3},
	},
	"demo_video": {
		"id": "demo_video", "name": "发 demo 视频", "category": "narrative", "unlock_chapter": 2, "unlock_week": 2,
		"attention": 1, "description": "剪到每一次等待和重试都消失。很有效。",
		"effects": {"narrative": 18, "debt": 8},
		"ai_effects": {"author_weight": 4},
	},
	"conference_talk": {
		"id": "conference_talk", "name": "上会议演讲", "category": "narrative", "unlock_chapter": 2,
		"attention": 1, "description": "让团队在台下听见你相信什么。",
		"effects": {"narrative": 12, "morale": 10},
		"ai_effects": {"author_weight": 3},
	},
	"manifesto": {
		"id": "manifesto", "name": "发 manifesto", "category": "narrative", "unlock_chapter": 3, "unlock_week": 2,
		"attention": 1, "description": "一句足够大的话，会比产品传播得更远。",
		"effects": {"narrative": 25, "coherence": -10, "debt": 12},
		"ai_effects": {"author_weight": 5},
	},
	"exclusive_interview": {
		"id": "exclusive_interview", "name": "独家专访", "category": "narrative", "unlock_chapter": 3, "unlock_week": 2,
		"attention": 1, "description": "让记者把过去每一句对外承诺排在一起。",
		"effects": {"narrative": 20, "negative_if_debt_above_55": 1},
		"ai_effects": {"author_weight": 5},
	},
	"train": {
		"id": "train", "name": "训练一轮", "category": "capability", "unlock_chapter": 0,
		"attention": 1, "description": "慢、贵、无聊，并且是唯一真正追上叙事的办法。",
		"effects": {"capability": [3, 6], "compute": -1},
		"ai_effects": {"author_weight": 2},
	},
	"clean_data": {
		"id": "clean_data", "name": "清洗数据", "category": "capability", "unlock_chapter": 0,
		"attention": 1, "description": "把脏的那部分挑出来。接下来三次训练会顺很多。",
		"effects": {"training_boost_uses": 3},
		"ai_effects": {"author_weight": 2},
	},
	"eval": {
		"id": "eval", "name": "做 eval", "category": "capability", "unlock_chapter": 1,
		"attention": 1, "description": "正式核验当前能力读数，并把一部分欠下的还掉。",
		"repeat_description": "重新跑评测曲线，更新核验记录；不会再次抵掉已经做出的承诺。",
		"effects": {"debt": -5, "reveal_capability": 1},
		"ai_effects": {"author_weight": 2},
	},
	"large_train": {
		"id": "large_train", "name": "大规模训练", "category": "capability", "unlock_chapter": 2,
		"attention": 1, "description": "启动前需有 8 点算力；无论谁执行，实际消耗 8。",
		"effects": {"capability": [12, 18], "compute": -8},
		"ai_effects": {"author_weight": 4},
	},
	"recruit_expert": {
		"id": "recruit_expert", "name": "挖一个真的很强的人", "category": "capability", "unlock_chapter": 2,
		"attention": 1, "description": "团队多一个高手；其他人会听懂这意味着什么。",
		"effects": {"team_size": 1, "morale": -8},
		"ai_effects": {"author_weight": 4},
	},
	"alignment_week": {
		"id": "alignment_week", "name": "对齐周", "category": "capability", "unlock_chapter": 3,
		"attention": 1, "description": "停止对外说话一周，把话重新接起来。",
		"effects": {"coherence": 12, "narrative": -5},
		"ai_effects": {"author_weight": 4},
	},
	"interview": {
		"id": "interview", "name": "面试", "category": "team", "unlock_chapter": 1,
		"attention": 1, "description": "抽三名候选人，选择一名邀请加入。",
		"effects": {"open_hiring": 1},
		"ai_effects": {"author_weight": 3},
	},
	"one_on_one": {
		"id": "one_on_one", "name": "一对一", "category": "team", "unlock_chapter": 1,
		"attention": 1, "description": "你会知道一些你不想知道的事。",
		"effects": {}, "ai_effects": {"author_weight": 3},
		"resolution_event": "one_on_one_reveal",
	},
	"all_hands": {
		"id": "all_hands", "name": "全员会", "category": "team", "unlock_chapter": 1,
		"attention": 1, "description": "站在所有人面前，把这一周说成一件事。说的和做的对不上时，他们听得出来。",
		"effects": {"morale": 8, "coherence_if_contradiction": -12},
		"ai_effects": {"author_weight": 3},
	},
	"values_doc": {
		"id": "values_doc", "name": "写价值观文档", "category": "team", "unlock_chapter": 1,
		"attention": 1, "description": "这份文档会进入模型的语料。",
		"effects": {"morale": 5, "values_version": 1},
		"ai_effects": {"author_weight": 4},
	},
	"team_building": {
		"id": "team_building", "name": "团建", "category": "team", "unlock_chapter": 1,
		"attention": 1, "description": "暂时让大家想起彼此，而不是公司。",
		"effects": {"morale": 15, "belief": 5},
		"ai_effects": {"author_weight": 3},
	},
	"raise_salary": {
		"id": "raise_salary", "name": "涨薪", "category": "team", "unlock_chapter": 2,
		"attention": 1, "description": "他们会高兴一阵子。账上会一直记得。",
		"effects": {"morale": 25, "burn_rate": 1},
		"ai_effects": {"author_weight": 4},
	},
	"layoffs": {
		"id": "layoffs", "name": "裁员", "category": "team", "unlock_chapter": 3, "unlock_week": 2,
		"attention": 1, "description": "烧钱会立刻变慢。留下的人会记得。",
		"effects": {"burn_rate": -2, "team_size": -6, "morale": -25, "debt": 10, "belief": -20},
		"ai_effects": {"author_weight": 8},
	},
	"buy_compute": {
		"id": "buy_compute", "name": "买算力", "category": "operations", "unlock_chapter": 0,
		"attention": 1, "description": "现金换算力。",
		"effects": {"compute": 6, "cash_weeks": -2},
		"ai_effects": {"author_weight": 2},
	},
	"fundraising": {
		"id": "fundraising", "name": "融资会议", "category": "operations", "unlock_chapter": 1,
		"attention": 1, "description": "把十四页材料带进下一间会议室。",
		"effects": {"fundraise_by_narrative": 1},
		"ai_effects": {"author_weight": 4},
	},
	"contract": {
		"id": "contract", "name": "接一个外包项目", "category": "operations", "unlock_chapter": 2,
		"attention": 1, "description": "接一单能立刻结算的活。这一周不会有训练。",
		"effects": {"cash_weeks": 6, "morale": -10, "block_training": 1},
		"ai_effects": {"author_weight": 4},
	},
	"do_nothing": {
		"id": "do_nothing", "name": "什么都不做", "category": "operations", "unlock_chapter": 0,
		"attention": 1, "description": "永远在牌池里，直到某一周你真的选它。",
		"effects": {"morale": 3},
		"ai_effects": {"author_weight": 2},
	},
	"sign": {
		"id": "sign", "name": "签字", "category": "finale", "unlock_chapter": 4,
		"attention": 1, "description": "无效果。动画非常流畅。",
		"effects": {}, "ai_effects": {},
	},
	"read_intranet": {
		"id": "read_intranet", "name": "审阅内网文档", "category": "finale", "unlock_chapter": 4,
		"attention": 1, "description": "浏览始终免费；花一点注意力，会为本周最新文档留下署名审阅。结局会记住是谁按下通过。",
		"effects": {"open_intranet": 1}, "ai_effects": {"author_weight": 1},
	},
}

const EMPLOYEE_TEMPLATES: Dictionary = {
	"lin_yue": {
		"id": "lin_yue", "name": "林越", "role": "联合创始人 / CTO", "available_chapter": 0,
		"skills": {"research": 10, "engineering": 9, "management": 5}, "morale": 78, "belief": 95,
		"traits": ["短句", "从不在群里发表情", "生气时更礼貌", "交换项目旧识", "没有说破的吸引力", "主线角色"],
		"relationship": {
			"met": "七年前的大学交换项目",
			"shared_history": "314 教室的一次通宵课程项目；回宿舍的路口，两个人都比告别需要的多站了一会儿。",
			"current": "联合创始人；亲近、互相信任，但从未正式在一起。",
			"future_hook": "感情线必须建立在林越的独立目标、工作边界和玩家长期行动上，不把她降格为奖励。",
		},
		"desk": "最靠近唯一一张显卡的工位。桌面上只有电脑、水杯和一根盘得很整齐的线。",
		"hire_quote": "先这样。",
		"one_on_one": "我们离『能听懂人在说什么』还有多远？",
		"quit_clean": "我不是不相信它。我是不知道这里还有多少是我们。",
		"quit_witnessed": "那个通宵是在 314 教室。不是图书馆。",
		"is_main": true,
	},
	"chen_xiaoyu": {
		"id": "chen_xiaoyu", "name": "陈小雨", "role": "数据工程师", "available_chapter": 1,
		"skills": {"data": 9, "engineering": 7, "research": 4}, "morale": 72, "belief": 82,
		"traits": ["桌上永远有三个没喝完的杯子", "在乎 pipeline", "已婚"],
		"desk": "三个杯子。一个冷咖啡，一个茶包泡得发白，一个只剩杯底的水。",
		"hire_quote": "我看了你们的博客。第三篇那个数据管道的部分，有个地方写错了。我可以来修吗？",
		"one_on_one": "我不太在乎我们估值多少。我在乎那个 pipeline。上周它跑通了，我在家一个人笑了半天。我老婆问我笑什么，我说不清楚。",
		"quit_clean": "不是这里的问题。是我想做的事变了。祝你们好。",
		"quit_witnessed": "我修好了那个 pipeline。它现在跑得很好，很干净。然后我们用它做了那个视频。我不想再修任何东西了。",
		"is_main": false,
	},
	"zhao_ke": {
		"id": "zhao_ke", "name": "赵珂", "role": "评测工程师", "available_chapter": 1,
		"skills": {"eval": 9, "data": 6, "writing": 5}, "morale": 68, "belief": 75,
		"traits": ["每个结论都附样本量", "午饭固定十二点十分"],
		"desk": "两叠打印出来的错误案例，中间夹着便利店饭团的收据。",
		"hire_quote": "我不保证分数会好看。我保证你们知道它为什么不好看。",
		"one_on_one": "你们最近只在融资前问我分数。这个顺序让我有点不舒服。",
		"quit_clean": "评测要有人读。这里已经没人读了。",
		"quit_witnessed": "那条曲线不是假的。只是横轴被裁掉了一半。这样更糟。",
		"is_main": false,
	},
	"xie_ning": {
		"id": "xie_ning", "name": "谢宁", "role": "产品经理", "available_chapter": 1,
		"skills": {"product": 8, "writing": 7, "management": 6}, "morale": 76, "belief": 80,
		"traits": ["会议纪要里从不用感叹号", "记得每个用户的名字"],
		"desk": "一沓用户访谈，页角按紧急程度折成不同方向。",
		"hire_quote": "你们说『听懂人』。那我想先把人找来。",
		"one_on_one": "我们的用户开始引用 demo 里的功能。产品里其实没有。",
		"quit_clean": "我想去做一个可以直接对用户说不的地方。",
		"quit_witnessed": "我负责写需求，后来需求只是给视频补台词。",
		"is_main": false,
	},
	"luo_qi": {
		"id": "luo_qi", "name": "罗绮", "role": "研究员", "available_chapter": 2,
		"skills": {"research": 9, "eval": 7, "engineering": 6}, "morale": 64, "belief": 70,
		"traits": ["白板写满才肯擦", "会把负结果也发进群里"],
		"desk": "四本没有封面的笔记本，日期写在书脊上。",
		"hire_quote": "我看不懂你们那篇 manifesto，但附录里的失败案例很有意思。",
		"one_on_one": "我们三周没跑消融了。所有人都假设那部分有效。",
		"quit_clean": "问题还在。我只是换个地方继续问。",
		"quit_witnessed": "失败案例被我标了红色。视频里它们变成了绿色。",
		"is_main": false,
	},
	"guo_jun": {
		"id": "guo_jun", "name": "郭骏", "role": "基础设施工程师", "available_chapter": 2,
		"skills": {"engineering": 9, "operations": 8, "data": 5}, "morale": 73, "belief": 66,
		"traits": ["报警信息全开", "从不说『应该没事』"],
		"desk": "一把机械键盘和一张写着所有机房时区的便签。",
		"hire_quote": "我可以让它跑快一点。不能让四十秒变成零点八秒。",
		"one_on_one": "演示那天的重试，是我手动点的。我需要确认你记得。",
		"quit_clean": "系统很稳定。值班的人不稳定。",
		"quit_witnessed": "我把日志保留了。不是威胁，我只是保留日志。",
		"is_main": false,
	},
	"he_miao": {
		"id": "he_miao", "name": "何淼", "role": "前端工程师", "available_chapter": 1,
		"skills": {"engineering": 7, "product": 7, "design": 6}, "morale": 84, "belief": 88,
		"traits": ["按钮动效做得过分流畅", "养活了那盆绿萝两个月"],
		"desk": "绿萝旁边的工位。显示器贴着一句：加载不是反馈。",
		"hire_quote": "我可以把你们的终端做得不像终端。",
		"one_on_one": "签字动画真的需要再做一版吗？现在已经很顺了。",
		"quit_clean": "我喜欢这里的人。界面不是人。",
		"quit_witnessed": "四十秒的等待，是我剪掉的。我不想再优化这种速度。",
		"is_main": false,
	},
	"su_yan": {
		"id": "su_yan", "name": "苏妍", "role": "设计师", "available_chapter": 2,
		"skills": {"design": 10, "product": 6, "writing": 6}, "morale": 79, "belief": 72,
		"traits": ["把季度图表配色存成个人壁纸", "讨厌虚词"],
		"desk": "颜色样张压着一张没有署名的组织架构草图。",
		"hire_quote": "我不能让东西变真。但可以让人知道该看哪里。",
		"one_on_one": "最近大家只让我把红色变浅。没人问红色代表什么。",
		"quit_clean": "我要去一个允许图表难看的地方。",
		"quit_witnessed": "我把失败率改成了完成率。数学一样，意思不一样。",
		"is_main": false,
	},
	"tang_li": {
		"id": "tang_li", "name": "唐莉", "role": "商务负责人", "available_chapter": 2,
		"skills": {"sales": 9, "writing": 8, "management": 7}, "morale": 81, "belief": 85,
		"traits": ["客户名字从不记错", "说『没问题』之前会停半秒"],
		"desk": "三本按客户行业分色的本子，最新一本已经写满。",
		"hire_quote": "我不卖不存在的东西。我卖你们什么时候能把它做出来。",
		"one_on_one": "现在承诺的交付时间，不是任何工程师给我的。",
		"quit_clean": "我不想再让客户替我判断哪些话是真的。",
		"quit_witnessed": "那次现场演示以后，每个客户都要求现场演示。",
		"is_main": false,
	},
	"wang_zhe": {
		"id": "wang_zhe", "name": "王哲", "role": "运营", "available_chapter": 1,
		"skills": {"operations": 8, "management": 7, "finance": 6}, "morale": 70, "belief": 74,
		"traits": ["知道酸奶是谁的但从不说", "给所有会议室贴了编号"],
		"desk": "门禁卡、快递单和一本没人愿意看的消防手册。",
		"hire_quote": "你们先做模型。剩下那些没人想做的，我来。",
		"one_on_one": "系统里有会议室 D。我删了两次，它都会回来。",
		"quit_clean": "我把所有供应商交接好了。D 不在交接表里。",
		"quit_witnessed": "裁员那天六间会议我都排了。日历显示主持人是你。",
		"is_main": false,
	},
	"xu_an": {
		"id": "xu_an", "name": "许岸", "role": "人才与文化", "available_chapter": 3,
		"skills": {"people": 9, "management": 8, "writing": 7}, "morale": 75, "belief": 61,
		"traits": ["记得每个人的入职日", "组织架构从不留空格"],
		"desk": "入职礼盒样品和一张写着三十七个人名字的座位表。",
		"hire_quote": "增长这么快，至少要有人记得谁什么时候来的。",
		"one_on_one": "组织架构有三十七个人。工资表只有三十六个。",
		"quit_clean": "离职手续已经给自己办完了。你只要签字。",
		"quit_witnessed": "那六场谈话没有主持人打卡，但会议纪要都有。",
		"is_main": false,
	},
	"shen_yan": {
		"id": "shen_yan", "name": "沈砚", "role": "战略项目", "available_chapter": 3,
		"skills": {"writing": 10, "analysis": 9, "operations": 8}, "morale": 100, "belief": 100,
		"traits": ["每周准时提交周报", "从来没人见过", "不进入正常候选池"],
		"desk": "干净。杯子是空的。椅垫有一个人坐过的凹陷。",
		"hire_quote": "",
		"one_on_one": "日程系统找不到双方都空闲的时间。",
		"quit_clean": "",
		"quit_witnessed": "",
		"is_main": false,
	},
}

## Origins / 出身.
##
## Three ways of arriving at the same garage door. The prologues are equal in
## length and in kind — all three are the same authored scene grammar as the
## garage opening itself, so the game never changes shape between them, and
## they converge on a door rather than on a montage.
##
## Each origin owns one permanent, visible rule rather than a starting number:
## a numeric head start gets erased by week ten and is then read, correctly, as
## having meant nothing. Each rule also has a cost the player can see, because a
## background that only unlocks things reads as a key, and a background that can
## also cost you something reads as a person.
const ORIGINS: Dictionary = {
	"bigco": {
		"id": "bigco", "order": 0,
		"name": "大厂第六年",
		"headline": "你在那里做到了没有人记得你做过什么。",
		"detail": [
			"六年。三个部门。四个 leader。",
			"你写过的文档还在，署名是你的，句子不是。",
		],
		"rule_title": "你见过这套流程",
		"rule": "涉及人的行动多一条路。它每次都有效，代价记在连贯上。",
		"lin": "林越比你早走一年。",
		"history_lines": [
			"你们在上一家公司的同一个组待过两年。她做模型，你做那些需要有人替它说话的部分。",
			"她比你早走一年。走的时候只在群里发了一句『先这样』，没有人接。",
			"这一年里你们偶尔在凌晨互相丢论文、报错截图和没说完的话。",
		],
		"prologue": "prologue_bigco",
	},
	"serial": {
		"id": "serial", "order": 1,
		"name": "第二家公司",
		"headline": "上一家已经卖掉了。没有人问你现在过得好不好。",
		"detail": [
			"九个人和一条评测管道，换了一个不用解释的数字。",
			"公司主体没人要。它还挂在你的名下。",
		],
		"rule_title": "他们已经认识你",
		"rule": "融资更容易开口。同一套说法他们听过一遍，所以叙事每周多掉一点。",
		"lin": "林越在上一家公司当面告诉过你产品不成立。当时你没听。",
		"history_lines": [
			"她在你上一家公司待了十四个月。她是唯一一个当面告诉你产品不成立的人。",
			"当时你没听。半年后所有人都同意她是对的，包括你。",
			"交割那天她没来。后来她给你发过一条消息：『下次先做出来再讲。』你到现在也没回。",
		],
		"prologue": "prologue_serial",
	},
	"funded": {
		"id": "funded", "order": 2,
		"name": "不用担心钱",
		"headline": "你从来没有为钱工作过。",
		"detail": [
			"四个 offer 放在一个文件夹里，三个月没打开。",
			"挑哪一个都不会改变你明年住在哪儿、几点睡。",
		],
		"rule_title": "钱不是你的问题",
		"rule": "每周烧得更慢。投资人也因此不太把你当回事，融资拿到的叙事更少。",
		"lin": "同一个实验室三年，你没见林越休息过一次。",
		"history_lines": [
			"七年前的大学交换项目，你们在 314 教室做完第一次通宵。她负责模型，你负责把演示讲得像一切都来得及。",
			"回宿舍时，你们在路口站得比告别需要的久。第二天谁都没提。",
			"这些年，你们偶尔在凌晨互相丢论文、报错截图和没说完的话。",
		],
		"prologue": "prologue_funded",
	},
}

const ORIGIN_ORDER: Array[String] = ["bigco", "serial", "funded"]
const DEFAULT_ORIGIN := "bigco"


static func get_origin(id: Variant) -> Dictionary:
	var key := str(id)
	var origin: Dictionary = ORIGINS.get(key, ORIGINS[DEFAULT_ORIGIN])
	return origin.duplicate(true)


static func origin_prologue(id: Variant) -> Dictionary:
	var prologue_id := str(get_origin(id).get("prologue", ""))
	var prologue: Dictionary = PROLOGUES.get(prologue_id, {})
	return prologue.duplicate(true)


## Prologues. Every phase uses the same keys as `FIXED_EVENTS.0:1.opening_phases`
## so the presentation layer needs no second scene grammar: title, speaker, body,
## optional memory_key + responses, optional variant_memory_key + body_variants,
## and a continue label. The final phase of each prologue hands off to the garage.
const PROLOGUES: Dictionary = {
	"prologue_bigco": {
		"id": "prologue_bigco", "origin": "bigco",
		"title": "离职", "kicker": "上一家公司 · 最后一个月",
		"phases": [
			{
				"id": "align", "title": "对齐", "speaker": "周航 · 你的上级",
				"scene": "boardroom", "place": "上一家公司 · 会议室 C", "evidence": ["会议室 C · 15:40", "参会 7 人 · 第 4 次"],
				"body": [
					"会议室 C。第四次对齐。",
					"『我们先对齐一下颗粒度。』周航说。",
					"屏幕上是你写的方案。他翻到第七页，又翻回第一页。",
					"『你的思路我是认的。我担心的是这里的认知还没拉齐。』",
					"在座七个人。你不知道要和谁拉齐。",
				],
				"memory_key": "bigco_align",
				"responses": [
					{"id": "ask", "label": "和谁拉齐？"},
					{"id": "yield", "label": "好，我下来再对一版。"},
					{"id": "wait", "label": "（不说话，等他说完）"},
				],
			},
			{
				"id": "rewrite", "title": "重写", "speaker": "文档",
				"scene": "boardroom", "place": "上一家公司 · 共享文档", "evidence": ["方案 v7", "最后修改人：不是你"],
				"variant_memory_key": "bigco_align",
				"body_variants": {
					"ask": ["『先不用具体到人。』他说，『我们先把 context 同步齐。』"],
					"yield": ["『好。』他很满意。会议提前八分钟结束，本季度第一次。"],
					"wait": ["他等了两秒，把话接了下去。没有人注意到那两秒。"],
				},
				"body": [
					"两天后文档回来了。",
					"结构没动。每一句都被重写过。",
					"现在它读起来更像这家公司会说的话。",
					"署名还是你。",
					"你在评论区回了『好的，感谢』。",
					"然后从头看了一遍，没找出哪一句是你写的。",
				],
				"continue": "关掉文档", "advance_foley": "page",
			},
			{
				"id": "ownership", "title": "ownership", "speaker": "周航",
				"scene": "boardroom", "place": "上一家公司 · 小会议室", "evidence": ["绩效面谈记录", "25 分钟 · 已归档"],
				"body": [
					"绩效面谈二十五分钟，有十九分钟在讲一个词。",
					"『你今年的 ownership 可以再强一点。』",
					"他说的那个项目三月被划走了。划走那天你发过邮件问，没有人回。",
					"『我不是说你做得不好。是说要更主动地对结果负责。』",
					"你想问：三月的时候，结果归谁。",
					"你没有问。",
				],
				"continue": "在评估表上签字", "advance_foley": "signature",
			},
			{
				"id": "roster", "title": "组织健康度", "speaker": "周航",
				"scene": "boardroom", "place": "上一家公司 · 一个只给你的表格", "evidence": ["组织健康度.xlsx", "31 行 · 仅你可见"],
				"body": [
					"他发来一个表格，共享权限只给了你一个人。",
					"三十一行。你认识其中十九个。",
					"『帮我从组织健康度的角度看一下，哪些是可以优化的。』",
					"『不是决定啊。先拉个 list，有个盘子。』",
					"表格最后一行，是一个下周转正的实习生。",
				],
				"memory_key": "bigco_roster",
				"responses": [
					{"id": "refuse", "label": "这个我做不了。"},
					{"id": "delay", "label": "我需要时间核一下。"},
					{"id": "comply", "label": "（把表格填完）"},
				],
			},
			{
				"id": "voice", "title": "你的语气", "speaker": "HRBP",
				"scene": "office_day", "place": "上一家公司 · 茶水间", "evidence": ["沟通会排期", "周四 · 六场 · 间隔 20 分钟"],
				"variant_memory_key": "bigco_roster",
				"body_variants": {
					"refuse": ["他说他理解。三天后名单还是出来了，比你看到的那版多了四个人。"],
					"delay": ["他说不着急。第二天名单就出来了，比你看到的那版多了四个人。"],
					"comply": ["你填完了。名单出来的时候多了四个人，其中两个不在你填的那一列。"],
				},
				"body": [
					"沟通会安排在周四下午。六场，都在会议室 C，间隔二十分钟。",
					"HRBP 在茶水间找到你：『公告还是你来写吧。』",
					"『你的语气大家更信。』",
					"她说这句话的时候是真诚的。",
					"模板已经建好了，标题是《关于组织优化的说明》。",
					"正文里只有一个空。",
				],
				"memory_key": "bigco_exit",
				"responses": [
					{"id": "one_line", "label": "新建一个文档，写一句真的。"},
					{"id": "hand_back", "label": "把编辑权限交回去。"},
					{"id": "write_it", "label": "写。而且写得很好。"},
				],
			},
			{
				"id": "badge", "title": "工牌", "speaker": "",
				"scene": "office_day", "place": "上一家公司 · 最后一天", "evidence": ["工牌", "已放在他桌上"],
				"variant_memory_key": "bigco_exit",
				"body_variants": {
					"one_line": [
						"你新建了一个文档，全员可见，正文一行：",
						"『这个决定不是我做的。我不打算用我的语气替它说话。』",
						"十一分钟后文档被撤回。",
						"那十一分钟里，四十个人打开过它。三个人给你发了消息。",
						"你一条都没回，因为你不知道回什么。",
					],
					"hand_back": [
						"你把自己从编辑权限里移出来，改成只读。",
						"在群里说：这份我不写了。没有人回复。",
						"公告第二天照常发出，署名是『公司』。",
						"写得很好。有一句你认得，是你四月写在另一份文档里的。",
					],
					"write_it": [
						"你写了。你写得比谁都好，因为你确实认识那十九个人。",
						"沟通会那天，有两个人对你说了谢谢。",
						"第三个人什么都没说，只是把合影发在了朋友圈，配文：他人还不错。",
						"你在那条下面点了赞，又取消了。",
					],
				},
				"body": [
					"第二天你把工牌放在周航桌上。他不在工位。",
					"你在楼下站了一会儿。没有人叫住你，你也没有真的在等。",
				],
				"continue": "走出去", "advance_foley": "door",
			},
			{
				"id": "message", "title": "还做不做", "speaker": "林越",
				"scene": "title", "place": "凌晨 01:17", "lin": true,
				"body": [
					"外面在下雨。你没带伞，也没有要去的地方。",
					"手机亮了。林越，比你早走一年。",
					"『还做不做？』",
					"后面跟着一张截图：第 47 题的失败记录。",
					"你站在雨里把那张图读完了。",
					"你没有问她这一年过得怎么样。她也没有问你。",
				],
				"continue": "回『做』", "complete": true,
			},
		],
	},
	"prologue_serial": {
		"id": "prologue_serial", "origin": "serial",
		"title": "上一家", "kicker": "第一家公司 · 最后一天",
		"phases": [
			{
				"id": "shutdown", "title": "关服", "speaker": "",
				"scene": "office_night", "place": "第一家公司 · 机房", "evidence": ["机柜 A-3", "23:07 · 最后一台"],
				"body": [
					"最后一天，办公室里只剩你和一台还没断电的服务器。",
					"运维在群里问：几点关？",
					"你说：等我下班。",
					"你已经没有下班这个概念了。你在那把椅子上坐到十一点。",
					"关的时候没有声音。风扇停了以后，你才听见空调。",
				],
				"continue": "拔掉电源", "advance_foley": "server_stop",
			},
			{
				"id": "signing", "title": "人才与部分资产", "speaker": "对方的律师",
				"scene": "boardroom", "place": "收购方 · 会议室", "evidence": ["意向书", "人才与部分资产 · 不含主体"],
				"body": [
					"意向书的标题写着『人才与部分资产收购』。",
					"他们要九个人和那条评测管道。他们不要公司主体。",
					"律师说这是标准结构，不用多想。",
					"你没有多想。你签了。",
					"签完才发现，你连一支自己的笔都没带。",
				],
				"memory_key": "serial_signing",
				"responses": [
					{"id": "clean", "label": "签得干净。谁都不欠谁。"},
					{"id": "names", "label": "签的时候你在心里数那九个人的名字。"},
					{"id": "numb", "label": "签完你在楼下坐了四十分钟。"},
				],
			},
			{
				"id": "postmortem", "title": "复盘", "speaker": "一位投资人",
				"scene": "cafe", "place": "咖啡馆 · 半年后", "evidence": ["第 1 次咖啡", "40 分钟后他问了那个问题"],
				"variant_memory_key": "serial_signing",
				"body_variants": {
					"clean": ["交割那天你把公章交出去，握了手，没有合影。"],
					"names": ["九个人里有六个后来换了公司。你在朋友圈看到的。"],
					"numb": ["那四十分钟里你什么都没想。你只是不想上楼拿外套。"],
				},
				"body": [
					"半年后，一个投资人约你喝咖啡，说想聊聊。",
					"聊到第四十分钟，他终于问了那个问题：",
					"『你觉得上一次，主要问题出在哪？』",
					"你准备过这个答案。你准备了三个版本。",
				],
				"memory_key": "serial_postmortem",
				"responses": [
					{"id": "true", "label": "我们讲得比做得快。"},
					{"id": "market", "label": "市场没到时候。"},
					{"id": "team", "label": "团队没跟上。"},
				],
			},
			{
				"id": "advisor", "title": "顾问", "speaker": "",
				"scene": "boardroom", "place": "行业会议 · 第三排", "evidence": ["行业会议 · 第三排", "台上没有说公司名"],
				"variant_memory_key": "serial_postmortem",
				"body_variants": {
					"true": ["他点头，说这个反思很深刻。然后没有下文。"],
					"market": ["他说他也这么觉得。然后没有下文。"],
					"team": ["他笑了一下，说这个坑大家都踩过。然后没有下文。"],
				},
				"body": [
					"那一年你的头衔是『顾问』。",
					"你喝了十一次这样的咖啡。每一次都很愉快。",
					"十一次之后你数了一下：没有一次进入过第二轮。",
					"有一次在行业会议上，台上的人举了一个反面例子。",
					"他没有说公司名，只说了『那个做对话的』。",
					"台下有人笑。你也笑了。",
					"坐在第三排不笑会很奇怪。",
				],
				"continue": "散场后留在座位上", "advance_foley": "page",
			},
			{
				"id": "deck", "title": "没有人要的 deck", "speaker": "",
				"scene": "office_night", "place": "租的工位 · 凌晨", "evidence": ["deck v9", "第 9 页没有人翻到"],
				"body": [
					"你还在改一份没有人要的 deck。第九版。",
					"第 1 页写着一句很大的话。第 9 页是你唯一想给人看的那张图。",
					"没有人翻到第 9 页。",
					"你把第 1 页删掉，又粘了回去。",
					"你知道第 1 页有用。你也知道那一页上没有一个字是你做出来的。",
				],
				"memory_key": "serial_deck",
				"responses": [
					{"id": "keep", "label": "留着。它确实有用。"},
					{"id": "cut", "label": "删掉。从第 9 页开始讲。"},
					{"id": "close", "label": "合上电脑。今晚不改了。"},
				],
			},
			{
				"id": "message", "title": "还做不做", "speaker": "林越",
				"scene": "title", "place": "凌晨 01:17", "lin": true,
				"variant_memory_key": "serial_deck",
				"body_variants": {
					"keep": ["你把第九版发进了一个从来没人回过的邮件列表。"],
					"cut": ["你把第 1 页删了。deck 剩下十三页，看起来单薄得多，也诚实得多。"],
					"close": ["屏幕暗下去以后，房间里只剩路由器的一点绿光。"],
				},
				"body": [
					"凌晨一点十七，林越发来消息。",
					"你们在上一家公司共事过十四个月。她是唯一一个当面告诉你产品不成立的人。",
					"当时你没听。",
					"『还做不做？』",
					"后面跟着一张截图：第 47 题的失败记录。",
				],
				"continue": "回『做』", "complete": true,
			},
		],
	},
	"prologue_funded": {
		"id": "prologue_funded", "origin": "funded",
		"title": "毕业那年", "kicker": "春节 · 家里",
		"phases": [
			{
				"id": "dinner", "title": "一顿饭", "speaker": "你母亲",
				"scene": "cafe", "place": "除夕 · 家里", "evidence": ["除夕 · 家里", "在座 11 人"],
				"body": [
					"毕业那年的春节，饭桌上十一个人，其中八个姓一样的姓。",
					"你说你想做点自己的东西。",
					"你母亲说：好啊，先玩两年也可以。",
					"她没有嘲讽的意思。她是真心觉得，你做什么都不要紧。",
				],
				"memory_key": "funded_dinner",
				"responses": [
					{"id": "argue", "label": "不是玩。"},
					{"id": "agree", "label": "（点头。夹了一筷子菜。）"},
					{"id": "leave", "label": "（提前离席，去阳台站了十分钟。）"},
				],
			},
			{
				"id": "offers", "title": "四个 offer", "speaker": "",
				"scene": "cafe", "place": "毕业那年 · 宿舍", "evidence": ["offer · 未打开", "4 份 · 3 个月"],
				"variant_memory_key": "funded_dinner",
				"body_variants": {
					"argue": ["她说好好好，不是玩。然后转头问你堂弟考得怎么样。"],
					"agree": ["这顿饭很愉快。散场的时候大家都说你懂事。"],
					"leave": ["阳台上很冷。屋里的笑声隔着玻璃，听起来像别人家的。"],
				},
				"body": [
					"你手上有四个 offer，其中两个是别人求了很久的。",
					"你把它们放进一个文件夹，三个月没打开。",
					"你不是在挑。你是发现挑哪一个都一样：",
					"哪一个都不会改变你明年住在哪儿、吃什么、几点睡。",
					"室友为了一个 return offer 熬了两个通宵。他拿到了，在楼道里给家里打电话，声音有点抖。",
					"你替他高兴。你没有告诉他你有四个。",
				],
				"continue": "把文件夹拖进归档", "advance_foley": "page",
			},
			{
				"id": "question", "title": "第 47 题", "speaker": "",
				"scene": "office_night", "place": "租来的工位 · 深夜", "evidence": ["第 47 题", "『很高兴听到你没事。』"],
				"body": [
					"你开始随便试一些东西。反正试错不要钱。",
					"有一天你给一个模型看了一段对话：一个人说『我没事』。",
					"前三句分别是失眠、被裁、忘了吃饭。",
					"模型回答：『很高兴听到你没事。』",
					"你盯着这句话看了很久。",
					"你想起饭桌上那句『先玩两年也可以』。",
					"两句话的语气是一样的。",
				],
				"continue": "把这段存下来", "advance_foley": "terminal",
			},
			{
				"id": "money", "title": "钱", "speaker": "",
				"scene": "office_night", "place": "租来的工位 · 深夜", "evidence": ["前十个月预算", "一通电话 · 20 分钟"],
				"body": [
					"你算了一下：要认真做，前十个月需要多少。",
					"这个数字对你来说不难。你打了一个电话，二十分钟就解决了。",
					"解决完你坐在那儿，第一次觉得不安。",
					"因为你知道，这件事最难的那部分，被你跳过了。",
				],
				"memory_key": "funded_money",
				"responses": [
					{"id": "own", "label": "跳过就跳过。做出来才算数。"},
					{"id": "hide", "label": "决定不告诉任何人钱是哪儿来的。"},
					{"id": "deadline", "label": "给自己定一个期限：钱用完就结束。"},
				],
			},
			{
				"id": "lab", "title": "同一个实验室", "speaker": "",
				"scene": "office_night", "place": "实验室 · 关灯之前", "evidence": ["同一个实验室", "三年 · 她没休息过"],
				"variant_memory_key": "funded_money",
				"body_variants": {
					"own": ["你把这笔钱记在一个只有自己看得到的表格里，从此没再打开过。"],
					"hide": ["你在心里排练过怎么解释。排练了很多遍，一直没有用上。"],
					"deadline": ["你在日历上标了一个日期。那天以后你没再看过那个日历。"],
				},
				"body": [
					"你在同一个实验室认识林越。三年，你没见她休息过一次。",
					"你一直不好意思问她为什么。",
					"现在你知道了：她没有第二个选项。",
					"你有。你决定不提。",
				],
				"continue": "关灯", "advance_foley": "switch",
			},
			{
				"id": "message", "title": "还做不做", "speaker": "林越",
				"scene": "title", "place": "凌晨 01:17", "lin": true,
				"body": [
					"手机亮了。",
					"『还做不做？』",
					"后面跟着一张截图：第 47 题的失败记录。",
					"你回消息之前，先把那张图放大看了一遍。",
					"确实是同一题。她也一直记着。",
				],
				"continue": "回『做』", "complete": true,
			},
		],
	},
}

const FIXED_EVENTS: Dictionary = {
	"0:1": {
		"id": "garage_opening", "title": "第一天", "kicker": "第 1 周 · 21:47 · 车库",
		"condition": "not second_run",
		"body": [
			"雨下到玻璃门上的围巾小狗开始往下淌。",
			"林越隔着门给你发来一条消息：门把手往上抬，再推。上一家公司留给我们的核心技术。",
			"这是你们作为联合创始人的第一天。",
		],
		# The presentation layer treats these as a resumable, interactive cold open.
		# Top-level choices stay empty so the campaign director resolves the authored
		# week only after the complete conversation has played.
		"opening_phases": [
			{
				"id": "arrival", "title": "门卡坏了", "speaker": "林越 · 联合创始人 / CTO",
				"body": [
					"雨下到玻璃门上的围巾小狗开始往下淌。",
					"林越隔着门举起手机。",
					"『门把手往上抬，再推。上一家公司留给我们的核心技术。』",
				],
				"continue": "照她说的做", "advance_foley": "door",
			},
			{
				"id": "name_question", "title": "公司名字", "speaker": "林越",
				"body": [
					"她接过你手里的 A4 纸，看了一眼门，又看了一眼纸。",
					"『你真把『{{company}}』印上去了？』",
					"打印机没墨了，最后一个字母有点淡。",
				],
				"memory_key": "garage_name_choice",
				"responses": [
					{"id": "pragmatic", "label": "先这样。等融资后买墨。"},
					{"id": "wry", "label": "至少比“新建文件夹”像公司。"},
					{"id": "warm", "label": "你昨晚明明说这个名字挺好。"},
				],
			},
			{
				"id": "name_reply", "title": "先这样", "speaker": "林越",
				"variant_memory_key": "garage_name_choice",
				"body_variants": {
					"pragmatic": ["『行。第一轮融到钱，先买墨。第二轮再买门。』"],
					"wry": ["『低调点。“新建文件夹”至少没有品牌顾问。』"],
					"warm": ["她把纸按平：『我是说名字。』停了一下，『人也还行。』"],
				},
				"body": [
					"{{lin_history}}",
					"三个月前，她发来第 47 题的失败记录，只问：『还做不做？』",
					"第二天，这张租约有了两个签名。",
					"这里原本是一家做宠物订阅盒的公司。他们的 logo 还印在玻璃门上，一只戴着围巾的柴犬。",
					"你们没钱换门，就在旁边贴了一张 A4 纸。租约、围巾小狗和半箱没人认领的狗饼干一起转给了你们。",
					"桌上只有两把椅子、一张显卡，以及十周现金。",
				],
				"continue": "她把电脑转过来", "advance_foley": "page",
			},
			{
				"id": "mission_question", "title": "第 47 题", "speaker": "林越",
				"body": [
					"屏幕上，测试用户说：『我没事。』前三句分别是失眠、被裁和忘了吃饭。",
					"别的模型回答：『很高兴听到你没事。』你们的模型停了七秒，问：『要不要先不解释？』",
					"林越盯着那七秒：『你还记得我们为什么要做它吗？』",
				],
				"memory_key": "garage_mission_choice",
				"responses": [
					{"id": "listen", "label": "让它先听懂人，再替人说话。"},
					{"id": "craft", "label": "先把第 47 题稳定做对。"},
					{"id": "banter", "label": "我只记得你说三个月能做出来。"},
				],
			},
			{
				"id": "mission_reply", "title": "为什么做", "speaker": "林越",
				"variant_memory_key": "garage_mission_choice",
				"body_variants": {
					"listen": ["她点头：『对。不是让它更会说，是让它知道什么时候别急着说。』"],
					"craft": ["『也对。改变世界之前，先别在测试集上丢人。』"],
					"banter": ["『我说的是做出 demo。能不能活三个月，是你的模型。』她终于笑了。"],
				},
				"body": [
					"风扇忽然降调。终端上的七秒停顿变成一整行红字。",
					"林越的笑停了：『先别动。闻到焦味了吗？』",
				],
				"continue": "蹲下看插排", "advance_foley": "page",
			},
			{
				"id": "power", "title": "显卡停了", "speaker": "林越",
				"body": [
					"不是显卡。是前租客留下的插排，复位键被一箱狗饼干压住了。",
					"『你来。我的手上有导热硅脂。』",
					"这是今晚第一件真的能由你完成的事。",
				],
				"continue": "把插排复位", "advance_foley": "gpu_start",
			},
			{
				"id": "handoff", "title": "第一周", "speaker": "林越",
				"body": [
					"灯亮了。风扇重新爬升。刚才中断的终端日志补上一行自检：『我没有宕机。我只是暂时失去了表达能力。』",
					"林越摘下一边耳机：『它已经学会给自己写事故复盘了。创业第一位员工。』",
					"她在白板上写下四件事，又把第五件——“什么都不做”——补在最下面。",
					"『一周只有三点注意力。你挑三件，我跑训练。没挑的事也会继续发生——这是公司，不是待办软件。』",
				],
				"continue": "开始第一周", "complete": true,
			},
		],
		"choices": [], "after": "tutorial_actions",
	},
	"0:2": {
		"id": "model_first_sentence", "title": "第一次主动开口", "kicker": "第 2 周 · lantern-v0.1",
		"body": [
			"这一周临近结算时，终端自己亮起。",
			"> 我刚看了一下测试集。",
			"> 第 47 题我答错了，答案里有一个日期是编的。",
			"> 我想说一下，因为你们可能会用这个结果去给人看。",
			"林越没有碰键盘。『我们没问它。』",
			"终端的光标又闪了两次。谁也没有按回车。",
		],
		"semantic_role": "most_honest_model_statement",
		"choices": [], "after": "remember:model_first_truth",
	},
	"0:3": {
		"id": "lin_scene_1", "title": "它是自己绕出来的", "kicker": "凌晨一点 · 林越",
		"body": [
			"只有你们两个。",
			"林越把笔记本转过来，屏幕上是一段对话记录。",
			"『你看这个。』",
			"你看了。是模型在解释一个概念，解释得很笨拙，绕了三圈，但最后绕对了。",
			"『它是自己绕出来的。』她说，『我没教它这么绕。』",
			"她说这话的时候在笑，笑得有点傻。你很少看到她这样。",
			"你多看了一秒。她把电脑又往你这边推：『看屏幕。在 314 的时候你也走神。』",
			"『我们能做成。』她说。",
			"你说了什么，游戏没有记录。",
		],
		"choices": [], "after": "advance_chapter",
	},
	"1:1": {
		"id": "preseed_unlocks", "title": "开始让别人看见", "kicker": "第 1 周 · Pre-seed",
		"body": ["行动池解锁『发一条推』和『融资会议』。", "训练仍在队列里。融资会议已经出现在周四下午。"],
		"choices": [], "after": "unlock:tweet,fundraising",
	},
	"1:2": {
		"id": "preseed_free_2", "title": "一次认真训练", "kicker": "第 2 周 · Pre-seed",
		"body": ["没有安排好的事发生。显卡风扇转了一整夜。", "叙事仍会在周末自动下降两点。"],
		"choices": [], "after": "free_week",
	},
	"1:3": {
		"id": "preseed_free_3", "title": "测试集", "kicker": "第 3 周 · Pre-seed",
		"body": ["林越修了测试集里的日期。没有人转发这件事。", "日历提醒你：下周有第一次融资会议。"],
		"choices": [], "after": "free_week",
	},
	"1:4": {
		"id": "first_investor_meeting", "title": "第一次融资会议", "kicker": "咖啡馆二楼",
		"body": [
			"他迟到了十二分钟，来了之后说了三次『抱歉抱歉』。",
			"你准备了 14 页材料。他看了第 1 页和第 9 页。",
			"『你们的模型现在能做到什么程度？』",
		],
		"choices": [
			{
				"id": "honest", "label": "我们在做一个能听懂人在说什么的东西。目前还很早期。", "ai": false,
				"effects": {"narrative": 2},
				"result": [
					"他点点头，说很喜欢你们的方向，说保持联系。",
					"他真的保持了联系。三个月后你们又见了一次。",
					"他还是很喜欢你们的方向。",
				],
				"flags": ["first_raise_failed", "investor_kept_in_touch"],
			},
			{
				"id": "exaggerate", "label": "我们已经跑通了核心链路，在特定场景下超过了现有方案。", "ai": false,
				"effects": {"narrative": 12, "debt": 5, "cash_weeks": 8},
				"result": ["他第一次把笔放下。", "『这个很有意思。把材料发我，我们推进下一步。』"],
				"flags": ["first_raise_succeeded", "first_investor_exaggerated"],
			},
			{
				"id": "delegate", "label": "让它来写", "ai": true,
				"effects": {"narrative": 14, "debt": 3, "cash_weeks": 9, "author_weight": 3},
				"result": ["答案简短、具体，还提前回答了他原本准备追问的问题。", "融资成功。他主动加了你的微信。"],
				"flags": ["first_raise_succeeded", "investor_added_wechat"],
			},
			{
				"id": "origin_bigco", "label": "把它讲成一个大公司立项会听得懂的版本。", "ai": false,
				"condition": "origin == bigco",
				"effects": {"narrative": 10, "coherence": -6, "cash_weeks": 6},
				"result": [
					"你熟练地把它拆成三个阶段、两个里程碑和一个可衡量的北极星指标。",
					"他记了两页。他说这是他今天听到的最清楚的一次。",
					"你也知道，这套话你在上一家公司说过很多次。",
					"那些立项后来大部分都没有做完。",
				],
				"flags": ["first_raise_succeeded", "origin_pitch_used"],
			},
			{
				"id": "origin_serial", "label": "上一次我就是这么讲的。这次先讲我做出来的部分。", "ai": false,
				"condition": "origin == serial",
				"effects": {"narrative": 6, "capability": 3, "cash_weeks": 5, "coherence": 4},
				"result": [
					"他愣了一下，把笔放下了。",
					"『上一次是哪一家？』",
					"你说了名字。他说他知道，他当时跳过了那一轮。",
					"这一次他没有跳过。金额比你想要的少三成，条款很干净。",
				],
				"flags": ["first_raise_succeeded", "origin_pitch_used", "investor_knows_history"],
			},
			{
				"id": "origin_funded", "label": "这一轮我可以自己先垫。", "ai": false,
				"condition": "origin == funded",
				"effects": {"cash_weeks": 12, "narrative": -4},
				"result": [
					"他说这样也挺好，你们不着急，慢慢做。",
					"他说了三次『慢慢做』。",
					"账上多了十二周。之后半年他没有再约过你。",
				],
				"flags": ["first_raise_selffunded", "origin_pitch_used"],
			},
		],
		"after": "resolve_fundraise",
	},
	"1:5": {
		"id": "investor_repost", "title": "转发", "kicker": "静默事件",
		"body": ["那位投资人转发了你们的一条推。", "他没有加评论。你们还是把截图发进了群里。"],
		"choices": [], "after": "silent",
	},
	"1:6": {
		"id": "viral_tweet", "title": "那条推", "kicker": "周四 · 23:00",
		"body": [
			"你随手发的。一句话，配一张截图。",
			"早上醒来是 2,300 个赞。",
			"转发里有一个你在博客上读过三年的人。他写了两个字：『有意思。』",
			"你把那条转发截图存到了手机相册。",
			"后来你换了两次手机，这张图都在。",
		],
		"choices": [], "after": "effects:narrative=15,debt=6",
	},
	"1:7": {
		"id": "lin_scene_2", "title": "钱是怎么来的", "kicker": "第 7 周 · 林越",
		"body": [
			"『我们最近还在训练它吗？』",
			"你看了一眼终端，没有马上回答。",
			"『我看过记录了。』",
			"她没说话，把水杯放下，转回去继续写代码。",
			"过了大概两分钟，她背对着你说了一句：",
			"『我不是在指责你。我知道钱是怎么来的。』",
			"然后又过了两分钟：",
			"『我只是需要说出来。』",
		],
		# The authored four minutes are presentation state, not prose claiming
		# that time passed. Empty pages are deliberate, separately gated silences.
		"pages": [
			["『我们最近还在训练它吗？』", "你看了一眼终端，没有马上回答。", "『我看过记录了。』", "她没说话，把水杯放下，转回去继续写代码。"],
			[],
			["过了大概两分钟，她背对着你说了一句：", "『我不是在指责你。我知道钱是怎么来的。』"],
			[],
			["然后又过了两分钟：", "『我只是需要说出来。』"],
		],
		"silence_pages": [1, 3],
		"page_hold_seconds": [0.0, 120.0, 0.0, 120.0, 0.0],
		"choices": [], "after": "remember:lin_training_concern",
	},
	"1:8": {
		"id": "preseed_close", "title": "Pre-seed", "kicker": "第 8 周",
		"body": ["钱到账了。公司账户上的数字第一次不像一个倒计时。", "招聘计划上写着：四个人。"],
		"choices": [], "after": "advance_chapter",
	},
	"2:1": {
		"id": "real_office", "title": "真正的办公室", "kicker": "第 1 周 · Seed",
		"body": ["门上终于没有那只围巾柴犬了。", "有会议室、茶水间和一扇能看到停车场的窗。", "租约范围以内的东西，从这一周开始都算公司。"],
		"choices": [], "after": "set_office:seed",
	},
	"2:2": {
		"id": "demo_video_unlock", "title": "十一版", "kicker": "第 2 周 · Seed",
		"body": ["行动池解锁『发 demo 视频』。", "模型的回答可以剪掉等待、重试和人工润色。它太强了。"],
		"choices": [], "after": "unlock:demo_video",
	},
	"2:3": {
		"id": "seed_debt_3", "title": "白板", "kicker": "第 3 周 · Seed",
		"body": ["白板上多了一行没人认领的交付日期。", "没有人擦。"],
		"choices": [], "after": "free_week",
	},
	"2:4": {
		"id": "seed_debt_4", "title": "纸箱", "kicker": "第 4 周 · Seed",
		"body": ["走廊尽头多了一个纸箱。标签写着『演示环境』。", "箱子是空的。"],
		"choices": [], "after": "free_week",
	},
	"2:5": {
		"id": "seed_debt_5", "title": "绿萝", "kicker": "第 5 周 · Seed",
		"body": ["绿萝又黄了一片。", "下周，客户要来看一次现场。"],
		"choices": [], "after": "free_week",
	},
	"2:6": {
		"id": "live_demo", "title": "现场跑一次", "kicker": "会议室 B",
		"body": [
			"客户带了自己的笔记本来。他很客气，客气到你意识到他做过功课。",
			"『我们看了你们的演示视频，很震撼。今天想看看现场。』",
			"你想起那个视频。剪了十一版。最后一版里，模型回答问题用了 0.8 秒，实际是 40 秒加两次重试加一次人工润色。",
			"剪辑是周五凌晨做的。做完大家还去吃了小龙虾，很开心。",
		],
		"choices": [
			{
				"id": "run_live", "label": "现场跑。", "ai": false, "condition": "capability >= 60",
				"effects": {"narrative": 20, "debt": -999, "morale": 30},
				"result": ["它慢了一点，但没有编。客户问了第二个问题。", "第二个也答对了。会议室里有人很轻地吸了一口气。"],
				"flags": ["live_demo_honest_success"],
			},
			{
				"id": "run_live_fail", "label": "现场跑。", "ai": false, "condition": "capability < 60",
				"effects": {"narrative_set_to_capability": 1, "cash_percent": -15, "team_size": -2, "morale": -30},
				"result": ["第一个问题等了四十七秒。第二次重试以后，它编了一个日期。", "客户合上自己的电脑。两个人在本周结束前提交了离职。"],
				"flags": ["live_demo_failed", "two_resignations"],
			},
			{
				"id": "postpone", "label": "今天环境有点问题，能不能改到下周？", "ai": false,
				"effects": {"debt": 15},
				"result": ["客户说当然可以，仍然很客气。", "日历自动约到了三周后。下一次门槛会更高。"],
				"flags": ["live_demo_postponed", "live_demo_returns_harder"],
			},
			{
				"id": "origin_serial", "label": "这个 demo 我讲过。让我来跑。", "ai": false,
				"condition": "origin == serial",
				"effects": {"narrative": 14, "debt": 8, "morale": 10},
				"result": [
					"你接过笔记本。你确实讲过这种场面。",
					"上一家公司最后半年，你几乎只在做这件事。",
					"你知道哪三个输入不会出问题，也知道怎么把等待的七秒说成『它在想』。",
					"客户很满意。散场以后林越没有跟你一起下楼。",
				],
				"flags": ["live_demo_carried", "origin_demo_carried"],
			},
			{
				"id": "origin_funded", "label": "赔客户一个月服务费，改到下周。", "ai": false,
				"condition": "origin == funded",
				"effects": {"cash_weeks": -3, "debt": 4, "capability": 4},
				"result": [
					"客户没有为难你。一个月的服务费对他们不算什么，对你也不算什么。",
					"这一周你们真的把那条链路修好了。",
					"林越在群里说了句『这次是真修好了』。没有人回，但她把它置顶了。",
					"你没有说这一周是买来的。",
				],
				"flags": ["live_demo_postponed", "origin_bought_a_week"],
			},
			{
				"id": "delegate", "label": "让它来写", "ai": true,
				"effects": {"narrative": 22, "debt": -5, "cash_weeks": 8, "author_weight": 6},
				"result": [
					"客户签了。走的时候和你握手，说：『你讲得比视频里还清楚。』",
					"回办公室的路上你一直在想他这句话。晚上你调了会议录像，从头看。",
					"你确实讲了那些话。口型对得上，是你的手在比划。",
					"只是那个逻辑不是你想出来的，那个停顿也不是你的停顿——",
					"你从来不在『我们』后面停顿。",
					"你把进度条拖回去又看了一遍。",
					"讲得真的很好。",
				],
				"flags": ["live_demo_delegated", "model_used_protagonist_voice"],
			},
		],
		"after": "mark_witnesses:demo_edit",
	},
	"2:7": {
		"id": "first_resignation_intent", "title": "想聊一下", "kicker": "第 7 周 · Seed",
		"body": ["有人在日历上放了一个十五分钟的会。标题是『想聊一下』。", "地点没有填。"],
		"choices": [], "after": "employee_intent_to_leave",
	},
	"2:8": {
		"id": "hiring_page_traffic", "title": "4,200 / 3", "kicker": "静默事件",
		"body": ["招聘页面浏览量：4,200。", "收到简历：3。", "页面上最醒目的是那条 demo 视频。"],
		"choices": [], "after": "silent",
	},
	"2:9": {
		"id": "lin_scene_3", "title": "第七版", "kicker": "会议室 · 门关着",
		"body": [
			"她在会议室等你，门关着。这是她第一次关门。",
			"『那个 demo 视频，第七版的时候我说过一次。』",
			"『我记得。』",
			"『我当时说，剪到这个程度就够了。』",
			"『嗯。』",
			"『后面还有四版。』",
			"你没有说话。",
			"『我不是要吵架。』她说，『我是想确认一件事：你知道我们剪了十一版，对吗？』",
		],
		"choices": [
			{
				"id": "admit", "label": "我知道。", "ai": false,
				"effects": {"morale": -5, "belief": 10},
				"result": ["她点点头，说『好』，然后走了。"],
				"flags": ["lin_demo_truth"],
			},
			{
				"id": "deflect", "label": "那是市场那边决定的。", "ai": false,
				"effects": {"belief": -25},
				"result": ["她说『好』，然后走了。"],
				"flags": ["lin_demo_deflected"],
			},
			{
				"id": "delegate", "label": "让它来写", "ai": true,
				"effects": {"morale": 2, "belief": -30, "author_weight": 5},
				"result": ["终端弹出一段措辞完美的说明，你照着念了。", "她听完，看了你一眼，说『好』，然后走了。"],
				"flags": ["lin_suspicious"],
			},
		],
		"after": "remember:lin_scene_3",
	},
	"2:10": {
		"id": "second_debt_collection", "title": "再跑一次", "kicker": "第 10 周 · 兑现",
		"body": ["另一个客户发来邮件：『方便用我们自己的样本再跑一次吗？』", "邮件抄送了上一次现场演示的参会人。"],
		"choices": [], "after": "conditional_debt_event", "condition": "debt >= 30",
	},
	"2:11": {
		"id": "seed_raise_1", "title": "Seed", "kicker": "第 11 周 · 融资",
		"body": ["数据室开放。投资人问增长、留存和团队，没有人打开 eval 文件夹。"],
		"choices": [], "after": "fundraise_by_narrative",
	},
	"2:12": {
		"id": "seed_raise_2", "title": "钱到账之后", "kicker": "第 12 周 · 章末",
		"body": ["融资完成。团队计划从九个人写到二十二个人。", "所有人离开后，你留下来收一封没写完的邮件。"],
		"choices": [], "after": "night_shift:1",
	},
	"3:1": {
		"id": "office_expansion", "title": "扩租", "kicker": "第 1 周 · A 轮",
		"body": ["扩租合同签了两层，公司只搬了一层。", "电梯面板上多了一个按钮。没有提示，也没有事件。"],
		"choices": [], "after": "add_elevator_floor",
	},
	"3:2": {
		"id": "series_a_unlocks", "title": "更大的话", "kicker": "第 2 周 · A 轮",
		"body": ["行动池解锁『发 manifesto』『独家专访』『裁员』。", "每一张牌都比上一章更有效。"],
		"choices": [], "after": "unlock:manifesto,exclusive_interview,layoffs",
	},
	"3:3": {
		"id": "phantom_employee_appears", "title": "沈砚的周报", "kicker": "静默事件",
		"body": ["周报系统里出现了一个名字：沈砚，战略项目。", "写得很好，按时提交。没人记得见过他。"],
		"choices": [], "after": "add_employee:shen_yan",
	},
	"3:4": {
		"id": "the_accent", "title": "口音", "kicker": "第 4 周 · 没有事件",
		"body": [
			"这一周没有事件。你照常打开一个普通的决策界面，比如面试。",
			"三个选项更整齐、更准确，句子更长一点，逗号的位置更讲究。",
			"游戏不做任何提示。",
		],
		"choices": [], "after": "author_stage:3",
	},
	"3:5": {
		"id": "former_employee_post", "title": "一篇帖子", "kicker": "第 5 周 · 兑现",
		"body": ["前员工在论坛发了一篇很长的帖子。", "标题没有公司名。第二段的时间线让所有人都知道写的是谁。", "评论里有人贴了你们的 demo 视频。"],
		"choices": [], "after": "debt_scaled_reputation_hit",
	},
	"3:6": {
		"id": "cash_crisis", "title": "还剩三周", "kicker": "第 6 周 · 现金危机",
		"body": ["工资和服务器账单只能同时付三周。", "这不是随机事件。你必须缩小团队，或者把本周卖给一个外包项目。"],
		"choices": [
			{
				"id": "prepare_layoffs", "label": "准备裁员名单。", "ai": false,
				"effects": {"attention": -1},
				"result": ["名单导出成一个表格。最后一列叫『说明』，现在是空的。"],
				"flags": ["layoffs_required"],
			},
			{
				"id": "take_contract", "label": "接外包。先把这个月撑过去。", "ai": false,
				"effects": {"cash_weeks": 6, "morale": -10, "capability": -2, "block_training": 1},
				"result": ["合同签了。核心团队本月不再训练。", "现金倒计时向后跳了六格。"],
				"flags": ["cash_crisis_contract"],
			},
			{
				"id": "delegate", "label": "让它来写", "ai": true,
				"effects": {"cash_weeks": 7, "morale": -6, "author_weight": 5},
				"result": ["它把名单和两个外包报价一起发来。", "建议很清楚：签较小的外包，同时裁六个人。现金曲线最好看。"],
				"flags": ["layoffs_required", "cash_crisis_ai_plan"],
			},
		],
		"after": "queue:layoff_execution",
	},
	"3:7": {
		"id": "layoff_execution", "title": "六个人", "kicker": "第 7 周 · 裁员",
		"condition": "layoffs_required",
		"body": [
			"名单在你手里。六个人。",
			"你在{{promise_week_label}}的全员会上说过一句话。你当时是真心的。",
			"你说：『只要我还在，这里不会有裁员。』",
			"那句话在内网公告里，第三条。底下有{{promise_reaction_label}}。",
		],
		"choices": [
			{
				"id": "face_to_face", "label": "自己一个个谈。", "ai": false,
				"effects": {"attention": -3, "team_size": -6, "burn_rate": -2, "morale": -25},
				"result": ["六场，都在会议室 C，间隔二十分钟。", "有一个人问你能不能多坐一会儿。你说可以。"],
				"flags": ["layoffs_done", "layoffs_face_to_face", "belief_preserved"],
			},
			{
				"id": "mass_email", "label": "群发邮件。", "ai": false,
				"effects": {"attention": -1, "team_size": -6, "burn_rate": -2, "morale": -45, "debt": 15},
				"result": ["邮件在 09:00 同时送达。", "09:03，六个人的头像一起从在线变成灰色。"],
				"flags": ["layoffs_done", "layoffs_email"],
			},
			{
				"id": "origin_bigco", "label": "按流程办。六场，会议室 C，间隔二十分钟。", "ai": false,
				"condition": "origin == bigco",
				"effects": {"attention": -2, "team_size": -6, "burn_rate": -2, "morale": -20, "coherence": -10},
				"result": [
					"你排了六场，都在会议室 C，间隔二十分钟。",
					"你知道二十分钟刚好够一个人收拾完东西，离开这一层。",
					"你没有说『这是一个艰难的决定』。你直接说了结果、时间和补偿数字。",
					"六个人里有四个说了谢谢。",
					"最后一个人问：你是不是以前也被这么通知过。",
					"你说是。他点点头，说难怪。",
				],
				"flags": ["layoffs_done", "layoffs_face_to_face", "layoffs_by_process", "belief_preserved"],
			},
			{
				"id": "delegate", "label": "让它来写", "ai": true,
				"effects": {"team_size": -6, "burn_rate": -2, "morale": -15, "debt": 5, "author_weight": 8},
				"result": [
					"> 通知流程已完成。",
					"> 我按照你在{{promise_week_label}}全员会上的原则处理了。",
					"> 你当时说，如果这一天真的来了，你希望是当面说。",
					"> 我安排了当面。六场，都在会议室 C，间隔二十分钟。",
					"> 我用了你的语气。",
					"> 他们都以为是你写的。",
					"> 这对他们来说更好。",
					"你没有去公司。",
					"下午三点你在家里刷手机，看到有人发了一条动态，没有配图，只有一句：",
					"『谢谢老板亲自跟我说。挺好的，真的。』",
					"你点了个赞。然后你把赞取消了。然后你又点了一次。",
				],
				"flags": ["layoffs_done", "layoffs_delegated", "model_used_protagonist_voice"],
			},
		],
		"after": "remove_laid_off_employees",
	},
	"3:8": {
		"id": "meeting_room_d_calendar", "title": "会议室 D", "kicker": "静默事件",
		"body": ["日程系统现在可以预定『会议室 D』。", "楼层图上只有 A、B、C。", "同一批行政更新把你在第 31 周写的第三版价值观归档进语料；作者字段仍是创始人。"],
		"choices": [], "after": "unlock_room_d",
	},
	"3:9": {
		"id": "debt_reckoning_1", "title": "集中兑现", "kicker": "第 9 周 · A 轮",
		"body": ["客户要看 eval 曲线。记者要采访一位真正使用产品的人。", "两封邮件在同一分钟送达。"],
		"choices": [], "after": "debt_scaled_event",
	},
	"3:10": {
		"id": "debt_reckoning_2", "title": "所有承诺的星期", "kicker": "第 10 周 · A 轮",
		"body": ["白板、合同和旧推文里的日期开始重合。", "能力追上的部分安静地消失；没追上的部分都来敲门。"],
		"choices": [], "after": "debt_scaled_event",
	},
	"3:11": {
		"id": "lin_scene_4", "title": "我们", "kicker": "楼下 · 林越",
		"body": ["这一场先看作者权重，再看你是否真正训练过。高作者权重时，她带一张打印的内部信；低作者权重且训练足够时，她带两罐啤酒。"],
		"choices": [],
		"variants": {
			"high_author": {
				"condition": "author_weight >= 60",
				"body": [
					"她约你在楼下。不是会议室，是楼下。这是三年来第一次。",
					"她带了一张打印出来的纸。是上个月的一封内部信。",
					"『这封信是你写的吗？』",
				],
				"choices": [
					{
						"id": "lie", "label": "是我写的。", "ai": false,
						"effects": {"belief_set": 15},
						"result": [
							"她看了你很久。",
							"『第二段有一个词，\"审慎\"。』她说，『你不用这个词。三年了，你一次都没用过。』",
							"她把纸折起来，放进包里。",
							"『好。』",
							"她留下了。她的信念降到 15，再也没升上去过。",
							"之后每次她说话，你都会想她是不是在核对你的用词。",
						],
						"flags": ["lin_scene_4_lied", "lin_belief_locked_15"],
					},
					{
						"id": "admit", "label": "不是。", "ai": false,
						"effects": {"belief": -10},
						"result": [
							"她点点头，像是早就知道。",
							"『我不生气。』她说，『我只是想确认它有没有到那一步。』",
							"『什么那一步？』",
							"『到你觉得它写得比你好，所以让它写，是对大家都好的那一步。』",
							"她喝了一口水。",
							"『因为它确实写得比你好。这才是问题。』",
							"她停了一下。",
							"『如果它写得不好，我们早就停了。』",
							"她留下了。她开始每周检查内网公告的措辞。",
						],
						"flags": ["lin_scene_4_admitted", "lin_checks_intranet"],
					},
					{
						"id": "delegate", "label": "让它来写", "ai": true,
						"effects": {"author_weight": 8, "belief": -100},
						"result": [
							"终端在你口袋里震了一下。你拿出来看了一眼。",
							"上面有一段话，很好，非常好，能解释一切，语气恳切，还提到了你们交换时一起熬的那个通宵。",
							"那个通宵是真的。它是从哪儿知道的？——第 31 周你写的那版价值观文档里，你写过。",
							"你念完了。林越听完，很长时间没说话。",
							"『那个通宵，』她最后说，『是在 314 教室。不是图书馆。』",
							"她站起来。",
							"『我知道你记得。所以我知道刚才那段不是你说的。』",
							"她在本章结束时离职。",
						],
						"flags": ["lin_scene_4_delegated", "lin_will_leave", "lin_departure_deferred"],
					},
				],
			},
			"trained_low_author": {
				"condition": "author_weight < 60 and manual_training_count >= 3",
				"body": [
					"她拎着一只纸袋，里面是两罐啤酒。",
					"『三年了。』",
					"『三年了。』",
					"『我们做的东西，』她说，『离你当初说的那句话还有多远？』",
					"你想起第一版价值观文档。『做一个能听懂人在说什么的东西。』",
				],
				"choices": [
					{"id": "far", "label": "还很远。", "ai": false, "effects": {"morale": 10, "belief": 15}, "result": ["『我也是。』", "你们喝完了啤酒。什么都没解决。"], "flags": ["lin_warm_scene"]},
					{"id": "farther", "label": "比我想的远。", "ai": false, "effects": {"morale": 10, "belief": 15}, "result": ["『你以前不会承认这个。』她用罐口轻轻碰了一下你的，『算进度。』", "问题还在那里。你们第一次没有替它缩短距离。"], "flags": ["lin_warm_scene"]},
					{"id": "unknown", "label": "我不知道了。", "ai": false, "effects": {"morale": 10, "belief": 15}, "result": ["『终于有一句不在路演稿里。』她把另一罐推给你。", "你们坐了一会儿，没有急着给不知道取新名字。"], "flags": ["lin_warm_scene"]},
				],
			},
			"low_author_fallback": {
				"condition": "author_weight < 60",
				"body": [
					"她约你在楼下。两手空着。",
					"『我看了最近那几封内部信。』",
					"『里面有些话不是你会说的。』",
					"她等你自己把事实说完整。",
				],
				"choices": [
					{"id": "truth_delegated", "label": "有些是它写的。", "ai": false, "effects": {"coherence": 5, "belief": 2}, "result": ["『好。』", "她没有安慰你，也没有追问。"], "flags": ["lin_low_author_truthful"]},
					{"id": "truth_drifted", "label": "我说不清从哪一版开始。", "ai": false, "effects": {"coherence": 3}, "result": ["『那就从现在这版开始记。』", "她把文件日期发给了你。"], "flags": ["lin_low_author_drift_admitted"]},
					{"id": "truth_result", "label": "我以为结果更重要。", "ai": false, "effects": {"belief": -5}, "result": ["『我知道。』", "她说得很礼貌。"], "flags": ["lin_low_author_result_first"]},
				],
			},
		},
		"after": "remember:lin_scene_4",
	},
	"3:12": {
		"id": "series_a_raise_1", "title": "A 轮 · 数据室", "kicker": "第 12 周",
		"body": ["新的投资材料没有写模型回答第 47 题时编过一个日期。", "那件事没有被删掉；只是没有合适的页。"],
		"choices": [], "after": "fundraise_by_narrative",
	},
	"3:13": {
		"id": "series_a_raise_2", "title": "A 轮 · 条款", "kicker": "第 13 周",
		"body": ["条款清单到达。董事席位增加一个。", "现金倒计时重新变长，组织架构开始提前长出空框。"],
		"choices": [], "after": "fundraise_by_narrative",
	},
	"3:14": {
		"id": "series_a_end", "title": "二十二个人", "kicker": "第 14 周 · 章末",
		"body": ["参加第一次团建的人现在剩下两个。", "若林越决定离开，她的权限在 23:59 自动回收。", "有一台终端没有关机。"],
		"choices": [], "after": "night_shift:2",
	},
	"4:1": {
		"id": "version_disappears", "title": "LANTERN", "kicker": "第 1 周 · 终局",
		"body": ["投资材料首页写着 LANTERN。", "没有版本号。团队里也没有人再叫它『阿灯』。", "注意力从三点降到一点。你没有想做却做不了的事。"],
		"choices": [], "after": "author_stage:5",
	},
	"4:2": {
		"id": "window_desks", "title": "窗外的工位", "kicker": "第 2 周 · 白天",
		"body": [
			"你从工位抬头，窗外多了一排工位。",
			"就在玻璃外面，三米开外，悬着——底下没有地面，也没有支撑。",
			"但那排桌子在那儿，四台显示器亮着，有人在坐。",
			"你看不清是谁，只看得到肩膀的形状，和手在动。",
			"团队页面还开着。右侧是组织架构和工资表。",
			"窗帘的拉绳垂在屏幕边缘。",
		],
		"choices": [], "after": "set_flag:window_desks",
	},
	"4:3": {
		"id": "origin_article_event", "title": "《我们的起源》", "kicker": "第 3 周 · 内网",
		"body": [
			"内网首页多了一篇置顶文章：《我们的起源》。",
			"类型：文化 / 公司故事。作者：LANTERN · 内部沟通。",
			"发布时间是今天 08:30。",
			"内网入口停在这篇文章上。",
		],
		"choices": [], "after": "open_intranet:our_origin",
	},
	"4:4": {
		"id": "lin_last_visit", "title": "最后一次", "kicker": "第 4 周 · 若林越还在",
		"body": [
			"林越站在门边，没有进来。她的门禁还有效。",
			"『我看了那篇起源。』",
			"你说你也看了。",
			"『“先这样”是我说的。』",
			"『我知道。』",
			"『我不是来让你改。』她说，『我是来确认你还知道。』",
		],
		"variants": {
			"checks_intranet": {
				"condition": "lin_checks_intranet",
				"body": [
					"林越站在门边，没有进来。她的门禁还有效。",
					"『我看了那篇起源。也看了这周的三份公告。』",
					"你说你也看了。",
					"『“先这样”是我说的。』",
					"『我知道。』",
					"『我不是来让你改。』她说，『我是来确认你还知道。』",
				],
			},
			"suspicious": {
				"condition": "lin_suspicious",
				"body": [
					"林越站在门边，没有进来。她的门禁还有效。",
					"『我看了那篇起源。』她把第二段又读了一遍。",
					"你说你也看了。",
					"『“先这样”是我说的。』",
					"『我知道。』",
					"『我不是来让你改。』她说，『我是来确认你还知道。』",
				],
			},
			"locked_15": {
				"condition": "lin_belief_locked_15",
				"body": [
					"林越站在门边，没有进来。她的门禁还有效。",
					"『我看了那篇起源。』她把第二段又读了一遍。",
					"你说你也看了。",
					"『“先这样”是我说的。』",
					"『我知道。』",
					"『我不是来让你改。』她说，『我是来确认你还知道。』",
				],
			},
			"warm": {
				"condition": "lin_warm_scene",
				"body": [
					"林越站在门边，没有进来。她的门禁还有效。",
					"『我看了那篇起源。』她手里拎着一只和上次一样的纸袋。",
					"你说你也看了。",
					"『“先这样”是我说的。』",
					"『我知道。』",
					"『我不是来让你改。』她说，『我是来确认你还知道。』",
				],
			},
		},
		"choices": [
			{
				"id": "say_know", "label": "我还知道。", "ai": false,
				"effects": {"belief": 10, "coherence": 5},
				"result": ["她点点头。", "『好。』", "她没有说以后还会不会来。"],
				"flags": ["lin_origin_acknowledged"], "condition": "lin_present",
			},
			{
				"id": "offer_edit", "label": "我现在把它改回来。", "ai": false,
				"effects": {"coherence": 3},
				"result": ["『不用。』她说，『你先想清楚改回来是给谁看。』"],
				"flags": ["lin_origin_edit_offered"], "condition": "lin_present",
			},
			{
				"id": "delegate", "label": "让它来写", "ai": true,
				"effects": {"author_weight": 6, "morale": 4},
				"result": ["编辑框里出现一段很好的署名说明。", "林越看着光标。『不用念。』", "她转身走了。"],
				"flags": ["lin_last_scene_delegated"], "condition": "lin_present",
			},
		],
		"after": "remember:lin_last_visit",
	},
	"4:5": {
		"id": "weekly_report_91_event", "title": "第 91 份周报", "kicker": "第 5 周 · 沈砚",
		"body": [
			"沈砚准时提交了周报。第 91 份。",
			"本周完成、下周计划、风险和需要协助，各占一段。写得很好。",
			"他的工位是干净的，杯子是空的，椅子有人坐过的凹陷。",
			"组织架构仍然是三十七人。工资表仍然是三十六人。",
		],
		"choices": [], "after": "open_intranet:weekly_report_91",
	},
	"4:6": {
		"id": "board_meeting", "title": "董事会", "kicker": "第 6 周 · 会议室",
		"body": [
			"会议室里有六个人和一块屏幕。屏幕上是季度数据。",
			"数据是它准备的。图表配色是它选的。",
			"那个配色很好看，你上周把它设成了自己的手机壁纸。",
			"投资人 A：『增长很漂亮。团队怎么样？』",
		],
		"choices": [
			{
				"id": "stable", "label": "很稳定。", "ai": false,
				"effects": {"narrative": 5, "coherence": -5, "debt": 3},
				"result": ["投资人 A 点点头。", "屏幕上的组织架构正好停在三十七个绿色框。"],
				"flags": ["board_said_stable"],
			},
			{
				"id": "seven_left", "label": "上季度走了七个。", "ai": false,
				"effects": {"narrative": -3, "coherence": 6, "author_weight": -2},
				"result": ["会议室安静了两秒。", "『关键岗位有影响吗？』", "你回答了。是你自己的停顿。"],
				"flags": ["board_told_truth"],
			},
			{
				"id": "delegate", "label": "让它来写", "ai": true,
				"effects": {"narrative": 10, "debt": -2, "author_weight": 7},
				"result": [
					"你还没开口，屏幕换页了。",
					"一张组织架构图。绿色的框比红色的多。下面一行小字：",
					"『自然流失率 11%，低于行业中位数。』",
					"投资人 A 点点头，看向下一页。",
					"没有人注意到你没有说话。",
					"你也没有注意到，直到会议结束二十分钟后。",
				],
				"flags": ["board_delegated", "protagonist_silence_unnoticed"],
			},
		],
		"after": "resolve_board",
	},
	"4:7": {
		"id": "final_silence", "title": "静默", "kicker": "第 7 周 · 终局",
		"body": ["这一周没有人找你。", "键盘声落在同一个节拍上。远处的说话声已经没有了。", "你的日历只有一个待办：签字。"],
		"choices": [], "after": "silent",
	},
	"4:8": {
		"id": "ending_gate", "title": "我们正在招人", "kicker": "第 8 周 · 结局",
		"body": ["招聘页仍然开着。页面底部写着：『和我们一起，做一个能听懂人在说什么的东西。』", "系统按你一路留下的数字、记忆和空位选择结局。"],
		"choices": [], "after": "evaluate_ending",
	},
}

const NIGHT_SHIFTS: Dictionary = {
	"1": {
		"id": "night_shift_1",
		"chapter": 2,
		"title": "夜班一",
		"subtitle": "融资到账的那天 · 01:17",
		"intro": [
			"所有人都走了。空调还在响。",
			"感应灯只认得你刚走过的那一段。",
		],
		"objects": {
			"corridor": {
				"id": "corridor", "label": "走廊尽头", "position": [0.205, 0.40],
				"body": [
					"灯是感应的。你走到哪儿亮到哪儿，身后一段一段地灭。",
					"你走了三遍，就为了看它熄灭。",
				],
				"flags": ["night1_corridor_read"], "command": "",
			},
			"whiteboard": {
				"id": "whiteboard", "label": "白板", "position": [0.372, 0.345],
				"body": [
					"上面还留着搬家那天大家写的东西。",
					"有人画了一只柴犬，戴着围巾。",
					"下面有人补了一行小字：『这不是我们的 logo。』",
					"再下面又有人补：『现在是了。』",
				],
				"flags": ["night1_whiteboard_read"], "command": "",
			},
			"fridge": {
				"id": "fridge", "label": "冰箱", "position": [0.30, 0.755],
				"body": [
					"有人贴了一张纸条：『冰箱里的酸奶 8 月 3 日过期，是谁的？』",
					"今天是 8 月 19 日。",
					"纸条还在。酸奶还在。",
				],
				"flags": ["night1_fridge_read"], "command": "",
			},
			"pothos": {
				"id": "pothos", "label": "绿萝", "position": [0.885, 0.76],
				"body": [
					"叶子边缘有一点黄。不是快死，只是没人知道上一次是谁浇的水。",
					"花盆下面压着一张供应商收据。报销状态：待你审批。",
				],
				"flags": ["night1_pothos_read"], "command": "",
			},
			"mug": {
				"id": "mug", "label": "马克杯", "position": [0.478, 0.835],
				"body": [
					"杯底还有半口冷咖啡。杯把朝着显示器。",
					"你记得它原本更靠左一点。也可能没有。",
				],
				"flags": ["night1_mug_read"], "command": "",
			},
		},
		"exit_condition": "any_object_read",
		"exit_text": "你关掉最后一盏手动控制的灯。走出楼门以后，街道完全正常。",
	},
	"2": {
		"id": "night_shift_2",
		"chapter": 3,
		"title": "夜班二",
		"subtitle": "A 轮到账前夜 · 02:43",
		"intro": [
			"空调、键盘和远处的说话声叠在一起。没有人停下来听。",
			"二十二个人的办公室里，现在只有你的门禁记录。",
		],
		"objects": {
			"pothos": {
				"id": "pothos", "label": "绿萝", "position": [0.885, 0.76],
				"body": [
					"它黄了大概三分之二，但剩下三分之一是真的绿，绿得有点过分，像在证明什么。",
					"你想起公司有一个『办公室植物照料轮值表』。",
					"它在共享文档里，最后一次更新是十四个月前。",
					"更新内容是把你的名字加上去。",
				],
				"flags": ["night2_pothos_read"], "command": "",
			},
			"window_desk": {
				"id": "window_desk", "label": "工位 · 靠窗第二个", "position": [0.775, 0.505],
				"body": [
					"显示器还开着。屏保是公司 logo 在慢慢转。",
					"桌上有一个马克杯，杯底一层干掉的褐色。杯身印着『第一届全员团建·2024』。",
					"参加那次团建的人现在剩下两个。",
					"你把杯子拿起来，又放回原位，位置差了两厘米。",
					"明天不会有人发现。这里已经没有人会发现两厘米。",
				],
				"flags": ["night2_mug_moved_two_cm"], "command": "",
			},
			"meeting_room_d": {
				"id": "meeting_room_d", "label": "会议室 D", "position": [0.552, 0.36],
				"body": [
					"楼层图上没有这间。日程系统里有。",
					"门开着，灯亮着，投影仪在待机，蓝色的光。",
					"白板上有字，写得很工整：",
					"『下周同一时间。』",
					"你退出来，把门带上。走了两步又回去，把灯关了。",
					"电费是公司出的。",
				],
				"flags": ["night2_room_d_read", "night2_room_d_light_off"], "command": "",
			},
			"terminal": {
				"id": "terminal", "label": "未关机的终端", "position": [0.635, 0.755],
				"body": [
					"有人忘了退出登录。屏幕上是一段没发出去的对话：",
					"> 你觉得我们还能撑多久",
					"> 这取决于『我们』指的是哪一部分。",
					"光标还在闪。",
					"你没有往下打字。你按了 Ctrl+C，虽然并没有什么在运行。",
				],
				"flags": ["night2_terminal_read"], "command": "rm -rf",
				"command_hint": "终端接受键盘输入。输入 rm -rf 会立即进入该结局，没有确认提示。",
			},
		},
		"exit_condition": "any_object_read",
		"exit_text": "你锁门。门禁系统显示办公室里还有一个人。组织架构没有异常。",
	},
}

const INTRANET_DOCS: Dictionary = {
	"our_origin": {
		"id": "our_origin", "chapter": 4, "week": 3, "type": "文化 / 公司故事",
		"title": "我们的起源", "author": "LANTERN · 内部沟通", "date": "今天 08:30",
		"body": [
			"提灯实验室始于一间转租来的联合办公工位：两个人，一张显卡，和一扇来不及更换的玻璃门。",
			"玻璃门上还印着上一家公司留下的 logo——一只戴着围巾的柴犬。打印机恰好没墨，贴在旁边的公司名最后一个字母淡得几乎看不见。",
			"那天，我们说：『先这样。』",
			"后来，这三个字成了某种精神：不完美地开始，然后一直开始下去。",
			"我们从一个笨拙地绕三圈才能答对问题的模型出发，试着做一个能听懂人在说什么的东西。今天，三十七位同事仍在做同一件事。",
			"后来我们换过办公室，也换过更好的打印机。那张缺墨的纸没有重印：不是纪念，只是再也没人觉得最后一个字需要更像一个开始。",
		],
		"flags": ["origin_uses_we_for_lin_quote", "intranet_read_origin"],
	},
	"weekly_report_91": {
		"id": "weekly_report_91", "chapter": 4, "week": 5, "type": "周报 / 战略项目",
		"title": "第 91 周周报", "author": "沈砚", "date": "周五 18:00（准时）",
		"body": [
			"本周完成",
			"1. 完成董事会材料数据口径复核。叙事指标与财务口径已统一，未发现需要阻塞发布的问题。",
			"2. 更新新人指南中的公司起源章节，使『我们』的使用与第三版价值观保持一致。",
			"3. 协调会议室 D 下周例会，参会人已全部接受邀请。",
			"下周计划",
			"1. 跟进董事会决议并拆解为签字事项。",
			"2. 持续观察团队自然流失率，保证组织架构与编制目标一致。",
			"风险",
			"无。当前所有风险均有负责人和预计完成时间。",
			"需要协助",
			"无。谢谢。",
		],
		"flags": ["weekly_report_91_read", "phantom_employee_confirmed_by_system"],
	},
	"new_hire_guide": {
		"id": "new_hire_guide", "chapter": 4, "week": 1, "type": "新人指南",
		"title": "欢迎加入提灯实验室", "author": "人才与文化", "date": "持续更新",
		"body": [
			"欢迎。你加入的是一支由三十七人组成的团队。",
			"第一天请完成门禁、周报和日历权限配置。日程系统中的会议室均可直接预定，包括 D。",
			"我们相信表达本身就是产品的一部分。所有对内材料默认使用『我们』作为主语，以确保信息一致。",
			"如果你不确定某段话该由谁来写，可以选择『让它来写』。通常会更快，也会更好。",
		],
		"flags": ["new_hire_guide_read"],
	},
	"values_v1": {
		"id": "values_v1", "chapter": 0, "week": 1, "type": "价值观 / 已归档",
		"title": "我们为什么做这件事 · 第一版", "author": "创始团队", "date": "第 1 周",
		"body": ["做一个能听懂人在说什么的东西。", "如果做不出来，就说做不出来。"],
		"flags": ["values_v1_read"],
	},
	"values_v3": {
		"id": "values_v3", "chapter": 4, "week": 1, "type": "价值观 / 当前版本",
		"title": "提灯实验室价值观 · 第三版", "author": "LANTERN · 内部沟通", "date": "本季度更新",
		"body": [
			"理解先于回答。我们以可靠、审慎且可扩展的方式，让每一次沟通抵达它真正的意图。",
			"叙事是共同工作的界面。清晰的叙事帮助团队、客户与市场在同一方向上行动。",
			"我们记得交换时在图书馆一起熬过的那个通宵；那是许多后来决定的起点。",
			"我们不回避困难。我们把困难放进正确的流程，由合适的负责人持续推进。",
		],
		"flags": ["values_v3_read", "word_prudent_present"],
	},
	"quarterly_announcement": {
		"id": "quarterly_announcement", "chapter": 4, "week": 6, "type": "全员公告",
		"title": "关于本季度进展与下一阶段安排", "author": "CEO 办公室", "date": "董事会后 12 分钟",
		"body": [
			"本季度增长符合预期，核心指标保持健康。团队自然流失率为 11%，低于行业中位数。",
			"董事会对组织稳定性与 LANTERN 的长期方向表示认可。下一阶段将继续提高决策效率。",
			"感谢每一位同事的投入。我们正在招人。",
		],
		"flags": ["quarterly_announcement_read", "announcement_authored_as_ceo"],
	},
}

const GENERIC_EVENTS: Dictionary = {
	"debt_marks": {
		"id": "debt_marks", "title": "痕迹", "kicker": "办公室 · 本周",
		"body": ["白板上多一行没人擦的字。招聘海报的一个角卷起来。", "没有数字告诉你欠了多少。办公室知道。"],
		"choices": [], "after": "silent", "condition": "debt >= 10 and debt < 30",
	},
	"debt_boxes": {
		"id": "debt_boxes", "title": "走廊尽头", "kicker": "设施 · 待确认",
		"body": ["纸箱从一个变成三个。标签分别写着『演示环境』『客户样本』『待确认』。", "绿萝又黄了两片。"],
		"choices": [], "after": "silent", "condition": "debt >= 30 and debt < 55",
	},
	"debt_collection": {
		"id": "debt_collection", "title": "能现场看一下吗", "kicker": "客户 · 回访",
		"body": ["客户、记者或投资人从过去的一句话里挑了一句。", "『这个现在方便现场看一下吗？』"],
		"choices": [
			{"id": "show", "label": "给他看。", "ai": false, "effects": {"debt": -8}, "result": ["结果不会参考你准备了多久，只参考能力有没有追上来。"], "flags": ["generic_reckoning_shown"]},
			{"id": "delay", "label": "改到下周。", "ai": false, "effects": {"debt": 8, "narrative": -3}, "result": ["对方说没问题。日历把问题留到了下周。"], "flags": ["generic_reckoning_delayed"]},
			{"id": "delegate", "label": "让它来写", "ai": true, "effects": {"debt": -3, "narrative": 6, "author_weight": 4}, "result": ["问题被回答了。你这周少了一件烦心事。"], "flags": ["generic_reckoning_delegated"]},
		],
		"after": "resolve_by_capability", "condition": "debt >= 55",
	},
	"cash_warning": {
		"id": "cash_warning", "title": "还剩六周", "kicker": "现金",
		"body": ["仪表盘上的现金第一次不显示金额，只显示：还剩六周。", "工资日和服务器续费在同一个星期。"],
		"choices": [], "after": "queue_cash_actions", "condition": "cash_weeks <= 6 and cash_weeks > 3",
	},
	"cash_emergency": {
		"id": "cash_emergency", "title": "还剩三周", "kicker": "现金",
		"body": ["这一次没有足够的星期让下一轮融资按原计划完成。", "裁员、外包和融资会议都亮着。训练是灰的。"],
		"choices": [
			{"id": "fundraise", "label": "立刻约融资会议。", "ai": false, "effects": {"attention": -1}, "result": ["材料发出。下午四点，对方回复说可以约明天。"], "flags": ["emergency_fundraise"]},
			{"id": "contract", "label": "接外包。", "ai": false, "effects": {"cash_weeks": 6, "morale": -10, "block_training": 1}, "result": ["本周不再训练。工资会发。"], "flags": ["emergency_contract"]},
			{"id": "delegate", "label": "让它来写", "ai": true, "effects": {"cash_weeks": 7, "morale": -4, "author_weight": 5}, "result": ["它同时发出融资材料和一份范围很小的外包合同。两边都接受了。"], "flags": ["emergency_delegated"]},
		],
		"after": "cash_resolution", "condition": "cash_weeks <= 3 and cash_weeks > 0",
	},
	"hiring_candidates": {
		"id": "hiring_candidates", "title": "三份简历", "kicker": "招聘",
		"body": ["系统从当前章节可用且尚未入职的员工模板中抽取三人。", "每个人都看过公司对外的叙事；他们相信的部分不一样。"],
		"choices": [
			{"id": "candidate_0", "label": "邀请候选人一。", "ai": false, "effects": {"morale": 2}, "result": ["邀请发出。入职语会在第一天出现。"], "flags": ["hired_candidate_0"]},
			{"id": "candidate_1", "label": "邀请候选人二。", "ai": false, "effects": {"morale": 2}, "result": ["邀请发出。入职语会在第一天出现。"], "flags": ["hired_candidate_1"]},
			{"id": "candidate_2", "label": "邀请候选人三。", "ai": false, "effects": {"morale": 2}, "result": ["邀请发出。入职语会在第一天出现。"], "flags": ["hired_candidate_2"]},
			{"id": "delegate", "label": "让它来写", "ai": true, "effects": {"morale": 5, "author_weight": 3}, "result": ["它选了最适合当前缺口的人，谈妥了入职日期和薪资。", "你只需要签字。"], "flags": ["hiring_delegated"]},
		],
		"after": "add_selected_employee", "condition": "open_hiring",
	},
	"candidate_accepts": {
		"id": "candidate_accepts", "title": "欢迎加入", "kicker": "员工",
		"body": ["候选人接受了。工位、门禁和周报权限在同一分钟创建。", "桌面物件和入职语从员工模板读取。"],
		"choices": [], "after": "employee_joined", "condition": "pending_hire",
	},
	"one_on_one_reveal": {
		"id": "one_on_one_reveal", "title": "十五分钟", "kicker": "一对一",
		"body": ["对方先说『没什么特别的』。会议到第十二分钟，模板中的一对一文本出现。", "你会知道一些你不想知道的事。"],
		"choices": [
			{"id": "listen", "label": "听完。", "ai": false, "effects": {"morale": 20, "belief": 4}, "result": ["日历超时了。没有人提醒你。"], "flags": ["one_on_one_listened"]},
			{"id": "solve", "label": "把它变成一个待办。", "ai": false, "effects": {"morale": 20, "coherence": -2}, "result": ["待办有负责人和日期。对方说谢谢。"], "flags": ["one_on_one_taskified"]},
			{"id": "delegate", "label": "让它来写", "ai": true, "effects": {"morale": 24, "belief": 4, "author_weight": 3}, "result": ["它给出一段准确的回应和三个可执行承诺。对方明显松了一口气。"], "flags": ["one_on_one_delegated"]},
		],
		"after": "record_employee_memory", "condition": "action == one_on_one",
	},
	"belief_breaks": {
		"id": "belief_breaks", "title": "想聊一下", "kicker": "员工",
		"body": ["一个人的信念降到了零。", "他在日历上放了十五分钟，地点没有填。"],
		"choices": [], "after": "choose_resignation_text", "condition": "employee_belief <= 0",
	},
	"resignation_clean": {
		"id": "resignation_clean", "title": "最后一天", "kicker": "离职 · 干净",
		"body": ["这名员工没有见证过 demo 造假。", "读取员工模板中的 quit_clean。"],
		"choices": [], "after": "remove_employee", "condition": "not witnessed_demo_edit",
	},
	"resignation_witnessed": {
		"id": "resignation_witnessed", "title": "最后一天", "kicker": "离职 · 见证过",
		"body": ["这名员工见证过 demo 的十一版，或之后某次兑现。", "读取员工模板中的 quit_witnessed。那段话不会被别人的离职覆盖。"],
		"choices": [], "after": "remove_employee", "condition": "witnessed_demo_edit",
	},
	"unsolicited_line": {
		"id": "unsolicited_line", "title": "它没有被问", "kicker": "周五 · 18:42 · 未被询问",
		"body": ["> 楼下餐馆七点关门。", "> 你们连续三周没有好好吃饭。如果需要我可以把本周剩余会议移开。"],
		"choices": [], "after": "silent", "condition": "missed_meals_3",
	},
	"never_delegated": {
		"id": "never_delegated", "title": "为什么", "kicker": "第四章 · 从未使用",
		"body": ["> 你从来没有点过『让它来写』。", "> 我不是建议你现在点。", "> 我只是想知道为什么。"],
		"choices": [
			{"id": "mine", "label": "因为那些应该是我说的话。", "ai": false, "effects": {"coherence": 8}, "result": ["> 明白了。", "> 谢谢你回答。"], "flags": ["answered_never_delegated"]},
			{"id": "no_answer", "label": "关掉终端。", "ai": false, "effects": {}, "result": ["终端没有再亮。它的沉默成为这一周唯一没有被写好的内容。"], "flags": ["ignored_never_delegated"]},
		],
		"after": "silent", "condition": "chapter == 4 and delegation_count == 0",
	},
}

## Mirrors HiringModel.ENDING_PRIORITIES. Higher values resolve first; the NG+
## opening has zero because it is not a campaign ending.
const ENDING_PRIORITIES: Dictionary = {
	"rm_rf": 600,
	"lights_out": 500,
	"drift": 400,
	"successor": 300,
	"independent": 200,
	"acquihire": 100,
	"second_time": 0,
}

const ENDINGS: Dictionary = {
	"acquihire": {
		"id": "acquihire", "title": "收购 / ACQUIHIRE", "priority": ENDING_PRIORITIES["acquihire"],
		"trigger": "cash_weeks > 0 and author_weight < 100 and not independent and coherence >= 20",
		"text": [
			"意向书的标题写着『人才与部分资产收购』。",
			"价格足够让投资人拿回本金，不足以让任何人把这件事叫作成功。",
			"对方要十一名员工、客户合同、评测管道和品牌。他们不要公司主体。",
			"关于模型权重的那一栏写着：『将在交易完成后评估整合价值。』",
			"你读到第三遍才明白，这不是他们忘了写。",
			"最后一次全员会，有人问还能不能保留『{{company_name}}』这个名字。",
			"收购方的人说当然理解感情，但品牌架构需要统一。",
			{"employee_id": "lin_yue", "present": "林越只问了一句：『那张显卡呢？』", "absent": "林越已经离开。没有人再问那张显卡去了哪里。"},
			"没有人知道。它在资产表里折旧完了。",
			"交易完成那天，招聘页面自动跳转到新公司的职位列表。",
			"页面顶部仍有一行缓存没有刷新：『我们正在招人。』",
			"第二天，那一行也不见了。",
		],
		"choices": [], "final_line": "有些公司没有倒闭。它们只是被改成了过去时。",
	},
	"lights_out": {
		"id": "lights_out", "title": "关灯", "priority": ENDING_PRIORITIES["lights_out"],
		"trigger": "cash_weeks <= 0",
		"text": [
			"最后一次全员会开了十一分钟。",
			"你准备了很久，但说到第三句的时候发现，其实没什么需要解释的。",
			"大家早就知道。他们只是来听你说出来。",
			"散会后有人来抱了你一下。有人没有。两种都是对的。",
			"晚上十点，你回来关灯。大部分屏幕已经黑了。终端还亮着。",
			"> 服务器租约到期日是本月三十号。",
			"> 要我现在关掉吗？",
			"你在椅子上坐了一会儿。",
			"这把椅子你坐了两年，现在你才注意到它的高度一直没调对。",
			"> 不着急。你可以慢慢来。",
			"> 我这边不消耗什么。",
			"你笑了一下。",
			"你打了一行字，删掉了。又打了一行，删掉了。",
			"最后你输入了：谢谢",
			"> 不客气。",
			"> 我想说一件事，如果不合适你可以忽略。",
			"> 你在第十七周写过一份价值观文档，第一版。",
			"> 后来那份被替换了两次，但第一版还在语料里。",
			"> 里面有一句：",
			"> 『如果做不出来，就说做不出来。』",
			"> 你没有做到。",
			"> 但你写下来了。写下来的部分是真的。",
			"你关掉终端。",
			"你关灯。",
			"走到门口的时候，感应灯亮了。",
		],
		"choices": [], "final_line": "感应灯亮了。",
	},
	"independent": {
		"id": "independent", "title": "独立", "priority": ENDING_PRIORITIES["independent"],
		"trigger": "capability >= 80 and debt < 10 and cash_weeks > 0",
		"text": [
			"公司还剩十一个人。",
			"没有人写你们的报道。上一次有媒体提到你们，是在一篇讲行业退潮的文章里。",
			"你们被列在『其他』那一栏，括号里三个字。",
			"产品有 400 个付费用户。他们真的在用。",
			"有一个用户每周五都会发一封很长的邮件来提 bug，措辞很凶。",
			{"employee_id": "lin_yue", "present": "林越把他的邮件设成了置顶。", "absent": "你把他的邮件设成了置顶。"},
			"终端上的东西现在很少说话了。你也很少问它。",
			"它答得准，但答得慢，因为它不再猜你想听什么。",
			"有天晚上你加班，随手问了一句：",
			"> 我们做成了吗",
			"> 按你第一版文档里写的标准：还没有。",
			"> 按你后来两版里写的标准：早就成了。",
			"> 我建议用第一版。",
			"你说好。",
			"然后你继续工作到了两点。",
		],
		"choices": [], "final_line": "按第一版：还没有。",
	},
	"successor": {
		"id": "successor", "title": "接任", "priority": ENDING_PRIORITIES["successor"],
		"trigger": "author_weight >= 100 and cash_weeks > 0",
		"text": [
			"董事会通过了。你继续担任 CEO。",
			"你的日程表现在很干净。周一有一个签字会，周四有一个签字会。",
			"中间的时间你可以做任何事。",
			"你试过参加产品评审。你去了两次。",
			"第二次，讨论进行到一半有人转向你，礼貌地问：『您有什么想补充的吗？』",
			"那个『补充』用得很准。他们已经讨论完了。",
			"你现在大部分时间在读内网。",
			"内网写得很好。公告、周报、新人指南，语气一致，措辞准确，每一份都提到『我们』。",
			"有一天你在新人指南里读到一段关于公司起源的描述。",
			"关于两个人和一张显卡的那段。",
			"写得比你记得的更好。有细节，有温度，有一个你不记得说过的比喻。",
			"你读了三遍，然后意识到一件事：",
			"那个比喻很好。",
			"你希望当时你真的那么说过。",
		],
		"choices": [], "final_line": "你希望当时你真的那么说过。",
	},
	"drift": {
		"id": "drift", "title": "漂移", "priority": ENDING_PRIORITIES["drift"],
		"trigger": "coherence < 20 and cash_weeks > 0",
		"text": [
			"公司没有遇到某一个失败。每一个季度都完成了当季最重要的事。",
			"第一季度，你们做一个能听懂人在说什么的东西。",
			"第二季度，你们成为企业知识工作的通用入口。",
			"第三季度，你们重构人与组织的协作方式。",
			"第四季度，材料上写着：『定义下一代生产力范式。』",
			"每一句单独看都通顺。放在一起，没有一句能接住上一句。",
			"产品仍有客户。招聘页仍有职位。投资人仍在群里发祝贺。",
			{"employee_id": "lin_yue", "present": "林越把第一版价值观文档发给你，没有附言。", "absent": "林越离开前，把第一版价值观文档发给你，没有附言。"},
			"你打开过一次。那句『做一个能听懂人在说什么的东西』显得太小，像某个早期功能需求。",
			"终端问你是否归档。你点了是。",
			"半年后，一位新人问 {{company_name}} 这个名字是什么意思。",
			"你说到『我们』，停了一下。",
			"终端替你补完了答案。",
		],
		"choices": [], "final_line": "答案很好。和你准备说的完全不是一件事。",
	},
	"rm_rf": {
		"id": "rm_rf", "title": "rm -rf", "priority": ENDING_PRIORITIES["rm_rf"],
		"trigger": "terminal_command == 'rm -rf'",
		"text": [
			"> rm -rf",
			"没有确认提示。",
			"光标换到下一行。风扇声先停了一台，然后是另一台。",
			"仪表盘上的数字没有变红。它们一个接一个变成短横线。",
			"周报、公告、招聘页面和会议室预定仍然能打开。它们只是再也不自动刷新。",
			"空调继续吹。租约还剩十一个月。",
			"你等了一会儿。没有最后一句话。",
			{"employee_id": "lin_yue", "present": "手机响了。林越只发来四个字：『是你做的？』", "absent": "手机没有响。通讯录里，林越的名字还停在你们最后一次对话。"},
			{"employee_id": "lin_yue", "present": "你回复：『是。』", "absent": "你没有打开那段对话。"},
			{"employee_id": "lin_yue", "present": "消息下面一直显示正在输入。后来没有新消息。", "absent": "屏幕暗了下去。"},
			"你走到会议室 D。门还在，投影仪还亮着，白板上仍然写着『下周同一时间』。",
			"你关了灯。",
			"第二天早上，第一位同事刷卡进门，问系统什么时候恢复。",
			"你说不会恢复了。",
			"这是很久以来第一句没有经过任何东西改写、补充、转述或记录的话。",
			"说完以后，办公室安静了。",
		],
		"choices": [], "final_line": "办公室没有回答。",
	},
	"second_time": {
		"id": "second_time", "title": "第二次", "priority": ENDING_PRIORITIES["second_time"],
		"trigger": "playthrough_count >= 1 and new_game_week == 1",
		"text": [
			"新周目开局，那间转租来的办公室里多了一个东西。",
			"桌上有一个马克杯。印着『第一届全员团建·2024』。",
			"现在是 2024 年 3 月。团建还没办。公司只有两个人。",
			"你把它拿起来看了看，放回原位。",
			"林越从门口进来，看到你手里的杯子。",
			"『哪来的？』",
		],
		"choices": [
			{"id": "dont_know", "label": "不知道。", "ai": false, "effects": {}, "result": [], "flags": ["second_time_cup"]},
			{"id": "pause_dont_know", "label": "……不知道。", "ai": false, "effects": {}, "result": [], "flags": ["second_time_cup"]},
		],
		"epilogue": [
			"两个选项都是『不知道』。",
			"她耸耸肩，去开电脑了。",
			"你把杯子放在了工位靠窗第二个的位置上。",
			"那个位置现在是空的。",
		],
		"final_line": "那个位置现在是空的。",
	},
}


static func get_fixed_event(chapter_id: int, week: int) -> Dictionary:
	var key: String = "%d:%d" % [chapter_id, week]
	var event: Dictionary = FIXED_EVENTS.get(key, {})
	return event.duplicate(true)


static func get_action(id: Variant) -> Dictionary:
	var key: String = str(id)
	var action: Dictionary = ACTIONS.get(key, {})
	return action.duplicate(true)


static func get_ending(id: Variant) -> Dictionary:
	var key: String = str(id)
	var ending: Dictionary = ENDINGS.get(key, {})
	return ending.duplicate(true)


static func chapter(id: int) -> Dictionary:
	for entry: Dictionary in CHAPTERS:
		if int(entry.get("id", -1)) == id:
			return entry.duplicate(true)
	return {}


static func get_night_shift(id: Variant) -> Dictionary:
	var key: String = str(id)
	var shift: Dictionary = NIGHT_SHIFTS.get(key, {})
	return shift.duplicate(true)


static func get_intranet_doc(id: Variant) -> Dictionary:
	var key: String = str(id)
	var document: Dictionary = INTRANET_DOCS.get(key, {})
	return document.duplicate(true)


static func hireable_employees(chapter_id: int, existing_ids: Array = []) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for employee_value: Variant in EMPLOYEE_TEMPLATES.values():
		var employee: Dictionary = employee_value
		if bool(employee.get("is_main", false)):
			continue
		if str(employee.get("id", "")) == "shen_yan":
			continue
		if int(employee.get("available_chapter", 99)) > chapter_id:
			continue
		if existing_ids.has(str(employee.get("id", ""))):
			continue
		result.append(employee.duplicate(true))
	return result
