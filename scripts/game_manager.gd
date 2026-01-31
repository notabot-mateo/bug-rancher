extends Node

## Bug Rancher - Game Manager
## Handles player data, bug collection, currency, and persistence

signal collection_changed
signal currency_changed(amount: int)
signal species_discovered(species_id: String)

const SAVE_PATH = "user://save.json"

var player_data: Dictionary = {
	"currency": 0,
	"discovered_species": [],  # Species IDs the player has seen
	"collection": [],  # Array of BugInstance dictionaries
	"breeding_slots": [],
	"upgrades": {},
	# Phase 4 additions
	"upgrade_levels": {
		"egg_slots": 1,
		"incubator_speed": 0,
		"genetics_lab": 0,
		"hybrid_chamber": 0
	},
	"consumables": {},
	"owned_cosmetics": [],
	"equipped_cosmetics": [],
	"daily_sells": {},
	"last_sell_reset": 0
}

var bug_instances: Array = []  # Runtime BugInstance objects

func _ready() -> void:
	if not load_game():
		_initialize_new_game()

func _initialize_new_game() -> void:
	print("Bug Rancher: Initializing new game...")
	
	# Give player a starter isopod
	var starter = create_wild_bug("isopod")
	starter["nickname"] = "Rolly"
	add_bug_to_collection(starter)
	
	# Mark isopod as discovered
	discover_species("isopod")
	
	save_game()
	print("New game initialized with starter: ", starter.nickname)

func create_wild_bug(species_id: String) -> Dictionary:
	var species = BugDatabase.get_bug(species_id)
	if species.is_empty():
		push_error("Unknown species: " + species_id)
		return {}
	
	var bug = {
		"id": _generate_id(),
		"species_id": species_id,
		"nickname": "",
		"level": 1,
		"ivs": _generate_random_ivs(),
		"evs": _generate_empty_evs(),
		"obtained_time": Time.get_unix_time_from_system()
	}
	
	return bug

func create_bred_bug(species_id: String, parent1_ivs: Dictionary, parent2_ivs: Dictionary) -> Dictionary:
	var bug = create_wild_bug(species_id)
	bug["ivs"] = _generate_inherited_ivs(parent1_ivs, parent2_ivs)
	bug["color_source"] = ""  # Set by breeding screen
	return bug

func create_bred_bug_with_bonus(species_id: String, parent1_ivs: Dictionary, parent2_ivs: Dictionary, iv_bonus: float) -> Dictionary:
	var bug = create_wild_bug(species_id)
	bug["ivs"] = _generate_inherited_ivs_with_bonus(parent1_ivs, parent2_ivs, iv_bonus)
	bug["color_source"] = ""
	return bug

func _generate_id() -> String:
	return str(randi()) + str(Time.get_ticks_msec())

func _generate_random_ivs() -> Dictionary:
	var ivs = {}
	for stat in ["VIT", "STR", "CAR", "SPC", "SPD", "STA", "INS", "ADP"]:
		ivs[stat] = randi_range(0, 31)
	return ivs

func _generate_empty_evs() -> Dictionary:
	var evs = {}
	for stat in ["VIT", "STR", "CAR", "SPC", "SPD", "STA", "INS", "ADP"]:
		evs[stat] = 0
	return evs

func _generate_inherited_ivs(p1: Dictionary, p2: Dictionary) -> Dictionary:
	return _generate_inherited_ivs_with_bonus(p1, p2, 0.0)

func _generate_inherited_ivs_with_bonus(p1: Dictionary, p2: Dictionary, bonus: float) -> Dictionary:
	var ivs = {}
	for stat in ["VIT", "STR", "CAR", "SPC", "SPD", "STA", "INS", "ADP"]:
		var avg = (p1.get(stat, 0) + p2.get(stat, 0)) / 2.0
		# Base floor is 25% of parent average, plus any bonus
		var floor_mult = 0.25 + bonus
		var floor_iv = int(avg * floor_mult)
		floor_iv = mini(floor_iv, 31)  # Cap at max IV
		ivs[stat] = randi_range(floor_iv, 31)
	return ivs

func add_bug_to_collection(bug: Dictionary) -> void:
	player_data.collection.append(bug)
	discover_species(bug.species_id)
	collection_changed.emit()

func remove_bug_from_collection(bug_id: String) -> void:
	for i in range(player_data.collection.size()):
		if player_data.collection[i].id == bug_id:
			player_data.collection.remove_at(i)
			collection_changed.emit()
			return

func get_bugs_by_species(species_id: String) -> Array:
	var result = []
	for bug in player_data.collection:
		if bug.species_id == species_id:
			result.append(bug)
	return result

func get_all_bugs() -> Array:
	return player_data.collection

func discover_species(species_id: String) -> void:
	if species_id not in player_data.discovered_species:
		player_data.discovered_species.append(species_id)
		species_discovered.emit(species_id)

func is_species_discovered(species_id: String) -> bool:
	return species_id in player_data.discovered_species

func get_discovered_species() -> Array:
	return player_data.discovered_species

func get_bug_count(species_id: String) -> int:
	var count = 0
	for bug in player_data.collection:
		if bug.species_id == species_id:
			count += 1
	return count

func calculate_quality_stars(ivs: Dictionary) -> int:
	var total = 0
	var max_total = 31 * 8  # 248 max
	for stat in ivs:
		total += ivs[stat]
	var percent = float(total) / float(max_total)
	
	if percent >= 0.95:
		return 5
	elif percent >= 0.80:
		return 4
	elif percent >= 0.60:
		return 3
	elif percent >= 0.40:
		return 2
	else:
		return 1

func get_highest_stat(bug: Dictionary) -> String:
	var species = BugDatabase.get_bug(bug.species_id)
	if species.is_empty():
		return "VIT"
	
	var highest_stat = "VIT"
	var highest_value = 0
	
	for stat in bug.ivs:
		var base = species.base_stats.get(stat, 10)
		var iv = bug.ivs.get(stat, 0)
		var ev = bug.evs.get(stat, 0)
		var total = base + iv + int(ev / 4.0)
		if total > highest_value:
			highest_value = total
			highest_stat = stat
	
	return highest_stat

func add_currency(amount: int) -> void:
	player_data.currency += amount
	currency_changed.emit(player_data.currency)

func spend_currency(amount: int) -> bool:
	if player_data.currency >= amount:
		player_data.currency -= amount
		currency_changed.emit(player_data.currency)
		return true
	return false

func get_currency() -> int:
	return player_data.currency

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(player_data))
		file.close()
		print("Game saved!")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		if error == OK:
			player_data = json.data
			print("Game loaded! Collection size: ", player_data.collection.size())
			return true
	return false
