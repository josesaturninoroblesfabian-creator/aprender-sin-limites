extends Control

signal gate_requested(index: int)
signal reached_goal
signal sound_requested(id: String)
signal checkpoint_changed
signal pause_requested
const UI = preload("res://scripts/math/math_ui.gd")
const LOGICAL := Vector2(1280, 560)
const WORLD_END := 3500.0
const FLOOR := 420.0
const GATES := [800.0, 1650.0, 2650.0]
const STAR_POINTS := [Vector2(385, 299), Vector2(1055, 334), Vector2(1800, 299), Vector2(2450, 329), Vector2(3155, 289)]
const PLATFORMS := [Rect2(280, 350, 210, 22), Rect2(950, 385, 210, 22), Rect2(1690, 350, 220, 22), Rect2(2330, 380, 230, 22), Rect2(3020, 340, 240, 22)]
var position_world := Vector2(100, FLOOR)
var velocity := Vector2.ZERO
var camera := 0.0
var clock := 0.0
var on_floor := true
var facing_right := true
var paused := false
var awaiting_gate := -1
var won := false
var active := true
var opened: Dictionary = {}
var collected: Array[int] = []
var keys: Dictionary = {}
var fingers: Dictionary = {}
var mouse_action := ""
var jump_queued := false
var particles: Array[Dictionary] = []
var stage_index := 0
var platforms: Array[Rect2] = []
var star_points: Array[Vector2] = []
var obstacles: Array[float] = []
var _font: Font = ThemeDB.fallback_font

func _ready() -> void:
	custom_minimum_size = Vector2(600, 400)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	grab_focus()
	configure(stage_index)
	for index in range(64):
		particles.append({"life": 0.0, "p": Vector2.ZERO, "v": Vector2.ZERO, "color": Color.WHITE})

func configure(index: int) -> void:
	stage_index = clampi(index, 0, 11)
	platforms.clear()
	star_points.clear()
	for item in range(5):
		var rect: Rect2 = PLATFORMS[item]
		var offset := float((stage_index + item) % 3 * 9)
		rect.position.y -= offset
		platforms.append(rect)
		star_points.append(STAR_POINTS[item] - Vector2(0, offset))
	obstacles.clear()
	var crate_positions := [575.0, 1310.0, 2120.0, 2930.0]
	for item in range(1 + stage_index / 3):
		obstacles.append(crate_positions[item])

func restore(gates: Dictionary, stars: Array) -> void:
	opened.clear()
	for index in range(3):
		if gates.has(index): opened[index] = true
	collected.clear()
	for star in stars:
		if int(star) in range(5) and int(star) not in collected:
			collected.append(int(star))
	position_world = Vector2(100, FLOOR)
	for index in range(3):
		if opened.has(index): position_world.x = GATES[index] + 100
	velocity = Vector2.ZERO
	on_floor = true

func clear_input() -> void:
	keys.clear()
	fingers.clear()
	mouse_action = ""
	jump_queued = false
	velocity.x = 0

func set_paused(value: bool) -> void:
	paused = value
	clear_input()

func open_gate(index: int) -> void:
	if index != awaiting_gate: return
	opened[index] = true
	awaiting_gate = -1
	clear_input()
	_burst(Vector2(GATES[index], 310), Color("#ffe598"))
	checkpoint_changed.emit()

func _process(delta: float) -> void:
	if not active: return
	clock += delta
	for particle in particles:
		if particle.life > 0:
			particle.life -= delta
			particle.p += particle.v * delta
			particle.v.y += 220 * delta
	if not paused and awaiting_gate < 0 and not won:
		_move(minf(delta, 0.04))
	camera = clampf(position_world.x - 430, 0, WORLD_END + 180 - LOGICAL.x)
	queue_redraw()

func _move(delta: float) -> void:
	var right := keys.has(KEY_RIGHT) or keys.has(KEY_D) or mouse_action == "right" or "right" in fingers.values()
	var left := keys.has(KEY_LEFT) or keys.has(KEY_A) or mouse_action == "left" or "left" in fingers.values()
	velocity.x = (float(right) - float(left)) * 300.0
	if absf(velocity.x) > 1: facing_right = velocity.x > 0
	if jump_queued and on_floor:
		velocity.y = -650
		on_floor = false
		sound_requested.emit("jump")
	jump_queued = false
	var previous_y := position_world.y
	velocity.y += 1450.0 * delta
	position_world += velocity * delta
	position_world.x = clampf(position_world.x, 30, WORLD_END + 20)
	on_floor = false
	if position_world.y >= FLOOR:
		position_world.y = FLOOR
		velocity.y = 0
		on_floor = true
	for platform in platforms:
		if velocity.y >= 0 and previous_y <= platform.position.y + 2 and position_world.y >= platform.position.y and position_world.x > platform.position.x - 14 and position_world.x < platform.end.x + 14:
			position_world.y = platform.position.y
			velocity.y = 0
			on_floor = true
	for obstacle in obstacles:
		if absf(position_world.x - obstacle) < 47 and position_world.y > FLOOR - 48:
			position_world.x = obstacle - 47 if velocity.x >= 0 else obstacle + 47
			velocity.x = 0
	for index in range(5):
		if index not in collected and (position_world - Vector2(0, 48)).distance_to(star_points[index]) < 59:
			collected.append(index)
			_burst(star_points[index], Color("#ffe484"))
			sound_requested.emit("star")
			checkpoint_changed.emit()
	for index in range(3):
		if not opened.has(index) and position_world.x >= GATES[index] - 42:
			position_world.x = GATES[index] - 42
			awaiting_gate = index
			clear_input()
			gate_requested.emit(index)
			return
	if position_world.x >= WORLD_END and opened.size() == 3:
		won = true
		clear_input()
		sound_requested.emit("finish")
		reached_goal.emit()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / LOGICAL)
	var environment: int = [2, 0, 1, 3][stage_index / 3]
	draw_texture_rect(UI.backdrop(environment), Rect2(-camera * 0.12, -245, 1600, 900), false)
	draw_rect(Rect2(0, 0, LOGICAL.x, 52), Color(0.015, 0.14, 0.22, 0.87))
	_label("★ %d / 5" % collected.size(), Vector2(30, 35), 25, Color("#ffe59c"))
	_label("Puertas %d / 3" % opened.size(), Vector2(225, 35), 25, Color.WHITE)
	_label("La meta está al final del camino", Vector2(710, 35), 23, Color.WHITE)
	# A continuous floor makes missed jumps recoverable; platforms reward exploration.
	draw_rect(Rect2(0, FLOOR, LOGICAL.x, 40), Color("#bc8955"))
	draw_rect(Rect2(0, FLOOR, LOGICAL.x, 9), Color("#78a84d"))
	for column in range(int(camera / 80), int(camera / 80) + 18):
		var x := column * 80 - camera
		draw_style_box(UI.style(Color("#b9a17c"), Color("#80694c"), 7, 0), Rect2(x, FLOOR + 12, 76, 26))
	for platform in platforms:
		var rect := Rect2(platform.position - Vector2(camera, 0), platform.size)
		draw_style_box(UI.style(Color("#b8a486"), Color("#725a40"), 8, 0), rect)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 6)), Color("#7cad56"))
	for obstacle in obstacles:
		var x := obstacle - camera
		draw_texture_rect(UI.object(4), Rect2(x - 32, FLOOR - 57, 64, 57), false)
		if absf(position_world.x - obstacle) < 180:
			_label("↑ Salta", Vector2(x - 30, FLOOR - 74), 18, Color("#123d54"))
	for index in range(5):
		if index in collected: continue
		var point: Vector2 = star_points[index] - Vector2(camera, 0)
		point.y += sin(clock * 3 + index) * 5
		draw_circle(point, 29 + sin(clock * 2) * 3, Color(1, 0.9, 0.38, 0.18))
		draw_texture_rect(UI.object(5), Rect2(point - Vector2(27, 27), Vector2(54, 54)), false)
	for index in range(3):
		var x: float = GATES[index] - camera
		var open := opened.has(index)
		draw_style_box(UI.style(Color("#a48b69"), Color("#65513e"), 14, 0), Rect2(x - 42, FLOOR - 150, 84, 150))
		draw_style_box(UI.style(Color("#92c56c") if open else Color("#956338"), Color("#e7cc83"), 12, 0), Rect2(x - 30, FLOOR - 136, 60, 136))
		_label("✓" if open else "?", Vector2(x - 19, FLOOR - 65), 46, Color.WHITE)
		draw_style_box(UI.style(Color("#fff8dd"), Color("#bc9b5b"), 8, 0), Rect2(x - 57, FLOOR - 188, 114, 34))
		_label("Puerta %d" % (index + 1), Vector2(x - 48, FLOOR - 163), 20, Color("#123d54"))
	var goal := Vector2(WORLD_END - camera, FLOOR)
	draw_line(goal - Vector2(0, 170), goal, Color("#795331"), 8, true)
	draw_colored_polygon(PackedVector2Array([goal - Vector2(0, 170), goal + Vector2(75, -145), goal - Vector2(0, 120)]), Color("#efba32"))
	draw_texture_rect(UI.object(7), Rect2(goal + Vector2(35, -70), Vector2(90, 80)), false)
	_label("META", goal + Vector2(-35, -185), 26, Color("#164858"))
	var frame := 0
	if won: frame = 7
	elif not on_floor: frame = 5 if velocity.y < 0 else 6
	elif absf(velocity.x) > 1: frame = [1, 2, 3, 4][int(clock * 9) % 4]
	var hero := Rect2(position_world - Vector2(camera + 74, 112), Vector2(148, 122))
	if not facing_right:
		hero.position.x += hero.size.x
		hero.size.x *= -1
	draw_texture_rect(UI.runner(frame), hero, false)
	for particle in particles:
		if particle.life > 0:
			draw_circle(particle.p - Vector2(camera, 0), 3.5, Color(particle.color, minf(1, particle.life)))
	_draw_controls()
	if paused:
		draw_rect(Rect2(Vector2.ZERO, LOGICAL), Color(0, 0.06, 0.12, 0.55))
		_label("PAUSA", Vector2(550, 255), 44, Color.WHITE)

func _label(value: String, point: Vector2, font_size: int, color: Color) -> void:
	draw_string(_font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _control_rect(action: String) -> Rect2:
	return {"left": Rect2(22, 470, 86, 72), "right": Rect2(122, 470, 86, 72), "jump": Rect2(1093, 470, 164, 72)}[action]

func _draw_controls() -> void:
	draw_rect(Rect2(0, 460, LOGICAL.x, 100), Color("#153c55"))
	for action in ["left", "right", "jump"]:
		var rect := _control_rect(action)
		var down: bool = action == mouse_action or action in fingers.values()
		draw_style_box(UI.style(Color("#0b6fa5") if not down else Color("#b7731a"), Color("#f7d985"), 16, 0), rect)
		_label({"left": "←", "right": "→", "jump": "↑ Saltar"}[action], rect.position + Vector2(23, 47), 30, Color.WHITE)
	_label("A / D o ← / → para mover · Espacio para saltar", Vector2(245, 507), 21, Color.WHITE)
	_label("En tablet: mantén una flecha y toca Saltar con otro dedo", Vector2(245, 536), 17, Color("#d8eaf0"))

func _action_at(local_point: Vector2) -> String:
	for action in ["left", "right", "jump"]:
		if _control_rect(action).has_point(local_point): return action
	return ""

func _input(event: InputEvent) -> void:
	if not active or not is_visible_in_tree(): return
	if event is InputEventKey and not event.echo:
		var key: int = event.physical_keycode
		if key == 0: key = event.keycode
		if key in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D, KEY_SPACE, KEY_UP, KEY_W]:
			if event.pressed and not paused and awaiting_gate < 0:
				keys[key] = true
				if key in [KEY_SPACE, KEY_UP, KEY_W]: jump_queued = true
			else: keys.erase(key)
			get_viewport().set_input_as_handled()
		elif key == KEY_P and event.pressed:
			pause_requested.emit()
			get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		var action := _action_at(local / size * LOGICAL)
		if event is InputEventScreenTouch and not event.pressed:
			fingers.erase(event.index)
		elif not paused and awaiting_gate < 0 and not action.is_empty():
			fingers[event.index] = action
			if event is InputEventScreenTouch and action == "jump": jump_queued = true
		else:
			fingers.erase(event.index)
		if not action.is_empty(): get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			mouse_action = ""
		elif not paused and awaiting_gate < 0:
			mouse_action = _action_at(event.position / size * LOGICAL)
			if mouse_action == "jump": jump_queued = true
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and active:
		clear_input()
		if not paused and awaiting_gate < 0 and is_inside_tree(): pause_requested.emit()

func _burst(point: Vector2, color: Color) -> void:
	var count := 0
	for particle in particles:
		if particle.life <= 0:
			particle.p = point
			particle.v = Vector2(randf_range(-100, 100), randf_range(-160, -40))
			particle.life = randf_range(0.5, 1.1)
			particle.color = color
			count += 1
			if count == 12: break

func _exit_tree() -> void:
	active = false
	clear_input()
