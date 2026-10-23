extends Control

signal close_requested

const LETTERS := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "Ñ", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
const EXERCISES_PER_LETTER := 10
const LETTER_ADVANCE_DELAY := 0.9
const SAVE_PATH := "user://progreso_traza_letras.cfg"
const CONDOR_FRAME_COUNT := 119
const CONDOR_FRAME_INTERVAL := 0.06
const CONDOR_IDLE_FRAME := 80
const PRAISE_AUDIO_PATHS := [
	"res://assets/audio-felicitacion-traza.mp3",
	"res://assets/felicitaciones/p_23391271_965.mp3",
	"res://assets/felicitaciones/p_23391426_98.mp3",
	"res://assets/felicitaciones/MiniMax_2026-10-23_11_03_52_Captivating_Storyteller.mp3",
	"res://assets/felicitaciones/MiniMax_2026-10-23_11_06_42_Captivating_Storyteller.mp3",
	"res://assets/felicitaciones/MiniMax_2026-10-23_11_08_25_Captivating_Storyteller.mp3",
	"res://assets/felicitaciones/p_23389894_865.mp3"
]

var current_letter_index := 0
var completed_by_letter: Dictionary = {}
var letter_image: TextureRect
var preview_image: TextureRect
var counter_label: Label
var counter_total_label: Label
var letter_caption: Label
var result_label: Label
var exercise_label: Label
var trace_canvas: Control
var start_button: Button
var next_button: Button
var next_lock_overlay: ColorRect
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
	if praise_audio == null or not praise_audio.playing:
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
	background.texture = load("res://assets/fondo-traza.png")
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
	board_art.texture = load("res://assets/tablero-trazos.png")
	board_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board_art.stretch_mode = TextureRect.STRETCH_SCALE
	board_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board_art)

	for frame_number in range(CONDOR_FRAME_COUNT):
		condor_frames.append(load("res://assets/condor-frames/frame_%03d.png" % frame_number))
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
	praise_audio.stream = load("res://assets/audio-felicitacion-traza.mp3") as AudioStream
	praise_audio.finished.connect(_on_praise_audio_finished)
	add_child(praise_audio)

	# Controles transparentes sobre las ilustraciones ya incluidas en el tablero.
	var back_button := _invisible_button(Rect2(0.02, 0.025, 0.25, 0.13), "Volver al tablero de lenguaje")
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
	trace_canvas.set_script(load("res://scripts/trace_canvas.gd"))
	_place(trace_canvas, 0.426, 0.232, 0.309, 0.51)
	add_child(trace_canvas)
	trace_canvas.connect("completed", Callable(self, "_on_trace_completed"))

	start_button = _visible_button("", Rect2(0.74, 0.285, 0.15, 0.14), "Toca y comienza a trazar")
	start_button.pressed.connect(_start_attempt)
	add_child(start_button)
	var retry_button := _visible_button("", Rect2(0.74, 0.455, 0.15, 0.215), "Borrar y volver a empezar")
	retry_button.pressed.connect(_reset_attempt)
	add_child(retry_button)

	var count_board := TextureRect.new()
	count_board.texture = load("res://assets/progreso-letras-madera.png")
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

	var message_cover := _panel(Color("#d6f3ff"), 0)
	_place(message_cover, 0.325, 0.815, 0.31, 0.095)
	add_child(message_cover)
	result_label = _label("Sigue los puntos para trazar la letra.", 19, Color("#0b4b88"))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(result_label, 0.33, 0.815, 0.30, 0.095)
	add_child(result_label)

	exercise_label = _label("Ejercicio 1 de 10", 14, Color("#0b4b88"))
	exercise_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exercise_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(exercise_label, 0.701, 0.795, 0.122, 0.035)
	add_child(exercise_label)
	preview_image = _letter_texture_rect()
	_place(preview_image, 0.701, 0.83, 0.122, 0.115)
	add_child(preview_image)

	next_button = _invisible_button(Rect2(0.885, 0.80, 0.105, 0.17), "Siguiente letra")
	next_button.pressed.connect(_go_to_next_letter)
	add_child(next_button)
	next_button.disabled = true
	next_lock_overlay = ColorRect.new()
	next_lock_overlay.color = Color(0.18, 0.24, 0.34, 0.48)
	next_lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(next_lock_overlay, 0.885, 0.80, 0.105, 0.17)
	add_child(next_lock_overlay)
	_add_alphabet_selector()

func _show_current_letter() -> void:
	var letter: String = String(LETTERS[current_letter_index])
	var letter_texture: Texture2D = load(_letter_image_path(letter)) as Texture2D
	letter_image.texture = letter_texture
	preview_image.texture = letter_texture
	letter_caption.text = "Letra: %s" % letter
	counter_label.text = "%d" % (current_letter_index + 1)
	counter_total_label.text = "%d" % LETTERS.size()
	var done := int(completed_by_letter.get(letter, 0))
	exercise_label.text = "Ejercicio %d de %d" % [mini(done + 1, EXERCISES_PER_LETTER), EXERCISES_PER_LETTER]
	if done >= EXERCISES_PER_LETTER:
		result_label.text = "¡Letra %s completada!" % letter
	else:
		result_label.text = "Sigue los puntos para trazar la letra."
	trace_canvas.call("set_guide_strokes", _letter_strokes(letter))
	# Las letras completadas siguen disponibles para practicar; el progreso queda guardado.
	start_button.disabled = false
	next_button.disabled = true
	next_lock_overlay.visible = done < EXERCISES_PER_LETTER or current_letter_index >= LETTERS.size() - 1
	if current_letter_index == LETTERS.size() - 1 and done >= EXERCISES_PER_LETTER:
		result_label.text = "¡Completaste las 27 letras!"
		next_lock_overlay.visible = true
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
	alphabet_image.texture = load("res://assets/tira-abecedario.png")
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
		key.focus_mode = Control.FOCUS_NONE
		key.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		key.tooltip_text = "Seleccionar y escuchar la letra %s" % letter
		key.add_theme_stylebox_override("normal", _alphabet_key_style(false, false))
		key.add_theme_stylebox_override("hover", _alphabet_key_style(false, true))
		key.add_theme_stylebox_override("pressed", _alphabet_key_style(true, false))
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
	var index := LETTERS.find(letter)
	if index < 0:
		return
	current_letter_index = index
	_show_current_letter()
	_speak_letter()

func _start_attempt() -> void:
	# Reinicia también las letras ya completadas para permitir volver a practicarlas.
	trace_canvas.call("reset_drawing")
	trace_canvas.call("start_drawing")
	result_label.text = "Empieza en el punto 1 y sigue el camino."

func _reset_attempt() -> void:
	trace_canvas.call("reset_drawing")
	var done := int(completed_by_letter.get(LETTERS[current_letter_index], 0))
	if done < EXERCISES_PER_LETTER:
		result_label.text = "Inténtalo otra vez siguiendo los puntos."

func _on_trace_completed() -> void:
	var letter: String = String(LETTERS[current_letter_index])
	var previous_done := int(completed_by_letter.get(letter, 0))
	var done := mini(previous_done + 1, EXERCISES_PER_LETTER)
	completed_by_letter[letter] = done
	_save_progress()
	result_label.text = "¡Lo hiciste muy bien! ¡Felicidades!"
	var audio_started := _play_praise_audio()
	if audio_started:
		start_button.disabled = true
		_set_alphabet_buttons_enabled(false)
	if done < EXERCISES_PER_LETTER:
		exercise_label.text = "Ejercicio %d de 10" % (done + 1)
		trace_canvas.call("reset_drawing")
	else:
		next_button.disabled = true
		next_lock_overlay.visible = current_letter_index >= LETTERS.size() - 1
		if current_letter_index == LETTERS.size() - 1:
			result_label.text = "¡Completaste las 27 letras! ¡Felicidades!"
	_update_progress_plaque()
	if previous_done < EXERCISES_PER_LETTER and done >= EXERCISES_PER_LETTER and current_letter_index < LETTERS.size() - 1:
		if audio_started and praise_audio.playing:
			await praise_audio.finished
			if not is_inside_tree():
				return
		await get_tree().create_timer(LETTER_ADVANCE_DELAY).timeout
		if not is_inside_tree():
			return
		current_letter_index += 1
		_show_current_letter()

func _go_to_next_letter() -> void:
	if next_button.disabled or current_letter_index >= LETTERS.size() - 1:
		return
	current_letter_index += 1
	_show_current_letter()

func _update_progress_plaque() -> void:
	counter_label.text = "%d" % (current_letter_index + 1)

func _find_first_unfinished_letter() -> int:
	for index in range(LETTERS.size()):
		if int(completed_by_letter.get(LETTERS[index], 0)) < EXERCISES_PER_LETTER:
			return index
	return LETTERS.size() - 1

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		var saved: Variant = config.get_value("trazos", "completados", {})
		if saved is Dictionary:
			completed_by_letter = saved
	for letter in LETTERS:
		completed_by_letter[letter] = clampi(int(completed_by_letter.get(letter, 0)), 0, EXERCISES_PER_LETTER)

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("trazos", "completados", completed_by_letter)
	config.save(SAVE_PATH)

func _speak_letter() -> void:
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(LETTERS[current_letter_index], "", 100.0, 1.0, 0.92, 0, true)

func _play_praise_audio() -> bool:
	if praise_audio == null or praise_audio_streams.is_empty():
		DisplayServer.tts_speak("Lo hiciste muy bien. ¡Felicidades!", "", 100.0, 1.0, 0.92, 0, true)
		return false
	DisplayServer.tts_stop()
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

func _set_alphabet_buttons_enabled(enabled: bool) -> void:
	for key_value in alphabet_buttons.values():
		(key_value as Button).disabled = not enabled

func _show_settings_message() -> void:
	result_label.text = "Puedes cambiar el sonido desde Configuración."

func _leave_screen() -> void:
	DisplayServer.tts_stop()
	if praise_audio != null and praise_audio.playing:
		praise_audio.stop()
		_on_praise_audio_finished()
	close_requested.emit()

func _letter_strokes(letter: String) -> Array:
	var shapes := {
		"A": [[Vector2(0.15, 0.88), Vector2(0.50, 0.12), Vector2(0.85, 0.88)], [Vector2(0.30, 0.58), Vector2(0.70, 0.58)]],
		"B": [[Vector2(0.25, 0.12), Vector2(0.25, 0.88)], [Vector2(0.25, 0.12), Vector2(0.58, 0.12), Vector2(0.78, 0.22), Vector2(0.80, 0.36), Vector2(0.70, 0.48), Vector2(0.25, 0.50)], [Vector2(0.25, 0.50), Vector2(0.64, 0.50), Vector2(0.80, 0.62), Vector2(0.79, 0.77), Vector2(0.63, 0.88), Vector2(0.25, 0.88)]],
		"C": [[Vector2(0.78, 0.20), Vector2(0.63, 0.12), Vector2(0.42, 0.14), Vector2(0.25, 0.30), Vector2(0.20, 0.50), Vector2(0.25, 0.72), Vector2(0.43, 0.86), Vector2(0.66, 0.87), Vector2(0.80, 0.78)]],
		"D": [[Vector2(0.28, 0.12), Vector2(0.28, 0.88)], [Vector2(0.28, 0.12), Vector2(0.52, 0.12), Vector2(0.73, 0.25), Vector2(0.82, 0.48), Vector2(0.77, 0.70), Vector2(0.59, 0.86), Vector2(0.28, 0.88)]],
		"E": [[Vector2(0.72, 0.12), Vector2(0.28, 0.12), Vector2(0.28, 0.88), Vector2(0.74, 0.88)], [Vector2(0.30, 0.50), Vector2(0.68, 0.50)]],
		"F": [[Vector2(0.28, 0.88), Vector2(0.28, 0.12), Vector2(0.75, 0.12)], [Vector2(0.30, 0.49), Vector2(0.67, 0.49)]],
		"G": [[Vector2(0.78, 0.22), Vector2(0.62, 0.12), Vector2(0.42, 0.15), Vector2(0.25, 0.31), Vector2(0.20, 0.52), Vector2(0.27, 0.73), Vector2(0.46, 0.87), Vector2(0.70, 0.84), Vector2(0.80, 0.70), Vector2(0.80, 0.55), Vector2(0.58, 0.55)]],
		"H": [[Vector2(0.25, 0.12), Vector2(0.25, 0.88)], [Vector2(0.75, 0.12), Vector2(0.75, 0.88)], [Vector2(0.26, 0.50), Vector2(0.74, 0.50)]],
		"I": [[Vector2(0.30, 0.12), Vector2(0.70, 0.12)], [Vector2(0.50, 0.12), Vector2(0.50, 0.88)], [Vector2(0.30, 0.88), Vector2(0.70, 0.88)]],
		"J": [[Vector2(0.32, 0.12), Vector2(0.75, 0.12)], [Vector2(0.68, 0.12), Vector2(0.68, 0.67), Vector2(0.60, 0.82), Vector2(0.43, 0.88), Vector2(0.28, 0.79), Vector2(0.25, 0.68)]],
		"K": [[Vector2(0.28, 0.12), Vector2(0.28, 0.88)], [Vector2(0.72, 0.12), Vector2(0.30, 0.52), Vector2(0.76, 0.88)]],
		"L": [[Vector2(0.30, 0.12), Vector2(0.30, 0.88), Vector2(0.75, 0.88)]],
		"M": [[Vector2(0.20, 0.88), Vector2(0.20, 0.12), Vector2(0.50, 0.52), Vector2(0.80, 0.12), Vector2(0.80, 0.88)]],
		"N": [[Vector2(0.24, 0.88), Vector2(0.24, 0.12), Vector2(0.76, 0.88), Vector2(0.76, 0.12)]],
		"Ñ": [[Vector2(0.24, 0.88), Vector2(0.24, 0.24), Vector2(0.76, 0.88), Vector2(0.76, 0.24)], [Vector2(0.34, 0.12), Vector2(0.50, 0.02), Vector2(0.67, 0.12)]],
		"O": [[Vector2(0.50, 0.12), Vector2(0.70, 0.17), Vector2(0.82, 0.34), Vector2(0.84, 0.53), Vector2(0.76, 0.73), Vector2(0.60, 0.86), Vector2(0.42, 0.86), Vector2(0.25, 0.73), Vector2(0.17, 0.53), Vector2(0.20, 0.34), Vector2(0.32, 0.17), Vector2(0.50, 0.12)]],
		# La panza vuelve al centro del asta; separarla evita que el punto final
		# se confunda con el mismo punto al pasar por el asta vertical.
		"P": [[Vector2(0.28, 0.88), Vector2(0.28, 0.12)], [Vector2(0.28, 0.12), Vector2(0.62, 0.12), Vector2(0.80, 0.24), Vector2(0.80, 0.40), Vector2(0.64, 0.51), Vector2(0.28, 0.51)]],
		"Q": [[Vector2(0.50, 0.12), Vector2(0.70, 0.17), Vector2(0.82, 0.34), Vector2(0.84, 0.53), Vector2(0.76, 0.73), Vector2(0.60, 0.86), Vector2(0.42, 0.86), Vector2(0.25, 0.73), Vector2(0.17, 0.53), Vector2(0.20, 0.34), Vector2(0.32, 0.17), Vector2(0.50, 0.12)], [Vector2(0.57, 0.65), Vector2(0.82, 0.90)]],
		# Igual que en la P, el asta y la curva son pasos separados para que
		# el final de la curva no coincida con un punto intermedio del asta.
		"R": [[Vector2(0.28, 0.88), Vector2(0.28, 0.12)], [Vector2(0.28, 0.12), Vector2(0.62, 0.12), Vector2(0.80, 0.24), Vector2(0.80, 0.40), Vector2(0.64, 0.51), Vector2(0.28, 0.51)], [Vector2(0.28, 0.51), Vector2(0.80, 0.88)]],
		"S": [[Vector2(0.78, 0.22), Vector2(0.62, 0.12), Vector2(0.40, 0.14), Vector2(0.25, 0.27), Vector2(0.28, 0.42), Vector2(0.47, 0.50), Vector2(0.67, 0.56), Vector2(0.80, 0.68), Vector2(0.75, 0.82), Vector2(0.58, 0.88), Vector2(0.36, 0.85), Vector2(0.22, 0.76)]],
		"T": [[Vector2(0.20, 0.12), Vector2(0.80, 0.12)], [Vector2(0.50, 0.12), Vector2(0.50, 0.88)]],
		"U": [[Vector2(0.24, 0.12), Vector2(0.24, 0.62), Vector2(0.30, 0.78), Vector2(0.44, 0.88), Vector2(0.60, 0.88), Vector2(0.75, 0.78), Vector2(0.80, 0.62), Vector2(0.80, 0.12)]],
		"V": [[Vector2(0.20, 0.12), Vector2(0.50, 0.88), Vector2(0.80, 0.12)]],
		"W": [[Vector2(0.15, 0.12), Vector2(0.30, 0.88), Vector2(0.50, 0.48), Vector2(0.70, 0.88), Vector2(0.85, 0.12)]],
		"X": [[Vector2(0.22, 0.12), Vector2(0.78, 0.88)], [Vector2(0.78, 0.12), Vector2(0.22, 0.88)]],
		"Y": [[Vector2(0.20, 0.12), Vector2(0.50, 0.50), Vector2(0.80, 0.12)], [Vector2(0.50, 0.50), Vector2(0.50, 0.88)]],
		"Z": [[Vector2(0.22, 0.12), Vector2(0.78, 0.12), Vector2(0.22, 0.88), Vector2(0.78, 0.88)]]
	}
	var raw_strokes: Array = shapes.get(letter, shapes["A"])
	var result: Array = []
	for raw_stroke in raw_strokes:
		var stroke := PackedVector2Array()
		for point in raw_stroke:
			stroke.append(point)
		result.append(stroke)
	return result

func _letter_image_path(letter: String) -> String:
	return "res://assets/trace-letters/%s.png" % letter

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
