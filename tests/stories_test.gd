extends SceneTree

const Repo = preload("res://scripts/stories/story_repository.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	if OS.get_environment("APRENDE_VALIDATION") != "1":
		push_error("Run tools/validate.ps1 to isolate saved progress.")
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	var audio: Node = root.get_node("StoryAudio")
	var original := ConfigFile.new()
	original.set_value("progreso", "temas", {"legacy_visit": true})
	original.set_value("custom", "keep", "original")
	original.save(Repo.SAVE_PATH)
	_check(Repo.totals().completed == 0, "Old visits became new story activity credit")
	var catalog := Repo.all_stories()
	_check(catalog.size() == 16, "The story collection lost titles")
	for story in catalog:
		_check(story.pages.size() == 8 and story.questions.size() == 4, "Story does not offer all four activities: " + story.id)
		var frame_hashes: Dictionary = {}
		for index in range(8):
			var frame := Repo.page_texture(story, index)
			var image := frame.atlas.get_image().get_region(Rect2i(frame.region))
			frame_hashes[hash(image.get_data())] = true
			var narration := load(story.pages[index].audio) as AudioStreamMP3
			_check(narration != null and narration.get_length() > 2.0, "Scene narration failed to decode: %s/%d" % [story.id, index])
		_check(frame_hashes.size() == 8, "The same cover was repeated instead of eight scenes: " + story.id)
		for question in story.questions:
			var clip := load(question.audio) as AudioStreamMP3
			_check(clip != null and clip.get_length() > 1.0, "Question audio failed to decode: " + story.id)
	var home := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(home)
	await process_frame
	home.call("_menu_selection", "Cuentos")
	var menu: Control = home.get("cuentos_menu_screen")
	_check(audio.get("current_path").ends_with("guide/welcome.mp3"), "Carmelo welcome is not packaged male audio")
	for pair in [["cuentos_ilustrados", "read"], ["escucha_cuento", "listen"], ["ordena_historia", "order"], ["preguntas_retos", "quiz"]]:
		menu.call("_on_hotspot_pressed", pair[0])
		await process_frame
		var library: Control = home.get("cuentos_selector_screen")
		_check(is_instance_valid(library) and library.get("activity_mode") == pair[1], "Main story card opened the wrong mode")
		_check(library.get("stories").size() == 16, "A mode did not share the same sixteen stories")
		await process_frame
		await process_frame
		var cards_fit := true
		for story in catalog:
			var card := library.find_child("Tarjeta_" + story.id, true, false) as Button
			var action: Label = library.get("story_action_labels")[story.id]
			cards_fit = cards_fit and card.get_global_rect().encloses(action.get_global_rect())
		_check(cards_fit, "Long titles or summaries clipped the library action labels")
		library.call("_on_back_pressed")
		await process_frame
	_check(Repo.totals().completed == 0, "Browsing story modes awarded completion")
	# The teammate's lower-row game and the four story modes must coexist.
	(menu.find_child("Hotspot_elegir_personaje", true, false) as Button).pressed.emit()
	await process_frame
	var character_game: Control = home.get("character_game_screen")
	_check(is_instance_valid(character_game) and not menu.is_visible_in_tree(), "Character game was lost when combining story changes")
	_check(character_game.get("character_grid").get_child_count() == 8 and character_game.get("character_rounds").size() == 5, "The teammate's characters or rounds were changed")
	_check(audio.get("current_path").is_empty(), "Carmelo's menu narration overlapped the character game")
	var target: Dictionary = character_game.get("character_rounds")[0]
	var wrong_id := "patito" if target.id == "caperucita" else "caperucita"
	(character_game.find_child("Personaje_" + wrong_id, true, false) as Button).pressed.emit()
	_check(character_game.get("score") == 0 and not character_game.get("answered"), "Wrong character selection awarded a point")
	for round_index in range(5):
		target = character_game.get("character_rounds")[round_index]
		(character_game.find_child("Personaje_" + target.id, true, false) as Button).pressed.emit()
		(character_game.get("next_button") as Button).pressed.emit()
	_check(character_game.get("score") == 5 and character_game.get("finish_panel").visible, "The teammate's five-round game did not reach its result")
	(character_game.find_child("VolverACuentos", true, false) as Button).pressed.emit()
	await process_frame
	_check(home.get("character_game_screen") == null and menu.is_visible_in_tree(), "Returning from characters did not restore the story menu")
	_check(Repo.totals().completed == 0, "Character game overwrote the four story activities' progress")
	menu.call("_on_hotspot_pressed", "elegir_personaje")
	await process_frame
	character_game = home.get("character_game_screen")
	home.call("_show_home")
	await process_frame
	_check(home.get("character_game_screen") == null and not is_instance_valid(character_game), "Returning home left the character game open")
	home.call("_menu_selection", "Cuentos")
	await process_frame
	home.call("_open_story_activity", "read")
	await process_frame
	var library: Control = home.get("cuentos_selector_screen")
	library.call("_on_story_selected", catalog[0])
	await process_frame
	var reader: Control = home.get("reading_screen")
	_check(reader.get("story_id") == catalog[0].id, "Selected story did not open")
	reader.call("_leave")
	await process_frame
	_check(is_instance_valid(home.get("cuentos_selector_screen")), "Leaving an activity lost the library")
	home.call("_return_to_cuentos")
	await process_frame
	home.call("_show_home")
	await process_frame
	for story_index in range(catalog.size()):
		var story: Dictionary = catalog[story_index]
		reader = (load("res://scenes/modo_lectura.tscn") as PackedScene).instantiate()
		reader.set("initial_story", story)
		root.add_child(reader)
		_check(not reader.call("_complete", "read"), "Partial reading counted as completed")
		reader.call("_change_page", 1)
		reader.call("_change_page", 1)
		reader.call("_change_page", 1)
		_check(not Repo.is_complete(story.id, "read"), "Reaching the last spread auto-completed reading")
		reader.call("_finish_reading")
		_check(Repo.is_complete(story.id, "read"), "Explicitly completed reading was not saved")
		reader.call("_switch_mode", "listen")
		reader.set("auto_advance", false)
		reader.set("current_page_index", 0)
		reader.call("_render")
		reader.call("_play_page")
		_check(audio.get("player").playing and reader.get("pending_page") == 0, "Listening mode did not start scene audio")
		reader.call("_toggle_playback")
		_check(audio.get("player").stream_paused, "Pause did not preserve the narration position")
		reader.call("_cancel_audio")
		_check(reader.get("listened").is_empty() and not Repo.is_complete(story.id, "listen"), "Interrupted or paused audio granted credit")
		if story_index == 0:
			for page in range(8):
				reader.set("auto_advance", page == 0)
				reader.set("current_page_index", page)
				reader.call("_render")
				reader.call("_play_page")
				var player: AudioStreamPlayer = audio.get("player")
				await create_timer(0.1).timeout
				# Accelerate the real decoder's end; the UI exposes no seeking control.
				player.seek(maxf(0, player.stream.get_length() - 0.035))
				await create_timer(0.35).timeout
				_check(reader.get("listened").has(page), "Real audio completion failed to count scene %d" % page)
				if page == 0:
					_check(reader.get("current_page_index") == 1 and audio.call("speaking"), "Auto narration did not continue with the next scene")
					reader.call("_cancel_audio")
			_check(Repo.is_complete(story.id, "listen"), "Eight full scene endings did not save listening")
			_check("8 escuchadas completas" in reader.get("counter_label").text, "Listening counter did not show the eighth completed scene")
		reader.call("_switch_mode", "order")
		reader.set("order_selected", story.order.duplicate())
		reader.get("order_selected").reverse()
		reader.call("_check_order")
		_check(not Repo.is_complete(story.id, "order"), "Wrong chronological order granted completion")
		reader.set("order_selected", [])
		reader.call("_render")
		await process_frame
		for page in story.order:
			var order_button := reader.find_child("Order_%d" % int(page), true, false) as Button
			order_button.pressed.emit()
			await process_frame
		reader.call("_check_order")
		_check(Repo.is_complete(story.id, "order"), "Correct chronological selection did not complete")
		reader.call("_switch_mode", "quiz")
		await process_frame
		if story_index == 0:
			(reader.get("nav").get_child(1) as Button).pressed.emit()
			_check(reader.get("activity_mode") == "read" and reader.get("current_page_index") == int(story.questions[0].evidence) / 2 * 2, "Question hint did not open its evidence spread")
			reader.call("_switch_mode", "quiz")
			_check(reader.get("question_index") == 0 and reader.get("quiz_points") == 0, "Returning from a hint changed the question or awarded points")
		reader.call("_next_question")
		_check(reader.get("question_index") == 0, "Quiz allowed skipping an unanswered question")
		for question_index in range(4):
			var question: Dictionary = story.questions[question_index]
			if story_index == 0 and question_index == 0:
				var wrong_index := 1 if question.choices.find(question.answer) == 0 else 0
				(reader.get("question_buttons")[wrong_index] as Button).pressed.emit()
				_check(reader.get("quiz_points") == 0 and reader.get("next_question_button").disabled, "Wrong quiz answer gave points or enabled skipping")
			var answer_index: int = question.choices.find(question.answer)
			(reader.get("question_buttons")[answer_index] as Button).pressed.emit()
			var points: int = reader.get("quiz_points")
			reader.call("_answer", question.answer)
			_check(reader.get("quiz_points") == points, "Repeating the correct answer farmed points")
			reader.call("_next_question")
			await process_frame
		_check(Repo.is_complete(story.id, "quiz"), "All four comprehension questions did not save")
		_check(Repo.best_score(story.id) == (35 if story_index == 0 else 40), "Quiz did not distinguish retry learning from first-try answers")
		reader.call("_cancel_audio")
		reader.queue_free()
		await process_frame
	var totals := Repo.totals()
	_check(totals.completed == 49 and totals.points == 635, "The four activities or points were counted incorrectly")
	Repo.complete(catalog[0].id, "quiz", 30)
	Repo.complete(catalog[0].id, "quiz", 30)
	_check(Repo.totals().points == 635, "Replaying lower scores increased total points")
	Repo.complete(catalog[0].id, "quiz", 40)
	_check(Repo.totals().points == 640, "A better result did not replace the previous best score")
	_check(Repo.complete("unknown_story", "quiz", 999) == ERR_INVALID_PARAMETER, "Unknown story created progress")
	var saved := ConfigFile.new()
	saved.load(Repo.SAVE_PATH)
	_check(saved.get_value("custom", "keep") == "original" and saved.get_value("progreso", "temas").has("legacy_visit"), "New progress overwrote legacy or custom save data")
	audio.call("set_sound", false, 80.0)
	_check(not audio.call("guide", "welcome", home), "Muted Carmelo still played audio")
	audio.call("set_sound", true, 80.0)
	home.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("STORIES TEST: %d checks, %d failure(s)" % [checks, failures])
	quit(0 if failures == 0 else 1)
