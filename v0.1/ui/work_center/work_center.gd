class_name WorkCenterView
extends ScrollContainer

signal action_selected(action_id: String)

const CARD_W := 280

var _box: VBoxContainer
var _selected_action := ""
var _built_key := ""

func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 16)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_box)

func selected_action() -> String:
	return _selected_action

# ---------- 结构 ----------

func _key() -> String:
	if GameState.save == null:
		return "nosave"
	var character: CharacterData = GameState.save.character
	var parts := [_selected_action, character.current_action_id]
	for loc_id in GameState.environment.locations:
		var loc: LocationData = GameState.environment.locations[loc_id]
		parts.append(loc_id + "=" + str(loc.unlocked))
	for action_id in GameState.environment.actions:
		if character.unlocked_actions.has(action_id):
			parts.append(action_id)
	return "|".join(parts)

func _is_unlocked(action_id: String) -> bool:
	return GameState.save != null and GameState.save.character.unlocked_actions.has(action_id)

# 动作的顶层地点id（无父即自身）
func _top_location_id(action: ActionDef) -> String:
	var parent: String = GameState.config_location_parents.get(action.location_id, "")
	return parent if parent != "" else action.location_id

func _unlock_level(action: ActionDef) -> int:
	var lv := 1
	for skill in action.unlock_requirements:
		lv = int(action.unlock_requirements[skill])
		break
	return lv

func _unlock_text(action: ActionDef) -> String:
	var parts := []
	for skill in action.unlock_requirements:
		parts.append("%s等级达到 %d" % [GameState.skill_name(str(skill)), int(action.unlock_requirements[skill])])
	return "、".join(parts) + " 解锁"

func _rebuild() -> void:
	_built_key = _key()
	for c in _box.get_children():
		c.queue_free()
	_sections.clear()
	if GameState.save == null:
		return

	# 按顶层地点分节；锁定动作以剪影卡并入自己所属的地区节
	for loc_id in GameState.environment.locations:
		var loc: LocationData = GameState.environment.locations[loc_id]
		if loc.parent_id != "":
			continue
		var unlocked := []
		var locked := []
		for action_id in GameState.environment.actions:
			var action: ActionDef = GameState.environment.actions[action_id]
			if _top_location_id(action) != loc_id:
				continue
			if _is_unlocked(action_id):
				unlocked.append(action)
			else:
				locked.append(action)
		if unlocked.is_empty():
			continue   # 未解锁地区整体不显示；锁定卡留在已解锁地区的节内
		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 12)
		section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_box.add_child(section)
		_sections[loc_id] = section
		section.add_child(_make_banner(loc))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		section.add_child(grid)
		for action in unlocked:
			grid.add_child(_make_card(action))
		for action in locked:
			grid.add_child(_make_locked_card(action))

# 点击左栏技能：滚动到该技能第一个已显示的地区节（无匹配或无显示中地区则无操作）
func scroll_to_skill(skill_id: String) -> void:
	for loc_id in GameState.config_locations:
		if GameState.config_location_parents.get(loc_id, "") != "":
			continue
		if not _sections.has(loc_id):
			continue
		for action_id in GameState.environment.actions:
			var action: ActionDef = GameState.environment.actions[action_id]
			if _top_location_id(action) != loc_id:
				continue
			if action.xp_rewards.has(skill_id) or action.unlock_requirements.has(skill_id):
				ensure_control_visible(_sections[loc_id])
				return

var _sections: Dictionary = {}   # 顶层地点id -> 节容器（重建时刷新）

func _make_locked_card(action: ActionDef) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_W, 0)
	card.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.PANEL_DARK))
	var v := VBoxContainer.new()
	card.add_child(v)

	var thumb := TextureRect.new()
	thumb.texture = UiTheme.load_texture(action.icon)
	thumb.custom_minimum_size = Vector2(CARD_W, CARD_W / 2)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.modulate = Color(0, 0, 0)   # 剪影
	v.add_child(thumb)

	var label := Label.new()
	label.text = _unlock_text(action)
	label.add_theme_color_override("font_color", UiTheme.INK_DIM)
	v.add_child(label)
	return card

func _make_banner(loc: LocationData) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 160)

	var banner := TextureRect.new()
	banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.texture = UiTheme.load_texture(GameState.config_location_banners.get(loc.id, ""))
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if not loc.unlocked:
		banner.modulate = Color(0.35, 0.35, 0.35)
	wrap.add_child(banner)

	# 底部压暗条 + 地点名
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.anchor_left = 0.0
	shade.anchor_right = 1.0
	shade.anchor_top = 1.0
	shade.anchor_bottom = 1.0
	shade.offset_left = 0
	shade.offset_right = 0
	shade.offset_top = -48
	shade.offset_bottom = 0
	wrap.add_child(shade)

	var label := Label.new()
	label.text = loc.name if loc.unlocked else loc.name + "（未解锁）"
	label.add_theme_color_override("font_color", UiTheme.INK)
	label.add_theme_font_size_override("font_size", 28)
	label.anchor_top = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = 12
	label.offset_top = -46
	wrap.add_child(label)
	return wrap

func _make_card(action: ActionDef) -> Control:
	var running := GameState.save.character.current_action_id == action.id
	var selected := _selected_action == action.id

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_W, 0)
	var border := Color(0, 0, 0, 0)
	if running or selected:
		border = UiTheme.TEAL if running else UiTheme.ACCENT
	card.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.PANEL, 6, border))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)

	var thumb := TextureRect.new()
	thumb.texture = UiTheme.load_texture(action.icon)
	thumb.custom_minimum_size = Vector2(CARD_W, CARD_W / 2)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	v.add_child(thumb)

	var name_label := Label.new()
	# 直属顶层地点的动作显示动作名；子地点动作显示子地点名
	var parent_id: String = GameState.config_location_parents.get(action.location_id, "")
	name_label.text = action.name if parent_id == "" else str(GameState.config_locations.get(action.location_id, action.name))
	name_label.add_theme_color_override("font_color", UiTheme.INK)
	v.add_child(name_label)

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	v.add_child(foot)

	var check := Label.new()
	check.text = "☑" if running else "☐"
	check.add_theme_color_override("font_color", UiTheme.TEAL if running else UiTheme.INK_DIM)
	foot.add_child(check)

	var lv := Label.new()
	lv.text = "Lv.%d" % _unlock_level(action)
	lv.add_theme_color_override("font_color", UiTheme.INK_DIM)
	foot.add_child(lv)

	var click := Button.new()
	click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	click.flat = true
	click.pressed.connect(_on_card_pressed.bind(action.id))
	card.add_child(click)
	return card

func _on_card_pressed(action_id: String) -> void:
	_selected_action = action_id
	action_selected.emit(action_id)
	_rebuild()

func refresh() -> void:
	if GameState.save == null:
		return
	if _key() != _built_key:
		_rebuild()
