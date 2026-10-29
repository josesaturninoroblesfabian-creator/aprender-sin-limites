extends RefCounted

const Store = preload("res://scripts/storage/progress_store.gd")
const Catalog = preload("res://scripts/math/activity_catalog.gd")
const PATH := "user://progreso_matematicas.cfg"
const SECTION := "aventura_v1"

static func records(key: String) -> Dictionary:
	var value: Variant = Store.read(PATH).get_value(SECTION, key, {})
	return value.duplicate(true) if value is Dictionary else {}

static func _write(key: String, value: Dictionary) -> Error:
	var config := Store.read(PATH)
	config.set_value(SECTION, key, value)
	return Store.write(config, PATH)

static func is_complete(id: String) -> bool:
	if Catalog.find(id).is_empty():
		return false
	var value: Variant = Store.read(PATH).get_value("progreso", "actividades", {})
	return value is Dictionary and value.get(id, false) == true

static func lesson_stars(id: String) -> int:
	var value: Variant = records("lessons").get(id, {})
	return clampi(int(value.get("stars", 0)), 0, 3) if value is Dictionary else 0

static func resume(id: String) -> Dictionary:
	var lesson := Catalog.find(id)
	var value: Variant = records("resume").get(id, {})
	if lesson.is_empty() or not value is Dictionary:
		return {}
	var stored_answers: Variant = value.get("answers", {})
	if not stored_answers is Dictionary: stored_answers = {}
	var cleaned: Dictionary = {}
	for question in lesson.questions:
		var entry: Variant = stored_answers.get(question.id, {})
		if entry is Dictionary and int(entry.get("answer", -1)) == int(question.result):
			cleaned[question.id] = {"answer": int(question.result), "first": entry.get("first", false) == true}
	var mistakes := _attempt_ids(value.get("mistakes", []), lesson)
	var hints := _attempt_ids(value.get("hinted", []), lesson)
	return {"answers": cleaned, "mistakes": mistakes, "hinted": hints} if (not cleaned.is_empty() or not mistakes.is_empty() or not hints.is_empty()) and cleaned.size() <= 6 else {}

static func _attempt_ids(value: Variant, lesson: Dictionary) -> Array:
	var valid: Array = []
	if value is Array:
		for question in lesson.questions:
			if question.id in value: valid.append(question.id)
	return valid

static func save_resume(id: String, answers: Dictionary, mistakes: Array = [], hinted: Array = []) -> Error:
	if Catalog.find(id).is_empty():
		return ERR_INVALID_PARAMETER
	var saved := records("resume")
	saved[id] = {"answers": answers.duplicate(true), "mistakes": mistakes.duplicate(), "hinted": hinted.duplicate()}
	return _write("resume", saved)

static func complete_lesson(id: String, answers: Dictionary) -> Error:
	var lesson := Catalog.find(id)
	if lesson.is_empty() or answers.size() != 6:
		return ERR_INVALID_PARAMETER
	var first := 0
	for question in lesson.questions:
		var record: Variant = answers.get(question.id, {})
		if not record is Dictionary or int(record.get("answer", -1)) != int(question.result):
			return ERR_INVALID_DATA
		first += 1 if record.get("first", false) == true else 0
	var stars := 3 if first == 6 else (2 if first >= 4 else 1)
	var config := Store.read(PATH)
	var old: Variant = config.get_value("progreso", "actividades", {})
	var activities: Dictionary = old.duplicate(true) if old is Dictionary else {}
	activities[id] = true
	config.set_value("progreso", "actividades", activities)
	var data := records("lessons")
	data[id] = {"stars": maxi(lesson_stars(id), stars)}
	config.set_value(SECTION, "lessons", data)
	var partial := records("resume")
	partial.erase(id)
	config.set_value(SECTION, "resume", partial)
	return Store.write(config, PATH)

static func game_record(id: String) -> Dictionary:
	var value: Variant = records("games").get(id, {})
	return value if value is Dictionary else {}

static func finish_game(id: String, score: int, stars: int, solved: int) -> Error:
	if id not in ["count_objects", "solve_exercises", "quick_challenge"] or solved < 1 or score < 0:
		return ERR_INVALID_PARAMETER
	if (id == "count_objects" and solved != 8) or (id == "solve_exercises" and solved != 10):
		return ERR_INVALID_DATA
	var data := records("games")
	var old := game_record(id)
	data[id] = {"score": maxi(int(old.get("score", 0)), mini(score, 1000)), "stars": maxi(int(old.get("stars", 0)), clampi(stars, 1, 3))}
	return _write("games", data)

static func level_record(level: int) -> Dictionary:
	var value: Variant = records("levels").get(str(level), {})
	return value if value is Dictionary else {}

static func level_unlocked(level: int) -> bool:
	return level == 0 or (level > 0 and level < 12 and level_record(level - 1).get("complete", false) == true)

static func complete_level(level: int, answers: Dictionary, collected: Array, reached_goal: bool) -> Error:
	if not level_unlocked(level) or not reached_goal or answers.size() != 3:
		return ERR_INVALID_DATA
	var first := 0
	for question in Catalog.level_questions(level):
		var value: Variant = answers.get(question.id, {})
		if not value is Dictionary or int(value.get("answer", -1)) != int(question.result):
			return ERR_INVALID_DATA
		first += 1 if value.get("first", false) == true else 0
	var unique: Dictionary = {}
	for star in collected:
		if int(star) >= 0 and int(star) < 5:
			unique[int(star)] = true
	var stars := 1 + (1 if unique.size() >= 3 else 0) + (1 if first == 3 else 0)
	var data := records("levels")
	data[str(level)] = {"complete": true, "stars": maxi(int(level_record(level).get("stars", 0)), stars)}
	var partial := records("routes")
	partial.erase(str(level))
	var config := Store.read(PATH)
	config.set_value(SECTION, "levels", data)
	config.set_value(SECTION, "routes", partial)
	return Store.write(config, PATH)

static func save_route(level: int, state: Dictionary) -> Error:
	if not level_unlocked(level):
		return ERR_INVALID_DATA
	var data := records("routes")
	data[str(level)] = state.duplicate(true)
	return _write("routes", data)

static func route(level: int) -> Dictionary:
	var value: Variant = records("routes").get(str(level), {})
	return value.duplicate(true) if value is Dictionary else {}

static func totals() -> Dictionary:
	var completed := 0
	var stars := 0
	for lesson in Catalog.all_lessons():
		completed += 1 if is_complete(lesson.id) else 0
		stars += lesson_stars(lesson.id)
	var paths := 0
	for level in range(12):
		paths += 1 if level_record(level).get("complete", false) else 0
	return {"lessons": completed, "stars": stars, "paths": paths}
