extends Control

signal changed(value: int)
signal selected(place: int)
const Rules = preload("res://scripts/numbers/number_rules.gd")
const UI = preload("res://scripts/math/math_ui.gd")
var width := 2
var counts: Array[int] = [0, 0]
var editable := true
var active_place := 0
var highlighted := -1
var show_total := true
var pulse := 0.0
var clock := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(280, 225)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_contents = true
	resized.connect(queue_redraw)

func setup(value_: int, digits_: int, can_edit: bool = true) -> void:
	width = clampi(digits_, 1, 4)
	counts = Rules.digits(value_, width)
	editable = can_edit
	active_place = width - 1
	queue_redraw()

func set_counts(values: Array) -> void:
	if values.size() != width: return
	for i in range(width): counts[i] = clampi(int(values[i]), 0, 10)
	queue_redraw()

func set_digit(digit: int) -> void:
	if not editable or digit < 0 or digit > 9: return
	counts[active_place] = digit
	pulse = 1.0
	changed.emit(Rules.value(counts))
	queue_redraw()

func add_piece(place: int, delta: int = 1) -> void:
	if not editable or place < 0 or place >= width: return
	counts[place] = clampi(counts[place] + delta, 0, 10)
	active_place = place
	pulse = 1.0
	changed.emit(Rules.value(counts))
	queue_redraw()

func exchange(place: int) -> bool:
	if not editable or place < 0 or place + 1 >= width or counts[place] < 10 or counts[place + 1] >= 9: return false
	counts[place] -= 10
	counts[place + 1] += 1
	active_place = place + 1
	pulse = 1.0
	changed.emit(Rules.value(counts))
	queue_redraw()
	return true

func column_rect(place: int) -> Rect2:
	var gap := 10.0
	var cell := maxf(1, (size.x - gap * (width - 1)) / width)
	return Rect2((width - 1 - place) * (cell + gap), 4, cell, maxf(1, size.y - 44))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_at(event.position)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_select_at(event.position)
		accept_event()

func _select_at(at: Vector2) -> void:
	if not editable: return
	for place in range(width):
		if column_rect(place).has_point(at):
			active_place = place
			selected.emit(place)
			queue_redraw()

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not editable or not data is Dictionary or data.get("type") != "number_digit": return false
	if not data.get("digit") is int or data.digit < 0 or data.digit > 9: return false
	for place in range(width):
		if column_rect(place).has_point(at): return true
	return false

func _drop_data(at: Vector2, data: Variant) -> void:
	if not _can_drop_data(at, data): return
	_select_at(at)
	set_digit(int(data.digit))

func _process(delta: float) -> void:
	clock += delta
	var was_pulsing := pulse > 0
	pulse = maxf(0, pulse - delta * 2.2)
	if was_pulsing and is_visible_in_tree(): queue_redraw()

func _label(value_: String, rect: Rect2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var baseline := rect.position.y + (rect.size.y + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, Vector2(rect.position.x, baseline), value_, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)

func _draw() -> void:
	for place in range(width):
		var rect := column_rect(place)
		var color: Color = Rules.COLORS[place]
		var active := (editable and place == active_place) or highlighted == place
		draw_style_box(UI.style(color.lightened(0.9), color if active else color.lightened(0.55), 18, 0), rect)
		if active: draw_style_box(_outline(color, 3), rect.grow(-3))
		_label(Rules.SHORT[place] + " · " + ("1000" if place == 3 else str(int(pow(10, place)))), Rect2(rect.position + Vector2(0, 6), Vector2(rect.size.x, 23)), 19, color.darkened(0.1))
		_label(str(counts[place]), Rect2(rect.position + Vector2(0, 30), Vector2(rect.size.x, 49)), 41, color)
		var area := Rect2(rect.position + Vector2(9, 86), rect.size - Vector2(18, 125))
		var piece_size := minf(area.size.x / 3.4, area.size.y / 3.9)
		for piece in range(counts[place]):
			var x := area.position.x + (piece % 3 + 0.5) * area.size.x / 3.0
			var y := area.position.y + (piece / 3 + 0.5) * area.size.y / 4.0
			var scale_ := 1.0 + pulse * 0.13 if active else 1.0
			_piece(place, Vector2(x, y), piece_size * scale_, color)
		if counts[place] == 0:
			_label("Vacío", Rect2(area.position, area.size), 20, color.darkened(0.1))
		_label("%d × %d" % [counts[place], int(pow(10, place))], Rect2(rect.position + Vector2(0, rect.size.y - 30), Vector2(rect.size.x, 26)), 18, color.darkened(0.1))
	if show_total:
		_label("Construiste: %d" % Rules.value(counts), Rect2(0, size.y - 35, size.x, 35), 25, Color("#174765"))

func _outline(color: Color, border: int) -> StyleBoxFlat:
	var box := UI.style(Color.TRANSPARENT, color, 15, 0)
	box.set_border_width_all(border)
	box.shadow_size = 0
	return box

func _piece(place: int, center: Vector2, side: float, color: Color) -> void:
	if place == 0:
		var small := Rect2(center - Vector2.ONE * side * 0.28, Vector2.ONE * side * 0.56)
		draw_style_box(UI.style(color, color.darkened(0.25), 3, 0), small)
	elif place == 1:
		var rect := Rect2(center - Vector2(side * 0.12, side * 0.43), Vector2(side * 0.24, side * 0.86))
		draw_rect(rect, color)
		for line in range(11):
			var y := rect.position.y + line * rect.size.y / 10.0
			draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color("#ffe4a8"), 1)
	elif place == 2:
		var rect := Rect2(center - Vector2.ONE * side * 0.4, Vector2.ONE * side * 0.8)
		draw_rect(rect, color)
		for line in range(11):
			var d := line * rect.size.x / 10.0
			draw_line(rect.position + Vector2(d, 0), rect.position + Vector2(d, rect.size.y), color.lightened(0.55), 0.8)
			draw_line(rect.position + Vector2(0, d), rect.position + Vector2(rect.size.x, d), color.lightened(0.55), 0.8)
	else:
		var rect := Rect2(center - Vector2.ONE * side * 0.28, Vector2.ONE * side * 0.56)
		var depth := Vector2(side * 0.2, -side * 0.2)
		draw_colored_polygon(PackedVector2Array([rect.position, rect.position + depth, Vector2(rect.end.x, rect.position.y) + depth, Vector2(rect.end.x, rect.position.y)]), color.lightened(0.35))
		draw_colored_polygon(PackedVector2Array([Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.position.y) + depth, rect.end + depth, rect.end]), color.darkened(0.22))
		draw_rect(rect, color)
		for line in range(11):
			var d := line * rect.size.x / 10.0
			draw_line(rect.position + Vector2(d, 0), rect.position + Vector2(d, rect.size.y), color.lightened(0.55), 0.8)
			draw_line(rect.position + Vector2(0, d), rect.position + Vector2(rect.size.x, d), color.lightened(0.55), 0.8)
