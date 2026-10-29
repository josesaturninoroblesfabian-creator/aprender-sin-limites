extends SceneTree
const Catalog = preload("res://scripts/geometry/geometry_catalog.gd")
const Shapes = preload("res://scripts/geometry/geometry_shapes.gd")
var checks := 0
var failures := 0
var pointer := Vector2.ZERO
func _initialize() -> void: _run.call_deferred()
func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _settle() -> void:
	for frame in range(3): await process_frame
func _move(at: Vector2, held: bool = false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.relative = at - pointer
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	pointer = at
	Input.parse_input_event(event)
	await _settle()
func _button(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	Input.parse_input_event(event)
	await _settle()
func _click(at: Vector2) -> void:
	await _move(at)
	await _button(at, true)
	await _button(at, false)
func _drag(from: Vector2, to: Vector2) -> void:
	await _move(from)
	await _button(from, true)
	await _move(from + Vector2(20, -18), true)
	_check(root.gui_is_dragging(), "Actual shape drag never started")
	for step in range(1, 7): await _move(from.lerp(to, step / 6.0), true)
	await _button(to, false)
	_check(not root.gui_is_dragging(), "Released shape remained on pointer")
func _touch(at: Vector2, index: int, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.index = index
	event.pressed = pressed
	Input.parse_input_event(event)
	await _settle()
func _run() -> void:
	if OS.get_environment("APRENDE_VALIDATION") != "1":
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	var screen: Control = load("res://scenes/geometry_activity.tscn").instantiate()
	root.add_child(screen)
	screen.audio.set_sound(false, 70)
	screen._start_lesson("flat_shapes_1")
	await _settle()
	var correct: Button
	var incorrect: Button
	for tile in screen.choices:
		if Shapes.token_shape(tile.token) == screen.question.shape: correct = tile
		else: incorrect = tile
	var target: Vector2 = screen.world.global_position + screen.world.slot_rect(0).get_center()
	await _drag(incorrect.get_global_rect().get_center(), target)
	_check(screen.world.placed.is_empty() and not screen.model_done, "Wrong native drag awarded completion")
	await _drag(correct.get_global_rect().get_center(), target)
	_check(screen.model_done and screen.world.placed.size() == 1, "Native drag did not fit exactly one piece")
	await _click(screen.next_button.get_global_rect().get_center())
	_check(screen.view == "practice", "Native next click failed")
	correct = null
	for tile in screen.choices:
		if Shapes.token_shape(tile.token) == screen.question.shape: correct = tile
	await _click(correct.get_global_rect().get_center())
	await _click(screen.world.global_position + screen.world.slot_rect(0).get_center())
	_check(screen.solved_current, "Tap-piece then tap-hole alternative failed")
	screen.queue_free()
	await _settle()
	screen = load("res://scenes/geometry_activity.tscn").instantiate()
	screen.topic_id = "solid_shapes"
	root.add_child(screen)
	screen._start_lesson("solid_shapes_1")
	await _settle()
	var start: Vector2 = screen.solid.get_global_rect().get_center()
	var yaw: float = screen.solid.yaw
	await _move(start)
	await _button(start, true)
	await _move(start + Vector2(85, 20), true)
	await _button(start + Vector2(85, 20), false)
	_check(screen.solid.interaction_count > 0 and screen.solid.yaw != yaw, "Native body drag failed to rotate mesh")
	screen.queue_free()
	await _settle()
	screen = load("res://scenes/geometry_activity.tscn").instantiate()
	screen.topic_id = "sides_vertices"
	root.add_child(screen)
	screen._start_lesson("sides_vertices_1")
	await _settle()
	_check(screen.choices.all(func(button: Button): return button.disabled), "Count responses enabled before inspecting")
	for index in range(3): await _click(screen.world.global_position + screen.world.part_point(index))
	_check(screen.world.marked.size() == 3 and screen.choices.all(func(button: Button): return not button.disabled), "Native side taps failed")
	for button in screen.choices:
		if button.text == "3":
			await _click(button.get_global_rect().get_center())
			break
	_check(screen.model_done, "Native count answer failed")
	screen.queue_free()
	await _settle()
	screen = load("res://scenes/geometry_activity.tscn").instantiate()
	screen.topic_id = "shape_patterns"
	root.add_child(screen)
	screen._start_lesson("shape_patterns_1")
	screen._show_model()
	await _settle()
	for tile in screen.choices:
		if Shapes.token_shape(tile.token) == screen.question.result[0]: correct = tile
	await _touch(correct.get_global_rect().get_center(), 0, true)
	await _touch(correct.get_global_rect().get_center(), 0, false)
	var hole: Vector2 = screen.world.global_position + screen.world.slot_rect(screen.question.holes[0]).get_center()
	await _touch(hole, 0, true)
	await _touch(hole, 0, false)
	_check(screen.model_done, "Native touch piece/slot did not complete pattern")
	screen.queue_free()
	await _settle()
	screen = load("res://scenes/geometry_activity.tscn").instantiate()
	screen.topic_id = "quick_challenge"
	root.add_child(screen)
	screen._start_game()
	await _settle()
	var left: Button
	var rise: Button
	for button in screen.find_children("*", "Button", true, false):
		if button.text == "◀ Izquierda": left = button
		if button.text == "▲ Subir": rise = button
	await _touch(left.get_global_rect().get_center(), 1, true)
	await _touch(rise.get_global_rect().get_center(), 2, true)
	_check(screen.world._held("left") and screen.world._held("rise"), "Real two-finger button input did not hold both actions")
	await _touch(left.get_global_rect().get_center(), 1, false)
	_check(not screen.world._held("left") and screen.world._held("rise"), "Real finger release cancelled another control")
	await _touch(rise.get_global_rect().get_center(), 2, false)
	left.grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_RIGHT
	key.pressed = true
	Input.parse_input_event(key)
	await _settle()
	_check(screen.world.keys.get(KEY_RIGHT, false), "Focused button swallowed flight keyboard input")
	key = InputEventKey.new()
	key.keycode = KEY_RIGHT
	key.pressed = false
	Input.parse_input_event(key)
	await _settle()
	_check(not screen.world.keys.get(KEY_RIGHT, false), "Released flight key remained held")
	var correct_index: int = screen.world.options.find(screen.question.result)
	if correct_index < 0:
		for i in range(screen.world.options.size()):
			if preload("res://scripts/geometry/geometry_rules.gd").matches(screen.question, screen.world.options[i]): correct_index = i
	await _click(screen.world.global_position + screen.world.option_rect(correct_index).get_center())
	_check(screen.world.target == correct_index, "Real cloud click did not start flight")
	for step in range(120): screen.world._process(1.0 / 60)
	_check(screen.solved_current and screen.score == 10, "Real flight did not award correct answer once")
	screen.queue_free()
	await _settle()
	await create_timer(0.5).timeout
	print("GEOMETRY INPUT TEST: %d checks, %d failure(s)" % [checks, failures])
	quit(0 if failures == 0 else 1)

