extends SceneTree

const Catalog = preload("res://scripts/numbers/number_catalog.gd")
const Rules = preload("res://scripts/numbers/number_rules.gd")
const Progress = preload("res://scripts/numbers/number_progress.gd")
const Board = preload("res://scripts/numbers/place_board.gd")
const Art = preload("res://scripts/numbers/number_art.gd")
const Store = preload("res://scripts/storage/progress_store.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _screen(topic: String) -> Control:
	var screen: Control = load("res://scenes/number_activity.tscn").instantiate()
	screen.topic_id = topic
	root.add_child(screen)
	screen.audio.set_sound(true, 70.0)
	return screen

func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func _fill_board(screen: Control, number: int) -> void:
	var digits := Rules.digits(number, int(screen.width))
	for place in range(int(screen.width) - 1, -1, -1):
		var touch := InputEventScreenTouch.new()
		touch.pressed = true
		touch.position = screen.board.column_rect(place).get_center()
		screen.board._gui_input(touch)
		(screen.find_child("Digit_" + str(digits[place]), true, false) as Button).pressed.emit()

func _finish_model(screen: Control) -> void:
	await _settle()
	if int(screen.lesson.exchange_place) < 0: _fill_board(screen, int(screen.lesson.model_number))
	screen.model_button.pressed.emit()
	screen.next_button.pressed.emit()

func _correct_practice(screen: Control) -> void:
	await _settle()
	match screen.question.kind:
		"build":
			_fill_board(screen, int(screen.question.result))
			screen.submit_button.pressed.emit()
		"order":
			for value in screen.question.result:
				for choice in screen.choices:
					if choice.get_meta("answer") == value: choice.pressed.emit()
			screen.submit_button.pressed.emit()
		_:
			for choice in screen.choices:
				if choice.get_meta("answer") == screen.question.result: choice.pressed.emit()

func _run() -> void:
	if OS.get_environment("APRENDE_VALIDATION") != "1":
		push_error("Run tools/validate.ps1 to isolate player data.")
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	var seed := ConfigFile.new()
	seed.set_value("custom", "keep", "teammate-numbers-progress")
	seed.set_value("progreso", "actividades", {"legacy_unknown": true, "one_digit_99": true})
	seed.save(Progress.PATH)
	_check(Progress.finish_lesson("one_digit_1", {}) != OK and not Progress.complete("one_digit_1"), "An empty Numbers mission earned completion")
	_check(Progress.finish_lesson("unknown", {}) != OK, "Unknown Numbers mission accepted")
	_check(not Rules.canonical([10, 0], 2) and not Rules.canonical([-1], 1) and Rules.canonical([0, 0, 0, 1], 4), "Place-value digit validity failed")
	var positions: Dictionary = {}
	for lesson in Catalog.lessons():
		for question in lesson.questions:
			if question.kind == "order": continue
			var options := Rules.options(question)
			var distinct := {}
			for value in options: distinct[value] = true
			_check(options.size() == 4 and distinct.size() == 4 and question.result in options and options.min() >= 0, "A Numbers question has ambiguous choices")
			positions[options.find(question.result)] = true
	_check(positions.size() == 4, "Numbers answers always appear in the same position")
	for width in range(1, 5):
		_check(Catalog.games("train", width).size() >= 8, "The number train cannot supply eight distinct stations")
		for question in Catalog.games("sequences", width):
			question = question.duplicate(true)
			question.kind = "sequence"
			question.number = int(question.result)
			_check(question.result in Rules.options(question), "Sequence's answer is missing from the stones")
	var voices: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/numbers/voice_lines.json"))
	for entry in voices.clips.values():
		var clip := load("res://assets/audio/llama/numbers_activities/" + entry.file) as AudioStreamMP3
		_check(clip != null and clip.get_length() > 0.3, "Numbers MP3 failed to decode: " + entry.file)
	for index in range(8):
		var cell: AtlasTexture = Art.object(index)
		var image := cell.atlas.get_image().get_region(Rect2i(cell.region))
		_check(image.get_pixel(0, 0).a < 0.02 and image.get_pixel(image.get_width() - 1, 0).a < 0.02, "A Numbers prop lost its transparent padding")
	for width in range(2, 5):
		var board := Board.new()
		root.add_child(board)
		board.setup(0, width)
		for place in range(width - 1):
			var counts := Rules.digits(0, width)
			counts[place] = 10
			board.set_counts(counts)
			var before := Rules.value(board.counts)
			_check(board.exchange(place) and Rules.value(board.counts) == before and board.counts[place] == 0 and board.counts[place + 1] == 1, "An exchange changed the value of the number")
		_check(not board.exchange(width - 1), "Exchanging beyond the highest column was allowed")
		board.queue_free()
		await process_frame
	var expected_stars := 0
	var lesson_index := 0
	for lesson in Catalog.lessons():
		var screen := _screen(lesson.topic)
		screen._start_lesson(lesson.id)
		await _settle()
		_check(screen.view == "model" and not Progress.complete(lesson.id), "Opening a Numbers mission earned a result")
		screen._begin_practice()
		_check(screen.view == "model", "The model was skipped without interaction")
		var quantity_before: int = Rules.value(screen.board.counts)
		await _finish_model(screen)
		_check(screen.view == "practice", "The interactive model did not open five practice questions")
		if int(lesson.exchange_place) >= 0: _check(quantity_before == int(lesson.model_number), "The exchange example started with the wrong total")
		for index in range(5):
			await _settle()
			_check(screen.navigation.get_global_rect().end.y <= 801, "A Numbers question escaped the viewport")
			var q: Dictionary = screen.question
			screen._next_round()
			_check(screen.round_index == index and not screen.solved_current, "An unanswered Numbers question was skipped")
			if lesson_index == 0 and index == 0:
				screen._submit(1)
				_check(screen.answers.is_empty() and not screen.solved_current, "Incorrect number awarded a result")
				screen._go_back()
				screen._start_lesson(lesson.id)
				_check(screen.wrong.has(q.id), "Wrong attempt disappeared after reopening")
			if lesson_index == 0 and index == 1:
				screen._show_hint()
				_check(screen.dialog_kind == "hint", "Numbers hint did not open")
				screen._close_dialog()
			if lesson.id == "four_digits_2" and index == 0:
				screen.board.active_place = 3
				screen.board.set_digit(1)
				screen._go_back()
				screen._start_lesson(lesson.id)
				_check(screen.board.counts[3] == 1 and Rules.value(screen.board.counts) == 1000, "A partial place-value construction was lost")
			if lesson.id == "one_digit_2" and index == 0:
				var data := {"type": "number_digit", "digit": 3}
				var point: Vector2 = screen.board.column_rect(0).get_center()
				_check(screen.board._can_drop_data(point, data) and not screen.board._can_drop_data(point, {"type": "number_digit", "digit": 30}), "Digit drag accepted an invalid payload")
				screen.board._drop_data(point, data)
				_check(screen.board.counts[0] == 3, "Dropping a digit did not change its column")
			if lesson.id == "one_digit_2" and index == 1:
				var key := InputEventKey.new()
				key.keycode = KEY_KP_1
				key.pressed = true
				screen._unhandled_key_input(key)
				_check(screen.board.counts[0] == 1, "The physical numeric keypad did not place a digit")
			if lesson.id == "one_digit_5" and index == 0:
				for value in q.values:
					for choice in screen.choices:
						if choice.get_meta("answer") == value: choice.pressed.emit()
				screen.submit_button.pressed.emit()
				_check(not screen.solved_current, "An incorrectly ordered sequence was accepted")
				while not screen.ordered.is_empty():
					var value: int = screen.ordered.pop_back()
					for choice in screen.choices:
						if choice.get_meta("answer") == value: choice.disabled = false
			await _correct_practice(screen)
			_check(screen.solved_current and screen.answers.has(q.id), "A correct answer was rejected: " + q.id)
			var count: int = screen.answers.size()
			screen._submit(q.result)
			_check(screen.answers.size() == count, "Duplicate presses increased progress")
			if lesson_index == 1 and index == 2:
				screen._go_back()
				screen._start_lesson(lesson.id)
				_check(screen.round_index == 3 and screen.answers.size() == 3, "Three completed challenges did not resume at the fourth")
			elif lesson_index == 1 and index == 4:
				screen._go_back()
				screen._start_lesson(lesson.id)
				_check(screen.view == "result" and Progress.complete(lesson.id), "Five solved challenges were lost before the result screen")
			else: screen.next_button.pressed.emit()
		var stars := 2 if lesson_index in [0, 4] else 3
		expected_stars += stars
		_check(Progress.complete(lesson.id) and Progress.stars(lesson.id) == stars, "Numbers completion or first-attempt stars are wrong: " + lesson.id)
		screen.queue_free()
		await process_frame
		lesson_index += 1
	_check(expected_stars == 58, "The reviewed attempt history did not match earned stars")
	for id in ["one_digit_1", "one_digit_5"]:
		var screen := _screen("one_digit")
		screen._start_lesson(id)
		await _finish_model(screen)
		for index in range(5):
			await _correct_practice(screen)
			screen.next_button.pressed.emit()
		_check(Progress.stars(id) == 3, "A better replay did not improve the previous stars")
		screen.queue_free()
		await process_frame
	var all_stars := 0
	for lesson in Catalog.lessons(): all_stars += Progress.stars(lesson.id)
	_check(all_stars == 60 and Catalog.lessons().filter(func(lesson): return Progress.complete(lesson.id)).size() == 20, "Repeated lessons inflated the number of missions")
	await _market_test()
	await _bridge_tests()
	await _comparison_tests()
	await _train_tests()
	var saved := Store.read(Progress.PATH)
	_check(saved.get_value("custom", "keep") == "teammate-numbers-progress" and saved.get_value("progreso", "actividades").get("legacy_unknown") == true and saved.get_value("progreso", "actividades").get("one_digit_99") == true, "Numbers activities overwrote legacy or teammate save data")
	_check(FileAccess.file_exists(Progress.PATH + ".bak"), "Numbers progress did not retain a recovery copy")
	await create_timer(0.5).timeout
	print("NUMBER ACTIVITIES TEST: %d checks, %d failure(s)" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _market_test() -> void:
	var screen := _screen("count_objects")
	screen._start_game()
	for round_ in range(8):
		await _settle()
		var world: Control = screen.world
		var total: int = world.total
		if total > 0:
			screen._submit(total)
			_check(not screen.solved_current and screen.answers.size() == round_, "The market answered before counting")
		for index in range(total):
			var touch := InputEventScreenTouch.new()
			touch.pressed = true
			touch.position = world.object_rect(index).get_center()
			world._gui_input(touch)
			_check(world.marked.size() == index + 1, "Touch failed to count a market product")
			world._gui_input(touch)
			_check(world.marked.size() == index + 1, "Repeated touches counted the same product twice")
		_check(world.marked.size() == total, "A market product was unreachable")
		for button in screen.choices:
			if button.get_meta("answer") == total: button.pressed.emit()
		_check(screen.solved_current, "The counted market answer was rejected")
		screen.next_button.pressed.emit()
	_check(screen.view == "game_result" and Progress.game_record("count_objects", 2).score == 80, "Eight market rounds did not save their result")
	var old: int = Progress.game_record("count_objects", 2).score
	_check(Progress.finish_game("count_objects", 2, screen.answers, screen.score) == OK and Progress.game_record("count_objects", 2).score == old, "Repeated market saving inflated the score")
	_check(Progress.finish_game("count_objects", 2, {}, 100) != OK, "Incomplete market earned a reward")
	screen.queue_free()
	await process_frame

func _bridge_tests() -> void:
	for width in range(1, 5):
		var screen := _screen("sequences")
		screen.width = width
		screen._start_game()
		var seen := {}
		for round_ in range(8):
			await _settle()
			var q: Dictionary = screen.question
			_check(not seen.has(q.id), "A bridge repeated before all eight were played")
			seen[q.id] = true
			if round_ == 0:
				screen._show_hint()
				_check(screen.world.show_rule and not screen.world.active, "Bridge hints did not show the rule or pause its animation")
				screen._close_dialog()
			var point: Vector2 = screen.world.stone_rect(q.missing).get_center()
			var data := {"type": "bridge_number", "value": int(q.result)}
			_check(screen.world._can_drop_data(point, data) and not screen.world._can_drop_data(Vector2.ZERO, data), "Bridge drop target accepts the wrong location")
			screen.world._drop_data(point, data)
			_check(screen.solved_current and screen.world.solved, "The correct stone did not finish the bridge")
			screen.world._process(2)
			_check(screen.world.walk == 4, "The llama did not cross the completed bridge")
			screen.next_button.pressed.emit()
		_check(screen.view == "game_result" and Progress.game_record("sequences", width).score == 75, "Bridge hint history or completion score failed")
		screen.queue_free()
		await process_frame

func _comparison_tests() -> void:
	for width in range(1, 5):
		var screen := _screen("compare")
		screen.width = width
		screen._start_game()
		for round_ in range(8):
			var q: Dictionary = screen.question
			if round_ == 0:
				var wrong := "<" if q.result != "<" else ">"
				screen._submit(wrong)
				_check(not screen.solved_current, "An incorrect comparison was accepted")
			for button in screen.choices:
				if button.get_meta("answer") == q.result: button.pressed.emit()
			_check(screen.solved_current, "The correct comparison was rejected")
			screen.world._process(1)
			_check(signf(screen.world.tilt) == signi(int(q.left) - int(q.right)), "The comparison balance tipped toward the wrong value")
			screen.next_button.pressed.emit()
		_check(screen.view == "game_result" and Progress.game_record("compare", width).score == 75, "Comparison rounds did not preserve wrong-attempt scoring")
		screen.queue_free()
		await process_frame

func _train_tests() -> void:
	for width in range(1, 5):
		var screen := _screen("quick_challenge")
		screen.width = width
		screen._start_game()
		var seen := {}
		for round_ in range(8):
			await _settle()
			var world: Control = screen.world
			var correct_lane: int = world.options.find(int(screen.question.result))
			_check(not seen.has(screen.question.id), "The train repeated a station in the same trip")
			seen[screen.question.id] = true
			if round_ == 0:
				var wrong_lane := (correct_lane + 1) % 4
				world.select_lane(wrong_lane)
				screen.train_depart.pressed.emit()
				world._process(2)
				_check(not screen.solved_current and world.phase == "return" and world.rejected.has(wrong_lane), "A wrong delivery was rewarded or did not return")
				world._process(1)
				_check(world.phase == "choice" and not world.select_lane(wrong_lane), "The rejected train station remained selectable")
			var touch := InputEventScreenTouch.new()
			touch.pressed = true
			touch.position = world.lane_rect(correct_lane).get_center()
			world._gui_input(touch)
			_check(world.lane == correct_lane, "Touch did not select the train's lane")
			screen.train_depart.pressed.emit()
			world._process(2)
			_check(screen.solved_current and world.phase == "delivered", "Train travel did not deliver the correct answer")
			screen.next_button.pressed.emit()
		_check(screen.view == "game_result" and Progress.game_record("quick_challenge", width).score == 75, "Eight train deliveries did not save the best score")
		screen.queue_free()
		await process_frame
	var screen := _screen("quick_challenge")
	screen.duration = 90
	screen._start_game()
	screen.audio.stop()
	screen._process(2)
	_check(screen.time_left == 88, "The optional train clock did not run")
	screen._show_pause()
	var before: float = screen.time_left
	screen._process(5)
	_check(screen.time_left == before and not screen.world.active, "Pause did not freeze the train and its clock")
	screen._go_back()
	_check(screen.dialog == null and screen.world.active, "Escape did not resume a paused train")
	screen._show_hint()
	screen._process(5)
	_check(screen.time_left == before and not screen.world.active, "A hint consumed train time")
	screen._close_dialog()
	screen._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(screen.dialog_kind == "pause" and not screen.world.active, "Losing focus did not pause train input")
	screen._close_dialog()
	screen.audio.speak("help")
	screen._process(3)
	_check(screen.time_left == before, "Narration consumed reading time in the train")
	screen.audio.stop()
	screen.time_left = 0.1
	screen._process(1)
	_check(screen.view == "game_result" and Progress.game_record("quick_challenge", 1).score == 75, "An empty timed trip overwrote the previous best result")
	_check(Progress.finish_game("quick_challenge", 1, {"unknown": {"answer": 1, "first": true}}, 10) != OK, "An unknown train question earned credit")
	var valid_id: String = Catalog.games("train", 1)[0].id
	_check(Progress.finish_game("quick_challenge", 1, {valid_id: {"answer": [], "first": true}}, 10) != OK, "Malformed train proof was accepted")
	screen.queue_free()
	await process_frame
