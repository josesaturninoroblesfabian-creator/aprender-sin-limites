extends Control

signal navigate_requested(module_name: String)

const UI = preload("res://scripts/math/math_ui.gd")
const ART := "res://assets/ui/encyclopedia/encyclopedia-reference.jpg"
const ART_SIZE := Vector2(1024, 682)
const SUBJECTS := {
	"Historia Universal": Rect2(406, 196, 307, 152),
	"Astronomía": Rect2(728, 202, 227, 134),
	"Biología": Rect2(727, 339, 229, 135),
	"Anatomía": Rect2(399, 384, 147, 212),
	"Zoología": Rect2(549, 476, 410, 125),
}
const SHORTCUTS := [
	["Inicio", "", Rect2(5, 8, 94, 73)],
	["Vocales", "Lenguaje", Rect2(5, 85, 94, 68)],
	["Abecedario", "Lenguaje", Rect2(5, 157, 94, 72)],
	["Números", "Números", Rect2(5, 232, 94, 72)],
	["Matemáticas", "Matemática", Rect2(5, 307, 94, 72)],
	["Geometría", "Geometría", Rect2(5, 382, 94, 72)],
	["Diccionario", "Diccionario", Rect2(5, 457, 94, 66)],
	["Cuentos", "Cuentos", Rect2(5, 601, 94, 72)],
]
var design: Control
var dialog: Control
var selected_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backing := ColorRect.new()
	backing.color = Color("#152e51")
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backing)
	design = Control.new()
	design.size = ART_SIZE
	add_child(design)
	var picture := UI.picture(load(ART), Vector2.ZERO)
	picture.size = ART_SIZE
	design.add_child(picture)
	for shortcut in SHORTCUTS:
		_add_hotspot(shortcut[0], shortcut[2], navigate_requested.emit.bind(shortcut[1]))
	_add_hotspot("Volver al inicio", Rect2(950, 4, 70, 72), navigate_requested.emit.bind(""))
	for subject in SUBJECTS:
		_add_hotspot(subject, SUBJECTS[subject], _show_subject.bind(subject))
	resized.connect(_fit_design)
	_fit_design()

func _fit_design() -> void:
	var factor := minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	design.scale = Vector2.ONE * factor
	design.position = (size - ART_SIZE * factor) * 0.5

func _add_hotspot(label: String, area: Rect2, callback: Callable) -> void:
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
		highlight.bg_color = Color(1.0, 0.91, 0.58, 0.18)
		highlight.border_color = Color("#fff2a0")
		highlight.set_border_width_all(3)
		highlight.set_corner_radius_all(16)
		button.add_theme_stylebox_override(state, highlight)
	button.pressed.connect(callback)
	design.add_child(button)

func _show_subject(subject: String) -> void:
	if is_instance_valid(dialog):
		return
	selected_button = get_viewport().gui_get_focus_owner() as Button
	dialog = ColorRect.new()
	dialog.color = Color(0.04, 0.10, 0.18, 0.74)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dialog)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(center)
	var content := UI.paper(center)
	content.get_parent().custom_minimum_size.x = 370
	content.add_child(UI.text(subject, 28))
	content.add_child(UI.text("Contenido en preparación.", 21))
	var close := UI.button("Volver a la Enciclopedia", UI.BLUE, 19)
	close.pressed.connect(_close_subject)
	content.add_child(close)
	close.grab_focus()
	for button in design.get_children():
		if button is Button:
			button.disabled = true

func _close_subject() -> void:
	dialog.queue_free()
	dialog = null
	for button in design.get_children():
		if button is Button:
			button.disabled = false
	if is_instance_valid(selected_button):
		selected_button.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(dialog):
			_close_subject()
		else:
			navigate_requested.emit("")
		get_viewport().set_input_as_handled()
