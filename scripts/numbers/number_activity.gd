extends Control

signal back_requested
const Catalog = preload("res://scripts/numbers/number_catalog.gd")
const Rules = preload("res://scripts/numbers/number_rules.gd")
const Progress = preload("res://scripts/numbers/number_progress.gd")
const UI = preload("res://scripts/math/math_ui.gd")
const Art = preload("res://scripts/numbers/number_art.gd")
const Audio = preload("res://scripts/numbers/number_audio.gd")
const Guide = preload("res://scripts/math/llama_guide.gd")
const Board = preload("res://scripts/numbers/place_board.gd")
const Block = preload("res://scripts/numbers/block_token.gd")
const Market = preload("res://scripts/numbers/market_counter.gd")
const Bridge = preload("res://scripts/numbers/sequence_bridge.gd")
const Stone = preload("res://scripts/numbers/bridge_choice.gd")
const Balance = preload("res://scripts/numbers/comparison_stage.gd")
const Train = preload("res://scripts/numbers/number_train.gd")

var topic_id := "one_digit"
var view := "hub"
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
var wrong: Dictionary = {}
var hinted: Dictionary = {}
var restored_draft: Dictionary = {}
var round_index := 0
var solved_current := false
var board: Control
var world: Control
var guide_text: Label
var selected_label: Label
var submit_button: Button
var next_button: Button
var model_button: Button
var piece_buttons: Array[Button] = []
var choices: Array[Button] = []
var ordered: Array[int] = []
var order_labels: Array[Label] = []
var model_done := false
var width := 1
var duration := 0.0
var time_left := 0.0
var questions: Array[Dictionary] = []
var score := 0
var train_depart: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not Catalog.TITLES.has(topic_id): topic_id = "one_digit"
	audio = Audio.new()
	add_child(audio)
	_build_shell()
	if topic_id in Catalog.TOPICS: _show_hub()
	else: _show_setup()
	audio.speak(topic_id)

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
	back_button = UI.button("‹ Números", UI.BLUE, 21)
	back_button.custom_minimum_size.x = 145
	back_button.name = "BackToNumbers"
	back_button.pressed.connect(_go_back)
	header.add_child(back_button)
	var sign := UI.paper(header, Color("#fff5d7"))
	heading = UI.text(Catalog.TITLES[topic_id], 28, Catalog.COLORS[topic_id])
	sign.add_child(heading)
	subtitle = UI.text("Descubre el valor de cada cifra", 17)
	sign.add_child(subtitle)
	pause_button = UI.button("Ⅱ Pausa", Color("#71509d"), 18)
	pause_button.pressed.connect(_show_pause)
	header.add_child(pause_button)
	var sound := UI.button("Sonido", Color("#71509d"), 18)
	sound.name = "NumbersSound"
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

func _clear(new_view: String, backdrop: int = 0) -> void:
	_close_dialog()
	if is_instance_valid(world) and world.get("active") != null: world.active = false
	board = null
	world = null
	guide_text = null
	selected_label = null
	train_depart = null
	submit_button = null
	next_button = null
	model_button = null
	piece_buttons.clear()
	choices.clear()
	order_labels.clear()
	ordered.clear()
	_clear_children(content)
	_clear_children(navigation)
	view = new_view
	solved_current = false
	background.texture = Art.backdrop(backdrop)
	heading.text = Catalog.TITLES[topic_id]
	back_button.text = "‹ Números" if view in ["hub", "setup"] else "‹ Misiones" if topic_id in Catalog.TOPICS else "‹ Preparar"
	pause_button.visible = view == "train"
	status.text = ""

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

func _show_hub() -> void:
	_clear("hub")
	subtitle.text = "Cinco misiones · Un descubrimiento y cinco retos en cada una"
	var trail := UI.row(content, 10)
	trail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for item in Catalog.lessons(topic_id):
		var card := UI.button("", Catalog.COLORS[topic_id])
		card.name = "NumbersMission_" + item.id
		card.custom_minimum_size.x = 180
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		trail.add_child(card)
		var inset := MarginContainer.new()
		inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left", "right", "top", "bottom"]: inset.add_theme_constant_override("margin_" + side, 12)
		inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(inset)
		var stack := UI.column(inset, 9)
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var caption := UI.text("MISIÓN %d" % item.tier, 18, Color("#fff0c4"))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(caption)
		stack.add_child(UI.picture(Art.object(7 if Progress.complete(item.id) else [3, 0, 6, 2, 7][int(item.tier) - 1]), Vector2(115, 112)))
		stack.add_child(UI.text(item.title, 23, Color.WHITE))
		stack.add_child(UI.text(item.aim, 18, Color("#fff7df")))
		var spacer := Control.new()
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stack.add_child(spacer)
		stack.add_child(UI.text(UI.stars(Progress.stars(item.id)), 30, Color("#ffdf76")))
		var partial := Progress.resume(item.id)
		var action := "Continuar · %d/5" % partial.answers.size() if not partial.is_empty() else "Repetir →" if Progress.complete(item.id) else "Descubrir →"
		stack.add_child(UI.text(action, 19, Color("#fff0b3")))
		card.pressed.connect(_start_lesson.bind(String(item.id)))
	status.text = "Puedes elegir cualquier misión. Abrirla no suma progreso; completarla sí."
	_nav("Escuchar la guía", func(): audio.speak(topic_id), Catalog.COLORS[topic_id])

func _start_lesson(id: String) -> void:
	lesson = Catalog.find(id)
	if lesson.is_empty() or lesson.topic != topic_id: return
	width = int(lesson.width)
	answers.clear()
	wrong.clear()
	hinted.clear()
	restored_draft.clear()
	var saved := Progress.resume(id)
	if not saved.is_empty():
		answers = saved.answers
		for key in saved.wrong: wrong[key] = true
		for key in saved.hinted: hinted[key] = true
		restored_draft = saved.draft
		_next_unsolved()
		if round_index >= 5: _finish_lesson()
		else: _render_question()
		audio.speak("resume")
	else: _show_model()

func _show_model() -> void:
	_clear("model")
	model_done = false
	question = lesson.model
	heading.text = lesson.title
	subtitle.text = "1. Mira el ejemplo · 2. Hazlo tú · 3. Practica cinco retos"
	var split := UI.row(content, 12)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := UI.paper(split)
	paper.add_child(UI.text("Vamos a formar " + str(lesson.model_number) if question.kind == "build" else question.text, 25, Catalog.COLORS[topic_id]))
	match question.kind:
		"build":
			board = Board.new()
			paper.add_child(board)
			board.setup(0, width)
			if int(lesson.exchange_place) >= 0:
				var parts := Rules.digits(0, width)
				parts[int(lesson.exchange_place)] = 10
				board.set_counts(parts)
				board.editable = false
				model_button = _nav("Cambiar 10 piezas por 1", _exchange_model, Catalog.COLORS[topic_id])
			else:
				_block_tray(paper)
				model_button = _nav("Comprobar", _check_model, Catalog.COLORS[topic_id])
		"order":
			_order_controls(paper)
			model_button = _nav("Comprobar orden", _check_model, Catalog.COLORS[topic_id])
		"place":
			board = Board.new()
			paper.add_child(board)
			board.setup(int(question.number), width, false)
			board.highlighted = int(question.place)
			board.show_total = false
			_number_choices(paper, question)
		"neighbor":
			_neighbor_path(paper)
			_number_choices(paper, question)
		_:
			var clue := UI.text(String(question.get("written", Rules.decomposition(int(question.number), width))), 33, Catalog.COLORS[topic_id])
			clue.size_flags_vertical = Control.SIZE_EXPAND_FILL
			clue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			clue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			paper.add_child(clue)
			_number_choices(paper, question)
	var guidance := _task_instruction(question.kind)
	if question.kind == "build" and int(lesson.exchange_place) >= 0:
		guidance = "Toca Cambiar 10 piezas por 1. Mira cómo pasan a la columna izquierda. La cantidad seguirá siendo la misma."
	_companion(split, String(lesson.aim) + "\n\n" + guidance)
	next_button = _nav("Practicar cinco retos →", _begin_practice, Color("#21804e"))
	next_button.disabled = true
	_nav("Repetir ejemplo", _show_model, Color("#75509e"))
	if question.kind == "build" and int(lesson.exchange_place) < 0:
		_nav("Cómo mover las piezas", func(): audio.speak("blocks"), Color("#147b8a"))
	status.text = guidance
	audio.speak(String(question.id) if int(lesson.exchange_place) < 0 else ["exchange_units", "exchange_tens", "exchange_hundreds"][int(lesson.exchange_place)])

func _task_instruction(kind: String) -> String:
	match kind:
		"build": return "Arrastra una pieza a su columna, o toca Añadir. Usa Quitar si sobra alguna."
		"read": return "Escucha o lee el nombre. Toca el número que corresponde."
		"compose": return "Junta el valor de las partes y toca el número completo."
		"place": return "Mira la columna marcada. Toca cuánto vale esa cifra, no solo cómo se llama."
		"neighbor": return "Mira el número del centro. Toca el que va antes o después, según la pregunta."
		"order": return "Toca primero el menor, después el siguiente y al final el mayor."
	return "Escucha, observa y elige."

func _review_model() -> void:
	_save_attempt()
	_show_model()

func _block_tray(parent: Node) -> void:
	selected_label = UI.text("Arrastra una pieza a su columna o toca Añadir:", 18)
	parent.add_child(selected_label)
	var row := UI.row(parent, 8)
	var labels := ["unidad", "decena", "centena", "millar"]
	for place in range(width - 1, -1, -1):
		var button := Block.new()
		button.place = place
		button.board = board
		button.name = "AddPiece_" + str(place)
		button.text = "Añadir 1 " + labels[place] + "\nVale " + str(int(pow(10, place)))
		button.tooltip_text = "Arrastra esta pieza a " + Board.NAMES[place] + ". Para quitarla puedes devolverla aquí."
		button.custom_minimum_size = Vector2(135, 66)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 17)
		var color: Color = Rules.COLORS[place]
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var box := UI.style(color.lightened(0.85) if state != "disabled" else Color("#e5e3d6"), color, 12, 6)
			box.content_margin_left = 52
			button.add_theme_stylebox_override(state, box)
			button.add_theme_color_override("font_" + ("color" if state == "normal" else state + "_color"), color.darkened(0.3))
		row.add_child(button)
		piece_buttons.append(button)
	board.changed.connect(func(_value: int):
		audio.effect("tap")
		_update_construction_guide()
		if view == "practice": _save_attempt()
	)
	board.rejected.connect(func(message: String):
		status.text = message
		audio.effect("retry")
	)

func _update_construction_guide() -> void:
	if not is_instance_valid(board) or not is_instance_valid(guide_text): return
	var total := Rules.value(board.counts)
	var target := int(lesson.model_number) if view == "model" else int(question.result)
	guide_text.text = "Queremos formar " + str(target) + ".\n\nAhora tienes " + str(total) + ":\n" + Rules.decomposition(total, width) + "."
	if total == target and Rules.canonical(board.counts, width):
		guide_text.text += "\n\n¡Ya está formado! Pulsa Comprobar."
	else: guide_text.text += "\n\nCada pieza aporta su valor. Añade o quita las que necesites."

func _reset_construction() -> void:
	if not is_instance_valid(board) or not board.editable: return
	board.motions.clear()
	board.set_counts(Rules.digits(0, width))
	board.changed.emit(0)

func _exchange_model() -> void:
	if view != "model" or model_done: return
	board.editable = true
	var changed: bool = board.exchange(int(lesson.exchange_place))
	board.editable = false
	if changed:
		guide_text.text = "%d = %d.\nLa cantidad no cambió.\n\n%s" % [int(lesson.model_number), Rules.value(board.counts), Rules.decomposition(int(lesson.model_number), width)]
		_complete_model()

func _check_model() -> void:
	if view != "model" or model_done: return
	if question.kind == "order":
		_model_choice(ordered.duplicate())
	elif is_instance_valid(board):
		if Rules.canonical(board.counts, width) and Rules.value(board.counts) == int(lesson.model_number):
			_complete_model()
		else:
			status.text = _construction_correction(int(lesson.model_number))
			audio.effect("retry")

func _model_choice(answer: Variant) -> void:
	if view != "model" or model_done: return
	if Rules.matches(question, answer): _complete_model()
	else:
		status.text = _task_instruction(question.kind) + " Puedes volver a intentar."
		audio.effect("retry")

func _construction_correction(target: int) -> String:
	if not is_instance_valid(board): return "Revisa la respuesta."
	var wanted := Rules.digits(target, width)
	for place in range(width - 1, -1, -1):
		if board.counts[place] != wanted[place]:
			return "Revisa " + Board.NAMES[place] + ": necesitamos " + str(wanted[place]) + (" pieza" if wanted[place] == 1 else " piezas") + ", pero hay " + str(board.counts[place]) + "."
	return "Cambia diez piezas por una de la columna izquierda."

func _complete_model() -> void:
	model_done = true
	solved_current = true
	if is_instance_valid(board): board.editable = false
	for button in piece_buttons: button.disabled = true
	for button in choices: button.disabled = true
	if is_instance_valid(model_button): model_button.disabled = true
	next_button.disabled = false
	guide_text.text = _explanation() + "\n\nEste fue un ejemplo. Ahora tendrás cinco retos parecidos para hacerlo tú."
	status.text = "¡Ejemplo entendido! Pulsa Practicar cinco retos."
	audio.effect("correct")
	audio.speak("model_done")

func _begin_practice() -> void:
	if view != "model" or not model_done: return
	_next_unsolved()
	var saved := Progress.resume(lesson.id)
	restored_draft = saved.get("draft", {})
	_render_question()

func _next_unsolved() -> void:
	round_index = 0
	while round_index < 5 and answers.has(lesson.questions[round_index].id): round_index += 1

func _render_question() -> void:
	if round_index >= 5:
		_finish_lesson()
		return
	_clear("practice")
	question = lesson.questions[round_index]
	heading.text = lesson.title
	subtitle.text = "Reto %d de 5 · Sin reloj · Puedes pedir una pista" % (round_index + 1)
	var split := UI.row(content, 12)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := UI.paper(split)
	paper.add_child(UI.text(question.text, 23, Catalog.COLORS[topic_id]))
	_companion(split, _task_instruction(question.kind) + "\n\n" + String(lesson.aim))
	match question.kind:
		"build":
			board = Board.new()
			paper.add_child(board)
			board.setup(0, width)
			_block_tray(paper)
			submit_button = _nav("Comprobar", _submit_build, Catalog.COLORS[topic_id])
			_nav("Vaciar", _reset_construction, Color("#846125"))
		"place":
			board = Board.new()
			paper.add_child(board)
			board.setup(int(question.number), width, false)
			board.highlighted = int(question.place)
			board.show_total = false
			_number_choices(paper, question)
		"order":
			_order_controls(paper)
			submit_button = _nav("Comprobar orden", func(): _submit(ordered.duplicate()), Catalog.COLORS[topic_id])
		"neighbor":
			_neighbor_path(paper)
			_number_choices(paper, question)
		_:
			var spacer := Control.new()
			spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
			paper.add_child(spacer)
			paper.add_child(UI.picture(Art.object(6), Vector2(95, 100)))
			var clue := String(question.get("written", Rules.decomposition(int(question.number), width)))
			var label := UI.text(clue, 37, Catalog.COLORS[topic_id])
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			paper.add_child(label)
			var space2 := Control.new()
			space2.size_flags_vertical = Control.SIZE_EXPAND_FILL
			paper.add_child(space2)
			_number_choices(paper, question)
	_nav("Ver pista", _show_hint, Color("#75509e"))
	_nav("Escuchar", _speak_question, Color("#147b8a"))
	if view == "practice": _nav("Ver ejemplo", _review_model, Color("#846125"))
	next_button = _nav("Siguiente →", _next_round, Color("#21804e"))
	next_button.disabled = true
	_restore_draft()
	status.text = _task_instruction(question.kind)
	_speak_question()

func _number_choices(parent: Node, item: Dictionary, bridge: bool = false) -> void:
	var row := UI.row(parent, 10)
	for value_ in Rules.options(item):
		var button: Button
		if bridge:
			button = Stone.new()
			button.value = value_
			button.add_theme_stylebox_override("normal", UI.style(Color("#fff3d1"), Color("#9c8050"), 20, 10))
			button.add_theme_color_override("font_color", Color("#194b68"))
			for state in ["hover", "pressed", "focus"]:
				button.add_theme_color_override("font_" + state + "_color", Color("#194b68"))
				button.add_theme_stylebox_override(state, UI.style(Color("#ffe3a3"), Color("#9c8050"), 20, 10))
			button.add_theme_stylebox_override("disabled", UI.style(Color("#e5e3d6"), Color("#aba994"), 20, 10))
			button.add_theme_color_override("font_disabled_color", Color("#61717b"))
		else: button = UI.button(str(value_), Color("#126f9c"), 31)
		button.text = str(value_)
		button.set_meta("answer", value_)
		button.name = "Answer_" + str(value_)
		button.custom_minimum_size = Vector2(100, 64)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 31)
		button.pressed.connect(_submit.bind(value_))
		row.add_child(button)
		choices.append(button)

func _neighbor_path(parent: Node) -> void:
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(space)
	var row := UI.row(parent, 9)
	for offset in range(-2, 3):
		var value_ := int(question.number) + offset
		var text := "?" if offset == int(question.offset) else str(value_)
		if value_ < (0 if width == 1 else int(pow(10, width - 1))) or value_ >= int(pow(10, width)): text = "·"
		var tile := UI.paper(row, Color("#fff0c4") if offset == 0 else Color("#eaf6fd"))
		var label := UI.text(text, 32, Color("#165477"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(label)
	var second := Control.new()
	second.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(second)

func _order_controls(parent: Node) -> void:
	parent.add_child(UI.text("Toca primero el menor, después el siguiente y al final el mayor.", 20))
	var target := UI.row(parent, 12)
	for i in range(3):
		var tile := UI.paper(target, Color("#fff0ca"))
		var label := UI.text("·", 37, Color("#966016"))
		label.custom_minimum_size.y = 65
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(label)
		order_labels.append(label)
	var options := UI.row(parent, 12)
	for value_ in question.values:
		var button := UI.button(str(value_), Color("#1b7d9c"), 33)
		button.set_meta("answer", value_)
		button.custom_minimum_size.y = 90
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func():
			if solved_current or ordered.size() >= 3: return
			ordered.append(value_)
			button.disabled = true
			_refresh_order()
			_save_attempt()
			audio.effect("tap")
		)
		options.add_child(button)
		choices.append(button)
	var undo := UI.button("↶ Quitar el último", Color("#8c6831"), 21)
	undo.pressed.connect(func():
		if solved_current or ordered.is_empty(): return
		var last: int = ordered.pop_back()
		for button in choices:
			if button.get_meta("answer") == last: button.disabled = false
		_refresh_order()
		_save_attempt()
	)
	parent.add_child(undo)

func _refresh_order() -> void:
	for i in range(order_labels.size()): order_labels[i].text = str(ordered[i]) if i < ordered.size() else "·"

func _submit_build() -> void:
	if not is_instance_valid(board): return
	if not Rules.canonical(board.counts, width):
		status.text = "Cada columna debe tener una cifra del 0 al 9. Canjea o elige su cifra."
		return
	_submit(Rules.value(board.counts))

func _save_attempt() -> void:
	if view != "practice" or lesson.is_empty(): return
	var draft := {}
	if not solved_current:
		draft = {"id": question.id}
		if is_instance_valid(board) and question.kind == "build": draft.counts = board.counts.duplicate()
		if question.kind == "order": draft.order = ordered.duplicate()
	Progress.save_resume(lesson.id, answers, wrong.keys(), hinted.keys(), draft)

func _restore_draft() -> void:
	if restored_draft.get("id", "") != question.id: return
	if question.kind == "build" and is_instance_valid(board):
		var counts: Variant = restored_draft.get("counts", [])
		if counts is Array and board.valid_counts(counts): board.set_counts(counts)
	elif question.kind == "order":
		var values: Variant = restored_draft.get("order", [])
		if values is Array:
			for value_ in values:
				if value_ in question.values and value_ not in ordered: ordered.append(int(value_))
			for button in choices: button.disabled = button.get_meta("answer") in ordered
			_refresh_order()
	restored_draft.clear()

func _submit(answer: Variant) -> void:
	if view == "model":
		_model_choice(answer)
		return
	if solved_current or is_instance_valid(dialog) or view not in ["practice", "market", "bridge", "compare", "train"]: return
	if view == "market" and world.marked.size() != world.total:
		status.text = "Primero toca todos los productos una sola vez."
		return
	if view == "practice" and question.kind == "order" and ordered.size() != 3:
		status.text = "Coloca los tres números antes de comprobar."
		return
	var correct: bool = answer == question.result if view == "compare" else Rules.matches(question, answer)
	if not correct:
		wrong[question.id] = true
		_save_attempt()
		for button in choices:
			if question.kind != "order" and button.get_meta("answer") == answer: button.disabled = true
		if view == "train": world.reject()
		status.text = _construction_correction(int(question.result)) if view == "practice" and question.kind == "build" else "Todavía no. " + _task_instruction(String(question.kind))
		audio.effect("retry")
		audio.speak("retry")
		return
	solved_current = true
	var clean := not wrong.has(question.id) and not hinted.has(question.id)
	answers[question.id] = {"answer": question.result, "first": clean}
	score += 10 if clean else 5
	if view != "practice": _update_game_subtitle()
	for button in choices: button.disabled = true
	for button in piece_buttons: button.disabled = true
	if is_instance_valid(board): board.editable = false
	if is_instance_valid(submit_button): submit_button.disabled = true
	if is_instance_valid(next_button): next_button.disabled = false
	if view == "bridge": world.solved = true
	if view == "compare": world.solved = true
	if view == "train":
		world.accept()
		train_depart.disabled = true
	status.text = _explanation()
	if is_instance_valid(guide_text): guide_text.text = _explanation()
	_save_attempt()
	audio.effect("correct")
	audio.speak("sequence_done" if view == "bridge" else "comparison_done" if view == "compare" else "correct")

func _explanation() -> String:
	if view == "compare": return "%d %s %d. La boca abierta mira al mayor; si coinciden, usamos =." % [int(question.left), question.result, int(question.right)]
	if question.kind == "sequence": return ("¡Puente completo! " if view == "bridge" else "¡Entrega correcta! ") + Rules.sequence_hint(question).split("\n")[0]
	if question.kind == "order": return "¡En orden! " + " < ".join(PackedStringArray(question.result.map(func(n): return str(n))))
	if question.kind == "place": return "El %d está en %s y vale %d." % [Rules.digits(int(question.number), width)[int(question.place)], Rules.PLACES[int(question.place)], int(question.result)]
	if question.kind == "neighbor": return ("Después de %d viene %d." if int(question.offset) > 0 else "Antes de %d está %d.") % [int(question.number), int(question.result)]
	if question.kind == "read": return String(question.written).capitalize() + " se escribe " + str(int(question.number)) + "."
	return "%d = %s" % [int(question.result), Rules.numeric_parts(int(question.result), int(question.width))]

func _next_round() -> void:
	if not solved_current: return
	if view == "practice":
		_next_unsolved()
		if round_index >= 5: _finish_lesson()
		else: _render_question()
	else:
		round_index += 1
		if round_index >= questions.size(): _finish_game()
		else: _render_game()

func _finish_lesson() -> void:
	var error := Progress.finish_lesson(lesson.id, answers)
	_clear("result")
	subtitle.text = "Cinco retos resueltos · Puedes repetir para mejorar"
	var paper := UI.paper(content)
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	paper.add_child(UI.picture(Art.object(7), Vector2(150, 155)))
	var label := UI.text("¡Misión completada!" if error == OK else "Terminaste los retos", 37, Catalog.COLORS[topic_id])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paper.add_child(label)
	var stars := UI.text(UI.stars(Progress.stars(lesson.id)), 66, Color("#b47b13"))
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paper.add_child(stars)
	paper.add_child(UI.text(lesson.aim, 25))
	status.text = "Avance guardado en este dispositivo." if error == OK else "No se pudo guardar. Conserva esta pantalla y vuelve a intentarlo."
	if error != OK: _nav("Reintentar guardado", _finish_lesson, Catalog.COLORS[topic_id])
	_nav("Volver a misiones", _show_hub, Catalog.COLORS[topic_id])
	_nav("Practicar otra vez", func():
		answers.clear()
		wrong.clear()
		hinted.clear()
		restored_draft.clear()
		_show_model()
	)
	audio.effect("finish")
	audio.speak("done")

func _show_setup() -> void:
	_clear("setup", 1 if topic_id == "count_objects" else 2 if topic_id in ["sequences", "compare"] else 3)
	subtitle.text = "Prepara tu aventura · Todo funciona sin conexión"
	var split := UI.row(content, 14)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper := UI.paper(split)
	var index: int = {"count_objects": 3, "sequences": 2, "compare": 7, "quick_challenge": 0}[topic_id]
	paper.add_child(UI.picture(Art.object(index), Vector2(135, 145)))
	var descriptions := {
		"count_objects": "Cuenta en el mercado. Cada producto viaja a tu canasta. Al completar diez aparece un grupo de diez. Hay ocho rondas, incluida una canasta vacía.",
		"sequences": "A la llama le falta una piedra para cruzar. Encuentra la regla, elige el número que falta y completa el puente. Ocho puentes por viaje.",
		"compare": "Observa las columnas de los dos números. Elige >, < o =. Comprueba tu decisión con la balanza. Ocho comparaciones por viaje.",
		"quick_challenge": "Escucha el reto, elige una de las cuatro vías y pulsa Viajar. Cada respuesta correcta entrega un paquete. Ocho estaciones sin reloj, o el tiempo que elijas."
	}
	paper.add_child(UI.text(descriptions[topic_id], 24))
	if topic_id != "count_objects":
		paper.add_child(UI.text("¿Con cuántas cifras jugamos?", 21))
		var sizes := UI.row(paper, 10)
		for n in range(1, 5):
			var select := UI.button(("✓ " if width == n else "") + str(n) + (" cifra" if n == 1 else " cifras"), Color("#176f95"), 21)
			select.name = "Width_" + str(n)
			select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			select.pressed.connect(func():
				width = n
				_show_setup()
			)
			sizes.add_child(select)
	else: width = 2
	if topic_id == "quick_challenge":
		var clocks := UI.row(paper, 10)
		for seconds in [0, 90, 120]:
			var select := UI.button(("✓ " if int(duration) == seconds else "") + ("Sin reloj" if seconds == 0 else str(seconds) + " segundos"), Color("#75509e"), 20)
			select.name = "Clock_" + str(seconds)
			select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			select.pressed.connect(func():
				duration = seconds
				_show_setup()
			)
			clocks.add_child(select)
	_companion(split, "Sin prisa para aprender.\n\nEscucha, prueba y pide ayuda. Los errores permiten volver a intentar.")
	var best := Progress.game_record(topic_id, width)
	if not best.is_empty(): guide_text.text += "\n\nMejor resultado:\n%d puntos\n%s" % [int(best.get("score", 0)), UI.stars(int(best.get("stars", 0)))]
	status.text = "Tus juegos y misiones guardan sus resultados por separado."
	_nav("¡Empezar aventura!", _start_game, Catalog.COLORS[topic_id])
	_nav("Escuchar cómo jugar", func(): audio.speak(topic_id), Color("#147b8a"))

func _start_game() -> void:
	answers.clear()
	wrong.clear()
	hinted.clear()
	questions.clear()
	round_index = 0
	score = 0
	time_left = duration
	if topic_id == "count_objects":
		var totals: Array = Catalog.load_data().market_totals
		for i in range(totals.size()): questions.append({"id": "market_" + str(i), "kind": "market", "number": totals[i], "result": totals[i], "width": 1 if int(totals[i]) < 10 else 2, "audio": "count"})
	else:
		questions = Catalog.games("sequences" if topic_id == "sequences" else "comparisons" if topic_id == "compare" else "train", width)
		questions.shuffle()
		if topic_id == "quick_challenge" and duration <= 0: questions = questions.slice(0, 8)
	_render_game()

func _render_game() -> void:
	var game_view: String = {"count_objects": "market", "sequences": "bridge", "compare": "compare", "quick_challenge": "train"}[topic_id]
	_clear(game_view, 1 if game_view == "market" else 2 if game_view in ["bridge", "compare"] else 3)
	question = questions[round_index]
	_update_game_subtitle()
	if game_view == "train":
		var prompt := UI.paper(content, Color("#fff8df"))
		prompt.add_child(UI.text(question.text, 26, Color("#63438f")))
		world = Train.new()
		content.add_child(world)
		world.setup(Rules.options(question))
		world.arrived.connect(_submit)
		world.lane_changed.connect(func(index: int):
			status.text = "Vía %d elegida. Pulsa Viajar para entregar en %d." % [index + 1, world.options[index]]
		)
		train_depart = _nav("▶ Viajar", _depart_train, Catalog.COLORS[topic_id])
		train_depart.name = "TrainDepart"
	else:
		var stage: Node = content
		if game_view in ["market", "compare"]:
			var paper := UI.paper(content, Color("#fffae9"))
			paper.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
			stage = paper
		if game_view == "market":
			world = Market.new()
			stage.add_child(world)
			world.setup(int(question.result), round_index % 3)
			world.changed.connect(func(_count: int):
				audio.effect("tap")
				var ready: bool = world.marked.size() == world.total
				for button in choices: button.disabled = not ready
				status.text = "Ya puedes elegir el total." if ready else "Cada producto marcado viaja a la canasta una sola vez."
			)
			_number_choices(stage, question)
			for button in choices: button.disabled = int(question.result) > 0
		elif game_view == "bridge":
			question.kind = "sequence"
			question.number = int(question.result)
			world = Bridge.new()
			stage.add_child(world)
			world.setup(question)
			world.answer_selected.connect(_submit)
			_number_choices(stage, question, true)
		else:
			question.kind = "comparison"
			world = Balance.new()
			stage.add_child(world)
			world.setup(question)
			var row := UI.row(stage, 14)
			for sign_ in ["<", "=", ">"]:
				var choice := UI.button(sign_ + "  " + {"<": "menor que", "=": "igual a", ">": "mayor que"}[sign_], Color("#a6386b"), 28)
				choice.set_meta("answer", sign_)
				choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				choice.pressed.connect(_submit.bind(sign_))
				row.add_child(choice)
				choices.append(choice)
	_nav("Ver pista", _show_hint, Color("#75509e"))
	_nav("Escuchar", _speak_question, Color("#147b8a"))
	next_button = _nav("Siguiente →", _next_round, Color("#21804e"))
	next_button.disabled = true
	status.text = {
		"train": "Toca la vía y pulsa Viajar. También puedes usar 1–4 o flechas arriba y abajo.",
		"market": "Toca todos los productos; después elige cuántos hay." if int(question.result) > 0 else "No hay productos. ¿Qué número representa la canasta vacía?",
		"bridge": "Busca cuánto cambia cada paso y completa el hueco.",
		"compare": "Empieza por la columna izquierda que sea diferente."
	}[game_view]
	_speak_question()

func _depart_train() -> void:
	if view != "train" or solved_current or is_instance_valid(dialog): return
	if world.depart():
		audio.effect("jump")
		status.text = "El paquete viaja a su estación…"

func _update_game_subtitle() -> void:
	if topic_id == "quick_challenge":
		subtitle.text = "%d %s · %d puntos · %s" % [answers.size(), "entrega" if answers.size() == 1 else "entregas", score, "Sin reloj · ocho estaciones" if duration <= 0 else "%d segundos" % ceili(time_left)]
	else: subtitle.text = "Ronda %d de 8 · %d puntos · Sin reloj" % [round_index + 1, score]

func _finish_game() -> void:
	var error := Progress.finish_game(topic_id, width, answers, score)
	var before := Progress.game_record(topic_id, width)
	_clear("game_result", 3)
	subtitle.text = "Tu mejor resultado se conserva al repetir"
	var paper := UI.paper(content)
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	paper.add_child(UI.picture(Art.object(7), Vector2(145, 150)))
	var title := UI.text("¡Buen viaje!", 39, Catalog.COLORS[topic_id])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	paper.add_child(title)
	paper.add_child(UI.text("%d retos resueltos · %d puntos en esta partida" % [answers.size(), score], 29))
	paper.add_child(UI.text("Mejor resultado: %d puntos · %s" % [int(before.get("score", 0)), UI.stars(int(before.get("stars", 0)))], 29, Color("#a46d13")))
	var partial := topic_id != "quick_challenge" and answers.size() < 8
	status.text = "Resultado guardado en este dispositivo." if error == OK else "Completa las ocho rondas para guardar el resultado." if partial else "Juega al menos una estación completa para guardar un resultado." if answers.is_empty() else "No se pudo guardar el resultado. Puedes reintentar."
	if error != OK and not partial and not answers.is_empty(): _nav("Reintentar guardado", _finish_game, Catalog.COLORS[topic_id])
	_nav("Jugar otra vez", _start_game, Catalog.COLORS[topic_id])
	_nav("Elegir aventura", _show_setup)
	audio.effect("finish")
	audio.speak("finish")

func _modal(title: String, kind: String) -> VBoxContainer:
	_close_dialog()
	dialog_kind = kind
	if is_instance_valid(world) and world.get("active") != null: world.active = false
	dialog = Control.new()
	dialog.name = "NumbersDialog"
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dialog)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.08, 0.16, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size.x = 760
	card.add_theme_stylebox_override("panel", UI.style(Color("#fff8e4"), Catalog.COLORS[topic_id], 23, 23))
	center.add_child(card)
	var stack := UI.column(card, 13)
	stack.add_child(UI.text(title, 31, Catalog.COLORS[topic_id]))
	return stack

func _close_dialog() -> void:
	if is_instance_valid(dialog):
		dialog.hide()
		dialog.queue_free()
	dialog = null
	dialog_kind = ""
	if is_instance_valid(world) and world.get("active") != null: world.active = true
	if is_instance_valid(audio): audio.stop()

func _close_button(parent: Node) -> void:
	var button := UI.button("Seguir aprendiendo", UI.BLUE, 22)
	button.pressed.connect(_close_dialog)
	parent.add_child(button)
	button.grab_focus()

func _show_hint() -> void:
	if question.is_empty() or solved_current or view not in ["practice", "market", "bridge", "compare", "train"]: return
	hinted[question.id] = true
	_save_attempt()
	var text := "Toca cada producto una vez. Cada diez marcados forman una decena. Si no hay ninguno, el total es cero."
	if view == "bridge" or question.kind == "sequence":
		text = Rules.sequence_hint(question)
		if view == "bridge": world.show_rule = true
	elif view == "compare":
		text = Rules.comparison_hint(question)
		world.show_hint = true
	elif view != "market": text = Rules.hint(question)
	var stack := _modal("Pensemos juntos", "hint")
	stack.add_child(UI.text(text, 26))
	stack.add_child(UI.text("Pedir ayuda sirve para aprender. Después vuelve al reto y prueba tu respuesta.", 21))
	_close_button(stack)
	audio.speak("help")

func _show_help() -> void:
	var stack := _modal("La llama te acompaña", "help")
	stack.add_child(UI.text("En el taller: arrastra un cubito, barra, placa o cubo a su columna, o toca Añadir. Usa Quitar para retirar piezas. Diez piezas cambian por una de la columna izquierda sin cambiar la cantidad.", 24))
	stack.add_child(UI.text("En el mercado toca cada producto una vez. En el puente arrastra la piedra o toca su respuesta. Para comparar, empieza por la columna izquierda. En el tren elige vía y pulsa Viajar.", 23))
	stack.add_child(UI.text("Puedes escuchar, pedir pistas y jugar sin reloj. Tu progreso se guarda en este dispositivo y funciona sin internet.", 22))
	_close_button(stack)
	audio.speak("help")

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

func _show_pause() -> void:
	if view != "train": return
	if dialog_kind == "pause":
		_close_dialog()
		return
	var stack := _modal("El tren espera", "pause")
	stack.add_child(UI.text("El viaje y el reloj están detenidos. Puedes continuar cuando quieras.", 25))
	_close_button(stack)
	var finish := UI.button("Terminar partida", Color("#846125"))
	finish.pressed.connect(_finish_game)
	stack.add_child(finish)
	audio.speak("pause")

func _speak_question() -> void:
	if question.is_empty(): return
	var id := String(question.get("audio", "count")).get_file().get_basename()
	audio.speak(id)

func _process(delta: float) -> void:
	if view != "train" or is_instance_valid(dialog) or duration <= 0: return
	# Narration and the review after a correct answer do not consume reading time.
	if solved_current or audio.speaking(): return
	time_left = maxf(0, time_left - delta)
	_update_game_subtitle()
	if time_left <= 0: _finish_game()

func _go_back() -> void:
	if is_instance_valid(dialog):
		_close_dialog()
		return
	_save_attempt()
	if view in ["hub", "setup"]:
		audio.stop()
		back_requested.emit()
	elif topic_id in Catalog.TOPICS: _show_hub()
	else: _show_setup()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey or not event.pressed or event.echo or is_instance_valid(dialog): return
	if view == "train":
		if event.keycode == KEY_P: _show_pause()
		elif event.keycode in [KEY_UP, KEY_DOWN]: world.select_lane(clampi(world.lane + (-1 if event.keycode == KEY_UP else 1), 0, 3))
		elif event.keycode >= KEY_1 and event.keycode <= KEY_4: world.select_lane(event.keycode - KEY_1)
		elif event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]: _next_round() if solved_current else _depart_train()
	elif view in ["model", "practice"] and is_instance_valid(board) and board.editable:
		var digit := -1
		if event.keycode >= KEY_0 and event.keycode <= KEY_9: digit = event.keycode - KEY_0
		elif event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9: digit = event.keycode - KEY_KP_0
		if digit >= 0:
			board.set_digit(digit)
			board.active_place = maxi(0, board.active_place - 1)
		elif event.keycode == KEY_LEFT: board._select_at(board.column_rect(mini(width - 1, board.active_place + 1)).get_center())
		elif event.keycode == KEY_RIGHT: board._select_at(board.column_rect(maxi(0, board.active_place - 1)).get_center())
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]: _check_model() if view == "model" else _submit_build()
	else: return
	get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and view == "train" and not is_instance_valid(dialog): _show_pause()

func _exit_tree() -> void:
	if is_instance_valid(audio): audio.stop()
