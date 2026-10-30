extends RefCounted

const Repo = preload("res://scripts/stories/story_repository.gd")
static var data: Dictionary = {}
static var portraits: Dictionary = {}

static func contain_rect(source: Vector2, target: Vector2) -> Rect2:
	if source.x <= 0 or source.y <= 0 or target.x <= 0 or target.y <= 0: return Rect2()
	var fitted := source * minf(target.x / source.x, target.y / source.y)
	return Rect2((target - fitted) * 0.5, fitted)


static func catalog() -> Dictionary:
	if data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/stories/visuals.json"))
		if parsed is Dictionary: data = parsed
	return data


static func character_texture(id: String) -> Texture2D:
	if portraits.has(id): return portraits[id]
	var entry: Dictionary = catalog().get("characters", {}).get(id, {})
	if entry.is_empty(): return null
	var story := Repo.find_story(entry.story)
	if story.is_empty(): return null
	# Keep small card images in memory, not eight complete scene atlases.
	var source: Texture2D = ResourceLoader.load(story.atlas, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
	var cell := Vector2(source.get_width() / 4.0, source.get_height() / 2.0)
	var index := int(entry.page)
	var crop: Array = entry.crop
	var region := Rect2(Vector2(index % 4, index / 4) * cell + Vector2(crop[0], crop[1]) * cell, Vector2(crop[2], crop[3]) * cell)
	var image := source.get_image().get_region(Rect2i(region))
	var fit := image.get_size() * (256.0 / maxf(image.get_width(), image.get_height()))
	image.resize(maxi(1, roundi(fit.x)), maxi(1, roundi(fit.y)), Image.INTERPOLATE_LANCZOS)
	portraits[id] = ImageTexture.create_from_image(image)
	return portraits[id]

