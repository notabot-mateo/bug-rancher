## BugInstance
## Represents a single bug with its genetics, level, and computed stats
class_name BugInstance
extends Resource

@export var id: String = ""  # Unique instance ID
@export var species_id: String = ""  # References bugs.json
@export var nickname: String = ""
@export var level: int = 1

# Genetics
@export var ivs: Dictionary = {}
@export var evs: Dictionary = {}

# Lineage
@export var parent_a_id: String = ""  # Empty = wild/starter
@export var parent_b_id: String = ""
@export var generation: int = 0

# Timestamps
@export var hatched_at: int = 0
@export var created_at: int = 0

## Create a new wild/starter bug
static func create_wild(species_id: String) -> BugInstance:
	var bug := BugInstance.new()
	bug.id = _generate_id()
	bug.species_id = species_id
	bug.level = 1
	bug.ivs = Genetics.generate_random_ivs()
	bug.evs = Genetics.create_empty_evs()
	bug.generation = 0
	bug.created_at = int(Time.get_unix_time_from_system())
	bug.hatched_at = bug.created_at
	return bug

## Create offspring from two parents
static func create_offspring(
	species_id: String,
	parent_a: BugInstance,
	parent_b: BugInstance
) -> BugInstance:
	var bug := BugInstance.new()
	bug.id = _generate_id()
	bug.species_id = species_id
	bug.level = 1
	bug.ivs = Genetics.generate_offspring_ivs(parent_a.ivs, parent_b.ivs)
	bug.evs = Genetics.create_empty_evs()
	bug.parent_a_id = parent_a.id
	bug.parent_b_id = parent_b.id
	bug.generation = maxi(parent_a.generation, parent_b.generation) + 1
	bug.created_at = int(Time.get_unix_time_from_system())
	return bug

## Get base stats from database
func get_base_stats() -> Dictionary:
	# Assumes BugDatabase is autoloaded
	return BugDatabase.get_bug(species_id).get("base_stats", {})

## Calculate current stats (base + IVs + EVs + level)
func get_current_stats() -> Dictionary:
	return Genetics.calculate_all_stats(get_base_stats(), ivs, evs, level)

## Get a single current stat
func get_stat(stat: String) -> int:
	var base: int = BugDatabase.get_base_stat(species_id, stat)
	return Genetics.calculate_stat(base, ivs.get(stat, 0), evs.get(stat, 0), level)

## Get IV quality rating
func get_iv_rating() -> String:
	return Genetics.rate_ivs(ivs)

## Get IV star rating (1-5)
func get_stars() -> int:
	return Genetics.get_iv_stars(ivs)

## Try to gain EVs from combat
func try_gain_combat_evs(enemy_level: int, enemy_primary_stat: String) -> Dictionary:
	var gains := Genetics.try_gain_evs(evs, enemy_level, enemy_primary_stat)
	if not gains.is_empty():
		evs = Genetics.apply_ev_gains(evs, gains)
	return gains

## Get total EV points invested
func get_total_evs() -> int:
	return Genetics.get_total_evs(evs)

## Check if bug can gain more EVs
func can_gain_evs() -> bool:
	return get_total_evs() < Genetics.EV_MAX_TOTAL

## Get display name
func get_display_name() -> String:
	if nickname.is_empty():
		return BugDatabase.get_bug(species_id).get("name", species_id)
	return nickname

## Generate unique ID
static func _generate_id() -> String:
	return "%d_%s" % [
		int(Time.get_unix_time_from_system() * 1000),
		str(randi()).md5_text().substr(0, 8)
	]

## Serialize for saving
func to_dict() -> Dictionary:
	return {
		"id": id,
		"species_id": species_id,
		"nickname": nickname,
		"level": level,
		"ivs": ivs,
		"evs": evs,
		"parent_a_id": parent_a_id,
		"parent_b_id": parent_b_id,
		"generation": generation,
		"hatched_at": hatched_at,
		"created_at": created_at
	}

## Deserialize from save data
static func from_dict(data: Dictionary) -> BugInstance:
	var bug := BugInstance.new()
	bug.id = data.get("id", "")
	bug.species_id = data.get("species_id", "")
	bug.nickname = data.get("nickname", "")
	bug.level = data.get("level", 1)
	bug.ivs = data.get("ivs", {})
	bug.evs = data.get("evs", {})
	bug.parent_a_id = data.get("parent_a_id", "")
	bug.parent_b_id = data.get("parent_b_id", "")
	bug.generation = data.get("generation", 0)
	bug.hatched_at = data.get("hatched_at", 0)
	bug.created_at = data.get("created_at", 0)
	return bug
