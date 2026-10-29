extends Control

signal level_chosen(index: int)
const UI = preload("res://scripts/math/math_ui.gd")
const Progress = preload("res://scripts/math/math_progress.gd")
const Catalog = preload("res://scripts/math/activity_catalog.gd")
var nodes: Array[Button] = []
var _font: Font = ThemeDB.fallback_font

func _ready() -> void:
	custom_minimum_size = Vector2(580, 420)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	for index in range(12):
		var button := UI.button(str(index + 1), Catalog.COLORS[Catalog.OPERATIONS[index / 3]], 30)
		button.name = "Path_%d" % index
		button.add_theme_stylebox_override("normal", UI.style(Catalog.COLORS[Catalog.OPERATIONS[index / 3]], Color("#ffe2a3"), 33, 3))
		button.disabled = not Progress.level_unlocked(index)
		button.pressed.connect(func(): level_chosen.emit(index))
		add_child(button)
		nodes.append(button)
	resized.connect(_fit)
	_fit()

func point(index: int) -> Vector2:
	var row_index := index / 3
	var column := index % 3 if row_index % 2 == 0 else 2 - index % 3
	return Vector2(0.2 + column * 0.3, 0.11 + row_index * 0.24) * size

func _fit() -> void:
	for index in range(nodes.size()):
		nodes[index].size = Vector2(68, 68)
		nodes[index].position = point(index) - Vector2(34, 32)
	queue_redraw()

func _draw() -> void:
	var points := PackedVector2Array()
	for index in range(12): points.append(point(index))
	draw_polyline(points, Color("#b1833e"), 14, true)
	draw_polyline(points, Color("#ffe4a1"), 8, true)
	for index in range(12):
		var record := Progress.level_record(index)
		var place := point(index) + Vector2(-42, 63)
		draw_string(_font, place, UI.stars(int(record.get("stars", 0))), HORIZONTAL_ALIGNMENT_CENTER, 90, 23, Color("#8c5804"))
		if index % 3 == 0:
			draw_string(_font, point(index) + Vector2(-86, -47), Catalog.TITLES[Catalog.OPERATIONS[index / 3]], HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#224d60"))
