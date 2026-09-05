class_name InventoryView
extends Control

signal closed

var _cap_label: Label
var _grid: GridContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.4)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.3
	panel.anchor_right = 0.7
	panel.anchor_top = 0.2
	panel.anchor_bottom = 0.8
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = 0
	panel.offset_bottom = 0
	add_child(panel)

	var v := VBoxContainer.new()
	panel.add_child(v)

	_cap_label = Label.new()
	v.add_child(_cap_label)

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_grid)

	var buy := Button.new()
	buy.text = "购买背包格（+1）"
	buy.pressed.connect(_on_buy)
	v.add_child(buy)

	var close := Button.new()
	close.text = "关闭"
	close.pressed.connect(func(): closed.emit())
	v.add_child(close)

func refresh() -> void:
	if GameState.save == null:
		return
	var inv: Inventory = GameState.save.character.inventory
	_cap_label.text = "背包 %d/%d  金币 %d" % [inv.occupied_slots(), inv.capacity, inv.gold()]
	for c in _grid.get_children():
		c.queue_free()
	for item_id in inv.items:
		if int(inv.items[item_id]) <= 0:
			continue
		var label := Label.new()
		label.text = "%s×%d" % [GameState.item_name(item_id), int(inv.items[item_id])]
		_grid.add_child(label)

func _on_buy() -> void:
	GameState.append_operation(Operation.TYPE_BUY_SLOTS, "1")
	GameState.update(Time.get_unix_time_from_system())
	refresh()
