extends Control

signal arrived(value: Variant)
const Shapes = preload("res://scripts/geometry/geometry_shapes.gd")
const Art = preload("res://scripts/geometry/geometry_art.gd")
const UI = preload("res://scripts/math/math_ui.gd")
var options: Array = []
var question: Dictionary = {}
var balloon_point := Vector2(0.5, 0.86)
var target := -1
var phase := "flying"
var active := true
var keys: Dictionary = {}
var touches: Dictionary = {}
var mouse_actions: Dictionary = {}
var rejected: Dictionary = {}
var clock := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(600, 280)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true
	resized.connect(queue_redraw)

func setup(item: Dictionary, values: Array) -> void:
	question = item
	options = values.duplicate()
	balloon_point = Vector2(0.5, 0.86)
	target = -1
	phase = "flying"
	rejected.clear()
	clear_controls()
	queue_redraw()

func clear_controls() -> void:
	keys.clear()
	touches.clear()
	mouse_actions.clear()

func set_paused(paused: bool) -> void:
	active = not paused
	if paused: clear_controls()

func set_touch(index: int, action: String, pressed: bool) -> void:
	if not active: return
	if pressed: touches[index] = action
	else: touches.erase(index)

func _held(action: String) -> bool:
	return mouse_actions.get(action, false) or action in touches.values()

func option_rect(index: int) -> Rect2:
	var width := minf(185, size.x / 4.0 - 20)
	return Rect2(size.x * (index + 0.5) / 4 - width * 0.5, 13, width, 112)

func choose(index: int) -> bool:
	if not active or phase != "flying" or index < 0 or index >= options.size() or rejected.has(index): return false
	target = index
	return true

func accept() -> void:
	phase = "solved"
	clear_controls()

func reject() -> void:
	if target >= 0: rejected[target] = true
	phase = "return"
	target = -1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_touch(event.position)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_touch(event.position)
		accept_event()

func _touch(at: Vector2) -> void:
	for index in range(options.size()):
		if option_rect(index).has_point(at):
			choose(index)
			break

func _process(delta: float) -> void:
	if not active: return
	clock += delta
	var at := balloon_point * size
	if phase == "return":
		at = at.move_toward(Vector2(0.5, 0.86) * size, delta * size.y * 1.15)
		if at.distance_to(Vector2(0.5, 0.86) * size) < 2: phase = "flying"
	elif phase == "flying":
		if target >= 0:
			at = at.move_toward(option_rect(target).get_center(), delta * maxf(300, size.y * 1.15))
		else:
			var horizontal := (1 if _held("right") or keys.get(KEY_RIGHT, false) or keys.get(KEY_D, false) else 0) - (1 if _held("left") or keys.get(KEY_LEFT, false) or keys.get(KEY_A, false) else 0)
			var rise: bool = _held("rise") or keys.get(KEY_UP, false) or keys.get(KEY_SPACE, false)
			at.x += horizontal * size.x * delta * 0.42
			at.y += (-0.58 if rise else 0.17) * size.y * delta
		at = at.clamp(Vector2(35, 30), size - Vector2(35, 12))
		for index in range(options.size()):
			if not rejected.has(index) and at.distance_to(option_rect(index).get_center()) < 30:
				target = index
				phase = "awaiting"
				arrived.emit(options[index])
				break
	balloon_point = at / size.max(Vector2.ONE)
	if is_visible_in_tree(): queue_redraw()

func _draw() -> void:
	if options.size() != 4: return
	var scenery := Art.backdrop(3)
	var fit := scenery.get_size() * maxf(size.x / scenery.get_width(), size.y / scenery.get_height())
	draw_texture_rect(scenery, Rect2((size - fit) * 0.5, fit), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.9, 0.97, 1, 0.16))
	var font := ThemeDB.fallback_font
	for index in range(4):
		var rect := option_rect(index)
		var alpha := 0.45 if rejected.has(index) else 0.95
		draw_style_box(UI.style(Color(1, 0.98, 0.89, alpha), Color("#c8aa61"), 30, 0), rect)
		var value: Variant = options[index]
		if value is int:
			draw_string(font, rect.position + Vector2(0, 75), str(value), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 43, Shapes.INK)
		else:
			var token := String(value)
			Shapes.paint(self, Shapes.token_shape(token), rect.grow(-14), Shapes.token_color(token, ["red", "blue", "gold", "green"][index]))
		if rejected.has(index):
			draw_line(rect.position + Vector2(18, 18), rect.end - Vector2(18, 18), Color("#ac4b52"), 5)
	var at := balloon_point * size
	var sway := sin(clock * 2.7) * 3
	draw_texture_rect(Art.object(4), Rect2(at + Vector2(-80, -137 + sway), Vector2(160, 160)), false)
	draw_texture_rect(UI.runner(0), Rect2(at + Vector2(-32, -29 + sway), Vector2(64, 64)), false)
	if phase == "solved": draw_texture_rect(Art.object(7), Rect2(at + Vector2(45, -40), Vector2(50, 50)), false)
	if phase == "flying" and target < 0:
		draw_style_box(UI.style(Color("#fff9e9"), Color("#c8aa61"), 10, 0), Rect2(size.x * 0.5 - 245, size.y - 31, 490, 29))
		draw_string(font, Vector2(0, size.y - 10), "Toca una nube para viajar o usa los controles", HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Shapes.INK)
