extends Button

## Bug Rancher - Species Slot
## Shows a single species in the compendium grid

@onready var sprite: TextureRect = $VBox/SpriteContainer/Sprite
@onready var name_label: Label = $VBox/NameLabel
@onready var count_label: Label = $VBox/CountLabel
@onready var undiscovered: ColorRect = $Undiscovered

var species_data: Dictionary = {}
var species_id: String = ""

func setup(species: Dictionary) -> void:
	species_data = species
	species_id = species.id
	
	# Set name
	name_label.text = species.name
	
	# Generate placeholder sprite based on species
	_generate_sprite()
	
	# Update discovered state and count
	_update_discovered_state()
	update_count()

func _generate_sprite() -> void:
	# Create a simple colored sprite based on species role
	var img = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	
	var base_color: Color
	var roles = species_data.get("role", [])
	
	if "combat" in roles:
		base_color = Color(0.9, 0.3, 0.3)  # Red
	elif "carry" in roles:
		base_color = Color(0.3, 0.7, 0.3)  # Green
	elif "traversal" in roles:
		base_color = Color(0.3, 0.5, 0.9)  # Blue
	elif "starter" in roles:
		base_color = Color(0.6, 0.5, 0.4)  # Brown (isopod)
	else:
		base_color = Color(0.7, 0.7, 0.3)  # Yellow
	
	# Draw a simple bug shape
	for x in range(100):
		for y in range(100):
			var color = Color.TRANSPARENT
			
			# Body (oval)
			var body_center = Vector2(50, 55)
			var body_radius = Vector2(35, 40)
			var body_dist = pow((x - body_center.x) / body_radius.x, 2) + pow((y - body_center.y) / body_radius.y, 2)
			if body_dist < 1.0:
				color = base_color
			
			# Head (circle)
			var head_center = Vector2(50, 20)
			var head_radius = 18
			if (Vector2(x, y) - head_center).length() < head_radius:
				color = base_color.lightened(0.1)
			
			# Eyes
			var eye1 = Vector2(42, 18)
			var eye2 = Vector2(58, 18)
			if (Vector2(x, y) - eye1).length() < 4 or (Vector2(x, y) - eye2).length() < 4:
				color = Color.WHITE
			
			# Antennae
			if y < 15 and y > 5:
				if abs(x - 40 + (15 - y) * 0.5) < 2 or abs(x - 60 - (15 - y) * 0.5) < 2:
					color = base_color.darkened(0.2)
			
			img.set_pixel(x, y, color)
	
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex

func _update_discovered_state() -> void:
	var discovered = GameManager.is_species_discovered(species_id)
	undiscovered.visible = not discovered
	
	if discovered:
		modulate = Color.WHITE
	else:
		modulate = Color(0.5, 0.5, 0.5)

func update_count() -> void:
	var count = GameManager.get_bug_count(species_id)
	if count > 0:
		count_label.text = "×%d" % count
	else:
		count_label.text = ""
	
	_update_discovered_state()
