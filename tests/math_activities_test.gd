extends SceneTree

const Catalog = preload("res://scripts/math/activity_catalog.gd")
const Rules = preload("res://scripts/math/math_rules.gd")
const Progress = preload("res://scripts/math/math_progress.gd")
const UI = preload("res://scripts/math/math_ui.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _screen(topic: String) -> Control:
	var screen := (load("res://scenes/math_activity.tscn") as PackedScene).instantiate()
	screen.set("topic_id", topic)
	root.add_child(screen)
	screen.get("audio").call("set_sound", true, 70.0)
	return screen

func _finish_example(screen: Control) -> void:
	var target := Rules.action_target(screen.get("question"))
	for index in range(target): screen.call("_advance_model")
	screen.call("_begin_practice")

func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func _fits(screen: Control) -> bool:
	var nav: Control = screen.get("navigation")
	return nav.get_global_rect().end.y <= 801

func _run() -> void:
	if OS.get_environment("APRENDE_VALIDATION") != "1":
		push_error("Use tools/validate.ps1 to isolate saved progress.")
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	var seed := ConfigFile.new()
	seed.set_value("custom", "keep", "team-save")
	seed.set_value("progreso", "actividades", {"legacy_unknown": true})
	seed.save(Progress.PATH)
	_check(Progress.totals().lessons == 0, "Unknown legacy records became mathematics credit")
	_check(Rules.answer("division", 8, 0) == -1 and Rules.answer("division", 7, 2) == -1, "Division accepted zero or a remainder in the exact-division curriculum")
	_check(Rules.answer("subtraction", 2, 5) == -1 and Rules.answer("subtraction", 5, 5) == 0, "Subtraction lost the zero boundary")
	_check(Progress.complete_lesson("addition_1", {}) != OK and not Progress.is_complete("addition_1"), "Empty lesson was awarded")
	_check(Progress.complete_lesson("unknown", {}) != OK, "Unknown lesson was saved")
	var selected_positions: Dictionary = {}
	for lesson in Catalog.all_lessons():
		for question in lesson.questions:
			var options := Rules.options(question)
			_check(options.size() == 4 and question.result in options, "Correct answer missing from the game options")
			var distinct: Dictionary = {}
			for value in options: distinct[value] = true
			_check(distinct.size() == 4 and options.min() >= 0, "Ambiguous or negative answer options")
			selected_positions[options.find(question.result)] = true
	_check(selected_positions.size() >= 3, "Answer placement reveals a fixed pattern")
	for operation in Catalog.OPERATIONS:
		_check(Catalog.pool([operation], 1).size() >= 10, "One selected operation cannot supply ten distinct practice questions")
	var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/math/activities_voice_lines.json"))
	for entry in provenance.clips.values():
		var sound := load("res://assets/audio/llama/activities/" + entry.file) as AudioStreamMP3
		_check(sound != null and sound.get_length() > 0.3, "A packaged mathematics voice clip failed to decode")
	var hero_hashes: Dictionary = {}
	for frame_index in range(8):
		var frame: AtlasTexture = UI.runner(frame_index)
		var image := frame.atlas.get_image().get_region(Rect2i(frame.region))
		hero_hashes[hash(image.get_data())] = true
		_check(image.get_pixel(0, 0).a < 0.02, "Llama running frames lost transparency")
	_check(hero_hashes.size() == 8, "The running llama has repeated poses")
	var lesson_index := 0
	for lesson in Catalog.all_lessons():
		var screen := _screen(lesson.topic)
		screen.call("_start_lesson", lesson.id)
		await _settle()
		_check(_fits(screen), "Guided mission controls overflowed the screen")
		_check(not Progress.is_complete(lesson.id), "Opening a mathematics mission granted completion")
		screen.call("_begin_practice")
		_check(screen.get("view") == "example", "A guided model could be skipped before any interaction")
		_finish_example(screen)
		_check(screen.get("view") == "practice", "Completing the model did not start six real questions")
		for index in range(6):
			await _settle()
			_check(_fits(screen), "Question keypad or navigation overflowed the screen")
			var question: Dictionary = screen.get("question")
			var before: int = screen.get("round_index")
			screen.call("_next_question")
			_check(screen.get("round_index") == before, "An unanswered lesson question was skipped")
			if lesson_index == 0 and index == 0:
				screen.call("_submit_number", int(question.result) + 1)
				_check(not screen.get("solved_current") and screen.get("answers").is_empty(), "Wrong lesson answer awarded completion")
				screen.call("_go_back")
				screen.call("_start_lesson", lesson.id)
				_check(screen.get("mistakes").has(question.id), "Leaving the lesson erased an earlier wrong attempt")
			if lesson_index == 0 and index == 1:
				screen.call("_show_hint")
				_check(screen.get("dialog_kind") == "hint", "The worked hint did not open")
				screen.call("_close_dialog")
			var first_result := false
			if lesson_index == 0 and index == 2:
				(screen.find_child("Key_3", true, false) as Button).pressed.emit()
				_check(screen.get("draft") == "3", "The on-screen numeric keypad did not enter a digit")
				(screen.get("submit_button") as Button).pressed.emit()
				first_result = screen.get("solved_current")
			elif lesson_index == 0 and index == 5:
				var digit := InputEventKey.new()
				digit.keycode = KEY_KP_4
				digit.pressed = true
				screen.call("_unhandled_key_input", digit)
				_check(screen.get("draft") == "4", "The physical number pad did not enter a digit")
				var enter := InputEventKey.new()
				enter.keycode = KEY_KP_ENTER
				enter.pressed = true
				screen.call("_unhandled_key_input", enter)
				first_result = screen.get("solved_current")
			else:
				first_result = screen.call("_submit_number", int(question.result))
			_check(first_result, "A correct lesson answer was rejected")
			var count: int = screen.get("answers").size()
			screen.call("_submit_number", int(question.result))
			_check(screen.get("answers").size() == count, "Repeated answer presses changed the lesson score")
			if lesson_index == 1 and index == 2:
				screen.call("_go_back")
				screen.call("_start_lesson", lesson.id)
				_check(screen.get("round_index") == 3 and screen.get("answers").size() == 3, "Three completed questions did not resume at the fourth")
				continue
			if lesson_index == 1 and index == 5:
				screen.call("_go_back")
				screen.call("_start_lesson", lesson.id)
				_check(screen.get("view") == "result", "Six answered questions were lost by leaving before the result screen")
			else: screen.call("_next_question")
		_check(Progress.is_complete(lesson.id), "Six solved questions did not save a mission")
		_check(Progress.lesson_stars(lesson.id) == (2 if lesson_index == 0 else 3), "Hints or incorrect attempts were counted as first-try answers")
		screen.queue_free()
		await process_frame
		lesson_index += 1
	_check(Progress.totals().lessons == 16 and Progress.totals().stars == 47, "Lesson totals included visits or repeated scores")
	var replay := _screen("addition")
	replay.call("_start_lesson", "addition_1")
	_finish_example(replay)
	for index in range(6):
		replay.call("_submit_number", int(replay.get("question").result))
		replay.call("_next_question")
	_check(Progress.totals().lessons == 16 and Progress.totals().stars == 48, "A better replay did not replace the previous record")
	replay.queue_free()
	await process_frame
	var counter := _screen("count_objects")
	counter.call("_start_game")
	for round_index in range(8):
		await _settle()
		var board: Control = counter.get("model")
		var total: int = counter.get("question").result
		for item in range(total):
			var tap := InputEventScreenTouch.new()
			tap.index = 0
			tap.pressed = true
			tap.position = board.get("rects")[item].get_center() / Vector2(800, 420) * board.size
			board.call("_gui_input", tap)
			board.call("_gui_input", tap)
		_check(board.get("selected").size() == total, "Touch counting counted a repeated object twice")
		(counter.get("count_buttons").filter(func(button: Button): return button.text == "Hay %d" % total)[0] as Button).pressed.emit()
		(counter.get("next_button") as Button).pressed.emit()
	_check(counter.get("view") == "game_result" and Progress.game_record("count_objects").score == 80, "Eight counting rounds did not finish")
	counter.queue_free()
	await process_frame
	var exercise := _screen("solve_exercises")
	(exercise.find_child("Use_addition", true, false) as Button).button_pressed = false
	(exercise.find_child("Use_subtraction", true, false) as Button).button_pressed = false
	exercise.call("_start_game")
	_check(exercise.get("view") == "setup", "An empty operation selection started a practice session")
	(exercise.find_child("Use_division", true, false) as Button).button_pressed = true
	_check(exercise.get("operations") == ["division"], "The visible operation switches selected a different operation")
	exercise.set("difficulty", 1)
	exercise.call("_start_game")
	var used: Dictionary = {}
	for index in range(10):
		var question: Dictionary = exercise.get("question")
		used[question.id] = true
		if index == 0:
			exercise.call("_show_hint")
			exercise.call("_close_dialog")
		exercise.call("_submit_number", int(question.result))
		exercise.call("_next_question")
	_check(used.size() == 10 and exercise.get("view") == "game_result", "Practice repeated questions instead of presenting ten distinct problems")
	_check(Progress.game_record("solve_exercises").score == 95, "A hinted practice answer received first-try points")
	exercise.queue_free()
	await process_frame
	var quick := _screen("quick_challenge")
	(quick.find_child("Clock_0", true, false) as Button).pressed.emit()
	_check(quick.get("duration") == 0.0, "The untimed button did not select the visible clock mode")
	quick.set("operations", Catalog.OPERATIONS.duplicate())
	quick.call("_start_game")
	quick.call("_process", 100.0)
	_check(quick.get("view") == "quick", "The untimed balloon game expired")
	for index in range(10):
		await _settle()
		var balloons: Control = quick.get("balloons")
		var value: int = quick.get("question").result
		var option_index: int = balloons.get("values").find(value)
		var point: Vector2 = balloons.call("balloon_rect", option_index).get_center()
		var tap := InputEventMouseButton.new()
		tap.button_index = MOUSE_BUTTON_LEFT
		tap.pressed = true
		tap.position = point / Vector2(800, 380) * balloons.size
		balloons.call("_gui_input", tap)
		_check(quick.get("solved_current"), "A balloon's visible hit area did not accept its answer")
		quick.call("_process", 0.7)
	_check(quick.get("view") == "game_result" and Progress.game_record("quick_challenge").score == 100, "The untimed ten-answer game did not finish")
	quick.set("duration", 60.0)
	quick.call("_start_game")
	quick.call("_process", 0.5)
	var remaining: float = quick.get("time_left")
	quick.call("_show_pause")
	quick.call("_process", 100.0)
	_check(quick.get("time_left") == remaining, "A paused game consumed its timer")
	quick.call("_show_pause")
	quick.call("_show_hint")
	quick.call("_process", 100.0)
	_check(quick.get("time_left") == remaining, "Reading a worked hint consumed its timer")
	quick.call("_close_dialog")
	quick.call("_submit_number", int(quick.get("question").result))
	quick.set("time_left", 0.01)
	quick.call("_process", 0.02)
	_check(quick.get("view") == "game_result" and Progress.game_record("quick_challenge").score == 100, "Timed replay farmed points instead of keeping the best score")
	quick.queue_free()
	await process_frame
	var route := _screen("level_game")
	route.call("_start_level", 1)
	_check(route.get("view") == "map" and route.get("arcade") == null, "A locked path opened before its predecessor")
	for path in range(12):
		route.call("_start_level", path)
		await _settle()
		var course: Control = route.get("arcade")
		_check(not Progress.level_record(path).get("complete", false), "Opening an adventure path granted completion")
		if path == 0:
			var right := InputEventKey.new()
			right.physical_keycode = KEY_D
			right.pressed = true
			course.call("_input", right)
			for tick in range(70): course.call("_process", 0.04)
			_check(course.get("position_world").x <= course.get("obstacles")[0] - 46, "The llama walked through a solid crate without jumping")
			course.call("clear_input")
			course.call("restore", {}, [])
			for pair in [[7, "right"], [8, "jump"]]:
				var touch := InputEventScreenTouch.new()
				touch.index = pair[0]
				touch.pressed = true
				var center: Vector2 = course.call("_control_rect", pair[1]).get_center()
				touch.position = course.get_global_transform_with_canvas() * (center / Vector2(1280, 560) * course.size)
				course.call("_input", touch)
			course.call("_process", 0.04)
			_check(course.get("fingers").size() == 2 and course.get("velocity").y < 0 and course.get("velocity").x > 0, "Two-finger movement and jumping did not work together")
			course.call("set_paused", true)
			var paused_at: Vector2 = course.get("position_world")
			course.call("_process", 1.0)
			_check(course.get("position_world") == paused_at and course.get("fingers").is_empty(), "Pause left movement or touch controls active")
			course.call("set_paused", false)
			course.call("restore", {}, [])
		var resumed := false
		var wrong_resumed := false
		for tick in range(1800):
			if route.get("view") != "adventure": break
			course = route.get("arcade")
			if int(course.get("awaiting_gate")) >= 0:
				var gate: int = course.get("awaiting_gate")
				_check(route.get("dialog_kind") == "gate", "A mathematical gate had no visible question")
				var question: Dictionary = route.get("question")
				if path == 0 and gate == 0 and not wrong_resumed:
					route.call("_answer_gate", int(question.result) + 1)
					_check(not course.get("opened").has(0), "A wrong gate answer opened the path")
					route.call("_go_back")
					route.call("_go_back")
					_check(route.get("dialog_kind") == "gate" and not route.get("gate_wrong").is_empty(), "Escape from pause lost the blocked gate or its earlier wrong attempt")
					route.call("_show_map")
					route.call("_start_level", 0)
					course = route.get("arcade")
					wrong_resumed = true
					continue
				if path == 0 and gate == 0:
					_check(not route.get("gate_wrong").is_empty(), "Resuming an unsolved gate erased its earlier wrong answer")
				route.call("_answer_gate", int(question.result))
				_check(course.get("opened").has(gate), "Correct gate answer did not open the door")
				if path == 0 and gate == 1 and not resumed:
					route.call("_show_map")
					route.call("_start_level", 0)
					course = route.get("arcade")
					_check(course.get("opened").size() == 2 and course.get("position_world").x > 1650, "The adventure did not resume at the last solved gate")
					resumed = true
				continue
			course.get("keys")[KEY_D] = true
			if course.get("on_floor"):
				for obstacle in course.get("obstacles"):
					if obstacle - course.get("position_world").x > 0 and obstacle - course.get("position_world").x < 115: course.set("jump_queued", true)
				for star in course.get("star_points"):
					if star.x - course.get("position_world").x > 0 and star.x - course.get("position_world").x < 125: course.set("jump_queued", true)
			course.call("_process", 0.04)
		_check(route.get("view") == "route_result" and Progress.level_record(path).get("complete", false), "An adventure path could not be completed with real movement, jumps and gate answers: %d" % path)
		_check(Progress.totals().paths == path + 1, "Adventure completion unlocked or counted the wrong path")
		await process_frame
	_check(Progress.totals().paths == 12, "The full twelve-path adventure did not finish")
	route.queue_free()
	await process_frame
	var saved := ConfigFile.new()
	saved.load(Progress.PATH)
	_check(saved.get_value("custom", "keep") == "team-save" and saved.get_value("progreso", "actividades").get("legacy_unknown", false), "New mathematics progress overwrote the team's older save data")
	await create_timer(0.15).timeout
	print("MATHEMATICS ACTIVITIES TEST: %d checks, %d failure(s)" % [checks, failures])
	quit(0 if failures == 0 else 1)
