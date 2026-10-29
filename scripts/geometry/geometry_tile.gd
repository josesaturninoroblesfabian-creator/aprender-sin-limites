extends Button

const Shapes = preload("res://scripts/geometry/geometry_shapes.gd")
var token := "circle:blue"
var angle := 0.0
var show_name := false
var draggable := true
var selected := false

func _draw() -> void:
	var height := size.y - (26 if show_name else 8)
	Shapes.paint(self, Shapes.token_shape(token), Rect2(7, 4, size.x - 14, height), Shapes.token_color(token), angle)
	if show_name:
		draw_string(ThemeDB.fallback_font, Vector2(0, size.y - 8), Shapes.NAMES.get(Shapes.token_shape(token), ""), HORIZONTAL_ALIGNMENT_CENTER, size.x, 17, Shapes.INK)
	if selected: draw_rect(Rect2(4, 4, size.x - 8, size.y - 8), Color("#b36e10"), false, 4)

func _get_drag_data(_at: Vector2) -> Variant:
	if disabled or not draggable: return null
	var preview: Control = get_script().new()
	preview.token = token
	preview.angle = angle
	preview.draggable = false
	preview.custom_minimum_size = Vector2(90, 90)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)
	return {"type": "geometry_tile", "token": token}
