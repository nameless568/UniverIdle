class_name DetailPanel
extends PanelContainer

var _selected_action := ""
var _built_key := ""

var _v: VBoxContainer
var _hero: TextureRect
var _title: Label
var _desc: Label
var _loot: HBoxContainer
var _cost_label: Label
var _xp_label: Label
var _start_btn: Button
var _run_box: VBoxContainer
var _progress: ProgressBar
var _remain_label: Label
var _stop_btn: Button
var _confirm: ConfirmationDialog
var _empty_label: Label

func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.BG, 0))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_v = VBoxContainer.new()
	_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_v.add_theme_constant_override("separation", 10)
	scroll.add_child(_v)

	_empty_label = Label.new()
	_empty_label.text = "点击左侧地图节点，查看详情。"
	_empty_label.add_theme_color_override("font_color", UiTheme.INK_DIM)
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_v.add_child(_empty_label)

	_hero = TextureRect.new()
	_hero.custom_minimum_size = Vector2(0, 210)
	_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_v.add_child(_hero)

	_title = Label.new()
	_title.add_theme_color_override("font_color", UiTheme.INK)
	_title.add_theme_font_size_override("font_size", 26)
	_v.add_child(_title)

	_desc = Label.new()
	_desc.add_theme_color_override("font_color", UiTheme.INK_DIM)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_v.add_child(_desc)

	_loot = HBoxContainer.new()
	_loot.add_theme_constant_override("separation", 6)
	_v.add_child(_loot)

	_cost_label = Label.new()
	_cost_label.add_theme_color_override("font_color", UiTheme.INK_DIM)
	_cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_v.add_child(_cost_label)

	_xp_label = Label.new()
	_xp_label.add_theme_color_override("font_color", UiTheme.INK_DIM)
	_v.add_child(_xp_label)

	_start_btn = Button.new()
	_start_btn.custom_minimum_size = Vector2(0, 54)
	UiTheme.style_button(_start_btn, UiTheme.PANEL_DARK)
	_start_btn.pressed.connect(_on_start)
	_v.add_child(_start_btn)

	# 运行面板（选中动作==当前动作时替换开始按钮）
	_run_box = VBoxContainer.new()
	_run_box.add_theme_constant_override("separation", 6)
	_v.add_child(_run_box)

	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = 1.0
	_progress.custom_minimum_size = Vector2(0, 14)
	_progress.show_percentage = false
	UiTheme.progress_style(_progress)
	_run_box.add_child(_progress)

	_remain_label = Label.new()
	_remain_label.add_theme_color_override("font_color", UiTheme.INK_DIM)
	_run_box.add_child(_remain_label)

	_stop_btn = Button.new()
	_stop_btn.text = "停止"
	UiTheme.style_button(_stop_btn, UiTheme.ACCENT.darkened(0.3))
	_stop_btn.pressed.connect(func(): _confirm.popup_centered())
	_run_box.add_child(_stop_btn)

	_confirm = ConfirmationDialog.new()
	_confirm.dialog_text = "确定停止当前挂机？"
	_confirm.ok_button_text = "停止"
	_confirm.cancel_button_text = "继续"
	_confirm.confirmed.connect(_do_stop)
	add_child(_confirm)

func select_action(action_id: String) -> void:
	_selected_action = action_id
	_built_key = ""

func _action() -> ActionDef:
	if _selected_action == "":
		return null
	return GameState.action_by_id(_selected_action)

func _title_text(action: ActionDef) -> String:
	var loc_name := str(GameState.config_locations.get(action.location_id, ""))
	var parent: String = GameState.config_location_parents.get(action.location_id, "")
	if parent != "":
		var parent_name := str(GameState.config_locations.get(parent, ""))
		return "%s · %s" % [parent_name, loc_name]
	return loc_name

func _key() -> String:
	if GameState.save == null:
		return "nosave"
	return _selected_action + "|" + GameState.save.character.current_action_id

func refresh() -> void:
	if GameState.save == null:
		return
	if _key() != _built_key:
		_rebuild()
	var action := _action()
	if action == null:
		return
	var character: CharacterData = GameState.save.character
	if character.current_action_id == action.id:
		_progress.value = character.progress
		_remain_label.text = "剩余 %.1f 秒" % (action.duration * (1.0 - character.progress))

func _rebuild() -> void:
	_built_key = _key()
	var action := _action()
	var has := action != null
	_empty_label.visible = not has
	_hero.visible = has
	_title.visible = has
	_desc.visible = has
	_loot.visible = has
	_cost_label.visible = has
	_xp_label.visible = has
	_start_btn.visible = has
	_run_box.visible = false
	if not has:
		return

	_hero.texture = UiTheme.load_texture(action.icon)
	_title.text = _title_text(action)
	_desc.text = action.description

	for c in _loot.get_children():
		c.queue_free()
	var costs := []
	for e in action.entries:
		if e.is_consumption():
			costs.append("消耗 %s×%d" % [GameState.item_name(e.item_id), abs(e.min_amount)])
			continue
		var slot := TextureRect.new()
		slot.texture = UiTheme.load_texture(GameState.config_items[e.item_id].icon)
		slot.custom_minimum_size = Vector2(44, 44)
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.tooltip_text = "%s %.0f%%（%d~%d）" % [GameState.item_name(e.item_id), e.chance * 100.0, e.min_amount, e.max_amount]
		_loot.add_child(slot)
	_cost_label.text = "、".join(costs)
	_cost_label.visible = costs.size() > 0

	var xp_parts := []
	for skill in action.xp_rewards:
		xp_parts.append("%s经验 +%d" % [GameState.skill_name(str(skill)), int(action.xp_rewards[skill])])
	_xp_label.text = "、".join(xp_parts)
	_xp_label.visible = xp_parts.size() > 0

	var verb := "开始"
	for skill in action.xp_rewards:
		verb = GameState.skill_name(str(skill))
		break
	_start_btn.text = verb

	if GameState.save.character.current_action_id == action.id:
		_start_btn.visible = false
		_run_box.visible = true

func _on_start() -> void:
	var action := _action()
	if action == null:
		return
	GameState.append_operation(Operation.TYPE_START_ACTION, action.id)
	GameState.update(Time.get_unix_time_from_system())

func _do_stop() -> void:
	GameState.append_operation(Operation.TYPE_STOP_ACTION, "")
	GameState.update(Time.get_unix_time_from_system())
