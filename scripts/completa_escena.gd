extends Control

signal back_requested

const Carmelo = preload("res://scripts/stories/carmelo_avatar.gd")
const PuzzlePiece = preload("res://scripts/games/puzzle_piece.gd")
const REPO = preload("res://scripts/stories/story_repository.gd")
const INK := Color("#173b70")
const WOOD := Color("#985128")
const STORY_IDS := ["tres_chanchitos", "caperucita_roja", "el_zorro_y_la_estrella", "hansel_y_gretel", "gallina_huevos_oro"]

var board: Control
var tray: VBoxContainer
var clue: Label
var progress: Label
var feedback: Label
var next_button: Button
var guide: TextureRect
var progress_badges: Label
var stories: Array[Dictionary] = []
var current_story: Dictionary = {}
var missing_slots: Array[int] = []
var placed_slots: Array[int] = []
var round_index := 0
var rounds := 3

func _ready() -> void:
	_build_ui()
	_load_stories()
	_start_round()
	StoryAudio.guide("welcome", self)
	get_viewport().size_changed.connect(_layout_board)

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/backgrounds/fondo-andes.png") as Texture2D
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.13, 0.28, 0.38)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		margin.add_theme_constant_override("margin_%s" % ["left", "top", "right", "bottom"][side], 18)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	margin.add_child(root)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 82
	root.add_child(header)
	var back := _button("⌂\nVolver al menú", Color("#985128"), Vector2(150, 68))
	back.pressed.connect(_back)
	header.add_child(back)
	var title_row := HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(title_row)
	var title_star_left := _label("★", 37, Color("#ffd339"), true)
	title_row.add_child(title_star_left)
	var title := Label.new()
	title.text = "¡Completa la escena!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 39)
	title.add_theme_color_override("font_color", Color("#fff26b"))
	title.add_theme_color_override("font_outline_color", Color("#173eaa"))
	title.add_theme_constant_override("outline_size", 8)
	_font(title, 800)
	title_row.add_child(title)
	var title_star_right := _label("★", 37, Color("#ffd339"), true)
	title_row.add_child(title_star_right)
	var progress_panel := PanelContainer.new()
	progress_panel.custom_minimum_size = Vector2(174, 76)
	progress_panel.add_theme_stylebox_override("panel", _style(Color("#0876c9"), Color("#ffd45b"), 4, 20))
	header.add_child(progress_panel)
	var progress_stack := VBoxContainer.new()
	progress_stack.add_theme_constant_override("separation", 0)
	progress_panel.add_child(progress_stack)
	progress = _label("Progreso 1 de 3", 17, Color.WHITE, true)
	progress_stack.add_child(progress)
	progress_badges = _label("⭐  🧩  🧩", 21, Color.WHITE, true)
	progress_badges.name = "InsigniasProgreso"
	progress_stack.add_child(progress_badges)
	var instruction := PanelContainer.new()
	instruction.add_theme_stylebox_override("panel", _style(Color("#92502c"), Color("#ffd05a"), 4, 18))
	root.add_child(instruction)
	clue = _label("Arrastra cada pieza hasta su lugar", 22, Color.WHITE, true)
	instruction.add_child(clue)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	root.add_child(content)
	var left := PanelContainer.new()
	left.custom_minimum_size.x = 205
	left.add_theme_stylebox_override("panel", _style(Color("#fff5df"), Color("#db9c44"), 4, 23))
	content.add_child(left)
	var left_stack := VBoxContainer.new()
	left_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_child(left_stack)
	guide = Carmelo.new()
	guide.custom_minimum_size = Vector2(0, 300)
	guide.texture = load("res://assets/carmelo-personaje.png") as Texture2D
	guide.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	left_stack.add_child(guide)
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", _style(Color.WHITE, Color("#087fd0"), 3, 22))
	left_stack.add_child(bubble)
	var guide_text := _label("¡Ayúdame a armar esta historia! Arrastra las piezas a su lugar.", 17, INK, true)
	guide_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(guide_text)
	var scene_panel := PanelContainer.new()
	scene_panel.name = "MarcoDeLaEscena"
	scene_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene_panel.add_theme_stylebox_override("panel", _style(Color("#fff0c5"), Color("#b97232"), 7, 27))
	content.add_child(scene_panel)
	board = Control.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene_panel.add_child(board)
	var side := PanelContainer.new()
	side.custom_minimum_size.x = 145
	side.add_theme_stylebox_override("panel", _style(Color("#fff5df"), Color("#db9c44"), 4, 23))
	content.add_child(side)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	side.add_child(stack)
	stack.add_child(_label("Piezas", 19, INK, true))
	tray = VBoxContainer.new()
	tray.alignment = BoxContainer.ALIGNMENT_CENTER
	tray.add_theme_constant_override("separation", 8)
	stack.add_child(tray)
	feedback = _label("Busca las piezas que completan la imagen.", 15, INK, true)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(feedback)
	var footer := HBoxContainer.new()
	footer.custom_minimum_size.y = 50
	root.add_child(footer)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	next_button = _button("¡Siguiente!  ➜", Color("#20b84c"), Vector2(205, 56))
	next_button.visible = false
	next_button.pressed.connect(_next_round)
	footer.add_child(next_button)

func _load_stories() -> void:
	var loaded: Variant = REPO.all_stories()
	if loaded is Array:
		for item in loaded:
			if item is Dictionary and String(item.get("id", "")) in STORY_IDS and not item.get("order", []).is_empty():
				stories.append(item)
	if stories.is_empty():
		clue.text = "No se encontraron escenas. Vuelve a intentarlo más tarde."

func _start_round() -> void:
	if stories.is_empty():
		return
	if round_index >= rounds:
		round_index = 0
	stories.shuffle()
	current_story = stories[round_index % stories.size()]
	missing_slots.clear()
	placed_slots.clear()
	var order: Array = current_story.get("order", [0, 2, 5, 7])
	var atlas: Texture2D = load(String(current_story.get("atlas", ""))) as Texture2D
	if atlas == null:
		return
	var cell := Vector2(atlas.get_width() / 4.0, atlas.get_height() / 2.0)
	var scene := AtlasTexture.new()
	scene.atlas = atlas
	scene.region = Rect2(Vector2(int(order[0]) % 4, int(order[0]) / 4) * cell, cell)
	for child in board.get_children(): child.queue_free()
	for child in tray.get_children(): child.queue_free()
	var scene_image := TextureRect.new()
	scene_image.texture = scene
	scene_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_image.stretch_mode = TextureRect.STRETCH_SCALE
	scene_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(scene_image)
	clue.text = "Completa la escena de «%s»" % String(current_story.get("title", "este cuento"))
	progress.text = "Progreso %d de %d" % [round_index + 1, rounds]
	var badge_text := ""
	for badge_index in range(rounds):
		badge_text += "⭐  " if badge_index <= round_index else "🧩  "
	progress_badges.text = badge_text.strip_edges()
	var slot_rects := [Rect2(0.55, 0.08, 0.29, 0.27), Rect2(0.10, 0.56, 0.28, 0.30), Rect2(0.62, 0.58, 0.28, 0.28)]
	for index in range(4):
		if index == 3:
			continue
		var slot := PanelContainer.new()
		slot.anchor_left = slot_rects[index].position.x
		slot.anchor_top = slot_rects[index].position.y
		slot.anchor_right = slot_rects[index].end.x
		slot.anchor_bottom = slot_rects[index].end.y
		slot.set_meta("slot_index", index)
		slot.add_theme_stylebox_override("panel", _style(Color("#75866e"), Color("#fffdf0"), 3, 28))
		slot.set_script(load("res://scripts/games/puzzle_slot.gd"))
		board.add_child(slot)
		var image := Label.new()
		image.text = "✦"
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		image.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		image.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		image.add_theme_font_size_override("font_size", 44)
		image.add_theme_color_override("font_color", Color("#606c5c"))
		slot.add_child(image)
		missing_slots.append(index)
		slot.set_meta("missing", true)
	for index in range(3):
		var piece := PuzzlePiece.new()
		piece.piece_index = missing_slots[index]
		var target_rect: Rect2 = slot_rects[missing_slots[index]]
		var piece_atlas := AtlasTexture.new()
		piece_atlas.atlas = atlas
		piece_atlas.region = Rect2(scene.region.position + target_rect.position * cell, target_rect.size * cell)
		piece.texture = piece_atlas
		piece.custom_minimum_size = Vector2(116, 78)
		piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		piece.stretch_mode = TextureRect.STRETCH_SCALE
		piece.mouse_filter = Control.MOUSE_FILTER_STOP
		tray.add_child(piece)
	feedback.text = "Arrastra las tres piezas a sus espacios."
	next_button.visible = false

func on_piece_dropped(slot: Control, piece_index: int) -> void:
	if not slot.has_meta("missing") or not bool(slot.get_meta("missing")) or piece_index != int(slot.get_meta("slot_index")):
		feedback.text = "¡Casi! Prueba con la pieza que coincide con ese espacio."
		return
	var dragged_piece: TextureRect
	for piece in tray.get_children():
		if piece is TextureRect and int(piece.get("piece_index")) == piece_index:
			dragged_piece = piece
			break
	if dragged_piece == null:
		feedback.text = "No encontré esa pieza. Intenta arrastrarla otra vez."
		return
	# Transfer the actual cropped image onto the board. Hiding the hole marker
	# alone left the opaque slot panel covering the scene underneath.
	var placed_image := TextureRect.new()
	placed_image.name = "PiezaColocada_%d" % piece_index
	placed_image.texture = dragged_piece.texture
	placed_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	placed_image.stretch_mode = TextureRect.STRETCH_SCALE
	placed_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placed_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(placed_image)
	slot.move_child(placed_image, 0)
	slot.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0), Color("#fffdf0"), 3, 28))
	slot.get_child(1).visible = false
	slot.set_meta("missing", false)
	placed_slots.append(piece_index)
	dragged_piece.queue_free()
	if placed_slots.size() == missing_slots.size():
		feedback.text = "¡Excelente! La escena de %s está completa." % String(current_story.get("title", "este cuento"))
		StoryAudio.guide("success", self)
		next_button.visible = true

func _next_round() -> void:
	if round_index == -1:
		round_index = 0
		next_button.text = "¡Siguiente! ➜"
		_start_round()
		return
	round_index += 1
	if round_index >= rounds:
		feedback.text = "¡Completaste las tres escenas! Carmelo está orgulloso de ti."
		progress.text = "¡Completado!"
		progress_badges.text = "⭐  ⭐  ⭐"
		next_button.text = "Jugar de nuevo"
		round_index = -1
		return
	_start_round()

func _layout_board() -> void:
	pass

func _back() -> void:
	StoryAudio.stop(self)
	back_requested.emit()

func _button(text: String, color: Color, minimum: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(color, Color("#fff0b4"), 3, 18))
	button.add_theme_stylebox_override("hover", _style(color.lightened(0.12), Color("#fff0b4"), 4, 18))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_font(button, 700)
	return button

func _label(text: String, size: int, color: Color, centered: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if centered: label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_font(label, 700)
	return label

func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(10)
	return style

func _font(control: Control, weight: int) -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Baloo 2", "Trebuchet MS", "Arial"])
	font.font_weight = weight
	font.fallbacks = [ThemeDB.fallback_font]
	control.add_theme_font_override("font", font)
