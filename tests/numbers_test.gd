extends SceneTree

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
		push_error("Use tools/validate.ps1 to isolate player saves.")
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	var home := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(home)
	await process_frame
	home.call("_menu_selection", "Números")
	await process_frame
	await process_frame
	var numbers: Control = home.get("language_screen")
	_check(is_instance_valid(numbers) and numbers.get_script().resource_path == "res://scripts/math/numbers_menu.gd", "Números opened the wrong module")
	if not is_instance_valid(numbers):
		quit(1)
		return
	_check(numbers.get("frames").size() == 6, "Llama atlas did not load six frames")
	_check(numbers.get("voice").playing, "Numbers welcome did not start its packaged audio")
	_check(numbers.get("current_voice") == "welcome", "Welcome clip is not active")
	var atlas: Texture2D = numbers.get("frames")[0].atlas
	_check(atlas.get_image().get_pixel(0, 0).a < 0.01, "Character atlas has an opaque background")
	_check(numbers.get("completed_activities").is_empty(), "New Numbers session started with fake progress")
	_check(numbers.get("progress_bar").value == 0.0, "Empty progress was not shown as zero")
	var buttons: Dictionary = numbers.get("buttons")
	for topic in ["one_digit", "two_digits", "three_digits", "four_digits", "count_objects", "sequences", "compare", "quick_challenge"]:
		(buttons[topic] as Button).pressed.emit()
		_check(numbers.get("selected_topic") == topic, "Topic button routed incorrectly: %s" % topic)
		_check(is_instance_valid(numbers.get("dialog_layer")), "Topic button did not open its preview: %s" % topic)
		_check(numbers.get("current_voice") == topic and numbers.get("voice").stream != null, "Topic did not use its local narration: %s" % topic)
		numbers.call("_close_dialog")
		_check(not numbers.get("voice").playing, "Closing a preview did not stop the voice")
	_check(numbers.get("completed_activities").is_empty(), "Opening previews awarded progress")
	_check(not FileAccess.file_exists("user://progreso_numeros.cfg"), "Exploring Numbers wrote a progress save")
	(buttons.help as Button).pressed.emit()
	_check(numbers.get("current_voice") == "help", "Help button did not start its guidance")
	numbers.call("_close_dialog")
	(buttons.settings as Button).pressed.emit()
	_check(is_instance_valid(numbers.get("dialog_layer")), "Settings button did not open sound controls")
	numbers.call("_set_voice_enabled", false)
	numbers.call("_speak", "welcome")
	_check(not numbers.get("voice").playing and numbers.get("frame_index") == 0, "Muted guide kept speaking or moving its mouth")
	numbers.call("_set_voice_enabled", true)
	numbers.call("_speak", "welcome")
	_check(numbers.get("voice").playing, "Unmuting did not allow local narration")
	numbers.call("_set_volume", 0.0)
	_check(not numbers.get("voice").playing, "Zero volume did not stop narration")
	numbers.call("_set_volume", 65.0)
	numbers.call("_set_voice_enabled", false)
	numbers.call("_close_dialog")
	root.size = Vector2i(1024, 600)
	await process_frame
	await process_frame
	var board: Control = numbers.get("design")
	_check(absf(board.size.x / board.size.y - 16.0 / 9.0) < 0.001, "Resizing distorted the menu artwork")
	# canvas_items stretch keeps logical coordinates separate from window pixels.
	_check(board.position.x >= 0 and board.position.y >= 0 and board.get_rect().end.x <= numbers.size.x + 1 and board.get_rect().end.y <= numbers.size.y + 1, "Menu escaped its logical viewport after resizing")
	(buttons.back as Button).pressed.emit()
	await process_frame
	_check(home.get("language_screen") == null, "Back button did not return to the main menu")
	home.call("_menu_selection", "Números")
	await process_frame
	numbers = home.get("language_screen")
	_check(numbers.get("muted") and numbers.get("volume") == 65.0, "Sound settings did not persist across reopening")
	_check(not numbers.get("voice").playing, "Reopening ignored the saved mute setting")
	numbers.call("_leave")
	await process_frame
	home.call("_menu_selection", "Cuentos")
	await process_frame
	var stories: Control = home.get("language_screen")
	_check(is_instance_valid(stories) and stories.get_script().resource_path == "res://scripts/cuentos_menu.gd", "Cuentos navigation was changed by Numbers")
	home.call("_show_home")
	await process_frame
	home.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("NUMBERS TEST: %d checks, %d failure(s)" % [checks, failures])
	quit(0 if failures == 0 else 1)
