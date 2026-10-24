extends Control

const MenuCatalog = preload("res://scripts/menu/menu_catalog.gd")

const GIRL_HELLO := "¡Bienvenido a Aprende sin Límites!"
const BOY_HELLO := "¿Qué deseas aprender? Escoge el tema que quieres aprender."
const BOY_BYE := "¡Aprendiste mucho hoy!"
const GIRL_BYE := "¡Hasta la próxima! ¡Adiós!"

var root_box: VBoxContainer
var content: VBoxContainer
var title_label: Label
var subtitle_label: Label
var menu_overlay: Control
var artwork: TextureRect
var girl_avatar: TextureRect
var boy_avatar: TextureRect
var dialogue_box: PanelContainer
var dialogue_label: Label
var greeting_audio: AudioStreamPlayer
var boy_intro_audio: AudioStreamPlayer
var exit_audio: AudioStreamPlayer
var speech_flow: String = ""
var girl_mouth_open: bool = false
var boy_mouth_open: bool = false
var girl_talking_frames: Array[Texture2D] = []
var girl_gif_frames: Array[Texture2D] = []
var girl_talking_frame_index: int = 0
var girl_gif_frame_clock: float = 0.0
var girl_gif_frame_interval: float = 0.08
var boy_gif_frames: Array[Texture2D] = []
var boy_gif_frame_index: int = 0
var boy_gif_frame_clock: float = 0.0
var boy_gif_frame_interval: float = 0.08
var exit_gif_frames: Array[Texture2D] = []
var exit_gif_frame_index: int = 0
var exit_gif_frame_clock: float = 0.0
var exit_gif_frame_interval: float = 0.08
var language_screen: Control
var cuentos_menu_screen: Control
var cuentos_selector_screen: Control
var reading_screen: Control

func _ready() -> void:
	_build_shell()
	greeting_audio = AudioStreamPlayer.new()
	greeting_audio.stream = load("res://assets/audio/bienvenida-nina.mp3")
	greeting_audio.finished.connect(_on_girl_greeting_finished)
	add_child(greeting_audio)
	boy_intro_audio = AudioStreamPlayer.new()
	boy_intro_audio.stream = load("res://assets/audio/audio-nino.mp3")
	boy_intro_audio.finished.connect(_on_boy_intro_finished)
	add_child(boy_intro_audio)
	exit_audio = AudioStreamPlayer.new()
	exit_audio.stream = load("res://assets/audio/audio-despedida.mp3")
	exit_audio.finished.connect(_on_exit_audio_finished)
	add_child(exit_audio)
	_show_home()
	_begin_welcome()

func _process(delta: float) -> void:
	if speech_flow == "exit" and exit_audio != null and exit_audio.playing and not exit_gif_frames.is_empty():
		exit_gif_frame_clock += delta
		if exit_gif_frame_clock >= exit_gif_frame_interval:
			exit_gif_frame_clock = 0.0
			exit_gif_frame_index = (exit_gif_frame_index + 1) % exit_gif_frames.size()
			_show_exit_gif_frame(exit_gif_frame_index)
	elif greeting_audio != null and greeting_audio.playing and not girl_gif_frames.is_empty():
		girl_gif_frame_clock += delta
		if girl_gif_frame_clock >= girl_gif_frame_interval:
			girl_gif_frame_clock = 0.0
			girl_talking_frame_index = (girl_talking_frame_index + 1) % girl_gif_frames.size()
			_show_gif_frame(girl_talking_frame_index)
	elif girl_mouth_open:
		_set_girl_mouth(false)
	if boy_intro_audio != null and boy_intro_audio.playing and not boy_gif_frames.is_empty():
		boy_gif_frame_clock += delta
		if boy_gif_frame_clock >= boy_gif_frame_interval:
			boy_gif_frame_clock = 0.0
			boy_gif_frame_index = (boy_gif_frame_index + 1) % boy_gif_frames.size()
			_show_boy_gif_frame(boy_gif_frame_index)
	elif boy_mouth_open:
		_set_boy_mouth(false)

func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("#cceeff")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	artwork = TextureRect.new()
	artwork.texture = load("res://assets/backgrounds/fondo-andes.png")
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(artwork)

	for frame_number in range(1, 7):
		girl_talking_frames.append(load("res://assets/characters/nina/nina-habla-%02d.png" % frame_number))
	for frame_number in range(100):
		girl_gif_frames.append(load("res://assets/characters/nina/welcome/frame_%03d.png" % frame_number))
	for frame_number in range(107):
		boy_gif_frames.append(load("res://assets/characters/nino/welcome/frame_%03d.png" % frame_number))
	for frame_number in range(78):
		exit_gif_frames.append(load("res://assets/characters/nina/goodbye/frame_%03d.png" % frame_number))
	girl_avatar = _make_avatar("res://assets/characters/nina/nina-habla-01.png", true)
	boy_avatar = _make_avatar("res://assets/characters/nino/nino-cerrada.png", false)
	_start_idle_animation(girl_avatar, 0.0)
	_start_idle_animation(boy_avatar, 0.45)

	root_box = VBoxContainer.new()
	root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_box.offset_left = 32
	root_box.offset_top = 18
	root_box.offset_right = -32
	root_box.offset_bottom = -18
	root_box.add_theme_constant_override("separation", 12)
	add_child(root_box)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	root_box.add_child(header)

	title_label = Label.new()
	title_label.text = "APRENDE SIN LÍMITES"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color("#063e77"))
	title_label.add_theme_color_override("font_shadow_color", Color.WHITE)
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	header.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "AVENTURAS DEL SABER  •  JUEGA  •  APRENDE  •  DESCUBRE"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 17)
	subtitle_label.add_theme_color_override("font_color", Color("#073e73"))
	root_box.add_child(subtitle_label)

	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	root_box.add_child(content)

	var footer := Label.new()
	footer.text = "¡Tu conocimiento no tiene fronteras!   •   Funciona sin conexión a internet"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 17)
	footer.add_theme_color_override("font_color", Color("#073e73"))
	root_box.add_child(footer)

	menu_overlay = Control.new()
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(menu_overlay)
	for item in MenuCatalog.ITEMS:
		var rect: Rect2 = item.rect
		_add_menu_card(item.name, item.icon, rect.position.x, rect.position.y, rect.size.x, rect.size.y)

	dialogue_box = PanelContainer.new()
	dialogue_box.anchor_left = 0.53
	dialogue_box.anchor_top = 0.04
	dialogue_box.anchor_right = 0.97
	dialogue_box.anchor_bottom = 0.17
	dialogue_box.add_theme_stylebox_override("panel", _card_style(Color("#073e83")))
	menu_overlay.add_child(dialogue_box)
	dialogue_label = Label.new()
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 22)
	dialogue_label.add_theme_color_override("font_color", Color.WHITE)
	dialogue_box.add_child(dialogue_label)
	dialogue_box.visible = false

func _make_avatar(normal_path: String, is_left: bool) -> TextureRect:
	var avatar := TextureRect.new()
	avatar.texture = load(normal_path)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_left:
		avatar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		avatar.offset_left = 4
		avatar.offset_right = 270
		avatar.offset_top = -360
		avatar.offset_bottom = -8
	else:
		avatar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		avatar.offset_left = -270
		avatar.offset_right = -4
		avatar.offset_top = -360
		avatar.offset_bottom = -8
	add_child(avatar)
	return avatar

func _start_idle_animation(avatar: TextureRect, delay: float) -> void:
	var start_y := avatar.position.y
	var tween := create_tween().set_loops()
	tween.tween_interval(delay)
	tween.tween_property(avatar, "position:y", start_y - 8.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(avatar, "position:y", start_y, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)



func _begin_welcome() -> void:
	speech_flow = "welcome"
	dialogue_box.visible = true
	dialogue_label.text = GIRL_HELLO
	girl_gif_frame_clock = 0.0
	girl_talking_frame_index = 0
	_show_gif_frame(0)
	if greeting_audio.stream != null and greeting_audio.stream.get_length() > 0.0:
		girl_gif_frame_interval = greeting_audio.stream.get_length() / girl_gif_frames.size()
	greeting_audio.play()

func _on_girl_greeting_finished() -> void:
	_show_girl_frame(0)
	_set_girl_mouth(false)
	if speech_flow != "welcome":
		return
	dialogue_label.text = BOY_HELLO
	boy_gif_frame_clock = 0.0
	boy_gif_frame_index = 0
	_show_boy_gif_frame(0)
	if boy_intro_audio.stream != null and boy_intro_audio.stream.get_length() > 0.0:
		boy_gif_frame_interval = boy_intro_audio.stream.get_length() / boy_gif_frames.size()
	boy_intro_audio.play()

func _on_boy_intro_finished() -> void:
	boy_avatar.texture = load("res://assets/characters/nino/nino-cerrada.png")
	_set_boy_mouth(false)
	if speech_flow == "welcome":
		dialogue_box.visible = false
		speech_flow = ""

func _set_girl_mouth(open: bool) -> void:
	if girl_avatar == null:
		return
	girl_mouth_open = open
	_show_girl_frame(2 if open else 0)

func _show_girl_frame(frame_index: int) -> void:
	if girl_avatar == null or girl_talking_frames.is_empty():
		return
	var safe_index: int = clampi(frame_index, 0, girl_talking_frames.size() - 1)
	girl_avatar.texture = girl_talking_frames[safe_index]

func _show_gif_frame(frame_index: int) -> void:
	if girl_avatar == null or girl_gif_frames.is_empty():
		return
	var safe_index: int = clampi(frame_index, 0, girl_gif_frames.size() - 1)
	girl_avatar.texture = girl_gif_frames[safe_index]

func _show_boy_gif_frame(frame_index: int) -> void:
	if boy_avatar == null or boy_gif_frames.is_empty():
		return
	var safe_index: int = clampi(frame_index, 0, boy_gif_frames.size() - 1)
	boy_avatar.texture = boy_gif_frames[safe_index]

func _show_exit_gif_frame(frame_index: int) -> void:
	if girl_avatar == null or exit_gif_frames.is_empty():
		return
	var safe_index: int = clampi(frame_index, 0, exit_gif_frames.size() - 1)
	girl_avatar.texture = exit_gif_frames[safe_index]

func _set_boy_mouth(open: bool) -> void:
	if boy_avatar == null or boy_mouth_open == open:
		return
	boy_mouth_open = open
	boy_avatar.texture = load("res://assets/characters/nino/nino-abierta.png") if open else load("res://assets/characters/nino/nino-cerrada.png")



func _add_menu_card(module_name: String, icon_path: String, x: float, y: float, width: float, height: float) -> void:
	var button := Button.new()
	button.name = "Hotspot" + module_name
	button.text = ""
	button.tooltip_text = module_name
	button.anchor_left = x
	button.anchor_top = y
	button.anchor_right = x + width
	button.anchor_bottom = y + height
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	var transparent_style := StyleBoxFlat.new()
	transparent_style.bg_color = Color.TRANSPARENT
	transparent_style.set_border_width_all(0)
	button.add_theme_stylebox_override("normal", transparent_style)
	button.add_theme_stylebox_override("hover", transparent_style)
	button.add_theme_stylebox_override("pressed", transparent_style)
	button.add_theme_stylebox_override("focus", transparent_style)
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	button.pressed.connect(_menu_selection.bind(module_name))
	menu_overlay.add_child(button)

func _show_home() -> void:
	if reading_screen != null and is_instance_valid(reading_screen):
		reading_screen.queue_free()
	reading_screen = null
	if cuentos_selector_screen != null and is_instance_valid(cuentos_selector_screen):
		cuentos_selector_screen.queue_free()
	cuentos_selector_screen = null
	if language_screen != null and is_instance_valid(language_screen):
		language_screen.queue_free()
	language_screen = null
	cuentos_menu_screen = null
	_clear_content()
	root_box.visible = false
	menu_overlay.visible = true
	artwork.visible = true
	girl_avatar.visible = true
	boy_avatar.visible = true
	dialogue_box.visible = false
	for child in menu_overlay.get_children():
		if child is Button:
			child.disabled = false

func _menu_selection(module_name: String) -> void:
	if module_name == "Salir":
		_start_exit_dialogue()
		return
	if speech_flow != "":
		DisplayServer.tts_stop()
		greeting_audio.stop()
		boy_intro_audio.stop()
		speech_flow = ""
		dialogue_box.visible = false
		_set_girl_mouth(false)
		_set_boy_mouth(false)
	var details := "Sonido, idioma y accesibilidad"
	for item in MenuCatalog.ITEMS:
		if item.name == module_name:
			details = item.detail
	_open_module(module_name, details)

func _open_module(module_name: String, description: String) -> void:
	if module_name == "Lenguaje":
		_open_language_game()
		return
	if module_name == "Cuentos":
		_open_cuentos_menu()
		return
	_show_module_placeholder(module_name, description)

func _open_cuentos_menu() -> void:
	menu_overlay.visible = false
	artwork.visible = false
	girl_avatar.visible = false
	boy_avatar.visible = false
	root_box.visible = false
	var cuentos: Control = load("res://scenes/cuentos_menu.tscn").instantiate()
	cuentos.connect("back_requested", Callable(self, "_show_home"))
	cuentos.connect("illustrated_stories_requested", Callable(self, "_open_illustrated_stories"))
	language_screen = cuentos
	cuentos_menu_screen = cuentos
	add_child(cuentos)

func _open_illustrated_stories() -> void:
	if cuentos_menu_screen != null and is_instance_valid(cuentos_menu_screen):
		cuentos_menu_screen.hide()
	var selector: Control = load("res://scenes/selector_cuentos.tscn").instantiate()
	selector.connect("back_requested", Callable(self, "_return_to_cuentos"))
	selector.connect("story_selected", Callable(self, "_open_story"))
	cuentos_selector_screen = selector
	add_child(selector)

func _open_story(story_data: Dictionary) -> void:
	if cuentos_selector_screen != null and is_instance_valid(cuentos_selector_screen):
		cuentos_selector_screen.hide()
	var reader: Control = load("res://scenes/modo_lectura.tscn").instantiate()
	reader.connect("back_requested", Callable(self, "_return_to_selector"))
	reader.connect("story_completed", Callable(cuentos_selector_screen, "mark_story_completed"))
	reader.set("initial_story", story_data)
	reading_screen = reader
	add_child(reader)

func _return_to_selector() -> void:
	if reading_screen != null and is_instance_valid(reading_screen):
		reading_screen.queue_free()
	reading_screen = null
	if cuentos_selector_screen != null and is_instance_valid(cuentos_selector_screen):
		cuentos_selector_screen.show()

func _return_to_cuentos() -> void:
	if cuentos_selector_screen != null and is_instance_valid(cuentos_selector_screen):
		cuentos_selector_screen.queue_free()
	cuentos_selector_screen = null
	if cuentos_menu_screen != null and is_instance_valid(cuentos_menu_screen):
		cuentos_menu_screen.show()

func _show_module_placeholder(module_name: String, description: String) -> void:
	menu_overlay.visible = false
	artwork.visible = false
	girl_avatar.visible = false
	boy_avatar.visible = false
	root_box.visible = true
	_clear_content()
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var heading := Label.new()
	heading.text = module_name
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 38)
	heading.add_theme_color_override("font_color", Color("#073e73"))
	content.add_child(heading)

	var info := Label.new()
	info.text = description + "\n\n¡Pronto comenzará esta aventura!"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 23)
	info.add_theme_color_override("font_color", Color("#17334d"))
	content.add_child(info)

	var back := Button.new()
	back.text = "Volver al menú"
	back.custom_minimum_size = Vector2(280, 64)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.add_theme_font_size_override("font_size", 22)
	back.add_theme_stylebox_override("normal", _card_style(Color("#0875bd")))
	back.add_theme_color_override("font_color", Color.WHITE)
	back.pressed.connect(_show_home)
	content.add_child(back)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(bottom_spacer)

func _open_language_game() -> void:
	menu_overlay.visible = false
	artwork.visible = true
	girl_avatar.visible = false
	boy_avatar.visible = false
	root_box.visible = false
	var lesson := Control.new()
	lesson.set_script(load("res://scripts/language/language_lesson.gd"))
	lesson.connect("back_requested", Callable(self, "_show_home"))
	language_screen = lesson
	add_child(lesson)

func _start_exit_dialogue() -> void:
	DisplayServer.tts_stop()
	greeting_audio.stop()
	boy_intro_audio.stop()
	exit_audio.stop()
	_set_girl_mouth(false)
	_set_boy_mouth(false)
	speech_flow = "exit"
	menu_overlay.visible = true
	artwork.visible = true
	girl_avatar.visible = true
	boy_avatar.visible = true
	root_box.visible = false
	for child in menu_overlay.get_children():
		if child is Button:
			child.disabled = true
	dialogue_box.visible = true
	dialogue_label.text = BOY_BYE
	exit_gif_frame_clock = 0.0
	exit_gif_frame_index = 0
	_show_exit_gif_frame(0)
	if exit_audio.stream != null and exit_audio.stream.get_length() > 0.0:
		exit_gif_frame_interval = exit_audio.stream.get_length() / exit_gif_frames.size()
	if exit_audio.stream == null:
		_show_exit_without_voice()
		return
	exit_audio.play()

func _on_exit_audio_finished() -> void:
	get_tree().quit()

func _show_exit_without_voice() -> void:
	dialogue_label.text = BOY_BYE
	await get_tree().create_timer(2.5).timeout
	dialogue_label.text = GIRL_BYE
	await get_tree().create_timer(2.5).timeout
	get_tree().quit()

func _clear_content() -> void:
	for child in content.get_children():
		child.queue_free()

func _card_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color("#ffffff")
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
