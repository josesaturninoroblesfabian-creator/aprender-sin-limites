extends TextureRect

const LANDSCAPE = preload("res://assets/ui/encyclopedia/andes-background.png")

func _ready() -> void:
	texture = LANDSCAPE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.10, 0.18, 0.60)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
