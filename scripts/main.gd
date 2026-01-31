extends Control

## Bug Rancher - Main Scene Controller
## Handles navigation between screens

@onready var screen_container: Control = $ScreenContainer
@onready var currency_label: Label = $Header/CurrencyLabel
@onready var compendium_btn: Button = $NavBar/CompendiumBtn
@onready var breeding_btn: Button = $NavBar/BreedingBtn
@onready var shop_btn: Button = $NavBar/ShopBtn

var compendium_scene = preload("res://scenes/compendium_screen.tscn")
var collection_scene = preload("res://scenes/collection_screen.tscn")
var breeding_scene = preload("res://scenes/breeding_screen.tscn")
var shop_scene = preload("res://scenes/shop_screen.tscn")

var current_screen: Control = null

func _ready() -> void:
	compendium_btn.pressed.connect(_on_compendium_pressed)
	breeding_btn.pressed.connect(_on_breeding_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	
	GameManager.currency_changed.connect(_update_currency)
	_update_currency(GameManager.get_currency())
	
	# Start on compendium
	_show_compendium()

func _update_currency(amount: int) -> void:
	currency_label.text = "💰 %d" % amount

func _clear_screen() -> void:
	if current_screen:
		current_screen.queue_free()
		current_screen = null

func _show_compendium() -> void:
	_clear_screen()
	current_screen = compendium_scene.instantiate()
	current_screen.species_selected.connect(_on_species_selected)
	screen_container.add_child(current_screen)

func _show_collection(species_id: String) -> void:
	_clear_screen()
	current_screen = collection_scene.instantiate()
	current_screen.setup(species_id)
	current_screen.back_pressed.connect(_on_collection_back)
	screen_container.add_child(current_screen)

func _on_species_selected(species_id: String) -> void:
	_show_collection(species_id)

func _on_collection_back() -> void:
	_show_compendium()

func _on_compendium_pressed() -> void:
	_show_compendium()

func _on_breeding_pressed() -> void:
	_show_breeding()

func _show_breeding() -> void:
	_clear_screen()
	current_screen = breeding_scene.instantiate()
	screen_container.add_child(current_screen)

func _on_shop_pressed() -> void:
	_show_shop()

func _show_shop() -> void:
	_clear_screen()
	current_screen = shop_scene.instantiate()
	screen_container.add_child(current_screen)
