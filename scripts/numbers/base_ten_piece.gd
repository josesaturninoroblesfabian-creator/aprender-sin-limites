extends Control

const Rules = preload("res://scripts/numbers/number_rules.gd")
var place := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(64, 64)
	resized.connect(queue_redraw)

func _draw() -> void:
	paint(self, place, size * 0.5, minf(size.x, size.y) * 0.9)

static func paint(canvas: CanvasItem, position: int, center: Vector2, side: float) -> void:
	var color: Color = Rules.COLORS[position]
	if position == 0:
		var rect := Rect2(center - Vector2.ONE * side * 0.32, Vector2.ONE * side * 0.64)
		canvas.draw_rect(rect, color)
		canvas.draw_rect(rect, color.darkened(0.3), false, 2)
		canvas.draw_line(rect.position + Vector2(2, 2), Vector2(rect.end.x - 2, rect.position.y + 2), color.lightened(0.5), 2)
	elif position == 1:
		var rect := Rect2(center - Vector2(side * 0.13, side * 0.45), Vector2(side * 0.26, side * 0.9))
		canvas.draw_rect(rect, color)
		for line in range(11):
			var y := rect.position.y + line * rect.size.y / 10.0
			canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color("#ffe4a8"), 1)
	elif position == 2:
		var rect := Rect2(center - Vector2.ONE * side * 0.4, Vector2.ONE * side * 0.8)
		canvas.draw_rect(rect, color)
		for line in range(11):
			var d := line * rect.size.x / 10.0
			canvas.draw_line(rect.position + Vector2(d, 0), rect.position + Vector2(d, rect.size.y), color.lightened(0.55), 0.8)
			canvas.draw_line(rect.position + Vector2(0, d), rect.position + Vector2(rect.size.x, d), color.lightened(0.55), 0.8)
	else:
		var rect := Rect2(center - Vector2.ONE * side * 0.28, Vector2.ONE * side * 0.56)
		var depth := Vector2(side * 0.2, -side * 0.2)
		canvas.draw_colored_polygon(PackedVector2Array([rect.position, rect.position + depth, Vector2(rect.end.x, rect.position.y) + depth, Vector2(rect.end.x, rect.position.y)]), color.lightened(0.35))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.position.y) + depth, rect.end + depth, rect.end]), color.darkened(0.22))
		canvas.draw_rect(rect, color)
		for line in range(11):
			var d := line * rect.size.x / 10.0
			canvas.draw_line(rect.position + Vector2(d, 0), rect.position + Vector2(d, rect.size.y), color.lightened(0.55), 0.8)
			canvas.draw_line(rect.position + Vector2(0, d), rect.position + Vector2(rect.size.x, d), color.lightened(0.55), 0.8)
