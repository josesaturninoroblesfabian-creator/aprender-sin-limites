extends Control

const UI = preload("res://scripts/math/math_ui.gd")
var operation := "addition"
var row: Dictionary = {}

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func set_example(topic: String, value: Dictionary) -> void:
	operation = topic
	row = value
	queue_redraw()

func _caption(value: String, at: Vector2, width: float, color: Color = UI.INK) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_CENTER, width, 16, color)

func _objects(amount: int, area: Rect2, crossed: bool = false) -> void:
	var columns := mini(15, maxi(1, amount))
	var count_rows := ceili(float(amount) / columns)
	var cell := minf(area.size.x / columns, area.size.y / maxi(1, count_rows))
	cell = minf(cell, 25)
	var start := area.position + Vector2((area.size.x - cell * columns) / 2, 0)
	for index in range(amount):
		var rect := Rect2(start + Vector2(index % columns, index / columns) * cell, Vector2.ONE * cell)
		draw_texture_rect(UI.object(0), rect.grow(-1), false, Color(1, 1, 1, 0.4 if crossed else 1.0))
		if crossed:
			draw_line(rect.position + Vector2(3, 3), rect.end - Vector2(3, 3), Color("#ba3545"), 2, true)

func _draw() -> void:
	if row.is_empty() or size.x < 1: return
	var half := size.x / 2
	if operation in ["addition", "subtraction"]:
		var left: int = row.a if operation == "addition" else row.result
		var right: int = row.b
		_caption("%d al empezar" % row.a if operation == "addition" else "%d quedan" % row.result, Vector2(0, 18), half)
		_caption("%d añadimos" % right if operation == "addition" else "%d quitamos" % right, Vector2(half, 18), half)
		_objects(left, Rect2(5, 25, half - 10, size.y - 28))
		_objects(right, Rect2(half + 5, 25, half - 10, size.y - 28), operation == "subtraction")
	else:
		# One representative group stays countable, even for 15 × 15.
		var amount: int = row.a if operation == "multiplication" else row.result
		var groups: int = row.b
		var group_caption := "1 grupo" if groups == 1 else "%d grupos iguales" % groups
		if operation == "division": group_caption = "1 grupo recibe el total" if groups == 1 else "%d grupos reciben lo mismo" % groups
		_caption(group_caption, Vector2(0, 18), half)
		var dot_size := minf(22, (half - 16) / maxi(1, groups))
		for index in range(groups):
			var center := Vector2(half / 2 + (index - (groups - 1) / 2.0) * dot_size, 48)
			draw_circle(center, dot_size * 0.39, Color("#13819d"), true, -1, true)
		_caption("%d en cada grupo" % amount, Vector2(half, 18), half)
		_objects(amount, Rect2(half + 5, 25, half - 10, size.y - 28))
