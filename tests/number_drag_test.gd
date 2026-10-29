extends SceneTree

const Catalog = preload("res://scripts/numbers/number_catalog.gd")
var checks := 0
var failures := 0
var pointer := Vector2.ZERO

func _initialize() -> void:
	_run.call_deferred()

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
	await _move(from + Vector2(18, -18), true)
	_check(root.gui_is_dragging(), "A real mouse drag did not start a piece preview")
	for step in range(1, 7): await _move(from.lerp(to, float(step) / 6), true)
	await _button(to, false)
	_check(not root.gui_is_dragging(), "The piece stayed attached to the pointer after release")

func _run() -> void:
	if OS.get_environment("APRENDE_VALIDATION") != "1":
		push_error("Run tools/validate.ps1 to isolate player saves.")
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	for width in range(1, 5):
		var screen: Control = load("res://scenes/number_activity.tscn").instantiate()
		screen.topic_id = Catalog.TOPICS[width - 1]
		root.add_child(screen)
		screen.audio.set_sound(false, 70)
		screen._start_lesson(screen.topic_id + "_2")
		await _settle()
		var board: Control = screen.board
		var tray: Button = screen.find_child("AddPiece_0", true, false)
		var target: Vector2 = board.get_global_rect().position + board.column_rect(0).get_center()
		await _drag(tray.get_global_rect().get_center(), target)
		_check(board.counts[0] == 1, "Dragging one unit did not add exactly one unit")
		await _click(tray.get_global_rect().get_center())
		_check(board.counts[0] == 2, "A real click on Add did not add a piece")
		await _click(board.remove_buttons[0].get_global_rect().get_center())
		_check(board.counts[0] == 1, "A real click on Remove did not remove a piece")
		var piece: Vector2 = board.get_global_rect().position + board.piece_rect(0, 0).get_center()
		await _drag(piece, tray.get_global_rect().get_center())
		_check(board.counts[0] == 0, "Returning an existing piece to its tray did not remove it")
		await _drag(tray.get_global_rect().get_center(), target)
		_check(board.counts[0] == 1, "A piece could not be moved after returning another")
		if width > 1:
			var wrong_column: Vector2 = board.get_global_rect().position + board.column_rect(1).get_center()
			await _drag(tray.get_global_rect().get_center(), wrong_column)
			_check(board.counts[0] == 1 and board.counts[1] == 0, "A unit became a ten when dropped in the wrong column")
			piece = board.get_global_rect().position + board.piece_rect(0, 0).get_center()
			await _drag(piece, wrong_column)
			_check(board.counts[0] == 1 and board.dragging == Vector2i(-1, -1), "An invalid drag lost or hid the existing piece")
		screen.queue_free()
		await _settle()
	await create_timer(0.5).timeout
	print("NUMBER DRAG TEST: %d checks, %d failure(s)" % [checks, failures])
	quit(0 if failures == 0 else 1)
