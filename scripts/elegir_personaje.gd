extends Control

signal back_requested

const INK := Color("#173b70")
const GOLD := Color("#ffd45b")
const CARD_COLORS: Array[Color] = [
	Color("#ed6a55"), Color("#35a8db"), Color("#f1b938"), Color("#7658c8"),
	Color("#30ad68"), Color("#e45295"), Color("#ef8241"), Color("#23a89c")
]
const ROUNDS_TO_WIN := 5
const CHARACTERS: Array[Dictionary] = [
	{
		"id": "caperucita", "name": "Caperucita Roja", "story": "Caperucita Roja",
		"image": "res://assets/cuentos/caperucita-portada.svg",
		"clue": "Lleva una capa roja y visita a su abuelita por el bosque."
	},
	{
		"id": "patito", "name": "El Patito Feo", "story": "El Patito Feo",
		"image": "res://assets/cuentos/patito-feo-portada.svg",
		"clue": "Es un ave que crece y descubre que es un hermoso cisne."
	},
	{
		"id": "leon", "name": "El León", "story": "El León y el Ratón",
		"image": "res://assets/cuentos/leon-raton-portada.svg",
		"clue": "Es un gran felino que aprende que hasta un ratoncito puede ayudarlo."
	},
	{
		"id": "tortuga", "name": "La Tortuga", "story": "La Liebre y la Tortuga",
		"image": "res://assets/cuentos/liebre-tortuga-portada.svg",
		"clue": "Avanza despacito, sin detenerse, y gana una carrera."
	},
	{
		"id": "pinocho", "name": "Pinocho", "story": "Pinocho",
		"image": "res://assets/cuentos/pinocho-portada.svg",
		"clue": "Es un muñeco de madera que aprende a decir la verdad."
	},
	{
		"id": "gato_botas", "name": "El Gato con Botas", "story": "El Gato con Botas",
		"image": "res://assets/cuentos/gato-botas-portada.svg",
		"clue": "Es un gato muy ingenioso que recorre el reino con sus botas."
	},
	{
		"id": "ricitos", "name": "Ricitos de Oro", "story": "Ricitos de Oro",
		"image": "res://assets/cuentos/ricitos-oro-portada.svg",
		"clue": "Encuentra una casa en el bosque con tres sillas, tres platos y tres camas."
	},
	{
		"id": "zorra", "name": "La Zorra", "story": "La Zorra y las Uvas",
		"image": "res://assets/cuentos/zorra-uvas-portada.svg",
		"clue": "Intenta alcanzar un racimo de uvas que está muy alto."
	}
]

var character_rounds: Array[Dictionary] = []
var round_index := 0
var score := 0
var answered := false
var round_label: Label
var clue_label: Label
var feedback_label: Label
var next_button: Button
var character_grid: GridContainer
var finish_panel: PanelContainer
var finish_label: Label

func _ready() -> void:
	_build_interface()
	_start_game()
	get_viewport().size_changed.connect(_update_grid_columns)
	_update_grid_columns()

func _build_interface() -> void:
	var background := TextureRect.new()
	background.name = "FondoJuego"
	background.texture = load("res://assets/backgrounds/fondo-andes.png") as Texture2D
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.13, 0.28, 0.40)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var safe_area := MarginContainer.new()
	safe_area.name = "MargenSeguro"
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area.add_theme_constant_override("margin_left", 26)
	safe_area.add_theme_constant_override("margin_top", 20)
	safe_area.add_theme_constant_override("margin_right", 26)
	safe_area.add_theme_constant_override("margin_bottom", 20)
	add_child(safe_area)

	var layout := VBoxContainer.new()
	layout.name = "LayoutJuego"
	layout.add_theme_constant_override("separation", 12)
	safe_area.add_child(layout)

	_build_header(layout)
	_build_clue(layout)
	_build_character_grid(layout)
	_build_footer(layout)
	_build_finish_panel(layout)

func _build_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.name = "EncabezadoJuego"
	header.custom_minimum_size.y = 70
	header.add_theme_constant_override("separation", 16)
	parent.add_child(header)

	var back := _button("⌂  Cuentos", Color("#087fd0"), 20, Vector2(165, 62), 21)
	back.name = "VolverACuentos"
	back.pressed.connect(_on_back_pressed)
	header.add_child(back)

	var title_panel := PanelContainer.new()
	title_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_panel.add_theme_stylebox_override("panel", _style(Color("#9b5429"), GOLD, 4, 24, 7))
	header.add_child(title_panel)
	var title := _label("¡Elige un personaje!", 32, Color.WHITE, true)
	title.add_theme_color_override("font_shadow_color", Color("#633516"))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title_panel.add_child(title)

	var progress_panel := PanelContainer.new()
	progress_panel.name = "ProgresoDelJuego"
	progress_panel.custom_minimum_size = Vector2(188, 62)
	progress_panel.add_theme_stylebox_override("panel", _style(Color("#eaf6ff"), Color("#48a9dc"), 3, 19, 4))
	header.add_child(progress_panel)
	round_label = _label("Reto 1 de %d" % ROUNDS_TO_WIN, 17, INK, true)
	progress_panel.add_child(round_label)

func _build_clue(parent: VBoxContainer) -> void:
	var clue_panel := PanelContainer.new()
	clue_panel.name = "PistaDelPersonaje"
	clue_panel.custom_minimum_size.y = 104
	clue_panel.add_theme_stylebox_override("panel", _style(Color("#fff8df"), Color("#f2b836"), 4, 22, 5))
	parent.add_child(clue_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3)
	clue_panel.add_child(stack)
	var heading := _label("Escucha la pista y encuentra quién es", 21, Color("#a34b25"), true)
	stack.add_child(heading)
	clue_label = _label("", 23, INK, true)
	clue_label.name = "TextoDeLaPista"
	clue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(clue_label)

func _build_character_grid(parent: VBoxContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "PersonajesDisponibles"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	character_grid = GridContainer.new()
	character_grid.name = "CuadriculaDePersonajes"
	character_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_grid.add_theme_constant_override("h_separation", 14)
	character_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(character_grid)

	for index in range(CHARACTERS.size()):
		character_grid.add_child(_build_character_card(CHARACTERS[index], index))

func _build_character_card(character: Dictionary, index: int) -> Button:
	var accent: Color = CARD_COLORS[index % CARD_COLORS.size()]
	var card := Button.new()
	card.name = "Personaje_%s" % String(character.id)
	card.custom_minimum_size = Vector2(220, 205)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_ALL
	card.clip_contents = true
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_theme_stylebox_override("normal", _style(Color("#fffaf0"), accent, 4, 20, 5))
	card.add_theme_stylebox_override("hover", _style(Color("#fffdf6"), GOLD, 5, 20, 8))
	card.add_theme_stylebox_override("pressed", _style(Color("#f3eddf"), accent.darkened(0.12), 4, 20, 2))
	card.add_theme_color_override("font_color", INK)
	card.pressed.connect(_on_character_selected.bind(String(character.id)))

	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.add_theme_constant_override("separation", 4)
	stack.offset_left = 9
	stack.offset_top = 9
	stack.offset_right = -9
	stack.offset_bottom = -7
	card.add_child(stack)

	var art_frame := PanelContainer.new()
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.custom_minimum_size.y = 142
	art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_frame.add_theme_stylebox_override("panel", _style(accent.lightened(0.43), accent.darkened(0.1), 2, 13, 0))
	stack.add_child(art_frame)
	var art := TextureRect.new()
	art.name = "Ilustracion"
	art.texture = load(String(character.image)) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 3
	art.offset_top = 3
	art.offset_right = -3
	art.offset_bottom = -3
	art_frame.add_child(art)

	var name_label := _label(String(character.name), 20, INK, true)
	name_label.name = "Nombre"
	name_label.custom_minimum_size.y = 34
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(name_label)
	return card

func _build_footer(parent: VBoxContainer) -> void:
	var footer := HBoxContainer.new()
	footer.name = "RespuestaDelJuego"
	footer.custom_minimum_size.y = 50
	footer.add_theme_constant_override("separation", 12)
	parent.add_child(footer)
	feedback_label = _label("Toca la tarjeta del personaje que describe la pista.", 18, Color.WHITE, false)
	feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(feedback_label)
	next_button = _button("Siguiente reto  ➜", Color("#21a85d"), 19, Vector2(205, 48), 20)
	next_button.name = "SiguienteReto"
	next_button.visible = false
	next_button.pressed.connect(_on_next_pressed)
	footer.add_child(next_button)

func _build_finish_panel(parent: VBoxContainer) -> void:
	finish_panel = PanelContainer.new()
	finish_panel.name = "ResultadoFinal"
	finish_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	finish_panel.add_theme_stylebox_override("panel", _style(Color("#fff8df"), GOLD, 5, 30, 10))
	finish_panel.visible = false
	parent.add_child(finish_panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 18)
	finish_panel.add_child(stack)
	finish_label = _label("", 34, INK, true)
	finish_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(finish_label)
	var replay := _button("↻  Jugar otra vez", Color("#f2a92e"), 22, Vector2(245, 64), 22)
	replay.pressed.connect(_start_game)
	stack.add_child(replay)
	var back := _button("⌂  Volver a Cuentos", Color("#087fd0"), 20, Vector2(245, 58), 22)
	back.pressed.connect(_on_back_pressed)
	stack.add_child(back)

func _start_game() -> void:
	character_rounds.clear()
	var shuffled_characters: Array[Dictionary] = []
	for character in CHARACTERS:
		shuffled_characters.append(character.duplicate())
	shuffled_characters.shuffle()
	for index in range(ROUNDS_TO_WIN):
		character_rounds.append(shuffled_characters[index])
	round_index = 0
	score = 0
	answered = false
	character_grid.visible = true
	finish_panel.visible = false
	feedback_label.visible = true
	next_button.visible = false
	feedback_label.text = "Toca la tarjeta del personaje que describe la pista."
	feedback_label.add_theme_color_override("font_color", Color.WHITE)
	_refresh_round()

func _refresh_round() -> void:
	if round_index >= character_rounds.size():
		_finish_game()
		return
	answered = false
	var target: Dictionary = character_rounds[round_index]
	clue_label.text = String(target.clue)
	round_label.text = "Reto %d de %d   •   ⭐ %d" % [round_index + 1, ROUNDS_TO_WIN, score]
	for card in character_grid.get_children():
		if card is Button:
			card.disabled = false

func _on_character_selected(character_id: String) -> void:
	if answered or round_index >= character_rounds.size():
		return
	var target: Dictionary = character_rounds[round_index]
	if character_id == String(target.id):
		answered = true
		score += 1
		feedback_label.text = "¡Muy bien! Encontraste a %s. ⭐" % String(target.name)
		feedback_label.add_theme_color_override("font_color", Color("#d8ffbb"))
		next_button.text = "Ver resultado  ➜" if round_index == ROUNDS_TO_WIN - 1 else "Siguiente reto  ➜"
		next_button.visible = true
		for card in character_grid.get_children():
			if card is Button:
				card.disabled = true
	else:
		feedback_label.text = "¡Casi! Vuelve a leer la pista y prueba otra tarjeta."
		feedback_label.add_theme_color_override("font_color", Color("#ffe9a7"))

func _on_next_pressed() -> void:
	if not answered:
		return
	round_index += 1
	next_button.visible = false
	feedback_label.add_theme_color_override("font_color", Color.WHITE)
	if round_index >= ROUNDS_TO_WIN:
		_finish_game()
	else:
		feedback_label.text = "¡Siguiente pista! Lee con atención."
		_refresh_round()

func _finish_game() -> void:
	character_grid.visible = false
	feedback_label.visible = false
	next_button.visible = false
	round_label.text = "¡Juego completado!"
	finish_label.text = "¡Lo lograste!\nReconociste %d de %d personajes.\n⭐⭐⭐⭐⭐" % [score, ROUNDS_TO_WIN]
	finish_panel.visible = true

func _update_grid_columns() -> void:
	if character_grid == null:
		return
	var width := get_viewport_rect().size.x
	character_grid.columns = 1 if width < 600.0 else (2 if width < 900.0 else (3 if width < 1120.0 else 4))

func _on_back_pressed() -> void:
	back_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _button(text: String, fill: Color, font_size: int, minimum_size: Vector2, radius: int) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = minimum_size
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color.WHITE)
	result.add_theme_color_override("font_hover_color", Color.WHITE)
	result.add_theme_color_override("font_pressed_color", Color.WHITE)
	_apply_font(result, 700)
	result.add_theme_stylebox_override("normal", _style(fill, Color("#fff0b4"), 3, radius, 4))
	result.add_theme_stylebox_override("hover", _style(fill.lightened(0.12), GOLD, 4, radius, 7))
	result.add_theme_stylebox_override("pressed", _style(fill.darkened(0.1), Color("#fff0b4"), 2, radius, 1))
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return result

func _label(text: String, size: int, color: Color, centered: bool) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if centered:
		result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font(result, 700)
	return result

func _style(fill: Color, border: Color, border_width: int, radius: int, shadow_size: int = 0) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(border_width)
	result.set_corner_radius_all(radius)
	result.set_content_margin_all(8)
	if shadow_size > 0:
		result.shadow_color = Color(0.05, 0.16, 0.24, 0.3)
		result.shadow_size = shadow_size
		result.shadow_offset = Vector2(0, 3)
	return result

func _apply_font(control: Control, weight: int) -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Baloo 2", "Trebuchet MS", "Arial"])
	font.font_weight = weight
	font.fallbacks = [ThemeDB.fallback_font]
	control.add_theme_font_override("font", font)
	control.add_theme_font_override("font", font)