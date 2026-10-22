extends Control

const MODULES := [
	{"name": "Lenguaje", "detail": "Letras y palabras", "icon": "ABC", "color": Color("#f5bd27")},
	{"name": "Matemática", "detail": "Las 4 operaciones", "icon": "+ − × ÷", "color": Color("#279de0")},
	{"name": "Números", "detail": "De 1 a 4 cifras", "icon": "1 2 3", "color": Color("#50b947")},
	{"name": "Geometría", "detail": "Figuras y lados", "icon": "△ □ ○", "color": Color("#7954d6")},
	{"name": "Cuentos", "detail": "Escucha y juega", "icon": "CUENTO", "color": Color("#ed8430")},
	{"name": "Diccionario", "detail": "Palabras y significados", "icon": "A–Z", "color": Color("#10aebb")},
	{"name": "Enciclopedia", "detail": "Ciencia e historia", "icon": "SABER", "color": Color("#df3d67")},
]

const WORDS := [
	{"word": "ABEJA", "hint": "Insecto que visita las flores y produce miel."},
	{"word": "BURRO", "hint": "Animal de campo con largas orejas."},
	{"word": "CASA", "hint": "Lugar donde vivimos y descansamos."},
	{"word": "DADO", "hint": "Cubo con puntos que usamos en algunos juegos."},
	{"word": "ESTRELLA", "hint": "Brilla en el cielo durante la noche."},
	{"word": "FLOR", "hint": "Crece en las plantas y puede tener muchos colores."},
	{"word": "GATO", "hint": "Animal doméstico que maúlla."},
	{"word": "HOJA", "hint": "Parte verde de una planta."},
	{"word": "IGLESIA", "hint": "Edificio del pueblo donde se reúnen algunas comunidades."},
	{"word": "JIRAFA", "hint": "Animal alto con cuello muy largo."},
	{"word": "KIWI", "hint": "Fruta pequeña de pulpa verde y sabor ácido."},
	{"word": "LUNA", "hint": "Acompaña a la Tierra y la vemos de noche."},
	{"word": "MONTAÑA", "hint": "Gran elevación natural del terreno."},
	{"word": "NUBE", "hint": "Está en el cielo y puede traer lluvia."},
	{"word": "OVEJA", "hint": "Animal que nos da lana."},
	{"word": "PERRO", "hint": "Animal que suele ladrar y acompañar a las familias."},
	{"word": "QUESO", "hint": "Alimento que se prepara con leche."},
	{"word": "RANA", "hint": "Animal verde que salta y vive cerca del agua."},
	{"word": "SOL", "hint": "Estrella que ilumina y calienta nuestro planeta."},
	{"word": "TREN", "hint": "Vehículo largo que avanza sobre rieles."},
	{"word": "UVA", "hint": "Fruta pequeña que crece en racimos."},
	{"word": "VACA", "hint": "Animal de granja que nos da leche."},
	{"word": "WIFI", "hint": "Conexión inalámbrica a internet; esta actividad no la necesita."},
	{"word": "XILÓFONO", "hint": "Instrumento musical que se toca golpeando sus láminas."},
	{"word": "YACU", "hint": "Palabra que significa agua en quechua."},
	{"word": "ZORRO", "hint": "Animal silvestre de hocico fino y cola larga."},
]

const BYE_BOY_ID := 201
const BYE_GIRL_ID := 202
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
var current_word: String = ""
var chosen_letters: String = ""
var girl_voice_id: String = ""
var boy_voice_id: String = ""
var speech_flow: String = ""
var mouth_clock: float = 0.0
var boy_mouth_clock: float = 0.0
var girl_mouth_open: bool = false
var boy_mouth_open: bool = false
var girl_tts_speaking: bool = false
var boy_tts_speaking: bool = false
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

func _ready() -> void:
	_build_shell()
	_select_voices()
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, Callable(self, "_on_tts_started"))
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, Callable(self, "_on_tts_ended"))
	greeting_audio = AudioStreamPlayer.new()
	greeting_audio.stream = load("res://assets/bienvenida-nina.mp3")
	greeting_audio.finished.connect(_on_girl_greeting_finished)
	add_child(greeting_audio)
	boy_intro_audio = AudioStreamPlayer.new()
	boy_intro_audio.stream = load("res://assets/audio-nino.mp3")
	boy_intro_audio.finished.connect(_on_boy_intro_finished)
	add_child(boy_intro_audio)
	exit_audio = AudioStreamPlayer.new()
	exit_audio.stream = load("res://assets/audio-despedida.mp3")
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
	elif girl_tts_speaking:
		mouth_clock += delta
		if mouth_clock >= 0.16:
			mouth_clock = 0.0
			_set_girl_mouth(not girl_mouth_open)
	elif girl_mouth_open:
		_set_girl_mouth(false)
	if boy_intro_audio != null and boy_intro_audio.playing and not boy_gif_frames.is_empty():
		boy_gif_frame_clock += delta
		if boy_gif_frame_clock >= boy_gif_frame_interval:
			boy_gif_frame_clock = 0.0
			boy_gif_frame_index = (boy_gif_frame_index + 1) % boy_gif_frames.size()
			_show_boy_gif_frame(boy_gif_frame_index)
	elif boy_tts_speaking:
		boy_mouth_clock += delta
		if boy_mouth_clock >= 0.16:
			boy_mouth_clock = 0.0
			_set_boy_mouth(not boy_mouth_open)
	elif boy_mouth_open:
		_set_boy_mouth(false)

func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = Color("#cceeff")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	artwork = TextureRect.new()
	artwork.texture = load("res://assets/fondo-andes.png")
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(artwork)

	for frame_number in range(1, 7):
		girl_talking_frames.append(load("res://assets/nina-habla-%02d.png" % frame_number))
	for frame_number in range(100):
		girl_gif_frames.append(load("res://assets/nina-gif/frame_%03d.png" % frame_number))
	for frame_number in range(107):
		boy_gif_frames.append(load("res://assets/nino-gif/frame_%03d.png" % frame_number))
	for frame_number in range(78):
		exit_gif_frames.append(load("res://assets/nina-despedida-gif/frame_%03d.png" % frame_number))
	girl_avatar = _make_avatar("res://assets/nina-habla-01.png", true)
	boy_avatar = _make_avatar("res://assets/nino-cerrada.png", false)
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
	_add_menu_card("Lenguaje", "res://assets/icons/01_lenguaje.png", 0.17, 0.33, 0.115, 0.13)
	_add_menu_card("Matemática", "res://assets/icons/02_matematica.png", 0.31, 0.33, 0.115, 0.13)
	_add_menu_card("Números", "res://assets/icons/03_numeros.png", 0.45, 0.33, 0.115, 0.13)
	_add_menu_card("Geometría", "res://assets/icons/04_geometria.png", 0.59, 0.33, 0.115, 0.13)
	_add_menu_card("Cuentos", "res://assets/icons/05_cuentos.png", 0.73, 0.33, 0.115, 0.13)
	_add_menu_card("Diccionario", "res://assets/icons/06_diccionario.png", 0.2125, 0.48, 0.125, 0.1375)
	_add_menu_card("Enciclopedia", "res://assets/icons/07_enciclopedia.png", 0.3625, 0.48, 0.125, 0.1375)
	_add_menu_card("Configuración", "res://assets/icons/08_configuracion.png", 0.5125, 0.48, 0.125, 0.1375)
	_add_menu_card("Salir", "res://assets/icons/09_salir.png", 0.6625, 0.48, 0.125, 0.1375)

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

func _select_voices() -> void:
	var spanish: Array = []
	for voice in DisplayServer.tts_get_voices():
		if String(voice.get("language", "")).to_lower().begins_with("es"):
			spanish.append(voice)
	if spanish.is_empty():
		for voice_id in DisplayServer.tts_get_voices_for_language("es"):
			spanish.append({"id": voice_id, "name": voice_id})
	if spanish.is_empty():
		return
	girl_voice_id = String(spanish[0].get("id", ""))
	boy_voice_id = girl_voice_id
	for voice in spanish:
		var name := String(voice.get("name", "")).to_lower()
		if _name_contains(name, ["sabina", "helena", "laura", "lucia", "lucía", "elena", "monica", "mónica", "paulina", "female", "mujer"]):
			girl_voice_id = String(voice.get("id", girl_voice_id))
		if _name_contains(name, ["raul", "raúl", "pablo", "jorge", "alvaro", "álvaro", "david", "hector", "héctor", "male", "hombre"]):
			boy_voice_id = String(voice.get("id", boy_voice_id))

func _name_contains(name: String, terms: Array) -> bool:
	for term in terms:
		if name.contains(String(term)):
			return true
	return false

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
	boy_avatar.texture = load("res://assets/nino-cerrada.png")
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
	boy_avatar.texture = load("res://assets/nino-abierta.png") if open else load("res://assets/nino-cerrada.png")

func _on_tts_started(utterance_id: int) -> void:
	if utterance_id == BYE_GIRL_ID:
		girl_tts_speaking = true
		dialogue_label.text = GIRL_BYE
	elif utterance_id == BYE_BOY_ID:
		boy_tts_speaking = true
		dialogue_label.text = BOY_BYE

func _on_tts_ended(utterance_id: int) -> void:
	if utterance_id == BYE_BOY_ID:
		boy_tts_speaking = false
		_set_boy_mouth(false)
		DisplayServer.tts_speak(GIRL_BYE, girl_voice_id, 85, 1.12, 0.94, BYE_GIRL_ID, true)
	elif utterance_id == BYE_GIRL_ID:
		girl_tts_speaking = false
		_set_girl_mouth(false)
		get_tree().quit()

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
	if language_screen != null and is_instance_valid(language_screen):
		language_screen.queue_free()
	language_screen = null
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
		girl_tts_speaking = false
		boy_tts_speaking = false
		_set_girl_mouth(false)
		_set_boy_mouth(false)
	var details := "Sonido, idioma y accesibilidad"
	for item in MODULES:
		if item.name == module_name:
			details = item.detail
	_open_module(module_name, details)

func _open_module(module_name: String, description: String) -> void:
	if module_name == "Lenguaje":
		_open_language_game()
		return
	_show_module_placeholder(module_name, description)

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
	lesson.set_script(load("res://scripts/language_lesson.gd"))
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
	girl_tts_speaking = false
	boy_tts_speaking = false
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

func _choose_letter(letter: String, tile: Button) -> void:
	chosen_letters += letter
	var answer: Label = content.find_child("Answer", true, false)
	answer.text = "  ".join(chosen_letters.split("", false)) + "  ".repeat(current_word.length() - chosen_letters.length())
	tile.disabled = true
	var feedback: Label = content.find_child("Feedback", true, false)
	feedback.text = "¡Bien! Sigue formando la palabra." if chosen_letters.length() < current_word.length() else "Ya puedes comprobar tu respuesta."

func _reset_word() -> void:
	chosen_letters = ""
	var answer: Label = content.find_child("Answer", true, false)
	answer.text = "  ".repeat(current_word.length())
	var feedback: Label = content.find_child("Feedback", true, false)
	feedback.text = "Toca las letras en el orden correcto."
	feedback.add_theme_color_override("font_color", Color("#17334d"))
	var letter_row: HBoxContainer = content.get_child(3)
	for tile in letter_row.get_children():
		tile.disabled = false

func _check_word() -> void:
	var feedback: Label = content.find_child("Feedback", true, false)
	if chosen_letters == current_word:
		feedback.text = "¡Excelente! ¡Palabra correcta!"
		feedback.add_theme_color_override("font_color", Color("#18773a"))
	else:
		feedback.text = "Todavía no. Prueba de nuevo o toca Borrar."
		feedback.add_theme_color_override("font_color", Color("#a33b28"))

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
