class_name LocationData
extends RefCounted

var id: String = ""
var name: String = ""
var unlocked: bool = false

func _init(p_id := "", p_name := "", p_unlocked := false) -> void:
	id = p_id
	name = p_name
	unlocked = p_unlocked
