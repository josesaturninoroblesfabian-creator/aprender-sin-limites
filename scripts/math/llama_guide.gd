extends TextureRect

var audio: Node
var clock := 0.0
var frames: Array[AtlasTexture] = []
const TALK := [1, 2, 1, 3, 2, 1, 0]

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var atlas: Texture2D = load("res://assets/characters/llama/llama-teacher-atlas.png")
	var cell := Vector2(atlas.get_width() / 3.0, atlas.get_height() / 2.0)
	for index in range(6):
		var frame := AtlasTexture.new()
		frame.atlas = atlas
		frame.region = Rect2(Vector2(index % 3, index / 3) * cell, cell)
		frame.filter_clip = true
		frames.append(frame)
	texture = frames[0]

func _process(delta: float) -> void:
	if not is_visible_in_tree() or frames.is_empty(): return
	clock += delta
	var talking: bool = is_instance_valid(audio) and audio.call("speaking")
	texture = frames[TALK[int(clock / 0.12) % TALK.size()] if talking else (4 if fmod(clock, 4.8) > 4.6 else 0)]
	pivot_offset = size * 0.5
	rotation = sin(clock * 2.0) * 0.012
