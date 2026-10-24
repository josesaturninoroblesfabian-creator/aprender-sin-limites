extends Control

signal back_requested
signal story_completed(story_id: String)

const CATALOG_PATH := "res://assets/data/cuentos.json"

var initial_story: Dictionary = {}

const INK := Color("#173b70")
const BLUE := Color("#087fd0")
const PAPER := Color("#fff9e9")
const GOLD := Color("#ffc928")
const GREEN := Color("#2ebd50")

var story_pages: Array[Dictionary] = []
var current_page_index := 0
var story_title_label: Label
var page_counter_label: Label
var page_heading_label: Label
var paragraph_label: Label
var illustration: TextureRect
var illustration_placeholder: Label
var previous_button: Button
var next_button: Button
var story_id := ""
var completion_emitted := false
var page_transition: Tween

func _ready() -> void:
	_build_interface()
	if initial_story.is_empty():
		_load_first_catalog_story()
	else:
		load_story_data(initial_story)

func _build_interface() -> void:
	var background := TextureRect.new()
	background.name = "FondoAndino"
	background.texture = load("res://assets/backgrounds/fondo-traza.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var tint := ColorRect.new()
	tint.name = "VeloLectura"
	tint.color = Color(0.04, 0.24, 0.42, 0.30)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)

	var safe_area := MarginContainer.new()
	safe_area.name = "MargenPantalla"
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area.add_theme_constant_override("margin_left", 30)
	safe_area.add_theme_constant_override("margin_top", 20)
	safe_area.add_theme_constant_override("margin_right", 30)
	safe_area.add_theme_constant_override("margin_bottom", 20)
	add_child(safe_area)

	var layout := VBoxContainer.new()
	layout.name = "LayoutLectura"
	layout.add_theme_constant_override("separation", 14)
	safe_area.add_child(layout)

	_build_header(layout)
	_build_open_book(layout)
	_build_navigation(layout)

func _build_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.name = "Encabezado"
	header.custom_minimum_size.y = 78
	header.add_theme_constant_override("separation", 18)
	parent.add_child(header)

	var back := _button("‹  Biblioteca", BLUE, 21, Vector2(190, 64), 24)
	back.name = "VolverACuentos"
	back.pressed.connect(_on_back_pressed)
	header.add_child(back)

	var title_panel := PanelContainer.new()
	title_panel.name = "LetreroTituloCuento"
	title_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_panel.add_theme_stylebox_override("panel", _style(Color("#a85421"), GOLD, 4, 25, 7))
	header.add_child(title_panel)

	story_title_label = Label.new()
	story_title_label.name = "TituloCuento"
	story_title_label.text = "Cuentos Ilustrados"
	story_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	story_title_label.add_theme_font_size_override("font_size", 30)
	story_title_label.add_theme_color_override("font_color", Color.WHITE)
	story_title_label.add_theme_color_override("font_shadow_color", Color("#67320f"))
	story_title_label.add_theme_constant_override("shadow_offset_x", 1)
	story_title_label.add_theme_constant_override("shadow_offset_y", 2)
	_apply_font(story_title_label, "Baloo 2", "ExtraBold")
	title_panel.add_child(story_title_label)

	var page_panel := PanelContainer.new()
	page_panel.name = "IndicadorPagina"
	page_panel.custom_minimum_size = Vector2(190, 60)
	page_panel.add_theme_stylebox_override("panel", _style(Color("#e9f7ff"), BLUE, 3, 22, 4))
	header.add_child(page_panel)

	page_counter_label = Label.new()
	page_counter_label.name = "NumeroPagina"
	page_counter_label.text = "Página 1 de 4"
	page_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_counter_label.add_theme_font_size_override("font_size", 19)
	page_counter_label.add_theme_color_override("font_color", INK)
	_apply_font(page_counter_label, "Baloo 2", "Bold")
	page_panel.add_child(page_counter_label)

func _build_open_book(parent: VBoxContainer) -> void:
	var book := PanelContainer.new()
	book.name = "LibroAbierto"
	book.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book.add_theme_stylebox_override("panel", _style(Color("#b66b31"), Color("#ffe18b"), 4, 34, 10))
	parent.add_child(book)

	var pages_margin := MarginContainer.new()
	pages_margin.add_theme_constant_override("margin_left", 18)
	pages_margin.add_theme_constant_override("margin_top", 18)
	pages_margin.add_theme_constant_override("margin_right", 18)
	pages_margin.add_theme_constant_override("margin_bottom", 18)
	book.add_child(pages_margin)

	var spread := HBoxContainer.new()
	spread.name = "DoblePagina"
	spread.add_theme_constant_override("separation", 18)
	pages_margin.add_child(spread)

	var illustration_page := PanelContainer.new()
	illustration_page.name = "PaginaIlustracion"
	illustration_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	illustration_page.size_flags_stretch_ratio = 1.05
	illustration_page.add_theme_stylebox_override("panel", _style(Color("#d9f2ff"), Color("#5eb8e7"), 3, 24, 3))
	spread.add_child(illustration_page)

	illustration = TextureRect.new()
	illustration.name = "Ilustracion"
	illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	illustration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	illustration.offset_left = 8
	illustration.offset_top = 8
	illustration.offset_right = -8
	illustration.offset_bottom = -8
	illustration_page.add_child(illustration)

	illustration_placeholder = Label.new()
	illustration_placeholder.name = "AvisoSinIlustracion"
	illustration_placeholder.text = "Aquí aparecerá\nla ilustración del cuento"
	illustration_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	illustration_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	illustration_placeholder.add_theme_font_size_override("font_size", 24)
	illustration_placeholder.add_theme_color_override("font_color", INK)
	illustration_placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	illustration_placeholder.visible = false
	illustration_placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	illustration_page.add_child(illustration_placeholder)

	var text_page := PanelContainer.new()
	text_page.name = "PaginaTexto"
	text_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_page.size_flags_stretch_ratio = 0.95
	text_page.add_theme_stylebox_override("panel", _style(PAPER, Color("#f5c448"), 3, 24, 3))
	spread.add_child(text_page)

	var text_margin := MarginContainer.new()
	text_margin.add_theme_constant_override("margin_left", 38)
	text_margin.add_theme_constant_override("margin_top", 28)
	text_margin.add_theme_constant_override("margin_right", 38)
	text_margin.add_theme_constant_override("margin_bottom", 24)
	text_page.add_child(text_margin)

	var text_stack := VBoxContainer.new()
	text_stack.name = "ContenidoLectura"
	text_stack.add_theme_constant_override("separation", 14)
	text_margin.add_child(text_stack)

	var section_label := Label.new()
	section_label.text = "LEE Y DESCUBRE"
	section_label.add_theme_font_size_override("font_size", 15)
	section_label.add_theme_color_override("font_color", Color("#278448"))
	_apply_font(section_label, "Baloo 2", "Bold")
	text_stack.add_child(section_label)

	page_heading_label = Label.new()
	page_heading_label.name = "TituloPagina"
	page_heading_label.text = "Una aventura comienza"
	page_heading_label.add_theme_font_size_override("font_size", 27)
	page_heading_label.add_theme_color_override("font_color", Color("#be4e21"))
	page_heading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(page_heading_label, "Baloo 2", "Bold")
	text_stack.add_child(page_heading_label)

	paragraph_label = Label.new()
	paragraph_label.name = "ParrafoCuento"
	paragraph_label.text = "El texto de la historia aparecerá aquí."
	paragraph_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	paragraph_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	paragraph_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paragraph_label.add_theme_font_size_override("font_size", 29)
	paragraph_label.add_theme_color_override("font_color", INK)
	paragraph_label.add_theme_constant_override("line_spacing", 8)
	_apply_font(paragraph_label, "Baloo 2", "Medium")
	text_stack.add_child(paragraph_label)

	var reader_tip := Label.new()
	reader_tip.text = "Tómate tu tiempo para leer ✨"
	reader_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reader_tip.add_theme_font_size_override("font_size", 16)
	reader_tip.add_theme_color_override("font_color", Color("#39744d"))
	_apply_font(reader_tip, "Baloo 2", "Regular")
	text_stack.add_child(reader_tip)

func _build_navigation(parent: VBoxContainer) -> void:
	var navigation := HBoxContainer.new()
	navigation.name = "ControlesLectura"
	navigation.alignment = BoxContainer.ALIGNMENT_CENTER
	navigation.add_theme_constant_override("separation", 36)
	navigation.custom_minimum_size.y = 82
	parent.add_child(navigation)

	previous_button = _button("‹", Color("#8054d6"), 42, Vector2(78, 72), 36)
	previous_button.name = "PaginaAnterior"
	previous_button.tooltip_text = "Página anterior"
	previous_button.pressed.connect(_change_page.bind(-1))
	navigation.add_child(previous_button)

	next_button = _button("›", GREEN, 42, Vector2(78, 72), 36)
	next_button.name = "PaginaSiguiente"
	next_button.tooltip_text = "Página siguiente"
	next_button.pressed.connect(_change_page.bind(1))
	navigation.add_child(next_button)

func _load_first_catalog_story() -> void:
	if not FileAccess.file_exists(CATALOG_PATH):
		_show_story_error("No se encontró el catálogo de cuentos.")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not parsed is Dictionary:
		_show_story_error("El catálogo de cuentos no tiene un formato válido.")
		return
	var catalog_stories: Variant = parsed.get("stories", [])
	if not catalog_stories is Array or catalog_stories.is_empty() or not catalog_stories[0] is Dictionary:
		_show_story_error("Todavía no hay cuentos para leer.")
		return
	load_story_data(catalog_stories[0])

func load_story_data(story_data: Dictionary) -> bool:
	var raw_pages: Variant = story_data.get("pages", [])
	if not raw_pages is Array or raw_pages.is_empty():
		_show_story_error("Este cuento todavía no tiene páginas.")
		return false
	var pages_array: Array = raw_pages
	story_pages.clear()
	for page_data in pages_array:
		if page_data is Dictionary:
			story_pages.append(page_data.duplicate(true))
	if story_pages.is_empty():
		_show_story_error("Este cuento todavía no tiene páginas.")
		return false
	story_title_label.text = String(story_data.get("title", "Cuentos Ilustrados"))
	story_id = String(story_data.get("id", ""))
	current_page_index = 0
	completion_emitted = false
	_render_current_page()
	return true

func _render_current_page() -> void:
	if story_pages.is_empty():
		return
	var page: Dictionary = story_pages[current_page_index]
	page_heading_label.text = String(page.get("heading", "Lee y descubre"))
	paragraph_label.text = String(page.get("text", ""))
	page_counter_label.text = "Página %d de %d" % [current_page_index + 1, story_pages.size()]
	_load_page_illustration(String(page.get("image", "")))
	previous_button.disabled = current_page_index == 0
	next_button.disabled = current_page_index >= story_pages.size() - 1
	if current_page_index == story_pages.size() - 1 and not completion_emitted and not story_id.is_empty():
		completion_emitted = true
		story_completed.emit(story_id)
	illustration.modulate.a = 0.0
	paragraph_label.modulate.a = 0.0
	if page_transition != null and page_transition.is_running():
		page_transition.kill()
	page_transition = create_tween().set_parallel(true)
	page_transition.tween_property(illustration, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
	page_transition.tween_property(paragraph_label, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)

func _load_page_illustration(path: String) -> void:
	if not path.is_empty() and ResourceLoader.exists(path):
		var texture := load(path) as Texture2D
		if texture != null:
			illustration.texture = texture
			illustration.visible = true
			illustration_placeholder.visible = false
			return
	illustration.texture = null
	illustration.visible = false
	illustration_placeholder.visible = true

func _change_page(direction: int) -> void:
	var next_index := current_page_index + direction
	if next_index < 0 or next_index >= story_pages.size():
		return
	current_page_index = next_index
	_render_current_page()

func _on_back_pressed() -> void:
	back_requested.emit()

func _show_story_error(message: String) -> void:
	story_title_label.text = "Cuentos Ilustrados"
	page_heading_label.text = "Aún no está listo"
	paragraph_label.text = message
	page_counter_label.text = "Sin páginas"
	illustration.texture = null
	illustration.visible = false
	illustration_placeholder.visible = true
	previous_button.disabled = true
	next_button.disabled = true

func _button(text: String, fill: Color, font_size: int, minimum_size: Vector2, radius: int) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = minimum_size
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color.WHITE)
	result.add_theme_color_override("font_hover_color", Color.WHITE)
	result.add_theme_color_override("font_pressed_color", Color.WHITE)
	_apply_font(result, "Baloo 2", "Bold")
	result.add_theme_stylebox_override("normal", _style(fill, Color("#fff3bf"), 3, radius, 5))
	result.add_theme_stylebox_override("hover", _style(fill.lightened(0.12), GOLD, 4, radius, 5))
	result.add_theme_stylebox_override("pressed", _style(fill.darkened(0.10), Color("#fff3bf"), 2, radius, 2))
	result.add_theme_stylebox_override("disabled", _style(Color("#9fb4ca"), Color("#dbe7f0"), 2, radius, 0))
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return result

func _style(fill: Color, border: Color, border_width: int, radius: int, shadow_size: int = 0) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(border_width)
	result.set_corner_radius_all(radius)
	result.set_content_margin_all(10)
	if shadow_size > 0:
		result.shadow_color = Color(0.04, 0.18, 0.32, 0.34)
		result.shadow_size = shadow_size
		result.shadow_offset = Vector2(0, 4)
	return result

func _apply_font(control: Control, family: String, fallback: String) -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray([family, "Trebuchet MS", "Arial"])
	match fallback:
		"ExtraBold":
			font.font_weight = 800
		"Bold":
			font.font_weight = 700
		"Medium":
			font.font_weight = 500
		_:
			font.font_weight = 400
	font.fallbacks = [ThemeDB.fallback_font]
	control.add_theme_font_override("font", font)
