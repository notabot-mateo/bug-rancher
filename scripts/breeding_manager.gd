## BreedingManager
## Handles breeding pairs, incubation, and hatching
extends Node

signal breeding_started(slot_index: int, parent_a: BugInstance, parent_b: BugInstance)
signal egg_ready(slot_index: int)
signal bug_hatched(slot_index: int, bug: BugInstance)

## Breeding slot data
class BreedingSlot:
	var parent_a: BugInstance = null
	var parent_b: BugInstance = null
	var offspring_species: String = ""
	var start_time: int = 0
	var hatch_time: int = 0
	var egg_ready: bool = false
	var offspring: BugInstance = null
	
	func is_empty() -> bool:
		return parent_a == null
	
	func is_incubating() -> bool:
		return not is_empty() and not egg_ready
	
	func get_progress() -> float:
		if is_empty() or egg_ready:
			return 0.0
		var now := int(Time.get_unix_time_from_system())
		var duration := hatch_time - start_time
		var elapsed := now - start_time
		return clampf(float(elapsed) / float(duration), 0.0, 1.0)
	
	func get_remaining_seconds() -> int:
		if is_empty() or egg_ready:
			return 0
		var now := int(Time.get_unix_time_from_system())
		return maxi(0, hatch_time - now)

## Constants
const BASE_INCUBATION_SECONDS := 300  # 5 minutes base
const MAX_BREEDING_SLOTS := 3  # Upgradeable later

## State
var slots: Array[BreedingSlot] = []
var unlocked_slots: int = 1  # Start with 1, unlock more

func _ready() -> void:
	# Initialize slots
	for i in range(MAX_BREEDING_SLOTS):
		slots.append(BreedingSlot.new())

func _process(_delta: float) -> void:
	# Check for completed incubations
	for i in range(slots.size()):
		var slot := slots[i]
		if slot.is_incubating():
			var now := int(Time.get_unix_time_from_system())
			if now >= slot.hatch_time:
				_complete_incubation(i)

## Start breeding two bugs
func start_breeding(
	slot_index: int,
	parent_a: BugInstance,
	parent_b: BugInstance,
	offspring_species: String = ""
) -> bool:
	if slot_index >= unlocked_slots:
		push_error("Slot not unlocked")
		return false
	
	var slot := slots[slot_index]
	if not slot.is_empty():
		push_error("Slot already in use")
		return false
	
	# Default to parent_a's species if not specified
	if offspring_species.is_empty():
		offspring_species = parent_a.species_id
	
	slot.parent_a = parent_a
	slot.parent_b = parent_b
	slot.offspring_species = offspring_species
	slot.start_time = int(Time.get_unix_time_from_system())
	slot.hatch_time = slot.start_time + _calculate_incubation_time(parent_a, parent_b)
	slot.egg_ready = false
	slot.offspring = null
	
	breeding_started.emit(slot_index, parent_a, parent_b)
	return true

## Calculate incubation time based on parents
func _calculate_incubation_time(parent_a: BugInstance, parent_b: BugInstance) -> int:
	var base_time := BASE_INCUBATION_SECONDS
	
	# Higher ADP = faster incubation
	var avg_adp: float = (float(parent_a.ivs.get("ADP", 15)) + float(parent_b.ivs.get("ADP", 15))) / 2.0
	var adp_bonus: float = avg_adp / 31.0 * 0.2  # Up to 20% faster
	
	var final_time := int(base_time * (1.0 - adp_bonus))
	return maxi(60, final_time)  # Minimum 1 minute

## Complete incubation - egg is ready
func _complete_incubation(slot_index: int) -> void:
	var slot := slots[slot_index]
	
	# Generate offspring
	slot.offspring = BugInstance.create_offspring(
		slot.offspring_species,
		slot.parent_a,
		slot.parent_b
	)
	slot.egg_ready = true
	
	egg_ready.emit(slot_index)

## Hatch egg and claim offspring
func hatch_egg(slot_index: int) -> BugInstance:
	var slot := slots[slot_index]
	if not slot.egg_ready or slot.offspring == null:
		return null
	
	var offspring := slot.offspring
	offspring.hatched_at = int(Time.get_unix_time_from_system())
	
	# Clear slot
	_clear_slot(slot_index)
	
	bug_hatched.emit(slot_index, offspring)
	return offspring

## Clear a breeding slot
func _clear_slot(slot_index: int) -> void:
	var slot := slots[slot_index]
	slot.parent_a = null
	slot.parent_b = null
	slot.offspring_species = ""
	slot.start_time = 0
	slot.hatch_time = 0
	slot.egg_ready = false
	slot.offspring = null

## Cancel breeding in progress
func cancel_breeding(slot_index: int) -> void:
	_clear_slot(slot_index)

## Get slot info
func get_slot(slot_index: int) -> BreedingSlot:
	if slot_index < slots.size():
		return slots[slot_index]
	return null

## Preview offspring IV floors before breeding
func preview_offspring(parent_a: BugInstance, parent_b: BugInstance) -> Dictionary:
	return {
		"iv_floors": GeneticsSystem.preview_iv_floors(parent_a.ivs, parent_b.ivs),
		"incubation_seconds": _calculate_incubation_time(parent_a, parent_b)
	}

## Unlock additional breeding slot
func unlock_slot() -> bool:
	if unlocked_slots < MAX_BREEDING_SLOTS:
		unlocked_slots += 1
		return true
	return false

## Get number of unlocked slots
func get_unlocked_slots() -> int:
	return unlocked_slots
