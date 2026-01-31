extends Node

## Bug Rancher - Upgrade Manager
## Handles permanent upgrades, consumables, cosmetics, and daily limits

signal upgrade_purchased(upgrade_id: String, new_level: int)
signal consumable_used(item_id: String)
signal daily_limits_reset

var _upgrade_data: Dictionary = {}
const SECONDS_PER_DAY := 86400

func _ready() -> void:
	_load_upgrade_data()

func _load_upgrade_data() -> void:
	var file = FileAccess.open("res://data/upgrades.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		if error == OK:
			_upgrade_data = json.data
			print("UpgradeManager: Loaded upgrade data")

# ============================================
# PERMANENT UPGRADES
# ============================================

func get_upgrade_level(upgrade_id: String) -> int:
	return GameManager.player_data.get("upgrade_levels", {}).get(upgrade_id, 0)

func get_max_level(upgrade_id: String) -> int:
	var upgrade = _upgrade_data.get("permanent", {}).get(upgrade_id, {})
	return upgrade.get("max_level", 0)

func get_upgrade_price(upgrade_id: String) -> int:
	var upgrade = _upgrade_data.get("permanent", {}).get(upgrade_id, {})
	var current_level = get_upgrade_level(upgrade_id)
	var prices = upgrade.get("prices", [])
	if current_level < prices.size():
		return prices[current_level]
	return 0

func get_upgrade_info(upgrade_id: String) -> Dictionary:
	return _upgrade_data.get("permanent", {}).get(upgrade_id, {})

func can_purchase_upgrade(upgrade_id: String) -> bool:
	var current_level = get_upgrade_level(upgrade_id)
	var max_level = get_max_level(upgrade_id)
	if current_level >= max_level:
		return false
	var price = get_upgrade_price(upgrade_id)
	return GameManager.get_currency() >= price

func purchase_upgrade(upgrade_id: String) -> bool:
	if not can_purchase_upgrade(upgrade_id):
		return false
	
	var price = get_upgrade_price(upgrade_id)
	if not GameManager.spend_currency(price):
		return false
	
	# Increment level
	if not GameManager.player_data.has("upgrade_levels"):
		GameManager.player_data["upgrade_levels"] = {}
	
	var current = get_upgrade_level(upgrade_id)
	GameManager.player_data["upgrade_levels"][upgrade_id] = current + 1
	
	GameManager.save_game()
	upgrade_purchased.emit(upgrade_id, current + 1)
	return true

func get_all_permanent_upgrades() -> Dictionary:
	return _upgrade_data.get("permanent", {})

# ============================================
# EFFECT CALCULATIONS
# ============================================

func get_egg_slot_count() -> int:
	var level = get_upgrade_level("egg_slots")
	var upgrade = _upgrade_data.get("permanent", {}).get("egg_slots", {})
	var per_level = upgrade.get("per_level", [1, 2, 3])
	if level < per_level.size():
		return per_level[level]
	return 1

func get_incubation_multiplier() -> float:
	var level = get_upgrade_level("incubator_speed")
	var upgrade = _upgrade_data.get("permanent", {}).get("incubator_speed", {})
	var per_level = upgrade.get("per_level", [1.0])
	if level < per_level.size():
		return per_level[level]
	return 1.0

func get_iv_floor_bonus() -> float:
	var bonus := 0.0
	
	# From genetics lab upgrade
	var level = get_upgrade_level("genetics_lab")
	var upgrade = _upgrade_data.get("permanent", {}).get("genetics_lab", {})
	var per_level = upgrade.get("per_level", [0.0])
	if level < per_level.size():
		bonus += per_level[level]
	
	# From cosmetics
	bonus += _get_cosmetic_bonus("iv_floor_bonus")
	
	return bonus

func get_hybrid_chance_bonus() -> float:
	var bonus := 0.0
	
	# From hybrid chamber upgrade
	var level = get_upgrade_level("hybrid_chamber")
	var upgrade = _upgrade_data.get("permanent", {}).get("hybrid_chamber", {})
	var per_level = upgrade.get("per_level", [0.0])
	if level < per_level.size():
		bonus += per_level[level]
	
	# From cosmetics
	bonus += _get_cosmetic_bonus("hybrid_chance_bonus")
	
	return bonus

func get_sell_price_bonus() -> float:
	return _get_cosmetic_bonus("sell_bonus")

func _get_cosmetic_bonus(bonus_type: String) -> float:
	var total := 0.0
	var equipped = GameManager.player_data.get("equipped_cosmetics", [])
	var cosmetics = _upgrade_data.get("cosmetics", {})
	
	for cosmetic_id in equipped:
		var cosmetic = cosmetics.get(cosmetic_id, {})
		var bonus = cosmetic.get("bonus", {})
		if bonus and bonus.has(bonus_type):
			total += bonus[bonus_type]
	
	return total

# ============================================
# CONSUMABLES
# ============================================

func get_consumable_count(item_id: String) -> int:
	return GameManager.player_data.get("consumables", {}).get(item_id, 0)

func get_consumable_info(item_id: String) -> Dictionary:
	return _upgrade_data.get("consumables", {}).get(item_id, {})

func get_all_consumables() -> Dictionary:
	return _upgrade_data.get("consumables", {})

func use_consumable(item_id: String) -> bool:
	var count = get_consumable_count(item_id)
	if count <= 0:
		return false
	
	GameManager.player_data["consumables"][item_id] = count - 1
	GameManager.save_game()
	consumable_used.emit(item_id)
	return true

func add_consumable(item_id: String, amount: int = 1) -> void:
	if not GameManager.player_data.has("consumables"):
		GameManager.player_data["consumables"] = {}
	
	var current = get_consumable_count(item_id)
	var info = get_consumable_info(item_id)
	var max_stack = info.get("stack_max", 99)
	
	GameManager.player_data["consumables"][item_id] = mini(current + amount, max_stack)
	GameManager.save_game()

func purchase_consumable(item_id: String) -> bool:
	var info = get_consumable_info(item_id)
	if info.is_empty():
		return false
	
	var price = info.get("price", 0)
	if not GameManager.spend_currency(price):
		return false
	
	add_consumable(item_id, 1)
	return true

# ============================================
# COSMETICS
# ============================================

func get_all_cosmetics() -> Dictionary:
	return _upgrade_data.get("cosmetics", {})

func owns_cosmetic(cosmetic_id: String) -> bool:
	return cosmetic_id in GameManager.player_data.get("owned_cosmetics", [])

func is_cosmetic_equipped(cosmetic_id: String) -> bool:
	return cosmetic_id in GameManager.player_data.get("equipped_cosmetics", [])

func purchase_cosmetic(cosmetic_id: String) -> bool:
	if owns_cosmetic(cosmetic_id):
		return false
	
	var cosmetic = _upgrade_data.get("cosmetics", {}).get(cosmetic_id, {})
	var price = cosmetic.get("price", 0)
	
	if not GameManager.spend_currency(price):
		return false
	
	if not GameManager.player_data.has("owned_cosmetics"):
		GameManager.player_data["owned_cosmetics"] = []
	
	GameManager.player_data["owned_cosmetics"].append(cosmetic_id)
	# Auto-equip on purchase
	equip_cosmetic(cosmetic_id)
	GameManager.save_game()
	return true

func equip_cosmetic(cosmetic_id: String) -> void:
	if not owns_cosmetic(cosmetic_id):
		return
	
	if not GameManager.player_data.has("equipped_cosmetics"):
		GameManager.player_data["equipped_cosmetics"] = []
	
	if cosmetic_id not in GameManager.player_data["equipped_cosmetics"]:
		GameManager.player_data["equipped_cosmetics"].append(cosmetic_id)
		GameManager.save_game()

func unequip_cosmetic(cosmetic_id: String) -> void:
	if GameManager.player_data.has("equipped_cosmetics"):
		GameManager.player_data["equipped_cosmetics"].erase(cosmetic_id)
		GameManager.save_game()

# ============================================
# DAILY SELL LIMITS
# ============================================

func get_daily_sell_count(species_id: String) -> int:
	check_daily_reset()
	return GameManager.player_data.get("daily_sells", {}).get(species_id, 0)

func get_daily_sell_limit(species_id: String) -> int:
	var limits = _upgrade_data.get("daily_limits", {})
	if "_" in species_id:  # Hybrid
		return limits.get("hybrid_species", 5)
	else:
		return limits.get("base_species", 3)

func can_sell_species_today(species_id: String) -> bool:
	return get_daily_sell_count(species_id) < get_daily_sell_limit(species_id)

func record_sale(species_id: String) -> void:
	check_daily_reset()
	
	if not GameManager.player_data.has("daily_sells"):
		GameManager.player_data["daily_sells"] = {}
	
	var current = get_daily_sell_count(species_id)
	GameManager.player_data["daily_sells"][species_id] = current + 1
	GameManager.save_game()

func check_daily_reset() -> void:
	var now = int(Time.get_unix_time_from_system())
	var last_reset = GameManager.player_data.get("last_sell_reset", 0)
	
	# Check if we've crossed midnight (simple: check if day changed)
	var last_day = last_reset / SECONDS_PER_DAY
	var current_day = now / SECONDS_PER_DAY
	
	if current_day > last_day:
		# Reset!
		GameManager.player_data["daily_sells"] = {}
		GameManager.player_data["last_sell_reset"] = now
		GameManager.save_game()
		daily_limits_reset.emit()
		print("Daily sell limits reset!")

func force_reset_daily_limits() -> void:
	GameManager.player_data["daily_sells"] = {}
	GameManager.player_data["last_sell_reset"] = int(Time.get_unix_time_from_system())
	GameManager.save_game()
	daily_limits_reset.emit()
