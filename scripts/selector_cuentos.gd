extends Control

signal back_requested
signal story_selected(story: Dictionary)
signal mode_changed(mode: String)

const Repo = preload("res://scripts/stories/story_repository.gd")
const UI = preload("res://scripts/stories/story_ui.gd")
const Carmelo = preload("res://scripts/stories/carmelo_avatar.gd")

const CATALOG_PATH := "res://assets/data/cuentos.json"
const PROGRESS_PATH := "user://cuentos_ilustrados.cfg"
const INK := Color("#173b70")
const GOLD := Color("#ffd45b")
const WOOD := Color("#9b5429")
const CARD_COLORS: Array[Color] = [Color("#b83e32"), Color("#0874a8"), Color("#926007"), Color("#6943ad")]

var stories: Array[Dictionary] = []
var completed_stories: Dictionary = {}
var progress_label: Label
var progress_bar: ProgressBar
var story_grid: GridContainer
var library_panel: PanelContainer
var status_label: Label
var story_action_labels: Dictionary = {}
var activity_mode := "read"
var mode_title: Label
var hint_label: Label
var badges: Dictionary = {}

func _ready() -> void:
	_build_interface()
	_load_progress()
	_load_catalog()
	get_viewport().size_changed.connect(_update_grid_columns)
	_update_grid_columns()
	refresh_library()
	StoryAudio.guide(activity_mode, self)

func _build_interface() -> void:
	var background := TextureRect.new()
	background.name = "FondoBiblioteca"
	background.texture = load("res://assets/backgrounds/fondo-paisaje-andino.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.name = "VeloLectura"
	shade.color = Color(0.02, 0.14, 0.29, 0.28)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var safe_area := MarginContainer.new()
	safe_area.name = "MargenSeguro"
	safe_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area.add_theme_constant_override("margin_left", 30)
	safe_area.add_theme_constant_override("margin_top", 22)
	safe_area.add_theme_constant_override("margin_right", 30)
	safe_area.add_theme_constant_override("margin_bottom", 22)
	add_child(safe_area)

	var layout := VBoxContainer.new()
	layout.name = "LayoutBiblioteca"
	layout.add_theme_constant_override("separation", 15)
	safe_area.add_child(layout)

	_build_header(layout)
	_build_library(layout)

func _build_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.name = "EncabezadoBiblioteca"
	header.custom_minimum_size.y = 76
	header.add_theme_constant_override("separation", 18)
	parent.add_child(header)

	var back := _button("⌂  Menú", Color("#087fd0"), 21, Vector2(155, 64), 22)
	back.name = "VolverAlMenuCuentos"
	back.pressed.connect(_on_back_pressed)
	header.add_child(back)

	var sign := PanelContainer.new()
	sign.name = "LetreroEligeUnCuento"
	sign.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sign.add_theme_stylebox_override("panel", _style(WOOD, GOLD, 4, 24, 7))
	header.add_child(sign)

	var title := Label.new()
	mode_title = title
	title.text = "Elige un Cuento"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_shadow_color", Color("#623516"))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 2)
	_apply_font(title, 800)
	sign.add_child(title)

	var progress_panel := PanelContainer.new()
	progress_panel.name = "IndicadorProgresoLectura"
	progress_panel.custom_minimum_size = Vector2(220, 64)
	progress_panel.add_theme_stylebox_override("panel", _style(Color("#eaf6ff"), Color("#48a9dc"), 3, 20, 4))
	header.add_child(progress_panel)

	var progress_stack := VBoxContainer.new()
	progress_stack.add_theme_constant_override("separation", 2)
	progress_panel.add_child(progress_stack)
	progress_label = Label.new()
	progress_label.text = "Leídos 0 / 0"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", INK)
	_apply_font(progress_label, 700)
	progress_stack.add_child(progress_label)
	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size.y = 10
	progress_bar.add_theme_stylebox_override("background", _bar_style(Color("#caddec")))
	progress_bar.add_theme_stylebox_override("fill", _bar_style(Color("#32c65a")))
	progress_stack.add_child(progress_bar)
	var avatar := Carmelo.new()
	avatar.custom_minimum_size = Vector2(80, 70)
	header.add_child(avatar)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	parent.add_child(mode_row)
	for mode in Repo.MODES:
		var mode_button := UI.button(Repo.MODE_TITLES[mode], Repo.MODE_COLORS[mode], 18)
		mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mode_button.pressed.connect(_change_mode.bind(mode))
		mode_row.add_child(mode_button)

func _build_library(parent: VBoxContainer) -> void:
	library_panel = PanelContainer.new()
	library_panel.name = "EstanteriaPergamino"
	library_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	library_panel.add_theme_stylebox_override("panel", _style(Color("#f3d9a1"), Color("#713e22"), 7, 32, 12))
	parent.add_child(library_panel)

	var inner_margin := MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", 23)
	inner_margin.add_theme_constant_override("margin_top", 15)
	inner_margin.add_theme_constant_override("margin_right", 23)
	inner_margin.add_theme_constant_override("margin_bottom", 16)
	library_panel.add_child(inner_margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	inner_margin.add_child(content)

	var hint := Label.new()
	hint_label = hint
	hint.name = "InstruccionBiblioteca"
	hint.text = "Escoge una portada y comienza a leer"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color("#70411f"))
	_apply_font(hint, 700)
	content.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.name = "DesplazamientoCuentos"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)

	story_grid = GridContainer.new()
	story_grid.name = "CuadriculaCuentos"
	story_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_grid.add_theme_constant_override("h_separation", 18)
	story_grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(story_grid)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", INK)
	_apply_font(status_label, 700)
	status_label.visible = false
	content.add_child(status_label)

func _load_catalog() -> void:
	if not FileAccess.file_exists(CATALOG_PATH):
		_show_error("No se encontró el catálogo de cuentos.")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not parsed is Dictionary:
		_show_error("El catálogo de cuentos no tiene un formato válido.")
		return
	var raw_stories: Variant = parsed.get("stories", [])
	if not raw_stories is Array:
		_show_error("No se pudo leer la lista de cuentos.")
		return

	for raw_story in raw_stories:
		if raw_story is Dictionary and not String(raw_story.get("id", "")).is_empty() and not String(raw_story.get("title", "")).is_empty():
			var pages: Variant = raw_story.get("pages", [])
			if pages is Array and not pages.is_empty():
				stories.append(raw_story.duplicate(true))

	if stories.is_empty():
		_show_error("Pronto habrá nuevos cuentos en esta estantería.")
		return
	status_label.visible = false
	progress_bar.max_value = stories.size()
	_refresh_progress()
	for index in range(stories.size()):
		story_grid.add_child(_build_story_card(stories[index], index))

func _build_story_card(story: Dictionary, index: int) -> Button:
	var accent: Color = CARD_COLORS[index % CARD_COLORS.size()]
	var card := Button.new()
	card.name = "Tarjeta_%s" % String(story.id)
	card.custom_minimum_size = Vector2(280, 370)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_ALL
	card.clip_contents = true
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_theme_stylebox_override("normal", _style(Color("#fffaf0"), accent, 4, 24, 6))
	card.add_theme_stylebox_override("hover", _style(Color("#fffdf6"), GOLD, 5, 24, 9))
	card.add_theme_stylebox_override("pressed", _style(Color("#f3eddf"), accent.darkened(0.12), 4, 24, 2))
	card.pressed.connect(_on_story_selected.bind(story))

	var margins := MarginContainer.new()
	margins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 13)
	margins.add_theme_constant_override("margin_top", 13)
	margins.add_theme_constant_override("margin_right", 13)
	margins.add_theme_constant_override("margin_bottom", 13)
	card.add_child(margins)

	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 8)
	margins.add_child(stack)

	var cover_frame := PanelContainer.new()
	cover_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover_frame.custom_minimum_size = Vector2(0, 174)
	cover_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cover_frame.add_theme_stylebox_override("panel", _style(accent.lightened(0.48), accent.darkened(0.12), 3, 17, 2))
	stack.add_child(cover_frame)
	var cover_path := String(story.get("cover", ""))
	if not cover_path.is_empty():
		var cover := TextureRect.new()
		cover.name = "Portada"
		cover.texture = Repo.cover_texture(story)
		cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cover.offset_left = 5
		cover.offset_top = 5
		cover.offset_right = -5
		cover.offset_bottom = -5
		cover_frame.add_child(cover)
	else:
		var cover_missing := _label("Ilustración del cuento", 20, INK, true)
		cover_missing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cover_missing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cover_frame.add_child(cover_missing)

	var title := _label(String(story.title), 24, INK, true)
	title.name = "Titulo"
	title.custom_minimum_size.y = 32
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(title, 800)
	stack.add_child(title)
	var summary := UI.label(story.get("summary", ""), 17)
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(summary)
	var badge := UI.label("", 15, Color("#277248"))
	stack.add_child(badge)
	badges[story.id] = badge

	var action_panel := PanelContainer.new()
	action_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_panel.add_theme_stylebox_override("panel", _style(accent, Color.WHITE, 3, 18, 3))
	stack.add_child(action_panel)
	var action := _label("▣  Leer cuento", 20, Color.WHITE, true)
	if completed_stories.has(String(story.get("id", ""))):
		action.text = "✓  Leer de nuevo"
	action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font(action, 800)
	action_panel.add_child(action)
	story_action_labels[String(story.get("id", ""))] = action
	margins.minimum_size_changed.connect(_fit_story_card.bind(card, margins))
	_fit_story_card.call_deferred(card, margins)
	return card

func _fit_story_card(card: Button, margins: MarginContainer) -> void:
	# Button does not inherit the minimum height of its container children.
	card.custom_minimum_size.y = maxf(370, margins.get_combined_minimum_size().y)

func _on_story_selected(story: Dictionary) -> void:
	StoryAudio.stop(self)
	story_selected.emit(story.duplicate(true))

func _on_back_pressed() -> void:
	StoryAudio.stop(self)
	back_requested.emit()

func mark_story_completed(story_id: String) -> void:
	# Completion has already been validated and saved by the activity screen.
	if not story_id.is_empty():
		refresh_library()

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(PROGRESS_PATH) != OK:
		return
	var saved: Variant = config.get_value("progreso", "cuentos", {})
	if saved is Dictionary:
		completed_stories = saved.duplicate()

func _refresh_progress() -> void:
	var completed := 0
	for story in stories:
		if Repo.is_complete(String(story.id), activity_mode):
			completed += 1
	progress_label.text = "%d / %d completados" % [completed, stories.size()]
	progress_bar.value = completed

func refresh_library() -> void:
	mode_title.text = Repo.MODE_TITLES.get(activity_mode, "Elige un cuento")
	hint_label.text = "Los mismos 16 cuentos, cuatro maneras de descubrirlos. Elige una portada."
	_refresh_progress()
	for story in stories:
		if story_action_labels.has(story.id):
			story_action_labels[story.id].text = ("✓ Repetir · " if Repo.is_complete(story.id, activity_mode) else "Empezar · ") + Repo.MODE_TITLES[activity_mode]
		if badges.has(story.id):
			var parts: Array[String] = []
			for mode in Repo.MODES:
				parts.append(("✓ " if Repo.is_complete(story.id, mode) else "○ ") + {"read": "Leer", "listen": "Oír", "order": "Ordenar", "quiz": "Retos"}[mode])
			badges[story.id].text = " · ".join(parts)

func _change_mode(mode: String) -> void:
	activity_mode = mode
	mode_changed.emit(mode)
	refresh_library()
	StoryAudio.guide(mode, self)

func _exit_tree() -> void:
	StoryAudio.stop(self)

func _update_grid_columns() -> void:
	if story_grid == null:
		return
	var width := get_viewport_rect().size.x
	story_grid.columns = 1 if width < 700.0 else (2 if width < 990.0 else 3)

func _show_error(message: String) -> void:
	status_label.text = message
	status_label.visible = true
	progress_label.text = "Biblioteca"
	progress_bar.max_value = 1
	progress_bar.value = 0

func _button(text: String, fill: Color, font_size: int, minimum_size: Vector2, radius: int) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = minimum_size
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color.WHITE)
	result.add_theme_color_override("font_hover_color", Color.WHITE)
	result.add_theme_color_override("font_pressed_color", Color.WHITE)
	_apply_font(result, 700)
	result.add_theme_stylebox_override("normal", _style(fill, Color("#fff0b4"), 3, radius, 5))
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
	result.set_content_margin_all(9)
	if shadow_size > 0:
		result.shadow_color = Color(0.05, 0.16, 0.24, 0.32)
		result.shadow_size = shadow_size
		result.shadow_offset = Vector2(0, 3)
	return result

func _bar_style(fill: Color) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.set_corner_radius_all(10)
	return result

func _apply_font(control: Control, weight: int) -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Baloo 2", "Trebuchet MS", "Arial"])
	font.font_weight = weight
	font.fallbacks = [ThemeDB.fallback_font]
	control.add_theme_font_override("font", font)
