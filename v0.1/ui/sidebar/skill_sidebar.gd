class_name SkillSidebar
extends PanelContainer

signal skill_selected(skill_id: String)

var _box: VBoxContainer
var _rows: Array = []   # [{"id": 技能id, "level": Label, "bar": ProgressBar}]
var _built := false

func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.BG, 0))
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	add_child(_box)

# 结构来自配置，启动后不变；只建一次，逐 tick 只刷数值
func refresh() -> void:
	if GameState.save == null:
		return
	if not _built:
		_build()
	_built = true
	var character: CharacterData = GameState.save.character
	for row in _rows:
		var skill: String = row["id"]
		var xp := int(character.skill_xp.get(skill, 0))
		var table: LevelTable = GameState.get_level_table(skill)
		var level := table.level_for_xp(xp)
		row["level"].text = "Lv.%d" % level
		# 本级起点与下一级阈值
		var start := 0
		if level >= 2 and level - 2 < table.thresholds.size():
			start = int(table.thresholds[level - 2])
		var next := -1
		if level - 1 < table.thresholds.size():
			next = int(table.thresholds[level - 1])
		if level >= table.max_level or next < 0 or next <= start:
			row["bar"].value = 1.0
			row["bar"].tooltip_text = "已满级"
		else:
			row["bar"].value = clampf(float(xp - start) / float(next - start), 0.0, 1.0)
			row["bar"].tooltip_text = "%d / %d 经验" % [xp, next]

func _build() -> void:
	for c in _box.get_children():
		c.queue_free()
	_rows.clear()
	for s in GameState.config_skills:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)

		var head := HBoxContainer.new()
		head.add_theme_constant_override("separation", 8)
		row.add_child(head)

		var block := ColorRect.new()
		block.color = Color(str(s["color"]))
		block.custom_minimum_size = Vector2(34, 34)
		head.add_child(block)

		var name_label := Label.new()
		name_label.text = str(s["name"])
		name_label.add_theme_color_override("font_color", UiTheme.INK)
		head.add_child(name_label)

		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(spacer)

		var level_label := Label.new()
		level_label.add_theme_color_override("font_color", UiTheme.INK_DIM)
		head.add_child(level_label)

		var bar := ProgressBar.new()
		bar.min_value = 0.0
		bar.max_value = 1.0
		bar.custom_minimum_size = Vector2(0, 10)
		bar.show_percentage = false
		UiTheme.progress_style(bar, Color(str(s["color"])))
		row.add_child(bar)

		# 行内容 + 覆盖层按钮（最上层接收点击，与工作卡同模式）
		var wrap := PanelContainer.new()
		var empty := StyleBoxEmpty.new()
		wrap.add_theme_stylebox_override("panel", empty)
		wrap.add_child(row)

		var btn := Button.new()
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0, 0, 0, 0)
		hover.border_color = UiTheme.ACCENT
		hover.set_border_width_all(2)
		hover.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("hover", hover)
		var pressed_style := hover.duplicate()
		pressed_style.border_color = UiTheme.TEAL
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.pressed.connect(func(): skill_selected.emit(str(s["id"])))
		wrap.add_child(btn)

		_box.add_child(wrap)
		_rows.append({"id": str(s["id"]), "level": level_label, "bar": bar})
