extends Control

signal closed
signal book_opened

const UI = preload("res://scripts/math/math_ui.gd")
const Backdrop = preload("res://scripts/ui/encyclopedia_backdrop.gd")
const LIBRARY := "user://anatomy"
var subject: String
var catalog: Array
var prompt: String
var repeat_prompt: Callable

var shelf: VBoxContainer
var shelf_status: Label
var reader: VBoxContainer
var title: Label
var status: Label
var page_input: LineEdit
var page_count: Label
var scroll: ScrollContainer
var picture: TextureRect
var previous: Button
var next: Button
var search: Button
var pack: ZIPReader
var total := 0
var current := 0
var zoom := 1.0
var transition: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Backdrop.new())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["top", "bottom", "left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var back := _button("← Volver", back_requested, header)
	title = UI.text(_shelf_title(), 30, Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_build_shelf(column)
	_build_reader(column)
	back.grab_focus()

func _build_shelf(parent: Control) -> void:
	shelf = VBoxContainer.new()
	shelf.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shelf.add_theme_constant_override("separation", 12)
	parent.add_child(shelf)
	var introduction := HBoxContainer.new()
	shelf.add_child(introduction)
	var prompt_label := UI.text(prompt, 20, Color.WHITE)
	prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	introduction.add_child(prompt_label)
	if repeat_prompt.is_valid():
		_button("Escuchar a la guía", repeat_prompt, introduction)
	shelf_status = UI.text("Elige un libro para empezar a leer.", 21, Color.WHITE)
	shelf.add_child(shelf_status)
	var books := HBoxContainer.new()
	books.size_flags_vertical = Control.SIZE_EXPAND_FILL
	books.add_theme_constant_override("separation", 16)
	shelf.add_child(books)
	for book in catalog:
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		books.add_child(card)
		var source := ZIPReader.new()
		var available := source.open(_pack_path(book[1])) == OK
		var cover := TextureRect.new()
		cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cover.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if available:
			cover.texture = _page_texture(source, 1)
			source.close()
		card.add_child(cover)
		var button := _button(book[0], _open_book.bind(book[0], book[1]), card)
		button.disabled = not available
		if not available:
			card.add_child(UI.text("Añade el paquete de este libro a la carpeta local.", 18, Color.WHITE))
	_button("Abrir carpeta de libros", _open_local_folder, shelf)

func _build_reader(parent: Control) -> void:
	reader = VBoxContainer.new()
	reader.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reader.add_theme_constant_override("separation", 7)
	parent.add_child(reader)
	var toolbar := HFlowContainer.new()
	toolbar.add_theme_constant_override("h_separation", 8)
	reader.add_child(toolbar)
	previous = _button("← Anterior", _step.bind(-1), toolbar)
	next = _button("Siguiente →", _step.bind(1), toolbar)
	page_count = UI.text("", 20, Color.WHITE)
	page_count.autowrap_mode = TextServer.AUTOWRAP_OFF
	page_count.custom_minimum_size.x = 110
	page_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toolbar.add_child(page_count)
	page_input = LineEdit.new()
	page_input.placeholder_text = "N.º"
	page_input.accessibility_name = "Número de página del visor"
	page_input.custom_minimum_size = Vector2(72, 42)
	page_input.max_length = 8
	page_input.add_theme_font_size_override("font_size", 22)
	page_input.text_submitted.connect(_jump)
	toolbar.add_child(page_input)
	search = _button("Buscar página", func(): _jump(page_input.text), toolbar)
	_button("−", _change_zoom.bind(-0.35), toolbar).tooltip_text = "Alejar página"
	_button("+", _change_zoom.bind(0.35), toolbar).tooltip_text = "Ampliar página"
	_button("Ajustar", _fit_page, toolbar).tooltip_text = "Ver toda la página"
	status = UI.text("La portada cuenta como página 1.", 17, Color("#d5e5f8"))
	reader.add_child(status)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.resized.connect(_size_page)
	reader.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	picture = TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.resized.connect(func(): picture.pivot_offset = picture.size * 0.5)
	center.add_child(picture)
	reader.hide()

func _button(label: String, action: Callable, parent: Control) -> Button:
	var button := UI.button(label, UI.BLUE, 19)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _pack_path(id: String) -> String:
	return LIBRARY.path_join(id + ".zip")

func _open_local_folder() -> void:
	var path := ProjectSettings.globalize_path(LIBRARY)
	DirAccess.make_dir_recursive_absolute(path)
	OS.shell_open(path)

func _open_book(book_name: String, id: String) -> void:
	var source := ZIPReader.new()
	if source.open(_pack_path(id)) != OK:
		return
	var info: Variant = JSON.parse_string(source.read_file("manifest.json").get_string_from_utf8())
	if not info is Dictionary or info.get("version", 0) != 1 or int(info.get("pages", 0)) < 1:
		source.close()
		shelf_status.text = "No se pudo leer el paquete de este libro."
		return
	var cover := _page_texture(source, 1)
	if cover == null:
		source.close()
		shelf_status.text = "No se pudo abrir la portada de este libro."
		return
	pack = source
	total = int(info["pages"])
	zoom = 1.0
	title.text = book_name
	shelf.hide()
	reader.show()
	_show_page(1, cover)
	page_input.grab_focus()
	book_opened.emit()

func _page_texture(source: ZIPReader, number: int) -> ImageTexture:
	var data := source.read_file("pages/%04d.webp" % number)
	var image := Image.new()
	if data.is_empty() or image.load_webp_from_buffer(data) != OK:
		return null
	return ImageTexture.create_from_image(image)

func _step(direction: int) -> void:
	_go_to(current + direction)

func _jump(value: String) -> void:
	var number := value.strip_edges()
	if not number.is_valid_int() or int(number) < 1 or int(number) > total:
		status.text = "Escribe un número del 1 al %d." % total
		page_input.grab_focus()
		page_input.select_all()
		return
	_go_to(int(number))

func _go_to(number: int) -> void:
	if number < 1 or number > total or (transition and transition.is_running()):
		return
	if number == current:
		status.text = "Ya estás en la página %d." % number
		return
	var texture := _page_texture(pack, number)
	if texture == null:
		status.text = "No se pudo abrir la página %d." % number
		return
	previous.disabled = true
	next.disabled = true
	search.disabled = true
	transition = create_tween()
	transition.tween_property(picture, "scale:x", 0.06, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	transition.tween_callback(_show_page.bind(number, texture))
	transition.tween_property(picture, "scale:x", 1.0, 0.17).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	transition.tween_callback(_update_buttons)

func _show_page(number: int, texture: ImageTexture) -> void:
	current = number
	picture.texture = texture
	page_count.text = "%d / %d" % [current, total]
	page_input.text = str(current)
	status.text = "La portada cuenta como página 1."
	scroll.scroll_horizontal = 0
	scroll.scroll_vertical = 0
	_size_page()
	if not transition or not transition.is_running():
		_update_buttons()

func _update_buttons() -> void:
	previous.disabled = current <= 1
	next.disabled = current >= total
	search.disabled = false

func _size_page() -> void:
	if not is_instance_valid(picture) or picture.texture == null:
		return
	var source_size := picture.texture.get_size()
	var available := (scroll.size - Vector2(24, 24)).max(Vector2.ONE)
	var factor := minf(available.x / source_size.x, available.y / source_size.y)
	picture.custom_minimum_size = source_size * factor * zoom

func _change_zoom(amount: float) -> void:
	zoom = clampf(zoom + amount, 1.0, 3.8)
	_size_page()

func _fit_page() -> void:
	zoom = 1.0
	_size_page()

func back_requested() -> void:
	if not reader.visible:
		closed.emit()
		return
	if transition and transition.is_valid():
		transition.kill()
	picture.scale = Vector2.ONE
	picture.texture = null
	pack.close()
	pack = null
	reader.hide()
	shelf.show()
	title.text = _shelf_title()

func _shelf_title() -> String:
	return subject + " · Biblioteca"

func _unhandled_key_input(event: InputEvent) -> void:
	if reader.visible and event.is_pressed() and not page_input.has_focus():
		if event.is_action_pressed("ui_left"):
			_step(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right"):
			_step(1)
			get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if pack != null:
		pack.close()
