extends SceneTree

const Sections = preload("res://scripts/math/learning_sections.gd")
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
		push_error("Run tools/validate.ps1 to isolate saved data.")
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	var home := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(home)
	await process_frame
	var previous_atlas: Texture2D
	for pair in [["Matemática", "mathematics"], ["Números", "numbers"], ["Geometría", "geometry"]]:
		var section := Sections.get_section(pair[1])
		var first: String = section.topics[0].id
		var second: String = section.topics[1].id
		var seeded := ConfigFile.new()
		seeded.set_value("custom", "keep", "preserved")
		seeded.set_value("progreso", "actividades", {first + "_1": true, second + "_2": true, first + "_99": true, "unknown_1": true, first + "_3": false})
		seeded.save(section.progress_path)
		home.call("_menu_selection", pair[0])
		await process_frame
		await process_frame
		var menu: Control = home.get("language_screen")
		_check(is_instance_valid(menu) and menu.get("section_id") == pair[1], "Main menu opened wrong llama section: %s" % pair[0])
		_check(menu.get("section").title == section.title, "Section heading is incorrect")
		_check(menu.get("progress_bar").max_value == section.total, "Section activity total is incorrect")
		_check(menu.get("completed_activities").size() == 2, "Invalid or another section's progress was counted")
		var atlas: Texture2D = menu.get("frames")[0].atlas
		_check(previous_atlas == null or atlas == previous_atlas, "Llama image was duplicated instead of sharing its atlas")
		previous_atlas = atlas
		menu.call("_set_voice_enabled", true)
		menu.call("_set_volume", 70.0)
		var player: AudioStreamPlayer = menu.get("voice")
		for clip_id in menu.get("clips"):
			menu.call("_speak", clip_id)
			_check(player.stream is AudioStreamMP3 and player.stream.get_length() > 0.3, "Local neural MP3 did not decode: %s/%s" % [pair[1], clip_id])
			_check(player.playing, "Local narration did not start: %s/%s" % [pair[1], clip_id])
		menu.call("_speak", "welcome")
		await create_timer(0.16).timeout
		_check(menu.get("frame_index") in [1, 2, 3], "Speaking llama did not animate its mouth")
		for topic in section.topics:
			(menu.get("buttons")[topic.id] as Button).pressed.emit()
			_check(menu.get("selected_topic") == topic.id, "Wrong topic selected in %s" % pair[1])
			if pair[1] == "mathematics":
				var activity: Control = menu.get("math_activity")
				_check(is_instance_valid(activity) and activity.get("topic_id") == topic.id, "The real mathematics activity did not open")
				_check(not menu.get("design").visible and not player.playing, "The mathematics menu overlapped its activity")
				activity.emit_signal("back_requested")
				await process_frame
			else:
				_check(menu.get("current_voice") == topic.id, "Wrong topic narration in %s" % pair[1])
				_check(is_instance_valid(menu.get("dialog_layer")), "Topic preview did not open")
				menu.call("_close_dialog")
			_check(not player.playing and player.stream == null, "Dialog close did not release its audio")
		var after := ConfigFile.new()
		after.load(section.progress_path)
		_check(after.get_value("custom", "keep") == "preserved" and after.get_value("progreso", "actividades") == seeded.get_value("progreso", "actividades"), "Menu exploration modified saved progress")
		menu.call("_show_help")
		var cancel := InputEventAction.new()
		cancel.action = "ui_cancel"
		cancel.pressed = true
		menu.call("_unhandled_key_input", cancel)
		_check(menu.get("dialog_layer") == null, "Escape did not close the menu dialog")
		menu.call("_set_voice_enabled", false)
		menu.call("_leave")
		_check(not player.playing, "Leaving a section kept its voice playing")
		await process_frame
		home.call("_menu_selection", pair[0])
		await process_frame
		menu = home.get("language_screen")
		_check(menu.get("muted") and menu.get("volume") == 70.0, "Shared voice preferences were lost")
		_check(not menu.get("voice").playing, "Saved mute was ignored")
		menu.call("_leave")
		await process_frame
	_check(Sections.get_section("numbers").progress_path != Sections.get_section("mathematics").progress_path and Sections.get_section("geometry").progress_path != Sections.get_section("numbers").progress_path, "Learning sections share a progress file")
	home.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("LEARNING SECTIONS TEST: %d checks, %d failure(s)" % [checks, failures])
	quit(0 if failures == 0 else 1)
