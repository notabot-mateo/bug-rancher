## Genetics System
## Handles IV inheritance, EV training, and stat calculations
extends Node
class_name GeneticsSystem

## IV Constants
const IV_MIN := 0
const IV_MAX := 31
const IV_INHERITANCE_FLOOR_BONUS := 0.25  # Parents pass 25% of their IV as floor

## EV Constants
const EV_MAX_PER_STAT := 252
const EV_MAX_TOTAL := 510
const EV_GAIN_BASE_CHANCE := 0.05  # 5% base chance
const EV_PER_GAIN := 4  # EVs gained per successful roll

## Stat multiplier at level 100
const IV_STAT_MULTIPLIER := 1.0  # Each IV point = +1 stat at max level
const EV_STAT_MULTIPLIER := 0.25  # Every 4 EVs = +1 stat at max level

#region IV Generation

## Generate random IVs for a wild/starter bug
static func generate_random_ivs() -> Dictionary:
	var ivs := {}
	for stat in ["VIT", "STR", "CAR", "SPC", "SPD", "STA", "INS", "ADP"]:
		ivs[stat] = randi_range(IV_MIN, IV_MAX)
	return ivs

## Generate IVs for offspring based on parents
## Higher parent IVs = higher floor for that stat
static func generate_offspring_ivs(parent_a_ivs: Dictionary, parent_b_ivs: Dictionary) -> Dictionary:
	var ivs := {}
	
	for stat in ["VIT", "STR", "CAR", "SPC", "SPD", "STA", "INS", "ADP"]:
		var parent_a_iv: int = parent_a_ivs.get(stat, 0)
		var parent_b_iv: int = parent_b_ivs.get(stat, 0)
		
		# Average parents' IVs, then apply floor bonus
		var parent_avg := (parent_a_iv + parent_b_iv) / 2.0
		var floor_bonus := int(parent_avg * IV_INHERITANCE_FLOOR_BONUS)
		
		# Calculate floor and ceiling
		var stat_floor := clampi(floor_bonus, IV_MIN, IV_MAX - 5)
		var stat_ceiling := IV_MAX
		
		# Random roll between floor and ceiling
		ivs[stat] = randi_range(stat_floor, stat_ceiling)
	
	return ivs

## Calculate IV inheritance preview (for UI)
static func preview_iv_floors(parent_a_ivs: Dictionary, parent_b_ivs: Dictionary) -> Dictionary:
	var floors := {}
	for stat in ["VIT", "STR", "CAR", "SPC", "SPD", "STA", "INS", "ADP"]:
		var parent_a_iv: int = parent_a_ivs.get(stat, 0)
		var parent_b_iv: int = parent_b_ivs.get(stat, 0)
		var parent_avg := (parent_a_iv + parent_b_iv) / 2.0
		floors[stat] = clampi(int(parent_avg * IV_INHERITANCE_FLOOR_BONUS), IV_MIN, IV_MAX - 5)
	return floors

#endregion

#region EV Training

## Initialize empty EVs
static func create_empty_evs() -> Dictionary:
	var evs := {}
	for stat in ["VIT", "STR", "CAR", "SPC", "SPD", "STA", "INS", "ADP"]:
		evs[stat] = 0
	return evs

## Calculate total EVs across all stats
static func get_total_evs(evs: Dictionary) -> int:
	var total := 0
	for stat in evs:
		total += evs[stat]
	return total

## Attempt to gain EVs from defeating an enemy
## Returns dictionary of EVs gained (can be empty if roll failed)
static func try_gain_evs(
	current_evs: Dictionary,
	enemy_level: int,
	enemy_primary_stat: String
) -> Dictionary:
	var evs_gained := {}
	
	# Check if we can gain more EVs
	var total_evs := get_total_evs(current_evs)
	if total_evs >= EV_MAX_TOTAL:
		return evs_gained  # Maxed out
	
	# Calculate chance: 5% × enemy level
	var chance := EV_GAIN_BASE_CHANCE * enemy_level
	chance = clampf(chance, 0.0, 1.0)  # Cap at 100%
	
	# Roll for EV gain
	if randf() <= chance:
		var current_stat_ev: int = current_evs.get(enemy_primary_stat, 0)
		
		# Check if this stat is maxed
		if current_stat_ev < EV_MAX_PER_STAT:
			var gain := mini(EV_PER_GAIN, EV_MAX_PER_STAT - current_stat_ev)
			# Also check total cap
			gain = mini(gain, EV_MAX_TOTAL - total_evs)
			
			if gain > 0:
				evs_gained[enemy_primary_stat] = gain
	
	return evs_gained

## Apply EV gains to a bug's EVs
static func apply_ev_gains(current_evs: Dictionary, gains: Dictionary) -> Dictionary:
	var new_evs := current_evs.duplicate()
	for stat in gains:
		new_evs[stat] = new_evs.get(stat, 0) + gains[stat]
	return new_evs

#endregion

#region Stat Calculation

## Calculate final stat value
## Formula: Base + (IV * IV_mult) + (EV * EV_mult) + Level Scaling
static func calculate_stat(
	base_value: int,
	iv: int,
	ev: int,
	level: int
) -> int:
	# Scale IVs and EVs based on level (full effect at level 100)
	var level_scale := level / 100.0
	
	var iv_bonus := iv * IV_STAT_MULTIPLIER * level_scale
	var ev_bonus := ev * EV_STAT_MULTIPLIER * level_scale
	
	# Base value also scales with level
	var scaled_base := base_value * (1.0 + level_scale)
	
	return int(scaled_base + iv_bonus + ev_bonus)

## Calculate all stats for a bug
static func calculate_all_stats(
	base_stats: Dictionary,
	ivs: Dictionary,
	evs: Dictionary,
	level: int
) -> Dictionary:
	var final_stats := {}
	for stat in base_stats:
		final_stats[stat] = calculate_stat(
			base_stats[stat],
			ivs.get(stat, 0),
			evs.get(stat, 0),
			level
		)
	return final_stats

#endregion

#region Quality Rating

## Rate a bug's IVs (for display)
## Returns: "trash", "common", "good", "great", "perfect"
static func rate_ivs(ivs: Dictionary) -> String:
	var total := 0
	for stat in ivs:
		total += ivs[stat]
	
	var max_total := IV_MAX * 8  # 248
	var percentage := float(total) / float(max_total)
	
	if percentage >= 0.95:
		return "perfect"
	elif percentage >= 0.80:
		return "great"
	elif percentage >= 0.60:
		return "good"
	elif percentage >= 0.40:
		return "common"
	else:
		return "trash"

## Get star rating (1-5) for IVs
static func get_iv_stars(ivs: Dictionary) -> int:
	var rating := rate_ivs(ivs)
	match rating:
		"perfect": return 5
		"great": return 4
		"good": return 3
		"common": return 2
		_: return 1

#endregion
