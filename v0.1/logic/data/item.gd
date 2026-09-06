class_name ItemDef
extends RefCounted

var id: String = ""
var name: String = ""
var category: String = ""
var icon: String = ""
var description: String = ""

func _init(p_id := "", p_name := "", p_category := "", p_icon := "", p_description := "") -> void:
	id = p_id
	name = p_name
	category = p_category
	icon = p_icon
	description = p_description
