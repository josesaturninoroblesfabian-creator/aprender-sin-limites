extends Control

signal answer_selected(value: int)
const UI = preload("res://scripts/math/math_ui.gd")
const Art = preload("res://scripts/numbers/number_art.gd")
var question: Dictionary = {}
var solved := false
var show_rule := false
var walk := 0.0
var clock := 0.0
var active := true

func _ready() -> void:
	custom_minimum_size = Vector2(550, 295)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true
	resized.connect(queue_redraw)

func setup(item: Dictionary) -> void:
	question = item
	solved = false
	show_rule = false
	walk = 0.0
	queue_redraw()

func stone_rect(index: int) -> Rect2:
	var w := minf(148.0, size.x / 6.3)
	var center := Vector2(size.x * (0.1 + index * 0.2), size.y * 0.6 - sin(index * PI / 4) * size.y * 0.13)
	return Rect2(center - Vector2(w * 0.5, w * 0.30), Vector2(w, w * 0.6))

func _can_drop_data(at: Vector2, data: Variant) -> bool:
	return active and not solved and not question.is_empty() and data is Dictionary and data.get("type") == "bridge_number" and data.get("value") is int and stone_rect(int(question.missing)).grow(16).has_point(at)

func _drop_data(at: Vector2, data: Variant) -> void:
	if _can_drop_data(at, data): answer_selected.emit(int(data.value))

func _process(delta: float) -> void:
	if not active: return
	clock += delta
	if solved: walk = minf(4, walk + delta * 2.2)
	if is_visible_in_tree(): queue_redraw()

func _draw() -> void:
	if question.is_empty(): return
	var font := ThemeDB.fallback_font
	for index in range(5):
		var rect := stone_rect(index)
		var missing := index == int(question.missing) and not solved
		if missing:
			draw_circle(rect.get_center(), rect.size.x * (0.47 + sin(clock * 3) * 0.025), Color(1, 0.94, 0.65, 0.68))
			draw_arc(rect.get_center(), rect.size.x * 0.46, 0, TAU, 40, Color("#ffe38a"), 3, true)
		else: draw_texture_rect(Art.object(2), rect.grow(15), false)
		var text := "?" if missing else str(int(question.terms[index]))
		var tag := Rect2(rect.get_center() - Vector2(rect.size.x * 0.43, 22), Vector2(rect.size.x * 0.86, 43))
		draw_style_box(UI.style(Color("#fff8e3"), Color("#cfa95c"), 12, 0), tag)
		draw_string(font, Vector2(tag.position.x, tag.position.y + 31), text, HORIZONTAL_ALIGNMENT_CENTER, tag.size.x, 29 if int(question.width) < 4 else 25, Color("#174765"))
		if index < 4 and show_rule:
			var middle := (rect.get_center() + stone_rect(index + 1).get_center()) * 0.5
			draw_string(font, middle - Vector2(22, 25), ("+" if int(question.step) > 0 else "−") + str(absi(int(question.step))), HORIZONTAL_ALIGNMENT_CENTER, 48, 21, Color("#fff6cc"))
	var index := mini(3, int(walk))
	var at := stone_rect(index).get_center().lerp(stone_rect(index + 1).get_center(), walk - index) if walk < 4 else stone_rect(4).get_center()
	at.y -= 77 + (absf(sin(clock * 12)) * 9 if solved and walk < 4 else 0)
	var frame := 1 + int(clock * 8) % 4 if solved and walk < 4 else 0
	draw_texture_rect(UI.runner(frame), Rect2(at - Vector2(54, 54), Vector2(108, 108)), false)
	var caption := "¡Puente completo!" if solved else "Arrastra la piedra al hueco o toca su respuesta"
	draw_style_box(UI.style(Color(0.02, 0.25, 0.35, 0.9), Color("#d7bb73"), 14), Rect2(15, size.y - 49, size.x - 30, 45))
	draw_string(font, Vector2(25, size.y - 18), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x - 50, 22, Color.WHITE)
