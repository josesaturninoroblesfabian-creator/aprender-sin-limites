extends Control

signal back_requested
const UI = preload("res://scripts/math/math_ui.gd")
const Guide = preload("res://scripts/math/llama_guide.gd")
const Art = preload("res://scripts/geometry/geometry_art.gd")
const Catalog = preload("res://scripts/geometry/geometry_catalog.gd")
const Rules = preload("res://scripts/geometry/geometry_rules.gd")
const Shapes = preload("res://scripts/geometry/geometry_shapes.gd")
const Progress = preload("res://scripts/geometry/geometry_progress.gd")
const Board = preload("res://scripts/geometry/geometry_board.gd")
const Solid = preload("res://scripts/geometry/solid_view.gd")
const Tile = preload("res://scripts/geometry/geometry_tile.gd")
const Preview = preload("res://scripts/geometry/geometry_preview.gd")
const Flight = preload("res://scripts/geometry/geometry_flight.gd")
const Audio = preload("res://scripts/geometry/geometry_audio.gd")

var topic_id := "flat_shapes"
var view := ""
var audio: Node
var background: TextureRect
var content: VBoxContainer
var navigation: HBoxContainer
var heading: Label
var subtitle: Label
var status: Label
var back_button: Button
var pause_button: Button
var dialog: Control
var dialog_kind := ""
var lesson: Dictionary = {}
var question: Dictionary = {}
var answers: Dictionary = {}
var wrong: Array = []
var hinted: Array = []
var round_index := 0
var solved_current := false
var model_done := false
var world: Control
var solid: Control
var guide_text: Label
var next_button: Button
var choices: Array[Button] = []
var difficulty := 1
var duration := 0
var time_left := 0.0
var score := 0
var questions: Array[Dictionary] = []

func _ready() -> void:
	audio = Audio.new()
	add_child(audio)
	_build_shell()
	if topic_id in Catalog.TOPICS: _show_hub()
	else: _show_setup()
	audio.speak(topic_id)

func _clear(next_view: String) -> void:
	_close_dialog()
	audio.stop()
	_pause_world(true)
	_clear_children(content)
	_clear_children(navigation)
	world = null
	solid = null
	guide_text = null
	next_button = null
	choices.clear()
	view = next_view
	solved_current = false
	background.texture = Art.backdrop(3 if view == "sky" else 1 if topic_id == "find_shape" else 2 if topic_id == "build_pattern" else 0)
	back_button.text = "‹ Geometría" if view in ["hub", "setup"] else "‹ Misiones" if topic_id in Catalog.TOPICS else "‹ Preparar"
	pause_button.visible = view == "sky"
	status.text = ""
	subtitle.text = "Explora las formas y sus partes"

func _show_hub() -> void:
	_clear("hub")
	var instruction := UI.paper(content, Color("#fff5d7"))
	instruction.add_child(UI.text("Elige una misión: primero un ejemplo, después cinco retos.", 24))
	var row := UI.row(content, 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for item in Catalog.lessons(topic_id):
		var stack := UI.paper(row)
		var preview := Preview.new()
		preview.question = item.model
		preview.custom_minimum_size = Vector2(130, 125)
		stack.add_child(preview)
		stack.add_child(UI.text(item.title, 21, Catalog.COLORS[topic_id]))
		var aim := UI.text(item.aim, 18)
		aim.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stack.add_child(aim)
		stack.add_child(UI.text(UI.stars(Progress.stars(item.id)), 26, Color("#986000")))
		var partial := Progress.resume(item.id)
		var launch := UI.button("Continuar" if not partial.is_empty() else "Volver a jugar" if Progress.complete(item.id) else "Descubrir", Catalog.COLORS[topic_id], 19)
		launch.pressed.connect(_start_lesson.bind(String(item.id)))
		stack.add_child(launch)
	status.text = "Las estrellas se ganan al resolver la misión. Puedes repetir y mejorar."

func _start_lesson(id: String) -> void:
	lesson = Catalog.find(id)
	var partial := Progress.resume(id)
	answers = partial.get("answers", {})
	wrong = partial.get("wrong", [])
	hinted = partial.get("hinted", [])
	if answers.size() == 5: _finish_lesson()
	elif partial.is_empty(): _show_model()
	else: _begin_practice()

func _show_model() -> void:
	_save_attempt()
	question = lesson.model
	model_done = false
	_render_stage("model")
	subtitle.text = "Ejemplo guiado · prueba antes de practicar"
	next_button.text = "Practicar cinco retos"
	next_button.disabled = true

func _begin_practice() -> void:
	var partial := Progress.resume(lesson.id)
	answers = partial.get("answers", answers)
	wrong = partial.get("wrong", wrong)
	hinted = partial.get("hinted", hinted)
	round_index = 0
	while round_index < 5 and answers.has(lesson.questions[round_index].id): round_index += 1
	if round_index == 5:
		_finish_lesson()
		return
	question = lesson.questions[round_index]
	_render_stage("practice")
	var draft: Dictionary = partial.get("draft", {})
	if is_instance_valid(world) and world is Board and draft.get("id", "") == question.id:
		world.restore(draft.get("state", {}))
		if world.is_complete() and question.kind != "count": _submit.call_deferred(question.result)

func _render_stage(stage: String) -> void:
	_clear(stage)
	subtitle.text = lesson.title if stage == "model" else "Reto %d de 5 · %s" % [round_index + 1, lesson.title] if stage == "practice" else "Ronda %d de 8 · %d puntos" % [round_index + 1, score]
	var paper := UI.paper(content, Color("#fffdf1"))
	paper.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	paper.add_child(UI.text(question.text, 25))
	var line := UI.row(paper, 12)
	line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var play := UI.column(line, 6)
	play.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if question.kind == "solid":
		var body_row := UI.row(play, 8)
		body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		solid = Solid.new()
		body_row.add_child(solid)
		solid.setup(question.shape)
		solid.turned.connect(func(): status.text = "Ahora observa sus superficies y elige el cuerpo.")
		if question.object_match:
			var index: int = Shapes.SOLIDS.find(question.shape)
			body_row.add_child(UI.picture(Art.object(index), Vector2(150, 145)))
		var rotate_row := UI.row(play, 10)
		rotate_row.alignment = BoxContainer.ALIGNMENT_CENTER
		for amount in [-0.5, 0.5]:
			var turn := UI.button("↶ Girar" if amount < 0 else "Girar ↷", UI.BLUE, 18)
			turn.pressed.connect(func(): solid.turn(amount))
			rotate_row.add_child(turn)
		_add_choices(play)
	else:
		world = Board.new()
		play.add_child(world)
		world.setup(question)
		world.attempted.connect(func(correct: bool):
			if not correct: _note_wrong()
		)
		world.changed.connect(_board_changed)
		world.completed.connect(func(): _submit(question.result))
		if question.kind in ["plane", "pattern", "count"]: _add_choices(play)
	if stage in ["model", "practice"]:
		_companion(line, _instruction())
	_nav("Escuchar", func(): audio.speak(question.audio), Color("#70529b"))
	_nav("Pista", _show_hint, Color("#a15e12"))
	if stage == "practice": _nav("Ver ejemplo", _show_model, Color("#177c70"))
	next_button = _nav("Practicar cinco retos" if stage == "model" else "Siguiente ›", _next_round)
	next_button.disabled = true
	status.text = _instruction()
	audio.speak(question.audio)

func _instruction() -> String:
	match question.kind:
		"plane": return "Arrastra una pieza al contorno. O toca una pieza y después el hueco."
		"pattern": return "Completa TODOS los huecos. " + ("Importan la forma y el color." if question.color_matters else "Importa la forma; el color no cambia la respuesta.")
		"solid": return "Desliza sobre el cuerpo para girarlo, o usa las flechas. Después elige su nombre."
		"count": return "Primero toca cada lado recto o esquina, según la consigna. Después elige la cantidad."
		"find": return "Encuentra las tres figuras pedidas. Cambiar el color o girarlas no cambia su nombre."
	return ""

func _add_choices(parent: Node) -> void:
	var row := UI.row(parent, 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for value in Rules.options(question):
		var button: Button
		if value is String:
			var tile := Tile.new()
			tile.token = value
			tile.show_name = question.kind == "solid"
			tile.draggable = question.kind in ["plane", "pattern"]
			tile.custom_minimum_size = Vector2(120, 95)
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			for state in ["normal", "hover", "pressed", "focus"]:
				tile.add_theme_stylebox_override(state, UI.style(Color("#e7f5f9"), Color("#177c95") if state == "focus" else Color("#9ac5d0"), 14, 5))
			button = tile
			if question.kind in ["plane", "pattern"]:
				button.pressed.connect(func():
					world.select(value)
					status.text = "Pieza elegida: toca el hueco donde va."
				)
			else: button.pressed.connect(_submit.bind(value))
		else:
			button = UI.button(str(value), Catalog.COLORS[topic_id], 27)
			button.custom_minimum_size.x = 100
			button.disabled = true
			button.pressed.connect(_submit.bind(value))
		choices.append(button)
		row.add_child(button)

func _board_changed() -> void:
	if question.kind in ["plane", "pattern"]:
		for button in choices:
			button.selected = button.token == world.selected_token
			button.queue_redraw()
	if question.kind == "count":
		for button in choices: button.disabled = not world.inspected() or solved_current
		if world.inspected(): status.text = "Ya exploraste el contorno. ¿Cuántas partes pedía la consigna?"
	audio.effect("tap")
	_save_attempt()

func _note_wrong() -> void:
	if solved_current or is_instance_valid(dialog): return
	if view != "model" and question.id not in wrong: wrong.append(question.id)
	status.text = "Todavía no. " + Rules.hint(question)
	if is_instance_valid(guide_text): guide_text.text = status.text
	audio.effect("retry")
	audio.speak("retry")
	_save_attempt()

func _submit(value: Variant) -> void:
	if solved_current or is_instance_valid(dialog): return
	if question.kind == "count" and view != "sky" and (not is_instance_valid(world) or not world.inspected()): return
	if question.kind in ["plane", "pattern", "find"] and view != "sky" and (not is_instance_valid(world) or not world.is_complete()): return
	if view == "model" and question.kind == "solid" and solid.interaction_count == 0:
		status.text = "Primero gira el cuerpo con el dedo o una flecha."
		return
	if not Rules.matches(question, value):
		_note_wrong()
		if world is Flight: world.reject()
		return
	solved_current = true
	for button in choices: button.disabled = true
	if world is Board: world.locked = true
	elif world is Flight: world.accept()
	if view == "model":
		model_done = true
		status.text = "¡Ejemplo completado! " + Rules.hint(question)
		audio.speak("model_done")
	else:
		var first: bool = question.id not in wrong and question.id not in hinted
		answers[question.id] = {"answer": question.result, "first": first}
		if view in ["game", "sky"]: score += 10 if first else 5
		status.text = "¡Lo descubriste! " + ("Puedes continuar." if question.kind != "solid" else String(question.fact))
		audio.speak("correct")
		_save_attempt()
	audio.effect("correct")
	if is_instance_valid(guide_text): guide_text.text = status.text
	next_button.disabled = false
	next_button.grab_focus()

func _save_attempt() -> void:
	if view != "practice" or lesson.is_empty(): return
	var draft := {}
	if world is Board and not solved_current: draft = {"id": question.id, "state": world.state()}
	if Progress.save_resume(lesson.id, answers, wrong, hinted, draft) != OK:
		status.text = "No se pudo guardar. Mantén esta pantalla abierta e intenta otra vez."

func _next_round() -> void:
	if not solved_current: return
	if view == "model":
		_begin_practice()
		return
	if view == "practice":
		_begin_practice()
		return
	round_index += 1
	if round_index >= questions.size(): _finish_game()
	else:
		question = questions[round_index]
		if topic_id == "quick_challenge": _render_sky()
		else: _render_stage("game")

func _finish_lesson() -> void:
	var result := Progress.finish_lesson(lesson.id, answers)
	_clear("result")
	var paper := UI.paper(content)
	paper.add_child(UI.text("¡Misión completada!", 36, Color("#177c70")))
	paper.add_child(UI.text(UI.stars(Progress.stars(lesson.id)), 65, Color("#a16400")))
	paper.add_child(UI.text("Resolviste cinco retos de " + lesson.title.to_lower() + ". Puedes volver para practicar.", 25))
	status.text = "Progreso guardado en este dispositivo." if result == OK else "No se pudo guardar: vuelve a intentar antes de salir."
	_nav("Volver a las misiones", _show_hub)
	if result != OK: _nav("Intentar guardar", _finish_lesson)
	audio.speak("done" if result == OK else "retry")
	audio.effect("finish")

func _show_setup() -> void:
	_clear("setup")
	var line := UI.row(content, 14)
	line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	line.add_child(UI.picture(Art.object(4 if topic_id == "quick_challenge" else 5 if topic_id == "build_pattern" else 7), Vector2(285, 220)))
	var paper := UI.paper(line)
	paper.add_child(UI.text({"find_shape": "Safari de las formas", "build_pattern": "El telar de patrones", "count_sides": "Un paseo por el contorno", "quick_challenge": "Vuelo entre las formas"}[topic_id], 30))
	paper.add_child(UI.text({"find_shape": "Encuentra tres figuras en cada ronda, aunque cambien de color, tamaño o posición.", "build_pattern": "Arrastra piezas y completa dos o tres huecos siguiendo la regla que se repite.", "count_sides": "Toca los lados o vértices y acompaña a la llama. Después elige cuántos hay.", "quick_challenge": "Toca una nube para viajar hacia la respuesta, o conduce el globo. Equivocarte permite volver a intentar."}[topic_id], 23))
	var mode := OptionButton.new()
	mode.custom_minimum_size.y = 52
	mode.add_item("Explorar · primeras formas")
	mode.add_item("Avanzar · más formas y reglas")
	mode.selected = difficulty - 1
	mode.item_selected.connect(func(index: int): difficulty = index + 1)
	paper.add_child(mode)
	if topic_id == "quick_challenge":
		var timer := OptionButton.new()
		timer.custom_minimum_size.y = 52
		for label in ["Sin reloj · 8 retos", "Viaje de 90 segundos", "Viaje de 120 segundos"]: timer.add_item(label)
		timer.selected = [0, 90, 120].find(duration)
		timer.item_selected.connect(func(index: int): duration = [0, 90, 120][index])
		paper.add_child(timer)
	paper.add_child(UI.text("Se guarda tu mejor marca. Repetir no suma puntos artificialmente.", 19))
	_nav("¡Comenzar!", _start_game, Color("#177c70"))
	status.text = "Juega a tu ritmo. Las pistas están siempre disponibles."

func _start_game() -> void:
	questions = Catalog.games(topic_id, difficulty)
	questions.shuffle()
	if duration == 0 or topic_id != "quick_challenge": questions.resize(mini(8, questions.size()))
	round_index = 0
	answers.clear()
	wrong.clear()
	hinted.clear()
	score = 0
	time_left = duration
	question = questions[0]
	if topic_id == "quick_challenge": _render_sky()
	else: _render_stage("game")

func _render_sky() -> void:
	_clear("sky")
	subtitle.text = "Reto %d · %d puntos" % [round_index + 1, score]
	var paper := UI.paper(content, Color("#f4fbff"))
	paper.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	var prompt := UI.row(paper, 10)
	var label := UI.text(question.text, 23)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt.add_child(label)
	if question.kind in ["count", "sky_pattern"] or question.get("object_match", false):
		var preview := Preview.new()
		preview.question = question
		preview.custom_minimum_size = Vector2(220, 100)
		prompt.add_child(preview)
	world = Flight.new()
	paper.add_child(world)
	world.setup(question, Rules.options(question))
	world.arrived.connect(_submit)
	var controls := UI.row(paper, 10)
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	for action in ["left", "rise", "right"]:
		var button := UI.button({"left": "◀ Izquierda", "rise": "▲ Subir", "right": "Derecha ▶"}[action], UI.BLUE, 18)
		button.button_down.connect(func(): if world is Flight: world.mouse_actions[action] = true)
		button.button_up.connect(func(): if world is Flight: world.mouse_actions.erase(action))
		button.gui_input.connect(func(event: InputEvent):
			if event is InputEventScreenTouch and world is Flight:
				world.set_touch(event.index, action, event.pressed)
				button.accept_event()
		)
		controls.add_child(button)
	_nav("Escuchar", func(): audio.speak(question.audio), Color("#70529b"))
	_nav("Pista", _show_hint, Color("#a15e12"))
	next_button = _nav("Siguiente ›", _next_round)
	next_button.disabled = true
	status.text = "Toca la nube de tu respuesta. También puedes volar con las flechas y ↑ o espacio."
	audio.speak(question.audio)

func _finish_game() -> void:
	var result := OK if answers.is_empty() else Progress.finish_game(topic_id, difficulty, answers, score)
	_clear("result")
	var paper := UI.paper(content)
	paper.add_child(UI.text("¡Exploración terminada!", 36, Color("#177c70")))
	paper.add_child(UI.text("%d puntos · %d retos resueltos" % [score, answers.size()], 34))
	var best := Progress.game_record(topic_id, difficulty)
	paper.add_child(UI.text("Mejor marca: %d puntos" % int(best.get("score", 0)), 25))
	_nav("Jugar otra vez", _show_setup)
	status.text = "Puedes practicar otra vez a tu ritmo." if result == OK else "No se pudo guardar tu marca."
	audio.speak("finish")
	audio.effect("finish")

func _pause_world(paused: bool) -> void:
	if world is Flight: world.set_paused(paused)
	elif is_instance_valid(world): world.active = not paused
	if is_instance_valid(solid):
		solid.active = not paused
		if paused: solid.dragging = false

func _modal(title: String, kind: String) -> VBoxContainer:
	_close_dialog()
	_pause_world(true)
	audio.stop()
	dialog_kind = kind
	dialog = ColorRect.new()
	dialog.color = Color(0.02, 0.12, 0.2, 0.8)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dialog)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(center)
	var stack := UI.paper(center)
	stack.get_parent().custom_minimum_size = Vector2(660, 0)
	stack.add_child(UI.text(title, 30, Color("#177c70")))
	return stack

func _close_dialog() -> void:
	if is_instance_valid(dialog):
		dialog.hide()
		dialog.queue_free()
	dialog = null
	dialog_kind = ""
	_pause_world(false)

func _show_hint() -> void:
	if question.is_empty(): return
	if view != "model" and not solved_current and question.id not in hinted: hinted.append(question.id)
	_save_attempt()
	var stack := _modal("Una pista para pensar", "hint")
	stack.add_child(UI.text(Rules.hint(question), 24))
	if world is Board:
		world.show_hint = true
		world.queue_redraw()
	_close_button(stack)

func _show_help() -> void:
	var stack := _modal("Exploramos geometría", "help")
	stack.add_child(UI.text("Figuras: arrastra al contorno, o toca pieza y hueco.\nCuerpos: desliza para girar o usa las flechas.\nLados y vértices: toca cada parte antes de responder.\nPatrones: completa los huecos según la regla.\nVuelo: toca una nube, o usa los controles.", 23))
	stack.add_child(UI.text("El cuadrado también es un rectángulo. Aquí llamamos «rectángulo alargado» al que tiene dos lados largos y dos cortos. El círculo tiene un borde curvo y cero lados rectos.", 20))
	_close_button(stack)
	audio.speak("help")

func _show_pause() -> void:
	if view != "sky": return
	var stack := _modal("El viaje espera", "pause")
	stack.add_child(UI.text("El globo y el reloj están detenidos.", 24))
	_close_button(stack)
	var finish := UI.button("Terminar este viaje", Color("#a15e12"))
	finish.pressed.connect(_finish_game)
	stack.add_child(finish)
	audio.speak("pause")

func _go_back() -> void:
	_save_attempt()
	if view in ["hub", "setup"]:
		audio.stop()
		back_requested.emit()
	elif topic_id in Catalog.TOPICS: _show_hub()
	else: _show_setup()

func _process(delta: float) -> void:
	if view == "sky" and duration > 0:
		if not is_instance_valid(dialog) and not solved_current and not audio.speaking():
			time_left = maxf(0, time_left - delta)
			if time_left <= 0:
				_finish_game()
				return
		subtitle.text = "%d s · %d puntos · reto %d" % [ceili(time_left), score, round_index + 1]

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and view == "sky" and not is_instance_valid(dialog): _show_pause()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and world is Flight and not is_instance_valid(dialog) and not solved_current:
		if event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D, KEY_UP, KEY_SPACE]:
			world.keys[event.keycode] = event.pressed
			get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(dialog): _close_dialog()
		else: _go_back()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_P and view == "sky": _show_pause()

func _exit_tree() -> void:
	if is_instance_valid(audio): audio.stop()

func _build_shell() -> void:
	background = UI.picture(Art.backdrop(0), Vector2.ZERO)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: safe.add_theme_constant_override("margin_" + side, 15)
	add_child(safe)
	var layout := UI.column(safe, 10)
	var header := UI.row(layout, 10)
	header.custom_minimum_size.y = 76
	back_button = UI.button("‹ Geometría", UI.BLUE, 21)
	back_button.custom_minimum_size.x = 145
	back_button.name = "BackToGeometry"
	back_button.pressed.connect(_go_back)
	header.add_child(back_button)
	var sign := UI.paper(header, Color("#fff5d7"))
	heading = UI.text(Catalog.TITLES[topic_id], 28, Catalog.COLORS[topic_id])
	sign.add_child(heading)
	subtitle = UI.text("Explora las formas y sus partes", 17)
	sign.add_child(subtitle)
	pause_button = UI.button("Ⅱ Pausa", Color("#71509d"), 18)
	pause_button.pressed.connect(_show_pause)
	header.add_child(pause_button)
	var sound := UI.button("Sonido", Color("#71509d"), 18)
	sound.name = "GeometrySound"
	sound.pressed.connect(_show_sound)
	header.add_child(sound)
	var help := UI.button("?", Color("#08768d"), 25)
	help.custom_minimum_size.x = 47
	help.pressed.connect(_show_help)
	header.add_child(help)
	var guide := Guide.new()
	guide.audio = audio
	guide.custom_minimum_size = Vector2(65, 73)
	header.add_child(guide)
	content = UI.column(layout, 10)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var message := PanelContainer.new()
	message.add_theme_stylebox_override("panel", UI.style(Color(0.04, 0.21, 0.29, 0.95), Color("#d3b571"), 14, 6))
	layout.add_child(message)
	status = UI.text("", 19, Color("#fff8de"))
	status.custom_minimum_size.y = 32
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_child(status)
	navigation = UI.row(layout, 10)
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER

func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		if child is Control: child.hide()
		child.queue_free()

func _nav(text: String, action: Callable, color: Color = UI.BLUE) -> Button:
	var button := UI.button(text, color, 20)
	button.pressed.connect(action)
	navigation.add_child(button)
	return button

func _companion(parent: Node, text: String) -> void:
	var stack := UI.paper(parent)
	stack.get_parent().custom_minimum_size.x = 240
	stack.get_parent().size_flags_horizontal = Control.SIZE_FILL
	var guide := Guide.new()
	guide.audio = audio
	guide.custom_minimum_size = Vector2(195, 175)
	stack.add_child(guide)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 85
	stack.add_child(scroll)
	guide_text = UI.text(text, 20)
	guide_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(guide_text)

func _show_sound() -> void:
	var stack := _modal("Voz y sonidos", "sound")
	var toggle := UI.button("Sonido activado" if not audio.muted else "Sonido silenciado", Color("#75509e"))
	toggle.toggle_mode = true
	toggle.button_pressed = not audio.muted
	toggle.toggled.connect(func(enabled: bool):
		audio.set_sound(enabled, audio.volume)
		toggle.text = "Sonido activado" if enabled else "Sonido silenciado"
	)
	stack.add_child(toggle)
	stack.add_child(UI.text("Volumen", 23))
	var slider := HSlider.new()
	slider.max_value = 100
	slider.step = 5
	slider.value = audio.volume
	slider.custom_minimum_size.y = 48
	slider.value_changed.connect(func(value_: float): audio.set_sound(not audio.muted, value_))
	stack.add_child(slider)
	var sample := UI.button("Escuchar a la llama", Color("#177c70"))
	sample.pressed.connect(func(): audio.speak(topic_id))
	stack.add_child(sample)
	_close_button(stack)

func _close_button(parent: Node) -> void:
	var button := UI.button("Seguir aprendiendo", UI.BLUE, 22)
	button.pressed.connect(_close_dialog)
	parent.add_child(button)
	button.grab_focus()

