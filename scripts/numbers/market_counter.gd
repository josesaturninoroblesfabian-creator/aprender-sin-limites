extends Control

signal changed(marked: int)
const UI = preload("res://scripts/math/math_ui.gd")
const Art = preload("res://scripts/numbers/number_art.gd")
var total := 0
var produce := 0
var marked: Dictionary = {}
var flights: Array[Dictionary] = []
var clock := 0.0
var active := true

func _ready() -> void:
	custom_minimum_size = Vector2(500, 300)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true
	resized.connect(queue_redraw)

func setup(number: int, produce_: int) -> void:
	total = clampi(number, 0, 40)
	produce = clampi(produce_, 0, 2)
	marked.clear()
	flights.clear()
	queue_redraw()

func object_rect(index: int) -> Rect2:
	var columns := 8 if total > 16 else 5
	var rows := maxi(1, ceili(float(total) / columns))
	var area := Rect2(14, 35, size.x * 0.73 - 18, size.y - 75)
	var cell := Vector2(area.size.x / columns, area.size.y / rows)
	var edge := minf(cell.x - 6, cell.y - 6)
	var center := area.position + Vector2(index % columns + 0.5, index / columns + 0.5) * cell
	return Rect2(center - Vector2.ONE * edge * 0.5, Vector2.ONE * edge)

func collect(index: int) -> bool:
	if not active or index < 0 or index >= total or marked.has(index): return false
	marked[index] = marked.size() + 1
	flights.append({"from": object_rect(index).get_center(), "time": 0.0})
	changed.emit(marked.size())
	queue_redraw()
	return true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_touch(event.position)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_touch(event.position)
		accept_event()

func _touch(at: Vector2) -> void:
	for index in range(total):
		if object_rect(index).has_point(at):
			collect(index)
			break

func _process(delta: float) -> void:
	clock += delta
	for flight in flights: flight.time += delta * 2.5
	for i in range(flights.size() - 1, -1, -1):
		if flights[i].time >= 1: flights.remove_at(i)
	if is_visible_in_tree(): queue_redraw()

func _icon(texture: Texture2D, rect: Rect2, tint: Color = Color.WHITE) -> void:
	var fit := texture.get_size() * minf(rect.size.x / texture.get_width(), rect.size.y / texture.get_height())
	draw_texture_rect(texture, Rect2(rect.get_center() - fit * 0.5, fit), false, tint)

func _center(value: String, rect: Rect2, font_size: int = 23, color: Color = Color("#164966")) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5 + font_size * 0.35), value, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)

func _draw() -> void:
	var field := Rect2(4, 4, size.x * 0.75 - 10, size.y - 8)
	draw_style_box(UI.style(Color("#fff7dd"), Color("#d4aa58"), 23), field)
	_center("Toca para contar · cada producto, una vez", Rect2(0, 0, field.size.x, 30), 19)
	for index in range(total):
		var rect := object_rect(index)
		if marked.has(index):
			draw_circle(rect.get_center(), rect.size.x * 0.4, Color("#e0f3cb"))
			_center(str(marked[index]), rect, 24, Color("#216d35"))
		else:
			var bob := sin(clock * 2.0 + index * 0.8) * 1.7
			rect.position.y += bob
			_icon(UI.object(produce), rect)
	if total == 0:
		_center("Hoy no hay productos.", Rect2(0, size.y * 0.35, field.size.x, 45), 29)
		_center("¿Qué número representa esta canasta vacía?", Rect2(0, size.y * 0.53, field.size.x, 38), 20)
	var basket := Rect2(size.x * 0.78, size.y * 0.32, size.x * 0.2, size.y * 0.42)
	_icon(Art.object(3), basket)
	_center("Marcados: %d" % marked.size(), Rect2(size.x * 0.75, 8, size.x * 0.25, 42), 24)
	_center("%d D · %d U" % [marked.size() / 10, marked.size() % 10], Rect2(size.x * 0.75, size.y - 60, size.x * 0.25, 35), 23)
	for group in range(marked.size() / 10):
		var pos := Vector2(size.x * 0.80 + group * 27, size.y * 0.83)
		draw_style_box(UI.style(Color("#e7b745"), Color("#a67116"), 4), Rect2(pos, Vector2(23, 23)))
		_center("10", Rect2(pos, Vector2(23, 23)), 13, Color("#5e3b07"))
	for flight in flights:
		var t := float(flight.time)
		var point: Vector2 = flight.from.lerp(basket.get_center(), t) + Vector2(0, -sin(t * PI) * 70)
		_icon(UI.object(produce), Rect2(point - Vector2(20, 20), Vector2(40, 40)))
