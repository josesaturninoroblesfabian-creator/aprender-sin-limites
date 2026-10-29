extends RefCounted

const Shapes = preload("res://scripts/geometry/geometry_shapes.gd")
const TOPICS := ["flat_shapes", "solid_shapes", "sides_vertices", "shape_patterns"]
const TITLES := {"flat_shapes": "Figuras planas", "solid_shapes": "Cuerpos geométricos", "sides_vertices": "Lados y vértices", "shape_patterns": "Patrones y formas", "find_shape": "Safari de las formas", "build_pattern": "El telar de los patrones", "count_sides": "Taller de contornos", "quick_challenge": "El globo explorador"}
const COLORS := {"flat_shapes": Color("#a46709"), "solid_shapes": Color("#25834c"), "sides_vertices": Color("#8044ae"), "shape_patterns": Color("#ae5617"), "find_shape": Color("#25834c"), "build_pattern": Color("#087b9e"), "count_sides": Color("#ae336b"), "quick_challenge": Color("#6e4b9e")}
static var data: Dictionary = {}

static func load_data() -> Dictionary:
	if data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/geometry/activities.json"))
		if parsed is Dictionary:
			data = parsed
			for lesson in data.lessons:
				lesson.tier = int(lesson.tier)
				_normalize(lesson.model)
				for question in lesson.questions: _normalize(question)
			for pool in data.games.values():
				for question in pool: _normalize(question)
	return data

static func _normalize(q: Dictionary) -> void:
	for key in ["angle", "difficulty", "unit_size"]:
		if q.has(key): q[key] = int(q[key])
	if q.has("holes"):
		for i in range(q.holes.size()): q.holes[i] = int(q.holes[i])
	if q.kind == "count": q.result = int(q.result)
	if q.kind == "find":
		for i in range(q.result.size()): q.result[i] = int(q.result[i])

static func lessons(topic: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for lesson in load_data().get("lessons", []):
		if topic.is_empty() or lesson.topic == topic: result.append(lesson)
	return result

static func find(id: String) -> Dictionary:
	for lesson in lessons():
		if lesson.id == id: return lesson
	return {}

static func games(topic: String, difficulty: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if topic == "quick_challenge":
		for q in load_data().get("games", {}).get(topic, []):
			if int(q.difficulty) <= difficulty: result.append(q.duplicate(true))
	else:
		for q in load_data().get("games", {}).get(topic, []):
			if int(q.difficulty) == difficulty: result.append(q.duplicate(true))
	return result
