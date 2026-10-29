extends RefCounted

const INK := Color("#193f60")
const BLUE := Color("#086bac")
const PAPER := Color("#fff9e9")
static var objects: Dictionary = {}
static var scenery: Dictionary = {}
static var runners: Dictionary = {}

static func style(fill: Color, border: Color = Color("#cfad65"), radius: int = 19, margin: int = 12) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	box.shadow_color = Color(0.02, 0.13, 0.19, 0.23)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 4)
	return box

static func text(value: String, font_size: int = 22, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

static func button(value: String, color: Color = BLUE, font_size: int = 22) -> Button:
	var control := Button.new()
	control.text = value
	control.custom_minimum_size.y = 52
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	control.add_theme_font_size_override("font_size", font_size)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var fill := color
		if state == "hover": fill = color.lightened(0.12)
		if state == "pressed": fill = color.darkened(0.12)
		if state == "disabled": fill = Color("#71838c")
		control.add_theme_stylebox_override(state, style(fill, Color("#ffe18e") if state == "focus" else fill.darkened(0.2), 15, 10))
		control.add_theme_color_override("font_" + ("color" if state == "normal" else state + "_color"), Color.WHITE)
	return control

static func paper(parent: Node, color: Color = PAPER) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", style(color))
	parent.add_child(panel)
	var stack := column(panel, 10)
	return stack

static func column(parent: Node, gap: int = 10) -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", gap)
	parent.add_child(stack)
	return stack

static func row(parent: Node, gap: int = 10) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", gap)
	parent.add_child(line)
	return line

static func picture(texture: Texture2D, minimum: Vector2) -> TextureRect:
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = minimum
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art

static func object(index: int) -> Texture2D:
	if not objects.has(index):
		objects[index] = _cell("res://assets/ui/math/activities/objects-atlas.png", index, 4, 2)
	return objects[index]

static func backdrop(index: int) -> Texture2D:
	if not scenery.has(index):
		scenery[index] = _cell("res://assets/ui/math/activities/scenery-atlas.png", index, 2, 2)
	return scenery[index]

static func runner(index: int) -> Texture2D:
	if not runners.has(index):
		runners[index] = _cell("res://assets/characters/llama/adventure/run-atlas.png", index, 4, 2)
	return runners[index]

static func _cell(path: String, index: int, columns: int, rows: int) -> AtlasTexture:
	var atlas: Texture2D = load(path)
	var cell := Vector2(float(atlas.get_width()) / columns, float(atlas.get_height()) / rows)
	var region := AtlasTexture.new()
	region.atlas = atlas
	region.region = Rect2(Vector2(index % columns, index / columns) * cell, cell)
	region.filter_clip = true
	return region

static func background(parent: Control, index: int) -> TextureRect:
	var art := picture(backdrop(index), Vector2.ZERO)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	parent.add_child(art)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.12, 0.2, 0.18)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shade)
	return art

static func stars(count: int) -> String:
	return "★".repeat(clampi(count, 0, 3)) + "☆".repeat(3 - clampi(count, 0, 3))
