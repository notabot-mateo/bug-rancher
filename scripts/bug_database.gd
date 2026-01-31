extends Node

## Bug Rancher - Bug Database
## Loads and provides access to bug species data

var _data: Dictionary = {}
var _bugs: Array = []

func _ready() -> void:
	_load_database()

func _load_database() -> void:
	var file = FileAccess.open("res://data/bugs.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		if error == OK:
			_data = json.data
			_bugs = _data.get("bugs", [])
			print("BugDatabase: Loaded ", _bugs.size(), " species")
		else:
			push_error("Failed to parse bugs.json")
	else:
		push_error("Failed to open bugs.json")

func get_all_bugs() -> Array:
	return _bugs

func get_all_species_ids() -> Array:
	var ids = []
	for bug in _bugs:
		ids.append(bug.id)
	return ids

func get_bug(species_id: String) -> Dictionary:
	for bug in _bugs:
		if bug.id == species_id:
			return bug
	return {}

func get_base_stat(species_id: String, stat: String) -> int:
	var bug = get_bug(species_id)
	if bug.is_empty():
		return 0
	return bug.base_stats.get(stat, 0)

func get_bugs_by_role(role: String) -> Array:
	var result = []
	for bug in _bugs:
		if role in bug.get("role", []):
			result.append(bug)
	return result

func get_stat_descriptions() -> Dictionary:
	return _data.get("meta", {}).get("stat_descriptions", {})

func get_species_count() -> int:
	return _bugs.size()
