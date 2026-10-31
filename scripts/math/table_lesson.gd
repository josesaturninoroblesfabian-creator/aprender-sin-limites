extends HBoxContainer

const UI = preload("res://scripts/math/math_ui.gd")
const Tables = preload("res://scripts/math/operation_tables.gd")
const Catalog = preload("res://scripts/math/activity_catalog.gd")
const Guide = preload("res://scripts/math/llama_guide.gd")
const Visual = preload("res://scripts/math/table_model.gd")
var operation := "addition"
var audio: Node
var number := 1
var selected_index := 0
var mode := "stopped"
var gap := -1.0
var rows: Array[Dictionary] = []
var table_buttons: Array[Button] = []
var row_buttons: Array[Button] = []
var title: Label
var idea: Label
var progress: Label
var equation: Label
var play_button: Button
var previous_button: Button
var next_button: Button
var lines: HBoxContainer
var line_scrolls: Array[ScrollContainer] = []
var model: Control

func _ready() -> void:
	name = "OperationTables"
	add_theme_constant_override("separation", 14)
	size_flags_vertical = SIZE_EXPAND_FILL
	audio.player.finished.connect(_on_finished)
	_build()
	select_table(1)

func _build() -> void:
	var selector := UI.paper(self)
	selector.get_parent().custom_minimum_size.x = 264
	selector.get_parent().size_flags_horizontal = SIZE_FILL
	selector.add_child(UI.text("Tablas del 1 al 15", 24, Catalog.COLORS[operation]))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 7)
	selector.add_child(grid)
	for value in range(1, 16):
		var button := UI.button(str(value), Catalog.COLORS[operation], 26)
		button.name = "Table_%02d" % value
		button.custom_minimum_size = Vector2(66, 48)
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.tooltip_text = "Tabla del %d" % value
		button.pressed.connect(select_table.bind(value))
		grid.add_child(button)
		table_buttons.append(button)
	var guide := Guide.new()
	guide.audio = audio
	guide.custom_minimum_size = Vector2(150, 80)
	guide.size_flags_vertical = SIZE_EXPAND_FILL
	selector.add_child(guide)
	idea = UI.text("", 17)
	selector.add_child(idea)
	var paper := UI.paper(self)
	paper.add_theme_constant_override("separation", 5)
	var header := UI.row(paper, 7)
	previous_button = UI.button("‹", Catalog.COLORS[operation], 24)
	previous_button.name = "PreviousTable"
	previous_button.custom_minimum_size.x = 48
	previous_button.custom_minimum_size.y = 48
	previous_button.pressed.connect(func(): select_table(number - 1))
	header.add_child(previous_button)
	title = UI.text("", 26, Catalog.COLORS[operation])
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)
	next_button = UI.button("›", Catalog.COLORS[operation], 24)
	next_button.name = "NextTable"
	next_button.custom_minimum_size.x = 48
	next_button.custom_minimum_size.y = 48
	next_button.pressed.connect(func(): select_table(number + 1))
	header.add_child(next_button)
	var controls := UI.row(paper, 8)
	play_button = UI.button("▶ Reproducir tabla", Color("#b12672"), 20)
	play_button.name = "PlayTable"
	play_button.size_flags_horizontal = SIZE_EXPAND_FILL
	play_button.custom_minimum_size.y = 48
	play_button.pressed.connect(toggle_playback)
	controls.add_child(play_button)
	var stop_button := UI.button("■ Parar", UI.BLUE, 19)
	stop_button.name = "StopTable"
	stop_button.custom_minimum_size.y = 48
	stop_button.pressed.connect(stop)
	controls.add_child(stop_button)
	progress = UI.text("", 17)
	paper.add_child(progress)
	lines = UI.row(paper, 12)
	lines.size_flags_vertical = SIZE_EXPAND_FILL
	for column in range(3):
		var scroll := ScrollContainer.new()
		scroll.name = "TableColumn%d" % column
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_horizontal = SIZE_EXPAND_FILL
		scroll.size_flags_vertical = SIZE_EXPAND_FILL
		scroll.custom_minimum_size.y = 260
		lines.add_child(scroll)
		line_scrolls.append(scroll)
		var stack := UI.column(scroll, 5)
		for index in range(column * 5, (column + 1) * 5):
			var button := UI.button("", UI.BLUE, 23)
			button.name = "Equation_%02d" % (index + 1)
			button.custom_minimum_size.y = 48
			button.size_flags_horizontal = SIZE_EXPAND_FILL
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.pressed.connect(select_row.bind(index, true))
			stack.add_child(button)
			row_buttons.append(button)
	var example := UI.paper(paper, Color("#eaf9ed"))
	example.add_theme_constant_override("separation", 3)
	equation = UI.text("", 23, Catalog.COLORS[operation])
	example.add_child(equation)
	model = Visual.new()
	model.custom_minimum_size.y = 64
	example.add_child(model)

func select_table(value: int) -> void:
	if value < 1 or value > 15: return
	stop()
	number = value
	rows = Tables.table(operation, number)
	title.text = "%s · Tabla del %d" % [Catalog.TITLES[operation], number]
	idea.text = Tables.idea(operation, number)
	previous_button.disabled = number == 1
	next_button.disabled = number == 15
	for index in range(15):
		var button := table_buttons[index]
		var selected := index + 1 == number
		for state in ["normal", "hover", "pressed", "focus"]:
			var fill: Color = Color("#ffbf3f") if selected else Catalog.COLORS[operation]
			if state == "hover": fill = fill.lightened(0.1)
			button.add_theme_stylebox_override(state, UI.style(fill, Color("#bc822f") if selected else fill.darkened(0.2), 15, 8))
			button.add_theme_color_override("font_color" if state == "normal" else "font_" + state + "_color", UI.INK if selected else Color.WHITE)
		row_buttons[index].text = "  " + Tables.expression(operation, rows[index])
	select_row(0)
	for scroll in line_scrolls: scroll.scroll_vertical = 0

func select_row(index: int, narrate: bool = false) -> void:
	if index < 0 or index >= rows.size(): return
	if narrate: stop()
	selected_index = index
	for position in range(row_buttons.size()):
		var selected := position == index
		row_buttons[position].add_theme_stylebox_override("normal", UI.style(Color("#ffedaa") if selected else Color("#edf5ff"), Color("#de9c20") if selected else Color("#bdd4e6"), 12, 7))
		row_buttons[position].add_theme_color_override("font_color", UI.INK)
		for state in ["hover", "pressed", "focus"]:
			row_buttons[position].add_theme_color_override("font_" + state + "_color", UI.INK)
			row_buttons[position].add_theme_stylebox_override(state, UI.style(Color("#ffe092"), Color("#bf821b"), 12, 7))
	equation.text = Tables.expression(operation, rows[index])
	model.set_example(operation, rows[index])
	progress.text = "Operación %d de 15 · Toca para escuchar o reproduce toda la tabla" % (index + 1)
	line_scrolls[index / 5].ensure_control_visible(row_buttons[index])
	if narrate:
		mode = "single"
		_read_selected()

func _read_selected() -> void:
	if not audio.speak_table(rows[selected_index].id):
		stop()
		progress.text = "Activa el sonido para escuchar. Puedes seguir leyendo las operaciones."

func toggle_playback() -> void:
	if mode == "playing":
		mode = "paused"
		audio.player.stream_paused = true
		play_button.text = "▶ Continuar"
		return
	if mode == "paused":
		mode = "playing"
		audio.player.stream_paused = false
		play_button.text = "Ⅱ Pausar"
		return
	stop()
	mode = "playing"
	select_row(0)
	play_button.text = "Ⅱ Pausar"
	_read_selected()

func _on_finished() -> void:
	if mode == "single":
		mode = "stopped"
	elif mode == "playing":
		if selected_index == 14:
			mode = "finished"
			play_button.text = "↻ Repetir tabla"
			progress.text = "¡Tabla completa! Repite, elige otra o practica en las misiones."
		else: gap = 0.55

func stop() -> void:
	mode = "stopped"
	gap = -1
	if is_instance_valid(audio): audio.stop()
	if is_instance_valid(play_button): play_button.text = "▶ Reproducir tabla"

func _process(delta: float) -> void:
	if mode in ["playing", "paused", "single"] and (audio.muted or audio.volume <= 0): stop()
	if mode != "playing" or gap < 0: return
	gap -= delta
	if gap <= 0:
		gap = -1
		select_row(selected_index + 1)
		_read_selected()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_inside_tree(): stop()

func _exit_tree() -> void:
	# The owning activity stops playback before replacing a view. Do not stop
	# a new mission's narration when this queued-for-deletion view exits later.
	if is_instance_valid(audio) and is_instance_valid(audio.player) and audio.player.finished.is_connected(_on_finished):
		audio.player.finished.disconnect(_on_finished)
