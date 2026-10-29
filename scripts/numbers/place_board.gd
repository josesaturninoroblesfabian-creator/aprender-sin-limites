extends Control

signal changed(value: int)
signal selected(place: int)
signal rejected(message: String)
const Rules = preload("res://scripts/numbers/number_rules.gd")
const UI = preload("res://scripts/math/math_ui.gd")
const Piece = preload("res://scripts/numbers/base_ten_piece.gd")
const NAMES := ["Unidades", "Decenas", "Centenas", "Millares"]
var width := 2
var counts: Array[int] = [0, 0]
var editable := true:
	set(value):
		editable = value
		_layout_buttons()
		queue_redraw()
var active_place := 0
var highlighted := -1
var show_total := true
var pulse := 0.0
var clock := 0.0
var remove_buttons: Array[Button] = []
var exchange_buttons: Array[Button] = []
var motions: Array[Dictionary] = []
var dragging := Vector2i(-1, -1)

func _ready() -> void:
	custom_minimum_size = Vector2(280, 245)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_contents = true
	resized.connect(func():
		_layout_buttons()
		queue_redraw()
	)

func setup(value_: int, digits_: int, can_edit: bool = true) -> void:
	width = clampi(digits_, 1, 4)
	counts = Rules.digits(value_, width)
	editable = can_edit
	active_place = width - 1
	for button in remove_buttons + exchange_buttons:
		remove_child(button)
		button.queue_free()
	remove_buttons.clear()
	exchange_buttons.clear()
	for place in range(width):
		var remove := _small_button("− Quitar 1", Rules.COLORS[place])
		remove.name = "RemovePiece_" + str(place)
		remove.pressed.connect(remove_piece.bind(place))
		add_child(remove)
		remove_buttons.append(remove)
		var swap := _small_button("Canjear 10 →", Rules.COLORS[place])
		swap.name = "ExchangePieces_" + str(place)
		swap.pressed.connect(exchange.bind(place))
		add_child(swap)
		exchange_buttons.append(swap)
	_layout_buttons()
	queue_redraw()

func _small_button(text_: String, color: Color) -> Button:
	var button := UI.button(text_, color, 16)
	button.custom_minimum_size.y = 40
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, UI.style(color if state != "disabled" else Color("#73858b"), Color("#fff0b2") if state == "focus" else color.darkened(0.2), 10, 3))
	return button

func valid_counts(values: Array) -> bool:
	if values.size() != width: return false
	for place in range(width):
		var value_: Variant = values[place]
		if not (value_ is int or value_ is float) or int(value_) != value_ or value_ < 0 or value_ > (9 if place == width - 1 else 10): return false
	return true

func set_counts(values: Array) -> void:
	if not valid_counts(values): return
	for i in range(width): counts[i] = int(values[i])
	_layout_buttons()
	queue_redraw()

func set_digit(digit: int) -> void:
	if not editable or digit < 0 or digit > 9: return
	counts[active_place] = digit
	_changed()

func add_piece(place: int, delta: int = 1, origin: Vector2 = Vector2.INF) -> void:
	if not editable or place < 0 or place >= width: return
	if delta < 0:
		remove_piece(place)
		return
	var cap := 9 if place == width - 1 else 10
	if counts[place] >= cap:
		rejected.emit("Canjea las diez piezas para formar una de la columna izquierda." if place < width - 1 else "En esta columna caben hasta nueve piezas.")
		return
	if Rules.value(counts) + int(pow(10, place)) >= int(pow(10, width)):
		rejected.emit("Ese número necesita otra columna. Quita piezas para volver a la meta.")
		return
	counts[place] += 1
	active_place = place
	if origin.is_finite(): motions.append({"place": place, "index": counts[place] - 1, "from": origin, "time": 0.0})
	_changed()

func remove_piece(place: int) -> bool:
	if not editable or place < 0 or place >= width or counts[place] <= 0: return false
	counts[place] -= 1
	active_place = place
	_changed()
	return true

func exchange(place: int) -> bool:
	if not editable or place < 0 or place + 1 >= width or counts[place] < 10: return false
	if counts[place + 1] >= (9 if place + 1 == width - 1 else 10): return false
	var origin := column_rect(place).get_center()
	counts[place] -= 10
	counts[place + 1] += 1
	active_place = place + 1
	motions.append({"place": place + 1, "index": counts[place + 1] - 1, "from": origin, "time": 0.0})
	_changed()
	return true

func _changed() -> void:
	pulse = 1.0
	_layout_buttons()
	changed.emit(Rules.value(counts))
	queue_redraw()

func column_rect(place: int) -> Rect2:
	var gap := 10.0
	var cell := maxf(1, (size.x - gap * (width - 1)) / width)
	return Rect2((width - 1 - place) * (cell + gap), 4, cell, maxf(1, size.y - 43))

func piece_rect(place: int, index: int) -> Rect2:
	var column := column_rect(place)
	var bottom := 71.0 if editable else 35.0
	var area := Rect2(column.position + Vector2(8, 87), Vector2(column.size.x - 16, maxf(8, column.size.y - 87 - bottom)))
	var rows := 4 if counts[place] > 9 else 3
	var cell := Vector2(area.size.x / 3.0, area.size.y / rows)
	var side := minf(cell.x, cell.y) * 0.86
	var center := area.position + Vector2(index % 3 + 0.5, index / 3 + 0.5) * cell
	return Rect2(center - Vector2.ONE * side * 0.5, Vector2.ONE * side)

func _layout_buttons() -> void:
	for place in range(remove_buttons.size()):
		if place >= counts.size(): continue
		var rect := column_rect(place)
		var can_exchange := place + 1 < width and counts[place] >= 10 and counts[place + 1] < (9 if place + 1 == width - 1 else 10)
		var remove := remove_buttons[place]
		remove.visible = editable
		remove.disabled = counts[place] <= 0 or not editable
		remove.position = rect.position + Vector2(5, rect.size.y - 44)
		remove.size = Vector2((rect.size.x - 14) * 0.46 if can_exchange else rect.size.x - 10, 40)
		remove.text = "− Quitar" if can_exchange else "− Quitar 1"
		var swap := exchange_buttons[place]
		swap.visible = editable and can_exchange
		swap.position = remove.position + Vector2(remove.size.x + 4, 0)
		swap.size = Vector2((rect.size.x - 14) * 0.54, 40)

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

func _get_drag_data(at: Vector2) -> Variant:
	if not editable: return null
	for place in range(width):
		for index in range(counts[place]):
			if piece_rect(place, index).grow(4).has_point(at):
				dragging = Vector2i(place, index)
				var preview := Piece.new()
				preview.place = place
				set_drag_preview(preview)
				return {"type": "base_ten_piece", "place": place, "source": self, "index": index}
	return null

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not editable or not data is Dictionary: return false
	if data.get("type") == "number_digit":
		return data.get("digit") is int and data.digit >= 0 and data.digit <= 9 and _place_at(at) >= 0
	if data.get("type") != "base_ten_piece" or not data.get("place") is int: return false
	var place := int(data.place)
	if place < 0 or place >= width or _place_at(at) != place: return false
	if data.get("source") != null and data.get("source") != self: return false
	return data.get("source") == self or counts[place] < (9 if place == width - 1 else 10)

func _place_at(at: Vector2) -> int:
	for place in range(width):
		if column_rect(place).has_point(at): return place
	return -1

func _drop_data(at: Vector2, data: Variant) -> void:
	if not _can_drop_data(at, data): return
	if data.type == "number_digit":
		_select_at(at)
		set_digit(int(data.digit))
	elif data.get("source") == self:
		motions.append({"place": int(data.place), "index": int(data.get("index", 0)), "from": at, "time": 0.0})
	else: add_piece(int(data.place), 1, at)
	dragging = Vector2i(-1, -1)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		dragging = Vector2i(-1, -1)
		queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	var moving := pulse > 0 or not motions.is_empty()
	pulse = maxf(0, pulse - delta * 2.2)
	for motion in motions: motion.time += delta * 2.4
	for i in range(motions.size() - 1, -1, -1):
		if motions[i].time >= 1: motions.remove_at(i)
	if moving and is_visible_in_tree(): queue_redraw()

func _label(text_: String, rect: Rect2, fs: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var baseline := rect.position.y + (rect.size.y + font.get_ascent(fs) - font.get_descent(fs)) * 0.5
	draw_string(font, Vector2(rect.position.x, baseline), text_, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fs, color)

func _draw() -> void:
	for place in range(width):
		var rect := column_rect(place)
		var color: Color = Rules.COLORS[place]
		draw_style_box(UI.style(color.lightened(0.91), color if highlighted == place else color.lightened(0.48), 18, 0), rect)
		_label(NAMES[place], Rect2(rect.position + Vector2(0, 6), Vector2(rect.size.x, 25)), 21, color.darkened(0.1))
		_label("Cada pieza vale " + str(int(pow(10, place))), Rect2(rect.position + Vector2(0, 32), Vector2(rect.size.x, 21)), 16, color.darkened(0.15))
		_label(str(counts[place]) + (" pieza" if counts[place] == 1 else " piezas"), Rect2(rect.position + Vector2(0, 55), Vector2(rect.size.x, 28)), 23, color)
		for index in range(counts[place]):
			if dragging == Vector2i(place, index): continue
			var piece := piece_rect(place, index)
			var center := piece.get_center()
			for motion in motions:
				if int(motion.place) == place and int(motion.index) == index:
					var t := smoothstep(0, 1, float(motion.time))
					center = Vector2(motion.from).lerp(center, t) + Vector2(0, -sin(t * PI) * 25)
			Piece.paint(self, place, center, piece.size.x)
		if counts[place] == 0:
			_label("Sin piezas: 0", Rect2(rect.position + Vector2(0, 91), Vector2(rect.size.x, maxf(20, rect.size.y - 165))), 19, color.darkened(0.1))
		var y := rect.size.y - (70 if editable else 31)
		_label("Aquí hay " + str(counts[place] * int(pow(10, place))), Rect2(rect.position + Vector2(0, y), Vector2(rect.size.x, 25)), 18, color.darkened(0.1))
	if show_total: _label("Número formado: %d" % Rules.value(counts), Rect2(0, size.y - 35, size.x, 35), 25, Color("#174765"))
