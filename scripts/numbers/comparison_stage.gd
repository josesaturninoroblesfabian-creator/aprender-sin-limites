extends Control

const Rules = preload("res://scripts/numbers/number_rules.gd")
const UI = preload("res://scripts/math/math_ui.gd")
const Art = preload("res://scripts/numbers/number_art.gd")
var question: Dictionary = {}
var solved := false
var show_hint := false
var tilt := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(600, 300)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func setup(item: Dictionary) -> void:
	question = item
	tilt = 0
	solved = false
	show_hint = false
	queue_redraw()

func _process(delta: float) -> void:
	if question.is_empty(): return
	var direction := signi(int(question.left) - int(question.right)) if solved else 0
	tilt = move_toward(tilt, direction * 26.0, delta * 65)
	if is_visible_in_tree(): queue_redraw()

func _label(value_: String, rect: Rect2, fs: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y * 0.5 + fs * 0.35), value_, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fs, color)

func _draw() -> void:
	if question.is_empty(): return
	var center := Vector2(size.x * 0.5, size.y * 0.72)
	var left := Vector2(size.x * 0.25, size.y * 0.60 + tilt)
	var right := Vector2(size.x * 0.75, size.y * 0.60 - tilt)
	draw_line(left, right, Color("#83572b"), 12, true)
	draw_colored_polygon(PackedVector2Array([center - Vector2(0, 45), center + Vector2(-40, 70), center + Vector2(40, 70)]), Color("#b77b32"))
	var different := -1
	for place in range(int(question.width) - 1, -1, -1):
		if Rules.digits(int(question.left), int(question.width))[place] != Rules.digits(int(question.right), int(question.width))[place]:
			different = place
			break
	for side in range(2):
		var number := int(question.left if side == 0 else question.right)
		var at := left if side == 0 else right
		var card := Rect2(at.x - size.x * 0.21, 8, size.x * 0.42, size.y * 0.38)
		draw_style_box(UI.style(Color("#fff9e7"), Color("#cca65d"), 20), card)
		_label(str(number), Rect2(card.position, Vector2(card.size.x, 53)), 39, Color("#174765"))
		var digits_ := Rules.digits(number, int(question.width))
		var span := card.size.x / int(question.width)
		for place in range(int(question.width)):
			var rect := Rect2(card.position + Vector2((int(question.width) - 1 - place) * span + 5, 57), Vector2(span - 10, card.size.y - 64))
			var color: Color = Rules.COLORS[place]
			draw_style_box(UI.style(color.lightened(0.91), color if show_hint and place == different else color.lightened(0.5), 8), rect)
			_label(Rules.SHORT[place], Rect2(rect.position, Vector2(rect.size.x, 22)), 17, color)
			_label(str(digits_[place]), Rect2(rect.position + Vector2(0, 24), Vector2(rect.size.x, 30)), 29, color)
		var basket := Rect2(at - Vector2(75, 60), Vector2(150, 105))
		draw_texture_rect(Art.object(3), basket, false)
		if int(question.width) == 1:
			for unit in range(number):
				var p := at + Vector2((unit % 5 - 2) * 24, -25 - (unit / 5) * 24)
				draw_texture_rect(UI.object(0), Rect2(p - Vector2(11, 11), Vector2(22, 22)), false)
	var sign_rect := Rect2(center.x - 45, size.y * 0.16, 90, 70)
	draw_style_box(UI.style(Color("#fff0bd"), Color("#b8832a"), 20), sign_rect)
	_label(String(question.result) if solved else "?", sign_rect, 44, Color("#a33369"))
