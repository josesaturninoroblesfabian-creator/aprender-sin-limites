extends SceneTree

## Run only through tools/validate.ps1, which isolates user:// from real saves.
const Alphabet = preload("res://scripts/language/alphabet.gd")
const LetterStrokes = preload("res://scripts/language/tracing/letter_strokes.gd")

var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	if not OS.get_environment("APRENDE_VALIDATION") == "1":
		push_error("Use tools/validate.ps1 to protect the player's saved progress.")
		quit(1)
		return
	for script_path in [
		"res://scripts/main.gd",
		"res://scripts/language/language_lesson.gd",
		"res://scripts/language/tracing/trace_exercise.gd",
		"res://scripts/language/tracing/trace_canvas.gd",
		"res://scripts/prototypes/nina_3d.gd",
		"res://scripts/prototypes/nino_modelo_3d.gd",
	]:
		var script := load(script_path) as GDScript
		_check(script != null and script.can_instantiate(), "Script cannot compile: %s" % script_path)
	if failures > 0:
		quit(1)
		return
	for letter in Alphabet.LETTERS:
		var strokes: Array = LetterStrokes.for_letter(letter)
		_check(not strokes.is_empty(), "Missing strokes for %s" % letter)
		for stroke in strokes:
			_check(stroke.size() >= 2, "Invalid stroke for %s" % letter)
			for point in stroke:
				_check(Rect2(0, 0, 1, 1).has_point(point), "Stroke outside normalized bounds: %s" % letter)
	var scene := load("res://scenes/main.tscn") as PackedScene
	_check(scene != null, "Main scene could not be loaded")
	if scene == null:
		quit(1)
		return
	var home := scene.instantiate()
	root.add_child(home)
	await process_frame
	await process_frame
	home.call("_menu_selection", "Lenguaje")
	await process_frame
	var lesson: Control = home.get("language_screen")
	_check(is_instance_valid(lesson), "Language lesson did not open")
	if is_instance_valid(lesson):
		_check(int(lesson.get("total_words")) == 270, "Unexpected word count")
		lesson.call("_show_letter", "Ñ")
		lesson.call("_step_example", -1)
		_check(int(lesson.get("selected_example")) == 9, "Example navigation does not wrap")
		lesson.call("_show_activity", "Traza la letra")
		await process_frame
		var trace: Control = lesson.get("trace_exercise")
		_check(is_instance_valid(trace), "Tracing did not open")
		if is_instance_valid(trace):
			# Exercise the actual drawing recognizer, not a direct completion callback.
			trace.call("_select_alphabet_letter", "A")
			trace.call("_start_attempt")
			var canvas: Control = trace.get("trace_canvas")
			for stroke in LetterStrokes.for_letter("A"):
				var samples: PackedVector2Array = canvas.call("_sample_path", stroke)
				canvas.call("_begin_stroke", samples[0])
				for point in samples:
					canvas.call("_extend_stroke", point)
				canvas.call("_finish_stroke", samples[samples.size() - 1])
			_check(int(trace.get("completed_by_letter").get("A", 0)) >= 1, "Valid tracing was not saved")
			trace.call("_leave_screen")
			await process_frame
			await process_frame
			_check(is_instance_valid(lesson), "Leaving tracing unexpectedly closed Lenguaje")
			if is_instance_valid(lesson):
				_check(lesson.get("trace_exercise") == null, "Tracing was not released")
				_check(lesson.get("selected_letter") == "Ñ", "Returning from tracing lost the selected letter")
		if is_instance_valid(lesson):
			lesson.call("_go_back")
			await process_frame
			await process_frame
	_check(home.get("language_screen") == null, "Return to home failed")
	home.call("_menu_selection", "Matemática")
	await process_frame
	home.call("_show_home")
	# Reopen tracing to verify the persisted progress can be read again.
	home.call("_menu_selection", "Lenguaje")
	await process_frame
	lesson = home.get("language_screen")
	lesson.call("_show_activity", "Traza la letra")
	await process_frame
	var reopened: Control = lesson.get("trace_exercise")
	_check(int(reopened.get("completed_by_letter").get("A", 0)) >= 1, "Saved tracing did not survive reopening")
	reopened.call("_leave_screen")
	await process_frame
	home.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("SMOKE TEST: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
