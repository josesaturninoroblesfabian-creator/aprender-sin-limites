extends Control

signal back_requested

const REFERENCE_BACKGROUND := "res://assets/ui/dictionary/dictionary-reference.jpg"

var search_field: LineEdit
var message_panel: PanelContainer
var message_label: Label
var message_time_left := 0.0

func _ready() -> void:
	_build_screen()

func _process(delta: float) -> void:
	if message_time_left > 0.0:
		message_time_left -= delta
		if message_time_left <= 0.0 and is_instance_valid(message_panel):
			message_panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		back_requested.emit()
		get_viewport().set_input_as_handled()

func _build_screen() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var background := TextureRect.new()
	background.name = "DictionaryReferenceBackground"
	background.texture = load(REFERENCE_BACKGROUND)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# The supplied reference already contains the search bar artwork. These controls
	# sit over its input, magnifier, and trash can so they remain visually matched.
	search_field = LineEdit.new()
	search_field.name = "SearchWord"
	search_field.placeholder_text = "Escribe una palabra"
	search_field.clear_button_enabled = false
	search_field.add_theme_font_size_override("font_size", 18)
	search_field.add_theme_color_override("font_color", Color("#333333"))
	search_field.add_theme_color_override("font_placeholder_color", Color("#888888"))
	search_field.add_theme_stylebox_override("normal", _transparent_input_style())
	search_field.add_theme_stylebox_override("focus", _transparent_input_style())
	search_field.anchor_left = 0.444
	search_field.anchor_top = 0.071
	search_field.anchor_right = 0.666
	search_field.anchor_bottom = 0.135
	search_field.offset_left = 5
	search_field.offset_top = 1
	search_field.offset_right = -4
	search_field.offset_bottom = -1
	search_field.tooltip_text = "Escribe aquí la palabra que quieres buscar"
	add_child(search_field)
	search_field.text_submitted.connect(_on_search_pressed)

	var search_button := _make_hotspot("SearchButton", "Buscar palabra", 0.678, 0.069, 0.718, 0.145)
	search_button.pressed.connect(func(): _on_search_pressed(search_field.text))
	add_child(search_button)
	var clear_button := _make_hotspot("ClearButton", "Borrar palabra", 0.718, 0.069, 0.755, 0.145)
	clear_button.pressed.connect(_on_clear_pressed)
	add_child(clear_button)

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "← Menú"
	back_button.tooltip_text = "Volver al menú principal (Esc)"
	back_button.anchor_left = 0.015
	back_button.anchor_top = 0.91
	back_button.anchor_right = 0.13
	back_button.anchor_bottom = 0.98
	back_button.add_theme_font_size_override("font_size", 17)
	back_button.add_theme_color_override("font_color", Color.WHITE)
	back_button.add_theme_stylebox_override("normal", _button_style(Color("#b85f20")))
	back_button.add_theme_stylebox_override("hover", _button_style(Color("#d9792f")))
	back_button.add_theme_stylebox_override("pressed", _button_style(Color("#934717")))
	back_button.pressed.connect(func(): back_requested.emit())
	add_child(back_button)

	message_panel = PanelContainer.new()
	message_panel.name = "DictionaryStatus"
	message_panel.anchor_left = 0.30
	message_panel.anchor_top = 0.86
	message_panel.anchor_right = 0.73
	message_panel.anchor_bottom = 0.94
	message_panel.add_theme_stylebox_override("panel", _button_style(Color("#fff8e8")))
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color("#6e3f20"))
	message_panel.add_child(message_label)
	message_panel.hide()
	add_child(message_panel)

func _make_hotspot(node_name: String, tooltip: String, left: float, top: float, right: float, bottom: float) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = ""
	button.tooltip_text = tooltip
	button.anchor_left = left
	button.anchor_top = top
	button.anchor_right = right
	button.anchor_bottom = bottom
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var transparent := StyleBoxFlat.new()
		transparent.bg_color = Color(1, 1, 1, 0.01)
		transparent.set_border_width_all(0)
		button.add_theme_stylebox_override(state, transparent)
	return button

func _transparent_input_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.01)
	style.set_border_width_all(0)
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.set_border_width_all(2)
	style.border_color = Color("#fff4d8")
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _on_clear_pressed() -> void:
	search_field.clear()
	search_field.grab_focus()
	_show_message("Se borró el texto. Escribe otra palabra para buscar.")

func _on_search_pressed(submitted_text: String = "") -> void:
	var query := submitted_text.strip_edges()
	if query.is_empty():
		query = search_field.text.strip_edges()
	if query.is_empty():
		_show_message("Escribe una palabra en el campo de búsqueda.")
		search_field.grab_focus()
		return
	_show_message("Buscaremos «%s» cuando configuremos el diccionario." % query)

func _show_message(message: String) -> void:
	message_label.text = message
	message_panel.show()
	message_time_left = 3.0
