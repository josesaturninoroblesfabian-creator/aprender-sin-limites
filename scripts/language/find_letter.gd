extends Control

## Minijuego Encuentra la letra: tres aciertos por cada letra del abecedario.
signal close_requested

const Alphabet = preload("res://scripts/language/alphabet.gd")
const LETTERS: Array = Alphabet.LETTERS
const SAVE_PATH := "user://progreso_encuentra_letra.cfg"
const TOTAL_EXERCISES := 81
const CHOICES_PER_ROUND := 18
const SAMPLE_RATE := 22050
const BUBBLE_COLORS := [
	Color("#47c6ec"), Color("#ff7d91"), Color("#9b72e8"), Color("#43c98b"),
	Color("#ffb845"), Color("#5d9df5"), Color("#f27c43"), Color("#36c7b5")
]

var rng := RandomNumberGenerator.new()
var hits_by_letter: Dictionary = {}
var current_letter_index := 0
var total_hits := 0
var choices_grid: GridContainer
var target_label: Label
var hit_label: Label
var progress_label: Label
var progress_fill: Panel
var feedback_label: Label
var star_labels: Array[Label] = []
var alphabet_tiles: Array[Label] = []
var sound_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var music_button: Button
var victory_layer: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rng.randomize()
	_load_progress()
	_build_screen()
	_refresh_round()
	_play_music()

func _build_screen() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/backgrounds/fondo-paisaje-andino.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var wash := ColorRect.new()
	wash.color = Color(0.28, 0.20, 0.48, 0.34)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var header := _panel(Color("#a969d5"), Color.WHITE, 3, 24)
	_place(header, 0.025, 0.018, 0.95, 0.10)
	add_child(header)
	var back := _button("←  Volver a Lenguaje", Color("#ef941c"), 17)
	_place(back, 0.012, 0.12, 0.25, 0.76)
	back.pressed.connect(func(): close_requested.emit())
	header.add_child(back)
	var title := _label("🔎  ENCUENTRA LA LETRA", 27, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(title, 0.27, 0.10, 0.48, 0.80)
	header.add_child(title)
	music_button = _button("♫ Música", Color("#4c9ce8"), 14)
	_place(music_button, 0.79, 0.16, 0.18, 0.68)
	music_button.pressed.connect(_toggle_music)
	header.add_child(music_button)

	var progress_card := _panel(Color("#f7f5ff"), Color("#b6a0ed"), 3, 20)
	_place(progress_card, 0.07, 0.135, 0.86, 0.11)
	add_child(progress_card)
	progress_label = _label("Progreso del abecedario: 0 / 81", 19, Color("#254b7b"))
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(progress_label, 0.025, 0.04, 0.56, 0.40)
	progress_card.add_child(progress_label)
	var track := _panel(Color("#d9e7f2"), Color("#a8cce0"), 1, 12)
	_place(track, 0.025, 0.53, 0.95, 0.31)
	progress_card.add_child(track)
	progress_fill = _panel(Color("#38c991"), Color("#a6f3cf"), 1, 12)
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(progress_fill, 0.012, 0.12, 0.001, 0.76)
	track.add_child(progress_fill)

	var prompt := _panel(Color("#fffdf6"), Color("#ffc947"), 4, 24)
	_place(prompt, 0.075, 0.265, 0.85, 0.115)
	add_child(prompt)
	target_label = _label("¡Busca la letra A!", 31, Color("#195b88"))
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(target_label, 0.03, 0.06, 0.62, 0.84)
	prompt.add_child(target_label)
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 6)
	_place(stars, 0.70, 0.02, 0.26, 0.60)
	prompt.add_child(stars)
	for _i in range(3):
		var star := _label("★", 33, Color("#d2d8df"))
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star.custom_minimum_size = Vector2(42, 42)
		star_labels.append(star)
		stars.add_child(star)
	hit_label = _label("Aciertos: 0 / 3", 15, Color("#47627b"))
	hit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(hit_label, 0.70, 0.64, 0.26, 0.28)
	prompt.add_child(hit_label)

	var board := _panel(Color("#ffd779"), Color("#fff8d9"), 4, 28)
	_place(board, 0.075, 0.405, 0.85, 0.46)
	add_child(board)
	choices_grid = GridContainer.new()
	choices_grid.columns = 6
	choices_grid.add_theme_constant_override("h_separation", 14)
	choices_grid.add_theme_constant_override("v_separation", 9)
	choices_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	choices_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(choices_grid)
	board.add_child(center)
	feedback_label = _label("Toca la letra que buscas.", 16, Color("#5d4b38"))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(feedback_label, 0.03, 0.90, 0.94, 0.08)
	board.add_child(feedback_label)

	var alphabet_panel := _panel(Color("#f8f4ff"), Color.WHITE, 3, 18)
	_place(alphabet_panel, 0.035, 0.885, 0.93, 0.095)
	add_child(alphabet_panel)
	var alphabet_row := HBoxContainer.new()
	alphabet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	alphabet_row.add_theme_constant_override("separation", 3)
	_place(alphabet_row, 0.012, 0.08, 0.976, 0.84)
	alphabet_panel.add_child(alphabet_row)
	for letter in LETTERS:
		var tile := _label(String(letter), 15, Color("#7b7b91"))
		tile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("normal", _style(Color("#e9e8f1"), Color.WHITE, 1, 8))
		alphabet_tiles.append(tile)
		alphabet_row.add_child(tile)

	sound_player = AudioStreamPlayer.new()
	sound_player.name = "Efectos"
	add_child(sound_player)
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicaRetro"
	music_player.stream = _make_tone_stream([523.25, 659.25, 783.99, 659.25, 587.33, 698.46, 880.0, 698.46, 523.25, 659.25, 783.99, 1046.5, 880.0, 783.99, 659.25, 523.25], 0.18, 0.095, true)
	music_player.volume_db = -7.0
	add_child(music_player)

func _refresh_round() -> void:
	if current_letter_index >= LETTERS.size():
		_show_victory()
		return
	var letter := String(LETTERS[current_letter_index])
	var hits := int(hits_by_letter.get(letter, 0))
	target_label.text = "¡Busca la letra %s!" % letter
	hit_label.text = "Aciertos: %d / 3" % hits
	progress_label.text = "Progreso del abecedario: %d / %d" % [total_hits, TOTAL_EXERCISES]
	progress_fill.visible = total_hits > 0
	progress_fill.anchor_right = 0.012 + 0.976 * float(total_hits) / TOTAL_EXERCISES
	feedback_label.text = "¡Muy bien! Sigue buscando." if hits > 0 else "Toca la letra que buscas."
	feedback_label.add_theme_color_override("font_color", Color("#5d4b38"))
	for i in range(star_labels.size()):
		star_labels[i].add_theme_color_override("font_color", Color("#ffbf18") if i < hits else Color("#d2d8df"))
	for i in range(alphabet_tiles.size()):
		var tile := alphabet_tiles[i]
		var tile_letter := String(LETTERS[i])
		var finished := int(hits_by_letter.get(tile_letter, 0)) >= 3
		tile.add_theme_color_override("font_color", Color("#ffffff") if i == current_letter_index or finished else Color("#7b7b91"))
		tile.add_theme_stylebox_override("normal", _style(Color("#4c9ce8") if i == current_letter_index else Color("#48c894") if finished else Color("#e9e8f1"), Color.WHITE, 1, 8))
	_build_bubbles(letter)

func _build_bubbles(target: String) -> void:
	for child in choices_grid.get_children():
		choices_grid.remove_child(child)
		child.queue_free()
	var options: Array[String] = []
	options.append(target)
	var distractors: Array[String] = []
	for letter in LETTERS:
		if String(letter) != target:
			distractors.append(String(letter))
	distractors.shuffle()
	for i in range(CHOICES_PER_ROUND - 1):
		options.append(distractors[i])
	options.shuffle()
	for option in options:
		var bubble := Button.new()
		bubble.text = option
		bubble.custom_minimum_size = Vector2(92, 76)
		bubble.add_theme_font_size_override("font_size", 30)
		bubble.add_theme_color_override("font_color", Color.WHITE)
		bubble.add_theme_color_override("font_hover_color", Color.WHITE)
		bubble.add_theme_stylebox_override("normal", _style(BUBBLE_COLORS[rng.randi_range(0, BUBBLE_COLORS.size() - 1)], Color("#ffffff"), 3, 40))
		var base_style := bubble.get_theme_stylebox("normal") as StyleBoxFlat
		var hover_style := base_style.duplicate() as StyleBoxFlat
		hover_style.bg_color = hover_style.bg_color.lightened(0.13)
		hover_style.border_color = Color("#fff6ac")
		bubble.add_theme_stylebox_override("hover", hover_style)
		bubble.add_theme_stylebox_override("pressed", _style(Color("#ffca52"), Color.WHITE, 3, 40))
		bubble.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		bubble.pressed.connect(_on_bubble_pressed.bind(option))
		choices_grid.add_child(bubble)
		bubble.modulate.a = 0.0
		var appear := create_tween().bind_node(bubble)
		appear.tween_property(bubble, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_bubble_pressed(letter: String) -> void:
	if current_letter_index >= LETTERS.size():
		return
	var target := String(LETTERS[current_letter_index])
	if letter == target:
		_play_success()
		var hits := int(hits_by_letter.get(target, 0)) + 1
		hits_by_letter[target] = hits
		total_hits += 1
		_save_progress()
		if hits >= 3:
			current_letter_index += 1
		if total_hits >= TOTAL_EXERCISES:
			_show_victory()
		else:
			_refresh_round()
			if hits >= 3:
				feedback_label.text = "¡Letra completada! Ahora busca %s." % LETTERS[current_letter_index]
	else:
		_play_error()
		feedback_label.text = "Casi… intenta con la letra %s." % target
		feedback_label.add_theme_color_override("font_color", Color("#a34a55"))

func _show_victory() -> void:
	if is_instance_valid(victory_layer):
		return
	progress_label.text = "Progreso del abecedario: %d / %d" % [TOTAL_EXERCISES, TOTAL_EXERCISES]
	progress_fill.visible = true
	progress_fill.anchor_right = 0.988
	for star in star_labels:
		star.add_theme_color_override("font_color", Color("#ffbf18"))
	for tile in alphabet_tiles:
		tile.add_theme_color_override("font_color", Color.WHITE)
		tile.add_theme_stylebox_override("normal", _style(Color("#48c894"), Color.WHITE, 1, 8))
	victory_layer = Control.new()
	victory_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(victory_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.12, 0.08, 0.25, 0.66)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory_layer.add_child(shade)
	var confetti := CPUParticles2D.new()
	confetti.position = get_viewport_rect().size * 0.5
	confetti.amount = 110
	confetti.lifetime = 3.0
	confetti.one_shot = true
	confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confetti.emission_rect_extents = Vector2(get_viewport_rect().size.x * 0.47, 12)
	confetti.position = Vector2(get_viewport_rect().size.x * 0.5, 0)
	confetti.explosiveness = 0.12
	confetti.direction = Vector2(0, 1)
	confetti.spread = 32.0
	confetti.initial_velocity_min = 80.0
	confetti.initial_velocity_max = 190.0
	confetti.gravity = Vector2(0, 220)
	confetti.scale_amount_min = 3.0
	confetti.scale_amount_max = 8.0
	var colors := Gradient.new()
	colors.set_color(0, Color("#ffd63b"))
	colors.add_point(0.25, Color("#ff5687"))
	colors.add_point(0.5, Color("#36c7ed"))
	colors.add_point(0.75, Color("#49d38c"))
	confetti.color_ramp = colors
	victory_layer.add_child(confetti)
	confetti.emitting = true
	var card := _panel(Color("#fffdf4"), Color("#ffc932"), 5, 30)
	_place(card, 0.27, 0.24, 0.46, 0.52)
	victory_layer.add_child(card)
	var trophy := _label("🏆", 78, Color.WHITE)
	trophy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(trophy, 0.12, 0.04, 0.76, 0.36)
	card.add_child(trophy)
	var message := _label("¡Lo lograste!\nEncontraste las 27 letras.", 28, Color("#155487"))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(message, 0.06, 0.40, 0.88, 0.27)
	card.add_child(message)
	var replay := _button("Volver a jugar", Color("#31bd7b"), 20)
	_place(replay, 0.08, 0.75, 0.39, 0.16)
	replay.pressed.connect(_restart_game)
	card.add_child(replay)
	var close := _button("Volver al curso", Color("#3988e8"), 18)
	_place(close, 0.53, 0.75, 0.39, 0.16)
	close.pressed.connect(func(): close_requested.emit())
	card.add_child(close)
	_play_success()

func _restart_game() -> void:
	if is_instance_valid(victory_layer):
		victory_layer.queue_free()
	victory_layer = null
	hits_by_letter.clear()
	current_letter_index = 0
	total_hits = 0
	_save_progress()
	_refresh_round()

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved: Variant = config.get_value("encuentra", "aciertos", {})
	if saved is Dictionary:
		for letter in LETTERS:
			hits_by_letter[String(letter)] = clampi(int(saved.get(String(letter), 0)), 0, 3)
	for letter in LETTERS:
		total_hits += int(hits_by_letter.get(String(letter), 0))
		if current_letter_index == LETTERS.find(letter) and int(hits_by_letter.get(String(letter), 0)) >= 3:
			current_letter_index += 1

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("encuentra", "aciertos", hits_by_letter)
	config.set_value("encuentra", "total", total_hits)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("No se pudo guardar el progreso de Encuentra la letra: %s" % error_string(error))

func _play_success() -> void:
	if is_instance_valid(sound_player):
		sound_player.stream = _make_tone_stream([659.25, 783.99, 1046.5], 0.09, 0.30)
		sound_player.play()

func _play_error() -> void:
	if is_instance_valid(sound_player):
		sound_player.stream = _make_tone_stream([293.66, 246.94], 0.12, 0.22)
		sound_player.play()

func _play_music() -> void:
	if is_instance_valid(music_player) and not music_player.playing:
		music_player.play()

func _toggle_music() -> void:
	if music_player.playing:
		music_player.stop()
		music_button.text = "♫ Música: apagada"
	else:
		_play_music()
		music_button.text = "♫ Música"

func _make_tone_stream(frequencies: Array, note_seconds: float, amplitude: float, looped: bool = false) -> AudioStreamWAV:
	var frames_per_note := maxi(1, int(SAMPLE_RATE * note_seconds))
	var total_frames := frames_per_note * frequencies.size()
	var data := PackedByteArray()
	data.resize(total_frames * 2)
	for note_index in range(frequencies.size()):
		var frequency := float(frequencies[note_index])
		for frame_index in range(frames_per_note):
			var t := float(frame_index) / SAMPLE_RATE
			var envelope := minf(1.0, minf(float(frame_index) / 120.0, float(frames_per_note - frame_index) / 220.0))
			var phase := fposmod(t * frequency, 1.0)
			var square := 1.0 if phase < 0.5 else -1.0
			var sample := int(round(clampf(square * amplitude * envelope, -1.0, 1.0) * 32767.0))
			data.encode_s16((note_index * frames_per_note + frame_index) * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = total_frames
	return stream

func _button(text: String, color: Color, font_size: int) -> Button:
	var result := Button.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color.WHITE)
	result.add_theme_color_override("font_hover_color", Color.WHITE)
	result.add_theme_color_override("font_pressed_color", Color.WHITE)
	result.add_theme_stylebox_override("normal", _style(color, Color.WHITE, 2, 15))
	result.add_theme_stylebox_override("hover", _style(color.lightened(0.12), Color("#fff176"), 3, 15))
	result.add_theme_stylebox_override("pressed", _style(color.darkened(0.12), Color.WHITE, 2, 15))
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return result

func _panel(fill: Color, border: Color, width: int, radius: int) -> Panel:
	var result := Panel.new()
	result.add_theme_stylebox_override("panel", _style(fill, border, width, radius))
	return result

func _label(text: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
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

func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.05, 0.11, 0.23, 0.26)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _exit_tree() -> void:
	if is_instance_valid(music_player):
		music_player.stop()
	if is_instance_valid(sound_player):
		sound_player.stop()
