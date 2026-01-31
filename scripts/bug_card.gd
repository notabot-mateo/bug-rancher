extends Control

## Bug Rancher - Bug Card
## A flippable card showing a single bug's info

@onready var card_base: Panel = $CardBase
@onready var front: Control = $CardBase/Front
@onready var back: Control = $CardBase/Back
@onready var sprite: TextureRect = $CardBase/Front/VBox/SpriteContainer/Sprite
@onready var name_label: Label = $CardBase/Front/VBox/NameLabel
@onready var nickname_label: Label = $CardBase/Front/VBox/NicknameLabel
@onready var stars_label: Label = $CardBase/Front/VBox/StarsLabel
@onready var top_stat_label: Label = $CardBase/Front/VBox/TopStatLabel
@onready var stats_container: VBoxContainer = $CardBase/Back/VBox/StatsContainer
@onready var back_header: Label = $CardBase/Back/VBox/HeaderLabel

var bug_data: Dictionary = {}
var species_data: Dictionary = {}
var is_flipped: bool = false

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func setup(bug: Dictionary) -> void:
	bug_data = bug
	species_data = BugDatabase.get_bug(bug.species_id)
	
	# Front side
	name_label.text = species_data.name
	
	if bug.nickname.is_empty():
		nickname_label.visible = false
	else:
		nickname_label.text = "\"%s\"" % bug.nickname
		nickname_label.visible = true
	
	# Stars
	var stars = GameManager.calculate_quality_stars(bug.ivs)
	stars_label.text = "⭐".repeat(stars)
	
	# Top stat
	var top_stat = GameManager.get_highest_stat(bug)
	var top_value = _calculate_stat(top_stat)
	top_stat_label.text = "Best: %s %d" % [top_stat, top_value]
	
	# Generate sprite
	_generate_sprite()
	
	# Back side - stat breakdown
	_populate_stats()

func _calculate_stat(stat: String) -> int:
	var base = species_data.base_stats.get(stat, 10)
	var iv = bug_data.ivs.get(stat, 0)
	var ev = bug_data.evs.get(stat, 0)
	return base + iv + int(ev / 4.0)

func _generate_sprite() -> void:
	var img = Image.create(150, 150, false, Image.FORMAT_RGBA8)
	
	var base_color: Color
	var roles = species_data.get("role", [])
	
	if "combat" in roles:
		base_color = Color(0.9, 0.3, 0.3)
	elif "carry" in roles:
		base_color = Color(0.3, 0.7, 0.3)
	elif "traversal" in roles:
		base_color = Color(0.3, 0.5, 0.9)
	elif "starter" in roles:
		base_color = Color(0.6, 0.5, 0.4)
	else:
		base_color = Color(0.7, 0.7, 0.3)
	
	# Tint based on quality
	var stars = GameManager.calculate_quality_stars(bug_data.ivs)
	if stars >= 4:
		base_color = base_color.lightened(0.2)
	
	# Draw bug shape
	for x in range(150):
		for y in range(150):
			var color = Color.TRANSPARENT
			
			var body_center = Vector2(75, 85)
			var body_radius = Vector2(50, 55)
			var body_dist = pow((x - body_center.x) / body_radius.x, 2) + pow((y - body_center.y) / body_radius.y, 2)
			if body_dist < 1.0:
				color = base_color
			
			var head_center = Vector2(75, 35)
			var head_radius = 25
			if (Vector2(x, y) - head_center).length() < head_radius:
				color = base_color.lightened(0.1)
			
			var eye1 = Vector2(63, 32)
			var eye2 = Vector2(87, 32)
			if (Vector2(x, y) - eye1).length() < 5 or (Vector2(x, y) - eye2).length() < 5:
				color = Color.WHITE
			
			if y < 20 and y > 5:
				if abs(x - 60 + (20 - y) * 0.6) < 3 or abs(x - 90 - (20 - y) * 0.6) < 3:
					color = base_color.darkened(0.2)
			
			img.set_pixel(x, y, color)
	
	sprite.texture = ImageTexture.create_from_image(img)

func _populate_stats() -> void:
	for child in stats_container.get_children():
		child.queue_free()
	
	var stat_descs = BugDatabase.get_stat_descriptions()
	
	for stat in ["VIT", "STR", "CAR", "SPC", "SPD", "STA", "INS", "ADP"]:
		var hbox = HBoxContainer.new()
		
		var stat_label = Label.new()
		stat_label.text = stat
		stat_label.custom_minimum_size.x = 40
		stat_label.add_theme_font_size_override("font_size", 14)
		hbox.add_child(stat_label)
		
		var base = species_data.base_stats.get(stat, 10)
		var iv = bug_data.ivs.get(stat, 0)
		var ev = bug_data.evs.get(stat, 0)
		var total = base + iv + int(ev / 4.0)
		
		# Progress bar for stat
		var bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(100, 16)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.max_value = 50  # Reasonable max for display
		bar.value = total
		bar.show_percentage = false
		hbox.add_child(bar)
		
		var value_label = Label.new()
		value_label.text = "%d" % total
		value_label.custom_minimum_size.x = 30
		value_label.add_theme_font_size_override("font_size", 14)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(value_label)
		
		# IV indicator
		var iv_label = Label.new()
		iv_label.text = "(+%d)" % iv
		iv_label.add_theme_font_size_override("font_size", 11)
		iv_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5) if iv >= 20 else Color(0.6, 0.6, 0.6))
		hbox.add_child(iv_label)
		
		stats_container.add_child(hbox)
	
	# Add total IV quality
	var total_iv = 0
	for stat in bug_data.ivs:
		total_iv += bug_data.ivs[stat]
	var iv_percent = int(float(total_iv) / (31 * 8) * 100)
	
	var quality_label = Label.new()
	quality_label.text = "IV Quality: %d%%" % iv_percent
	quality_label.add_theme_font_size_override("font_size", 14)
	quality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(quality_label)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_flip_card()

func _flip_card() -> void:
	is_flipped = not is_flipped
	
	# Animate flip
	var tween = create_tween()
	tween.tween_property(card_base, "scale:x", 0.0, 0.15)
	tween.tween_callback(_swap_sides)
	tween.tween_property(card_base, "scale:x", 1.0, 0.15)

func _swap_sides() -> void:
	front.visible = not is_flipped
	back.visible = is_flipped
