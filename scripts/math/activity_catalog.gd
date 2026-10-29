extends RefCounted

const Rules = preload("res://scripts/math/math_rules.gd")
const PATH := "res://data/math/activities.json"
const OPERATIONS := ["addition", "subtraction", "multiplication", "division"]
const TITLES := {"addition": "Suma", "subtraction": "Resta", "multiplication": "Multiplicación", "division": "División", "count_objects": "Contar objetos", "solve_exercises": "Resolver ejercicios", "level_game": "Aventura por los Andes", "quick_challenge": "Fiesta de globos"}
const COLORS := {"addition": Color("#9d5708"), "subtraction": Color("#20864c"), "multiplication": Color("#8041b6"), "division": Color("#087ab1"), "count_objects": Color("#288445"), "solve_exercises": Color("#116faf"), "level_game": Color("#96590c"), "quick_challenge": Color("#b72b6e")}
static var lessons: Array[Dictionary] = []

static func all_lessons() -> Array[Dictionary]:
	if lessons.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			for item in parsed.get("lessons", []):
				item.tier = int(item.tier)
				_normalize_question(item.model)
				for question in item.questions:
					_normalize_question(question)
				lessons.append(item)
	return lessons

static func _normalize_question(question: Dictionary) -> void:
	for key in ["a", "b", "result"]:
		question[key] = int(question[key])

static func find(id: String) -> Dictionary:
	for lesson in all_lessons():
		if lesson.id == id:
			return lesson
	return {}

static func for_topic(topic: String) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	for lesson in all_lessons():
		if lesson.topic == topic:
			selected.append(lesson)
	return selected

static func pool(operations: Array, difficulty: int = 1) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	for lesson in all_lessons():
		if lesson.topic in operations and (lesson.tier <= 2 if difficulty == 1 else (lesson.tier <= 3 if difficulty == 2 else true)):
			for question in lesson.questions:
				selected.append(question)
	return selected

static func level_questions(level: int) -> Array[Dictionary]:
	if level < 0 or level >= 12:
		return []
	var topic: String = OPERATIONS[level / 3]
	var tier: int = [1, 3, 4][level % 3]
	var lesson := find("%s_%d" % [topic, tier])
	var selected: Array[Dictionary] = []
	for offset in range(3):
		selected.append(lesson.questions[(level % 3 + offset) % 6])
	return selected
