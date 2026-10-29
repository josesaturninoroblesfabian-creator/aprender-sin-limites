extends SceneTree
const Catalog = preload("res://scripts/geometry/geometry_catalog.gd")
const Rules = preload("res://scripts/geometry/geometry_rules.gd")
const Shapes = preload("res://scripts/geometry/geometry_shapes.gd")
const Progress = preload("res://scripts/geometry/geometry_progress.gd")
const Board = preload("res://scripts/geometry/geometry_board.gd")
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
func _solve(screen: Control) -> void:
	var q: Dictionary = screen.question
	if screen.world is Board:
		var board: Control = screen.world
		match q.kind:
			"plane", "pattern":
				for index in board.holes():
					for token in q.options:
						if Rules.token_matches(token, board.expected_token(index), q.get("color_matters", false)):
							board.fit(token, index)
							break
			"count":
				var count: int = 1 if q.shape == "circle" else Shapes.SIDES[q.shape]
				for index in range(count): board.mark_at(board.part_point(index))
				screen._submit(q.result)
			"find":
				for index in q.result: board._touch(board.item_rect(index).get_center())
	elif q.kind == "solid":
		screen.solid.turn(0.4)
		screen._submit(q.result)
func _run() -> void:
	if OS.get_environment("APRENDE_VALIDATION") != "1":
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	_check(Catalog.lessons().size() == 20, "Need twenty missions")
	var unique := {}
	for lesson in Catalog.lessons():
		_check(lesson.questions.size() == 5, "Need five challenges")
		for q in [lesson.model] + lesson.questions:
			_check(not unique.has(q.id), "Repeated question ID")
			unique[q.id] = true
			_check(Rules.matches(q, q.result), "Canonical result rejected")
			_check(not Rules.matches(q, null), "Null result accepted")
			if q.kind == "count": _check(int(q.result) == Shapes.SIDES[q.shape], "Wrong side/corner count")
			if q.kind == "pattern":
				var expected := []
				for hole in q.holes:
					var token: String = q.sequence[int(hole) % int(q.unit_size)]
					_check(token == q.sequence[hole], "Broken pattern")
					expected.append(token if q.color_matters else Shapes.token_shape(token))
				_check(expected == q.result, "Wrong pattern answer")
		var screen: Control = load("res://scenes/geometry_activity.tscn").instantiate()
		screen.topic_id = lesson.topic
		root.add_child(screen)
		screen.audio.set_sound(true, 70)
		screen._start_lesson(lesson.id)
		await _settle()
		_check(screen.audio.speaking() and screen.audio.current_id == lesson.model.id, "Guided example voice did not play")
		screen.audio.set_sound(false, 70)
		_check(screen.view == "model", "New mission should start with a model")
		if lesson.model.kind == "solid":
			screen._submit(screen.question.result)
			_check(not screen.solved_current, "Model skipped without rotating")
		if lesson.model.kind == "count":
			screen._submit(screen.question.result)
			_check(not screen.solved_current, "Count skipped exploration")
		_solve(screen)
		_check(screen.model_done and screen.answers.is_empty(), "Guided model should not award points")
		screen._next_round()
		await _settle()
		for round_ in range(5):
			_check(screen.view == "practice" and screen.round_index == round_, "Wrong practice position")
			screen.audio.set_sound(true, 70)
			_check(screen.audio.speak(screen.question.audio) and screen.audio.current_id == screen.question.id, "Question voice did not play")
			screen.audio.set_sound(false, 70)
			_solve(screen)
			_check(screen.solved_current, "Real activity could not be solved: " + screen.question.id)
			screen._submit(screen.question.result)
			_check(screen.answers.size() == round_ + 1, "Duplicate response awarded")
			screen._next_round()
			await _settle()
		_check(screen.view == "result" and Progress.complete(lesson.id) and Progress.stars(lesson.id) == 3, "Mission result not saved")
		screen.queue_free()
		await _settle()
	for topic in ["find_shape", "build_pattern", "count_sides", "quick_challenge"]:
		for level in [1, 2]:
			var screen: Control = load("res://scenes/geometry_activity.tscn").instantiate()
			screen.topic_id = topic
			root.add_child(screen)
			screen.audio.set_sound(false, 70)
			screen.difficulty = level
			screen._start_game()
			await _settle()
			_check(screen.questions.size() == 8, "Untimed game should have eight rounds")
			var ids := {}
			for round_ in range(8):
				_check(not ids.has(screen.question.id), "Repeated game question")
				ids[screen.question.id] = true
				if topic == "quick_challenge": screen._submit(screen.question.result)
				else: _solve(screen)
				_check(screen.solved_current, "Game cannot be solved: " + screen.question.id)
				screen._next_round()
				await _settle()
			_check(screen.view == "result" and screen.score == 80, "Game score wrong")
			_check(int(Progress.game_record(topic, level).get("score", 0)) == 80, "Game record missing")
			screen.queue_free()
			await _settle()
	var board: Control = preload("res://scripts/geometry/geometry_board.gd").new()
	root.add_child(board)
	board.size = Vector2(700, 320)
	var count: Dictionary = Catalog.lessons("sides_vertices")[0].model
	board.setup(count)
	_check(not board.mark_at(board.polygon()[0]), "Corner counted as a side")
	_check(board.mark_at(board.part_point(0)) and not board.mark_at(board.part_point(0)), "Duplicate side counted")
	var snapshot: Dictionary = board.state()
	board.setup(count)
	board.restore(snapshot)
	_check(board.marked.size() == 1, "Partial side inspection lost")
	for index in range(1, 3): board.mark_at(board.part_point(index))
	_check(board.inspected(), "Triangle sides incomplete")
	board.queue_free()
	var screen: Control = load("res://scenes/geometry_activity.tscn").instantiate()
	screen.topic_id = "shape_patterns"
	root.add_child(screen)
	screen.audio.set_sound(false, 70)
	screen._start_lesson("shape_patterns_1")
	screen._begin_practice()
	await _settle()
	screen._show_hint()
	_check(screen.question.id in screen.hinted and not screen.world.active, "Hint not recorded/paused")
	screen._close_dialog()
	_check(screen.world.active, "Hint did not resume")
	screen._note_wrong()
	_solve(screen)
	_check(not screen.answers[screen.question.id].first, "Help/error awarded first-try points")
	var saved_id: String = screen.lesson.id
	screen._go_back()
	screen._start_lesson(saved_id)
	_check(screen.round_index == 1, "Resume lost answered question")
	screen.queue_free()
	await _settle()
	screen = load("res://scenes/geometry_activity.tscn").instantiate()
	screen.topic_id = "sides_vertices"
	root.add_child(screen)
	screen._start_lesson("sides_vertices_2")
	screen._begin_practice()
	await _settle()
	screen.world.mark_at(screen.world.part_point(0))
	screen._show_model()
	screen._begin_practice()
	await _settle()
	_check(screen.world.marked.size() == 1 and not screen.world.inspected(), "Reviewing example erased partial inspected parts")
	screen._go_back()
	screen._start_lesson("sides_vertices_2")
	await _settle()
	_check(screen.world.marked.size() == 1, "Exit/resume erased partial inspected parts")
	screen.queue_free()
	await _settle()
	screen = load("res://scenes/geometry_activity.tscn").instantiate()
	screen.topic_id = "quick_challenge"
	root.add_child(screen)
	screen.duration = 90
	screen._start_game()
	await _settle()
	screen.audio.set_sound(false, 70)
	screen.set_process(false)
	var seconds: float = screen.time_left
	screen._process(1.0)
	_check(screen.time_left == seconds - 1.0, "Active flight clock did not advance")
	screen._show_hint()
	seconds = screen.time_left
	screen._process(2.0)
	_check(screen.time_left == seconds and not screen.world.active, "Hint did not stop clock and flight")
	screen._close_dialog()
	screen.audio.set_sound(true, 70)
	screen.audio.speak(screen.question.audio)
	screen._process(2.0)
	_check(screen.time_left == seconds, "Narration consumed challenge time")
	screen.audio.stop()
	screen._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(screen.dialog_kind == "pause" and not screen.world.active, "Focus loss did not pause")
	screen._close_dialog()
	screen._submit(screen.question.result)
	screen._process(2.0)
	_check(screen.time_left == seconds, "Reading answer review consumed time")
	screen._next_round()
	screen.audio.stop()
	screen._process(200.0)
	_check(screen.view == "result" and screen.answers.size() == 1, "Timed finish lost valid partial score")
	screen.queue_free()
	await _settle()
	_check(Progress.finish_lesson("flat_shapes_1", {}) == ERR_INVALID_DATA, "Empty visit awarded progress")
	_check(Progress.finish_game("find_shape", 1, {"made_up": {"answer": 1}}, 10) == ERR_INVALID_DATA, "Unknown game proof awarded points")
	var flight: Control = preload("res://scripts/geometry/geometry_flight.gd").new()
	root.add_child(flight)
	flight.size = Vector2(900, 340)
	var q: Dictionary = Catalog.games("quick_challenge", 2)[0]
	flight.setup(q, Rules.options(q))
	flight.set_touch(1, "left", true)
	flight.set_touch(2, "rise", true)
	_check(flight._held("left") and flight._held("rise"), "Two fingers not independent")
	flight.set_touch(1, "left", false)
	_check(not flight._held("left") and flight._held("rise"), "Releasing one finger cancelled another")
	flight.set_paused(true)
	_check(flight.touches.is_empty() and not flight.active, "Pause kept stale controls")
	flight.set_paused(false)
	var value: Array = []
	flight.arrived.connect(func(answer: Variant): value.append(answer))
	flight.choose(0)
	for step in range(120): flight._process(1.0 / 60)
	_check(value.size() == 1 and value[0] == flight.options[0], "Flight never reached selected cloud")
	flight.reject()
	for step in range(120): flight._process(1.0 / 60)
	_check(flight.phase == "flying" and flight.rejected.has(0), "Wrong flight did not return")
	flight.queue_free()
	var voices: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/geometry/voice_lines.json"))
	for clip in voices.clips.values():
		var stream: AudioStreamMP3 = load("res://assets/audio/llama/geometry_activities/" + clip.file)
		_check(stream != null and stream.get_length() > 0.1, "Local voice could not decode: " + clip.file)
	await _settle()
	await create_timer(0.5).timeout
	print("GEOMETRY ACTIVITIES TEST: %d checks, %d failure(s)" % [checks, failures])
	quit(0 if failures == 0 else 1)

