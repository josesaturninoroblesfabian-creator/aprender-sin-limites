extends Control

signal back_requested
signal story_completed(story_id: String)
signal activity_completed(story_id: String, mode: String)
const Repo = preload("res://scripts/stories/story_repository.gd")
const UI = preload("res://scripts/stories/story_ui.gd")
const Carmelo = preload("res://scripts/stories/carmelo_avatar.gd")

var initial_story: Dictionary = {}
var activity_mode := "read"
var story: Dictionary = {}
var story_pages: Array = []
var story_id := ""
var current_page_index := 0
var body: VBoxContainer
var title_label: Label
var counter_label: Label
var feedback_label: Label
var nav: HBoxContainer
var mode_buttons: Dictionary = {}
var continue_button: Button
var play_button: Button
var paragraph_label: RichTextLabel
var read_seen: Dictionary = {}
var listened: Dictionary = {}
var pending_page := -1
var active_timings: Array = []
var highlighted_word := -1
var auto_advance := true
var session_awarded: Dictionary = {}
var order_choices: Array = []
var order_selected: Array = []
var order_done := false
var question_index := 0
var solved_questions: Dictionary = {}
var mistaken_questions: Dictionary = {}
var wrong_options: Dictionary = {}
var quiz_points := 0
var quiz_done := false
var next_question_button: Button
var question_buttons: Array[Button] = []
var question_feedback := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story = Repo.find_story(String(initial_story.get("id", "")))
	if story.is_empty():
		story = Repo.all_stories()[0]
	story_pages = story.pages
	story_id = story.id
	if activity_mode not in Repo.MODES:
		activity_mode = "read"
	order_choices = story.order.duplicate()
	order_choices.shuffle()
	if order_choices == story.order:
		order_choices.reverse()
	StoryAudio.ended.connect(_on_audio_ended)
	_build_shell()
	_render()
	StoryAudio.guide(activity_mode, self)

func _build_shell() -> void:
	UI.background(self)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var layout := UI.column(margin, 10)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	header.custom_minimum_size.y = 76
	layout.add_child(header)
	var back := UI.button("‹ Biblioteca")
	back.custom_minimum_size.x = 150
	back.pressed.connect(_leave)
	header.add_child(back)
	var heading := UI.column(header, 2)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label = UI.label(story.title, 29, Color.WHITE)
	heading.add_child(title_label)
	counter_label = UI.label("", 17, Color("#ffdc8d"))
	heading.add_child(counter_label)
	var sound := UI.button("Sonido", Color("#7950b3"), 18)
	sound.pressed.connect(func():
		_cancel_audio()
		UI.sound_dialog(self)
	)
	header.add_child(sound)
	var avatar := Carmelo.new()
	avatar.custom_minimum_size = Vector2(95, 78)
	header.add_child(avatar)
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 8)
	layout.add_child(steps)
	for index in range(Repo.MODES.size()):
		var mode: String = Repo.MODES[index]
		var step := UI.button("%d. %s" % [index + 1, Repo.MODE_TITLES[mode]], Repo.MODE_COLORS[mode], 18)
		step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step.pressed.connect(_switch_mode.bind(mode))
		steps.add_child(step)
		mode_buttons[mode] = step
	body = VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	layout.add_child(body)
	feedback_label = UI.label("", 18, Color("#ffefc2"))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(feedback_label)
	nav = HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 12)
	layout.add_child(nav)

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		if child is Control:
			child.hide()
		child.queue_free()

func _render() -> void:
	_clear(body)
	_clear(nav)
	paragraph_label = null
	play_button = null
	continue_button = null
	feedback_label.text = ""
	for mode in mode_buttons:
		var selected: bool = mode == activity_mode
		mode_buttons[mode].modulate.a = 1.0 if selected else 0.72
		mode_buttons[mode].tooltip_text = "Actividad actual" if selected else "Seguir con este mismo cuento"
	match activity_mode:
		"read": _render_read()
		"listen": _render_listen()
		"order": _render_order()
		"quiz": _render_quiz()

func _switch_mode(mode: String) -> void:
	_cancel_audio()
	activity_mode = mode
	if mode == "read":
		current_page_index = current_page_index / 2 * 2
	_render()
	StoryAudio.guide(mode, self)

func _render_read() -> void:
	counter_label.text = "Historieta · Escenas %d–%d de 8 · Lee a tu ritmo" % [current_page_index + 1, mini(current_page_index + 2, 8)]
	var spread := HBoxContainer.new()
	spread.add_theme_constant_override("separation", 14)
	spread.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spread)
	for index in range(current_page_index, mini(current_page_index + 2, story_pages.size())):
		read_seen[index] = true
		var page: Dictionary = story_pages[index]
		var card := UI.panel()
		spread.add_child(card)
		var stack := UI.column(card, 7)
		stack.add_child(UI.label("%d · %s" % [index + 1, page.heading], 21, Color("#9b5429")))
		var art := UI.picture(Repo.page_texture(story, index), 150)
		stack.add_child(art)
		stack.add_child(UI.label(page.text, 19))
		var bubble := UI.panel(Color("#e7f3ff"), Color("#9dcee9"))
		bubble.add_theme_stylebox_override("panel", UI.style(Color("#e7f3ff"), Color("#9dcee9"), 15, 8))
		stack.add_child(bubble)
		bubble.add_child(UI.label(page.speech, 18, Color("#085d80")))
	var previous := _nav_button("‹ Anteriores", UI.BLUE, _change_page.bind(-1))
	previous.disabled = current_page_index == 0
	var listen_here := _nav_button("Escuchar estas escenas", Color("#118b74"), func():
		activity_mode = "listen"
		_render()
		_play_page()
	)
	listen_here.tooltip_text = "Cambiar a narración de este cuento"
	if current_page_index < 6:
		_nav_button("Siguientes ›", UI.BLUE, _change_page.bind(1))
	else:
		var finish := _nav_button("Terminar lectura ✓", Color("#19814e"), _finish_reading)
		finish.disabled = read_seen.size() < 8
	feedback_label.text = "Mira primero la imagen y después descubre qué pasó."

func _finish_reading() -> void:
	if read_seen.size() < 8:
		return
	if _complete("read"):
		feedback_label.text = "¡Recorriste todas las escenas! Puedes volver a leerlas cuando quieras."
		StoryAudio.guide("read_complete", self)
		_add_continue("Escuchar este cuento →", "listen")

func _render_listen() -> void:
	counter_label.text = "Narración · Escena %d de 8 · %d escuchadas completas" % [current_page_index + 1, listened.size()]
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 14)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(split)
	var art_card := UI.panel()
	art_card.size_flags_stretch_ratio = 0.9
	split.add_child(art_card)
	art_card.add_child(UI.picture(Repo.page_texture(story, current_page_index), 200))
	var text_card := UI.panel()
	text_card.size_flags_stretch_ratio = 1.15
	split.add_child(text_card)
	var stack := UI.column(text_card, 12)
	var page: Dictionary = story_pages[current_page_index]
	stack.add_child(UI.label(page.heading, 26, Color("#9b5429")))
	paragraph_label = RichTextLabel.new()
	paragraph_label.bbcode_enabled = true
	paragraph_label.scroll_active = true
	paragraph_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	paragraph_label.add_theme_font_size_override("normal_font_size", 25)
	paragraph_label.add_theme_color_override("default_color", UI.INK)
	paragraph_label.text = page.narration
	stack.add_child(paragraph_label)
	var auto := CheckButton.new()
	auto.text = "Continuar con la siguiente escena"
	auto.custom_minimum_size.y = 44
	auto.button_pressed = auto_advance
	for state in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
		auto.add_theme_color_override(state, UI.INK)
	auto.toggled.connect(func(value: bool): auto_advance = value)
	stack.add_child(auto)
	active_timings = []
	if FileAccess.file_exists(page.timings):
		var timing: Variant = JSON.parse_string(FileAccess.get_file_as_string(page.timings))
		if timing is Dictionary:
			active_timings = timing.get("words", [])
	highlighted_word = -1
	var previous := _nav_button("‹ Escena", UI.BLUE, _change_page.bind(-1))
	previous.disabled = current_page_index == 0
	play_button = _nav_button("▶ Reproducir", Color("#118b74"), _toggle_playback)
	_nav_button("Repetir", Color("#7950b3"), _play_page)
	var next := _nav_button("Escena ›", UI.BLUE, _change_page.bind(1))
	next.disabled = current_page_index == 7
	feedback_label.text = "Pulsa Reproducir. Las palabras se resaltan mientras Carmelo narra."
	if listened.size() == 8:
		_add_continue("Ordenar esta historia →", "order")

func _play_page() -> void:
	_cancel_audio()
	if StoryAudio.play(story_pages[current_page_index].audio, self):
		pending_page = current_page_index
		if is_instance_valid(play_button):
			play_button.text = "Ⅱ Pausar"
	else:
		feedback_label.text = "Activa la voz y sube el volumen en Sonido para escuchar."

func _toggle_playback() -> void:
	if pending_page == current_page_index and StoryAudio.owns(self):
		StoryAudio.pause_or_resume(self)
		play_button.text = "▶ Continuar" if StoryAudio.player.stream_paused else "Ⅱ Pausar"
	else:
		_play_page()

func _process(_delta: float) -> void:
	if activity_mode != "listen" or not is_instance_valid(paragraph_label) or pending_page < 0 or not StoryAudio.owns(self):
		return
	var position := StoryAudio.player.get_playback_position()
	var found := -1
	for index in range(active_timings.size()):
		if position >= float(active_timings[index].start) and position < float(active_timings[index].end):
			found = index
			break
	if found == highlighted_word:
		return
	highlighted_word = found
	var text: String = story_pages[current_page_index].narration
	if found < 0:
		paragraph_label.text = text
	else:
		var word: Dictionary = active_timings[found]
		var start := int(word["from"])
		var end := int(word["to"])
		paragraph_label.text = text.substr(0, start) + "[bgcolor=#ffe29a][b]" + text.substr(start, end - start) + "[/b][/bgcolor]" + text.substr(end)

func _on_audio_ended(path: String, completed: bool) -> void:
	if pending_page < 0 or pending_page >= story_pages.size() or path != story_pages[pending_page].audio:
		return
	var finished_page := pending_page
	pending_page = -1
	if is_instance_valid(play_button):
		play_button.text = "▶ Reproducir"
	if not completed or activity_mode != "listen":
		return
	listened[finished_page] = true
	counter_label.text = "Narración · Escena %d de 8 · %d escuchadas completas" % [current_page_index + 1, listened.size()]
	if listened.size() == 8:
		_complete("listen")
		feedback_label.text = "¡Escuchaste las ocho escenas completas!"
		_add_continue("Ordenar esta historia →", "order")
	elif auto_advance and finished_page < 7:
		current_page_index = finished_page + 1
		_render()
		_play_page()

func _cancel_audio() -> void:
	pending_page = -1
	StoryAudio.stop(self)

func _change_page(direction: int) -> void:
	var was_playing := activity_mode == "listen" and StoryAudio.owns(self) and StoryAudio.speaking()
	_cancel_audio()
	var step := 2 if activity_mode == "read" else 1
	current_page_index = clampi(current_page_index + direction * step, 0, 6 if activity_mode == "read" else 7)
	_render()
	if was_playing:
		_play_page()

func _render_order() -> void:
	counter_label.text = "Ordena cuatro momentos · Toca las imágenes desde el principio hasta el final"
	var instructions := UI.panel()
	body.add_child(instructions)
	instructions.add_child(UI.label("Toca una escena para añadirla a la fila. Tócala otra vez para quitarla.", 20))
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cards)
	for value in order_choices:
		var index := int(value)
		var card := UI.button("", Color("#fffaf0"))
		card.name = "Order_%d" % index
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.disabled = order_done
		card.add_theme_stylebox_override("normal", UI.style(Color("#fffaf0"), Color("#a982ce"), 20, 12))
		cards.add_child(card)
		var stack := VBoxContainer.new()
		stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack.offset_left = 12
		stack.offset_right = -12
		stack.offset_top = 12
		stack.offset_bottom = -12
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_theme_constant_override("separation", 8)
		card.add_child(stack)
		var place := order_selected.find(index)
		stack.add_child(UI.label("Posición %d" % (place + 1) if place >= 0 else "Toca para elegir", 19, Color("#7950b3")))
		stack.add_child(UI.picture(Repo.page_texture(story, index), 150))
		stack.add_child(UI.label(story_pages[index].heading, 21))
		card.pressed.connect(_pick_order.bind(index))
	var chosen := UI.panel(Color("#e9efff"))
	body.add_child(chosen)
	var titles: Array[String] = []
	for index in order_selected:
		titles.append(story_pages[index].heading)
	chosen.add_child(UI.label("Tu orden: " + (" → ".join(titles) if not titles.is_empty() else "elige la primera escena"), 19))
	_nav_button("Reiniciar", UI.BLUE, func():
		order_selected.clear()
		order_done = false
		_render()
	)
	var check := _nav_button("Comprobar orden", Color("#7950b3"), _check_order)
	check.disabled = order_selected.size() != 4 or order_done
	if order_done:
		feedback_label.text = "¡Correcto! Recordaste qué ocurrió antes y después."
		_add_continue("Responder preguntas →", "quiz")

func _pick_order(index: int) -> void:
	if order_done:
		return
	if order_selected.has(index):
		order_selected.erase(index)
	else:
		order_selected.append(index)
	_render()

func _check_order() -> void:
	if order_selected == story.order:
		order_done = true
		_complete("order")
		_render()
		StoryAudio.guide("success", self)
	else:
		feedback_label.text = "Revisa qué ocurrió al principio y qué cambió después. Puedes intentarlo otra vez."
		StoryAudio.guide("retry", self)

func _render_quiz() -> void:
	question_buttons.clear()
	if quiz_done:
		_render_quiz_result()
		return
	var question: Dictionary = story.questions[question_index]
	counter_label.text = "Pregunta %d de 4 · %d puntos en este intento" % [question_index + 1, quiz_points]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	var art := UI.panel()
	art.size_flags_stretch_ratio = 0.65
	row.add_child(art)
	var aside := UI.column(art, 10)
	aside.add_child(UI.picture(Repo.page_texture(story, int(question.evidence)), 150))
	aside.add_child(UI.label("Piensa en lo que pasó y en las decisiones de los personajes.", 20))
	var paper := UI.panel()
	paper.size_flags_stretch_ratio = 1.35
	row.add_child(paper)
	var stack := UI.column(paper, 12)
	stack.add_child(UI.label(question.prompt, 27))
	for choice in question.choices:
		var option := UI.button("", Color("#087fd0"))
		option.custom_minimum_size.y = 72
		var caption := UI.label(choice, 21, Color.WHITE)
		caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		caption.offset_left = 16
		caption.offset_right = -16
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		option.add_child(caption)
		option.disabled = solved_questions.has(question_index) or wrong_options.get(question_index, []).has(choice)
		option.pressed.connect(_answer.bind(String(choice)))
		question_buttons.append(option)
		stack.add_child(option)
	feedback_label.text = question_feedback
	_nav_button("Escuchar pregunta", Color("#118b74"), func():
		_cancel_audio()
		StoryAudio.play(question.audio, self)
	)
	_nav_button("Pista: volver a la escena", Color("#7950b3"), func():
		activity_mode = "read"
		current_page_index = int(question.evidence) / 2 * 2
		_cancel_audio()
		_render()
	)
	next_question_button = _nav_button("Terminar preguntas ✓" if question_index == 3 else "Siguiente pregunta ›", UI.BLUE, _next_question)
	next_question_button.disabled = not solved_questions.has(question_index)

func _answer(choice: String) -> void:
	if quiz_done or solved_questions.has(question_index):
		return
	_cancel_audio()
	var question: Dictionary = story.questions[question_index]
	if choice == question.answer:
		solved_questions[question_index] = true
		quiz_points += 5 if mistaken_questions.has(question_index) else 10
		question_feedback = "¡Bien pensado! " + question.explanation
	else:
		mistaken_questions[question_index] = true
		var wrong: Array = wrong_options.get(question_index, [])
		if choice not in wrong:
			wrong.append(choice)
		wrong_options[question_index] = wrong
		question_feedback = "Todavía no. Revisa la escena o prueba otra respuesta."
	_render()

func _next_question() -> void:
	if not solved_questions.has(question_index):
		return
	question_feedback = ""
	if question_index < 3:
		question_index += 1
	else:
		quiz_done = true
		_complete("quiz", quiz_points)
		StoryAudio.guide("quiz_complete", self)
	_render()

func _render_quiz_result() -> void:
	counter_label.text = "Preguntas terminadas · Comprender es más importante que acertar a la primera"
	var card := UI.panel()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(card)
	var stack := UI.column(card, 12)
	stack.add_child(UI.label("¡Una aventura comprendida!", 33, Color("#8a5518")))
	stack.add_child(UI.label("%d / 40 puntos en este intento" % quiz_points, 30))
	stack.add_child(UI.label("Mejor puntuación guardada: %d / 40" % Repo.best_score(story_id), 23))
	stack.add_child(UI.label("10 puntos al acertar a la primera; 5 al aprender después de un intento. Repetir mejora tu récord, sin sumar puntos infinitos.", 21))
	for mode in Repo.MODES:
		stack.add_child(UI.label(("✓ " if Repo.is_complete(story_id, mode) else "○ ") + Repo.MODE_TITLES[mode], 22, Repo.MODE_COLORS[mode]))
	_nav_button("Practicar preguntas otra vez", Color("#7950b3"), func():
		question_index = 0
		quiz_points = 0
		quiz_done = false
		solved_questions.clear()
		mistaken_questions.clear()
		wrong_options.clear()
		session_awarded.erase("quiz")
		_render()
	)
	_nav_button("Elegir otro cuento", UI.BLUE, _leave)

func _complete(mode: String, score: int = 0) -> bool:
	if mode == "read" and read_seen.size() < 8:
		return false
	if mode == "listen" and listened.size() < 8:
		return false
	if mode == "order" and not order_done:
		return false
	if mode == "quiz" and solved_questions.size() < 4:
		return false
	if not session_awarded.has(mode):
		if Repo.complete(story_id, mode, score) != OK:
			feedback_label.text = "La actividad terminó, pero no pudimos guardar. Inténtalo de nuevo."
			return false
		session_awarded[mode] = true
		activity_completed.emit(story_id, mode)
		if mode == "read":
			story_completed.emit(story_id)
	return true

func _nav_button(text: String, color: Color, callback: Callable) -> Button:
	var button := UI.button(text, color, 19)
	button.pressed.connect(callback)
	nav.add_child(button)
	return button

func _add_continue(text: String, mode: String) -> void:
	if is_instance_valid(continue_button):
		return
	continue_button = _nav_button(text, Color("#19814e"), _switch_mode.bind(mode))

func _leave() -> void:
	_cancel_audio()
	back_requested.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not UI.dismiss_modal(self):
			_leave()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	_cancel_audio()
