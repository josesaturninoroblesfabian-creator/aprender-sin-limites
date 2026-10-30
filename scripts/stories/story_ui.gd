extends RefCounted

const INK := Color("#173b70")
const BLUE := Color("#086fb7")
const PAPER := Color("#fffaf0")
const StoryImage = preload("res://scripts/stories/story_image.gd")

static func style(fill: Color, border: Color = Color("#c9dded"), radius: int = 18, margin: int = 12) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	return box

static func label(text: String, size: int = 21, color: Color = INK) -> Label:
	var node := Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node

static func button(text: String, color: Color = BLUE, size: int = 20) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 48
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size", size)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var fill := color.lightened(0.1) if state == "hover" else color
		if state == "disabled":
			fill = Color("#718ba1")
		node.add_theme_stylebox_override(state, style(fill, Color("#ffe19a") if state == "focus" else fill.darkened(0.2), 14, 8))
		node.add_theme_color_override("font_" + ("color" if state == "normal" else state + "_color"), Color.WHITE)
	return node

static func picture(texture: Texture2D, minimum_height: float = 100) -> TextureRect:
	var node: TextureRect = StoryImage.new() if texture is AtlasTexture else TextureRect.new()
	if node is StoryImage: node.set_frame(texture)
	else: node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.clip_contents = true
	node.custom_minimum_size.y = minimum_height
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func panel(fill: Color = PAPER, border: Color = Color("#e8c98d")) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", style(fill, border, 21, 14))
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

static func column(parent: Node, separation: int = 10) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	parent.add_child(node)
	return node

static func background(parent: Control) -> void:
	var art := TextureRect.new()
	art.texture = load("res://assets/backgrounds/fondo-paisaje-andino.png")
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.12, 0.23, 0.64)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shade)

static func modal(parent: Control, title: String) -> VBoxContainer:
	var overlay := Control.new()
	overlay.name = "StoryModal"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.04, 0.09, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var card := panel()
	card.anchor_left = 0.26
	card.anchor_top = 0.23
	card.anchor_right = 0.76
	card.anchor_bottom = 0.78
	overlay.add_child(card)
	var stack := column(card, 14)
	stack.set_meta("overlay", overlay)
	stack.add_child(label(title, 29))
	return stack

static func dismiss_modal(parent: Control) -> bool:
	var overlay := parent.get_node_or_null("StoryModal")
	if overlay == null:
		return false
	StoryAudio.stop()
	overlay.queue_free()
	return true

static func close_modal_button(stack: VBoxContainer) -> void:
	var close := button("Cerrar")
	close.pressed.connect(func():
		StoryAudio.stop()
		stack.get_meta("overlay").queue_free()
	)
	stack.add_child(close)
	close.grab_focus()

static func sound_dialog(parent: Control) -> void:
	StoryAudio.stop()
	var stack := modal(parent, "La voz de Carmelo")
	var toggle := button("Voz activada" if not StoryAudio.muted else "Voz silenciada", Color("#7950b3"))
	toggle.toggle_mode = true
	toggle.button_pressed = not StoryAudio.muted
	toggle.toggled.connect(func(enabled: bool):
		StoryAudio.set_sound(enabled, StoryAudio.volume)
		toggle.text = "Voz activada" if enabled else "Voz silenciada"
	)
	stack.add_child(toggle)
	stack.add_child(label("Volumen", 21))
	var slider := HSlider.new()
	slider.max_value = 100
	slider.step = 5
	slider.value = StoryAudio.volume
	slider.custom_minimum_size.y = 45
	slider.value_changed.connect(func(value: float): StoryAudio.set_sound(not StoryAudio.muted, value))
	stack.add_child(slider)
	var sample := button("Escuchar una muestra", Color("#118b74"))
	sample.pressed.connect(func(): StoryAudio.guide("welcome", parent))
	stack.add_child(sample)
	stack.add_child(label("Audio incluido. Funciona sin internet.", 17))
	close_modal_button(stack)
