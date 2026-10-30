extends TextureRect

const Art = preload("res://scripts/stories/story_art.gd")
var source_frame: AtlasTexture

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(_fit)
	_fit()

func set_frame(value: AtlasTexture) -> void:
	source_frame = value
	_fit()

func _fit() -> void:
	if source_frame == null: return
	# Keep the complete scene. The visible border follows the image, not a crop.
	texture = source_frame
	queue_redraw()

func image_rect() -> Rect2:
	return Art.contain_rect(source_frame.get_size(), size) if source_frame != null else Rect2()

func _draw() -> void:
	if source_frame != null: draw_rect(image_rect().grow(-1), Color("#a8bbc9"), false, 2, true)

