extends Node
class_name HybridGenerator

## Bug Rancher - Hybrid Species Generator
## Dynamically generates hybrid species from two base species

const DOMINANT_WEIGHT := 0.6
const SECONDARY_WEIGHT := 0.4

## Cache of generated hybrid data
var _hybrid_cache: Dictionary = {}
var _hybrid_names: Dictionary = {}

func _ready() -> void:
	_load_hybrid_names()

func _load_hybrid_names() -> void:
	var file = FileAccess.open("res://data/hybrid_names.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		if error == OK:
			_hybrid_names = json.data.get("hybrids", {})
			print("HybridGenerator: Loaded ", _hybrid_names.size(), " hybrid names")

## Get or generate a hybrid species
## dominant_id comes first in the name, gets 60% stat weight
func get_hybrid(dominant_id: String, secondary_id: String) -> Dictionary:
	if dominant_id == secondary_id:
		return BugDatabase.get_bug(dominant_id)
	
	var hybrid_id = "%s_%s" % [dominant_id, secondary_id]
	
	if _hybrid_cache.has(hybrid_id):
		return _hybrid_cache[hybrid_id]
	
	var hybrid = _generate_hybrid(dominant_id, secondary_id)
	_hybrid_cache[hybrid_id] = hybrid
	return hybrid

## Check if a species ID is a hybrid
func is_hybrid(species_id: String) -> bool:
	return "_" in species_id and species_id.count("_") == 1

## Get the base species components from a hybrid ID
func get_hybrid_parents(hybrid_id: String) -> Array:
	if not is_hybrid(hybrid_id):
		return []
	var parts = hybrid_id.split("_")
	return [parts[0], parts[1]]  # [dominant, secondary]

## Generate hybrid species data
func _generate_hybrid(dominant_id: String, secondary_id: String) -> Dictionary:
	var dominant = BugDatabase.get_bug(dominant_id)
	var secondary = BugDatabase.get_bug(secondary_id)
	
	if dominant.is_empty() or secondary.is_empty():
		push_error("Cannot create hybrid: invalid parent species")
		return {}
	
	var hybrid_id = "%s_%s" % [dominant_id, secondary_id]
	
	# Generate blended stats (60/40 weighted)
	var blended_stats = {}
	for stat in ["VIT", "STR", "CAR", "SPC", "SPD", "STA", "INS", "ADP"]:
		var dom_val = dominant.base_stats.get(stat, 10)
		var sec_val = secondary.base_stats.get(stat, 10)
		blended_stats[stat] = int(dom_val * DOMINANT_WEIGHT + sec_val * SECONDARY_WEIGHT)
	
	# Normalize to 100 total (may drift slightly due to rounding)
	var total = 0
	for stat in blended_stats:
		total += blended_stats[stat]
	if total != 100:
		var diff = 100 - total
		# Add/remove from highest stat
		var highest_stat = "VIT"
		var highest_val = 0
		for stat in blended_stats:
			if blended_stats[stat] > highest_val:
				highest_val = blended_stats[stat]
				highest_stat = stat
		blended_stats[highest_stat] += diff
	
	# Combine roles (unique)
	var combined_roles = []
	for role in dominant.get("role", []):
		if role not in combined_roles and role != "starter":
			combined_roles.append(role)
	for role in secondary.get("role", []):
		if role not in combined_roles and role != "starter":
			combined_roles.append(role)
	if combined_roles.is_empty():
		combined_roles = ["hybrid"]
	
	# Combine abilities (dominant first, then secondary)
	var combined_abilities = []
	for ability in dominant.get("special_abilities", []):
		if ability not in combined_abilities:
			combined_abilities.append(ability)
	for ability in secondary.get("special_abilities", []):
		if ability not in combined_abilities and combined_abilities.size() < 4:
			combined_abilities.append(ability)
	
	# Look up creative name from hybrid_names.json
	var name_key = "%s_%s" % [dominant_id, secondary_id]
	var hybrid_name: String
	var fantasy: String
	
	if _hybrid_names.has(name_key):
		hybrid_name = _hybrid_names[name_key].get("name", "")
		fantasy = _hybrid_names[name_key].get("fantasy", "")
	
	# Fallback to generated name if not found
	if hybrid_name.is_empty():
		var dom_name = dominant.name.split(" ")[0]
		var sec_name = secondary.name.split(" ")[0]
		hybrid_name = "%s-%s" % [dom_name, sec_name]
	
	if fantasy.is_empty():
		fantasy = "A hybrid combining the %s's %s with the %s's %s." % [
			dominant.name.to_lower(),
			dominant.get("fantasy", "traits").split(",")[0].to_lower(),
			secondary.name.to_lower(),
			secondary.get("fantasy", "traits").split(",")[0].to_lower()
		]
	
	return {
		"id": hybrid_id,
		"name": hybrid_name,
		"is_hybrid": true,
		"dominant_parent": dominant_id,
		"secondary_parent": secondary_id,
		"role": combined_roles,
		"fantasy": fantasy,
		"base_stats": blended_stats,
		"special_abilities": combined_abilities
	}

## Get all possible hybrid IDs (for compendium)
func get_all_hybrid_ids() -> Array:
	var base_species = BugDatabase.get_all_species_ids()
	var hybrids = []
	
	for dom in base_species:
		for sec in base_species:
			if dom != sec:
				hybrids.append("%s_%s" % [dom, sec])
	
	return hybrids

## Roll breeding outcome for cross-species breeding
## Returns: { "type": "dominant" | "secondary" | "hybrid", "species_id": String }
func roll_breeding_outcome(parent_a_species: String, parent_b_species: String) -> Dictionary:
	if parent_a_species == parent_b_species:
		return { "type": "same", "species_id": parent_a_species }
	
	var roll = randf()
	
	if roll < 0.25:
		# 25% - Species A with B coloring
		return { 
			"type": "dominant_a", 
			"species_id": parent_a_species,
			"color_source": parent_b_species
		}
	elif roll < 0.50:
		# 25% - Species B with A coloring
		return {
			"type": "dominant_b",
			"species_id": parent_b_species,
			"color_source": parent_a_species
		}
	else:
		# 50% - Hybrid (randomly pick which is dominant)
		var hybrid_id: String
		if randf() < 0.5:
			hybrid_id = "%s_%s" % [parent_a_species, parent_b_species]
		else:
			hybrid_id = "%s_%s" % [parent_b_species, parent_a_species]
		return {
			"type": "hybrid",
			"species_id": hybrid_id,
			"color_source": "blended"
		}

## For hybrid breeding - simplify back to base species
func roll_hybrid_breeding_outcome(hybrid_species: String, other_species: String) -> Dictionary:
	var parents = get_hybrid_parents(hybrid_species)
	if parents.is_empty():
		return roll_breeding_outcome(hybrid_species, other_species)
	
	# Hybrid × Pure = one of the base components or the pure species
	var possible_outcomes = [parents[0], parents[1]]
	if not is_hybrid(other_species):
		possible_outcomes.append(other_species)
	else:
		# Hybrid × Hybrid - combine all base components
		var other_parents = get_hybrid_parents(other_species)
		for p in other_parents:
			if p not in possible_outcomes:
				possible_outcomes.append(p)
	
	var chosen = possible_outcomes[randi() % possible_outcomes.size()]
	return {
		"type": "simplified",
		"species_id": chosen,
		"color_source": hybrid_species if randf() < 0.5 else other_species
	}
