extends RefCounted

const Store = preload("res://scripts/storage/progress_store.gd")
const Catalog = preload("res://scripts/numbers/number_catalog.gd")
const Rules = preload("res://scripts/numbers/number_rules.gd")
const PATH := "user://progreso_numeros.cfg"
const SECTION := "exploracion_v1"

static func records(key: String) -> Dictionary:
	var result: Variant = Store.read(PATH).get_value(SECTION, key, {})
	return result.duplicate(true) if result is Dictionary else {}

static func stars(id: String) -> int:
	var value_: Variant = records("lessons").get(id, {})
	return clampi(int(value_.get("stars", 0)), 0, 3) if value_ is Dictionary else 0

static func complete(id: String) -> bool:
	if Catalog.find(id).is_empty(): return false
	var old: Variant = Store.read(PATH).get_value("progreso", "actividades", {})
	return old is Dictionary and old.get(id, false) == true

static func resume(id: String) -> Dictionary:
	var lesson := Catalog.find(id)
	var stored: Variant = records("resume").get(id, {})
	if lesson.is_empty() or not stored is Dictionary: return {}
	var answers: Dictionary = {}
	var wrong: Array = []
	var hinted: Array = []
	var raw: Variant = stored.get("answers", {})
	if not raw is Dictionary: raw = {}
	for question in lesson.questions:
		var answer: Variant = raw.get(question.id, {})
		if answer is Dictionary and Rules.matches(question, answer.get("answer")):
			answers[question.id] = {"answer": question.result, "first": answer.get("first", false) == true}
		if stored.get("wrong", []) is Array and question.id in stored.get("wrong", []): wrong.append(question.id)
		if stored.get("hinted", []) is Array and question.id in stored.get("hinted", []): hinted.append(question.id)
	var draft: Variant = stored.get("draft", {})
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
	for question in lesson.questions:
		var record: Variant = answers.get(question.id, {})
		if not record is Dictionary or not Rules.matches(question, record.get("answer")): return ERR_INVALID_DATA
		first += 1 if record.get("first", false) == true else 0
	var config := Store.read(PATH)
	var old: Variant = config.get_value("progreso", "actividades", {})
	var activities: Dictionary = old.duplicate(true) if old is Dictionary else {}
	activities[id] = true
	config.set_value("progreso", "actividades", activities)
	var lessons_ := records("lessons")
	lessons_[id] = {"stars": maxi(stars(id), 3 if first == 5 else 2 if first >= 3 else 1)}
	config.set_value(SECTION, "lessons", lessons_)
	var partial := records("resume")
	partial.erase(id)
	config.set_value(SECTION, "resume", partial)
	return Store.write(config, PATH)

static func game_record(kind: String, width: int) -> Dictionary:
	var value_: Variant = records("games").get(kind + "_" + str(width), {})
	return value_ if value_ is Dictionary else {}

static func finish_game(kind: String, width: int, answers: Dictionary, score: int) -> Error:
	if kind not in ["count_objects", "sequences", "compare", "quick_challenge"] or width < 1 or width > 4 or score < 0 or answers.is_empty(): return ERR_INVALID_DATA
	if kind == "count_objects" and width != 2: return ERR_INVALID_DATA
	if kind != "quick_challenge" and answers.size() != 8: return ERR_INVALID_DATA
	var allowed: Dictionary = {}
	if kind == "count_objects":
		var totals: Array = Catalog.load_data().market_totals
		for i in range(totals.size()): allowed["market_" + str(i)] = totals[i]
	else:
		for question in Catalog.games("sequences" if kind == "sequences" else "comparisons" if kind == "compare" else "train", width): allowed[question.id] = question.result
	var first := 0
	var earned := 0
	for id in answers:
		var record: Variant = answers[id]
		if not allowed.has(id) or not record is Dictionary: return ERR_INVALID_DATA
		var actual: Variant = record.get("answer")
		var expected: Variant = allowed[id]
		if expected is String:
			if not actual is String or actual != expected: return ERR_INVALID_DATA
		elif not (actual is int or actual is float) or actual != expected: return ERR_INVALID_DATA
		var clean: bool = record.get("first", false) == true
		first += 1 if clean else 0
		earned += 10 if clean else 5
	if score != earned: return ERR_INVALID_DATA
	var awarded := 3 if first >= 7 else 2 if first >= 4 else 1
	var key := kind + "_" + str(width)
	var best := game_record(kind, width)
	var games := records("games")
	games[key] = {"score": maxi(score, int(best.get("score", 0))), "stars": maxi(awarded, int(best.get("stars", 0))), "solved": maxi(answers.size(), int(best.get("solved", 0)))}
	var config := Store.read(PATH)
	config.set_value(SECTION, "games", games)
	return Store.write(config, PATH)
