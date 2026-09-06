extends Node

const SAVE_DIR := "user://saves"
const CONFIG_DIR := "res://config/"
const TEMPLATE_PATH := "res://ui/save_template/template.json"

class SaveData:
	var version: int = 1
	var character: CharacterData = null
	var last_update_utc: float = 0.0

	func _init() -> void:
		character = CharacterData.new()

var environment: EnvironmentData = EnvironmentData.new()
var config_items: Dictionary = {}          # id -> ItemDef
var config_actions: Dictionary = {}        # id -> ActionDef
var config_locations: Dictionary = {}      # id -> 名称
var config_location_parents: Dictionary = {}  # id -> 父地点id（空=顶层地点）
var config_location_banners: Dictionary = {}  # 顶层地点id -> 横幅图路径（可选）
var config_skills: Array = []                 # 保序：[{"id","name","color"}]
var config_level_tables: Dictionary = {}   # 技能名称 -> LevelTable
var config_bag: Dictionary = {"free_slots": 10, "base": 15, "increment": 8}

var save: SaveData = null
var current_save_path: String = ""
var config_ok: bool = false
var _debug_rewind := 0.0   # 调试步进：待回拨的秒数（不落盘，随消费清零）

func _ready() -> void:
	config_ok = _load_config()

# ---------- 查询辅助 ----------

func get_level_table(skill: String) -> LevelTable:
	if config_level_tables.has(skill):
		return config_level_tables[skill]
	if config_level_tables.has("default"):
		return config_level_tables["default"]
	return LevelTable.new("default", [], 99)

func item_name(item_id: String) -> String:
	if config_items.has(item_id):
		return config_items[item_id].name
	return item_id

func action_by_id(action_id: String) -> ActionDef:
	if environment.actions.has(action_id):
		return environment.actions[action_id]
	return null

# ---------- 配置加载 ----------

func _read_json(path: String):
	if not FileAccess.file_exists(path):
		push_error("配置缺失: " + path)
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("无法打开配置: " + path)
		return null
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if data == null:
		push_error("配置解析失败: " + path)
		return null
	return data

func _load_config() -> bool:
	var ok := true
	ok = _load_items(_read_json(CONFIG_DIR + "items.json")) and ok
	ok = _load_locations(_read_json(CONFIG_DIR + "locations.json")) and ok
	ok = _load_skills(_read_json(CONFIG_DIR + "skills.json")) and ok
	ok = _load_level_tables(_read_json(CONFIG_DIR + "level_tables.json")) and ok
	ok = _load_actions(_read_json(CONFIG_DIR + "actions.json")) and ok
	ok = _load_bag(_read_json(CONFIG_DIR + "bag.json")) and ok
	if ok:
		environment.items = config_items
		environment.actions = config_actions
	return ok

func _load_items(data) -> bool:
	if data == null or not data.has("items"):
		push_error("items.json 缺少 items")
		return false
	var seen := {}
	for row in data["items"]:
		var id := str(row.get("id", ""))
		if id == "" or not id.begins_with("i_"):
			push_error("物品 id 非法: " + id)
			return false
		if seen.has(id):
			push_error("物品 id 重复: " + id)
			return false
		seen[id] = true
		config_items[id] = ItemDef.new(
			id,
			str(row.get("name", "")),
			str(row.get("category", "")),
			str(row.get("icon", "")),
			str(row.get("description", "")))
	return true

func _load_locations(data) -> bool:
	if data == null or not data.has("locations"):
		push_error("locations.json 缺少 locations")
		return false
	config_locations.clear()
	config_location_parents.clear()
	config_location_banners.clear()
	var seen := {}
	for row in data["locations"]:
		var id := str(row.get("id", ""))
		if id == "" or seen.has(id):
			push_error("地点 id 非法或重复: " + id)
			return false
		seen[id] = true
		config_locations[id] = str(row.get("name", ""))
		config_location_parents[id] = str(row.get("parent", ""))
		config_location_banners[id] = str(row.get("banner", ""))
	for id in config_location_parents:
		var parent: String = config_location_parents[id]
		if parent == "":
			continue
		if not seen.has(parent):
			push_error("地点 %s 的父地点不存在: %s" % [id, parent])
			return false
		if config_location_parents.get(parent, "") != "":
			push_error("只支持一层地点层级: 地点 %s 的父地点 %s 自身也是子地点" % [id, parent])
			return false
	return true

func _load_skills(data) -> bool:
	if data == null or not data.has("skills"):
		push_error("skills.json 缺少 skills")
		return false
	config_skills.clear()
	var seen := {}
	for row in data["skills"]:
		var id := str(row.get("id", ""))
		if id == "" or seen.has(id):
			push_error("技能 id 非法或重复: " + id)
			return false
		seen[id] = true
		config_skills.append({
			"id": id,
			"name": str(row.get("name", id)),
			"color": str(row.get("color", "#72a898")),
		})
	return true

# 技能中文名（无配置时回落为 id）
func skill_name(skill_id: String) -> String:
	for s in config_skills:
		if s["id"] == skill_id:
			return s["name"]
	return skill_id

func _load_level_tables(data) -> bool:
	if data == null or not data.has("tables"):
		push_error("level_tables.json 缺少 tables")
		return false
	for row in data["tables"]:
		var skill := str(row.get("skill", ""))
		if skill == "":
			push_error("等级表缺少 skill")
			return false
		var thresholds = row.get("thresholds", [])
		var prev := -1
		for t in thresholds:
			var v := int(t)
			if v <= prev:
				push_error("等级表 %s 未严格递增" % skill)
				return false
			prev = v
		config_level_tables[skill] = LevelTable.new(skill, thresholds, int(row.get("max", 99)))
	return true

func _load_actions(data) -> bool:
	if data == null or not data.has("actions"):
		push_error("actions.json 缺少 actions")
		return false
	var seen := {}
	for row in data["actions"]:
		var id := str(row.get("id", ""))
		if id == "" or not id.begins_with("a_"):
			push_error("动作 id 非法: " + id)
			return false
		if seen.has(id):
			push_error("动作 id 重复: " + id)
			return false
		seen[id] = true

		var action := ActionDef.new()
		action.id = id
		action.name = str(row.get("name", ""))
		action.location_id = str(row.get("location", ""))
		action.description = str(row.get("description", ""))
		action.icon = str(row.get("icon", ""))
		action.duration = float(row.get("duration", 1.0))
		if action.duration <= 0.0:
			push_error("动作耗时必须为正: " + id)
			return false

		var unlock = row.get("unlock", {})
		for skill in unlock:
			action.unlock_requirements[str(skill)] = int(unlock[skill])
			if not config_level_tables.has(str(skill)) and not config_level_tables.has("default"):
				push_error("动作 %s 的解锁技能 %s 无等级表" % [id, str(skill)])
				return false

		var xp = row.get("xp", {})
		for skill in xp:
			action.xp_rewards[str(skill)] = int(xp[skill])

		var entries = row.get("entries", [])
		for e in entries:
			var item_id := str(e.get("item", ""))
			if not config_items.has(item_id):
				push_error("动作 %s 引用了不存在的物品 %s" % [id, item_id])
				return false
			action.entries.append(ActionDef.Entry.new(
				item_id,
				float(e.get("chance", 1.0)),
				int(e.get("min", 0)),
				int(e.get("max", 0))))

		config_actions[id] = action
	return true

func _load_bag(data) -> bool:
	if data == null:
		return false
	config_bag["free_slots"] = int(data.get("free_slots", 10))
	config_bag["base"] = int(data.get("base", 15))
	config_bag["increment"] = int(data.get("increment", 8))
	if config_bag["free_slots"] < 0 or config_bag["base"] < 0 or config_bag["increment"] < 0:
		push_error("背包定价不允许为负")
		return false
	return true

# ---------- 存档 ----------

func new_game() -> void:
	var data = _read_json(TEMPLATE_PATH)
	if data == null:
		push_error("模版新档缺失")
		return
	_deserialize_save(data)
	save.last_update_utc = Time.get_unix_time_from_system()
	Resolver.compute_unlocks(self, save.character)

func load_game(path: String) -> bool:
	var data = _read_json(path)
	if data == null:
		return false
	_deserialize_save(data)
	current_save_path = path
	return true

func save_game(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("写入存档失败: " + path)
		return
	f.store_string(JSON.stringify(_serialize_save(), "\t"))
	f.close()
	current_save_path = path

func save_current() -> void:
	if current_save_path != "":
		save_game(current_save_path)

func save_new_slot() -> String:
	var i := 1
	while true:
		var path := SAVE_DIR + "/save_%d.json" % i
		if not FileAccess.file_exists(path):
			save_game(path)
			return path
		i += 1
	return ""

func list_saves() -> Array:
	var out = []
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			var path := SAVE_DIR + "/" + fname
			var data = _read_json(path)
			if data != null:
				var ch = data.get("character", {})
				out.append({
					"path": path,
					"name": str(ch.get("name", "旅行者")),
					"last_update": float(data.get("last_update_utc", 0.0)),
				})
		fname = dir.get_next()
	dir.list_dir_end()
	return out

func delete_save(path: String) -> void:
	var dir := DirAccess.open(SAVE_DIR)
	if dir != null:
		dir.remove(path.get_file())

func _serialize_save() -> Dictionary:
	var character: CharacterData = save.character
	var locs = []
	for id in environment.locations:
		var loc: LocationData = environment.locations[id]
		locs.append({"id": loc.id, "name": loc.name, "unlocked": loc.unlocked})
	return {
		"version": 1,
		"character": {
			"id": character.id,
			"name": character.name,
			"current_action": character.current_action_id,
			"progress": character.progress,
			"skill_xp": character.skill_xp.duplicate(),
			"unlocked_actions": character.unlocked_actions.keys(),
			"inventory": {
				"capacity": character.inventory.capacity,
				"items": character.inventory.items.duplicate(),
			},
		},
		"locations": locs,
		"last_update_utc": save.last_update_utc,
	}

func _deserialize_save(data: Dictionary) -> void:
	save = SaveData.new()
	var character: CharacterData = save.character
	var c = data.get("character", {})
	character.id = str(c.get("id", "p_default"))
	character.name = str(c.get("name", "旅行者"))
	character.current_action_id = str(c.get("current_action", ""))
	character.progress = float(c.get("progress", 0.0))

	var xp = c.get("skill_xp", {})
	for k in xp:
		character.skill_xp[str(k)] = int(xp[k])

	var unlocked = c.get("unlocked_actions", [])
	for aid in unlocked:
		character.unlocked_actions[str(aid)] = true

	var inv = c.get("inventory", {})
	character.inventory.capacity = int(inv.get("capacity", config_bag.get("free_slots", 10)))
	var items = inv.get("items", {})
	for k in items:
		character.inventory.items[str(k)] = int(items[k])

	environment.locations.clear()
	var locs = data.get("locations", [])
	for l in locs:
		var loc := LocationData.new(
			str(l.get("id", "")),
			str(l.get("name", "")),
			bool(l.get("unlocked", false)))
		environment.locations[loc.id] = loc

	# 父地点id 是配置数据，存档只存解锁状态；载入后从配置回填
	for id in environment.locations:
		environment.locations[id].parent_id = config_location_parents.get(id, "")

	# 配置新增而存档里还没有的地点，补为未解锁（向后兼容旧档）
	for id in config_locations:
		if not environment.locations.has(id):
			environment.locations[id] = LocationData.new(id, config_locations[id], false)
			environment.locations[id].parent_id = config_location_parents.get(id, "")

	save.last_update_utc = float(data.get("last_update_utc", 0.0))

# ---------- 唯一入口：存档.更新() ----------

func update(now_utc: float) -> void:
	if save == null:
		return
	var character: CharacterData = save.character
	var dt: float = now_utc - save.last_update_utc
	if dt <= 0.0:
		return

	# 2/3 闭式动作推进与结算
	if character.current_action_id != "" and environment.actions.has(character.current_action_id):
		var action: ActionDef = environment.actions[character.current_action_id]
		var adv := Resolver.advance(action, character.progress, dt)
		character.progress = float(adv["progress"])
		var n := int(adv["count"])
		if n > 0:
			var summary := Resolver.settle(self, character, action, n)
			_emit_settle_message(action, summary)

	# 4 解锁判定
	Resolver.compute_unlocks(self, character)

	# 5 执行操作
	_consume_operations(character)

	# 6 写盘
	save.last_update_utc = now_utc - _debug_rewind
	_debug_rewind = 0.0
	save_current()

# ---------- 操作 ----------

func append_operation(type: String, param: String) -> void:
	if save == null:
		return
	save.character.operations.append(Operation.new(type, param))

func _consume_operations(character: CharacterData) -> void:
	for op in character.operations:
		_consume_one(op, character)
	character.operations.clear()

func _consume_one(op: Operation, character: CharacterData) -> void:
	match op.type:
		Operation.TYPE_START_ACTION:
			var aid := op.param
			if aid == character.current_action_id:
				return
			if environment.actions.has(aid) and character.unlocked_actions.has(aid):
				character.current_action_id = aid
				character.progress = 0.0
			else:
				MessageBus.emit_message("red", "无法开始该动作（不存在或未解锁）")
		Operation.TYPE_STOP_ACTION:
			character.current_action_id = ""
			character.progress = 0.0
		Operation.TYPE_SET_NAME:
			character.name = op.param
		Operation.TYPE_BUY_SLOTS:
			_buy_slots(op.param, character)
		Operation.TYPE_DEBUG_STEP:
			# 调试：累计回拨秒数；update() 写时间戳时统一扣除，使下一次更新多结算 n 秒
			if op.param.is_valid_int() and op.param.to_int() > 0:
				_debug_rewind += float(op.param.to_int())

func _buy_slots(param: String, character: CharacterData) -> void:
	if not param.is_valid_int():
		MessageBus.emit_message("red", "购买格数无效")
		return
	var n := param.to_int()
	if n <= 0:
		MessageBus.emit_message("red", "购买格数无效")
		return

	var free := int(config_bag.get("free_slots", 10))
	var base := int(config_bag.get("base", 15))
	var inc := int(config_bag.get("increment", 8))
	var c := character.inventory.capacity
	var total := 0
	for k in n:
		total += base + inc * (c - free + k)

	if character.inventory.gold() < total:
		MessageBus.emit_message("red", "金币不足，无法购买背包格")
		return

	character.inventory.spend_gold(total)
	character.inventory.capacity = c + n
	MessageBus.emit_message("blue", "解锁背包格 +%d（花费 %d 金币）" % [n, total])

# ---------- 消息 ----------

func _fmt_counts(d: Dictionary) -> String:
	var parts = []
	for id in d:
		parts.append("%s×%d" % [item_name(id), int(d[id])])
	return "、".join(parts)

func _emit_settle_message(action: ActionDef, summary: Dictionary) -> void:
	var completed := int(summary["completed"])
	if completed <= 0 and not bool(summary["stopped"]):
		return
	var text := "完成 %d 次「%s」（%.1f 秒）" % [completed, action.name, float(completed) * action.duration]
	var consumed: Dictionary = summary["consumed"]
	var gained: Dictionary = summary["gained"]
	var discarded: Dictionary = summary["discarded"]
	if consumed.size() > 0:
		text += "，消耗 " + _fmt_counts(consumed)
	if gained.size() > 0:
		text += "，获得 " + _fmt_counts(gained)
	if discarded.size() > 0:
		text += "，因背包满丢弃 " + _fmt_counts(discarded)
	MessageBus.emit_message("white", text)
	if bool(summary["stopped"]):
		MessageBus.emit_message("red", str(summary["stop_reason"]))
