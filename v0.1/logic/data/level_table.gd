class_name LevelTable
extends RefCounted

var skill_name: String = ""
var thresholds: Array = []   # 累计总经验（第1项=升到2级所需总经验，严格递增）
var max_level: int = 99

func _init(p_name := "", p_thresholds := [], p_max := 99) -> void:
	skill_name = p_name
	thresholds = p_thresholds
	max_level = p_max

# 技能等级 = 满足表内多少项 + 1，封顶最大等级。
func level_for_xp(xp: int) -> int:
	var level := 1
	for t in thresholds:
		if xp >= int(t):
			level += 1
		else:
			break
	return mini(level, max_level)
