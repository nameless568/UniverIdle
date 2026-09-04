class_name Operation
extends RefCounted

const TYPE_START_ACTION := "start_action"
const TYPE_STOP_ACTION := "stop_action"
const TYPE_SET_NAME := "set_name"
const TYPE_BUY_SLOTS := "buy_slots"

var type: String = ""
var param: String = ""

func _init(p_type := "", p_param := "") -> void:
	type = p_type
	param = p_param
