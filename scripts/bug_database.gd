## BugDatabase
## Loads and provides access to bug species data from JSON
extends Node

const BUGS_PATH := "res://data/bugs.json"

var _data: Dictionary = {}
var _bugs: Array = []
var _bugs_by_id: Dictionary = {}

func _ready() -> void:
	load_bugs()

func load_bugs() -> void:
	var file := FileAccess.open(BUGS_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to load bugs.json")
		return
	
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("Failed to parse bugs.json: " + json.get_error_message())
		return
	
	_data = json.data
	_bugs = _data.get("bugs", [])
	
	# Index by ID for fast lookup
	for bug in _bugs:
		_bugs_by_id[bug.id] = bug
	
	print("Loaded %d bug species" % _bugs.size())

## Get all bug species
func get_all_bugs() -> Array:
	return _bugs

## Get a bug by ID
func get_bug(bug_id: String) -> Dictionary:
	return _bugs_by_id.get(bug_id, {})

## Get base stat value for a bug
func get_base_stat(bug_id: String, stat: String) -> int:
	var bug := get_bug(bug_id)
	if bug.is_empty():
		return 0
	return bug.get("base_stats", {}).get(stat, 0)

## Get all stat names
func get_stat_names() -> Array:
	return _data.get("meta", {}).get("stats", [])

## Get stat description
func get_stat_description(stat: String) -> String:
	return _data.get("meta", {}).get("stat_descriptions", {}).get(stat, "")

## Get bugs by role
func get_bugs_by_role(role: String) -> Array:
	var result := []
	for bug in _bugs:
		if role in bug.get("role", []):
			result.append(bug)
	return result
