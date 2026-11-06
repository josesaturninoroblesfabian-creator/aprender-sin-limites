extends Control

signal back_requested

const REFERENCE_BACKGROUND := "res://assets/ui/dictionary/dictionary-reference.jpg"
const DICTIONARY_DATA_PATH := "res://data/dictionary/dictionary_a.json"
const INVALID_QUERY_MESSAGE := "Escribe bien la palabra para entenderte"

var search_field: LineEdit
var message_panel: PanelContainer
var message_label: Label
var result_card: PanelContainer
var result_term: Label
var result_category: Label
var result_definition: RichTextLabel
var entries_by_term: Dictionary = {}
var message_time_left := 0.0
var spanish_voice := ""

func _ready() -> void:
	_load_dictionary()
	_find_spanish_voice()
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

func _load_dictionary() -> void:
	if not FileAccess.file_exists(DICTIONARY_DATA_PATH):
		push_error("No se encontró el diccionario: " + DICTIONARY_DATA_PATH)
		return
	var file := FileAccess.open(DICTIONARY_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("No se pudo leer el archivo del diccionario.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_error("El diccionario debe contener una lista JSON de entradas.")
		return
	for value in parsed:
		if not value is Dictionary:
			continue
		var entry: Dictionary = value
		var term := String(entry.get("palabra", "")).strip_edges()
		if term.is_empty():
			continue
		entries_by_term[_normalize(term)] = entry

func _find_spanish_voice() -> void:
	for voice in DisplayServer.tts_get_voices():
		var language := String(voice.get("language", "")).to_lower()
		if language.begins_with("es"):
			spanish_voice = String(voice.get("id", ""))
			return

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

	# El arte ya incluye la barra de búsqueda; el campo y los botones coinciden con ella.
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

	_build_result_card()
	_build_status()

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
	_show_welcome()

func _build_result_card() -> void:
	result_card = PanelContainer.new()
	result_card.name = "DictionaryResult"
	result_card.anchor_left = 0.16
	result_card.anchor_top = 0.25
	result_card.anchor_right = 0.84
	result_card.anchor_bottom = 0.78
	result_card.add_theme_stylebox_override("panel", _result_style())
	result_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(result_card)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	result_card.add_child(content)
	result_term = Label.new()
	result_term.add_theme_font_size_override("font_size", 30)
	result_term.add_theme_color_override("font_color", Color("#82451e"))
	result_term.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(result_term)
	result_category = Label.new()
	result_category.add_theme_font_size_override("font_size", 18)
	result_category.add_theme_color_override("font_color", Color("#28749a"))
	content.add_child(result_category)
	var divider := HSeparator.new()
	content.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	result_definition = RichTextLabel.new()
	result_definition.bbcode_enabled = false
	result_definition.fit_content = true
	result_definition.scroll_active = false
	result_definition.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_definition.add_theme_font_size_override("normal_font_size", 19)
	result_definition.add_theme_color_override("default_color", Color("#3c3329"))
	result_definition.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(result_definition)

func _build_status() -> void:
	message_panel = PanelContainer.new()
	message_panel.name = "DictionaryStatus"
	message_panel.anchor_left = 0.30
	message_panel.anchor_top = 0.82
	message_panel.anchor_right = 0.73
	message_panel.anchor_bottom = 0.90
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

func _result_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.97, 0.88, 0.96)
	style.set_corner_radius_all(20)
	style.set_border_width_all(4)
	style.border_color = Color("#e8a728")
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 22
	style.content_margin_bottom = 20
	return style

func _on_clear_pressed() -> void:
	search_field.clear()
	_show_welcome()
	search_field.grab_focus()

func _on_search_pressed(submitted_text: String = "") -> void:
	var query := submitted_text.strip_edges()
	if query.is_empty():
		query = search_field.text.strip_edges()
	if query.is_empty():
		_show_error(INVALID_QUERY_MESSAGE)
		search_field.grab_focus()
		return

	var parsed_query := _parse_query(query)
	var term := String(parsed_query.get("term", ""))
	if term.is_empty():
		_show_error(INVALID_QUERY_MESSAGE)
		return

	var entry := _find_entry(term)
	if entry.is_empty():
		var missing_message := "Lo lamento, no encuentro información de esa persona" if bool(parsed_query.get("person", false)) else "Lo lamento, no encuentro información de esa palabra"
		_show_error(missing_message)
		return

	_show_entry(entry)

func _parse_query(query: String) -> Dictionary:
	var normalized := _normalize(query)
	var person_intent := false
	var prefixes := [
		{"text": "que significado tiene", "person": false},
		{"text": "que significa la palabra", "person": false},
		{"text": "que significa", "person": false},
		{"text": "significado de", "person": false},
		{"text": "quien fue", "person": true},
		{"text": "quien es", "person": true},
		{"text": "que es", "person": false}
	]
	for item in prefixes:
		var prefix: String = item["text"]
		if normalized == prefix or normalized.begins_with(prefix + " "):
			normalized = normalized.substr(prefix.length()).strip_edges()
			person_intent = bool(item["person"])
			break
	return {"term": normalized, "person": person_intent}

func _find_entry(normalized_term: String) -> Dictionary:
	if entries_by_term.has(normalized_term):
		return entries_by_term[normalized_term]
	# A partial prefix is useful for young learners, but only use it when unique.
	var match_entry: Dictionary = {}
	for key in entries_by_term:
		if String(key).begins_with(normalized_term):
			if not match_entry.is_empty():
				return {}
			match_entry = entries_by_term[key]
	return match_entry

func _normalize(value: String) -> String:
	var normalized := value.to_lower().strip_edges()
	for pair in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"]]:
		normalized = normalized.replace(pair[0], pair[1])
	# Conserva ñ para distinguirla de n; quita signos y puntuación comunes.
	for symbol in ["?", "¿", "!", "¡", ".", ",", ":", ";", "\"", "'", "“", "”"]:
		normalized = normalized.replace(symbol, "")
	return " ".join(normalized.split(" ", false))

func _show_entry(entry: Dictionary) -> void:
	var term := String(entry.get("palabra", "Palabra"))
	var category := String(entry.get("tipo", "Sin categoría"))
	var definition := String(entry.get("significado", "No hay una definición disponible."))
	result_term.text = term
	result_category.text = "Categoría: " + category
	result_definition.text = definition
	result_card.show()
	message_panel.hide()
	_speak("%s. Categoría: %s. %s" % [term, category, definition])

func _show_welcome() -> void:
	result_term.text = "Busca una palabra"
	result_category.text = "Diccionario de la letra A"
	result_definition.text = "Escribe una palabra o pregunta, por ejemplo: «¿Qué significa avión?» o «¿Quién fue Atahualpa?»"
	result_card.show()
	message_panel.hide()

func _show_error(message: String) -> void:
	_show_message(message)
	_speak(message)

func _show_message(message: String) -> void:
	message_label.text = message
	message_panel.show()
	message_time_left = 5.0

func _speak(message: String) -> void:
	if not spanish_voice.is_empty():
		DisplayServer.tts_stop()
		DisplayServer.tts_speak(message, spanish_voice, 100, 1.0, 1.0, Time.get_ticks_msec(), true)
