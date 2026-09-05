class_name WelcomeView
extends Control

signal game_started

var _list: ItemList
var _continue_btn: Button
var _delete_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var v := VBoxContainer.new()
	v.anchor_left = 0.3
	v.anchor_right = 0.7
	v.anchor_top = 0.15
	v.anchor_bottom = 0.85
	v.offset_left = 0
	v.offset_right = 0
	v.offset_top = 0
	v.offset_bottom = 0
	add_child(v)

	var title := Label.new()
	title.text = "UniverIdle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_list)

	var row := HBoxContainer.new()
	v.add_child(row)

	_continue_btn = Button.new()
	_continue_btn.text = "继续"
	_continue_btn.pressed.connect(_on_continue)
	row.add_child(_continue_btn)

	var new_btn := Button.new()
	new_btn.text = "新建游戏"
	new_btn.pressed.connect(_on_new)
	row.add_child(new_btn)

	_delete_btn = Button.new()
	_delete_btn.text = "删除"
	_delete_btn.pressed.connect(_on_delete)
	row.add_child(_delete_btn)

	refresh()

func refresh() -> void:
	_list.clear()
	for info in GameState.list_saves():
		var idx := _list.add_item(info["name"])
		_list.set_item_metadata(idx, info["path"])
	_continue_btn.disabled = (_list.item_count == 0)
	_delete_btn.disabled = (_list.item_count == 0)

func _selected_path() -> String:
	var sel := _list.get_selected_items()
	if sel.is_empty():
		return ""
	return str(_list.get_item_metadata(sel[0]))

func _on_continue() -> void:
	var path := _selected_path()
	if path == "":
		return
	if GameState.load_game(path):
		game_started.emit()

func _on_new() -> void:
	GameState.new_game()
	GameState.save_new_slot()
	game_started.emit()

func _on_delete() -> void:
	var path := _selected_path()
	if path == "":
		return
	GameState.delete_save(path)
	refresh()
