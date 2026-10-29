extends Control

signal answer_chosen(value: int)
const UI = preload("res://scripts/math/math_ui.gd")
var values: Array[int] = []
var rejected: Dictionary = {}
var clock := 0.0
var active := true
var accepted_value := -1
var solved_clock := 0.0
var _font: Font = ThemeDB.fallback_font

func _ready() -> void:
	custom_minimum_size = Vector2(450, 300)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func reset(options: Array[int]) -> void:
	values = options
	rejected.clear()
	clock = 0
	active = true
	accepted_value = -1
	solved_clock = 0
	queue_redraw()

func balloon_rect(index: int) -> Rect2:
	return Rect2(45 + index * 190, 95 + sin(clock * 1.2 + index * 1.4) * 18, 142, 175)

func _process(delta: float) -> void:
	if active: clock += delta
	elif accepted_value >= 0: solved_clock += delta
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(800, 380))
	for index in range(values.size()):
		var rect := balloon_rect(index)
		var disabled := rejected.has(values[index])
		var modulate_color := Color(0.6, 0.6, 0.6, 0.55) if disabled else Color.WHITE
		draw_line(rect.get_center() + Vector2(0, 75), Vector2(rect.get_center().x + sin(clock + index) * 25, 364), Color(1, 0.94, 0.74, 0.8), 2, true)
		draw_texture_rect(UI.object(6), rect, false, modulate_color)
		var center := rect.get_center() + Vector2(0, -8)
		draw_circle(center, 37, Color("#fff9e9") if not disabled else Color("#c4c6c5"))
		draw_string(_font, center + Vector2(-36, 12), str(values[index]), HORIZONTAL_ALIGNMENT_CENTER, 72, 32, UI.INK)
		if values[index] == accepted_value:
			var side := 90.0 + minf(solved_clock * 80, 35)
			draw_texture_rect(UI.object(5), Rect2(center - Vector2.ONE * side * 0.5, Vector2.ONE * side), false)

func _gui_input(event: InputEvent) -> void:
	if not active: return
	var pressed: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	pressed = pressed or (event is InputEventScreenTouch and event.pressed)
	if not pressed: return
	var point: Vector2 = event.position / size * Vector2(800, 380)
	for index in range(values.size()):
		var rect := balloon_rect(index)
		var relative := (point - rect.get_center()) / (rect.size * 0.5)
		if relative.length_squared() <= 1.0 and not rejected.has(values[index]):
			answer_chosen.emit(values[index])
			accept_event()
			break
