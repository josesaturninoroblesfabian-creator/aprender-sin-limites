extends Control

signal back_requested

const Carmelo = preload("res://scripts/stories/carmelo_avatar.gd")
const Repo = preload("res://scripts/stories/story_repository.gd")
const Ink := Color("#173b70")
const Gold := Color("#ffd34f")
const ROUND_COUNT := 3
const QUESTION_SECONDS := 20.0

var questions: Array[Dictionary] = []
var question_index := 0
var score := 0
var seconds_left := QUESTION_SECONDS
var answered := false
var progress_label: Label
var question_label: Label
var story_label: Label
var timer_label: Label
var feedback_label: Label
var options_grid: GridContainer
var next_button: Button
var result_panel: PanelContainer
var result_label: Label
var carmelo: TextureRect

func _ready() -> void:
	_build_ui()
	_load_questions()
	_show_question()
	StoryAudio.guide("welcome", self)

func _process(delta: float) -> void:
	if answered or question_index >= questions.size():
		return
	seconds_left = maxf(0.0, seconds_left - delta)
	_refresh_timer()
	if seconds_left <= 0.0:
		_on_time_up()

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/backgrounds/fondo-andes.png") as Texture2D
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.13, 0.28, 0.38)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for pair in [["margin_left", 20], ["margin_top", 14], ["margin_right", 20], ["margin_bottom", 14]]:
		margin.add_theme_constant_override(pair[0], pair[1])
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	_build_header(root)
	var instruction := PanelContainer.new()
	instruction.add_theme_stylebox_override("panel", _style(Color("#92502c"), Gold, 4, 18))
	root.add_child(instruction)
	instruction.add_child(_label("Responde preguntas sobre el cuento", 22, Color.WHITE, true))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	_build_carmelo(body)
	_build_quiz_panel(body)
	_build_footer(root)
	_build_result_panel(root)

func _build_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 82
	header.add_theme_constant_override("separation", 12)
	parent.add_child(header)
	var back := _button("⌂\nVolver al menú", Color("#985128"), Vector2(150, 68))
	back.pressed.connect(_go_back)
	header.add_child(back)
	var title_sign := PanelContainer.new()
	title_sign.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_sign.add_theme_stylebox_override("panel", _style(Color("#0c83d5"), Gold, 4, 24))
	header.add_child(title_sign)
	var title := _label("★ ¡Reto Rápido! ★", 38, Color("#fff26b"), true)
	title.add_theme_color_override("font_outline_color", Color("#173eaa"))
	title.add_theme_constant_override("outline_size", 7)
	title_sign.add_child(title)
	var progress_panel := PanelContainer.new()
	progress_panel.custom_minimum_size = Vector2(180, 76)
	progress_panel.add_theme_stylebox_override("panel", _style(Color("#0876c9"), Gold, 4, 20))
	header.add_child(progress_panel)
	progress_label = _label("Progreso 1 de 3\n⭐  🧩  🧩", 17, Color.WHITE, true)
	progress_panel.add_child(progress_label)

func _build_carmelo(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 205
	panel.add_theme_stylebox_override("panel", _style(Color("#fff5df"), Color("#db9c44"), 4, 23))
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 6)
	panel.add_child(stack)
	carmelo = Carmelo.new()
	carmelo.texture = load("res://assets/carmelo-personaje.png") as Texture2D
	carmelo.custom_minimum_size = Vector2(0, 280)
	stack.add_child(carmelo)
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", _style(Color.WHITE, Color("#087fd0"), 3, 22))
	stack.add_child(bubble)
	var speech := _label("¡Rápido, rápido! ¿Cuál es la respuesta correcta?", 17, Ink, true)
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(speech)

func _build_quiz_panel(parent: HBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "PanelPregunta"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color("#fff3d7"), Color("#b97232"), 7, 27))
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	story_label = _label("Cuento", 16, Color("#a34b25"), true)
	content.add_child(story_label)
	question_label = _label("¿Cuál es la respuesta?", 27, Color("#61351d"), true)
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(question_label)
	options_grid = GridContainer.new()
	options_grid.columns = 3
	options_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	options_grid.add_theme_constant_override("h_separation", 12)
	options_grid.add_theme_constant_override("v_separation", 12)
	content.add_child(options_grid)

func _build_footer(parent: VBoxContainer) -> void:
	# Use a full-width Control and anchor the timer independently of the next
	# button. In an HBox, two expanding spacers can compress the timer on small
	# window sizes and stack its label one character per line.
	var footer := Control.new()
	footer.custom_minimum_size.y = 64
	parent.add_child(footer)
	var timer_center := CenterContainer.new()
	timer_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	footer.add_child(timer_center)
	var hourglass := PanelContainer.new()
	hourglass.custom_minimum_size = Vector2(260, 58)
	hourglass.add_theme_stylebox_override("panel", _style(Color("#fff5df"), Gold, 3, 18))
	timer_center.add_child(hourglass)
	var timer_stack := HBoxContainer.new()
	timer_stack.add_theme_constant_override("separation", 8)
	timer_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	hourglass.add_child(timer_stack)
	var timer_title := _label("⌛ ¡Tiempo!", 19, Ink, true)
	timer_title.custom_minimum_size.x = 128
	timer_stack.add_child(timer_title)
	timer_label = _label("20 s", 23, Color("#e45b2c"), true)
	timer_label.custom_minimum_size.x = 54
	timer_stack.add_child(timer_label)
	next_button = _button("¡Siguiente! ➜", Color("#20b84c"), Vector2(205, 54))
	next_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	next_button.offset_left = -205
	next_button.offset_top = -27
	next_button.offset_right = 0
	next_button.offset_bottom = 27
	next_button.visible = false
	next_button.pressed.connect(_next_question)
	footer.add_child(next_button)

func _build_result_panel(parent: VBoxContainer) -> void:
	result_panel = PanelContainer.new()
	result_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_panel.add_theme_stylebox_override("panel", _style(Color("#fff3d7"), Gold, 5, 28))
	result_panel.visible = false
	parent.add_child(result_panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	result_panel.add_child(stack)
	result_label = _label("", 34, Ink, true)
	stack.add_child(result_label)
	var replay := _button("↻  Jugar otra vez", Color("#f2a92e"), Vector2(230, 58))
	replay.pressed.connect(_restart)
	stack.add_child(replay)
	var back := _button("⌂  Volver a Cuentos", Color("#985128"), Vector2(230, 58))
	back.pressed.connect(_go_back)
	stack.add_child(back)

func _load_questions() -> void:
	for story in Repo.all_stories():
		var story_questions: Variant = story.get("questions", [])
		if story_questions is Array:
			for question in story_questions:
				if question is Dictionary and question.get("choices", []).size() >= 2:
					var item: Dictionary = question.duplicate(true)
					item["story_title"] = String(story.get("title", "Cuento"))
					item["story_id"] = String(story.get("id", ""))
					questions.append(item)
	questions.shuffle()
	if questions.size() > ROUND_COUNT:
		questions.resize(ROUND_COUNT)

func _show_question() -> void:
	if question_index >= questions.size():
		_finish_quiz()
		return
	answered = false
	seconds_left = QUESTION_SECONDS
	next_button.visible = false
	var question: Dictionary = questions[question_index]
	question_label.text = String(question.get("prompt", "¿Cuál es la respuesta?"))
	story_label.text = "📖  " + String(question.get("story_title", "Cuento"))
	progress_label.text = "Progreso %d de %d\n%s" % [question_index + 1, ROUND_COUNT, _stars_for_round(question_index)]
	for child in options_grid.get_children():
		options_grid.remove_child(child)
		child.queue_free()
	var choices: Array = question.get("choices", []).duplicate()
	choices.shuffle()
	for index in range(choices.size()):
		options_grid.add_child(_build_option(String(choices[index]), index))
	_refresh_timer()

func _build_option(choice: String, index: int) -> Button:
	var colors := [Color("#e75486"), Color("#29a8dc"), Color("#f0a834")]
	var button := Button.new()
	button.name = "Opcion_%d" % index
	button.set_meta("choice", choice)
	button.custom_minimum_size = Vector2(170, 182)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _style(Color.WHITE, colors[index % colors.size()], 5, 22))
	button.add_theme_stylebox_override("hover", _style(Color("#fffaf0"), Gold, 6, 22))
	button.add_theme_stylebox_override("pressed", _style(Color("#f4ead7"), colors[index % colors.size()].darkened(0.15), 4, 22))
	button.add_theme_stylebox_override("disabled", _style(Color.WHITE, colors[index % colors.size()], 4, 22))
	button.text = ""
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Ink)
	button.add_theme_color_override("font_disabled_color", Ink)
	_font(button, 700)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10
	content.offset_top = 10
	content.offset_right = -10
	content.offset_bottom = -10
	content.add_theme_constant_override("separation", 6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	var artwork_frame := PanelContainer.new()
	artwork_frame.custom_minimum_size = Vector2(0, 112)
	artwork_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	artwork_frame.clip_contents = true
	artwork_frame.add_theme_stylebox_override("panel", _style(Color("#eaf6ff"), Color("#d5e3ef"), 2, 15))
	artwork_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(artwork_frame)
	var artwork := TextureRect.new()
	artwork.name = "IlustracionRespuesta"
	artwork.texture = _illustration_for_choice(choice)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.offset_left = 3
	artwork.offset_top = 3
	artwork.offset_right = -3
	artwork.offset_bottom = -3
	artwork_frame.add_child(artwork)
	var answer_label := _label(choice, 19, Ink, true)
	answer_label.name = "TextoRespuesta"
	answer_label.custom_minimum_size = Vector2(0, 42)
	answer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(answer_label)
	button.pressed.connect(_choose_answer.bind(choice, button))
	return button

func _choose_answer(choice: String, selected: Button) -> void:
	if answered:
		return
	answered = true
	var question: Dictionary = questions[question_index]
	var correct_answer := String(question.get("answer", ""))
	var correct := choice == correct_answer
	if correct:
		score += 1
		selected.add_theme_stylebox_override("disabled", _style(Color("#d5f6d7"), Color("#28a84a"), 6, 22))
		StoryAudio.guide("progress", self)
	else:
		selected.add_theme_stylebox_override("disabled", _style(Color("#ffe0df"), Color("#e0524d"), 6, 22))
		StoryAudio.guide("retry", self)
	for child in options_grid.get_children():
		if child is Button:
			child.disabled = true
			if String(question.get("answer", "")) == String(child.get_meta("choice", "")):
				child.add_theme_stylebox_override("disabled", _style(Color("#d5f6d7"), Color("#28a84a"), 6, 22))
	next_button.visible = true
	if correct:
		next_button.text = "¡Correcto! Siguiente ➜"
	else:
		next_button.text = "La respuesta era: %s  ➜" % correct_answer

func _on_time_up() -> void:
	if answered:
		return
	answered = true
	for child in options_grid.get_children():
		if child is Button:
			child.disabled = true
			if String(questions[question_index].get("answer", "")) == String(child.get_meta("choice", "")):
				child.add_theme_stylebox_override("disabled", _style(Color("#d5f6d7"), Color("#28a84a"), 6, 22))
	next_button.text = "¡Se acabó el tiempo! ➜"
	next_button.visible = true
	StoryAudio.guide("retry", self)

func _next_question() -> void:
	question_index += 1
	if question_index < questions.size():
		_show_question()
	else:
		_finish_quiz()

func _finish_quiz() -> void:
	options_grid.visible = false
	question_label.visible = false
	story_label.visible = false
	next_button.visible = false
	result_panel.visible = true
	progress_label.text = "¡Completado!\n⭐  ⭐  ⭐"
	result_label.text = "¡Reto terminado!\nAcertaste %d de %d preguntas.\n%s" % [score, questions.size(), "🏆" if score == questions.size() else "⭐"]
	StoryAudio.guide("success", self)

func _restart() -> void:
	questions.clear()
	question_index = 0
	score = 0
	result_panel.visible = false
	options_grid.visible = true
	question_label.visible = true
	story_label.visible = true
	_load_questions()
	_show_question()

func _refresh_timer() -> void:
	if timer_label == null:
		return
	timer_label.text = "%02d s" % ceili(seconds_left)
	timer_label.add_theme_color_override("font_color", Color("#e0524d") if seconds_left <= 5.0 else Color("#e45b2c"))

func _stars_for_round(index: int) -> String:
	var result := ""
	for badge in range(ROUND_COUNT):
		result += "⭐  " if badge < index else "🧩  "
	return result.strip_edges()

func _icon_for_choice(choice: String) -> String:
	var normalized := choice.to_lower()
	if "lobo" in normalized or "zorro" in normalized:
		return "🐺"
	if "abuela" in normalized or "mujer" in normalized:
		return "👵"
	if "niñ" in normalized or "caperucita" in normalized:
		return "🧒"
	if "oso" in normalized:
		return "🐻"
	if "vecino" in normalized or "campesino" in normalized or "guardabosques" in normalized:
		return "🧑‍🌾"
	if "casa" in normalized or "ladrillo" in normalized:
		return "🏠"
	if "ratón" in normalized or "raton" in normalized:
		return "🐭"
	if "patito" in normalized or "cisne" in normalized:
		return "🦢"
	return "✨"

func _illustration_for_choice(choice: String) -> Texture2D:
	var normalized := choice.to_lower()
	var question: Dictionary = questions[question_index]
	var current_story_id := String(question.get("story_id", ""))
	var story_id := current_story_id
	if "lobo" in normalized or "zorro" in normalized:
		story_id = "caperucita_roja"
	elif "oso" in normalized:
		story_id = "ricitos_de_oro"
	elif "abuela" in normalized or "niñ" in normalized or "caperucita" in normalized:
		story_id = "caperucita_roja"
	elif "paja" in normalized or "ladrillo" in normalized or "chanchito" in normalized or "casa" in normalized:
		story_id = "tres_chanchitos"
	elif "cisne" in normalized or "patito" in normalized or "río" in normalized or "rio" in normalized:
		story_id = "patito_feo"
	elif "ratón" in normalized or "raton" in normalized or "león" in normalized or "leon" in normalized:
		story_id = "leon_y_raton"
	elif "sol" in normalized or "viento" in normalized:
		story_id = "el_viento_y_el_sol"
	var story := Repo.find_story(story_id)
	if story.is_empty():
		var stories := Repo.all_stories()
		if stories.is_empty():
			return null
		story = stories[0]
	if story_id == current_story_id:
		# Use the evidence scene for the right answer and different scenes from
		# the same cuento for distractors, so all three cards have visible art.
		var evidence_page := clampi(int(question.get("evidence", 0)), 0, 7)
		var page_index := evidence_page
		if choice != String(question.get("answer", "")):
			var choices: Array = question.get("choices", [])
			var choice_index: int = maxi(0, choices.find(choice))
			page_index = posmod(evidence_page + choice_index + 1, 8)
			if page_index == evidence_page:
				page_index = posmod(page_index + 1, 8)
		return Repo.page_texture(story, page_index)
	# The catalog provides dedicated cover art. Loading that path directly avoids
	# depending on atlas cropping/import state for the option illustrations.
	var cover_path := String(story.get("cover", ""))
	if not cover_path.is_empty():
		var cover := ResourceLoader.load(cover_path) as Texture2D
		if cover != null:
			return cover
	return Repo.cover_texture(story)

func _go_back() -> void:
	StoryAudio.stop(self)
	back_requested.emit()

func _button(text: String, color: Color, minimum: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(color, Color("#fff0b4"), 3, 19))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.12), Gold, 4, 19))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_font(button, 700)
	return button

func _label(text: String, size: int, color: Color, centered: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_font(label, 700)
	return label

func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(9)
	return style

func _font(control: Control, weight: int) -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Baloo 2", "Trebuchet MS", "Arial"])
	font.font_weight = weight
	font.fallbacks = [ThemeDB.fallback_font]
	control.add_theme_font_override("font", font)
