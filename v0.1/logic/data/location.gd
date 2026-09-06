class_name LocationData
extends RefCounted

var id: String = ""
var name: String = ""
var parent_id: String = ""   # 父地点id（空=顶层地点）；配置数据，存档只存解锁状态
var unlocked: bool = false

func _init(p_id := "", p_name := "", p_unlocked := false) -> void:
	id = p_id
	name = p_name
	unlocked = p_unlocked
