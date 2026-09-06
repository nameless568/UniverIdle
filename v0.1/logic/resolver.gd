class_name Resolver
extends RefCounted

# 闭式动作推进：返回 {"count": 结算次数, "progress": 新完成百分比}
static func advance(action: ActionDef, progress: float, dt: float) -> Dictionary:
	var duration := action.duration
	if duration <= 0.0:
		duration = 0.01
	var total := progress * duration + dt
	var count := int(floor(total / duration))
	var new_progress := (total / duration) - count
	return {"count": count, "progress": new_progress}

# 按技能经验查等级（回落到默认表由 GameState.get_level_table 处理）
static func level_for_skill(state, skill: String, xp: int) -> int:
	var table: LevelTable = state.get_level_table(skill)
	return table.level_for_xp(xp)

# 解锁判定：动作满足全部需求 -> 加入已解锁集合（单调只加不减）；地点内任一动作解锁即解锁。
static func compute_unlocks(state, character: CharacterData) -> void:
	for action_id in state.environment.actions:
		var action: ActionDef = state.environment.actions[action_id]
		if character.unlocked_actions.has(action_id):
			continue
		var ok := true
		for skill in action.unlock_requirements:
			var need: int = int(action.unlock_requirements[skill])
			var xp: int = int(character.skill_xp.get(skill, 0))
			if level_for_skill(state, str(skill), xp) < need:
				ok = false
				break
		if ok:
			character.unlocked_actions[action_id] = true

	for loc_id in state.environment.locations:
		var loc: LocationData = state.environment.locations[loc_id]
		if loc.unlocked:
			continue
		for action_id in state.environment.actions:
			var action: ActionDef = state.environment.actions[action_id]
			if action.location_id == loc_id and character.unlocked_actions.has(action_id):
				loc.unlocked = true
				break

	# 父地点：任一子地点解锁，即父地点解锁（只支持一层，单调只加不减）
	for loc_id in state.environment.locations:
		var loc: LocationData = state.environment.locations[loc_id]
		if loc.parent_id == "" or not loc.unlocked:
			continue
		if state.environment.locations.has(loc.parent_id):
			var parent: LocationData = state.environment.locations[loc.parent_id]
			if not parent.unlocked:
				parent.unlocked = true

# 结算 count 次：消耗先查后扣，获取独立掷骰，经验累计；中途缺料则停止。
static func settle(state, character: CharacterData, action: ActionDef, count: int) -> Dictionary:
	var gained := {}
	var consumed := {}
	var discarded := {}
	var completed := 0
	var stopped := false
	var stop_reason := ""

	for _i in count:
		var cost_entries := []
		for e in action.entries:
			if e.is_consumption():
				cost_entries.append(e)

		var can_afford := true
		for e in cost_entries:
			if character.inventory.count(e.item_id) < abs(e.min_amount):
				can_afford = false
				stop_reason = "缺少「%s」，动作停止" % state.item_name(e.item_id)
				break

		if not can_afford:
			stopped = true
			character.current_action_id = ""
			character.progress = 0.0
			break

		for e in cost_entries:
			var amount = abs(e.min_amount)
			character.inventory.try_consume(e.item_id, amount)
			consumed[e.item_id] = int(consumed.get(e.item_id, 0)) + amount

		for e in action.entries:
			if e.is_consumption() or e.chance <= 0.0:
				continue
			if randf() >= e.chance:
				continue
			var amount = e.min_amount
			if e.max_amount > e.min_amount:
				amount = randi_range(e.min_amount, e.max_amount)
			if amount <= 0:
				continue
			if character.inventory.add_item(e.item_id, amount):
				gained[e.item_id] = int(gained.get(e.item_id, 0)) + amount
			else:
				discarded[e.item_id] = int(discarded.get(e.item_id, 0)) + amount

		for skill in action.xp_rewards:
			var xp := int(action.xp_rewards[skill])
			character.skill_xp[skill] = int(character.skill_xp.get(skill, 0)) + xp

		completed += 1

	return {
		"completed": completed,
		"gained": gained,
		"consumed": consumed,
		"discarded": discarded,
		"stopped": stopped,
		"stop_reason": stop_reason,
	}
