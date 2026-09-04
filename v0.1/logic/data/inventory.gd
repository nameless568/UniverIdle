class_name Inventory
extends RefCounted

const GOLD_ITEM_ID := "i_gold"

var items: Dictionary = {}   # 物品id -> 数量(int)
var capacity: int = 10

func gold() -> int:
	return int(items.get(GOLD_ITEM_ID, 0))

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	items[GOLD_ITEM_ID] = gold() + amount

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if gold() < amount:
		return false
	var remaining := gold() - amount
	if remaining <= 0:
		items.erase(GOLD_ITEM_ID)
	else:
		items[GOLD_ITEM_ID] = remaining
	return true

func count(item_id: String) -> int:
	return int(items.get(item_id, 0))

func occupied_slots() -> int:
	var n := 0
	for id in items:
		if id == GOLD_ITEM_ID:
			continue
		if int(items[id]) > 0:
			n += 1
	return n

# 入包：已存在则累加；新物品（非金币）占一格，满则失败；金币不占格。
func add_item(item_id: String, amount: int) -> bool:
	if amount <= 0:
		return false
	if item_id == GOLD_ITEM_ID:
		add_gold(amount)
		return true
	if items.has(item_id) and int(items[item_id]) > 0:
		items[item_id] = int(items[item_id]) + amount
		return true
	if occupied_slots() >= capacity:
		return false
	items[item_id] = amount
	return true

func try_consume(item_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if count(item_id) < amount:
		return false
	var remaining := count(item_id) - amount
	if remaining <= 0:
		items.erase(item_id)
	else:
		items[item_id] = remaining
	return true
