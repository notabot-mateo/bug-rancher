extends Control

## Bug Rancher - Shop Screen
## Buy items, sell bugs for currency

@onready var balance_label: Label = $VBox/Header/BalanceLabel
@onready var sell_tab: Button = $VBox/TabBar/SellTab
@onready var buy_tab: Button = $VBox/TabBar/BuyTab
@onready var sell_panel: Panel = $VBox/SellPanel
@onready var buy_panel: Panel = $VBox/BuyPanel
@onready var bug_grid: GridContainer = $VBox/SellPanel/VBox/ScrollContainer/BugGrid
@onready var selected_label: Label = $VBox/SellPanel/VBox/SelectedPanel/HBox/SelectedInfo/SelectedLabel
@onready var total_label: Label = $VBox/SellPanel/VBox/SelectedPanel/HBox/SelectedInfo/TotalLabel
@onready var sell_button: Button = $VBox/SellPanel/VBox/SelectedPanel/HBox/SellButton

## Price tiers by star rating
const PRICES := {
	1: 10,
	2: 25,
	3: 50,
	4: 100,
	5: 250
}
const HYBRID_BONUS := 1.5  # 50% more for hybrids

var selected_bugs: Array = []  # Array of bug IDs to sell
var bug_buttons: Dictionary = {}  # bug_id -> Button

func _ready() -> void:
	sell_tab.pressed.connect(_on_sell_tab)
	buy_tab.pressed.connect(_on_buy_tab)
	sell_button.pressed.connect(_on_sell_pressed)
	
	GameManager.currency_changed.connect(_update_balance)
	GameManager.collection_changed.connect(_refresh_bug_grid)
	
	_update_balance(GameManager.get_currency())
	_refresh_bug_grid()

func _on_sell_tab() -> void:
	sell_tab.button_pressed = true
	buy_tab.button_pressed = false
	sell_panel.visible = true
	buy_panel.visible = false

func _on_buy_tab() -> void:
	sell_tab.button_pressed = false
	buy_tab.button_pressed = true
	sell_panel.visible = false
	buy_panel.visible = true

func _update_balance(amount: int) -> void:
	balance_label.text = "💰 %d" % amount

func _refresh_bug_grid() -> void:
	# Clear existing
	for child in bug_grid.get_children():
		child.queue_free()
	bug_buttons.clear()
	selected_bugs.clear()
	_update_selection_ui()
	
	# Populate with owned bugs
	var bugs = GameManager.get_all_bugs()
	for bug in bugs:
		var btn = _create_bug_button(bug)
		bug_grid.add_child(btn)
		bug_buttons[bug.id] = btn

func _create_bug_button(bug: Dictionary) -> Button:
	var btn = Button.new()
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(200, 100)
	
	var species = _get_species(bug.species_id)
	var stars = GameManager.calculate_quality_stars(bug.ivs)
	var price = calculate_price(bug)
	var is_hybrid = "_" in bug.species_id
	
	var display_name = bug.nickname if not bug.nickname.is_empty() else species.get("name", bug.species_id)
	
	var hybrid_tag = " [HYBRID]" if is_hybrid else ""
	btn.text = "%s%s\n%s\n💰 %d" % [display_name, hybrid_tag, "⭐".repeat(stars), price]
	
	btn.toggled.connect(_on_bug_toggled.bind(bug))
	
	return btn

func _get_species(species_id: String) -> Dictionary:
	var species = BugDatabase.get_bug(species_id)
	if species.is_empty() and "_" in species_id:
		var parts = species_id.split("_")
		if parts.size() >= 2:
			species = HybridGen.get_hybrid(parts[0], parts[1])
	return species

func calculate_price(bug: Dictionary) -> int:
	var stars = GameManager.calculate_quality_stars(bug.ivs)
	var base_price = PRICES.get(stars, 10)
	
	# Hybrid bonus
	var is_hybrid = "_" in bug.species_id
	if is_hybrid:
		base_price = int(base_price * HYBRID_BONUS)
	
	return base_price

func _on_bug_toggled(pressed: bool, bug: Dictionary) -> void:
	if pressed:
		if bug.id not in selected_bugs:
			selected_bugs.append(bug.id)
	else:
		selected_bugs.erase(bug.id)
	
	_update_selection_ui()

func _update_selection_ui() -> void:
	var total = 0
	for bug_id in selected_bugs:
		var bug = _find_bug_by_id(bug_id)
		if not bug.is_empty():
			total += calculate_price(bug)
	
	selected_label.text = "Selected: %d bug%s" % [selected_bugs.size(), "s" if selected_bugs.size() != 1 else ""]
	total_label.text = "Total: 💰 %d" % total
	sell_button.disabled = selected_bugs.is_empty()
	sell_button.text = "💰 Sell for %d" % total if total > 0 else "💰 Sell All"

func _find_bug_by_id(bug_id: String) -> Dictionary:
	for bug in GameManager.get_all_bugs():
		if bug.id == bug_id:
			return bug
	return {}

func _on_sell_pressed() -> void:
	if selected_bugs.is_empty():
		return
	
	var total_earned = 0
	var bugs_sold = 0
	
	# Calculate total and remove bugs
	for bug_id in selected_bugs:
		var bug = _find_bug_by_id(bug_id)
		if not bug.is_empty():
			total_earned += calculate_price(bug)
			GameManager.remove_bug_from_collection(bug_id)
			bugs_sold += 1
	
	# Add currency
	GameManager.add_currency(total_earned)
	GameManager.save_game()
	
	# Clear selection and refresh
	selected_bugs.clear()
	_refresh_bug_grid()
	
	# Show feedback
	print("Sold %d bugs for %d gold!" % [bugs_sold, total_earned])
