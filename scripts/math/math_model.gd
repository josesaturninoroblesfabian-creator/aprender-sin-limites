extends Control

signal counted(index: int)
const UI = preload("res://scripts/math/math_ui.gd")
const Rules = preload("res://scripts/math/math_rules.gd")
var question: Dictionary = {}
var step := 0
var mode := "operation"
var count_total := 0
var item_kind := 0
var selected: Dictionary = {}
var clock := 0.0
var motion := 1.0
var previous_value := 0
var rects: Array[Rect2] = []
var reveal := false
var _font: Font = ThemeDB.fallback_font

func _ready() -> void:
	custom_minimum_size = Vector2(430, 295)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func set_question(value: Dictionary, show_result: bool = false) -> void:
	question = value
	mode = "operation"
	step = 0
	reveal = show_result
	previous_value = Rules.visible_value(question, 0)
	motion = 1.0
	queue_redraw()

func advance() -> bool:
	if question.is_empty() or step >= Rules.action_target(question): return false
	previous_value = Rules.visible_value(question, step)
	step += 1
	motion = 0.0
	queue_redraw()
	return step == Rules.action_target(question)

func setup_count(total: int, kind: int) -> void:
	mode = "count"
	count_total = total
	item_kind = kind
	selected.clear()
	rects.clear()
	var columns := 5
	var rows := ceili(float(total) / columns)
	var gap := minf(78, 290.0 / rows)
	for index in range(total):
		var center := Vector2(150 + index % columns * 122, 95 + index / columns * gap)
		rects.append(Rect2(center, Vector2(70, 70)))
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	motion = minf(1.0, motion + delta * 2.7)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(800, 420))
	if mode == "count":
		_draw_count()
		return
	if question.is_empty(): return
	_title(Rules.expression(question, reveal or step == Rules.action_target(question)), Vector2(400, 43), 37)
	match question.operation:
		"addition", "subtraction": _draw_line_model()
		"multiplication": _draw_groups()
		"division": _draw_sharing()

func _title(value: String, point: Vector2, font_size: int = 22, color: Color = UI.INK, width: float = 770) -> void:
	draw_string(_font, point - Vector2(width * 0.5, 0), value, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)

func _icon(index: int, rect: Rect2, alpha: float = 1.0) -> void:
	var side := minf(rect.size.x, rect.size.y)
	var fitted := Rect2(rect.get_center() - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	draw_texture_rect(UI.object(index), fitted, false, Color(1, 1, 1, alpha))

func _draw_count() -> void:
	_title("Toca cada objeto para marcarlo", Vector2(400, 43), 27)
	for index in range(rects.size()):
		var rect := rects[index]
		var offset := Vector2(0, sin(clock * 1.7 + index) * 1.7)
		if selected.has(index):
			draw_circle(rect.get_center() + offset, 44, Color("#e2f5cf"))
			draw_arc(rect.get_center() + offset, 42, 0, TAU, 36, Color("#338342"), 3, true)
		_icon(item_kind, Rect2(rect.position + offset, rect.size))
		if selected.has(index):
			var number: int = selected[index]
			draw_circle(rect.position + Vector2(60, 4), 17, UI.BLUE)
			_title(str(number), rect.position + Vector2(60, 11), 19, Color.WHITE, 35)
	_title("Has marcado %d" % selected.size(), Vector2(400, 407), 22, Color("#276b3c"))

func _draw_line_model() -> void:
	var a := int(question.a)
	var b := int(question.b)
	var small := maxi(a, b) <= 20 and int(question.result) <= 20
	if small:
		var left := Rect2(28, 69, 348, 168)
		var right := Rect2(424, 69, 348, 168)
		draw_style_box(UI.style(Color("#e7f6ff"), Color("#87c2d7")), left)
		draw_style_box(UI.style(Color("#fff0d6"), Color("#e6c58c")), right)
		var remaining := Rules.visible_value(question, step)
		var first_count := a if question.operation == "addition" else remaining
		_draw_pile(first_count, left, 0, 1.0)
		var second_count := b if question.operation == "addition" else a - remaining
		_draw_pile(second_count, right, 0, 1.0 if question.operation == "addition" else 0.35)
		_title("Tenemos %d" % (a if question.operation == "addition" else remaining), Vector2(200, 92), 20)
		_title("Agregamos %d" % b if question.operation == "addition" else "Quitamos %d" % second_count, Vector2(600, 92), 20)
		_title("+" if question.operation == "addition" else "−", Vector2(400, 165), 35)
	else:
		_title("D = decenas · U = unidades", Vector2(400, 73), 17, Color("#56727e"))
		var current := Rules.visible_value(question, step)
		var remaining := b - (current - a if question.operation == "addition" else a - current)
		var exchange: bool = step > 0 and question.operation == "subtraction" and current % 10 < remaining % 10
		var carrying: bool = question.operation == "addition" and step == Rules.action_target(question) and a % 10 + b % 10 >= 10 and motion < 0.7
		_draw_blocks(current, Vector2(48, 65), Color("#167daf"), exchange or carrying)
		_draw_blocks(remaining, Vector2(425, 65), Color("#ae6813"))
		var caption := "Faltan %d por %s" % [remaining, "agregar" if question.operation == "addition" else "quitar"]
		if exchange:
			caption = "%d D y %d U → %d D y %d U" % [current / 10, current % 10, current / 10 - 1, current % 10 + 10]
		elif question.operation == "addition" and a % 10 + b % 10 >= 10:
			caption = "10 unidades se cambian por 1 decena"
		_title(caption, Vector2(400, 271), 21, Color("#895919"))
	var value := Rules.visible_value(question, step)
	var maximum := maxi(a, int(question.result))
	var lower := 0 if small else mini(a, int(question.result)) / 10 * 10
	var upper := (5 if maximum <= 5 else (10 if maximum <= 10 else 20)) if small else maxi(lower + 20, int(ceil(float(maximum) / 10.0)) * 10)
	var y := 335.0
	var x_start := 43.0
	var x_end := 756.0
	draw_line(Vector2(x_start, y), Vector2(x_end, y), Color("#558aa4"), 4, true)
	var interval := 1 if small else 10
	for number in range(lower, upper + 1, interval):
		var x := lerpf(x_start, x_end, float(number - lower) / (upper - lower))
		draw_line(Vector2(x, y - 7), Vector2(x, y + 7), Color("#558aa4"), 2, true)
		_title(str(number), Vector2(x, y + 29), 21 if upper <= 10 else 17, UI.INK, 42)
	var from_x := lerpf(x_start, x_end, float(previous_value - lower) / (upper - lower))
	var to_x := lerpf(x_start, x_end, float(value - lower) / (upper - lower))
	var amount := ease(motion, -2.0)
	var current_x := lerpf(from_x, to_x, amount)
	if step > 0:
		var points := PackedVector2Array()
		for index in range(25):
			var t := float(index) / 24
			points.append(Vector2(lerpf(from_x, to_x, t), y - 10 - sin(PI * t) * 37))
		draw_polyline(points, Color("#dd8d12"), 4, true)
	var dot := Vector2(current_x, y - 13 - sin(PI * amount) * 37)
	draw_circle(dot, 17, Color("#ffe79b"))
	draw_circle(dot, 10, Color("#d8870f"))
	if small:
		var hero := Rect2(dot - Vector2(26, 52), Vector2(52, 52))
		if question.operation == "subtraction":
			hero.position.x += 52
			hero.size.x = -52
		draw_texture_rect(UI.runner(5 if motion < 1 else 0), hero, false)
	_title("Empieza en %d" % a if step == 0 else "Ahora estás en %d" % value, Vector2(400, 405), 23, UI.BLUE)

func _draw_pile(total: int, area: Rect2, kind: int, alpha: float) -> void:
	var columns := 5
	var rows := maxi(1, ceili(float(total) / columns))
	var h := minf(47, 115.0 / rows)
	for index in range(total):
		var position := area.position + Vector2(40 + index % columns * 54, 33 + index / columns * h)
		_icon(kind, Rect2(position, Vector2(43, h)), alpha)

func _draw_blocks(value: int, position: Vector2, color: Color, exchange: bool = false) -> void:
	var tens := value / 10 - (1 if exchange and value >= 10 else 0)
	var units := value % 10 + (10 if exchange and value >= 10 else 0)
	_title(str(value), position + Vector2(140, 20), 30, color, 280)
	for index in range(tens):
		for unit in range(10):
			draw_style_box(UI.style(color.lightened(0.32), color, 2, 0), Rect2(position + Vector2(index * 27, 35 + unit * 10), Vector2(22, 9)))
	for unit in range(units):
		draw_style_box(UI.style(Color("#f4bf3b"), Color("#b48011"), 3, 0), Rect2(position + Vector2(190 + unit % 3 * 25, 35 + unit / 3 * 25), Vector2(20, 20)))
	_title("%d D   %d U" % [tens, units], position + Vector2(140, 165), 21, color, 280)

func _draw_groups() -> void:
	var groups := int(question.a)
	var each := int(question.b)
	var row_height := minf(45, 300.0 / groups)
	var icon_size := minf(36, row_height - 7)
	for row_index in range(groups):
		var y := 65 + row_index * row_height
		var color := Color("#e2f0db") if row_index < step else Color("#f2eddf")
		draw_style_box(UI.style(color, Color("#aac4a1"), 9, 0), Rect2(158, y, 500, row_height - 4))
		_title("Grupo %d" % (row_index + 1), Vector2(90, y + row_height * 0.68), 18, UI.INK, 130)
		for column in range(each):
			var opacity := motion if row_index == step - 1 else (1.0 if row_index < step else 0.28)
			_icon(0, Rect2(185 + column * minf(46, 435.0 / each), y + 1, icon_size, icon_size), opacity)
	var total := Rules.visible_value(question, step)
	_title("%d grupos de %d = %d" % [step, each, total] if step == groups else "Grupos formados: %d de %d · Total: %d" % [step, groups, total], Vector2(400, 407), 25, Color("#693b9c"))

func _draw_sharing() -> void:
	var total := int(question.a)
	var baskets := int(question.b)
	var remaining := total - step * baskets
	_title("Para repartir: %d" % remaining, Vector2(400, 78), 24, Color("#9a5c17"))
	var columns := mini(3, baskets)
	var rows := ceili(float(baskets) / columns)
	var cell_h := minf(125, 280.0 / rows)
	var cell_w := minf(235, 710.0 / columns)
	var start_x := 400 - cell_w * columns * 0.5
	for index in range(baskets):
		var origin := Vector2(start_x + index % columns * cell_w, 97 + index / columns * cell_h)
		_icon(3, Rect2(origin + Vector2(25, cell_h * 0.29), Vector2(cell_w - 50, cell_h * 0.54)))
		for fruit in range(step):
			var side := minf(25, cell_h * 0.27)
			var destination := origin + Vector2(cell_w * 0.27 + fruit % 3 * side, fruit / 3 * side * 0.7 + 5)
			if fruit == step - 1 and motion < 1: destination = Vector2(400, 84).lerp(destination, ease(motion, -2.0))
			_icon(0, Rect2(destination, Vector2(side, side)))
		_title("Cesta %d: %d" % [index + 1, step], origin + Vector2(cell_w * 0.5, cell_h - 4), 18, UI.INK, cell_w)
	_title("Todas reciben lo mismo: %d en cada una" % step, Vector2(400, 407), 23, UI.BLUE)

func _gui_input(event: InputEvent) -> void:
	if mode != "count": return
	var pressed: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	pressed = pressed or (event is InputEventScreenTouch and event.pressed)
	if not pressed: return
	var point: Vector2 = event.position / size * Vector2(800, 420)
	for index in range(rects.size()):
		if rects[index].grow(7).has_point(point) and not selected.has(index):
			selected[index] = selected.size() + 1
			counted.emit(index)
			queue_redraw()
			accept_event()
			break
