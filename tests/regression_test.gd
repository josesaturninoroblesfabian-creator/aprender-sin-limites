extends SceneTree

const Alphabet = preload("res://scripts/language/alphabet.gd")
const LetterStrokes = preload("res://scripts/language/tracing/letter_strokes.gd")
const Canvas = preload("res://scripts/language/tracing/trace_canvas.gd")
const ProgressStore = preload("res://scripts/storage/progress_store.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _draw_letter(canvas: Control, letter: String, sparse: bool = false) -> void:
	canvas.call("set_guide_strokes", LetterStrokes.for_letter(letter))
	canvas.call("start_drawing")
	for path in LetterStrokes.for_letter(letter):
		var samples: PackedVector2Array = canvas.call("_sample_path", path)
		canvas.call("_begin_stroke", samples[0])
		if sparse:
			# A slow device can omit motion events along a straight segment.
			for point in path:
				canvas.call("_extend_stroke", point * canvas.size)
		else:
			for point in samples:
				canvas.call("_extend_stroke", point)
		canvas.call("_finish_stroke", samples[samples.size() - 1])

func _run() -> void:
	if OS.get_environment("APRENDE_VALIDATION") != "1":
		push_error("Run tools/validate.ps1 to isolate saved data.")
		quit(1)
		return
	var narration: Node = root.get_node("Narration")
	create_timer(30.0).timeout.connect(func():
		push_error("Regression test exceeded 30 seconds")
		quit(1)
	)
	var canvas := Canvas.new()
	root.add_child(canvas)
	for dimensions in [Vector2(370, 356), Vector2(280, 300)]:
		canvas.size = dimensions
		for letter in Alphabet.LETTERS:
			_draw_letter(canvas, letter)
			_check(not canvas.drawing_enabled, "Valid complete %s rejected at %s" % [letter, dimensions])
			_draw_letter(canvas, letter, true)
			_check(not canvas.drawing_enabled, "Sparse valid %s rejected at %s" % [letter, dimensions])
	canvas.size = Vector2(370, 356)
	for letter in ["A", "O", "L", "V"]:
		canvas.set_guide_strokes(LetterStrokes.for_letter(letter))
		canvas.start_drawing()
		var path: PackedVector2Array = LetterStrokes.for_letter(letter)[0]
		var samples: PackedVector2Array = canvas.call("_sample_path", path)
		canvas.call("_begin_stroke", samples[0])
		canvas.call("_finish_stroke", samples[samples.size() - 1])
		_check(canvas.current_stroke_index == 0, "Shortcut accepted for %s" % letter)
	# A partial stroke can be resumed without forcing a child to restart.
	canvas.set_guide_strokes(LetterStrokes.for_letter("I"))
	canvas.start_drawing()
	var first_path: PackedVector2Array = LetterStrokes.for_letter("I")[0]
	var resume_samples: PackedVector2Array = canvas.call("_sample_path", first_path)
	canvas.call("_begin_stroke", resume_samples[0])
	for index in range(21):
		canvas.call("_extend_stroke", resume_samples[index])
	canvas.call("_finish_stroke", resume_samples[20])
	_check(canvas.current_stroke_index == 0, "Partial stroke incorrectly completed")
	canvas.call("_begin_stroke", resume_samples[20])
	for index in range(21, resume_samples.size()):
		canvas.call("_extend_stroke", resume_samples[index])
	canvas.call("_finish_stroke", resume_samples[resume_samples.size() - 1])
	_check(canvas.current_stroke_index == 1, "Resuming a valid stroke failed")
	canvas.set_guide_strokes(LetterStrokes.for_letter("A"))
	canvas.start_drawing()
	var touch := InputEventScreenTouch.new()
	touch.index = 1
	touch.pressed = true
	touch.position = Vector2(0.15, 0.88) * canvas.size
	canvas.call("_gui_input", touch)
	var other_touch := InputEventScreenTouch.new()
	other_touch.index = 2
	other_touch.pressed = true
	other_touch.position = Vector2.ZERO
	canvas.call("_gui_input", other_touch)
	_check(canvas.active_touch_index == 1, "A second finger took over the active stroke")
	other_touch.pressed = false
	canvas.call("_gui_input", other_touch)
	_check(canvas.is_drawing, "Releasing a second finger ended the active stroke")
	touch.pressed = false
	canvas.call("_gui_input", touch)
	_check(not canvas.is_drawing and canvas.active_touch_index == -1, "Active finger release did not stop drawing")
	touch.pressed = true
	canvas.call("_gui_input", touch)
	var outside_drag := InputEventScreenDrag.new()
	outside_drag.index = 1
	outside_drag.position = Vector2(-300, -300)
	canvas.call("_input", outside_drag)
	touch.pressed = false
	touch.position = Vector2(-300, -300)
	canvas.call("_input", touch)
	_check(canvas.active_touch_index == -1, "Rejected drag outside the panel locked future touches")
	canvas.reset_drawing()
	canvas.queue_free()
	await process_frame
	# Legacy visits must remain on disk and must not become listening credit.
	var legacy := ConfigFile.new()
	legacy.set_value("progreso", "ejemplos", {"A": [true, true, true, true, true, true, true, true, true, true]})
	legacy.set_value("custom", "keep", "original")
	legacy.save("user://progreso_lenguaje.cfg")
	var lesson := Control.new()
	lesson.set_script(load("res://scripts/language/language_lesson.gd"))
	root.add_child(lesson)
	lesson.call("_stop_condor_intro")
	_check(lesson.get("completed_examples")["A"].count(true) == 0, "Visits became listening credit")
	_check(lesson.get("letter_label").text == "A de Árbol", "Accented initial letter not normalized")
	_check(lesson.call("_word_caption", "Ñ", "Niño") == "Ñ en Niño", "Ñ must remain distinct from N")
	lesson.call("_select_and_speak_letter", "Ñ")
	_check(narration.get("current_clip") == "letter_14", "Touching Ñ did not start its letter audio")
	_check(lesson.get("selected_letter") == "Ñ", "Touching a letter did not select it")
	_check(lesson.get("completed_examples")["Ñ"].count(true) == 0, "Letter audio granted word listening credit")
	lesson.call("_show_letter", "A")
	var big_letter_button := lesson.find_child("ListenBigLetter", true, false) as Button
	big_letter_button.pressed.emit()
	_check(narration.get("current_clip") == "letter_00", "Touching the large letter did not pronounce A")
	lesson.call("_speak_current_word")
	_check(not String(narration.get("current_clip")).is_empty(), "Local word audio did not start")
	if not String(narration.get("current_clip")).is_empty():
		await Signal(narration, "finished")
	_check(lesson.get("completed_examples")["A"][0], "Full local playback did not grant listening credit")
	lesson.call("_step_example", 1)
	lesson.call("_speak_current_word")
	lesson.call("_step_example", 1)
	_check(not lesson.get("completed_examples")["A"][1], "Interrupted playback granted credit")
	_check(String(narration.get("current_clip")).is_empty(), "Navigation did not cancel narration")
	lesson.call("_speak_current_word")
	if not String(narration.get("current_clip")).is_empty():
		await Signal(narration, "finished")
	var saved := ProgressStore.read("user://progreso_lenguaje.cfg")
	_check(saved.get_value("custom", "keep") == "original", "Migration lost unknown save fields")
	_check(saved.get_value("progreso", "ejemplos")["A"].count(true) == 10, "Migration changed legacy visits")
	_check(FileAccess.file_exists("user://progreso_lenguaje.cfg.bak"), "No previous save backup")
	var recovery := ConfigFile.new()
	recovery.set_value("test", "value", 1)
	ProgressStore.write(recovery, "user://recovery.cfg")
	recovery.set_value("test", "value", 2)
	ProgressStore.write(recovery, "user://recovery.cfg")
	DirAccess.rename_absolute("user://recovery.cfg", "user://recovery.cfg.missing")
	_check(ProgressStore.read("user://recovery.cfg").get_value("test", "value", 0) == 1, "Missing primary save did not recover its backup")
	lesson.call("_show_activity", "Traza la letra")
	var trace: Control = lesson.get("trace_exercise")
	trace.get("completed_by_letter")["Z"] = 10
	trace.call("_select_alphabet_letter", "Z")
	_check(trace.get("result_label").text != "¡Completaste las 27 letras!", "Z alone was treated as all letters")
	_check(trace.get("counter_label").text == "1", "Progress plaque must count completed letters")
	trace.get("completed_by_letter")["A"] = 10
	trace.call("_select_alphabet_letter", "A")
	_check(not trace.get("next_button").disabled, "Next letter remains locked after completion")
	trace.call("_go_to_next_letter")
	_check(trace.get("current_letter_index") == 1, "Next letter button did not advance")
	(trace.get("start_button") as Button).pressed.emit()
	_check(narration.get("current_clip") == "trace_start", "Pencil button did not start its instruction")
	var trace_area: Control = trace.get("trace_canvas")
	var b_samples: PackedVector2Array = trace_area.get("sampled_strokes")[0]
	trace_area.call("_begin_stroke", b_samples[0])
	for point in b_samples:
		trace_area.call("_extend_stroke", point)
	trace_area.call("_finish_stroke", b_samples[b_samples.size() - 1])
	_check(trace_area.get("completed_lines").size() == 1, "Could not draw a stroke before erasing")
	var progress_before_erase: Dictionary = trace.get("completed_by_letter").duplicate()
	(trace.get("erase_button") as Button).pressed.emit()
	_check(trace_area.get("completed_lines").is_empty() and trace_area.get("current_line").is_empty(), "Eraser left drawn ink on the canvas")
	_check(trace_area.get("current_stroke_index") == 0 and trace_area.get("drawing_enabled"), "Eraser did not return to the first stroke ready to draw")
	_check(trace.get("completed_by_letter") == progress_before_erase, "Erasing changed saved progress")
	_check(narration.get("current_clip") == "trace_retry", "Eraser did not play its instruction")
	trace.call("_leave_screen")
	await process_frame
	lesson.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("REGRESSION TEST: %d checks, %d failure(s)" % [checks, failures])
	quit(0 if failures == 0 else 1)
