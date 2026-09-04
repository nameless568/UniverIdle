class_name EnvironmentData
extends RefCounted

var public_inventory: Dictionary = {}  # 当前不用，备多人
var locations: Dictionary = {}          # 地点id -> LocationData（是否解锁为存档状态）
var items: Dictionary = {}              # 物品id -> ItemDef（配置）
var actions: Dictionary = {}            # 动作id -> ActionDef（配置）
