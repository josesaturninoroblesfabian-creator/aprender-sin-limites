extends RefCounted

const Rules = preload("res://scripts/numbers/number_rules.gd")
const PATH := "res://data/numbers/activities.json"
const TOPICS := ["one_digit", "two_digits", "three_digits", "four_digits"]
const TITLES := {"one_digit": "Números de 1 cifra", "two_digits": "Números de 2 cifras", "three_digits": "Números de 3 cifras", "four_digits": "Números de 4 cifras", "count_objects": "El mercado de los números", "sequences": "El puente de las secuencias", "compare": "Mayor, menor o igual", "quick_challenge": "El tren de los números"}
const COLORS := {"one_digit": Color("#9e6309"), "two_digits": Color("#25834c"), "three_digits": Color("#8044ae"), "four_digits": Color("#b95a17"), "count_objects": Color("#25834c"), "sequences": Color("#087b9e"), "compare": Color("#ae336b"), "quick_challenge": Color("#6e4b9e")}
static var data: Dictionary = {}

static func load_data() -> Dictionary:
	if data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			data = parsed
			for lesson in data.lessons:
				for key in ["width", "tier", "model_number", "exchange_place"]: lesson[key] = int(lesson[key])
				for question in lesson.questions: _normalize(question)
			for question in data.sequences:
				for key in ["width", "step", "missing", "result"]: question[key] = int(question[key])
				question.terms = _ints(question.terms)
			for question in data.comparisons:
				for key in ["width", "left", "right"]: question[key] = int(question[key])
			data.market_totals = _ints(data.market_totals)
	return data

static func _ints(values: Array) -> Array[int]:
	var result: Array[int] = []
	for n in values: result.append(int(n))
	return result

static func _normalize(question: Dictionary) -> void:
	for key in ["number", "width", "place", "offset"]:
		if question.has(key): question[key] = int(question[key])
	if question.kind == "order":
		question.values = _ints(question.values)
		question.result = _ints(question.result)
	else: question.result = int(question.result)

static func lessons(topic: String = "") -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	for lesson in load_data().get("lessons", []):
		if topic.is_empty() or lesson.topic == topic: selected.append(lesson)
	return selected

static func find(id: String) -> Dictionary:
	for lesson in lessons():
		if lesson.id == id: return lesson
	return {}

static func games(kind: String, width: int) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	if kind == "train":
		for lesson in lessons(TOPICS[clampi(width - 1, 0, 3)]):
			for question in lesson.questions:
				if question.kind in ["read", "compose", "place", "neighbor"]: selected.append(question)
		for question in games("sequences", width):
			var item: Dictionary = question.duplicate(true)
			item.kind = "sequence"
			item.number = int(item.result)
			selected.append(item)
	else:
		for question in load_data().get(kind, []):
			if int(question.width) == width: selected.append(question)
	return selected
