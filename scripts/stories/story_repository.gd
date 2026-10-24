extends RefCounted

const ProgressStore = preload("res://scripts/storage/progress_store.gd")
const CATALOG_PATH := "res://assets/data/cuentos.json"
const SAVE_PATH := "user://progreso_cuentos.cfg"
const MODES := ["read", "listen", "order", "quiz"]
const MODE_TITLES := {"read": "Leer con imágenes", "listen": "Escucha el cuento", "order": "Ordena la historia", "quiz": "Preguntas y retos"}
const MODE_COLORS := {"read": Color("#965800"), "listen": Color("#08735f"), "order": Color("#6d3bab"), "quiz": Color("#ba3924")}
static var cache: Array[Dictionary] = []
static var covers: Dictionary = {}

static func all_stories() -> Array[Dictionary]:
	if cache.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
		if parsed is Dictionary:
			for item in parsed.get("stories", []):
				if item is Dictionary:
					# JSON numbers are floats; card callbacks use integer scene indices.
					var order: Array = []
					for value in item.get("order", []):
						order.append(int(value))
					item["order"] = order
					cache.append(item)
	return cache

static func find_story(id: String) -> Dictionary:
	for story in all_stories():
		if story.id == id:
			return story
	return {}

static func page_texture(story: Dictionary, index: int) -> AtlasTexture:
	var texture: Texture2D = load(story.atlas)
	var cell := Vector2(texture.get_width() / 4.0, texture.get_height() / 2.0)
	var frame := AtlasTexture.new()
	frame.atlas = texture
	frame.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
	frame.filter_clip = true
	return frame

static func cover_texture(story: Dictionary) -> Texture2D:
	if not covers.has(story.id):
		# Keep tiny covers, not sixteen full-size GPU atlases, in the library grid.
		var source: Texture2D = ResourceLoader.load(story.atlas, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
		var cell := Rect2i(0, 0, source.get_width() / 4, source.get_height() / 2)
		var image := source.get_image().get_region(cell)
		image.resize(216, roundi(216.0 * image.get_height() / image.get_width()), Image.INTERPOLATE_LANCZOS)
		covers[story.id] = ImageTexture.create_from_image(image)
	return covers[story.id]

static func saved() -> Dictionary:
	var config := ProgressStore.read(SAVE_PATH)
	var value: Variant = config.get_value("journey_v2", "stories", {})
	return value.duplicate(true) if value is Dictionary else {}

static func is_complete(id: String, mode: String) -> bool:
	var record: Variant = saved().get(id, {})
	return record is Dictionary and record.get(mode, false) == true

static func best_score(id: String) -> int:
	var record: Variant = saved().get(id, {})
	return clampi(int(record.get("best_score", 0)), 0, 40) if record is Dictionary else 0

static func complete(id: String, mode: String, score: int = 0) -> Error:
	if mode not in MODES or find_story(id).is_empty():
		return ERR_INVALID_PARAMETER
	var config := ProgressStore.read(SAVE_PATH)
	var data := saved()
	var existing: Variant = data.get(id, {})
	var record: Dictionary = existing.duplicate(true) if existing is Dictionary else {}
	record[mode] = true
	if mode == "quiz":
		record["best_score"] = maxi(best_score(id), clampi(score, 0, 40))
	data[id] = record
	config.set_value("journey_v2", "stories", data)
	return ProgressStore.write(config, SAVE_PATH)

static func totals() -> Dictionary:
	var data := saved()
	var done := 0
	var points := 0
	for story in all_stories():
		var record: Variant = data.get(story.id, {})
		if record is Dictionary:
			for mode in MODES:
				if record.get(mode, false) == true:
					done += 1
			points += clampi(int(record.get("best_score", 0)), 0, 40)
	return {"completed": done, "total": all_stories().size() * MODES.size(), "points": points}
