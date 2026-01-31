extends Control

## Bug Rancher - Collection Screen
## Shows all bugs of a single species as a hand of cards

signal back_pressed

@onready var back_button: Button = $VBox/Header/BackButton
@onready var species_name_label: Label = $VBox/Header/SpeciesName
@onready var guidebook_text: RichTextLabel = $VBox/GuidebookPanel/GuidebookText
@onready var card_hand: HBoxContainer = $VBox/CardContainer/CardHand
@onready var empty_label: Label = $VBox/EmptyLabel

var bug_card_scene = preload("res://scenes/components/bug_card.tscn")
var current_species_id: String = ""

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

func setup(species_id: String) -> void:
	current_species_id = species_id
	
	var species = BugDatabase.get_bug(species_id)
	if species.is_empty():
		return
	
	# Set header
	species_name_label.text = species.name
	
	# Set guidebook text
	var description = species.get("description", "")
	if description.is_empty():
		description = species.get("fantasy", "A mysterious creature.")
	var real_hook = species.get("real_world_hook", "")
	
	guidebook_text.text = "[b]%s[/b]\n\n%s\n\n[i]Real-world: %s[/i]" % [
		species.name, description, real_hook
	]
	
	# Populate card hand
	_populate_cards()

func _populate_cards() -> void:
	# Clear existing cards
	for child in card_hand.get_children():
		child.queue_free()
	
	# Get all bugs of this species
	var bugs = GameManager.get_bugs_by_species(current_species_id)
	
	if bugs.is_empty():
		empty_label.visible = true
		return
	
	empty_label.visible = false
	
	# Create a card for each bug
	for bug in bugs:
		var card = bug_card_scene.instantiate()
		card.setup(bug)
		card_hand.add_child(card)

func _on_back_pressed() -> void:
	back_pressed.emit()
