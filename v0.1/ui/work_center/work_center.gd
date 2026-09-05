class_name WorkCenterView
extends PanelContainer

var _title: Label
var _cards: VBoxContainer
var _run_label: Label
var _progress: ProgressBar
var _remain_label: Label
var _stop_btn: Button
var _detail: Label
var _confirm: ConfirmationDialog
var _current_location := ""
var _selected_action := ""
var _cards_key_built := ""

func _ready() -> void:
	var v := VBoxContainer.new()
	add_child(v)

	_title = Label.new()
	v.add_child(_title)

	_cards = VBoxContainer.new()
	v.add_child(_cards)

	_run_label = Label.new()
	v.add_child(_run_label)

	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = 1.0
	v.add_child(_progress)

	_remain_label = Label.new()
	v.add_child(_remain_label)

	_stop_btn = Button.new()
	_stop_btn.text = "停止挂机"
	_stop_btn.pressed.connect(_on_stop)
	v.add_child(_stop_btn)

	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_detail)

	_confirm = ConfirmationDialog.new()
	_confirm.dialog_text = "确定停止当前挂机？"
	_confirm.ok_button_text = "停止"
	_confirm.confirmed.connect(_do_stop)
	add_child(_confirm)

func set_location(loc_id: String) -> void:
	_current_location = loc_id
	_rebuild_cards()

func _cards_key() -> String:
	if GameState.save == null:
		return "nosave|" + _current_location
	var parts := [_current_location]
	for action_id in GameState.environment.actions:
		if GameState.save.character.unlocked_actions.has(action_id):
			parts.append(action_id)
	return "|".join(parts)

func _rebuild_cards() -> void:
	_cards_key_built = _cards_key()
	for c in _cards.get_children():
		c.queue_free()
	if GameState.save == null:
		return
	var loc_name := ""
	if GameState.environment.locations.has(_current_location):
		loc_name = GameState.environment.locations[_current_location].name
	_title.text = "地点：%s" % loc_name

	# 本地点及其子地点内的动作；子地点动作带小标题分组
	var scope := [_current_location]
	for cid in GameState.environment.locations:
		var cloc: LocationData = GameState.environment.locations[cid]
		if cloc.parent_id == _current_location:
			scope.append(cid)

	for scope_id in scope:
		var group_started := false
		for action_id in GameState.environment.actions:
			var action: ActionDef = GameState.environment.actions[action_id]
			if action.location_id != scope_id:
				continue
			if not group_started and scope_id != _current_location:
				var header := Label.new()
				header.text = GameState.environment.locations[scope_id].name
				header.add_theme_color_override("font_color", Color(0.62, 0.4, 0.3))
				_cards.add_child(header)
			group_started = true
			var btn := Button.new()
			var unlocked := GameState.save.character.unlocked_actions.has(action_id)
			btn.text = action.name if unlocked else action.name + "（需 " + _unlock_text(action) + "）"
			btn.disabled = not unlocked
			btn.pressed.connect(_on_card_pressed.bind(action_id))
			_cards.add_child(btn)

func _unlock_text(action: ActionDef) -> String:
	var parts := []
	for skill in action.unlock_requirements:
		parts.append("%s Lv.%d" % [skill, int(action.unlock_requirements[skill])])
	return "、".join(parts)

func _on_card_pressed(action_id: String) -> void:
	_selected_action = action_id
	GameState.append_operation(Operation.TYPE_START_ACTION, action_id)
	GameState.update(Time.get_unix_time_from_system())

func _on_stop() -> void:
	_confirm.popup_centered()

func _do_stop() -> void:
	GameState.append_operation(Operation.TYPE_STOP_ACTION, "")
	GameState.update(Time.get_unix_time_from_system())

func _preview(action: ActionDef) -> String:
	var lines := []
	for e in action.entries:
		if e.is_consumption():
			lines.append("消耗 %s×%d" % [GameState.item_name(e.item_id), abs(e.min_amount)])
		else:
			lines.append("掉落 %s %.0f%%（%d~%d）" % [GameState.item_name(e.item_id), e.chance * 100.0, e.min_amount, e.max_amount])
	for skill in action.xp_rewards:
		lines.append("经验 %s +%d" % [skill, int(action.xp_rewards[skill])])
	return "\n".join(lines)

func refresh() -> void:
	if GameState.save == null:
		return
	if _cards_key() != _cards_key_built:
		_rebuild_cards()
	var character: CharacterData = GameState.save.character
	var running := ""
	if character.current_action_id != "" and GameState.environment.actions.has(character.current_action_id):
		running = character.current_action_id

	if running != "":
		var action: ActionDef = GameState.environment.actions[running]
		_run_label.text = "进行中：%s" % action.name
		_progress.value = character.progress
		_remain_label.text = "剩余 %.1f 秒" % (action.duration * (1.0 - character.progress))
		_stop_btn.disabled = false
		_detail.text = action.description + "\n" + _preview(action)
	else:
		_run_label.text = "闲置"
		_progress.value = 0.0
		_remain_label.text = ""
		_stop_btn.disabled = true
		if _selected_action != "" and GameState.environment.actions.has(_selected_action):
			var action: ActionDef = GameState.environment.actions[_selected_action]
			_detail.text = action.description + "\n" + _preview(action)
		else:
			_detail.text = "点击动作卡开始挂机。"
