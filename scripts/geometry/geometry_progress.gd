extends RefCounted

const Store = preload("res://scripts/storage/progress_store.gd")
const Catalog = preload("res://scripts/geometry/geometry_catalog.gd")
const Rules = preload("res://scripts/geometry/geometry_rules.gd")
const PATH := "user://progreso_geometria.cfg"
const SECTION := "exploracion_v1"

static func records(key: String) -> Dictionary:
	var value: Variant = Store.read(PATH).get_value(SECTION, key, {})
	return value.duplicate(true) if value is Dictionary else {}

static func complete(id: String) -> bool:
	if Catalog.find(id).is_empty(): return false
	var value: Variant = Store.read(PATH).get_value("progreso", "actividades", {})
	return value is Dictionary and value.get(id, false) == true

static func stars(id: String) -> int:
	var value: Variant = records("lessons").get(id, {})
	return clampi(int(value.get("stars", 0)), 0, 3) if value is Dictionary else 0

static func resume(id: String) -> Dictionary:
	var lesson := Catalog.find(id)
	var value: Variant = records("resume").get(id, {})
	if lesson.is_empty() or not value is Dictionary: return {}
	var raw: Variant = value.get("answers", {})
	if not raw is Dictionary: raw = {}
	var answers := {}
	var wrong: Array = []
	var hinted: Array = []
	for q in lesson.questions:
		var record: Variant = raw.get(q.id, {})
		if record is Dictionary and Rules.matches(q, record.get("answer")): answers[q.id] = {"answer": q.result, "first": record.get("first", false) == true}
		if value.get("wrong", []) is Array and q.id in value.get("wrong", []): wrong.append(q.id)
		if value.get("hinted", []) is Array and q.id in value.get("hinted", []): hinted.append(q.id)
	var draft: Variant = value.get("draft", {})
	if not draft is Dictionary: draft = {}
	return {"answers": answers, "wrong": wrong, "hinted": hinted, "draft": draft} if not answers.is_empty() or not wrong.is_empty() or not hinted.is_empty() or not draft.is_empty() else {}

static func save_resume(id: String, answers: Dictionary, wrong: Array, hinted: Array, draft: Dictionary = {}) -> Error:
	if Catalog.find(id).is_empty(): return ERR_INVALID_PARAMETER
	var data := records("resume")
	data[id] = {"answers": answers.duplicate(true), "wrong": wrong.duplicate(), "hinted": hinted.duplicate(), "draft": draft.duplicate(true)}
	var config := Store.read(PATH)
	config.set_value(SECTION, "resume", data)
	return Store.write(config, PATH)

static func finish_lesson(id: String, answers: Dictionary) -> Error:
	var lesson := Catalog.find(id)
	if lesson.is_empty() or answers.size() != 5: return ERR_INVALID_DATA
	var first := 0
	for q in lesson.questions:
		var record: Variant = answers.get(q.id, {})
		if not record is Dictionary or not Rules.matches(q, record.get("answer")): return ERR_INVALID_DATA
		first += 1 if record.get("first", false) == true else 0
	var config := Store.read(PATH)
	var value: Variant = config.get_value("progreso", "actividades", {})
	var completed: Dictionary = value.duplicate(true) if value is Dictionary else {}
	completed[id] = true
	config.set_value("progreso", "actividades", completed)
	var lessons := records("lessons")
	lessons[id] = {"stars": maxi(stars(id), 3 if first == 5 else 2 if first >= 3 else 1)}
	config.set_value(SECTION, "lessons", lessons)
	var partial := records("resume")
	partial.erase(id)
	config.set_value(SECTION, "resume", partial)
	return Store.write(config, PATH)

static func game_record(topic: String, difficulty: int) -> Dictionary:
	var value: Variant = records("games").get(topic + "_" + str(difficulty), {})
	return value if value is Dictionary else {}

static func finish_game(topic: String, difficulty: int, answers: Dictionary, score: int) -> Error:
	if topic not in ["find_shape", "build_pattern", "count_sides", "quick_challenge"] or difficulty not in [1, 2] or answers.is_empty(): return ERR_INVALID_DATA
	if topic != "quick_challenge" and answers.size() != 8: return ERR_INVALID_DATA
	var known := {}
	for q in Catalog.games(topic, difficulty): known[q.id] = q
	var first := 0
	var expected_score := 0
	for id in answers:
		var record: Variant = answers[id]
		if not known.has(id) or not record is Dictionary or not Rules.matches(known[id], record.get("answer")): return ERR_INVALID_DATA
		var clean: bool = record.get("first", false) == true
		first += 1 if clean else 0
		expected_score += 10 if clean else 5
	if score != expected_score: return ERR_INVALID_DATA
	var config := Store.read(PATH)
	var best := game_record(topic, difficulty)
	var games := records("games")
	games[topic + "_" + str(difficulty)] = {"score": maxi(score, int(best.get("score", 0))), "stars": maxi(3 if first >= 7 else 2 if first >= 4 else 1, int(best.get("stars", 0)))}
	config.set_value(SECTION, "games", games)
	return Store.write(config, PATH)
