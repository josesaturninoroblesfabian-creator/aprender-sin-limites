extends Control

signal back_requested
signal navigate_requested(module: String)

const REFERENCE_BACKGROUND := "res://assets/ui/dictionary/dictionary-menu.jpg"
const ART_SIZE := Vector2(1536, 1024)
const SHORTCUTS := ["Inicio", "Vocales", "Abecedario", "Números", "Matemática", "Geometría", "Diccionario", "Cuentos"]
const EXAMPLES := [
	["Sol", preload("res://assets/audio/guides/sol.wav")],
	["Árbol", preload("res://assets/audio/guides/arbol.wav")],
	["Casa", preload("res://assets/audio/guides/casa.wav")],
]
const Alphabet = preload("res://scripts/language/alphabet.gd")
const IllustratedWords = preload("res://scripts/language/illustrated_words.gd")
const LearningGuide = preload("res://scripts/ui/learning_guide.gd")
const INVALID_QUERY_MESSAGE := "Escribe bien la palabra para entenderte"

var search_field: LineEdit
var message_panel: PanelContainer
var message_label: Label
var result_card: PanelContainer
var result_term: Label
var result_category: Label
var result_definition: RichTextLabel
var result_illustration: Label
var result_scroll: ScrollContainer
var suggestions: HFlowContainer
var entries_by_term: Dictionary = {}
var entries_without_accents: Dictionary = {}
var illustrations: Dictionary = {}
var message_time_left := 0.0
var guide: LearningGuide
var design: Control
var example_buttons: Array[Button] = []

func _ready() -> void:
	_load_dictionary()
	_build_screen()
	guide.play_intro()

func _process(delta: float) -> void:
	if message_time_left > 0.0:
		message_time_left -= delta
		if message_time_left <= 0.0 and is_instance_valid(message_panel):
			message_panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_navigate("Inicio")
		get_viewport().set_input_as_handled()

func _load_dictionary() -> void:
	for words in IllustratedWords.WORDS_BY_LETTER.values():
		for pair: String in words:
			var parts := pair.split("|", false, 1)
			illustrations[_normalize(parts[0], false)] = parts[1]
	for letter: String in Alphabet.LETTERS:
		var dictionary_path := "res://data/dictionary/dictionary_%s.json" % letter.to_lower()
		if not FileAccess.file_exists(dictionary_path):
			push_error("No se encontró el diccionario: " + dictionary_path)
			continue
		var file := FileAccess.open(dictionary_path, FileAccess.READ)
		if file == null:
			push_error("No se pudo leer el diccionario: " + dictionary_path)
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if not parsed is Array:
			push_error("El diccionario debe contener una lista JSON de entradas: " + dictionary_path)
			continue
		for value in parsed:
			if not value is Dictionary:
				continue
			var entry: Dictionary = value
			var term := String(entry.get("palabra", "")).strip_edges()
			if term.is_empty():
				continue
			var exact := _normalize(term, false)
			var folded := _normalize(term)
			if entries_by_term.has(exact):
				continue
			entries_by_term[exact] = entry
			# An unaccented query must not guess between different spellings.
			entries_without_accents[folded] = {} if entries_without_accents.has(folded) else entry

func _build_screen() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backing := ColorRect.new()
	backing.color = Color("#152e51")
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backing)
	design = Control.new()
	design.size = ART_SIZE
	add_child(design)
	var background := TextureRect.new()
	background.texture = preload(REFERENCE_BACKGROUND)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.size = ART_SIZE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design.add_child(background)

	search_field = LineEdit.new()
	search_field.name = "SearchWord"
	search_field.position = Vector2(766, 302)
	search_field.size = Vector2(500, 62)
	search_field.placeholder_text = "Escribe una palabra..."
	search_field.clear_button_enabled = true
	search_field.add_theme_font_size_override("font_size", 29)
	search_field.add_theme_color_override("font_color", Color("#172b48"))
	search_field.add_theme_color_override("font_placeholder_color", Color("#66758c"))
	for state in ["normal", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#fafbfd")
		style.content_margin_left = 12
		if state == "focus":
			style.border_color = Color("#3a92de")
			style.set_border_width_all(2)
			style.set_corner_radius_all(8)
		search_field.add_theme_stylebox_override(state, style)
	design.add_child(search_field)
	search_field.text_submitted.connect(_on_search_pressed)
	search_field.text_changed.connect(func(value: String):
		if value.is_empty():
			_reset_results()
	)
	_add_hotspot("Buscar palabra", Rect2(1271, 299, 183, 74), func(): _on_search_pressed(search_field.text))

	for i in SHORTCUTS.size():
		var module: String = SHORTCUTS[i]
		var destination := "Lenguaje" if module in ["Vocales", "Abecedario"] else module
		_add_hotspot(module, Rect2(8, 15 + 123 * i, 140, 109), _navigate.bind(destination))
	_add_hotspot("Volver al inicio", Rect2(1428, 9, 100, 97), _navigate.bind("Inicio"))
	_add_hotspot("Escuchar al guía del Diccionario", Rect2(245, 222, 331, 318), func(): guide.play_intro())

	for i in EXAMPLES.size():
		var example: Array = EXAMPLES[i]
		example_buttons.append(_add_hotspot(example[0], Rect2(749, 434 + i * 155, 615, 140), _search_example.bind(example[0])))
		example_buttons.append(_add_hotspot("Escuchar " + example[0], Rect2(1376, 463 + i * 155, 81, 85), _play_example.bind(example[1])))

	_build_result_card()
	guide.animate_art(background, Vector2(473, 447), Vector2(404, 411), Vector2(526, 373))
	_build_status()
	_reset_results()
	resized.connect(_fit_design)
	_fit_design()

func _fit_design() -> void:
	var factor := minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	design.scale = Vector2.ONE * factor
	design.position = (size - ART_SIZE * factor) * 0.5

func _navigate(module: String) -> void:
	guide.stop()
	if module == "Inicio":
		back_requested.emit()
	elif module != "Diccionario":
		navigate_requested.emit(module)

func _search_example(word: String) -> void:
	search_field.text = word
	_on_search_pressed(word)

func _play_example(stream: AudioStream) -> void:
	guide.play_clip(stream)

func _build_result_card() -> void:
	result_card = PanelContainer.new()
	result_card.name = "DictionaryResult"
	result_card.position = Vector2(721, 414)
	result_card.size = Vector2(768, 485)
	result_card.add_theme_stylebox_override("panel", _result_style())
	result_card.mouse_filter = Control.MOUSE_FILTER_STOP
	design.add_child(result_card)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	result_card.add_child(content)
	result_term = Label.new()
	result_term.add_theme_font_size_override("font_size", 42)
	result_term.add_theme_color_override("font_color", Color("#82451e"))
	result_term.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(result_term)
	result_category = Label.new()
	result_category.add_theme_font_size_override("font_size", 23)
	result_category.add_theme_color_override("font_color", Color("#28749a"))
	content.add_child(result_category)
	var divider := HSeparator.new()
	content.add_child(divider)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	content.add_child(body)
	result_illustration = Label.new()
	result_illustration.custom_minimum_size.x = 110
	result_illustration.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_illustration.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_illustration.add_theme_font_size_override("font_size", 72)
	body.add_child(result_illustration)
	result_scroll = ScrollContainer.new()
	result_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(result_scroll)
	result_definition = RichTextLabel.new()
	result_definition.bbcode_enabled = false
	result_definition.fit_content = true
	result_definition.scroll_active = false
	result_definition.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_definition.add_theme_font_size_override("normal_font_size", 26)
	result_definition.add_theme_color_override("default_color", Color("#3c3329"))
	result_definition.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_scroll.add_child(result_definition)
	guide = LearningGuide.new()
	guide.setup(false, preload("res://assets/audio/guides/dictionary-intro.wav"))
	design.add_child(guide)
	var actions := HBoxContainer.new()
	content.add_child(actions)
	guide.add_replay_to(actions)
	var clear := Button.new()
	clear.text = "Volver a los ejemplos"
	clear.add_theme_font_size_override("font_size", 22)
	clear.pressed.connect(_on_clear_pressed)
	actions.add_child(clear)
	suggestions = HFlowContainer.new()
	content.add_child(suggestions)

func _build_status() -> void:
	message_panel = PanelContainer.new()
	message_panel.name = "DictionaryStatus"
	message_panel.position = Vector2(750, 916)
	message_panel.size = Vector2(716, 65)
	message_panel.add_theme_stylebox_override("panel", _button_style(Color("#fff8e8")))
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_color_override("font_color", Color("#6e3f20"))
	message_panel.add_child(message_label)
	message_panel.hide()
	design.add_child(message_panel)

func _add_hotspot(label: String, area: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.name = label.replace(" ", "_")
	button.tooltip_text = label
	button.accessibility_name = label
	button.position = area.position
	button.size = area.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	for state in ["hover", "pressed", "focus"]:
		var highlight := StyleBoxFlat.new()
		highlight.bg_color = Color(1.0, 0.92, 0.68, 0.12)
		highlight.border_color = Color("#fff2a0")
		highlight.set_border_width_all(3)
		highlight.set_corner_radius_all(16)
		button.add_theme_stylebox_override(state, highlight)
	button.pressed.connect(callback)
	design.add_child(button)
	return button

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
	style.bg_color = Color("#fff8e8")
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
	_reset_results()
	search_field.grab_focus()

func _on_search_pressed(submitted_text: String = "") -> void:
	var query := submitted_text.strip_edges()
	if query.is_empty():
		query = search_field.text.strip_edges()
	if query.is_empty():
		_show_error(INVALID_QUERY_MESSAGE)
		search_field.grab_focus()
		return

	guide.stop()
	_show_search_result(query)

func _show_search_result(query: String) -> void:
	var parsed_query := _parse_query(query)
	var term := String(parsed_query.get("term", ""))
	if term.is_empty():
		_show_error(INVALID_QUERY_MESSAGE)
		return

	var entry := _find_entry(term)
	if entry.is_empty():
		var alternatives := _prefix_entries(term, 5)
		if not alternatives.is_empty():
			_show_entry_choices(alternatives)
			return
		var missing_message := "Lo lamento, no encuentro información de esa persona" if bool(parsed_query.get("person", false)) else "Lo lamento, no encuentro información de esa palabra"
		_show_error(missing_message)
		return

	_show_entry(entry)

func _parse_query(query: String) -> Dictionary:
	var spelling := _normalize(query, false)
	var normalized := _normalize(spelling)
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
			spelling = spelling.substr(prefix.length()).strip_edges()
			person_intent = bool(item["person"])
			break
	return {"term": spelling, "person": person_intent}

func _find_entry(normalized_term: String) -> Dictionary:
	if entries_by_term.has(normalized_term):
		return entries_by_term[normalized_term]
	var folded := _normalize(normalized_term)
	if entries_without_accents.has(folded):
		return entries_without_accents[folded]
	var matches := _prefix_entries(normalized_term, 2)
	return matches[0] if matches.size() == 1 else {}

func _prefix_entries(term: String, limit: int) -> Array[Dictionary]:
	var folded := _normalize(term)
	var matches: Array[Dictionary] = []
	for key: String in entries_by_term:
		if _normalize(key).begins_with(folded):
			matches.append(entries_by_term[key])
			if matches.size() == limit:
				break
	return matches

func _normalize(value: String, fold_accents := true) -> String:
	var normalized := value.to_lower().strip_edges()
	if fold_accents:
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
	_set_result_body(definition, illustrations.get(_normalize(term, false), ""))
	_set_suggestions([])
	_set_result_visible(true)
	message_panel.hide()
	guide.speak("%s. %s" % [term, definition], true)

func _reset_results() -> void:
	guide.stop()
	guide.reset_reading()
	_set_result_visible(false)
	message_panel.hide()

func _set_result_visible(visible_result: bool) -> void:
	result_card.visible = visible_result
	for button in example_buttons:
		button.visible = not visible_result

func _set_result_body(definition: String, illustration := "") -> void:
	result_definition.text = definition
	result_illustration.text = illustration
	result_illustration.visible = not illustration.is_empty()
	result_scroll.scroll_vertical = 0

func _show_entry_choices(entries: Array[Dictionary]) -> void:
	guide.reset_reading()
	var words: Array[String] = []
	for entry in entries:
		words.append(entry["palabra"])
	result_term.text = "¿Buscabas alguna de estas?"
	result_category.text = "Palabras que empiezan igual"
	_set_result_body("Toca una palabra para ver su significado.")
	_set_suggestions(words)
	_set_result_visible(true)
	message_panel.hide()

func _set_suggestions(words: Array) -> void:
	for child in suggestions.get_children():
		suggestions.remove_child(child)
		child.queue_free()
	suggestions.visible = not words.is_empty()
	for word: String in words:
		var button := Button.new()
		button.text = word
		button.custom_minimum_size.y = 36
		button.add_theme_stylebox_override("normal", _button_style(Color("#9b4e22")))
		button.add_theme_stylebox_override("hover", _button_style(Color("#b85f20")))
		button.pressed.connect(func():
			search_field.text = word
			_on_search_pressed(word)
		)
		suggestions.add_child(button)

func _show_error(message: String) -> void:
	_reset_results()
	_show_message(message)
	_speak(message)

func _show_message(message: String) -> void:
	message_label.text = message
	message_panel.show()
	message_time_left = 5.0

func _speak(message: String) -> void:
	guide.speak(message)
