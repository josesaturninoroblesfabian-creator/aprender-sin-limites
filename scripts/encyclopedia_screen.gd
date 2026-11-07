extends Control

signal navigate_requested(module_name: String)

const UI = preload("res://scripts/math/math_ui.gd")
const LearningGuide = preload("res://scripts/ui/learning_guide.gd")
const EncyclopediaReader = preload("res://scripts/encyclopedia_reader.gd")
const ART := "res://assets/ui/encyclopedia/encyclopedia-menu.jpg"
const ART_SIZE := Vector2(1536, 1024)
const SUBJECTS := {
	"Historia Universal": Rect2(736, 304, 329, 193),
	"Astronomía": Rect2(1097, 307, 330, 190),
	"Biología": Rect2(1095, 511, 334, 198),
	"Anatomía": Rect2(725, 508, 335, 199),
	"Zoología": Rect2(713, 711, 716, 184),
}
const EXPLORER_PROMPTS := {
	"Historia Universal": ["¿Qué usaban las personas para escribir hace mucho tiempo?", preload("res://assets/audio/guides/child-voices/history.wav")],
	"Astronomía": ["¿Por qué algunas noches vemos la Luna con una forma diferente?", preload("res://assets/audio/guides/child-voices/astronomy.wav")],
	"Biología": ["Piensa en una planta. ¿Qué necesita para crecer?", preload("res://assets/audio/guides/child-voices/biology.wav")],
	"Anatomía": ["Pon la mano sobre tu pecho. ¿Puedes sentir cómo late el corazón?", preload("res://assets/audio/guides/child-voices/anatomy.wav")],
	"Zoología": ["Piensa en dos animales. ¿En qué se parecen y en qué son diferentes?", preload("res://assets/audio/guides/child-voices/zoology.wav")],
}
const BOOKS := {
	"Anatomía": [["Atlas visual de anatomía", "atlas-visual"], ["Prometheus · Aparato locomotor", "prometheus"]],
	"Astronomía": [["100 conceptos básicos de astronomía", "astronomia-100-conceptos"], ["El libro de la astronomía", "libro-astronomia"]],
	"Zoología": [["Zoología para gestión ambiental", "zoologia"]],
	"Historia Universal": [["El alba de la civilización", "alba-civilizacion"], ["Atlas de la historia universal", "atlas-historia-universal"]],
	"Biología": [["Biología · Conceptos y fundamentos básicos", "biologia-fundamentos"]],
}
const SHORTCUTS := [
	["Inicio", "", Rect2(10, 15, 136, 100)],
	["Vocales", "Lenguaje", Rect2(10, 128, 136, 98)],
	["Abecedario", "Lenguaje", Rect2(10, 242, 136, 102)],
	["Números", "Números", Rect2(10, 354, 136, 101)],
	["Matemáticas", "Matemática", Rect2(10, 467, 136, 102)],
	["Geometría", "Geometría", Rect2(10, 580, 136, 101)],
	["Diccionario", "Diccionario", Rect2(10, 690, 136, 100)],
	["Cuentos", "Cuentos", Rect2(10, 910, 136, 101)],
]
var design: Control
var selected_button: Button
var guide: LearningGuide
var book_reader: EncyclopediaReader

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
	_add_hotspot("Volver al inicio", Rect2(1428, 9, 100, 97), navigate_requested.emit.bind(""))
	for subject in SUBJECTS:
		_add_hotspot(subject, SUBJECTS[subject], _show_subject.bind(subject))
	guide = LearningGuide.new()
	guide.setup(true, preload("res://assets/audio/guides/child-voices/encyclopedia-intro.wav"))
	design.add_child(guide)
	guide.animate_art(picture, Vector2(495, 407), Vector2(417, 368), Vector2(529, 326))
	_add_hotspot("Escuchar a la guía de Enciclopedia", Rect2(261, 195, 365, 294), guide.play_intro)
	guide.play_intro()
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
	if is_instance_valid(book_reader) or not BOOKS.has(subject):
		return
	selected_button = get_viewport().gui_get_focus_owner() as Button
	design.hide()
	var prompt: Array = EXPLORER_PROMPTS[subject]
	book_reader = EncyclopediaReader.new()
	book_reader.subject = subject
	book_reader.catalog = BOOKS[subject]
	book_reader.prompt = prompt[0]
	book_reader.repeat_prompt = guide.play_clip.bind(prompt[1])
	book_reader.book_opened.connect(guide.stop)
	book_reader.closed.connect(_close_subject)
	add_child(book_reader)
	guide.play_clip(prompt[1])

func _close_subject() -> void:
	guide.stop()
	book_reader.queue_free()
	book_reader = null
	design.show()
	if is_instance_valid(selected_button):
		selected_button.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(book_reader):
			book_reader.back_requested()
		else:
			navigate_requested.emit("")
		get_viewport().set_input_as_handled()
