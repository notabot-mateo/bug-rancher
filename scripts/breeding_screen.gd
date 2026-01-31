extends Control

## Bug Rancher - Breeding Screen
## Handles parent selection, breeding preview, and egg incubation

signal breeding_complete(new_bug: Dictionary)

@onready var parent_a_sprite: TextureRect = $VBox/ParentSelection/ParentASlot/VBox/Sprite
@onready var parent_a_name: Label = $VBox/ParentSelection/ParentASlot/VBox/NameLabel
@onready var parent_a_stars: Label = $VBox/ParentSelection/ParentASlot/VBox/StarsLabel
@onready var parent_a_btn: Button = $VBox/ParentSelection/ParentASlot/VBox/SelectBtn

@onready var parent_b_sprite: TextureRect = $VBox/ParentSelection/ParentBSlot/VBox/Sprite
@onready var parent_b_name: Label = $VBox/ParentSelection/ParentBSlot/VBox/NameLabel
@onready var parent_b_stars: Label = $VBox/ParentSelection/ParentBSlot/VBox/StarsLabel
@onready var parent_b_btn: Button = $VBox/ParentSelection/ParentBSlot/VBox/SelectBtn

@onready var outcome_label: RichTextLabel = $VBox/PreviewPanel/VBox/OutcomeLabel
@onready var iv_floor_label: Label = $VBox/PreviewPanel/VBox/IVFloorLabel
@onready var breed_button: Button = $VBox/BreedButton

@onready var egg_timer_label: Label = $VBox/EggSlots/EggSlot1/VBox/TimerLabel
@onready var hatch_btn: Button = $VBox/EggSlots/EggSlot1/VBox/HatchBtn

@onready var bug_picker: Panel = $BugPicker
@onready var bug_grid: GridContainer = $BugPicker/VBox/ScrollContainer/BugGrid
@onready var picker_cancel: Button = $BugPicker/VBox/Header/CancelBtn

var parent_a: Dictionary = {}
var parent_b: Dictionary = {}
var selecting_for: String = ""  # "a" or "b"

var egg_data: Dictionary = {}
var egg_hatch_time: int = 0
const BASE_INCUBATION_SECONDS := 60  # 1 minute for testing

var hybrid_gen: HybridGenerator

func _ready() -> void:
	hybrid_gen = HybridGenerator.new()
	
	parent_a_btn.pressed.connect(_on_select_parent_a)
	parent_b_btn.pressed.connect(_on_select_parent_b)
	breed_button.pressed.connect(_on_breed_pressed)
	hatch_btn.pressed.connect(_on_hatch_pressed)
	picker_cancel.pressed.connect(_close_picker)
	
	_update_ui()

func _process(_delta: float) -> void:
	if not egg_data.is_empty():
		var now = int(Time.get_unix_time_from_system())
		var remaining = egg_hatch_time - now
		if remaining <= 0:
			egg_timer_label.text = "Ready!"
			hatch_btn.visible = true
		else:
			egg_timer_label.text = "%d:%02d" % [remaining / 60, remaining % 60]
			hatch_btn.visible = false

func _on_select_parent_a() -> void:
	selecting_for = "a"
	_show_picker()

func _on_select_parent_b() -> void:
	selecting_for = "b"
	_show_picker()

func _show_picker() -> void:
	# Populate with available bugs
	for child in bug_grid.get_children():
		child.queue_free()
	
	var bugs = GameManager.get_all_bugs()
	for bug in bugs:
		# Skip if already selected as the other parent
		if selecting_for == "a" and not parent_b.is_empty() and bug.id == parent_b.id:
			continue
		if selecting_for == "b" and not parent_a.is_empty() and bug.id == parent_a.id:
			continue
		
		var btn = Button.new()
		var species = BugDatabase.get_bug(bug.species_id)
		if species.is_empty() and hybrid_gen.is_hybrid(bug.species_id):
			species = hybrid_gen.get_hybrid(
				hybrid_gen.get_hybrid_parents(bug.species_id)[0],
				hybrid_gen.get_hybrid_parents(bug.species_id)[1]
			)
		
		var display_name = bug.nickname if not bug.nickname.is_empty() else species.get("name", bug.species_id)
		var stars = GameManager.calculate_quality_stars(bug.ivs)
		btn.text = "%s\n%s" % [display_name, "⭐".repeat(stars)]
		btn.custom_minimum_size = Vector2(200, 80)
		btn.pressed.connect(_on_bug_picked.bind(bug))
		bug_grid.add_child(btn)
	
	bug_picker.visible = true

func _close_picker() -> void:
	bug_picker.visible = false
	selecting_for = ""

func _on_bug_picked(bug: Dictionary) -> void:
	if selecting_for == "a":
		parent_a = bug
	elif selecting_for == "b":
		parent_b = bug
	
	_close_picker()
	_update_ui()

func _update_ui() -> void:
	# Parent A
	if parent_a.is_empty():
		parent_a_name.text = "Empty"
		parent_a_stars.text = ""
		parent_a_sprite.texture = null
	else:
		var species = _get_species(parent_a.species_id)
		var display_name = parent_a.nickname if not parent_a.nickname.is_empty() else species.get("name", "???")
		parent_a_name.text = display_name
		parent_a_stars.text = "⭐".repeat(GameManager.calculate_quality_stars(parent_a.ivs))
		parent_a_sprite.texture = _generate_bug_texture(species)
	
	# Parent B
	if parent_b.is_empty():
		parent_b_name.text = "Empty"
		parent_b_stars.text = ""
		parent_b_sprite.texture = null
	else:
		var species = _get_species(parent_b.species_id)
		var display_name = parent_b.nickname if not parent_b.nickname.is_empty() else species.get("name", "???")
		parent_b_name.text = display_name
		parent_b_stars.text = "⭐".repeat(GameManager.calculate_quality_stars(parent_b.ivs))
		parent_b_sprite.texture = _generate_bug_texture(species)
	
	# Preview
	if not parent_a.is_empty() and not parent_b.is_empty():
		_update_preview()
		breed_button.disabled = not egg_data.is_empty()
	else:
		outcome_label.text = "Select two bugs to see possible outcomes..."
		iv_floor_label.text = "IV Floor Bonus: --"
		breed_button.disabled = true

func _get_species(species_id: String) -> Dictionary:
	var species = BugDatabase.get_bug(species_id)
	if species.is_empty() and hybrid_gen.is_hybrid(species_id):
		var parents = hybrid_gen.get_hybrid_parents(species_id)
		species = hybrid_gen.get_hybrid(parents[0], parents[1])
	return species

func _update_preview() -> void:
	var species_a = _get_species(parent_a.species_id)
	var species_b = _get_species(parent_b.species_id)
	
	if parent_a.species_id == parent_b.species_id:
		outcome_label.text = "[b]Same Species[/b]\n100%% → %s" % species_a.name
	else:
		var hybrid_ab = hybrid_gen.get_hybrid(parent_a.species_id, parent_b.species_id)
		var hybrid_ba = hybrid_gen.get_hybrid(parent_b.species_id, parent_a.species_id)
		
		outcome_label.text = """[b]Cross-Species Breeding[/b]
25%% → %s (w/ %s colors)
25%% → %s (w/ %s colors)
50%% → Hybrid (%s or %s)""" % [
			species_a.name, species_b.name,
			species_b.name, species_a.name,
			hybrid_ab.name, hybrid_ba.name
		]
	
	# Calculate IV floor bonus
	var avg_iv_bonus = 0.0
	for stat in parent_a.ivs:
		var avg = (parent_a.ivs[stat] + parent_b.ivs.get(stat, 0)) / 2.0
		avg_iv_bonus += avg * 0.25
	avg_iv_bonus /= 8.0
	iv_floor_label.text = "IV Floor Bonus: +%.1f avg" % avg_iv_bonus

func _on_breed_pressed() -> void:
	if parent_a.is_empty() or parent_b.is_empty():
		return
	
	# Get upgrade bonuses
	var hybrid_bonus = Upgrades.get_hybrid_chance_bonus()
	var iv_bonus = Upgrades.get_iv_floor_bonus()
	var speed_mult = Upgrades.get_incubation_multiplier()
	
	# Determine offspring (with hybrid chance bonus)
	var outcome: Dictionary
	if hybrid_gen.is_hybrid(parent_a.species_id) or hybrid_gen.is_hybrid(parent_b.species_id):
		outcome = hybrid_gen.roll_hybrid_breeding_outcome(parent_a.species_id, parent_b.species_id)
	else:
		outcome = _roll_breeding_with_bonus(parent_a.species_id, parent_b.species_id, hybrid_bonus)
	
	# Create egg data (store IV bonus for hatching)
	egg_data = {
		"species_id": outcome.species_id,
		"color_source": outcome.get("color_source", outcome.species_id),
		"parent_a_ivs": parent_a.ivs.duplicate(),
		"parent_b_ivs": parent_b.ivs.duplicate(),
		"outcome_type": outcome.type,
		"iv_bonus": iv_bonus  # Apply when hatching
	}
	
	# Calculate incubation time with speed bonus
	var incubation_time = int(BASE_INCUBATION_SECONDS * speed_mult)
	egg_hatch_time = int(Time.get_unix_time_from_system()) + incubation_time
	
	egg_timer_label.text = "Incubating..."
	breed_button.disabled = true
	
	# Clear parents
	parent_a = {}
	parent_b = {}
	_update_ui()

func _roll_breeding_with_bonus(species_a: String, species_b: String, hybrid_bonus: float) -> Dictionary:
	if species_a == species_b:
		return { "type": "same", "species_id": species_a }
	
	# Base hybrid chance is 50%, add bonus
	var hybrid_chance = 0.50 + hybrid_bonus
	var base_chance = (1.0 - hybrid_chance) / 2.0  # Split remaining between A and B
	
	var roll = randf()
	
	if roll < base_chance:
		return { 
			"type": "dominant_a", 
			"species_id": species_a,
			"color_source": species_b
		}
	elif roll < base_chance * 2:
		return {
			"type": "dominant_b",
			"species_id": species_b,
			"color_source": species_a
		}
	else:
		var hybrid_id: String
		if randf() < 0.5:
			hybrid_id = "%s_%s" % [species_a, species_b]
		else:
			hybrid_id = "%s_%s" % [species_b, species_a]
		return {
			"type": "hybrid",
			"species_id": hybrid_id,
			"color_source": "blended"
		}

func _on_hatch_pressed() -> void:
	if egg_data.is_empty():
		return
	
	# Create the new bug with inherited IVs (including any IV bonus)
	var iv_bonus = egg_data.get("iv_bonus", 0.0)
	var new_bug = GameManager.create_bred_bug_with_bonus(
		egg_data.species_id,
		egg_data.parent_a_ivs,
		egg_data.parent_b_ivs,
		iv_bonus
	)
	new_bug["color_source"] = egg_data.color_source
	
	GameManager.add_bug_to_collection(new_bug)
	
	# Clear egg
	egg_data = {}
	egg_hatch_time = 0
	egg_timer_label.text = "Empty"
	hatch_btn.visible = false
	
	_update_ui()
	
	# Show what hatched
	var species = _get_species(new_bug.species_id)
	var stars = GameManager.calculate_quality_stars(new_bug.ivs)
	outcome_label.text = "[b]🎉 Hatched![/b]\n%s (%s)" % [species.name, "⭐".repeat(stars)]

func _generate_bug_texture(species: Dictionary) -> ImageTexture:
	var img = Image.create(120, 120, false, Image.FORMAT_RGBA8)
	
	var base_color: Color
	var roles = species.get("role", [])
	
	if "combat" in roles:
		base_color = Color(0.9, 0.3, 0.3)
	elif "carry" in roles:
		base_color = Color(0.3, 0.7, 0.3)
	elif "traversal" in roles:
		base_color = Color(0.3, 0.5, 0.9)
	elif "starter" in roles:
		base_color = Color(0.6, 0.5, 0.4)
	elif species.get("is_hybrid", false):
		base_color = Color(0.8, 0.5, 0.8)  # Purple for hybrids
	else:
		base_color = Color(0.7, 0.7, 0.3)
	
	for x in range(120):
		for y in range(120):
			var color = Color.TRANSPARENT
			var body_center = Vector2(60, 70)
			var body_radius = Vector2(40, 45)
			var body_dist = pow((x - body_center.x) / body_radius.x, 2) + pow((y - body_center.y) / body_radius.y, 2)
			if body_dist < 1.0:
				color = base_color
			var head_center = Vector2(60, 30)
			if (Vector2(x, y) - head_center).length() < 20:
				color = base_color.lightened(0.1)
			img.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(img)
