extends SceneTree

const Tables = preload("res://scripts/math/operation_tables.gd")
const Progress = preload("res://scripts/math/math_progress.gd")
var checks := 0
var failures := 0

func _initialize() -> void: _run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _settle() -> void:
	for frame in range(3): await process_frame

func _click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await _settle()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		Input.parse_input_event(event)
		await _settle()

func _run() -> void:
	if OS.get_environment("APRENDE_VALIDATION") != "1":
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	var saved := Progress.totals().duplicate(true)
	_check(Tables.table("unknown", 1).is_empty() and Tables.table("addition", 0).is_empty() and Tables.table("division", 16).is_empty(), "Invalid table index accepted")
	for operation in Tables.OPERATIONS:
		var screen: Control = load("res://scenes/math_activity.tscn").instantiate()
		screen.topic_id = operation
		root.add_child(screen)
		screen.audio.set_sound(true, 50)
		await _settle()
		_check(screen.view == "tables", "Operation did not open its tables")
		var lesson: Control = screen.tables
		_check(lesson.table_buttons.size() == 15 and lesson.row_buttons.size() == 15, "Table selectors or equation controls missing")
		if operation == "addition":
			await _click(lesson.table_buttons[14])
			_check(lesson.number == 15, "Actual selector click did not choose table 15")
			await _click(lesson.row_buttons[14])
			_check(lesson.selected_index == 14 and screen.audio.current_id == "addition_15_15", "Actual equation click did not read the selected equation")
			await _click(lesson.play_button)
			_check(lesson.mode == "playing" and lesson.selected_index == 0, "Actual Play click did not start the table")
			await _click(lesson.play_button)
			_check(lesson.mode == "paused", "Actual Pause click did not pause")
			await _click(lesson.play_button)
			var deadline := Time.get_ticks_msec() + 10000
			while lesson.selected_index == 0 and Time.get_ticks_msec() < deadline:
				await process_frame
			_check(lesson.selected_index == 1 and screen.audio.current_id == "addition_15_02", "Natural audio completion did not advance to the next highlighted equation")
		for number in range(1, 16):
			lesson.select_table(number)
			var rows := Tables.table(operation, number)
			_check(rows.size() == 15, "Table does not contain 15 equations")
			_check(lesson.previous_button.disabled == (number == 1) and lesson.next_button.disabled == (number == 15), "Table navigation escaped the 1–15 boundaries")
			for index in range(15):
				var row: Dictionary = rows[index]
				var correct := 0
				match operation:
					"addition": correct = row.a + row.b
					"subtraction": correct = row.a - row.b
					"multiplication": correct = row.a * row.b
					"division":
						_check(row.b > 0 and row.a % row.b == 0, "Table contains a zero divisor or remainder")
						correct = row.a / row.b
				_check(correct == row.result and row.result >= 0, "Incorrect equation in " + row.id)
				_check(lesson.row_buttons[index].text.strip_edges() == Tables.expression(operation, row), "Displayed equation differs from source")
				var stream := load("res://assets/audio/llama/tables/" + row.id + ".mp3") as AudioStreamMP3
				_check(stream != null and stream.get_length() > 0.5, "Whole-equation narration missing: " + row.id)
		lesson.select_table(1)
		lesson.toggle_playback()
		_check(lesson.mode == "playing" and screen.audio.current_id == lesson.rows[0].id, "Playback did not start at the first row")
		lesson.toggle_playback()
		_check(lesson.mode == "paused" and screen.audio.player.stream_paused and not screen.audio.speaking(), "Pause did not pause the narrator and llama")
		lesson._process(5)
		_check(lesson.selected_index == 0, "Paused table advanced")
		lesson.toggle_playback()
		_check(lesson.mode == "playing" and not screen.audio.player.stream_paused, "Continue did not resume the same narration")
		# Exercise the real finished signal and gap without waiting through 900 clips.
		for index in range(15):
			_check(lesson.selected_index == index, "Autoplay skipped or repeated a row")
			_check(screen.audio.current_id == lesson.rows[index].id, "Highlight and narrator became unsynchronized")
			screen.audio.player.stop()
			screen.audio.player.finished.emit()
			if index < 14:
				lesson._process(0.6)
		_check(lesson.mode == "finished" and lesson.selected_index == 14, "Last equation did not finish the table")
		lesson.toggle_playback()
		_check(lesson.selected_index == 0 and lesson.mode == "playing", "Repeat did not restart from the first equation")
		lesson.select_row(8, true)
		_check(lesson.mode == "single" and screen.audio.current_id == lesson.rows[8].id, "Tapping a row did not interrupt autoplay and read that row")
		lesson.select_table(15)
		_check(lesson.mode == "stopped" and not screen.audio.speaking() and lesson.selected_index == 0, "Changing table left the previous narration running")
		lesson.toggle_playback()
		screen._show_help()
		_check(lesson.mode == "stopped" and not screen.audio.speaking(), "Help left table narration running behind it")
		screen._close_dialog()
		lesson.toggle_playback()
		screen.audio.set_sound(false, 50)
		lesson._process(0.1)
		_check(lesson.mode == "stopped", "Muting left autoplay active")
		lesson.toggle_playback()
		_check(lesson.mode == "stopped", "Muted playback pretended to narrate")
		screen.audio.set_sound(true, 50)
		lesson.toggle_playback()
		lesson._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
		_check(lesson.mode == "stopped" and not screen.audio.speaking(), "Backgrounded app kept narrating")
		screen._show_hub()
		screen._start_lesson(operation + "_1")
		var narration: String = screen.audio.current_id
		await _settle()
		_check(screen.view == "example" and screen.audio.current_id == narration and not narration.is_empty(), "Replacing the table stopped a new mission's voice")
		screen._go_back()
		_check(screen.view == "hub", "Missions lost their original back navigation")
		screen._show_tables()
		var back_count := [0]
		screen.back_requested.connect(func(): back_count[0] += 1)
		screen._go_back()
		_check(back_count[0] == 1, "Table back button did not return to Mathematics")
		screen.queue_free()
		await _settle()
	_check(Progress.totals() == saved, "Reading tables changed mission scores or progress")
	print("OPERATION TABLES: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
