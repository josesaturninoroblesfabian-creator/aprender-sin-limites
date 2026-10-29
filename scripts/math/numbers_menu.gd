extends Control

signal back_requested
signal topic_selected(topic_id: String)

const Sections = preload("res://scripts/math/learning_sections.gd")
const ProgressStore = preload("res://scripts/storage/progress_store.gd")
# Keep the previous Numbers preferences; all three menus share the same guide.
const SETTINGS_PATH := "user://ajustes_numeros.cfg"
const TALK_FRAMES := [1, 2, 1, 3, 2, 1, 0]

@export_enum("numbers", "mathematics", "geometry") var section_id := "numbers"
var section: Dictionary = {}

var design: Control
var avatar: TextureRect
var frames: Array[AtlasTexture] = []
var voice: AudioStreamPlayer
var clips: Dictionary = {}
var buttons: Dictionary = {}
var bubble_label: Label
var progress_label: Label
var progress_bar: ProgressBar
var progress_stars: Array[Label] = []
var dialog_layer: Control
var focus_before_dialog: Control
var selected_topic: String = ""
var current_voice: String = ""
var muted := false
var volume := 85.0
var elapsed := 0.0
var talking_clock := 0.0
var frame_index := -1
var completed_activities: Dictionary = {}
var math_activity: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	section = Sections.get_section(section_id)
	var settings := ProgressStore.read(SETTINGS_PATH)
	muted = settings.get_value("audio", "muted", false) == true
	var stored_volume: Variant = settings.get_value("audio", "volume", 85.0)
	if stored_volume is float or stored_volume is int:
		volume = clampf(float(stored_volume), 0.0, 100.0)
	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string(section.voice_catalog))
	if catalog is Dictionary:
		clips = catalog.get("clips", {})
	voice = AudioStreamPlayer.new()
	voice.finished.connect(_on_voice_finished)
	add_child(voice)
	var matte := ColorRect.new()
	matte.color = Color("#063d6b")
	matte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	matte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(matte)
	design = Control.new()
	design.clip_contents = true
	add_child(design)
	var background := TextureRect.new()
	background.texture = load(section.background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design.add_child(background)
	_build_avatar()
	_build_bubble()
	for topic in section.topics:
		_add_hotspot(topic.id, topic.title, topic.rect, topic.color)
	if section_id == "geometry":
		var back_art := TextureRect.new()
		back_art.texture = load("res://assets/ui/language/volver-menu.png")
		back_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		back_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		back_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(back_art, Rect2(0.008, 0.865, 0.149, 0.121))
		design.add_child(back_art)
	_add_hotspot("back", "Volver al menú principal", Rect2(0.008, 0.865, 0.149, 0.121), Color("#ffe082"))
	_add_hotspot("settings", "Configuración de sonido", Rect2(0.847, 0.057, 0.071, 0.106), Color("#c1a0ff"))
	_add_hotspot("help", "Ayuda", Rect2(0.927, 0.057, 0.063, 0.106), Color("#b9eeff"))
	_build_progress()
	_load_progress()
	resized.connect(_fit_design)
	_fit_design()
	_speak("welcome")

func _fit_design() -> void:
	if not is_instance_valid(design):
		return
	var width := minf(size.x, size.y * 16.0 / 9.0)
	design.size = Vector2(width, width * 9.0 / 16.0)
	design.position = (size - design.size) * 0.5

func _build_avatar() -> void:
	var atlas: Texture2D = load("res://assets/characters/llama/llama-teacher-atlas.png")
	var cell := Vector2(atlas.get_width() / 3.0, atlas.get_height() / 2.0)
	for index in range(6):
		var frame := AtlasTexture.new()
		frame.atlas = atlas
		frame.region = Rect2(Vector2(index % 3, index / 3) * cell, cell)
		frame.filter_clip = true
		frames.append(frame)
	avatar = TextureRect.new()
	avatar.name = "LlamaGuide"
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(avatar, Rect2(-0.06, 0.285, 0.385, 0.56))
	design.add_child(avatar)
	_set_frame(0)
	var repeat := _add_hotspot("repeat", "Toca la llama para repetir la bienvenida", Rect2(0.01, 0.33, 0.25, 0.49), Color("#ffdf72"))
	repeat.add_theme_stylebox_override("hover", _hotspot_style(Color.TRANSPARENT, Color.TRANSPARENT))

func _build_bubble() -> void:
	var bubble := PanelContainer.new()
	bubble.name = "GuideBubble"
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_theme_stylebox_override("panel", _panel_style(Color("#fffdf0"), Color("#ffce3c"), 4, 22))
	_place(bubble, Rect2(0.018, 0.215, 0.258, 0.12))
	design.add_child(bubble)
	bubble_label = _label(section.greeting + "\nTócame para escuchar otra vez.", 19, Color("#073e83"))
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble.add_child(bubble_label)

func _add_hotspot(id: String, title: String, rect: Rect2, color: Color) -> Button:
	var button := Button.new()
	button.name = "%s_%s" % [section_id, id]
	button.tooltip_text = title
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", _hotspot_style(Color.TRANSPARENT, Color.TRANSPARENT))
	button.add_theme_stylebox_override("hover", _hotspot_style(Color(1, 1, 1, 0.12), color))
	button.add_theme_stylebox_override("pressed", _hotspot_style(Color(1, 1, 1, 0.25), Color.WHITE))
	button.add_theme_stylebox_override("focus", _hotspot_style(Color(1, 1, 1, 0.08), Color.WHITE))
	_place(button, rect)
	button.pressed.connect(_on_menu_pressed.bind(id))
	design.add_child(button)
	buttons[id] = button
	return button

func _build_progress() -> void:
	var panel := PanelContainer.new()
	panel.name = "LearningProgress"
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#eff8ff"), Color("#bce4f7"), 2, 14))
	_place(panel, Rect2(0.778, 0.343, 0.202, 0.22))
	design.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	panel.add_child(column)
	progress_label = _label("0 de %d actividades" % section.total, 16, Color("#134a78"))
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(progress_label)
	progress_bar = ProgressBar.new()
	progress_bar.max_value = section.total
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size.y = 13
	progress_bar.add_theme_stylebox_override("background", _panel_style(Color("#c5d5e4"), Color.TRANSPARENT, 0, 8))
	progress_bar.add_theme_stylebox_override("fill", _panel_style(Color("#28c753"), Color.TRANSPARENT, 0, 8))
	column.add_child(progress_bar)
	var levels := HBoxContainer.new()
	levels.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(levels)
	for caption in ["Iniciando", "Practicando", "¡Experto!"]:
		var level := VBoxContainer.new()
		level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		level.add_theme_constant_override("separation", 0)
		levels.add_child(level)
		var star := _label("★", 35, Color("#899aab"))
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level.add_child(star)
		progress_stars.append(star)
		var text := _label(caption, 11, Color("#134a78"))
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level.add_child(text)

func _process(delta: float) -> void:
	if is_instance_valid(math_activity): return
	elapsed += delta
	var talking := is_instance_valid(voice) and voice.playing and not muted and volume > 0.0
	if talking:
		talking_clock += delta
		_set_frame(TALK_FRAMES[int(talking_clock / 0.12) % TALK_FRAMES.size()])
	else:
		talking_clock = 0.0
		_set_frame(4 if fmod(elapsed, 4.8) > 4.62 else 0)
	if is_instance_valid(avatar):
		var bob := sin(elapsed * 2.2) * 1.8
		avatar.offset_top = bob
		avatar.offset_bottom = bob

func _set_frame(index: int) -> void:
	if index != frame_index and is_instance_valid(avatar):
		frame_index = index
		avatar.texture = frames[index]

func _speak(id: String) -> void:
	_stop_voice()
	if muted or volume <= 0.0:
		return
	var entry: Dictionary = clips.get(id, {})
	var file := String(entry.get("file", ""))
	if not file.is_valid_filename() or file.get_extension() not in ["mp3", "wav"]:
		return
	var path: String = section.voice_folder + file
	if not ResourceLoader.exists(path):
		return
	voice.stream = load(path) as AudioStream
	if voice.stream == null:
		return
	voice.volume_db = linear_to_db(volume / 100.0)
	current_voice = id
	voice.play()

func _stop_voice() -> void:
	current_voice = ""
	if is_instance_valid(voice):
		voice.stop()
		voice.stream = null
	_set_frame(0)

func _on_voice_finished() -> void:
	current_voice = ""
	_set_frame(0)

func _on_menu_pressed(id: String) -> void:
	match id:
		"back":
			_leave()
		"repeat":
			_speak("welcome")
		"help":
			_show_help()
		"settings":
			_show_settings()
		_:
			_show_topic(id)

func _show_topic(id: String) -> void:
	var topic := Sections.find_topic(section, id)
	if topic.is_empty():
		return
	selected_topic = id
	topic_selected.emit(id)
	if section_id == "mathematics":
		_open_math_activity(id)
		return
	var column := _open_dialog(topic.title, topic.color)
	var example := _label(topic.example, 30, topic.color.darkened(0.25))
	example.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(example)
	_add_paragraph(column, topic.detail, 22)
	_add_paragraph(column, "Próximamente: actividades para practicar este tema.", 17)
	var repeat := _action_button("Escuchar otra vez", topic.color.darkened(0.18))
	repeat.pressed.connect(_speak.bind(id))
	column.add_child(repeat)
	_add_close_button(column)
	_speak(id)

func _open_math_activity(id: String) -> void:
	_close_dialog()
	if is_instance_valid(math_activity): _close_math_activity()
	_stop_voice()
	design.hide()
	var screen: Control = load("res://scenes/math_activity.tscn").instantiate()
	screen.set("topic_id", id)
	screen.connect("back_requested", _close_math_activity)
	math_activity = screen
	add_child(screen)

func _close_math_activity() -> void:
	if is_instance_valid(math_activity):
		var activity_audio: Node = math_activity.get("audio")
		if is_instance_valid(activity_audio): activity_audio.call("stop")
		math_activity.hide()
		math_activity.queue_free()
	math_activity = null
	design.show()
	var settings := ProgressStore.read(SETTINGS_PATH)
	muted = settings.get_value("audio", "muted", false) == true
	volume = clampf(float(settings.get_value("audio", "volume", 85.0)), 0, 100)
	_load_progress()

func _show_help() -> void:
	var column := _open_dialog("¡Vamos a explorar!", Color("#087ecc"))
	var guidance := "Toca una tarjeta para conocer su tema.\nToca la llama para repetir la bienvenida.\nEn Configuración puedes ajustar su voz."
	if section_id == "mathematics": guidance = "Las cuatro operaciones tienen misiones para aprender paso a paso. Abajo encontrarás cuatro juegos para practicar. En la aventura mueve la llama con flechas y salta con Espacio o con los controles táctiles."
	_add_paragraph(column, guidance, 21)
	_add_paragraph(column, "Tu progreso se guardará en este dispositivo al completar actividades. Explorar el menú no suma estrellas.", 18)
	_add_close_button(column)
	_speak("help")

func _show_settings() -> void:
	_stop_voice()
	var column := _open_dialog("Sonido", Color("#8350ca"))
	var enabled := CheckButton.new()
	enabled.text = "Escuchar a la guía"
	enabled.button_pressed = not muted
	enabled.custom_minimum_size.y = 44
	enabled.add_theme_font_size_override("font_size", 23)
	enabled.add_theme_color_override("font_color", Color("#21496e"))
	enabled.add_theme_color_override("font_hover_color", Color("#073e83"))
	enabled.add_theme_color_override("font_pressed_color", Color("#21496e"))
	enabled.add_theme_color_override("font_hover_pressed_color", Color("#073e83"))
	enabled.add_theme_color_override("font_focus_color", Color("#073e83"))
	enabled.toggled.connect(_set_voice_enabled)
	column.add_child(enabled)
	_add_paragraph(column, "Volumen de la voz", 19)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.value = volume
	slider.custom_minimum_size.y = 44
	slider.value_changed.connect(_set_volume)
	column.add_child(slider)
	var sample := _action_button("Probar la voz", Color("#8350ca"))
	sample.pressed.connect(_speak.bind("welcome"))
	column.add_child(sample)
	_add_paragraph(column, "La voz está incluida y funciona sin internet.", 16)
	_add_close_button(column)

func _open_dialog(title: String, color: Color) -> VBoxContainer:
	_close_dialog()
	focus_before_dialog = get_viewport().gui_get_focus_owner()
	_stop_voice()
	dialog_layer = Control.new()
	dialog_layer.name = "LearningDialog"
	dialog_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	design.add_child(dialog_layer)
	var shade := Button.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed"]:
		var dim_style := StyleBoxFlat.new()
		dim_style.bg_color = Color(0.01, 0.07, 0.15, 0.70)
		shade.add_theme_stylebox_override(state, dim_style)
	shade.pressed.connect(_close_dialog)
	dialog_layer.add_child(shade)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#fffdf3"), color, 5, 25, 22))
	_place(panel, Rect2(0.29, 0.23, 0.48, 0.58))
	dialog_layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 13)
	panel.add_child(column)
	var heading := _label(title, 32, Color("#153f73"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	for button in buttons.values():
		button.disabled = true
	return column

func _add_close_button(column: VBoxContainer) -> void:
	var close := _action_button("Volver a " + section.title, Color("#087ecc"))
	close.pressed.connect(_close_dialog)
	column.add_child(close)
	close.grab_focus()

func _close_dialog() -> void:
	if is_instance_valid(dialog_layer):
		dialog_layer.hide()
		dialog_layer.queue_free()
	dialog_layer = null
	_stop_voice()
	for button in buttons.values():
		button.disabled = false
	if is_instance_valid(focus_before_dialog):
		focus_before_dialog.grab_focus()

func _set_voice_enabled(enabled: bool) -> void:
	muted = not enabled
	if muted:
		_stop_voice()
	_save_settings()

func _set_volume(value: float) -> void:
	volume = value
	if volume <= 0.0:
		_stop_voice()
	elif voice.playing:
		voice.volume_db = linear_to_db(volume / 100.0)
	_save_settings()

func _save_settings() -> void:
	var config := ProgressStore.read(SETTINGS_PATH)
	config.set_value("audio", "muted", muted)
	config.set_value("audio", "volume", volume)
	if ProgressStore.write(config, SETTINGS_PATH) != OK:
		bubble_label.text = "No se pudo guardar el ajuste de sonido."

func _load_progress() -> void:
	completed_activities.clear()
	var config := ProgressStore.read(section.progress_path)
	var saved: Variant = config.get_value("progreso", "actividades", {})
	if saved is Dictionary:
		for id in saved:
			if saved[id] == true and _valid_activity_id(String(id)):
				completed_activities[id] = true
	_refresh_progress()

func _valid_activity_id(id: String) -> bool:
	for topic in section.topics.slice(0, 4):
		for index in range(1, int(section.per_topic) + 1):
			if id == "%s_%d" % [topic.id, index]:
				return true
	return false

func _refresh_progress() -> void:
	var count := completed_activities.size()
	progress_label.text = ("%d de %d misiones" if section_id == "mathematics" else "%d de %d actividades") % [count, section.total]
	progress_bar.value = count
	for index in range(progress_stars.size()):
		progress_stars[index].add_theme_color_override("font_color", Color("#ffc928") if count >= [1, int(section.total) / 2, int(section.total)][index] else Color("#899aab"))

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(math_activity): return
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(dialog_layer):
			_close_dialog()
		else:
			_leave()
		get_viewport().set_input_as_handled()

func _leave() -> void:
	_stop_voice()
	back_requested.emit()

func _exit_tree() -> void:
	_stop_voice()

func _add_paragraph(column: VBoxContainer, text: String, font_size: int) -> void:
	var label := _label(text, font_size, Color("#21496e"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)

func _action_button(text: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 21)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, _panel_style(color.lightened(0.12) if state == "hover" else color, Color("#d4efff") if state == "focus" else color.darkened(0.2), 2, 13, 6))
	return button

func _panel_style(fill: Color, border: Color, width: int, radius: int, margin: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	return style

func _hotspot_style(fill: Color, border: Color) -> StyleBoxFlat:
	return _panel_style(fill, border, 3, 22, 0)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _place(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.end.x
	control.anchor_bottom = rect.end.y
