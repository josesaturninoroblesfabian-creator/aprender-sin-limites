extends Control

signal changed
signal attempted(correct: bool)
signal completed
const Shapes = preload("res://scripts/geometry/geometry_shapes.gd")
const Rules = preload("res://scripts/geometry/geometry_rules.gd")
const UI = preload("res://scripts/math/math_ui.gd")
var question: Dictionary = {}
var selected_token := ""
var placed: Dictionary = {}
var marked: Dictionary = {}
var active := true
var locked := false
var show_hint := false
var angle_extra := 0.0
var clock := 0.0
var flash := 0.0
var llama_x := 50.0
var llama_target := 50.0
var trail_from := Vector2.ZERO
var trail_to := Vector2.ZERO
var trail_progress := 1.0
var flights: Array[Dictionary] = []

func _ready() -> void:
	custom_minimum_size = Vector2(350, 255)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true
	resized.connect(queue_redraw)

func setup(item: Dictionary) -> void:
	question = item
	selected_token = ""
	placed.clear()
	marked.clear()
	flights.clear()
	angle_extra = 0
	active = true
	locked = false
	show_hint = false
	queue_redraw()

func select(token: String) -> void:
	if not active or locked or token not in question.get("options", []): return
	selected_token = token
	changed.emit()
	queue_redraw()

func slot_rect(index: int) -> Rect2:
	if question.kind == "plane":
		var side := minf(size.y - 48, size.x * 0.58)
		return Rect2(Vector2(size.x * 0.5, size.y * 0.46) - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	var count: int = question.get("sequence", []).size()
	var cell := minf(115.0, (size.x - 16) / maxi(1, count))
	return Rect2((size.x - cell * count) * 0.5 + index * cell + 4, size.y * 0.35, cell - 8, cell - 8)

func holes() -> Array:
	return [0] if question.kind == "plane" else question.get("holes", [])

func expected_token(index: int) -> String:
	return String(question.shape) if question.kind == "plane" else String(question.sequence[index])

func fit(token: String, index: int, origin: Vector2 = Vector2.INF) -> bool:
	if not active or locked or index not in holes() or placed.has(index) or token not in question.get("options", []): return false
	var correct := Rules.token_matches(token, expected_token(index), question.get("color_matters", false))
	attempted.emit(correct)
	if not correct:
		flash = 0.5
		queue_redraw()
		return false
	placed[index] = token
	if origin.is_finite(): flights.append({"token": token, "from": origin, "slot": index, "time": 0.0})
	changed.emit()
	if is_complete(): completed.emit()
	queue_redraw()
	return true

func inspected() -> bool:
	if question.kind != "count": return false
	return marked.size() == (1 if question.shape == "circle" else int(Shapes.SIDES[question.shape]))

func is_complete() -> bool:
	if question.kind == "count": return inspected()
	if question.kind == "find": return marked.size() == question.result.size()
	return placed.size() == holes().size()

func state() -> Dictionary:
	return {"placed": placed.duplicate(), "marked": marked.keys()}

func restore(state_: Dictionary) -> void:
	var raw: Variant = state_.get("placed", {})
	if raw is Dictionary and question.kind in ["plane", "pattern"]:
		for index in holes():
			var token: Variant = raw.get(index, raw.get(str(index), ""))
			if token is String and token in question.options and Rules.token_matches(token, expected_token(index), question.get("color_matters", false)): placed[index] = token
	var ids: Variant = state_.get("marked", [])
	if ids is Array and question.kind in ["count", "find"]:
		for value in ids:
			if not (value is int or value is float): continue
			var id := int(value)
			if question.kind == "find" and id in question.result: marked[id] = marked.size() + 1
			elif question.kind == "count" and id >= 0 and id < (1 if question.shape == "circle" else int(Shapes.SIDES[question.shape])): marked[id] = marked.size() + 1
	changed.emit()
	queue_redraw()

func turn(degrees: float) -> void:
	if not active or question.kind != "plane": return
	angle_extra += degrees
	queue_redraw()

func shape_center() -> Vector2:
	return Vector2(size.x * 0.5, size.y * 0.47)

func shape_radius() -> float:
	return minf(size.x * 0.3, size.y * 0.30)

func polygon() -> PackedVector2Array:
	return Shapes.points(question.shape, shape_center(), shape_radius(), float(question.get("angle", 0)))

func part_point(index: int) -> Vector2:
	if question.shape == "circle": return shape_center() + Vector2(shape_radius(), 0)
	var points := polygon()
	return points[index] if question.part == "vertices" else (points[index] + points[(index + 1) % points.size()]) * 0.5

func mark_at(at: Vector2) -> bool:
	if not active or locked or question.kind != "count": return false
	var index := -1
	if question.shape == "circle":
		if absf(at.distance_to(shape_center()) - shape_radius()) <= 23: index = 0
	else:
		var points := polygon()
		var nearest := 24.0
		for i in range(points.size()):
			var distance := at.distance_to(points[i])
			if question.part == "sides":
				var a := points[i]
				var b := points[(i + 1) % points.size()]
				var fraction := (at - a).dot(b - a) / a.distance_squared_to(b)
				if fraction < 0.12 or fraction > 0.88: continue
				distance = at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b))
			if distance < nearest:
				nearest = distance
				index = i
	if index < 0 or marked.has(index): return false
	marked[index] = marked.size() + 1
	if question.shape != "circle":
		var points := polygon()
		trail_from = points[index]
		trail_to = points[(index + 1) % points.size()] if question.part == "sides" else points[index]
		trail_progress = 0
	changed.emit()
	queue_redraw()
	return true

func item_rect(index: int) -> Rect2:
	var cell := Vector2((size.x - 24) / 4.0, (size.y - 88) / 2.0)
	var side := minf(cell.x - 16, cell.y - 12)
	var center := Vector2(12, 6) + Vector2(index % 4 + 0.5, index / 4 + 0.5) * cell
	return Rect2(center - Vector2.ONE * side * 0.5, Vector2.ONE * side)

func find_at(at: Vector2) -> bool:
	if not active or locked or question.kind != "find": return false
	for index in range(question.items.size()):
		var item: Dictionary = question.items[index]
		var rect := item_rect(index)
		var radius := rect.size.x * 0.42 * float(item.scale)
		if not Shapes.hit(item.shape, at, rect.get_center(), radius, item.angle): continue
		if marked.has(index): return false
		var correct: bool = item.shape == question.target
		attempted.emit(correct)
		if not correct:
			flash = 0.4
			return false
		marked[index] = marked.size() + 1
		llama_target = rect.get_center().x
		changed.emit()
		if is_complete(): completed.emit()
		queue_redraw()
		return true
	return false

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not active or locked or question.kind not in ["plane", "pattern"] or not data is Dictionary or data.get("type") != "geometry_tile" or data.get("token") not in question.options: return false
	for index in holes():
		if not placed.has(index) and slot_rect(index).grow(8).has_point(at): return true
	return false

func _drop_data(at: Vector2, data: Variant) -> void:
	if not _can_drop_data(at, data): return
	for index in holes():
		if slot_rect(index).grow(8).has_point(at):
			fit(String(data.token), index, at)
			break

func _touch(at: Vector2) -> void:
	match question.get("kind", ""):
		"count": mark_at(at)
		"find": find_at(at)
		"plane", "pattern":
			if not selected_token.is_empty():
				for index in holes():
					if slot_rect(index).grow(8).has_point(at): fit(selected_token, index, at)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_touch(event.position)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_touch(event.position)
		accept_event()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT and question.get("kind") == "count": _touch(event.position)
	elif event is InputEventScreenDrag and question.get("kind") == "count": _touch(event.position)

func _process(delta: float) -> void:
	if not active: return
	clock += delta
	flash = maxf(0, flash - delta)
	llama_x = move_toward(llama_x, llama_target, delta * 250)
	trail_progress = minf(1, trail_progress + delta * 2)
	for flight in flights: flight.time += delta * 3
	for i in range(flights.size() - 1, -1, -1):
		if flights[i].time >= 1: flights.remove_at(i)
	if is_visible_in_tree(): queue_redraw()

func _label(text_: String, rect: Rect2, fs: int = 21, color: Color = Shapes.INK) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.get_center().y + fs * 0.35), text_, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fs, color)

func _draw() -> void:
	if question.is_empty(): return
	match question.kind:
		"plane":
			var rect := slot_rect(0)
			Shapes.paint(self, question.shape, rect, Shapes.COLORS.get(question.get("color", "blue")), float(question.get("angle", 0)) + angle_extra, not placed.has(0))
			_label("¡Encajó!" if placed.has(0) else "Aquí va tu pieza", Rect2(0, size.y - 43, size.x, 35))
		"pattern":
			for index in range(question.sequence.size()):
				var rect := slot_rect(index)
				if index in question.holes and not placed.has(index):
					draw_style_box(UI.style(Color("#fff2bd"), Color("#b6882b"), 16, 0), rect)
					_label("?", rect, 38)
				else:
					var token: String = placed.get(index, question.sequence[index])
					Shapes.paint(self, Shapes.token_shape(token), rect, Shapes.token_color(token))
			if show_hint:
				var start := slot_rect(0).position + Vector2(0, slot_rect(0).size.y + 10)
				var end := slot_rect(int(question.unit_size) - 1).end + Vector2(0, 10)
				draw_line(start, end, Color("#9b6320"), 4)
				_label("Se repite este grupo", Rect2(start + Vector2(0, 7), Vector2(end.x - start.x, 30)), 18)
			_label("Toca una pieza y después el hueco, o arrástrala", Rect2(0, size.y - 42, size.x, 32), 19)
		"count": _draw_count()
		"find":
			for index in range(question.items.size()):
				var item: Dictionary = question.items[index]
				var rect := item_rect(index)
				if marked.has(index):
					draw_circle(rect.get_center(), rect.size.x * 0.4, Color("#e4f5c8"))
					_label("✓", rect, 42, Color("#218049"))
				else:
					var scale_: float = item.scale
					var fit := Rect2(rect.get_center() - rect.size * scale_ * 0.5, rect.size * scale_)
					Shapes.paint(self, item.shape, fit, Shapes.COLORS[item.color], item.angle)
					if show_hint and item.shape == question.target: draw_arc(rect.get_center(), rect.size.x * 0.46, 0, TAU, 50, Color("#fff1a4"), 4)
			draw_texture_rect(UI.runner(1 + int(clock * 7) % 4 if absf(llama_x - llama_target) > 1 else 0), Rect2(llama_x - 35, size.y - 80, 70, 70), false)
			_label("Encontradas: %d / %d" % [marked.size(), question.result.size()], Rect2(80, size.y - 48, size.x - 160, 35), 25)
	if flash > 0: draw_rect(Rect2(3, 3, size.x - 6, size.y - 6), Color(0.95, 0.54, 0.21, flash), false, 4)

func _draw_count() -> void:
	var radius := shape_radius()
	var center := shape_center()
	if question.shape == "circle":
		draw_arc(center, radius, 0, TAU, 80, Color("#28a2a8") if marked.is_empty() else Color("#d39917"), 8, true)
		_label("Toca su borde curvo" if marked.is_empty() else "Borde curvo · 0 lados rectos", Rect2(0, size.y - 43, size.x, 35), 23)
		return
	var points := polygon()
	var fill: Color = Shapes.COLORS.blue.lightened(0.84)
	draw_colored_polygon(points, fill)
	for i in range(points.size()):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var done := marked.has(i)
		draw_line(a, b, Color("#d49817") if done and question.part == "sides" else Shapes.INK, 8 if done and question.part == "sides" else 4, true)
		if question.part == "vertices" or show_hint: draw_circle(a, 12 if done else 9, Color("#d49817") if done and question.part == "vertices" else Color("#9651b9"))
		if done:
			var at := a if question.part == "vertices" else (a + b) * 0.5
			at += (at - center).normalized() * 25
			_label(str(marked[i]), Rect2(at - Vector2(16, 16), Vector2(32, 32)), 24, Color("#915a09"))
	if not marked.is_empty():
		var at := trail_from.lerp(trail_to, trail_progress)
		draw_texture_rect(UI.runner(1 + int(clock * 7) % 4 if trail_progress < 1 else 0), Rect2(at - Vector2(24, 42), Vector2(48, 48)), false)
	_label("Marcados: %d %s" % [marked.size(), "lados" if question.part == "sides" else "vértices"], Rect2(0, size.y - 43, size.x, 35), 24)
