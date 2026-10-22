extends Control

signal back_requested

const LETTERS := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "Ñ", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
const TOTAL_WORDS := 270
const PROGRESS_FILE := "user://progreso_lenguaje.cfg"
const CONDOR_FRAME_COUNT := 119
const CONDOR_FRAME_INTERVAL := 0.04
const CONDOR_INTRO_SEGMENTS := [
	"¡Bienvenido a este curso de lenguaje! Mi nombre es Conde, el cóndor, y yo seré tu guía.",
	"En este curso aprenderás el abecedario y a reconocer las palabras de cada letra. Pulsa Escuchar para oírlas.",
	"La barra de Mi Progreso se llenará conforme vayas escuchando todas las palabras del abecedario.",
	"Además, tienes juegos y actividades para que aprendas.",
	"En Traza la letra aprenderás a escribir.",
	"En Escucha y aprende escucharás las palabras y las repetirás usando el micrófono. Enciéndelo para participar.",
	"En Une con la imagen relacionarás las imágenes con las palabras que les corresponden.",
	"En Encuentra la letra buscarás la letra adecuada entre muchas letras desordenadas.",
	"Por último, Juegos por niveles ofrece juegos divertidos para seguir aprendiendo. ¡Así que puedes comenzar!"
]
const ACTIVITIES := [
	["✍️", "Traza la letra", "Practica su escritura", "#43b64b"],
	["🔊", "Escucha y repite", "Oye el sonido", "#168bd2"],
	["🍎", "Une con la imagen", "Relaciona palabra y dibujo", "#8053d5"],
	["🔎", "Encuentra la letra", "Busca entre palabras", "#ef8428"],
	["🎮", "Juegos por niveles", "Pon a prueba lo aprendido", "#df3970"]
]

var selected_letter: String = "A"
var selected_example: int = 0
var spanish_voice: String = ""
var examples_data: Dictionary = {}
var completed_examples: Dictionary = {}
var letter_label: Label
var word_label: Label
var picture_label: Label
var picture_texture: TextureRect
var condor_avatar: TextureRect
var condor_audio: AudioStreamPlayer
var condor_frames: Array[Texture2D] = []
var condor_frame_index: int = 0
var condor_frame_clock: float = 0.0
var progress_label: Label
var completed_letters_label: Label
var letter_progress_label: Label
var progress_fill: Panel
var progress_tween: Tween
var word_star_labels: Array[Label] = []
var guide_message: Label
var trace_exercise: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	examples_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/abecedario.json")) as Dictionary
	_load_word_progress()
	_find_spanish_voice()
	_build_screen()
	_show_letter("A")
	_start_condor_intro()

func _process(delta: float) -> void:
	if condor_audio == null or not condor_audio.playing or condor_frames.is_empty():
		return
	condor_frame_clock += delta
	while condor_frame_clock >= CONDOR_FRAME_INTERVAL:
		condor_frame_clock -= CONDOR_FRAME_INTERVAL
		condor_frame_index = (condor_frame_index + 1) % condor_frames.size()
		condor_avatar.texture = condor_frames[condor_frame_index]
	_update_condor_caption()

func _find_spanish_voice() -> void:
	for voice in DisplayServer.tts_get_voices():
		if String(voice.get("language", "")).to_lower().begins_with("es"):
			spanish_voice = String(voice.get("id", ""))
			return

func _build_screen() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/fondo-paisaje-andino.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# Marca y encabezado superior.
	var brand := _label("Aprende\nsin Límites", 32, Color.WHITE)
	_place(brand, 0.018, 0.012, 0.24, 0.17)
	brand.add_theme_color_override("font_shadow_color", Color("#063c79"))
	brand.add_theme_constant_override("shadow_offset_x", 3)
	brand.add_theme_constant_override("shadow_offset_y", 3)
	brand.add_theme_font_size_override("font_size", 34)

	var banner := TextureRect.new()
	banner.texture = load("res://assets/logo-lenguaje.png")
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(banner, 0.285, 0.022, 0.48, 0.18)
	add_child(banner)

	var settings := _image_button("res://assets/boton-configuracion.png", "Configuración")
	_place(settings, 0.79, 0.035, 0.095, 0.12)
	settings.pressed.connect(_show_settings)
	add_child(settings)
	var help := _image_button("res://assets/boton-ayuda.png", "Ayuda")
	_place(help, 0.895, 0.035, 0.09, 0.12)
	help.pressed.connect(_show_help)
	add_child(help)

	# Conde queda a la izquierda del tablero, con fondo transparente.
	for frame_number in range(CONDOR_FRAME_COUNT):
		condor_frames.append(load("res://assets/condor-frames/frame_%03d.png" % frame_number))
	condor_avatar = TextureRect.new()
	condor_avatar.texture = condor_frames[0]
	condor_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	condor_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	condor_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(condor_avatar, -0.015, 0.37, 0.255, 0.40)
	add_child(condor_avatar)

	# Burbuja para subtítulos breves sincronizados con la narración.
	var instruction := _panel(Color("#fffdf4"), Color("#f6c532"), 3, 22)
	_place(instruction, 0.012, 0.225, 0.145, 0.19)
	add_child(instruction)
	guide_message = _label("¡Hola! Soy Conde, tu guía.", 14, Color("#073b78"))
	guide_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	guide_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(guide_message, 0.04, 0.03, 0.92, 0.70)
	instruction.add_child(guide_message)
	var repeat_guide := _button("¿Volver a repetir la guía?", Color("#168bd2"), 12)
	repeat_guide.tooltip_text = "Reproducir otra vez las instrucciones de Conde"
	_place(repeat_guide, 0.035, 0.77, 0.93, 0.19)
	repeat_guide.pressed.connect(_start_condor_intro)
	instruction.add_child(repeat_guide)
	condor_audio = AudioStreamPlayer.new()
	condor_audio.stream = load("res://assets/audio-condor-bienvenida.mp3")
	condor_audio.finished.connect(_on_condor_intro_finished)
	add_child(condor_audio)

	# Tarjeta central: letra, palabra, ilustración y controles para recorrer los 10 ejemplos.
	var hero := _panel(Color("#fffdf4"), Color("#f6bd24"), 5, 32)
	_place(hero, 0.205, 0.235, 0.525, 0.305)
	add_child(hero)
	var letter_big := _label("A", 126, Color("#ed2631"))
	letter_big.name = "BigLetter"
	letter_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_big.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(letter_big, 0.025, 0.05, 0.29, 0.88)
	hero.add_child(letter_big)
	var middle := VBoxContainer.new()
	_place(middle, 0.335, 0.12, 0.30, 0.76)
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", 5)
	hero.add_child(middle)
	letter_label = _label("A de Árbol", 32, Color("#0b417e"))
	letter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	middle.add_child(letter_label)
	var listen := _button("🔊  Escuchar", Color("#ffc928"), 21)
	listen.custom_minimum_size = Vector2(145, 52)
	listen.add_theme_color_override("font_color", Color("#153b66"))
	listen.pressed.connect(_speak_current_word)
	middle.add_child(listen)
	var picture := _panel(Color("#d9f2ff"), Color("#88d0ed"), 2, 22)
	_place(picture, 0.655, 0.06, 0.30, 0.86)
	hero.add_child(picture)
	picture_label = _label("🌳", 77, Color("#073b78"))
	picture_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	picture_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(picture_label, 0.0, 0.02, 1.0, 0.77)
	picture.add_child(picture_label)
	picture_texture = TextureRect.new()
	picture_texture.texture = load("res://assets/icono-quince.svg")
	picture_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture_texture.visible = false
	_place(picture_texture, 0.16, 0.04, 0.68, 0.70)
	picture.add_child(picture_texture)
	word_label = _label("Árbol", 26, Color("#e62531"))
	word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(word_label, 0.0, 0.76, 1.0, 0.22)
	picture.add_child(word_label)

	var previous := _image_button("res://assets/flecha-izquierda.png", "Ejemplo anterior")
	_place(previous, 0.168, 0.34, 0.055, 0.095)
	previous.pressed.connect(_step_example.bind(-1))
	add_child(previous)
	var next := _image_button("res://assets/flecha-derecha.png", "Siguiente ejemplo")
	_place(next, 0.722, 0.34, 0.055, 0.095)
	next.pressed.connect(_step_example.bind(1))
	add_child(next)

	# Progreso por palabras: barra total y diez estrellas para la letra elegida.
	var progress := _panel(Color("#eef7ff"), Color("#168bd2"), 3, 26)
	_place(progress, 0.775, 0.225, 0.215, 0.315)
	add_child(progress)
	var progress_star := TextureRect.new()
	progress_star.texture = load("res://assets/estrella-progreso.png")
	progress_star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	progress_star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	progress_star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(progress_star, 0.12, 0.035, 0.16, 0.15)
	progress.add_child(progress_star)
	var progress_title := _label("Mi Progreso", 22, Color("#07447f"))
	progress_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_place(progress_title, 0.30, 0.035, 0.62, 0.14)
	progress.add_child(progress_title)
	progress_label = _label("0 / 270 palabras", 16, Color("#123b62"))
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(progress_label, 0.04, 0.18, 0.92, 0.10)
	progress.add_child(progress_label)
	var progress_track := TextureRect.new()
	progress_track.texture = load("res://assets/barra-progreso-marco.png")
	progress_track.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	progress_track.stretch_mode = TextureRect.STRETCH_SCALE
	progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(progress_track, 0.055, 0.30, 0.89, 0.13)
	progress.add_child(progress_track)
	progress_fill = _panel(Color("#39ff14"), Color("#c9ff8a"), 1, 12)
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_style := progress_fill.get_theme_stylebox("panel") as StyleBoxFlat
	fill_style.shadow_color = Color(0.18, 1.0, 0.0, 0.85)
	fill_style.shadow_size = 9
	fill_style.shadow_offset = Vector2.ZERO
	_place(progress_fill, 0.10, 0.34, 0.001, 0.05)
	progress.add_child(progress_fill)
	completed_letters_label = _label("Letras completas: 0 / 27", 13, Color("#123b62"))
	completed_letters_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(completed_letters_label, 0.04, 0.46, 0.92, 0.09)
	progress.add_child(completed_letters_label)
	letter_progress_label = _label("Letra A: 0 / 10 palabras", 14, Color("#123b62"))
	letter_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(letter_progress_label, 0.04, 0.55, 0.92, 0.09)
	progress.add_child(letter_progress_label)
	var star_grid := GridContainer.new()
	star_grid.columns = 5
	star_grid.add_theme_constant_override("h_separation", 2)
	star_grid.add_theme_constant_override("v_separation", 0)
	_place(star_grid, 0.10, 0.65, 0.80, 0.30)
	progress.add_child(star_grid)
	for word_index in range(10):
		var star := _label("☆", 20, Color("#8a9daf"))
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		star.size_flags_vertical = Control.SIZE_EXPAND_FILL
		star.tooltip_text = "Palabra %d de la letra" % (word_index + 1)
		word_star_labels.append(star)
		star_grid.add_child(star)

	# Tira ilustrada del alfabeto español con una zona clicable por cada letra.
	var alphabet_area := Control.new()
	_place(alphabet_area, 0.10, 0.56, 0.88, 0.18)
	add_child(alphabet_area)
	var alphabet_image := TextureRect.new()
	alphabet_image.texture = load("res://assets/tira-abecedario.png")
	alphabet_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	alphabet_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	alphabet_image.stretch_mode = TextureRect.STRETCH_SCALE
	alphabet_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alphabet_area.add_child(alphabet_image)
	var alphabet_rows := VBoxContainer.new()
	_place(alphabet_rows, 0.018, 0.064, 0.964, 0.84)
	alphabet_rows.add_theme_constant_override("separation", 8)
	alphabet_area.add_child(alphabet_rows)
	_add_alphabet_hit_row(alphabet_rows, LETTERS.slice(0, 13))
	_add_alphabet_hit_row(alphabet_rows, LETTERS.slice(13, LETTERS.size()))

	# Cinta ilustrada para identificar la zona de actividades.
	var activity_title := TextureRect.new()
	activity_title.texture = load("res://assets/titulo-juegos-actividades.png")
	activity_title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	activity_title.stretch_mode = TextureRect.STRETCH_SCALE
	activity_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(activity_title, 0.205, 0.728, 0.35, 0.055)
	add_child(activity_title)
	var activity_row := HBoxContainer.new()
	_place(activity_row, 0.205, 0.785, 0.78, 0.185)
	activity_row.add_theme_constant_override("separation", 9)
	add_child(activity_row)
	var activity_images := [
		"res://assets/actividad-trazar.png",
		"res://assets/actividad-escuchar.png",
		"res://assets/actividad-unir.png",
		"res://assets/actividad-encontrar.png",
		"res://assets/actividad-niveles.png"
	]
	for i in range(ACTIVITIES.size()):
		var activity: Array = ACTIVITIES[i]
		var tile := TextureButton.new()
		tile.texture_normal = load(activity_images[i])
		tile.texture_hover = load(activity_images[i])
		tile.texture_pressed = load(activity_images[i])
		tile.ignore_texture_size = true
		tile.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tile.custom_minimum_size = Vector2(110, 96)
		# El nombre ya forma parte de la ilustración; no mostrar un tooltip encima.
		tile.pressed.connect(_show_activity.bind(String(activity[1])))
		activity_row.add_child(tile)

	var back := TextureButton.new()
	back.texture_normal = load("res://assets/volver-menu.png")
	back.texture_hover = load("res://assets/volver-menu.png")
	back.texture_pressed = load("res://assets/volver-menu.png")
	back.ignore_texture_size = true
	back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back.tooltip_text = "Volver al menú principal"
	_place(back, 0.012, 0.825, 0.17, 0.145)
	back.pressed.connect(_go_back)
	add_child(back)

func _add_alphabet_hit_row(parent: VBoxContainer, row_letters: Array) -> void:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 0)
	parent.add_child(row)
	for letter in row_letters:
		var key := Button.new()
		key.text = ""
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key.size_flags_vertical = Control.SIZE_EXPAND_FILL
		key.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0), Color(1, 1, 1, 0), 0, 8))
		key.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.35), 2, 8))
		key.add_theme_stylebox_override("pressed", _style(Color(1, 1, 1, 0.3), Color.WHITE, 2, 8))
		key.add_theme_stylebox_override("focus", _style(Color(1, 1, 1, 0), Color(1, 1, 1, 0), 0, 8))
		key.tooltip_text = "Letra %s" % letter
		key.pressed.connect(_show_letter.bind(letter))
		row.add_child(key)

func _show_letter(letter: String) -> void:
	_stop_condor_intro()
	DisplayServer.tts_stop()
	selected_letter = letter
	selected_example = 0
	_render_example()

func _render_example() -> void:
	var examples: Array = examples_data.get(selected_letter, [])
	if examples.is_empty():
		return
	selected_example = posmod(selected_example, examples.size())
	_mark_example_completed(selected_letter, selected_example)
	var parts := String(examples[selected_example]).split("|", false, 1)
	var word := String(parts[0])
	var picture := String(parts[1]) if parts.size() > 1 else "⭐"
	var big_letter: Label = find_child("BigLetter", true, false)
	big_letter.text = selected_letter
	letter_label.text = "%s de %s" % [selected_letter, word] if word.to_upper().begins_with(selected_letter) else "%s en %s" % [selected_letter, word]
	word_label.text = word
	var show_quince_icon := selected_letter == "Q" and word == "Quince"
	picture_texture.visible = show_quince_icon
	picture_label.visible = not show_quince_icon
	picture_label.text = "" if show_quince_icon else picture
	_update_progress_display()
	guide_message.text = "¡Muy bien!\n%s de %s" % [selected_letter, word]

func _load_word_progress() -> void:
	var config := ConfigFile.new()
	if config.load(PROGRESS_FILE) == OK:
		var saved: Variant = config.get_value("progreso", "ejemplos", {})
		if saved is Dictionary:
			completed_examples = saved
	for letter in LETTERS:
		var stored: Variant = completed_examples.get(letter, [])
		var visited: Array = stored.duplicate() if stored is Array else []
		var expected: Array = examples_data.get(letter, [])
		while visited.size() < expected.size():
			visited.append(false)
		if visited.size() > expected.size():
			visited.resize(expected.size())
		completed_examples[letter] = visited

func _mark_example_completed(letter: String, example_index: int) -> void:
	var visited: Array = completed_examples.get(letter, [])
	if example_index < 0 or example_index >= visited.size() or bool(visited[example_index]):
		return
	visited[example_index] = true
	completed_examples[letter] = visited
	var config := ConfigFile.new()
	config.set_value("progreso", "ejemplos", completed_examples)
	config.save(PROGRESS_FILE)

func _update_progress_display() -> void:
	var total_completed := 0
	var letters_completed := 0
	for letter in LETTERS:
		var visited: Array = completed_examples.get(letter, [])
		var letter_count := 0
		for is_completed in visited:
			if bool(is_completed):
				letter_count += 1
		total_completed += letter_count
		if not visited.is_empty() and letter_count == visited.size():
			letters_completed += 1
	var selected_visited: Array = completed_examples.get(selected_letter, [])
	var selected_count := 0
	for is_completed in selected_visited:
		if bool(is_completed):
			selected_count += 1
	progress_label.text = "%d / %d palabras" % [total_completed, TOTAL_WORDS]
	completed_letters_label.text = "Letras completas: %d / %d" % [letters_completed, LETTERS.size()]
	letter_progress_label.text = "Letra %s: %d / %d palabras" % [selected_letter, selected_count, selected_visited.size()]
	for index in range(word_star_labels.size()):
		var completed := index < selected_visited.size() and bool(selected_visited[index])
		word_star_labels[index].text = "★" if completed else "☆"
		word_star_labels[index].add_theme_color_override("font_color", Color("#ffc928") if completed else Color("#8a9daf"))
	var fill_start := 0.10
	var fill_width := 0.80
	var ratio := clampf(float(total_completed) / float(TOTAL_WORDS), 0.0, 1.0)
	progress_fill.anchor_left = fill_start
	var target_right := fill_start + fill_width * ratio
	if progress_tween != null and progress_tween.is_running():
		progress_tween.kill()
	progress_tween = create_tween()
	progress_tween.tween_property(progress_fill, "anchor_right", target_right, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _step_example(direction: int) -> void:
	_stop_condor_intro()
	selected_example += direction
	DisplayServer.tts_stop()
	_render_example()

func _speak_current_word() -> void:
	_stop_condor_intro()
	var examples: Array = examples_data.get(selected_letter, [])
	if examples.is_empty():
		return
	var word := String(examples[selected_example]).split("|", false, 1)[0]
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(word, spanish_voice, 100.0, 1.0, 0.92, 0, true)
	guide_message.text = "¡Escucha!\n%s" % word

func _show_help() -> void:
	_stop_condor_intro()
	guide_message.text = "Usa las letras y flechas para explorar. Pulsa Escuchar para oír cada palabra."

func _show_settings() -> void:
	_stop_condor_intro()
	guide_message.text = "El sonido usa la voz en español instalada en Windows."

func _show_activity(activity_name: String) -> void:
	_stop_condor_intro()
	if activity_name == "Traza la letra":
		_open_trace_exercise()
		return
	guide_message.text = "%s estará disponible en la siguiente etapa." % activity_name

func _open_trace_exercise() -> void:
	if trace_exercise != null and is_instance_valid(trace_exercise):
		return
	DisplayServer.tts_stop()
	var trace_script: Script = load("res://scripts/trace_exercise.gd") as Script
	if trace_script == null:
		guide_message.text = "No se pudo abrir Traza la letra. Inténtalo de nuevo."
		return
	trace_exercise = Control.new()
	trace_exercise.set_script(trace_script)
	trace_exercise.connect("close_requested", Callable(self, "_close_trace_exercise"))
	add_child(trace_exercise)

func _close_trace_exercise() -> void:
	if trace_exercise != null and is_instance_valid(trace_exercise):
		trace_exercise.queue_free()
	trace_exercise = null
	visible = true
	_go_back()

func _go_back() -> void:
	_stop_condor_intro()
	DisplayServer.tts_stop()
	back_requested.emit()

func _start_condor_intro() -> void:
	if condor_audio == null or condor_audio.stream == null:
		return
	condor_audio.stop()
	condor_frame_index = 0
	condor_frame_clock = 0.0
	condor_avatar.texture = condor_frames[0]
	guide_message.text = CONDOR_INTRO_SEGMENTS[0]
	condor_audio.play()

func _update_condor_caption() -> void:
	var duration := condor_audio.stream.get_length()
	if duration <= 0.0:
		return
	var fraction := clampf(condor_audio.get_playback_position() / duration, 0.0, 0.999)
	var total_weight := 0
	for segment in CONDOR_INTRO_SEGMENTS:
		total_weight += String(segment).length()
	var target_weight := int(fraction * total_weight)
	var accumulated := 0
	for segment_index in range(CONDOR_INTRO_SEGMENTS.size()):
		accumulated += String(CONDOR_INTRO_SEGMENTS[segment_index]).length()
		if target_weight < accumulated:
			guide_message.text = CONDOR_INTRO_SEGMENTS[segment_index]
			return

func _on_condor_intro_finished() -> void:
	if not condor_frames.is_empty():
		condor_avatar.texture = condor_frames[0]
	guide_message.text = "¡Empecemos! Elige una letra."

func _stop_condor_intro() -> void:
	if condor_audio != null and condor_audio.playing:
		condor_audio.stop()
	if condor_avatar != null and not condor_frames.is_empty():
		condor_avatar.texture = condor_frames[0]

func _image_button(texture_path: String, description: String) -> TextureButton:
	var result := TextureButton.new()
	var image: Texture2D = load(texture_path)
	result.texture_normal = image
	result.texture_hover = image
	result.texture_pressed = image
	result.ignore_texture_size = true
	result.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	result.tooltip_text = description
	return result

func _button(text: String, color: Color, font_size: int) -> Button:
	var result := Button.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color.WHITE)
	result.add_theme_color_override("font_hover_color", Color.WHITE)
	result.add_theme_color_override("font_pressed_color", Color.WHITE)
	result.add_theme_stylebox_override("normal", _style(color, Color.WHITE, 2, 15))
	result.add_theme_stylebox_override("hover", _style(color.lightened(0.12), Color("#ffe17a"), 3, 15))
	result.add_theme_stylebox_override("pressed", _style(color.darkened(0.12), Color.WHITE, 2, 15))
	result.add_theme_stylebox_override("focus", _style(color, Color("#ffe17a"), 3, 15))
	return result

func _panel(fill: Color, border: Color, border_width: int, radius: int) -> Panel:
	var result := Panel.new()
	result.add_theme_stylebox_override("panel", _style(fill, border, border_width, radius))
	return result

func _label(text: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result

func _place(control: Control, x: float, y: float, width: float, height: float) -> void:
	control.anchor_left = x
	control.anchor_top = y
	control.anchor_right = x + width
	control.anchor_bottom = y + height
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0

func _style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(border_width)
	result.set_corner_radius_all(radius)
	result.content_margin_left = 8
	result.content_margin_right = 8
	result.content_margin_top = 6
	result.content_margin_bottom = 6
	return result

func _letter_color(letter: String) -> Color:
	var colors := ["#e73536", "#168bd2", "#f5bd27", "#45b84b", "#8053d5", "#ed8428", "#ec3d75", "#10aebb"]
	return Color(colors[LETTERS.find(letter) % colors.size()])

