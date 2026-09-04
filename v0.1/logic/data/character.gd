class_name CharacterData
extends RefCounted

var id: String = "p_default"
var name: String = "旅行者"
var operations: Array = []             # of Operation（不落盘）
var inventory: Inventory = null
var current_action_id: String = ""     # 空=闲置
var progress: float = 0.0              # 0..1
var skill_xp: Dictionary = {}          # 技能名称 -> 整数经验
var unlocked_actions: Dictionary = {}  # 动作id -> true（集合）

func _init() -> void:
	inventory = Inventory.new()
