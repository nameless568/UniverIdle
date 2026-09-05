class_name TopBar
extends PanelContainer

signal open_inventory
signal open_character
signal back_to_welcome

var gold_label: Label
var name_label: Label

func _ready() -> void:
	var h := HBoxContainer.new()
	add_child(h)

	gold_label = Label.new()
	h.add_child(gold_label)

	name_label = Label.new()
	h.add_child(name_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(spacer)

	var inv_btn := Button.new()
	inv_btn.text = "背包"
	inv_btn.pressed.connect(func(): open_inventory.emit())
	h.add_child(inv_btn)

	var char_btn := Button.new()
	char_btn.text = "角色"
	char_btn.pressed.connect(func(): open_character.emit())
	h.add_child(char_btn)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.pressed.connect(func(): back_to_welcome.emit())
	h.add_child(back_btn)

func refresh() -> void:
	if GameState.save == null:
		return
	gold_label.text = "金币 %d" % GameState.save.character.inventory.gold()
	name_label.text = GameState.save.character.name
