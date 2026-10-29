extends Control

const Shapes = preload("res://scripts/geometry/geometry_shapes.gd")
const Art = preload("res://scripts/geometry/geometry_art.gd")
const UI = preload("res://scripts/math/math_ui.gd")
var question: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resized.connect(queue_redraw)

func _draw() -> void:
	if question.is_empty(): return
	if question.kind in ["pattern", "sky_pattern"]:
		var count: int = question.sequence.size()
		var cell := minf(size.y - 5, size.x / maxi(1, count))
		for index in range(count):
			var rect := Rect2((size.x - cell * count) * 0.5 + index * cell + 2, 2, cell - 4, cell - 4)
			if index in question.holes:
				draw_style_box(UI.style(Color("#fff0be"), Color("#b38e41"), 9, 0), rect)
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y * 0.65), "?", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 26, Shapes.INK)
			else:
				var token: String = question.sequence[index]
				Shapes.paint(self, Shapes.token_shape(token), rect, Shapes.token_color(token))
	elif question.kind == "solid" and question.get("object_match", false):
		var texture := Art.object(Shapes.SOLIDS.find(question.shape))
		var fit := texture.get_size() * minf(size.x / texture.get_width(), size.y / texture.get_height())
		draw_texture_rect(texture, Rect2((size - fit) * 0.5, fit), false)
	else: Shapes.paint(self, question.get("shape", "triangle"), Rect2(Vector2.ZERO, size), Shapes.COLORS.blue, float(question.get("angle", 0)))
