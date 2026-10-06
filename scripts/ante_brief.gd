class_name AnteBrief
extends RefCounted
## What an ante is, in plain words (ante-arc spec, add-ante-intro-card): its name,
## target, reward and any special rule. Read-only text built from the tunables, so the
## intro card, the HUD chip and the shop's NEXT strip always agree with the rules.

var title: String
var target: int
var reward: String
var rule: String
var short_rule: String
var is_boss: bool
var is_risk: bool


static func for_ante(ante: int, ante_cfg: AnteConfig, shop_cfg: ShopConfig, throw_cfg: ThrowConfig) -> AnteBrief:
	var b := AnteBrief.new()
	var idx := clampi(ante - 1, 0, ante_cfg.targets.size() - 1)
	var name := ante_cfg.round_names[idx].to_upper() if idx < ante_cfg.round_names.size() else ""
	b.title = "ANTE %d · %s ROUND" % [ante, name]
	b.target = ante_cfg.targets[idx]
	b.is_boss = ante_cfg.boss_antes.has(ante)
	b.is_risk = ante_cfg.risk_antes.has(ante)
	b.reward = "Win: %dg + %dg per spare throw" % [shop_cfg.base_gold_per_ante, shop_cfg.gold_per_leftover_throw]
	if b.is_boss:
		var window := throw_cfg.lock_window_duration_s * ante_cfg.boss_window_scale
		b.rule = "Boss rule: lock windows halved (%.2f s)" % window
		b.short_rule = "½ WINDOWS"
	elif b.is_risk:
		b.rule = "Or skip this round for +%dg" % ante_cfg.skip_reward_gold
		b.short_rule = "SKIP +%dg" % ante_cfg.skip_reward_gold
	else:
		b.rule = "%d throws to beat the target" % ante_cfg.throws_per_round
	return b
