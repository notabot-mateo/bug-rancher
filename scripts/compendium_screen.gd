extends Control

## Bug Rancher - Compendium Screen
## Shows a grid of all species, discovered or not

signal species_selected(species_id: String)

@onready var grid: GridContainer = $ScrollContainer/GridContainer

var species_slot_scene = preload("res://scenes/components/species_slot.tscn")

func _ready() -> void:
	_populate_grid()
	GameManager.collection_changed.connect(_refresh_counts)
	GameManager.species_discovered.connect(_on_species_discovered)

func _populate_grid() -> void:
	# Clear existing
	for child in grid.get_children():
		child.queue_free()
	
	# Add slot for each species
	var all_species = BugDatabase.get_all_bugs()
	for species in all_species:
		var slot = species_slot_scene.instantiate()
		slot.setup(species)
		slot.pressed.connect(_on_slot_pressed.bind(species.id))
		grid.add_child(slot)

func _refresh_counts() -> void:
	for slot in grid.get_children():
		slot.update_count()

func _on_species_discovered(_species_id: String) -> void:
	# Refresh to show newly discovered species
	_populate_grid()

func _on_slot_pressed(species_id: String) -> void:
	if GameManager.is_species_discovered(species_id):
		species_selected.emit(species_id)
