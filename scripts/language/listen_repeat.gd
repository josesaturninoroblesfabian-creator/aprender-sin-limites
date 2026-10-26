extends Control

## Pantalla Escucha y repite. Su árbol se construye aquí:
## ListenRepeat (Control)
## ├── Fondo (TextureRect) / Velo (ColorRect)
## ├── Encabezado (Panel): volver y título
## ├── Guía (Panel): cóndor e instrucciones
## ├── TarjetaCentral (Panel): letra, ilustración, palabra, escuchar y grabar
## ├── MiProgreso (Panel): contador de 270, barra y estrellas
## └── Abecedario (Panel): botones para las 27 letras

signal close_requested

const Alphabet = preload("res://scripts/language/alphabet.gd")
const LETTERS: Array = Alphabet.LETTERS
const DATA_PATH := "res://data/language/abecedario.json"
const PROGRESS_PATH := "user://progreso_escucha_repite.cfg"
const RECORDINGS_PATH := "user://repeticiones"
const INSTRUCTIONS_AUDIO_PATH := "res://assets/audio/audio-instrucciones-escucha-repite.mp3"
const FINAL_AUDIO_PATH := "res://assets/audio/audio-final-completa-270.mp3"
const COMPLETION_GAME_PATH := "res://assets/games/condor-andino-abecedario.html"
const PRAISE_AUDIO_PATHS := [
	"res://assets/audio/felicitacion-repite-01.mp3",
	"res://assets/audio/felicitacion-repite-02.mp3",
	"res://assets/audio/felicitacion-repite-03.mp3",
	"res://assets/audio/felicitacion-repite-04.mp3",
	"res://assets/audio/felicitacion-repite-05.mp3",
	"res://assets/audio/felicitacion-repite-06.mp3",
	"res://assets/audio/felicitacion-repite-07.mp3",
	"res://assets/audio/felicitacion-repite-08.mp3",
	"res://assets/audio/felicitacion-repite-09.mp3",
	"res://assets/audio/felicitacion-repite-10.mp3",
	"res://assets/audio/felicitacion-repite-11.mp3"
]
const EXPECTED_WORDS_PER_LETTER := 10
const TOTAL_WORDS := 270
const CONDOR_FRAME_COUNT := 119
const CONDOR_FRAME_INTERVAL := 0.04
const NEON_YELLOW := Color("#eaff00")
const KEY_COLORS := ["#f04450", "#3989ed", "#f1a800", "#17b981", "#a34be9", "#ed3f8d", "#fa7c25", "#14b8ae", "#10abc9"]

var words: Array[Dictionary] = []
var current_index := 0
var completed: Dictionary = {}
var recording_frames := PackedVector2Array()
var capture_effect: AudioEffectCapture
var microphone_player: AudioStreamPlayer
var instructions_player: AudioStreamPlayer
var praise_player: AudioStreamPlayer
var final_audio_player: AudioStreamPlayer
var condor_avatar: TextureRect
var condor_frames: Array[Texture2D] = []
var condor_frame_index := 0
var condor_frame_clock := 0.0
var recording := false
var recording_started_msec := 0
var record_bus_name := "RepeatCapture"
var created_record_bus := false
var last_praise_index := -1
var final_audio_pending := false
var final_audio_played := false

var letter_display: Label
var word_display: Label
var picture_display: Label
var item_counter: Label
var progress_display: Label
var progress_detail: Label
var progress_fill: Panel
var global_stars: Array[Label] = []
var previous_button: Button
var next_button: Button
var listen_button: Button
var record_button: Button
var repeat_instructions_button: Button
var status_display: Label
var alphabet_buttons: Dictionary = {}
var completion_tween: Tween

func start(initial_letter: String = "A") -> void:
	name = "EscuchaYRepite"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_words()
	_load_progress()
	_setup_microphone()
	_build_screen()
	_select_letter(initial_letter)
	if final_audio_pending:
		_play_final_audio()
	else:
		_play_instructions()

func _process(delta: float) -> void:
	if recording:
		_drain_microphone_buffer()
	var condor_audio_playing := _guidance_audio_playing()
	if condor_audio_playing and not condor_frames.is_empty():
		condor_frame_clock += delta
		while condor_frame_clock >= CONDOR_FRAME_INTERVAL:
			condor_frame_clock -= CONDOR_FRAME_INTERVAL
			condor_frame_index = (condor_frame_index + 1) % condor_frames.size()
			condor_avatar.texture = condor_frames[condor_frame_index]

func _load_words() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not parsed is Dictionary:
		push_error("No se pudo leer el abecedario de Escucha y repite.")
		return
	for letter in LETTERS:
		var examples: Variant = parsed.get(letter, [])
		if not examples is Array or examples.size() != EXPECTED_WORDS_PER_LETTER:
			push_error("La letra %s debe tener exactamente 10 palabras." % letter)
			continue
		var seen := {}
		for example_index in range(examples.size()):
			var parts := String(examples[example_index]).split("|", false, 1)
			if parts.is_empty() or String(parts[0]).strip_edges().is_empty():
				continue
			var word := String(parts[0]).strip_edges()
			if seen.has(word.to_lower()):
				push_error("La letra %s contiene una palabra repetida: %s." % [letter, word])
				continue
			seen[word.to_lower()] = true
			words.append({
				"letter": letter,
				"word": word,
				"picture": String(parts[1]) if parts.size() > 1 else "⭐",
				"letter_index": LETTERS.find(letter),
				"example_index": example_index
			})
	if words.size() != TOTAL_WORDS:
		push_error("Se esperaban 270 palabras distintas y se encontraron %d." % words.size())

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(PROGRESS_PATH) == OK:
		var saved: Variant = config.get_value("repeticiones", "completadas", {})
		if saved is Dictionary:
			for entry in words:
				var identifier := _word_id(entry)
				if bool(saved.get(identifier, false)):
					completed[identifier] = true
		final_audio_pending = bool(config.get_value("repeticiones", "audio_final_pendiente", false))
		final_audio_played = bool(config.get_value("repeticiones", "audio_final_reproducido", false))
	if completed.size() >= TOTAL_WORDS and not final_audio_played:
		final_audio_pending = true

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("repeticiones", "completadas", completed)
	config.set_value("repeticiones", "audio_final_pendiente", final_audio_pending)
	config.set_value("repeticiones", "audio_final_reproducido", final_audio_played)
	var error := config.save(PROGRESS_PATH)
	if error != OK:
		push_warning("No se pudo guardar el progreso de voz: %s" % error_string(error))

func _setup_microphone() -> void:
	var bus_index := AudioServer.get_bus_index(record_bus_name)
	if bus_index < 0:
		bus_index = AudioServer.bus_count
		AudioServer.add_bus(bus_index)
		AudioServer.set_bus_name(bus_index, record_bus_name)
		AudioServer.set_bus_send(bus_index, "Master")
		AudioServer.set_bus_volume_db(bus_index, -48.0)
		created_record_bus = true
	var already_has_capture := false
	for effect_index in range(AudioServer.get_bus_effect_count(bus_index)):
		if AudioServer.get_bus_effect(bus_index, effect_index) is AudioEffectCapture:
			capture_effect = AudioServer.get_bus_effect(bus_index, effect_index) as AudioEffectCapture
			already_has_capture = true
			break
	if not already_has_capture:
		capture_effect = AudioEffectCapture.new()
		capture_effect.buffer_length = 1.0
		AudioServer.add_bus_effect(bus_index, capture_effect)
	microphone_player = AudioStreamPlayer.new()
	microphone_player.name = "Microfono"
	microphone_player.bus = record_bus_name
	microphone_player.stream = AudioStreamMicrophone.new()
	add_child(microphone_player)

func _build_screen() -> void:
	var background := TextureRect.new()
	background.name = "Fondo"
	background.texture = load("res://assets/backgrounds/fondo-paisaje-andino.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var wash := ColorRect.new()
	wash.name = "Velo"
	wash.color = Color(0.10, 0.70, 0.92, 0.30)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var header := _panel(Color("#32bfe8"), Color("#ffffff"), 3, 26)
	header.name = "Encabezado"
	_place(header, 0.015, 0.018, 0.97, 0.105)
	add_child(header)
	var back := _button("←  Volver a Lenguaje", Color("#f5a00a"), 18)
	_place(back, 0.014, 0.14, 0.23, 0.70)
	back.pressed.connect(func(): close_requested.emit())
	header.add_child(back)
	var title := _label("🔊  2. ESCUCHA Y REPITE", 30, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(title, 0.25, 0.06, 0.52, 0.78)
	header.add_child(title)
	var subtitle := _label("Aprende el Abecedario", 15, Color("#fffbea"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(subtitle, 0.35, 0.75, 0.30, 0.22)
	header.add_child(subtitle)

	var guide := _panel(Color("#a9e6fa"), Color.WHITE, 2, 26)
	guide.name = "Guia"
	_place(guide, 0.015, 0.145, 0.205, 0.525)
	add_child(guide)
	condor_frames.clear()
	for frame_number in range(CONDOR_FRAME_COUNT):
		condor_frames.append(load("res://assets/characters/condor/frames/frame_%03d.png" % frame_number))
	condor_avatar = TextureRect.new()
	condor_avatar.texture = condor_frames[0]
	condor_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	condor_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	condor_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(condor_avatar, 0.10, 0.04, 0.80, 0.45)
	guide.add_child(condor_avatar)
	var guide_text := _label("¡Vamos a escuchar y repetir!\n\nPulsa una letra, escucha la palabra y graba tu voz.", 16, Color("#20364f"))
	guide_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	guide_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(guide_text, 0.06, 0.51, 0.88, 0.29)
	guide.add_child(guide_text)
	repeat_instructions_button = _button("🔁  Repetir instrucciones", Color("#278bc8"), 13)
	repeat_instructions_button.tooltip_text = "Volver a escuchar las instrucciones de Conde"
	_place(repeat_instructions_button, 0.08, 0.83, 0.84, 0.13)
	repeat_instructions_button.pressed.connect(_play_instructions)
	guide.add_child(repeat_instructions_button)
	instructions_player = AudioStreamPlayer.new()
	instructions_player.name = "AudioInstrucciones"
	instructions_player.stream = load(INSTRUCTIONS_AUDIO_PATH) as AudioStream
	instructions_player.finished.connect(_on_guidance_audio_finished)
	add_child(instructions_player)
	praise_player = AudioStreamPlayer.new()
	praise_player.name = "AudioFelicitacion"
	praise_player.finished.connect(_on_guidance_audio_finished)
	add_child(praise_player)
	final_audio_player = AudioStreamPlayer.new()
	final_audio_player.name = "AudioFinal270"
	final_audio_player.stream = load(FINAL_AUDIO_PATH) as AudioStream
	final_audio_player.finished.connect(_on_guidance_audio_finished)
	add_child(final_audio_player)

	var card := _panel(Color("#fffdf2"), Color("#ffdf36"), 5, 30)
	card.name = "TarjetaCentral"
	_place(card, 0.235, 0.145, 0.52, 0.525)
	add_child(card)
	letter_display = _label("A", 104, Color("#ef4350"))
	letter_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(letter_display, 0.025, 0.08, 0.21, 0.67)
	card.add_child(letter_display)
	var separator := ColorRect.new()
	separator.color = Color("#d8dfea")
	_place(separator, 0.245, 0.15, 0.004, 0.56)
	card.add_child(separator)
	var word_card := _panel(Color("#edf8ff"), Color("#90d8f7"), 3, 20)
	_place(word_card, 0.29, 0.105, 0.66, 0.52)
	card.add_child(word_card)
	picture_display = _label("🌈", 68, Color.WHITE)
	picture_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	picture_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(picture_display, 0.04, 0.03, 0.92, 0.62)
	word_card.add_child(picture_display)
	word_display = _label("A de Arcoíris", 28, Color("#07517d"))
	word_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(word_display, 0.04, 0.65, 0.92, 0.29)
	word_card.add_child(word_display)
	item_counter = _label("Palabra 1 de 10", 15, Color("#204b71"))
	item_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(item_counter, 0.28, 0.65, 0.68, 0.09)
	card.add_child(item_counter)
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 8)
	_place(controls, 0.03, 0.73, 0.94, 0.15)
	card.add_child(controls)
	previous_button = _button("◀ Anterior", Color("#377fe3"), 15)
	previous_button.custom_minimum_size = Vector2(120, 48)
	previous_button.pressed.connect(_step_word.bind(-1))
	controls.add_child(previous_button)
	listen_button = _button("🔊 Escuchar", Color("#ffbd19"), 15, Color("#42310b"))
	listen_button.custom_minimum_size = Vector2(145, 48)
	listen_button.pressed.connect(_listen_to_word)
	controls.add_child(listen_button)
	record_button = _button("🎙 Grabar voz", Color("#22c991"), 14)
	record_button.custom_minimum_size = Vector2(150, 48)
	record_button.pressed.connect(_toggle_recording)
	controls.add_child(record_button)
	next_button = _button("Siguiente ▶", Color("#377fe3"), 15)
	next_button.custom_minimum_size = Vector2(120, 48)
	next_button.pressed.connect(_step_word.bind(1))
	controls.add_child(next_button)
	status_display = _label("Tu voz queda guardada en este dispositivo.", 13, Color("#28536d"))
	status_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(status_display, 0.05, 0.89, 0.90, 0.09)
	card.add_child(status_display)

	var progress := _panel(Color("#f3fbff"), Color("#82d7fb"), 3, 26)
	progress.name = "MiProgreso"
	_place(progress, 0.775, 0.145, 0.21, 0.525)
	add_child(progress)
	var progress_title := _label("⭐  Mi Progreso", 21, Color("#17476a"))
	progress_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(progress_title, 0.035, 0.035, 0.93, 0.15)
	progress.add_child(progress_title)
	progress_display = _label("Letras completas: 0 / 270", 16, Color("#09567f"))
	progress_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(progress_display, 0.04, 0.22, 0.92, 0.18)
	progress.add_child(progress_display)
	var track := _panel(Color("#d7efff"), Color("#8dd9ff"), 1, 12)
	_place(track, 0.09, 0.44, 0.82, 0.09)
	progress.add_child(track)
	progress_fill = _panel(Color("#21c8ad"), Color("#d4fff3"), 1, 12)
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_fill.visible = false
	_place(progress_fill, 0.02, 0.12, 0.001, 0.76)
	track.add_child(progress_fill)
	progress_detail = _label("Letra A: 0 de 10 palabras grabadas", 13, Color("#184a67"))
	progress_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(progress_detail, 0.04, 0.56, 0.92, 0.13)
	progress.add_child(progress_detail)
	var reward_text := _label("Estrellas de recompensa", 13, Color("#a65a00"))
	reward_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(reward_text, 0.04, 0.70, 0.92, 0.10)
	progress.add_child(reward_text)
	var rewards := HBoxContainer.new()
	rewards.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards.add_theme_constant_override("separation", 7)
	_place(rewards, 0.12, 0.80, 0.76, 0.16)
	progress.add_child(rewards)
	for _star_index in range(3):
		var star := _label("★", 30, Color("#e3dba8"))
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star.custom_minimum_size = Vector2(40, 40)
		global_stars.append(star)
		rewards.add_child(star)

	var alphabet_panel := _panel(Color("#e9f8ff"), Color.WHITE, 3, 28)
	alphabet_panel.name = "Abecedario"
	_place(alphabet_panel, 0.015, 0.69, 0.97, 0.295)
	add_child(alphabet_panel)
	var alphabet_title := _label("🟠  Toca una letra para empezar:", 17, Color("#31465d"))
	_place(alphabet_title, 0.025, 0.025, 0.55, 0.13)
	alphabet_panel.add_child(alphabet_title)
	var available := _label("27 letras disponibles", 13, Color("#a64b00"))
	available.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(available, 0.77, 0.025, 0.20, 0.13)
	alphabet_panel.add_child(available)
	var grid := GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 7)
	_place(grid, 0.018, 0.20, 0.964, 0.76)
	alphabet_panel.add_child(grid)
	for letter_index in range(LETTERS.size()):
		var letter: String = LETTERS[letter_index]
		var key := _button(letter, Color(KEY_COLORS[letter_index % KEY_COLORS.size()]), 24)
		key.custom_minimum_size = Vector2(70, 55)
		key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key.size_flags_vertical = Control.SIZE_EXPAND_FILL
		key.pressed.connect(_select_letter.bind(letter))
		alphabet_buttons[letter] = key
		grid.add_child(key)

func _select_letter(letter: String) -> void:
	if recording or _celebration_locked():
		return
	if _guidance_audio_playing():
		_stop_guidance_audio()
	for index in range(words.size()):
		if words[index].letter == letter:
			current_index = index
			_render_current_word()
			return

func _step_word(amount: int) -> void:
	if recording or _celebration_locked() or words.is_empty():
		return
	_stop_guidance_audio()
	current_index = clampi(current_index + amount, 0, words.size() - 1)
	_render_current_word()

func _render_current_word() -> void:
	if words.is_empty() or not is_instance_valid(word_display):
		return
	var entry: Dictionary = words[current_index]
	letter_display.text = String(entry.letter)
	word_display.text = "%s de %s" % [entry.letter, entry.word]
	picture_display.text = String(entry.picture)
	item_counter.text = "Palabra %d de 10" % (int(entry.example_index) + 1)
	var celebration_locked := _celebration_locked()
	previous_button.disabled = recording or celebration_locked or current_index == 0
	next_button.disabled = recording or celebration_locked or current_index >= words.size() - 1
	listen_button.disabled = recording or celebration_locked
	record_button.disabled = celebration_locked
	repeat_instructions_button.disabled = recording or celebration_locked
	for letter in LETTERS:
		var key: Button = alphabet_buttons.get(letter)
		if key != null:
			key.disabled = recording or celebration_locked
			key.modulate = Color.WHITE if letter == entry.letter else Color(0.79, 0.83, 0.89, 1.0)
	_update_progress()

func _listen_to_word() -> void:
	if recording or _celebration_locked() or words.is_empty():
		return
	_stop_guidance_audio()
	var entry: Dictionary = words[current_index]
	var clip_id := "word_%02d_%02d" % [int(entry.letter_index), int(entry.example_index)]
	if not Narration.speak(clip_id, String(entry.word)):
		status_display.text = "No se encontró una voz disponible en este equipo."
	else:
		status_display.text = "Escucha con atención: %s" % entry.word

func _toggle_recording() -> void:
	if recording:
		_finish_recording()
	else:
		_begin_recording()

func _begin_recording() -> void:
	if _celebration_locked():
		return
	if AudioServer.get_input_device_list().is_empty():
		status_display.text = "Conecta un micrófono y permite su uso en Windows."
		return
	if capture_effect == null or microphone_player == null:
		status_display.text = "No se pudo preparar el micrófono. Revisa los permisos de audio."
		return
	_stop_guidance_audio()
	Narration.stop()
	recording_frames.clear()
	capture_effect.clear_buffer()
	recording_started_msec = Time.get_ticks_msec()
	if not microphone_player.playing:
		microphone_player.play()
	recording = true
	repeat_instructions_button.disabled = true
	record_button.text = "⏹ Detener"
	status_display.text = "Te escucho… di la palabra y pulsa Terminar."
	_render_current_word()

func _drain_microphone_buffer() -> void:
	if capture_effect == null:
		return
	while capture_effect.get_frames_available() > 0:
		var frames_to_read := mini(capture_effect.get_frames_available(), 4096)
		if frames_to_read <= 0:
			break
		recording_frames.append_array(capture_effect.get_buffer(frames_to_read))

func _finish_recording() -> void:
	_drain_microphone_buffer()
	if is_instance_valid(microphone_player):
		microphone_player.stop()
	recording = false
	repeat_instructions_button.disabled = false
	record_button.text = "🎙  Grabar voz"
	if Time.get_ticks_msec() - recording_started_msec < 250 or recording_frames.size() < int(AudioServer.get_mix_rate() * 0.2):
		status_display.text = "La grabación fue muy corta. Intenta otra vez."
		_render_current_word()
		return
	var peak := 0.0
	for frame in recording_frames:
		peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
	if peak < 0.003:
		status_display.text = "No se oyó tu voz. Revisa el micrófono y vuelve a grabar."
		_render_current_word()
		return
	var error := _save_recording()
	if error != OK:
		status_display.text = "No se pudo guardar el audio. Revisa el espacio disponible."
		push_warning("No se pudo guardar la repetición: %s" % error_string(error))
		_render_current_word()
		return
	var entry: Dictionary = words[current_index]
	var completed_all_before := completed.size() >= TOTAL_WORDS
	completed[_word_id(entry)] = true
	if not completed_all_before and completed.size() >= TOTAL_WORDS and not final_audio_played:
		final_audio_pending = true
	_save_progress()
	status_display.text = "¡Completaste las 270 palabras!" if final_audio_pending else "¡Muy bien! Tu voz quedó grabada."
	_render_current_word()
	_play_random_praise()

func _save_recording() -> Error:
	var directory := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RECORDINGS_PATH))
	if directory != OK:
		return directory
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = AudioServer.get_mix_rate()
	wav.stereo = true
	var data := PackedByteArray()
	data.resize(recording_frames.size() * 4)
	for frame_index in range(recording_frames.size()):
		var frame := recording_frames[frame_index]
		data.encode_s16(frame_index * 4, int(round(clampf(frame.x, -1.0, 1.0) * 32767.0)))
		data.encode_s16(frame_index * 4 + 2, int(round(clampf(frame.y, -1.0, 1.0) * 32767.0)))
	wav.data = data
	var entry: Dictionary = words[current_index]
	var file_path := "%s/%s.wav" % [RECORDINGS_PATH, _word_id(entry)]
	return wav.save_to_wav(file_path)

func _word_id(entry: Dictionary) -> String:
	return "%02d_%02d" % [int(entry.letter_index), int(entry.example_index)]

func _play_instructions() -> void:
	if recording or instructions_player == null or instructions_player.stream == null:
		return
	Narration.stop()
	_stop_guidance_audio()
	instructions_player.play()

func _play_random_praise() -> void:
	if recording or praise_player == null or PRAISE_AUDIO_PATHS.is_empty():
		return
	Narration.stop()
	_stop_guidance_audio()
	var selected_index := randi_range(0, PRAISE_AUDIO_PATHS.size() - 1)
	if PRAISE_AUDIO_PATHS.size() > 1 and selected_index == last_praise_index:
		selected_index = (selected_index + randi_range(1, PRAISE_AUDIO_PATHS.size() - 1)) % PRAISE_AUDIO_PATHS.size()
	last_praise_index = selected_index
	praise_player.stream = load(PRAISE_AUDIO_PATHS[selected_index]) as AudioStream
	if praise_player.stream == null:
		push_warning("No se pudo cargar el audio de felicitación: %s" % PRAISE_AUDIO_PATHS[selected_index])
		if final_audio_pending:
			_play_final_audio()
		return
	praise_player.play()

func _guidance_audio_playing() -> bool:
	return (instructions_player != null and instructions_player.playing) or (praise_player != null and praise_player.playing) or (final_audio_player != null and final_audio_player.playing)

func _celebration_locked() -> bool:
	return final_audio_pending or (final_audio_player != null and final_audio_player.playing)

func _stop_guidance_audio() -> void:
	if instructions_player != null:
		instructions_player.stop()
	if praise_player != null:
		praise_player.stop()
	if final_audio_player != null:
		final_audio_player.stop()
	_reset_condor_pose()

func _on_guidance_audio_finished() -> void:
	if _guidance_audio_playing():
		return
	if final_audio_pending:
		_play_final_audio()
		return
	if completed.size() >= TOTAL_WORDS and not final_audio_played:
		final_audio_played = true
		_save_progress()
		_open_completion_game()
	_reset_condor_pose()
	if is_instance_valid(record_button):
		_render_current_word()

func _play_final_audio() -> void:
	if final_audio_player == null:
		return
	if final_audio_player.stream == null:
		push_warning("No se pudo cargar el audio de celebración de las 270 palabras.")
		final_audio_pending = false
		final_audio_played = true
		_save_progress()
		status_display.text = "¡Completaste las 270 palabras!"
		_render_current_word()
		_open_completion_game()
		return
	Narration.stop()
	if instructions_player != null:
		instructions_player.stop()
	if praise_player != null:
		praise_player.stop()
	final_audio_pending = false
	_save_progress()
	_reset_condor_pose()
	status_display.text = "¡Felicidades! Completaste las 270 palabras."
	final_audio_player.play()
	_render_current_word()

func _open_completion_game() -> void:
	var game_path := ProjectSettings.globalize_path(COMPLETION_GAME_PATH)
	if not FileAccess.file_exists(COMPLETION_GAME_PATH):
		push_warning("No se encontró el juego de celebración: %s" % game_path)
		status_display.text = "¡Completaste las 270 palabras! No se encontró el juego sorpresa."
		return
	var game_uri := "file:///" + game_path.replace("\\", "/").replace(" ", "%20")
	var error := OS.shell_open(game_uri)
	if error != OK:
		push_warning("No se pudo abrir el juego de celebración: %s" % error_string(error))
		status_display.text = "¡Completaste las 270 palabras! Abre el juego sorpresa desde el proyecto."
	else:
		status_display.text = "¡Felicidades! Se abrió el juego sorpresa del cóndor."

func _reset_condor_pose() -> void:
	condor_frame_index = 0
	condor_frame_clock = 0.0
	if is_instance_valid(condor_avatar) and not condor_frames.is_empty():
		condor_avatar.texture = condor_frames[0]

func _update_progress() -> void:
	if not is_instance_valid(progress_display) or words.is_empty():
		return
	var completed_count := completed.size()
	progress_display.text = "Letras completas: %d / %d" % [completed_count, TOTAL_WORDS]
	var current_entry: Dictionary = words[current_index]
	var letter_count := 0
	for entry in words:
		if entry.letter == current_entry.letter and completed.has(_word_id(entry)):
			letter_count += 1
	progress_detail.text = "Letra %s: %d de 10 palabras grabadas" % [current_entry.letter, letter_count]
	var ratio := clampf(float(completed_count) / float(TOTAL_WORDS), 0.0, 1.0)
	progress_fill.visible = ratio > 0.0
	progress_fill.anchor_right = 0.02 + 0.96 * ratio
	var all_done := completed_count >= TOTAL_WORDS
	var fill_style := progress_fill.get_theme_stylebox("panel") as StyleBoxFlat
	fill_style.bg_color = NEON_YELLOW if all_done else Color("#21c8ad")
	fill_style.border_color = Color("#ffffb5") if all_done else Color("#d4fff3")
	fill_style.shadow_color = Color(0.86, 1.0, 0.0, 0.95) if all_done else Color(0.03, 0.18, 0.26, 0.25)
	fill_style.shadow_size = 13 if all_done else 4
	var stars_lit := 0
	if completed_count >= int(ceil(float(TOTAL_WORDS) * 0.25)):
		stars_lit = 1
	if completed_count >= int(ceil(float(TOTAL_WORDS) * 0.65)):
		stars_lit = 2
	if all_done:
		stars_lit = 3
	for star_index in range(global_stars.size()):
		var lit := star_index < stars_lit
		global_stars[star_index].add_theme_color_override("font_color", NEON_YELLOW if lit else Color("#c9d3dc"))
		global_stars[star_index].modulate = Color.WHITE if lit else Color(0.72, 0.75, 0.78, 1.0)
	if all_done and (completion_tween == null or not completion_tween.is_running()):
		completion_tween = create_tween().set_loops()
		for star in global_stars:
			completion_tween.parallel().tween_property(star, "scale", Vector2(1.18, 1.18), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			completion_tween.parallel().tween_property(star, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.45)

func _button(text: String, color: Color, font_size: int, font_color: Color = Color.WHITE) -> Button:
	var result := Button.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", font_color)
	result.add_theme_color_override("font_hover_color", font_color)
	result.add_theme_color_override("font_pressed_color", font_color)
	result.add_theme_stylebox_override("normal", _style(color, Color.WHITE, 2, 15))
	result.add_theme_stylebox_override("hover", _style(color.lightened(0.12), Color("#fff176"), 3, 15))
	result.add_theme_stylebox_override("pressed", _style(color.darkened(0.12), Color.WHITE, 2, 15))
	result.add_theme_stylebox_override("disabled", _style(color.darkened(0.18), Color("#d3dce5"), 1, 15))
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
	result.shadow_color = Color(0.03, 0.18, 0.26, 0.25)
	result.shadow_size = 4
	result.shadow_offset = Vector2(0, 3)
	result.content_margin_left = 9
	result.content_margin_right = 9
	result.content_margin_top = 6
	result.content_margin_bottom = 6
	return result

func _exit_tree() -> void:
	if recording:
		recording = false
	if is_instance_valid(microphone_player):
		microphone_player.stop()
	if is_instance_valid(instructions_player):
		instructions_player.stop()
	if is_instance_valid(praise_player):
		praise_player.stop()
	if is_instance_valid(final_audio_player):
		final_audio_player.stop()
	Narration.stop()
	if created_record_bus:
		var bus_index := AudioServer.get_bus_index(record_bus_name)
		if bus_index >= 0:
			AudioServer.remove_bus(bus_index)
