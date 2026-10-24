extends Control

signal close_requested

const Alphabet = preload("res://scripts/language/alphabet.gd")
const LETTERS = Alphabet.LETTERS
const LetterStrokes = preload("res://scripts/language/tracing/letter_strokes.gd")
const ProgressStore = preload("res://scripts/storage/progress_store.gd")
const EXERCISES_PER_LETTER := 10
const SAVE_PATH := "user://progreso_traza_letras.cfg"
const CONDOR_FRAME_COUNT := 119
const CONDOR_FRAME_INTERVAL := 0.06
const CONDOR_IDLE_FRAME := 80
const PRAISE_AUDIO_PATHS := [
	"res://assets/audio/audio-felicitacion-traza.mp3",
	"res://assets/audio/praise/p_23391271_965.mp3",
	"res://assets/audio/praise/p_23391426_98.mp3",
	"res://assets/audio/praise/MiniMax_2026-10-23_11_03_52_Captivating_Storyteller.mp3",
	"res://assets/audio/praise/MiniMax_2026-10-23_11_06_42_Captivating_Storyteller.mp3",
	"res://assets/audio/praise/MiniMax_2026-10-23_11_08_25_Captivating_Storyteller.mp3",
	"res://assets/audio/praise/p_23389894_865.mp3"
]

var current_letter_index := 0
var completed_by_letter: Dictionary = {}
var letter_image: TextureRect
var counter_label: Label
var counter_total_label: Label
var letter_caption: Label
var result_label: Label
var exercise_label: Label
var trace_canvas: Control
var start_button: Button
var erase_button: Button
var next_button: Button
var alphabet_buttons: Dictionary = {}
var condor_avatar: TextureRect
var condor_frames: Array[Texture2D] = []
var condor_frame_clock := 0.0
var condor_frame_index := 0
var praise_audio: AudioStreamPlayer
var praise_audio_streams: Array[AudioStream] = []
var praise_rng := RandomNumberGenerator.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	praise_rng.randomize()
	_load_progress()
	_build_screen()
	current_letter_index = _find_first_unfinished_letter()
	_show_current_letter()

func _process(delta: float) -> void:
	if condor_frames.is_empty() or condor_avatar == null:
		return
	var speaking := (praise_audio != null and praise_audio.playing) or Narration.current_clip.begins_with("letter_") or Narration.current_clip.begins_with("trace_")
	if not speaking:
		condor_frame_clock = 0.0
		if condor_frame_index != CONDOR_IDLE_FRAME:
			condor_frame_index = CONDOR_IDLE_FRAME
			condor_avatar.texture = condor_frames[condor_frame_index]
		return
	condor_frame_clock += delta
	while condor_frame_clock >= CONDOR_FRAME_INTERVAL:
		condor_frame_clock -= CONDOR_FRAME_INTERVAL
		condor_frame_index = (condor_frame_index + 1) % condor_frames.size()
		condor_avatar.texture = condor_frames[condor_frame_index]

func _build_screen() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/backgrounds/fondo-traza.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var letter_tile := _rounded_panel(Color("#f3223b"), Color.TRANSPARENT, 0, 22)
	_place(letter_tile, 0.219, 0.432, 0.181, 0.224)
	add_child(letter_tile)
	var trace_tile := _rounded_panel(Color("#fffefd"), Color("#8cd4f3"), 2, 22)
	_place(trace_tile, 0.432, 0.237, 0.297, 0.50)
	add_child(trace_tile)
	var result_letter_tile := _rounded_panel(Color.WHITE, Color.TRANSPARENT, 0, 18)
	_place(result_letter_tile, 0.697, 0.79, 0.13, 0.155)
	add_child(result_letter_tile)

	var board_art := TextureRect.new()
	board_art.texture = load("res://assets/ui/tracing/tablero-trazos.png")
	board_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board_art.stretch_mode = TextureRect.STRETCH_SCALE
	board_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board_art)

	for frame_number in range(CONDOR_FRAME_COUNT):
		condor_frames.append(load("res://assets/characters/condor/frames/frame_%03d.png" % frame_number))
	condor_avatar = TextureRect.new()
	condor_avatar.texture = condor_frames[CONDOR_IDLE_FRAME]
	condor_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	condor_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	condor_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(condor_avatar, -0.005, 0.34, 0.205, 0.47)
	add_child(condor_avatar)
	praise_audio = AudioStreamPlayer.new()
	for audio_path in PRAISE_AUDIO_PATHS:
		var audio_stream := load(audio_path) as AudioStream
		if audio_stream != null:
			praise_audio_streams.append(audio_stream)
	praise_audio.stream = load("res://assets/audio/audio-felicitacion-traza.mp3") as AudioStream
	praise_audio.finished.connect(_on_praise_audio_finished)
	add_child(praise_audio)

	# Controles transparentes sobre las ilustraciones ya incluidas en el tablero.
	var back_button := _invisible_button(Rect2(0.02, 0.025, 0.25, 0.13), "Volver al tablero de lenguaje")
	# The background image says "Menú Principal"; use a real control so its
	# label matches the parent screen and can be edited without repainting art.
	back_button.text = "← Volver a Lenguaje"
	back_button.add_theme_font_size_override("font_size", 23)
	for state in ["normal", "hover", "pressed", "focus"]:
		var back_style := StyleBoxFlat.new()
		back_style.bg_color = Color("#99501c") if state == "normal" else Color("#b96522")
		back_style.border_color = Color("#ffcf5c")
		back_style.set_border_width_all(3)
		back_style.set_corner_radius_all(16)
		back_button.add_theme_stylebox_override(state, back_style)
	back_button.pressed.connect(_leave_screen)
	add_child(back_button)
	var settings_button := _invisible_button(Rect2(0.86, 0.018, 0.13, 0.14), "Configuración")
	settings_button.pressed.connect(_show_settings_message)
	add_child(settings_button)

	letter_image = _letter_texture_rect()
	_place(letter_image, 0.219, 0.432, 0.181, 0.224)
	add_child(letter_image)
	var speak_button := _invisible_button(Rect2(0.348, 0.665, 0.045, 0.065), "Escuchar la letra")
	speak_button.pressed.connect(_speak_letter)
	add_child(speak_button)
	var caption_cover := _rounded_panel(Color("#ffd400"), Color.TRANSPARENT, 0, 5)
	_place(caption_cover, 0.266, 0.682, 0.081, 0.034)
	add_child(caption_cover)
	letter_caption = _label("Letra: A", 19, Color("#114a7f"))
	letter_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(letter_caption, 0.261, 0.672, 0.09, 0.052)
	add_child(letter_caption)

	trace_canvas = Control.new()
	trace_canvas.set_script(load("res://scripts/language/tracing/trace_canvas.gd"))
	_place(trace_canvas, 0.436, 0.242, 0.289, 0.445)
	add_child(trace_canvas)
	trace_canvas.connect("completed", Callable(self, "_on_trace_completed"))
	trace_canvas.connect("stroke_rejected", Callable(self, "_on_stroke_rejected"))
	trace_canvas.connect("stroke_finished", Callable(self, "_on_stroke_finished"))

	start_button = _visible_button("", Rect2(0.74, 0.285, 0.15, 0.14), "Toca y comienza a trazar")
	start_button.pressed.connect(_start_attempt)
	add_child(start_button)
	erase_button = _visible_button("", Rect2(0.738, 0.445, 0.127, 0.225), "Borrar el trazo actual")
	erase_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var erase_style := StyleBoxFlat.new()
		erase_style.bg_color = Color("#079af4") if state == "normal" else Color("#087dcc")
		erase_style.border_color = Color("#006dab")
		erase_style.set_border_width_all(3)
		erase_style.set_corner_radius_all(22)
		erase_style.shadow_color = Color(0.0, 0.3, 0.6, 0.22)
		erase_style.shadow_size = 3
		erase_style.shadow_offset = Vector2(0, 3)
		erase_button.add_theme_stylebox_override(state, erase_style)
	erase_button.pressed.connect(_reset_attempt)
	add_child(erase_button)
	var erase_icon := TextureRect.new()
	erase_icon.texture = load("res://assets/ui/tracing/icono-borrador.svg")
	erase_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	erase_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	erase_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(erase_icon, 0.25, 0.08, 0.50, 0.48)
	erase_button.add_child(erase_icon)
	var erase_label := _label("Borrar", 26, Color.WHITE)
	erase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	erase_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(erase_label, 0.05, 0.60, 0.90, 0.30)
	erase_button.add_child(erase_label)

	var count_board := TextureRect.new()
	count_board.texture = load("res://assets/ui/tracing/progreso-letras-madera.png")
	count_board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	count_board.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	count_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(count_board, 0.005, 0.78, 0.20, 0.19)
	add_child(count_board)
	counter_label = _label("1", 32, Color.WHITE)
	counter_label.add_theme_color_override("font_shadow_color", Color("#542309"))
	counter_label.add_theme_constant_override("shadow_offset_x", 2)
	counter_label.add_theme_constant_override("shadow_offset_y", 3)
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(counter_label, 0.075, 0.84, 0.04, 0.07)
	add_child(counter_label)
	counter_total_label = _label("27", 30, Color.WHITE)
	counter_total_label.add_theme_color_override("font_shadow_color", Color("#542309"))
	counter_total_label.add_theme_constant_override("shadow_offset_x", 2)
	counter_total_label.add_theme_constant_override("shadow_offset_y", 3)
	counter_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_total_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(counter_total_label, 0.12, 0.84, 0.055, 0.07)
	add_child(counter_total_label)

	result_label = _label("Sigue los puntos para trazar la letra.", 16, Color("#0b4b88"))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(result_label, 0.436, 0.695, 0.289, 0.042)
	add_child(result_label)

	exercise_label = _label("Ejercicio 1 de 10", 14, Color("#0b4b88"))
	exercise_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exercise_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(exercise_label, 0.219, 0.735, 0.181, 0.032)
	add_child(exercise_label)

	next_button = _visible_button("Siguiente →", Rect2(0.74, 0.685, 0.15, 0.065), "Siguiente letra")
	next_button.add_theme_font_size_override("font_size", 19)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#168bd2") if state != "disabled" else Color("#6b8295")
		style.border_color = Color.WHITE
		style.set_border_width_all(2)
		style.set_corner_radius_all(14)
		next_button.add_theme_stylebox_override(state, style)
	next_button.pressed.connect(_go_to_next_letter)
	add_child(next_button)
	_add_alphabet_selector()

func _show_current_letter() -> void:
	var letter: String = String(LETTERS[current_letter_index])
	var letter_texture: Texture2D = load(_letter_image_path(letter)) as Texture2D
	letter_image.texture = letter_texture
	letter_caption.text = "Letra: %s" % letter
	_update_progress_plaque()
	counter_total_label.text = "%d" % LETTERS.size()
	var done := int(completed_by_letter.get(letter, 0))
	exercise_label.text = "Ejercicio %d de %d" % [mini(done + 1, EXERCISES_PER_LETTER), EXERCISES_PER_LETTER]
	if done >= EXERCISES_PER_LETTER:
		result_label.text = "¡Letra %s completada!" % letter
	else:
		result_label.text = "Sigue los puntos para trazar la letra."
	trace_canvas.call("set_guide_strokes", LetterStrokes.for_letter(letter))
	# Las letras completadas siguen disponibles para practicar; el progreso queda guardado.
	start_button.disabled = false
	_update_next_button()
	if _completed_letter_count() == LETTERS.size():
		result_label.text = "¡Completaste las 27 letras!"
	_update_alphabet_selection()

func _add_alphabet_selector() -> void:
	# Deja visible la placa 1/27 a la izquierda y reduce el abecedario al 80 %.
	var alphabet_area := Control.new()
	_place(alphabet_area, 0.21, 0.78, 0.79, 0.188)
	alphabet_area.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(alphabet_area)
	# La tira tiene bordes transparentes; esta base tapa los botones del tablero que
	# se veían por los huecos, en especial la flecha que asomaba a la derecha.
	var alphabet_backing := _rounded_panel(Color("#fff0bd"), Color("#ffc42f"), 3, 18)
	_place(alphabet_backing, 0.0, 0.0, 1.0, 1.0)
	alphabet_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alphabet_area.add_child(alphabet_backing)

	var alphabet_image := TextureRect.new()
	alphabet_image.texture = load("res://assets/ui/language/tira-abecedario.png")
	alphabet_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	alphabet_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	alphabet_image.stretch_mode = TextureRect.STRETCH_SCALE
	alphabet_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alphabet_area.add_child(alphabet_image)

	_add_alphabet_hit_row(alphabet_area, LETTERS.slice(0, 13), 0.11, 0.40)
	_add_alphabet_hit_row(alphabet_area, LETTERS.slice(13, LETTERS.size()), 0.52, 0.40)

func _add_alphabet_hit_row(parent: Control, row_letters: Array, top: float, height: float) -> void:
	var row := HBoxContainer.new()
	_place(row, 0.02, top, 0.96, height)
	row.add_theme_constant_override("separation", 0)
	parent.add_child(row)
	for letter_value in row_letters:
		var letter := String(letter_value)
		var key := Button.new()
		key.text = ""
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key.size_flags_vertical = Control.SIZE_EXPAND_FILL
		key.focus_mode = Control.FOCUS_ALL
		key.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		key.tooltip_text = "Seleccionar y escuchar la letra %s" % letter
		key.add_theme_stylebox_override("normal", _alphabet_key_style(false, false))
		key.add_theme_stylebox_override("hover", _alphabet_key_style(false, true))
		key.add_theme_stylebox_override("pressed", _alphabet_key_style(true, false))
		key.add_theme_stylebox_override("focus", _alphabet_key_style(true, false))
		key.pressed.connect(_select_alphabet_letter.bind(letter))
		alphabet_buttons[letter] = key
		row.add_child(key)

func _alphabet_key_style(selected: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.22 if hovered else (0.16 if selected else 0.0))
	style.border_color = Color("#ffffff") if selected else Color("#8bdcff")
	style.set_border_width_all(3 if selected else (2 if hovered else 0))
	style.set_corner_radius_all(12)
	return style

func _update_alphabet_selection() -> void:
	for letter_value in alphabet_buttons:
		var letter := String(letter_value)
		var key := alphabet_buttons[letter] as Button
		key.add_theme_stylebox_override("normal", _alphabet_key_style(letter == LETTERS[current_letter_index], false))

func _select_alphabet_letter(letter: String) -> void:
	if praise_audio.playing:
		return
	var index := LETTERS.find(letter)
	if index < 0:
		return
	current_letter_index = index
	_show_current_letter()
	_speak_letter()

func _start_attempt() -> void:
	if praise_audio.playing:
		return
	trace_canvas.call("reset_drawing")
	trace_canvas.call("start_drawing")
	result_label.text = "Empieza en el punto 1 y sigue el camino."
	Narration.speak("trace_start", "Empieza en el punto uno y sigue el camino.")

func _reset_attempt() -> void:
	if praise_audio.playing:
		return
	Narration.stop()
	trace_canvas.call("reset_drawing")
	trace_canvas.call("start_drawing")
	result_label.text = "Borrado. Empieza otra vez en el punto 1."
	Narration.speak("trace_retry", "Puedes intentarlo otra vez. Sigue el camino de la letra.")

func _on_trace_completed() -> void:
	var letter := String(LETTERS[current_letter_index])
	var done := mini(int(completed_by_letter.get(letter, 0)) + 1, EXERCISES_PER_LETTER)
	completed_by_letter[letter] = done
	var saved := _save_progress()
	result_label.text = "¡Muy bien! Ejercicio guardado." if saved else "¡Muy bien! No se pudo guardar."
	var audio_started := _play_praise_audio()
	if audio_started:
		start_button.disabled = true
		_set_alphabet_buttons_enabled(false)
	if done < EXERCISES_PER_LETTER:
		exercise_label.text = "Ejercicio %d de %d" % [done + 1, EXERCISES_PER_LETTER]
		trace_canvas.call("reset_drawing")
	else:
		result_label.text = "¡Letra %s completada!" % letter
		if _completed_letter_count() == LETTERS.size():
			result_label.text = "¡Completaste las 27 letras!"
	_update_progress_plaque()
	_update_next_button()

func _on_stroke_rejected() -> void:
	result_label.text = "Sigue el camino; retoma donde quedaste."

func _on_stroke_finished(number: int, total: int) -> void:
	if number < total:
		result_label.text = "¡Bien! Ahora sigue el punto %d." % (number + 1)

func _update_next_button() -> void:
	var done := int(completed_by_letter.get(LETTERS[current_letter_index], 0))
	next_button.disabled = done < EXERCISES_PER_LETTER or current_letter_index >= LETTERS.size() - 1 or praise_audio.playing

func _go_to_next_letter() -> void:
	if next_button.disabled or current_letter_index >= LETTERS.size() - 1:
		return
	current_letter_index += 1
	_show_current_letter()

func _update_progress_plaque() -> void:
	counter_label.text = "%d" % _completed_letter_count()
	counter_label.tooltip_text = "Letras completadas"

func _completed_letter_count() -> int:
	var count := 0
	for letter in LETTERS:
		if int(completed_by_letter.get(letter, 0)) >= EXERCISES_PER_LETTER:
			count += 1
	return count

func _find_first_unfinished_letter() -> int:
	for index in range(LETTERS.size()):
		if int(completed_by_letter.get(LETTERS[index], 0)) < EXERCISES_PER_LETTER:
			return index
	return LETTERS.size() - 1

func _load_progress() -> void:
	var config := ProgressStore.read(SAVE_PATH)
	var saved: Variant = config.get_value("trazos", "completados", {})
	if saved is Dictionary:
		completed_by_letter = saved
	for letter in LETTERS:
		var stored: Variant = completed_by_letter.get(letter, 0)
		completed_by_letter[letter] = clampi(stored, 0, EXERCISES_PER_LETTER) if stored is int else 0

func _save_progress() -> bool:
	var config := ProgressStore.read(SAVE_PATH)
	config.set_value("trazos", "completados", completed_by_letter)
	var error := ProgressStore.write(config, SAVE_PATH)
	if error != OK:
		push_warning("No se pudo guardar el progreso de trazado: %s" % error_string(error))
	return error == OK

func _speak_letter() -> void:
	if praise_audio.playing:
		return
	Narration.speak("letter_%02d" % current_letter_index, LETTERS[current_letter_index])

func _play_praise_audio() -> bool:
	if praise_audio == null or praise_audio_streams.is_empty():
		return false
	Narration.stop()
	if praise_audio.playing:
		praise_audio.stop()
	praise_audio.stream = praise_audio_streams[praise_rng.randi_range(0, praise_audio_streams.size() - 1)]
	condor_frame_index = 0
	condor_frame_clock = 0.0
	condor_avatar.texture = condor_frames[condor_frame_index]
	praise_audio.play()
	return true

func _on_praise_audio_finished() -> void:
	condor_frame_clock = 0.0
	condor_frame_index = CONDOR_IDLE_FRAME
	if condor_avatar != null and not condor_frames.is_empty():
		condor_avatar.texture = condor_frames[CONDOR_IDLE_FRAME]
	_set_alphabet_buttons_enabled(true)
	if start_button != null:
		start_button.disabled = false
	_update_next_button()

func _set_alphabet_buttons_enabled(enabled: bool) -> void:
	for key_value in alphabet_buttons.values():
		(key_value as Button).disabled = not enabled

func _show_settings_message() -> void:
	result_label.text = "Audio local. Usa el altavoz para repetir."

func _leave_screen() -> void:
	Narration.stop()
	if praise_audio != null and praise_audio.playing:
		praise_audio.stop()
		_on_praise_audio_finished()
	close_requested.emit()

func _letter_image_path(letter: String) -> String:
	return "res://assets/ui/tracing/letters/%s.png" % letter

func _letter_texture_rect() -> TextureRect:
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

func _invisible_button(rect: Rect2, tooltip: String) -> Button:
	var button := Button.new()
	button.text = ""
	_place(button, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	button.tooltip_text = tooltip
	button.add_theme_stylebox_override("normal", _clear_style())
	button.add_theme_stylebox_override("hover", _clear_style())
	button.add_theme_stylebox_override("pressed", _clear_style())
	button.add_theme_stylebox_override("focus", _clear_style())
	return button

func _visible_button(text: String, rect: Rect2, tooltip: String) -> Button:
	var button := _invisible_button(rect, tooltip)
	button.text = text
	return button

func _clear_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	return style

func _panel(fill: Color, border_width: int) -> Panel:
	var panel := Panel.new()
	var style := _clear_style()
	style.bg_color = fill
	style.set_border_width_all(border_width)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _rounded_panel(fill: Color, border: Color, border_width: int, radius: int) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _place(control: Control, x: float, y: float, width: float, height: float) -> void:
	control.anchor_left = x
	control.anchor_top = y
	control.anchor_right = x + width
	control.anchor_bottom = y + height
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0

func _exit_tree() -> void:
	Narration.stop()
	if is_instance_valid(praise_audio):
		praise_audio.stop()
