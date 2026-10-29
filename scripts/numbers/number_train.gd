extends Control

signal arrived(value: int)
signal lane_changed(index: int)
const UI = preload("res://scripts/math/math_ui.gd")
const Art = preload("res://scripts/numbers/number_art.gd")
var options: Array[int] = []
var lane := 0
var displayed_lane := 0.0
var phase := "choice"
var progress := 0.0
var rejected: Dictionary = {}
var active := true
var clock := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(600, 330)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	resized.connect(queue_redraw)

func setup(values: Array[int]) -> void:
	options = values.duplicate()
	lane = 0
	displayed_lane = 0.0
	phase = "choice"
	progress = 0
	rejected.clear()
	queue_redraw()

func lane_rect(index: int) -> Rect2:
	var height := (size.y - 26) / 4.0
	return Rect2(6, 10 + index * height, size.x - 12, height)

func select_lane(index: int) -> bool:
	if not active or phase != "choice" or index < 0 or index >= options.size() or rejected.has(index): return false
	lane = index
	lane_changed.emit(index)
	queue_redraw()
	return true

func depart() -> bool:
	if not active or phase != "choice" or rejected.has(lane) or options.size() != 4: return false
	phase = "travel"
	progress = 0
	return true

func reject() -> void:
	rejected[lane] = true
	phase = "return"
	progress = 1

func accept() -> void:
	phase = "delivered"
	progress = 1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_touch(event.position)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_touch(event.position)
		accept_event()

func _touch(at: Vector2) -> void:
	for index in range(4):
		if lane_rect(index).has_point(at): select_lane(index)

func _process(delta: float) -> void:
	if not active: return
	clock += delta
	displayed_lane = move_toward(displayed_lane, float(lane), delta * 6)
	if phase == "travel":
		progress = minf(1, progress + delta * 0.85)
		if progress >= 1:
			phase = "arrived"
			arrived.emit(options[lane])
	elif phase == "return":
		progress = maxf(0, progress - delta * 1.6)
		if progress <= 0:
			phase = "choice"
			for index in range(4):
				if not rejected.has(index):
					select_lane(index)
					break
	if is_visible_in_tree(): queue_redraw()

func _draw() -> void:
	if options.size() != 4: return
	var font := ThemeDB.fallback_font
	for index in range(4):
		var rect := lane_rect(index)
		var selected := index == lane
		var color := Color(1, 0.93, 0.62, 0.63) if selected else Color(0.05, 0.28, 0.28, 0.27)
		if rejected.has(index): color = Color(0.36, 0.2, 0.22, 0.32)
		draw_style_box(UI.style(color, Color("#ffd66d") if selected else Color(0.7, 0.83, 0.69, 0.3), 16), rect)
		var center := rect.get_center().y
		var scroll := fmod(clock * 23, 28)
		for sleeper in range(int(size.x / 28)):
			var x := sleeper * 28.0 - scroll
			draw_line(Vector2(x, center - 9), Vector2(x, center + 10), Color("#a27e50"), 6)
		draw_line(Vector2(15, center - 6), Vector2(size.x - 135, center - 6), Color("#dce4de"), 3)
		draw_line(Vector2(15, center + 6), Vector2(size.x - 135, center + 6), Color("#85968d"), 3)
		var station := Rect2(size.x - 131, center - 38, 63, 77)
		draw_texture_rect(Art.object(4), station, false, Color(1, 1, 1, 0.5 if rejected.has(index) else 1))
		var tag := Rect2(size.x - 260, center - 27, 125, 54)
		draw_style_box(UI.style(Color("#fff9df"), Color("#aa8140"), 12), tag)
		draw_string(font, Vector2(tag.position.x, center + 11), str(options[index]), HORIZONTAL_ALIGNMENT_CENTER, tag.size.x, 31, Color("#34505e"))
		draw_string(font, Vector2(9, center + 8), str(index + 1), HORIZONTAL_ALIGNMENT_CENTER, 35, 23, Color("#fff5cf"))
	var lane_h := (size.y - 26) / 4.0
	var y := 10 + (displayed_lane + 0.5) * lane_h
	var x := lerpf(185, size.x - 335, smoothstep(0, 1, progress))
	var bob := sin(clock * 16) * 1.3 if phase == "travel" else 0.0
	draw_texture_rect(Art.object(1), Rect2(x - 127, y - 30 + bob, 97, 65), false)
	draw_texture_rect(Art.object(0), Rect2(x - 40, y - 39 + bob, 112, 80), false)
	draw_texture_rect(UI.runner(0), Rect2(x - 19, y - 58 + bob, 50, 50), false)
	for puff in range(4):
		var age := fmod(clock * 1.4 + puff * 0.25, 1.0)
		var point := Vector2(x + 38 - age * 55, y - 43 - age * 42)
		draw_circle(point, 3 + age * 7, Color(1, 0.97, 0.9, (1 - age) * 0.6))
	if phase == "delivered":
		draw_texture_rect(Art.object(7), Rect2(size.x - 68, y - 30, 60, 60), false)
