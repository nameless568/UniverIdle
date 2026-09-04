class_name ActionDef
extends RefCounted

# 物品消耗与获取条目：消耗为负值且 min==max、概率 1；获取为独立绝对概率。
class Entry:
	extends RefCounted

	var item_id: String = ""
	var chance: float = 1.0
	var min_amount: int = 0
	var max_amount: int = 0

	func _init(p_item_id := "", p_chance := 1.0, p_min := 0, p_max := 0) -> void:
		item_id = p_item_id
		chance = p_chance
		min_amount = p_min
		max_amount = p_max

	func is_consumption() -> bool:
		return chance >= 1.0 and min_amount == max_amount and min_amount < 0

var id: String = ""
var name: String = ""
var location_id: String = ""
var unlock_requirements: Dictionary = {}   # 技能名称 -> 所需技能等级(int)
var entries: Array = []                      # of ActionDef.Entry
var duration: float = 1.0
var xp_rewards: Dictionary = {}              # 技能名称 -> 整数经验
var description: String = ""
var icon: String = ""
