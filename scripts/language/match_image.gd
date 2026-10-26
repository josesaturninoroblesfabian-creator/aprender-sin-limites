extends Control

## Minijuego: relaciona cada letra con la palabra ilustrada que le corresponde.
## Cada ronda presenta tres parejas; 27 rondas forman los 81 ejercicios.
signal close_requested

const Alphabet = preload("res://scripts/language/alphabet.gd")
const LETTERS: Array = Alphabet.LETTERS
const SAVE_PATH := "user://progreso_unir_imagen.cfg"
const SAMPLE_RATE := 22050
const CONDOR_FRAME_COUNT := 119
const CONDOR_FRAME_INTERVAL := 0.04
const CONDOR_INTRO_AUDIO := "res://assets/audio/audio-instrucciones-une-imagen.mp3"
const CONDOR_COMPLETION_AUDIO := "res://assets/audio/audio-felicitacion-completa-unir-imagen.mp3"
const MUSIC_TRACKS := [
	"res://assets/audio/unir-imagen-musica-01.mp3",
	"res://assets/audio/unir-imagen-musica-02.mp3"
]
const WORDS_BY_LETTER := {
	"A": ["Árbol|🌳", "Avión|✈️", "Abeja|🐝"], "B": ["Barco|🚢", "Balón|⚽", "Bicicleta|🚲"],
	"C": ["Casa|🏠", "Conejo|🐇", "Cereza|🍒"], "D": ["Dado|🎲", "Delfín|🐬", "Dinosaurio|🦖"],
	"E": ["Elefante|🐘", "Estrella|⭐", "Escoba|🧹"], "F": ["Flor|🌸", "Foca|🦭", "Flauta|🪈"],
	"G": ["Gato|🐈", "Globo|🎈", "Guitarra|🎸"], "H": ["Helado|🍦", "Huevo|🥚", "Hormiga|🐜"],
	"I": ["Isla|🏝️", "Iguana|🦎", "Imán|🧲"], "J": ["Jirafa|🦒", "Jabón|🧼", "Jardín|🌷"],
	"K": ["Koala|🐨", "Kiwi|🥝", "Kimono|👘"], "L": ["León|🦁", "Luna|🌙", "Lápiz|✏️"],
	"M": ["Manzana|🍎", "Mariposa|🦋", "Montaña|⛰️"], "N": ["Nube|☁️", "Naranja|🍊", "Nido|🪺"],
	"Ñ": ["Ñandú|🐦", "Ñame|🍠", "Ñu|🦬"], "O": ["Oso|🐻", "Oveja|🐑", "Olla|🍲"],
	"P": ["Perro|🐕", "Pelota|⚽", "Piña|🍍"], "Q": ["Queso|🧀", "Quena|🪈", "Quetzal|🐦"],
	"R": ["Rana|🐸", "Reloj|⌚", "Robot|🤖"], "S": ["Sol|☀️", "Sandía|🍉", "Silla|🪑"],
	"T": ["Tortuga|🐢", "Tren|🚂", "Tomate|🍅"], "U": ["Uva|🍇", "Unicornio|🦄", "Uniforme|👔"],
	"V": ["Vaca|🐄", "Vela|🕯️", "Volcán|🌋"], "W": ["Wafle|🧇", "Wifi|📶", "Wok|🍳"],
	"X": ["Xilófono|🎼", "Xoloitzcuintle|🐕", "Xenón|💡"], "Y": ["Yate|🛥️", "Yegua|🐎", "Yoyo|🪀"],
	"Z": ["Zapato|👞", "Zorro|🦊", "Zanahoria|🥕"]
}

class MatchBoard extends Control:
	signal pair_checked(correct: bool, exercise_id: int)
	signal tapped

	var entries: Array[Dictionary] = []
	var solved: Dictionary = {}
	var left_order: Array[int] = [0, 1, 2]
	var right_order: Array[int] = [0, 1, 2]
	var left_rects: Array[Rect2] = []
	var right_rects: Array[Rect2] = []
	var selected_left := -1
	var drag_position := Vector2.ZERO
	var dragging := false
	var rng := RandomNumberGenerator.new()
	var feedback := ""
	var feedback_color := Color("#234c73")

	func set_round(round_entries: Array[Dictionary], done: Dictionary) -> void:
		entries = round_entries.duplicate()
		solved = done
		rng.randomize()
		left_order = [0, 1, 2]
		right_order = [0, 1, 2]
		left_order.shuffle()
		right_order.shuffle()
		selected_left = -1
		dragging = false
		feedback = "Une la palabra que corresponde con la imagen indicada."
		feedback_color = Color("#234c73")
		queue_redraw()

	func update_solved(done: Dictionary) -> void:
		solved = done
		queue_redraw()

	func _draw() -> void:
		left_rects.clear()
		right_rects.clear()
		var w := size.x
		var h := size.y
		var left_card_w := w * 0.36
		var right_card_w := w * 0.42
		var card_h := minf(h * 0.22, 88.0)
		var left_x := w * 0.035
		var right_x := w * 0.54
		var top := h * 0.17
		var row_gap := h * 0.265
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(left_x + 10, h * 0.105), "LETRAS", HORIZONTAL_ALIGNMENT_LEFT, left_card_w - 10, 20, Color("#0b5284"))
		draw_string(font, Vector2(right_x + 10, h * 0.105), "DIBUJOS Y PALABRAS", HORIZONTAL_ALIGNMENT_LEFT, right_card_w - 10, 20, Color("#0b5284"))
		for i in range(3):
			left_rects.append(Rect2(left_x, top + i * row_gap, left_card_w, card_h))
			right_rects.append(Rect2(right_x, top + i * row_gap, right_card_w, card_h))
		# Líneas de respuestas ya acertadas, detrás de las tarjetas.
		for left_row in range(3):
			var entry_index: int = left_order[left_row]
			var entry: Dictionary = entries[entry_index]
			var identifier := str(entry.id)
			if not solved.has(identifier):
				continue
			var target_row := -1
			for right_row in range(3):
				if right_order[right_row] == entry_index:
					target_row = right_row
					break
			if target_row >= 0:
				draw_line(left_rects[left_row].get_center() + Vector2(left_card_w * 0.48, 0), right_rects[target_row].get_center() - Vector2(right_card_w * 0.48, 0), Color("#35b982"), 7.0, true)
		if dragging and selected_left >= 0:
			draw_line(left_rects[selected_left].get_center() + Vector2(left_card_w * 0.48, 0), drag_position, Color("#168bd2"), 6.0, true)
		for row in range(3):
			var left_entry: Dictionary = entries[left_order[row]]
			var left_id := str(left_entry.id)
			var left_fill := Color("#e8f6ff")
			var left_border := Color("#48a8ed")
			if solved.has(left_id):
				left_fill = Color("#d7f8e8")
				left_border = Color("#28ae76")
			elif selected_left == row:
				left_fill = Color("#fff2af")
				left_border = Color("#f2a900")
			_draw_card(left_rects[row], left_fill, left_border)
			var capital := String(left_entry.letter)
			var lowercase := capital.to_lower()
			draw_string(font, Vector2(left_rects[row].position.x + 12, left_rects[row].position.y + card_h * 0.66), "%s   %s" % [capital, lowercase], HORIZONTAL_ALIGNMENT_CENTER, left_card_w - 24, 40, Color("#134777"))
			var right_entry: Dictionary = entries[right_order[row]]
			var right_fill := Color("#fff9df")
			var right_border := Color("#f1bd38")
			if solved.has(str(right_entry.id)):
				right_fill = Color("#d7f8e8")
				right_border = Color("#28ae76")
			_draw_card(right_rects[row], right_fill, right_border)
			var icon := String(right_entry.icon)
			var object_word := String(right_entry.word)
			draw_string(font, Vector2(right_rects[row].position.x + 12, right_rects[row].position.y + card_h * 0.66), "%s   %s" % [icon, object_word], HORIZONTAL_ALIGNMENT_CENTER, right_card_w - 24, 28, Color("#16517c"))
		if not feedback.is_empty():
			draw_string(font, Vector2(w * 0.035, h * 0.965), feedback, HORIZONTAL_ALIGNMENT_CENTER, w * 0.93, 16, feedback_color)

	func _draw_card(rect: Rect2, fill: Color, border: Color) -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = fill
		style.border_color = border
		style.set_border_width_all(3)
		style.set_corner_radius_all(18)
		style.shadow_color = Color(0.04, 0.16, 0.24, 0.18)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 3)
		style.draw(get_canvas_item(), rect)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_press(event.position)
			else:
				_handle_release(event.position)
			accept_event()
		elif event is InputEventMouseMotion and dragging:
			drag_position = event.position
			queue_redraw()
			accept_event()
		elif event is InputEventScreenTouch:
			if event.pressed:
				_handle_press(event.position)
			else:
				_handle_release(event.position)
			accept_event()
		elif event is InputEventScreenDrag and dragging:
			drag_position = event.position
			queue_redraw()
			accept_event()

	func _input(event: InputEvent) -> void:
		if not dragging:
			return
		var inverse_transform := get_global_transform_with_canvas().affine_inverse()
		if event is InputEventMouseMotion:
			var mouse_local: Vector2 = inverse_transform * event.position
			if not Rect2(Vector2.ZERO, size).has_point(mouse_local):
				drag_position = mouse_local
				queue_redraw()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var release_local: Vector2 = inverse_transform * event.position
			if not Rect2(Vector2.ZERO, size).has_point(release_local):
				_handle_release(release_local)
		elif event is InputEventScreenDrag:
			var touch_local: Vector2 = inverse_transform * event.position
			if not Rect2(Vector2.ZERO, size).has_point(touch_local):
				drag_position = touch_local
				queue_redraw()
		elif event is InputEventScreenTouch and not event.pressed:
			var touch_release_local: Vector2 = inverse_transform * event.position
			if not Rect2(Vector2.ZERO, size).has_point(touch_release_local):
				_handle_release(touch_release_local)

	func _handle_press(position: Vector2) -> void:
		tapped.emit()
		for row in range(left_rects.size()):
			if left_rects[row].has_point(position):
				var entry: Dictionary = entries[left_order[row]]
				if solved.has(str(entry.id)):
					return
				selected_left = row
				dragging = true
				drag_position = position
				feedback = "Suelta la línea sobre la palabra que empieza con esta letra."
				feedback_color = Color("#234c73")
				queue_redraw()
				return
		if selected_left >= 0:
			for row in range(right_rects.size()):
				if right_rects[row].has_point(position):
					_attempt_match(row)
					return

	func _handle_release(position: Vector2) -> void:
		if selected_left < 0:
			return
		dragging = false
		drag_position = position
		for row in range(right_rects.size()):
			if right_rects[row].has_point(position):
				_attempt_match(row)
				return
		queue_redraw()

	func _attempt_match(right_row: int) -> void:
		if selected_left < 0 or right_row < 0 or right_row >= right_order.size():
			return
		var left_entry: Dictionary = entries[left_order[selected_left]]
		var right_entry: Dictionary = entries[right_order[right_row]]
		if solved.has(str(left_entry.id)) or solved.has(str(right_entry.id)):
			feedback = "Esa pareja ya está unida. Elige otra."
			feedback_color = Color("#b67508")
			selected_left = -1
			queue_redraw()
			return
		var correct: bool = String(left_entry["letter"]) == String(right_entry["letter"])
		if correct:
			feedback = "¡Muy bien! ¡Encontraste la pareja!"
			feedback_color = Color("#168d61")
			pair_checked.emit(true, int(left_entry.id))
		else:
			feedback = "Casi. Intenta unir esa letra con otra imagen."
			feedback_color = Color("#d84b53")
			pair_checked.emit(false, -1)
		selected_left = -1
		queue_redraw()


var solved: Dictionary = {}
var rounds: Array[Array] = []
var current_round := 0
var round_revision := 0
var score_label: Label
var round_label: Label
var progress_fill: Panel
var stars: Array[Label] = []
var board: MatchBoard
var previous_button: Button
var next_button: Button
var success_player: AudioStreamPlayer
var error_player: AudioStreamPlayer
var click_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var condor_avatar: TextureRect
var condor_audio: AudioStreamPlayer
var condor_frames: Array[Texture2D] = []
var condor_frame_index := 0
var condor_frame_clock := 0.0
var condor_speaking := false
var completion_audio_played := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rng.randomize()
	_build_rounds()
	_load_progress()
	_build_ui()
	current_round = _first_unfinished_round()
	_refresh_round()
	_setup_audio()
	_setup_condor_intro()

func _process(delta: float) -> void:
	if not condor_speaking or not is_instance_valid(condor_audio) or not condor_audio.playing or condor_frames.is_empty():
		return
	condor_frame_clock += delta
	while condor_frame_clock >= CONDOR_FRAME_INTERVAL:
		condor_frame_clock -= CONDOR_FRAME_INTERVAL
		condor_frame_index = (condor_frame_index + 1) % condor_frames.size()
		condor_avatar.texture = condor_frames[condor_frame_index]

func _build_rounds() -> void:
	var exercise_id := 0
	for word_index in range(3):
		for group_start in range(0, LETTERS.size(), 3):
			var round_entries: Array[Dictionary] = []
			for offset in range(3):
				var letter_index := group_start + offset
				if letter_index >= LETTERS.size():
					continue
				var letter := String(LETTERS[letter_index])
				var examples: Array = WORDS_BY_LETTER.get(letter, [])
				var parts := String(examples[word_index]).split("|", false, 1)
				round_entries.append({
					"id": exercise_id,
					"letter": letter,
					"word": String(parts[0]),
					"icon": String(parts[1]) if parts.size() > 1 else "⭐"
				})
				exercise_id += 1
			rounds.append(round_entries)
	if exercise_id != 81 or rounds.size() != 27:
		push_error("Une con la imagen debe tener 81 ejercicios distribuidos en 27 rondas.")

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved: Variant = config.get_value("progreso", "parejas_completadas", {})
	if saved is Dictionary:
		for identifier in saved:
			if bool(saved[identifier]) and int(identifier) >= 0 and int(identifier) < 81:
				solved[str(identifier)] = true

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progreso", "parejas_completadas", solved)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("No se pudo guardar el progreso de Une con la imagen: %s" % error_string(error))

func _build_ui() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/backgrounds/fondo-paisaje-andino.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var header := _panel(Color("#20aee2"), Color.WHITE, 3, 24)
	_place(header, 0.025, 0.025, 0.95, 0.12)
	add_child(header)
	var back := _button("←  Volver a Lenguaje", Color("#f5a00a"), 18)
	_place(back, 0.015, 0.15, 0.23, 0.70)
	back.pressed.connect(func(): close_requested.emit())
	header.add_child(back)
	var title := _label("3. UNE CON LA IMAGEN", 30, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(title, 0.26, 0.08, 0.48, 0.55)
	header.add_child(title)
	var subtitle := _label("Relaciona cada letra con su dibujo", 15, Color("#fffbea"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(subtitle, 0.30, 0.62, 0.40, 0.25)
	header.add_child(subtitle)
	var instruction := _label("Arrastra una letra hasta el dibujo y la palabra que empiezan con ella.", 19, Color("#114577"))
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(instruction, 0.07, 0.155, 0.86, 0.055)
	add_child(instruction)
	var board_panel := _panel(Color("#fffdf4"), Color("#ffdc38"), 5, 28)
	_place(board_panel, 0.055, 0.225, 0.89, 0.455)
	add_child(board_panel)
	board = MatchBoard.new()
	board.name = "TableroDeParejas"
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.offset_left = 18
	board.offset_top = 12
	board.offset_right = -18
	board.offset_bottom = -12
	board.pair_checked.connect(_on_pair_checked)
	board.tapped.connect(_play_click)
	board_panel.add_child(board)
	var progress_panel := _panel(Color("#eef8ff"), Color("#68c9f1"), 3, 20)
	_place(progress_panel, 0.11, 0.735, 0.78, 0.105)
	add_child(progress_panel)
	score_label = _label("Parejas encontradas: 0 / 81", 19, Color("#0b4e80"))
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(score_label, 0.025, 0.08, 0.31, 0.36)
	progress_panel.add_child(score_label)
	round_label = _label("Ronda 1 / 27", 15, Color("#16517c"))
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(round_label, 0.34, 0.08, 0.31, 0.36)
	progress_panel.add_child(round_label)
	var stars_row := HBoxContainer.new()
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_row.add_theme_constant_override("separation", 14)
	_place(stars_row, 0.68, 0.015, 0.30, 0.52)
	progress_panel.add_child(stars_row)
	for i in range(3):
		var star := _label("☆", 32, Color("#a9b7c4"))
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star.custom_minimum_size = Vector2(38, 42)
		stars.append(star)
		stars_row.add_child(star)
	var progress_track := _panel(Color("#d9e7f0"), Color("#b6d2e4"), 1, 12)
	_place(progress_track, 0.025, 0.57, 0.95, 0.27)
	progress_panel.add_child(progress_track)
	progress_fill = _panel(Color("#30ce88"), Color("#16a96a"), 1, 12)
	progress_fill.anchor_left = 0.0
	progress_fill.anchor_top = 0.0
	progress_fill.anchor_right = 0.0
	progress_fill.anchor_bottom = 1.0
	progress_track.add_child(progress_fill)
	previous_button = _button("◀  Anterior", Color("#3787e5"), 19)
	_place(previous_button, 0.315, 0.865, 0.17, 0.085)
	previous_button.pressed.connect(_previous_round)
	add_child(previous_button)
	next_button = _button("Siguiente  ▶", Color("#3787e5"), 19)
	_place(next_button, 0.515, 0.865, 0.17, 0.085)
	next_button.pressed.connect(_next_round)
	add_child(next_button)

func _refresh_round(reshuffle_board: bool = true) -> void:
	if rounds.is_empty() or not is_instance_valid(board):
		return
	current_round = clampi(current_round, 0, rounds.size() - 1)
	if reshuffle_board:
		board.set_round(rounds[current_round], solved)
	else:
		board.update_solved(solved)
	var count := solved.size()
	score_label.text = "Parejas encontradas: %d / 81" % count
	round_label.text = "Ronda %d / 27" % [current_round + 1]
	var percent := float(count) / 81.0
	progress_fill.anchor_right = percent
	var lit := 0
	if count >= 27:
		lit = 1
	if count >= 54:
		lit = 2
	if count >= 81:
		lit = 3
	for i in range(stars.size()):
		stars[i].text = "★" if i < lit else "☆"
		stars[i].add_theme_color_override("font_color", Color("#ffe600") if i < lit else Color("#a9b7c4"))
	previous_button.disabled = current_round <= 0
	next_button.disabled = current_round >= rounds.size() - 1
	if count >= 81:
		board.feedback = "¡Completaste los 81 ejercicios! ¡Eres increíble!"
		board.feedback_color = Color("#168d61")
		progress_fill.add_theme_stylebox_override("panel", _style(Color("#eaff00"), Color("#f7b928"), 2, 12))
	else:
		progress_fill.add_theme_stylebox_override("panel", _style(Color("#30ce88"), Color("#16a96a"), 1, 12))
		if _round_is_complete(current_round):
			board.feedback = "¡Ronda completa! ¡Sigue así!"
			board.feedback_color = Color("#168d61")
	board.queue_redraw()

func _round_is_complete(round_index: int) -> bool:
	if round_index < 0 or round_index >= rounds.size():
		return false
	for entry in rounds[round_index]:
		if not solved.has(str(entry.id)):
			return false
	return true

func _on_pair_checked(correct: bool, exercise_id: int) -> void:
	if correct:
		solved[str(exercise_id)] = true
		_save_progress()
		_play_success()
		_refresh_round(false)
		if solved.size() >= 81 and not completion_audio_played:
			completion_audio_played = _play_condor_completion()
		if _round_is_complete(current_round) and current_round < rounds.size() - 1:
			round_revision += 1
			_advance_after_delay(round_revision, current_round)
	else:
		_play_error()

func _advance_after_delay(revision: int, from_round: int) -> void:
	await get_tree().create_timer(1.0).timeout
	if revision != round_revision or current_round != from_round:
		return
	current_round += 1
	_refresh_round()

func _previous_round() -> void:
	round_revision += 1
	current_round = maxi(0, current_round - 1)
	_refresh_round()

func _next_round() -> void:
	round_revision += 1
	current_round = mini(rounds.size() - 1, current_round + 1)
	_refresh_round()

func _first_unfinished_round() -> int:
	for i in range(rounds.size()):
		if not _round_is_complete(i):
			return i
	return maxi(0, rounds.size() - 1)

func _setup_audio() -> void:
	success_player = _audio_player("SonidoAcierto", _make_tone_stream([784.0, 988.0, 1175.0], 0.12, 0.32))
	error_player = _audio_player("SonidoError", _make_tone_stream([220.0, 185.0], 0.13, 0.25))
	click_player = _audio_player("SonidoClic", _make_tone_stream([660.0], 0.045, 0.18))
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicaDeFondo"
	music_player.volume_db = -12.0
	add_child(music_player)
	var selected_music_index := rng.randi_range(0, MUSIC_TRACKS.size() - 1)
	var music := load(MUSIC_TRACKS[selected_music_index]) as AudioStreamMP3
	if music != null:
		music.loop = true
		music_player.stream = music
		music_player.play()
	else:
		push_warning("No se pudo cargar la música de Une con la imagen.")

func _setup_condor_intro() -> void:
	for frame_number in range(CONDOR_FRAME_COUNT):
		var frame := load("res://assets/characters/condor/frames/frame_%03d.png" % frame_number) as Texture2D
		if frame != null:
			condor_frames.append(frame)
	condor_avatar = TextureRect.new()
	condor_avatar.name = "CondorPresentador"
	condor_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	condor_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	condor_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(condor_avatar, 0.855, 0.015, 0.11, 0.13)
	if not condor_frames.is_empty():
		condor_avatar.texture = condor_frames[0]
	add_child(condor_avatar)
	condor_audio = AudioStreamPlayer.new()
	condor_audio.name = "AudioPresentacionCondor"
	condor_audio.stream = load(CONDOR_INTRO_AUDIO) as AudioStream
	condor_audio.finished.connect(_on_condor_audio_finished)
	add_child(condor_audio)
	_start_condor_intro()

func _start_condor_intro() -> void:
	if not is_instance_valid(condor_audio) or condor_audio.stream == null:
		push_warning("No se pudo cargar el audio de presentación de Une con la imagen.")
		return
	condor_audio.stop()
	condor_frame_index = 0
	condor_frame_clock = 0.0
	if not condor_frames.is_empty():
		condor_avatar.texture = condor_frames[0]
	condor_speaking = true
	condor_audio.play()

func _play_condor_completion() -> bool:
	if not is_instance_valid(condor_audio):
		return false
	var completion_stream := load(CONDOR_COMPLETION_AUDIO) as AudioStream
	if completion_stream == null:
		push_warning("No se pudo cargar el audio de felicitación de Une con la imagen.")
		return false
	condor_audio.stop()
	condor_audio.stream = completion_stream
	condor_frame_index = 0
	condor_frame_clock = 0.0
	if not condor_frames.is_empty():
		condor_avatar.texture = condor_frames[0]
	if is_instance_valid(music_player):
		music_player.stop()
	condor_speaking = true
	condor_audio.play()
	return true

func _on_condor_audio_finished() -> void:
	condor_speaking = false
	condor_frame_index = 0
	condor_frame_clock = 0.0
	if is_instance_valid(condor_avatar) and not condor_frames.is_empty():
		condor_avatar.texture = condor_frames[0]
	if is_instance_valid(music_player) and not music_player.playing:
		music_player.play()

func _audio_player(player_name: String, stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.stream = stream
	player.volume_db = -4.0
	add_child(player)
	return player

func _make_tone_stream(frequencies: Array, note_seconds: float, amplitude: float) -> AudioStreamWAV:
	var samples_per_note := int(SAMPLE_RATE * note_seconds)
	var data := PackedByteArray()
	data.resize(samples_per_note * frequencies.size() * 2)
	for i in range(samples_per_note * frequencies.size()):
		var note_index := int(i / samples_per_note)
		var local_sample := i % samples_per_note
		var phase := TAU * float(frequencies[note_index]) * float(local_sample) / SAMPLE_RATE
		var edge := minf(float(local_sample) / (SAMPLE_RATE * 0.012), float(samples_per_note - local_sample) / (SAMPLE_RATE * 0.025))
		var envelope := clampf(edge, 0.0, 1.0)
		var wave := 1.0 if sin(phase) >= 0.0 else -1.0
		data.encode_s16(i * 2, int(round(wave * amplitude * envelope * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

func _play_success() -> void:
	if is_instance_valid(success_player):
		success_player.play()

func _play_error() -> void:
	if is_instance_valid(error_player):
		error_player.play()

func _play_click() -> void:
	if is_instance_valid(click_player):
		click_player.play()

func _build_button(text: String, color: Color, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(color, Color.WHITE, 2, 16))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.12), Color("#fff176"), 3, 16))
	button.add_theme_stylebox_override("pressed", _style(color.darkened(0.12), Color.WHITE, 2, 16))
	button.add_theme_stylebox_override("disabled", _style(color.darkened(0.2), Color("#ccd4dc"), 1, 16))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button

func _button(text: String, color: Color, font_size: int) -> Button:
	return _build_button(text, color, font_size)

func _panel(fill: Color, border: Color, border_width: int, radius: int) -> Panel:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", _style(fill, border, border_width, radius))
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

func _style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.03, 0.18, 0.26, 0.22)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _exit_tree() -> void:
	if is_instance_valid(condor_audio):
		condor_audio.stop()
	if is_instance_valid(music_player):
		music_player.stop()
	for player in [success_player, error_player, click_player]:
		if is_instance_valid(player):
			player.stop()
