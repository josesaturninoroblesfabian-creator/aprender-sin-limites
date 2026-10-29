extends Control

signal back_requested
const Catalog = preload("res://scripts/math/activity_catalog.gd")
const Rules = preload("res://scripts/math/math_rules.gd")
const Progress = preload("res://scripts/math/math_progress.gd")
const UI = preload("res://scripts/math/math_ui.gd")
const Audio = preload("res://scripts/math/math_audio.gd")
const Guide = preload("res://scripts/math/llama_guide.gd")
const Model = preload("res://scripts/math/math_model.gd")
const Balloons = preload("res://scripts/math/balloon_game.gd")
const Adventure = preload("res://scripts/math/andes_adventure.gd")
const Map = preload("res://scripts/math/adventure_map.gd")

var topic_id := "addition"
var view := "hub"
var audio: Node
var background: TextureRect
var content: VBoxContainer
var navigation: HBoxContainer
var status: Label
var subtitle: Label
var heading: Label
var back_button: Button
var pause_button: Button
var dialog: Control
var dialog_kind := ""
var lesson: Dictionary = {}
var question: Dictionary = {}
var answers: Dictionary = {}
var mistakes: Dictionary = {}
var hinted: Dictionary = {}
var model: Control
var balloons: Control
var arcade: Control
var guide_text: Label
var model_note: Label
var draft_label: Label
var submit_button: Button
var next_button: Button
var model_button: Button
var practice_button: Button
var draft := ""
var solved_current := false
var round_index := 0
var questions: Array[Dictionary] = []
var operations: Array = ["addition", "subtraction"]
var difficulty := 1
var difficulty_buttons: Array[Button] = []
var duration := 60.0
var time_left := 60.0
var score := 0
var solved := 0
var first_count := 0
var delayed_next := -1.0
var level := 0
var route_answers: Dictionary = {}
var gate_wrong: Dictionary = {}
var gate_assisted := false
var restored_gate_attempt := -1
var gate_feedback: Label
var gate_hint: Label
var gate_options: Array[Button] = []
var count_buttons: Array[Button] = []
var elapsed := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not Catalog.TITLES.has(topic_id): topic_id = "addition"
	audio = Audio.new()
	add_child(audio)
	_build_shell()
	if topic_id in Catalog.OPERATIONS: _show_hub()
	elif topic_id == "level_game": _show_map()
	else: _show_setup()
	audio.speak(topic_id)

func _build_shell() -> void:
	background = UI.background(self, 0)
	var safe := MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		safe.add_theme_constant_override("margin_" + side, 17)
	add_child(safe)
	var layout := UI.column(safe, 10)
	var header := UI.row(layout, 12)
	header.custom_minimum_size.y = 76
	back_button = UI.button("‹ Matemáticas", UI.BLUE, 21)
	back_button.name = "BackToMathematics"
	back_button.custom_minimum_size.x = 164
	back_button.pressed.connect(_go_back)
	header.add_child(back_button)
	var sign := UI.paper(header, Color("#fff5d7"))
	sign.get_parent().add_theme_stylebox_override("panel", UI.style(Color("#fff5d7"), Color("#bc822f"), 20, 9))
	heading = UI.text(Catalog.TITLES[topic_id], 30, Catalog.COLORS[topic_id])
	sign.add_child(heading)
	subtitle = UI.text("Aprende, descubre y juega a tu ritmo", 17)
	sign.add_child(subtitle)
	pause_button = UI.button("Ⅱ Pausa", Color("#7750a0"), 18)
	pause_button.visible = false
	pause_button.pressed.connect(_show_pause)
	header.add_child(pause_button)
	var sound := UI.button("Sonido", Color("#71509d"), 18)
	sound.name = "ActivitySound"
	sound.pressed.connect(_show_sound)
	header.add_child(sound)
	var help := UI.button("?", Color("#08768d"), 25)
	help.custom_minimum_size.x = 48
	help.pressed.connect(_show_help)
	header.add_child(help)
	var guide := Guide.new()
	guide.audio = audio
	guide.custom_minimum_size = Vector2(68, 75)
	header.add_child(guide)
	content = UI.column(layout, 10)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	status = UI.text("", 20, Color("#fff8dc"))
	status.custom_minimum_size.y = 47
	status.add_theme_color_override("font_shadow_color", Color("#183b52"))
	status.add_theme_constant_override("shadow_offset_x", 1)
	status.add_theme_constant_override("shadow_offset_y", 2)
	status.add_theme_color_override("font_outline_color", Color("#183b52"))
	status.add_theme_constant_override("outline_size", 2)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(status)
	navigation = UI.row(layout, 12)
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER

func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		if child is Control: child.hide()
		child.queue_free()

func _clear(new_view: String, backdrop_index: int = 0) -> void:
	_close_dialog()
	audio.stop()
	if is_instance_valid(arcade):
		_save_route()
		arcade.active = false
	model = null
	model_note = null
	balloons = null
	arcade = null
	delayed_next = -1
	_clear_children(content)
	_clear_children(navigation)
	status.text = ""
	view = new_view
	background.texture = UI.backdrop(backdrop_index)
	pause_button.visible = view in ["adventure", "quick"]
	back_button.text = "‹ Matemáticas" if view in ["hub", "setup", "map"] else ("‹ Caminos" if topic_id == "level_game" else "‹ Misiones" if topic_id in Catalog.OPERATIONS else "‹ Preparar")
	heading.text = Catalog.TITLES[topic_id]

func _nav(value: String, callback: Callable, color: Color = UI.BLUE) -> Button:
	var button := UI.button(value, color, 20)
	button.pressed.connect(callback)
	navigation.add_child(button)
	return button

func _companion(parent: Node, message: String, height: int = 215) -> VBoxContainer:
	var stack := UI.paper(parent)
	stack.get_parent().custom_minimum_size.x = 260
	stack.get_parent().size_flags_horizontal = Control.SIZE_FILL
	var guide := Guide.new()
	guide.audio = audio
	guide.custom_minimum_size = Vector2(210, height)
	stack.add_child(guide)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 62
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	guide_text = UI.text(message, 21)
	guide_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(guide_text)
	return stack

func _show_hub() -> void:
	_clear("hub")
	subtitle.text = "Cuatro misiones · Un ejemplo guiado y seis retos en cada una"
	var split := UI.row(content, 15)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	split.add_child(grid)
	for item in Catalog.for_topic(topic_id):
		var card := UI.button("", Catalog.COLORS[topic_id])
		card.name = "Mission_" + item.id
		card.custom_minimum_size = Vector2(250, 210)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 14)
		card.add_child(margin)
		var stack := UI.column(margin, 5)
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var top := UI.row(stack)
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(UI.picture(UI.object(5 if Progress.is_complete(item.id) else int(item.tier) % 3), Vector2(37, 37)))
		var caption := UI.text("MISIÓN %d" % int(item.tier), 17, Color("#fff2c2"))
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(caption)
		stack.add_child(UI.text(item.title, 24, Color.WHITE))
		stack.add_child(UI.text(item.aim, 18, Color("#fff5df")))
		var sample := UI.text(Rules.expression(item.model, true), 28, Color("#fff3be"))
		stack.add_child(sample)
		var partial := Progress.resume(item.id)
		var action := "Continuar · %d / 6" % partial.answers.size() if not partial.is_empty() else ("Repetir · " + UI.stars(Progress.lesson_stars(item.id)) if Progress.is_complete(item.id) else "Descubrir →")
		stack.add_child(UI.text(action, 18, Color("#fff0a0")))
		card.pressed.connect(_start_lesson.bind(String(item.id)))
	var totals := Progress.totals()
	var companion := _companion(split, "Cada signo tiene una idea. Vamos a entenderla moviendo las cantidades.")
	companion.add_child(UI.text("%d / 16 misiones completadas\n%d estrellas en misiones" % [totals.lessons, totals.stars], 19, Catalog.COLORS[topic_id]))
	status.text = "Puedes elegir cualquier misión y volver a practicar. Tu mejor resultado se conserva."
	_nav("Escuchar la guía", func(): audio.speak(topic_id), Catalog.COLORS[topic_id])

func _start_lesson(id: String) -> void:
	lesson = Catalog.find(id)
	if lesson.is_empty() or lesson.topic != topic_id: return
	answers.clear()
	mistakes.clear()
	hinted.clear()
	var saved := Progress.resume(id)
	if not saved.is_empty():
		answers = saved.answers
		for question_id in saved.get("mistakes", []): mistakes[question_id] = true
		for question_id in saved.get("hinted", []): hinted[question_id] = true
		_next_unsolved()
		_render_question()
		audio.speak("resume")
	else:
		_show_example()

func _show_example() -> void:
	_clear("example")
	question = lesson.model
	heading.text = lesson.title
	subtitle.text = "Primero descubrimos cómo funciona · Sin reloj"
	var split := UI.row(content, 15)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := UI.paper(split)
	paper.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	paper.add_child(UI.text(question.text, 22))
	model = Model.new()
	paper.add_child(model)
	model.set_question(question)
	var companion := _companion(split, lesson.aim, 190)
	model_note = UI.text("Toca el botón de abajo y observa cada cambio.", 18)
	companion.add_child(model_note)
	model_button = _nav(Rules.action_label(question), _advance_model, Catalog.COLORS[topic_id])
	practice_button = _nav("¡Ahora tú! Seis retos →", _begin_practice, Color("#197d4b"))
	practice_button.disabled = true
	_nav("Repetir ejemplo", _show_example, Color("#7750a0"))
	status.text = "Mueve las cantidades antes de pasar a los retos."
	audio.speak(String(lesson.id) + "_intro")

func _advance_model() -> void:
	if not is_instance_valid(model) or model.step >= Rules.action_target(question): return
	var finished: bool = model.advance()
	audio.effect("tap")
	if finished:
		model_button.disabled = true
		practice_button.disabled = false
		guide_text.text = "\n".join(Rules.explanation(question))
		guide_text.add_theme_font_size_override("font_size", 18)
		model_note.text = "Ahora puedes pasar a los seis retos."
		status.text = "¡Lo descubriste! " + Rules.expression(question, true)
		audio.speak("model_done")
	else:
		guide_text.text = "Paso %d de %d.\n\n%s" % [model.step, Rules.action_target(question), _model_caption()]

func _model_caption() -> String:
	var value := Rules.visible_value(question, model.step)
	if question.operation == "multiplication": return "%d grupos de %d. El total va creciendo: %d." % [model.step, int(question.b), value]
	if question.operation == "division": return "Cada cesta recibe %d. Quedan %d por repartir." % [value, int(question.a) - value * int(question.b)]
	return "Ahora estás en %d. Observa el recorrido en la recta." % value

func _begin_practice() -> void:
	if not is_instance_valid(model) or model.step < Rules.action_target(question): return
	_next_unsolved()
	_render_question()

func _next_unsolved() -> void:
	round_index = 0
	while round_index < 6 and answers.has(lesson.questions[round_index].id): round_index += 1
	if round_index < 6: question = lesson.questions[round_index]

func _render_question() -> void:
	var lesson_mode := topic_id in Catalog.OPERATIONS
	if lesson_mode and round_index >= 6:
		_finish_lesson()
		return
	_clear("practice" if lesson_mode else "exercise", 0 if lesson_mode else 1)
	if not lesson_mode: question = questions[round_index]
	draft = ""
	solved_current = false
	heading.text = lesson.title if lesson_mode else "Encargos de la feria"
	subtitle.text = "Reto %d de %d · Piensa, observa y responde" % [round_index + 1, 6 if lesson_mode else 10]
	var split := UI.row(content, 15)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := UI.paper(split)
	paper.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	paper.add_child(UI.text(question.text, 23))
	model = Model.new()
	paper.add_child(model)
	model.set_question(question)
	var tools := UI.row(paper)
	var move := UI.button(Rules.action_label(question), Catalog.COLORS[question.operation], 19)
	move.pressed.connect(_hint_move)
	tools.add_child(move)
	var read := UI.button("▶ Escuchar", Color("#177c70"), 19)
	read.pressed.connect(func(): audio.speak(question.id))
	tools.add_child(read)
	_build_keypad(split)
	status.text = "Escribe tu respuesta. Puedes mover las cantidades o pedir una pista."
	next_button = _nav("Siguiente reto →", _next_question, Color("#197d4b"))
	next_button.disabled = true
	_nav("Ver pista", _show_hint, Color("#7750a0"))
	if lesson_mode:
		_nav("Volver al ejemplo", _show_example, Catalog.COLORS[topic_id])
	else:
		_nav("Escuchar problema", func(): audio.speak(question.id), Color("#177c70"))
	audio.speak(question.id)

func _build_keypad(parent: Node) -> void:
	var stack := UI.paper(parent, Color("#f0f8ff"))
	stack.get_parent().custom_minimum_size.x = 280
	stack.get_parent().size_flags_horizontal = Control.SIZE_FILL
	stack.add_child(UI.text("Mi respuesta", 21))
	var field := PanelContainer.new()
	field.add_theme_stylebox_override("panel", UI.style(Color.WHITE, Color("#72acc8"), 13, 8))
	stack.add_child(field)
	draft_label = UI.text("?", 42, UI.BLUE)
	draft_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	field.add_child(draft_label)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 9)
	stack.add_child(grid)
	for value in ["7", "8", "9", "4", "5", "6", "1", "2", "3", "⌫", "0", "✓"]:
		var button := UI.button(value, Color("#0874b1") if value not in ["⌫", "✓"] else Color("#267e56"), 28)
		button.name = "Key_" + value
		button.custom_minimum_size = Vector2(72, 56)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_key.bind(String(value)))
		grid.add_child(button)
		if value == "✓": submit_button = button
	stack.add_child(UI.text("También puedes usar el teclado y pulsar Enter.", 17))

func _key(value: String) -> void:
	if solved_current: return
	if value == "✓":
		_submit()
		return
	if value == "⌫": draft = draft.left(maxi(0, draft.length() - 1))
	elif draft.length() < 3:
		draft = value if draft == "0" else draft + value
	if is_instance_valid(draft_label): draft_label.text = draft if not draft.is_empty() else "?"
	audio.effect("tap")

func _attempt_key() -> String:
	return String(question.id) if topic_id in Catalog.OPERATIONS else "%s_%d" % [question.id, round_index]

func _submit() -> void:
	if draft.is_empty():
		status.text = "Primero escribe un resultado."
		return
	_submit_number(int(draft))

func _submit_number(value: int) -> bool:
	if solved_current or view not in ["practice", "exercise", "count", "quick"]: return false
	if value != int(question.result):
		mistakes[_attempt_key()] = true
		_persist_attempt()
		status.text = "Cuenta de nuevo. Cada objeto se cuenta una sola vez." if view == "count" else Rules.feedback(question, value)
		audio.effect("retry")
		if view == "quick" and is_instance_valid(balloons): balloons.rejected[value] = true
		return false
	solved_current = true
	var first := not mistakes.has(_attempt_key()) and not hinted.has(_attempt_key())
	first_count += 1 if first else 0
	solved += 1
	score += 10 if first else 5
	audio.stop()
	audio.effect("correct")
	status.text = "¡Bien pensado! " + ("Hay %d en total." % int(question.result) if view == "count" else Rules.expression(question, true))
	if is_instance_valid(model) and view != "count":
		model.reveal = true
		model.step = Rules.action_target(question)
		model.previous_value = Rules.visible_value(question, model.step)
	if topic_id in Catalog.OPERATIONS:
		answers[question.id] = {"answer": value, "first": first}
		if _persist_attempt() != OK: status.text += " No pudimos guardar todavía."
	if view == "quick":
		balloons.active = false
		balloons.accepted_value = value
		delayed_next = 0.65
	else:
		next_button.disabled = false
		if is_instance_valid(submit_button): submit_button.disabled = true
		if view == "count":
			for option in count_buttons: option.disabled = true
	return true

func _persist_attempt() -> Error:
	if topic_id not in Catalog.OPERATIONS or lesson.is_empty(): return OK
	return Progress.save_resume(lesson.id, answers, mistakes.keys(), hinted.keys())

func _next_question() -> void:
	if not solved_current: return
	if topic_id in Catalog.OPERATIONS:
		_next_unsolved()
		_render_question()
	elif view == "count":
		round_index += 1
		if round_index >= 8: _finish_game()
		else: _render_count()
	elif view == "exercise":
		round_index += 1
		if round_index >= 10: _finish_game()
		else: _render_question()

func _hint_move() -> void:
	if solved_current or not is_instance_valid(model): return
	hinted[_attempt_key()] = true
	_persist_attempt()
	model.advance()
	status.text = _model_caption()
	audio.effect("tap")

func _finish_lesson() -> void:
	var error := Progress.complete_lesson(lesson.id, answers)
	if error != OK:
		status.text = "La misión terminó, pero no pudimos guardar. Vuelve a intentarlo."
		return
	_clear("result")
	heading.text = "¡Una idea que ya conoces!"
	subtitle.text = lesson.title
	var row := UI.row(content, 22)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(UI.picture(UI.object(5), Vector2(250, 260)))
	var stack := UI.paper(row)
	stack.add_child(UI.text("¡Resolviste los seis retos!", 36, Catalog.COLORS[topic_id]))
	stack.add_child(UI.text(UI.stars(Progress.lesson_stars(lesson.id)), 65, Color("#a56c0c")))
	stack.add_child(UI.text("Tu mejor resultado se queda guardado. Puedes practicar otra vez para mejorarlo.", 25))
	stack.add_child(UI.text("Tres estrellas: seis aciertos sin pistas ni errores. Dos: al menos cuatro. Una: misión terminada aprendiendo con ayuda.", 20))
	_nav("Elegir otra misión", _show_hub, Catalog.COLORS[topic_id])
	_nav("Practicar esta misión", func():
		answers.clear()
		mistakes.clear()
		hinted.clear()
		_show_example()
	, Color("#7750a0"))
	status.text = "Progreso guardado en este dispositivo."
	audio.speak("done")

func _show_setup() -> void:
	_clear("setup", 3 if topic_id == "quick_challenge" else 1)
	subtitle.text = {"count_objects": "El huerto de las cantidades · Ocho rondas sin reloj", "solve_exercises": "Problemas con sentido · Diez encargos en cada partida", "quick_challenge": "Resuelve y toca el globo · Con reloj o a tu ritmo"}.get(topic_id, "Vamos a jugar")
	var split := UI.row(content, 20)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var stack := UI.paper(split)
	if topic_id == "count_objects":
		stack.add_child(UI.text("Cuenta, marca y descubre", 35, Catalog.COLORS[topic_id]))
		var objects := UI.row(stack)
		for index in range(3): objects.add_child(UI.picture(UI.object(index), Vector2(135, 150)))
		stack.add_child(UI.text("Toca cada manzana, zanahoria o maíz para marcarlo. Después elige cuántos hay.", 27))
		stack.add_child(UI.text("Aquí practicamos cantidades del 1 al 20. Aprender a sumar tiene sus propias misiones.", 22))
	else:
		stack.add_child(UI.text("¿Qué quieres practicar?", 30, Catalog.COLORS[topic_id]))
		var checks := UI.row(stack, 14)
		for operation in Catalog.OPERATIONS:
			var check := UI.button(("✓ " if operation in operations else "") + Rules.SYMBOLS[operation] + " " + Catalog.TITLES[operation], Catalog.COLORS[operation], 18)
			check.name = "Use_" + operation
			check.toggle_mode = true
			check.button_pressed = operation in operations
			check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			check.toggled.connect(func(enabled: bool):
				_toggle_operation(enabled, operation)
				check.text = ("✓ " if enabled else "") + Rules.SYMBOLS[operation] + " " + Catalog.TITLES[operation]
			)
			checks.add_child(check)
		stack.add_child(UI.text("Elige un camino", 24))
		var levels := UI.row(stack)
		difficulty_buttons.clear()
		for index in range(3):
			var button := UI.button(("✓ " if difficulty == index + 1 else "") + ["Primeros pasos", "Voy avanzando", "Más desafíos"][index], Catalog.COLORS[topic_id], 18)
			button.name = "Difficulty_%d" % (index + 1)
			button.toggle_mode = true
			button.button_pressed = difficulty == index + 1
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.pressed.connect(_choose_difficulty.bind(index + 1))
			levels.add_child(button)
			difficulty_buttons.append(button)
		stack.add_child(UI.text("Primeros pasos: sumas y restas hasta 10, grupos y repartos sencillos. Avanzando: hasta 20 y más tablas. Más desafíos: decenas y todas las tablas del recorrido.", 19))
		if topic_id == "quick_challenge":
			stack.add_child(UI.text("Tú eliges el ritmo", 24))
			var times := UI.row(stack)
			for seconds in [60, 90, 0]:
				var timed := UI.button(("✓ " if int(duration) == seconds else "") + ("Sin reloj" if seconds == 0 else "%d segundos" % seconds), Color("#9b3575"), 19)
				timed.name = "Clock_%d" % seconds
				timed.toggle_mode = true
				timed.button_pressed = int(duration) == seconds
				timed.pressed.connect(func():
					duration = seconds
					for sibling in times.get_children(): sibling.button_pressed = sibling == timed
					for sibling in times.get_children(): sibling.text = ("✓ " if sibling.button_pressed else "") + ("Sin reloj" if times.get_children().find(sibling) == 2 else "%d segundos" % [60, 90][times.get_children().find(sibling)])
				)
				times.add_child(timed)
			stack.add_child(UI.text("El reloj se detiene al pausar o abrir una pista. Sin reloj, termina diez aciertos a tu ritmo.", 18))
		else:
			stack.add_child(UI.picture(UI.object(3), Vector2(150, 120)))
			stack.add_child(UI.text("Ayuda en la feria resolviendo pequeños problemas. Puedes escuchar cada encargo y pedir una pista.", 23))
	var companion := _companion(split, "No hay prisa por acertar. Observa, prueba y aprende.")
	var record := Progress.game_record(topic_id)
	if not record.is_empty(): companion.add_child(UI.text("Mi mejor resultado\n" + UI.stars(int(record.get("stars", 0))) + "\n%d puntos" % int(record.get("score", 0)), 23, Catalog.COLORS[topic_id]))
	_nav("¡Empezar!", _start_game, Catalog.COLORS[topic_id])
	_nav("Escuchar cómo jugar", func(): audio.speak(topic_id), Color("#177c70"))
	status.text = "Todo el juego funciona sin internet."

func _toggle_operation(enabled: bool, operation: String) -> void:
	if enabled and operation not in operations: operations.append(operation)
	elif not enabled: operations.erase(operation)

func _choose_difficulty(value: int) -> void:
	difficulty = clampi(value, 1, 3)
	for index in range(difficulty_buttons.size()):
		difficulty_buttons[index].button_pressed = index + 1 == difficulty
		difficulty_buttons[index].text = ("✓ " if index + 1 == difficulty else "") + ["Primeros pasos", "Voy avanzando", "Más desafíos"][index]

func _start_game() -> void:
	if topic_id != "count_objects" and operations.is_empty():
		status.text = "Elige al menos una operación para jugar."
		return
	questions = Catalog.pool(operations, difficulty)
	questions.shuffle()
	score = 0
	solved = 0
	first_count = 0
	round_index = 0
	mistakes.clear()
	hinted.clear()
	if topic_id == "count_objects": _render_count()
	elif topic_id == "solve_exercises": _render_question()
	else:
		time_left = duration
		_render_quick()

func _render_count() -> void:
	_clear("count", 1)
	var total: int = [3, 5, 8, 10, 12, 15, 18, 20][round_index]
	question = {"id": "count_%d" % total, "a": total, "b": 1, "result": total, "operation": "count"}
	solved_current = false
	subtitle.text = "Ronda %d de 8 · Marca cada objeto y elige la cantidad" % (round_index + 1)
	var split := UI.row(content, 15)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := UI.paper(split)
	paper.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	model = Model.new()
	paper.add_child(model)
	model.setup_count(total, round_index % 3)
	model.counted.connect(func(_index: int): audio.effect("tap"))
	var stack := _companion(split, "¿Cuántos objetos hay?", 150)
	count_buttons.clear()
	for value in Rules.options(question, round_index):
		var option := UI.button("Hay %d" % value, Catalog.COLORS[topic_id], 25)
		option.name = "CountAnswer_%d" % value
		option.pressed.connect(_submit_number.bind(value))
		stack.add_child(option)
		count_buttons.append(option)
	next_button = _nav("Siguiente ronda →", _next_question, Catalog.COLORS[topic_id])
	next_button.disabled = true
	_nav("Escuchar", func(): audio.speak(question.id), Color("#177c70"))
	status.text = "Toca una vez cada objeto. El número que aparece te ayuda a no contarlo dos veces."
	audio.speak(question.id)

func _render_quick() -> void:
	_clear("quick", 3)
	question = questions[round_index % questions.size()]
	solved_current = false
	heading.text = "Fiesta de globos"
	subtitle.text = "%d aciertos · %d puntos · %s" % [solved, score, "Sin reloj · meta: 10" if duration <= 0 else "Tiempo: %d s" % ceili(time_left)]
	var paper := UI.paper(content, Color(1, 0.98, 0.92, 0.96))
	paper.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	var equation := UI.text(Rules.expression(question), 43, Catalog.COLORS[topic_id])
	equation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paper.add_child(equation)
	balloons = Balloons.new()
	balloons.name = "AnswerBalloons"
	balloons.answer_chosen.connect(_submit_number)
	paper.add_child(balloons)
	balloons.reset(Rules.options(question, round_index))
	_nav("Ver pista", _show_hint, Color("#7750a0"))
	_nav("Escuchar problema", func(): audio.speak(question.id), Color("#177c70"))
	status.text = "Toca el globo con la respuesta correcta."

func _next_quick() -> void:
	if duration <= 0 and solved >= 10:
		_finish_game()
		return
	round_index += 1
	_render_quick()

func _finish_game() -> void:
	var current_score := score
	var stars := 3 if first_count >= 8 else (2 if first_count >= 4 else 1)
	if topic_id == "quick_challenge": stars = 3 if solved >= 10 else (2 if solved >= 5 else 1)
	var saved := solved > 0 and Progress.finish_game(topic_id, current_score, stars, solved) == OK
	_clear("game_result", 3 if topic_id == "quick_challenge" else 1)
	heading.text = "¡Una partida para aprender!"
	subtitle.text = Catalog.TITLES[topic_id]
	var row := UI.row(content, 22)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(UI.picture(UI.object(7), Vector2(255, 255)))
	var stack := UI.paper(row)
	stack.add_child(UI.text("%d retos resueltos" % solved, 38, Catalog.COLORS[topic_id]))
	stack.add_child(UI.text("%d puntos en esta partida" % current_score, 30))
	stack.add_child(UI.text(UI.stars(stars if solved > 0 else 0), 66, Color("#a56c0c")))
	var best := Progress.game_record(topic_id)
	stack.add_child(UI.text("Mejor puntuación guardada: %d" % int(best.get("score", 0)), 25))
	stack.add_child(UI.text("Repetir mejora tu récord. Los puntos de las partidas no se acumulan sin límite.", 22))
	status.text = "Tu mejor resultado se guardó." if saved else "Puedes volver a intentarlo. La partida no registró nuevos resultados."
	_nav("Jugar otra vez", _start_game, Catalog.COLORS[topic_id])
	_nav("Elegir dificultad", _show_setup, Color("#7750a0"))
	audio.speak("done" if saved else "quick_ready")

func _show_map() -> void:
	_clear("map", 2)
	subtitle.text = "Doce caminos · Tres puertas matemáticas en cada uno"
	var split := UI.row(content, 16)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := UI.paper(split, Color(1, 0.97, 0.85, 0.95))
	paper.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	var map := Map.new()
	map.level_chosen.connect(_start_level)
	paper.add_child(map)
	var companion := _companion(split, "Salta, recoge estrellas y resuelve tres puertas por camino.", 160)
	companion.add_child(UI.text("Teclado: flechas + Espacio.\nTablet: flechas + Saltar.\nP: pausa.", 18))
	companion.add_child(UI.text("%d / 12 caminos terminados" % Progress.totals().paths, 21, Catalog.COLORS[topic_id]))
	status.text = "Los caminos se abren al llegar a la meta del anterior. Un salto fallado no borra lo aprendido."
	_nav("Escuchar cómo jugar", func(): audio.speak("level_game"), Catalog.COLORS[topic_id])

func _start_level(index: int) -> void:
	if not Progress.level_unlocked(index): return
	level = index
	route_answers.clear()
	var saved := Progress.route(level)
	restored_gate_attempt = -1
	gate_wrong.clear()
	gate_assisted = false
	var saved_answers: Variant = saved.get("answers", {})
	var opened: Dictionary = {}
	var level_questions := Catalog.level_questions(level)
	for gate in range(3):
		var q: Dictionary = level_questions[gate]
		var answer: Variant = saved_answers.get(q.id, {}) if saved_answers is Dictionary else {}
		if not answer is Dictionary or int(answer.get("answer", -1)) != int(q.result): break
		route_answers[q.id] = {"answer": int(q.result), "first": answer.get("first", false) == true}
		opened[gate] = true
	if int(saved.get("pending_gate", -1)) == opened.size() and opened.size() < 3:
		restored_gate_attempt = opened.size()
		var rejected: Variant = saved.get("pending_errors", [])
		if rejected is Array:
			for value in rejected: gate_wrong[int(value)] = true
		gate_assisted = saved.get("pending_assisted", false) == true
	_clear("adventure", 2)
	subtitle.text = "Camino %d · %s · Llega a la meta después de resolver las tres puertas" % [level + 1, Catalog.TITLES[Catalog.OPERATIONS[level / 3]]]
	arcade = Adventure.new()
	arcade.stage_index = level
	arcade.name = "AndesCourse"
	arcade.gate_requested.connect(_show_gate)
	arcade.reached_goal.connect(_finish_level)
	arcade.sound_requested.connect(func(id: String): audio.effect(id))
	arcade.checkpoint_changed.connect(_save_route)
	arcade.pause_requested.connect(_show_pause)
	content.add_child(arcade)
	var saved_stars: Variant = saved.get("collected", [])
	arcade.restore(opened, saved_stars if saved_stars is Array else [])
	status.text = "Las estrellas premian explorar. Las puertas se abren al resolver operaciones."
	audio.stop()

func _save_route() -> void:
	if not is_instance_valid(arcade) or arcade.won: return
	var pending: int = arcade.awaiting_gate
	Progress.save_route(level, {"answers": route_answers.duplicate(true), "collected": arcade.collected.duplicate(), "pending_gate": pending, "pending_errors": gate_wrong.keys() if pending >= 0 else [], "pending_assisted": gate_assisted if pending >= 0 else false})

func _show_gate(index: int, fresh: bool = true) -> void:
	if not is_instance_valid(arcade) or arcade.awaiting_gate != index: return
	if fresh and restored_gate_attempt != index:
		gate_wrong.clear()
		gate_assisted = false
	if restored_gate_attempt == index: restored_gate_attempt = -1
	question = Catalog.level_questions(level)[index]
	var stack := _modal("Puerta %d de 3" % (index + 1), "gate")
	stack.add_child(UI.text(question.text, 23))
	stack.add_child(UI.text(Rules.expression(question), 42, Catalog.COLORS[question.operation]))
	var row := UI.row(stack)
	gate_options.clear()
	for value in Rules.options(question, level):
		var option := UI.button(str(value), Catalog.COLORS[question.operation], 30)
		option.name = "GateAnswer_%d" % value
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.custom_minimum_size.y = 67
		option.disabled = gate_wrong.has(value)
		option.pressed.connect(_answer_gate.bind(value))
		row.add_child(option)
		gate_options.append(option)
	gate_feedback = UI.text("Piensa y elige. Puedes pedir una pista.", 20)
	stack.add_child(gate_feedback)
	gate_hint = UI.text("", 20)
	stack.add_child(gate_hint)
	var tools := UI.row(stack)
	var hint := UI.button("Ver pista", Color("#7750a0"), 20)
	hint.pressed.connect(func():
		gate_assisted = true
		gate_hint.text = "\n".join(Rules.explanation(question))
		_save_route()
	)
	tools.add_child(hint)
	var listen := UI.button("▶ Escuchar", Color("#177c70"), 20)
	listen.pressed.connect(func(): audio.speak(question.id))
	tools.add_child(listen)
	var leave := UI.button("Volver al mapa", UI.BLUE, 20)
	leave.pressed.connect(func():
		_save_route()
		_show_map()
	)
	stack.add_child(leave)
	audio.speak(question.id)

func _answer_gate(value: int) -> bool:
	if not is_instance_valid(arcade) or arcade.awaiting_gate < 0 or dialog_kind != "gate": return false
	if value != int(question.result):
		gate_wrong[value] = true
		_save_route()
		gate_feedback.text = Rules.feedback(question, value)
		for option in gate_options:
			if option.text == str(value): option.disabled = true
		audio.effect("retry")
		return false
	var index: int = arcade.awaiting_gate
	route_answers[question.id] = {"answer": value, "first": gate_wrong.is_empty() and not gate_assisted}
	_close_dialog()
	arcade.open_gate(index)
	audio.effect("correct")
	status.text = "¡Puerta abierta! Sigue el camino y busca la próxima."
	return true

func _finish_level() -> void:
	if not is_instance_valid(arcade) or not arcade.won or arcade.position_world.x < Adventure.WORLD_END: return
	var stars_collected: Array = arcade.collected.duplicate()
	var error := Progress.complete_level(level, route_answers, stars_collected, true)
	_clear("route_result", 2)
	heading.text = "¡Camino completado!"
	subtitle.text = "Camino %d · Tu siguiente aventura ya está más cerca" % (level + 1)
	var split := UI.row(content, 22)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(UI.picture(UI.runner(7), Vector2(330, 360)))
	var stack := UI.paper(split)
	stack.add_child(UI.text("Resolviste las tres puertas", 36, Catalog.COLORS[topic_id]))
	stack.add_child(UI.text(UI.stars(int(Progress.level_record(level).get("stars", 0))), 64, Color("#a56c0c")))
	stack.add_child(UI.text("Recogiste %d de 5 estrellas del paisaje." % stars_collected.size(), 27))
	stack.add_child(UI.text("Una estrella por llegar; otra por recoger al menos tres; otra por resolver las tres puertas al primer intento y sin pistas.", 22))
	status.text = "Camino guardado. Puedes repetir para mejorar tus estrellas." if error == OK else "Llegaste a la meta, pero no pudimos guardar."
	_nav("Ver mis caminos", _show_map, Catalog.COLORS[topic_id])
	if level < 11 and Progress.level_unlocked(level + 1): _nav("Siguiente camino →", _start_level.bind(level + 1), Color("#197d4b"))
	audio.speak("level_done")

func _modal(title: String, kind: String) -> VBoxContainer:
	_close_dialog()
	if is_instance_valid(arcade): arcade.set_paused(true)
	if is_instance_valid(balloons): balloons.active = false
	dialog_kind = kind
	dialog = Control.new()
	dialog.name = "MathDialog"
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dialog)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.08, 0.16, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size.x = 770
	card.add_theme_stylebox_override("panel", UI.style(UI.PAPER, Catalog.COLORS[topic_id], 23, 22))
	center.add_child(card)
	var stack := UI.column(card, 12)
	stack.add_child(UI.text(title, 31, Catalog.COLORS[topic_id]))
	return stack

func _close_dialog() -> void:
	if is_instance_valid(dialog):
		dialog.hide()
		dialog.queue_free()
	dialog = null
	dialog_kind = ""
	if is_instance_valid(arcade): arcade.set_paused(false)
	if is_instance_valid(balloons): balloons.active = not solved_current
	if is_instance_valid(audio): audio.stop()

func _close_button(stack: Node, value: String = "Seguir aprendiendo") -> void:
	var close := UI.button(value, UI.BLUE, 21)
	close.pressed.connect(_close_dialog)
	stack.add_child(close)
	close.grab_focus()

func _show_hint() -> void:
	if question.is_empty() or solved_current: return
	hinted[_attempt_key()] = true
	_persist_attempt()
	var stack := _modal("Lo pensamos paso a paso", "hint")
	stack.add_child(UI.text(Rules.expression(question, true), 35, Catalog.COLORS[question.operation]))
	stack.add_child(UI.text("\n".join(Rules.explanation(question)), 24))
	stack.add_child(UI.text("Pedir ayuda es parte de aprender. Vuelve al reto y escribe la respuesta.", 20))
	_close_button(stack)
	audio.speak("help")

func _show_help() -> void:
	var stack := _modal("La llama te acompaña", "help")
	stack.add_child(UI.text("En las misiones primero movemos las cantidades. Después resolvemos seis retos con el teclado o los botones. Puedes escuchar, pedir pistas y repetir.", 25))
	stack.add_child(UI.text("En la aventura: flechas o A/D para moverte, Espacio para saltar. En tablet puedes usar dos dedos. Las puertas tienen operaciones; el suelo continuo permite volver a intentar los saltos.", 23))
	stack.add_child(UI.text("El progreso y las voces están en este dispositivo. Todo funciona sin conexión.", 22))
	_close_button(stack)
	audio.speak("help")

func _show_sound() -> void:
	var stack := _modal("Voz y sonidos", "sound")
	var toggle := UI.button("Sonido activado" if not audio.muted else "Sonido silenciado", Color("#7750a0"))
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
	slider.custom_minimum_size.y = 50
	slider.value_changed.connect(func(value: float): audio.set_sound(not audio.muted, value))
	stack.add_child(slider)
	var sample := UI.button("Escuchar a la llama", Color("#177c70"))
	sample.pressed.connect(func(): audio.speak(topic_id))
	stack.add_child(sample)
	stack.add_child(UI.text("La misma voz que en el menú. Audio incluido, sin internet.", 21))
	_close_button(stack)

func _show_pause() -> void:
	if view not in ["adventure", "quick"]: return
	if dialog_kind == "pause":
		_close_dialog()
		if is_instance_valid(arcade) and arcade.awaiting_gate >= 0: _show_gate(arcade.awaiting_gate, false)
		return
	var stack := _modal("Una pausa para respirar", "pause")
	stack.add_child(UI.text("El juego y el reloj están detenidos. Puedes seguir cuando quieras.", 25))
	var resume_button := UI.button("▶ Continuar", Color("#197d4b"))
	resume_button.pressed.connect(func():
		_close_dialog()
		if is_instance_valid(arcade) and arcade.awaiting_gate >= 0: _show_gate(arcade.awaiting_gate, false)
	)
	stack.add_child(resume_button)
	var leave := UI.button("Guardar y volver a los caminos" if topic_id == "level_game" else "Terminar partida", UI.BLUE)
	leave.pressed.connect(func():
		if topic_id == "level_game":
			_save_route()
			_show_map()
		else: _finish_game()
	)
	stack.add_child(leave)
	audio.speak("pause")

func _process(delta: float) -> void:
	elapsed += delta
	if view != "quick" or is_instance_valid(dialog): return
	if duration > 0:
		time_left = maxf(0, time_left - delta)
		subtitle.text = "%d aciertos · %d puntos · Tiempo: %d s" % [solved, score, ceili(time_left)]
		if time_left <= 0:
			_finish_game()
			return
	if delayed_next >= 0:
		delayed_next -= delta
		if delayed_next <= 0: _next_quick()

func _go_back() -> void:
	if is_instance_valid(dialog):
		if dialog_kind == "gate": _show_pause()
		else:
			_close_dialog()
			if is_instance_valid(arcade) and arcade.awaiting_gate >= 0: _show_gate(arcade.awaiting_gate, false)
		return
	if view in ["hub", "setup", "map"]:
		audio.stop()
		back_requested.emit()
	elif topic_id in Catalog.OPERATIONS: _show_hub()
	elif topic_id == "level_game":
		_save_route()
		_show_map()
	else: _show_setup()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(dialog): _go_back()
		elif view in ["adventure", "quick"]: _show_pause()
		else: _go_back()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(dialog) or view not in ["practice", "exercise"]: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.unicode >= 48 and event.unicode <= 57: _key(char(event.unicode))
		elif event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9: _key(str(event.keycode - KEY_KP_0))
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]: _submit()
		elif event.keycode == KEY_BACKSPACE: _key("⌫")
		else: return
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_inside_tree() and view == "quick" and not is_instance_valid(dialog): _show_pause()

func _exit_tree() -> void:
	_save_route()
	if is_instance_valid(arcade): arcade.clear_input()
	if is_instance_valid(audio): audio.stop()
