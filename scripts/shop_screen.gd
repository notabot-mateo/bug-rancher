extends Control

## Bug Rancher - Shop Screen
## Sell bugs, buy upgrades, consumables, and cosmetics

@onready var balance_label: Label = $VBox/Header/BalanceLabel
@onready var sell_tab: Button = $VBox/TabBar/SellTab
@onready var buy_tab: Button = $VBox/TabBar/BuyTab
@onready var sell_panel: Panel = $VBox/SellPanel
@onready var buy_panel: Panel = $VBox/BuyPanel
@onready var bug_grid: GridContainer = $VBox/SellPanel/VBox/ScrollContainer/BugGrid
@onready var selected_label: Label = $VBox/SellPanel/VBox/SelectedPanel/HBox/SelectedInfo/SelectedLabel
@onready var total_label: Label = $VBox/SellPanel/VBox/SelectedPanel/HBox/SelectedInfo/TotalLabel
@onready var sell_button: Button = $VBox/SellPanel/VBox/SelectedPanel/HBox/SellButton

# Buy panel elements
@onready var upgrade_container: VBoxContainer = $VBox/BuyPanel/VBox/ScrollContainer/UpgradeContainer

## Price tiers by star rating
const PRICES := {
	1: 10,
	2: 25,
	3: 50,
	4: 100,
	5: 250
}
const HYBRID_BONUS := 1.5

var selected_bugs: Array = []
var bug_buttons: Dictionary = {}

func _ready() -> void:
	sell_tab.pressed.connect(_on_sell_tab)
	buy_tab.pressed.connect(_on_buy_tab)
	sell_button.pressed.connect(_on_sell_pressed)
	
	GameManager.currency_changed.connect(_update_balance)
	GameManager.collection_changed.connect(_refresh_bug_grid)
	Upgrades.upgrade_purchased.connect(_on_upgrade_purchased)
	Upgrades.daily_limits_reset.connect(_refresh_bug_grid)
	
	_update_balance(GameManager.get_currency())
	_refresh_bug_grid()
	_populate_buy_panel()

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
	_populate_buy_panel()

func _update_balance(amount: int) -> void:
	balance_label.text = "💰 %d" % amount

func _on_upgrade_purchased(_upgrade_id: String, _new_level: int) -> void:
	_update_balance(GameManager.get_currency())
	_populate_buy_panel()

# ============================================
# SELL PANEL
# ============================================

func _refresh_bug_grid() -> void:
	for child in bug_grid.get_children():
		child.queue_free()
	bug_buttons.clear()
	selected_bugs.clear()
	_update_selection_ui()
	
	var bugs = GameManager.get_all_bugs()
	for bug in bugs:
		var btn = _create_bug_button(bug)
		bug_grid.add_child(btn)
		bug_buttons[bug.id] = btn

func _create_bug_button(bug: Dictionary) -> Button:
	var btn = Button.new()
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(200, 120)
	
	var species = _get_species(bug.species_id)
	var stars = GameManager.calculate_quality_stars(bug.ivs)
	var price = calculate_price(bug)
	var is_hybrid = "_" in bug.species_id
	
	var display_name = bug.nickname if not bug.nickname.is_empty() else species.get("name", bug.species_id)
	
	# Daily limit info
	var sold_today = Upgrades.get_daily_sell_count(bug.species_id)
	var limit = Upgrades.get_daily_sell_limit(bug.species_id)
	var can_sell = Upgrades.can_sell_species_today(bug.species_id)
	
	var limit_text = "(%d/%d today)" % [sold_today, limit]
	var hybrid_tag = " 🧬" if is_hybrid else ""
	
	btn.text = "%s%s\n%s\n💰 %d\n%s" % [display_name, hybrid_tag, "⭐".repeat(stars), price, limit_text]
	
	if not can_sell:
		btn.disabled = true
		btn.modulate = Color(0.6, 0.6, 0.6)
	
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
	if "_" in bug.species_id:
		base_price = int(base_price * HYBRID_BONUS)
	
	# Cosmetic sell bonus
	var sell_bonus = Upgrades.get_sell_price_bonus()
	base_price = int(base_price * (1.0 + sell_bonus))
	
	return base_price

func _on_bug_toggled(pressed: bool, bug: Dictionary) -> void:
	if pressed:
		if not Upgrades.can_sell_species_today(bug.species_id):
			# Unpress immediately if limit reached
			bug_buttons[bug.id].button_pressed = false
			return
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
	sell_button.text = "💰 Sell for %d" % total if total > 0 else "💰 Sell"

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
	
	for bug_id in selected_bugs:
		var bug = _find_bug_by_id(bug_id)
		if not bug.is_empty():
			if Upgrades.can_sell_species_today(bug.species_id):
				total_earned += calculate_price(bug)
				Upgrades.record_sale(bug.species_id)
				GameManager.remove_bug_from_collection(bug_id)
				bugs_sold += 1
	
	GameManager.add_currency(total_earned)
	GameManager.save_game()
	
	selected_bugs.clear()
	_refresh_bug_grid()
	
	print("Sold %d bugs for %d gold!" % [bugs_sold, total_earned])

# ============================================
# BUY PANEL
# ============================================

func _populate_buy_panel() -> void:
	for child in upgrade_container.get_children():
		child.queue_free()
	
	# Section: Permanent Upgrades
	var upgrades_header = Label.new()
	upgrades_header.text = "⬆️ Permanent Upgrades"
	upgrades_header.add_theme_font_size_override("font_size", 20)
	upgrade_container.add_child(upgrades_header)
	
	var permanent = Upgrades.get_all_permanent_upgrades()
	for upgrade_id in permanent:
		var row = _create_upgrade_row(upgrade_id, permanent[upgrade_id])
		upgrade_container.add_child(row)
	
	upgrade_container.add_child(HSeparator.new())
	
	# Section: Consumables
	var consumables_header = Label.new()
	consumables_header.text = "🧪 Consumables"
	consumables_header.add_theme_font_size_override("font_size", 20)
	upgrade_container.add_child(consumables_header)
	
	var consumables = Upgrades.get_all_consumables()
	for item_id in consumables:
		var row = _create_consumable_row(item_id, consumables[item_id])
		upgrade_container.add_child(row)
	
	upgrade_container.add_child(HSeparator.new())
	
	# Section: Cosmetics
	var cosmetics_header = Label.new()
	cosmetics_header.text = "🎨 Cosmetics"
	cosmetics_header.add_theme_font_size_override("font_size", 20)
	upgrade_container.add_child(cosmetics_header)
	
	var cosmetics = Upgrades.get_all_cosmetics()
	for cosmetic_id in cosmetics:
		var row = _create_cosmetic_row(cosmetic_id, cosmetics[cosmetic_id])
		upgrade_container.add_child(row)

func _create_upgrade_row(upgrade_id: String, data: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size.y = 60
	
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	var level = Upgrades.get_upgrade_level(upgrade_id)
	var max_level = data.get("max_level", 1)
	name_label.text = "%s (Lv %d/%d)" % [data.get("name", upgrade_id), level, max_level]
	name_label.add_theme_font_size_override("font_size", 16)
	info.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = data.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.add_child(desc_label)
	
	row.add_child(info)
	
	var buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(120, 50)
	
	if level >= max_level:
		buy_btn.text = "MAX"
		buy_btn.disabled = true
	else:
		var price = Upgrades.get_upgrade_price(upgrade_id)
		buy_btn.text = "💰 %d" % price
		buy_btn.disabled = not Upgrades.can_purchase_upgrade(upgrade_id)
		buy_btn.pressed.connect(_on_buy_upgrade.bind(upgrade_id))
	
	row.add_child(buy_btn)
	
	return row

func _create_consumable_row(item_id: String, data: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size.y = 50
	
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	var owned = Upgrades.get_consumable_count(item_id)
	name_label.text = "%s (Owned: %d)" % [data.get("name", item_id), owned]
	name_label.add_theme_font_size_override("font_size", 16)
	info.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = data.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.add_child(desc_label)
	
	row.add_child(info)
	
	var buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(100, 40)
	var price = data.get("price", 0)
	buy_btn.text = "💰 %d" % price
	buy_btn.disabled = GameManager.get_currency() < price
	buy_btn.pressed.connect(_on_buy_consumable.bind(item_id))
	row.add_child(buy_btn)
	
	return row

func _create_cosmetic_row(cosmetic_id: String, data: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size.y = 50
	
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	var owned = Upgrades.owns_cosmetic(cosmetic_id)
	var status = " ✓" if owned else ""
	name_label.text = "%s%s" % [data.get("name", cosmetic_id), status]
	name_label.add_theme_font_size_override("font_size", 16)
	info.add_child(name_label)
	
	var desc_label = Label.new()
	var bonus = data.get("bonus")
	var bonus_text = ""
	if bonus:
		for key in bonus:
			bonus_text = "+%d%% %s" % [int(bonus[key] * 100), key.replace("_", " ")]
	desc_label.text = data.get("description", "") + (" | " + bonus_text if bonus_text else "")
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.add_child(desc_label)
	
	row.add_child(info)
	
	var buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(100, 40)
	
	if owned:
		buy_btn.text = "Owned"
		buy_btn.disabled = true
	else:
		var price = data.get("price", 0)
		buy_btn.text = "💰 %d" % price
		buy_btn.disabled = GameManager.get_currency() < price
		buy_btn.pressed.connect(_on_buy_cosmetic.bind(cosmetic_id))
	
	row.add_child(buy_btn)
	
	return row

func _on_buy_upgrade(upgrade_id: String) -> void:
	Upgrades.purchase_upgrade(upgrade_id)

func _on_buy_consumable(item_id: String) -> void:
	if Upgrades.purchase_consumable(item_id):
		_update_balance(GameManager.get_currency())
		_populate_buy_panel()

func _on_buy_cosmetic(cosmetic_id: String) -> void:
	if Upgrades.purchase_cosmetic(cosmetic_id):
		_update_balance(GameManager.get_currency())
		_populate_buy_panel()
