extends Control

signal close_requested

const BACKGROUND_PATH := "res://assets/ui/language/juegos-por-niveles-fondo.png"
const LEVEL_ONE_IMAGE_PATH := "res://assets/games/condor-volador-recolector.png"
const LEVEL_ONE_GAME_PATH := "res://assets/games/condor-andino-abecedario.html"
const LEVEL_TWO_IMAGE_PATH := "res://assets/games/encuentra-la-letra-portada.png"
const LEVEL_TWO_GAME_PATH := "res://assets/games/encuentra-la-letra-juego-del-abecedario.html"
const LEVEL_THREE_IMAGE_PATH := "res://assets/games/une-palabras-imagenes-portada.png"
const LEVEL_THREE_GAME_PATH := "res://assets/games/matching_game.html"
const LEVEL_FOUR_IMAGE_PATH := "res://assets/games/condor-guerrero-portada.jpg"
const LEVEL_FOUR_SCENE_PATH := "res://scenes/language/condor_zombie_game.tscn"
const SOURCE_SIZE := Vector2(1672.0, 941.0)

var background: TextureRect
var level_buttons: Array[Button] = []
var help_dialog: AcceptDialog
var level_dialog: AcceptDialog
var back_hotspot: Button
var help_hotspot: Button
var level_one_art: TextureRect
var level_two_art: TextureRect
var level_three_art: TextureRect
var level_four_art: TextureRect
var level_four_game: Node2D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_screen()
	_layout_controls()
	get_viewport().size_changed.connect(_layout_controls)

func _build_screen() -> void:
	background = TextureRect.new()
	background.texture = load(BACKGROUND_PATH)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	for index in range(6):
		var button := Button.new()
		button.text = "Nivel %d" % (index + 1)
		button.tooltip_text = "Seleccionar nivel %d" % (index + 1)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 30)
		button.add_theme_color_override("font_color", Color("#70400d"))
		button.add_theme_color_override("font_hover_color", Color("#4f2d09"))
		button.add_theme_color_override("font_pressed_color", Color("#4f2d09"))
		button.add_theme_color_override("font_focus_color", Color("#70400d"))
		button.add_theme_stylebox_override("normal", _empty_style())
		button.add_theme_stylebox_override("hover", _card_style(Color(1.0, 0.79, 0.23, 0.25), Color("#ffb522"), 4))
		button.add_theme_stylebox_override("pressed", _card_style(Color(1.0, 0.67, 0.12, 0.34), Color("#ef8a11"), 5))
		button.add_theme_stylebox_override("focus", _card_style(Color(1.0, 0.88, 0.37, 0.15), Color("#ffcb31"), 5))
		button.pressed.connect(_on_level_pressed.bind(index + 1))
		if index == 0:
			button.text = ""
			button.tooltip_text = "Cóndor volador recolector: pulsa para jugar"
			level_one_art = TextureRect.new()
			level_one_art.texture = load(LEVEL_ONE_IMAGE_PATH)
			level_one_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			level_one_art.offset_left = 12.0
			level_one_art.offset_top = 12.0
			level_one_art.offset_right = -12.0
			level_one_art.offset_bottom = -12.0
			level_one_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			level_one_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			level_one_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(level_one_art)
		elif index == 1:
			button.text = ""
			button.tooltip_text = "Encuentra la letra: pulsa para jugar"
			level_two_art = TextureRect.new()
			level_two_art.texture = load(LEVEL_TWO_IMAGE_PATH)
			level_two_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			level_two_art.offset_left = 12.0
			level_two_art.offset_top = 12.0
			level_two_art.offset_right = -12.0
			level_two_art.offset_bottom = -12.0
			level_two_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			level_two_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			level_two_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(level_two_art)
		elif index == 2:
			button.text = ""
			button.tooltip_text = "Une las palabras con las imágenes: pulsa para jugar"
			level_three_art = TextureRect.new()
			level_three_art.texture = load(LEVEL_THREE_IMAGE_PATH)
			level_three_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			level_three_art.offset_left = 12.0
			level_three_art.offset_top = 12.0
			level_three_art.offset_right = -12.0
			level_three_art.offset_bottom = -12.0
			level_three_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			level_three_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			level_three_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(level_three_art)
		elif index == 3:
			button.text = ""
			button.tooltip_text = "Nivel 4: Cóndor Guerrero"
			level_four_art = TextureRect.new()
			level_four_art.texture = load(LEVEL_FOUR_IMAGE_PATH)
			level_four_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			level_four_art.offset_left = 12.0
			level_four_art.offset_top = 12.0
			level_four_art.offset_right = -12.0
			level_four_art.offset_bottom = -12.0
			level_four_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			level_four_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			level_four_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(level_four_art)
		level_buttons.append(button)
		add_child(button)

	# Zonas transparentes alineadas con los botones dibujados en la imagen.
	back_hotspot = Button.new()
	back_hotspot.text = ""
	back_hotspot.tooltip_text = "Volver a Lenguaje"
	back_hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_hotspot.add_theme_stylebox_override("normal", _empty_style())
	back_hotspot.add_theme_stylebox_override("hover", _card_style(Color(1.0, 1.0, 1.0, 0.13), Color(1.0, 0.87, 0.45, 0.9), 4))
	back_hotspot.pressed.connect(func() -> void: close_requested.emit())
	add_child(back_hotspot)

	help_hotspot = Button.new()
	help_hotspot.text = ""
	help_hotspot.tooltip_text = "Ayuda"
	help_hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	help_hotspot.add_theme_stylebox_override("normal", _empty_style())
	help_hotspot.add_theme_stylebox_override("hover", _card_style(Color(1.0, 1.0, 1.0, 0.13), Color("#76dcff"), 4))
	help_hotspot.pressed.connect(_show_help)
	add_child(help_hotspot)

	help_dialog = AcceptDialog.new()
	help_dialog.title = "Ayuda"
	help_dialog.dialog_text = "Elige uno de los seis espacios para entrar a un nivel. Pulsa «Volver a Lenguaje» para regresar."
	help_dialog.ok_button_text = "¡Entendido!"
	add_child(help_dialog)

	level_dialog = AcceptDialog.new()
	level_dialog.title = "Juegos por niveles"
	level_dialog.dialog_text = ""
	level_dialog.ok_button_text = "Continuar"
	add_child(level_dialog)

func _layout_controls() -> void:
	if background == null:
		return
	var viewport_size := get_viewport_rect().size
	# Mapea los controles a la misma escala y recorte que KEEP_ASPECT_COVERED.
	var image_scale := maxf(viewport_size.x / SOURCE_SIZE.x, viewport_size.y / SOURCE_SIZE.y)
	var image_offset := (viewport_size - SOURCE_SIZE * image_scale) * 0.5
	var cards := [
		Rect2(307, 245, 337, 233), Rect2(669, 245, 337, 233), Rect2(1029, 245, 337, 233),
		Rect2(307, 499, 337, 232), Rect2(669, 499, 337, 232), Rect2(1029, 499, 337, 232)
	]
	for index in range(level_buttons.size()):
		var source_card: Rect2 = cards[index]
		var card_position := image_offset + source_card.position * image_scale
		level_buttons[index].position = card_position
		level_buttons[index].size = source_card.size * image_scale
	# Los dos botones inferiores se ubican sobre los rótulos del arte de fondo.
	var back_source_rect := Rect2(60, 773, 500, 150)
	var help_source_rect := Rect2(1280, 766, 350, 160)
	back_hotspot.position = image_offset + back_source_rect.position * image_scale
	back_hotspot.size = back_source_rect.size * image_scale
	help_hotspot.position = image_offset + help_source_rect.position * image_scale
	help_hotspot.size = help_source_rect.size * image_scale

func _on_level_pressed(level: int) -> void:
	if level == 1:
		_open_html_game(LEVEL_ONE_GAME_PATH, "Cóndor volador recolector")
		return
	if level == 2:
		_open_html_game(LEVEL_TWO_GAME_PATH, "Encuentra la letra")
		return
	if level == 3:
		_open_html_game(LEVEL_THREE_GAME_PATH, "Une las palabras con las imágenes")
		return
	if level == 4:
		_open_level_four_game()
		return
	level_dialog.dialog_text = "Seleccionaste el nivel %d. Aquí aparecerán sus juegos." % level
	level_dialog.popup_centered()

func _open_level_four_game() -> void:
	if is_instance_valid(level_four_game):
		return
	var packed_scene := load(LEVEL_FOUR_SCENE_PATH) as PackedScene
	if packed_scene == null:
		level_dialog.dialog_text = "No se pudo cargar el juego del Cóndor Guerrero."
		level_dialog.popup_centered()
		return
	level_four_game = packed_scene.instantiate() as Node2D
	if level_four_game == null:
		level_dialog.dialog_text = "La escena del Nivel 4 no tiene un nodo de juego válido."
		level_dialog.popup_centered()
		return
	level_four_game.close_requested.connect(_close_level_four_game)
	add_child(level_four_game)

func _close_level_four_game() -> void:
	if is_instance_valid(level_four_game):
		level_four_game.queue_free()
	level_four_game = null

func _open_html_game(game_resource_path: String, game_title: String) -> void:
	if not FileAccess.file_exists(game_resource_path):
		level_dialog.dialog_text = "No se encontró el juego «%s» dentro de assets/games." % game_title
		level_dialog.popup_centered()
		return
	var game_path := ProjectSettings.globalize_path(game_resource_path)
	var game_uri := "file:///" + game_path.replace("\\", "/").replace(" ", "%20")
	var error := OS.shell_open(game_uri)
	if error != OK:
		level_dialog.dialog_text = "No se pudo abrir «%s». Revisa que tengas un navegador configurado." % game_title
		level_dialog.popup_centered()

func _show_help() -> void:
	help_dialog.popup_centered()

func _empty_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	style.set_border_width_all(0)
	style.set_corner_radius_all(20)
	return style

func _card_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.28, 0.16, 0.02, 0.2)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style
