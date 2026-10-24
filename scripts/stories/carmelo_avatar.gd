extends TextureRect

const TALK := [1, 2, 1, 3, 2, 1, 0]
var frames: Array[AtlasTexture] = []
var clock := 0.0
var frame_index := -1

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var atlas: Texture2D = load("res://assets/characters/carmelo/carmelo-atlas.png")
	var cell := Vector2(atlas.get_width() / 3.0, atlas.get_height() / 2.0)
	for index in range(6):
		var frame := AtlasTexture.new()
		frame.atlas = atlas
		frame.region = Rect2(Vector2(index % 3, index / 3) * cell, cell)
		frame.filter_clip = true
		frames.append(frame)
	_process(0.0)

func _process(delta: float) -> void:
	if not is_visible_in_tree() or frames.is_empty():
		return
	clock += delta
	var index: int = TALK[int(clock / 0.13) % TALK.size()] if StoryAudio.speaking() else (4 if fmod(clock, 4.7) > 4.54 else 0)
	if index != frame_index:
		texture = frames[index]
		frame_index = index
	var bob := sin(clock * 2.3) * 1.4
	if not is_equal_approx(anchor_top, anchor_bottom):
		offset_top = bob
		offset_bottom = bob
	else:
		pivot_offset = size * 0.5
		rotation = sin(clock * 2.3) * 0.006
