extends Control

signal completed

var guide_strokes: Array = []
var current_stroke_index: int = 0
var drawing_enabled: bool = false
var is_drawing: bool = false
var current_line := PackedVector2Array()
var completed_lines: Array[PackedVector2Array] = []
var furthest_sample: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	set_process_input(true)

func set_guide_strokes(strokes: Array) -> void:
	guide_strokes = strokes.duplicate(true)
	reset_drawing()

func start_drawing() -> void:
	drawing_enabled = true
	is_drawing = false
	queue_redraw()

func reset_drawing() -> void:
	drawing_enabled = false
	is_drawing = false
	current_stroke_index = 0
	furthest_sample = 0
	current_line.clear()
	completed_lines.clear()
	queue_redraw()

func _draw() -> void:
	for stroke_index in range(guide_strokes.size()):
		var samples := _sample_path(guide_strokes[stroke_index])
		for dash_index in range(0, samples.size() - 1, 4):
			var end_index: int = mini(dash_index + 2, samples.size() - 1)
			draw_line(samples[dash_index], samples[end_index], Color("#c5cbd0"), 8.0, true)
		if samples.size() > 2:
			var arrow_index: int = int(samples.size() * 0.60)
			var direction := (samples[mini(arrow_index + 1, samples.size() - 1)] - samples[arrow_index]).normalized()
			_draw_arrow(samples[arrow_index], direction)
		var start_point: Vector2 = samples[0]
		draw_circle(start_point, 18.0, Color("#168bd2"))
		draw_string(ThemeDB.fallback_font, start_point + Vector2(0, 7), str(stroke_index + 1), HORIZONTAL_ALIGNMENT_CENTER, 38.0, 20, Color.WHITE)
		draw_circle(samples[samples.size() - 1], 10.0, Color("#aeb6bd"))
	for line in completed_lines:
		if line.size() > 1:
			draw_polyline(line, Color("#24a9ed"), 13.0, true)
	if current_line.size() > 1:
		draw_polyline(current_line, Color("#f04450"), 13.0, true)

func _draw_arrow(position: Vector2, direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	var side := Vector2(-direction.y, direction.x)
	var tip := position + direction * 12.0
	var left := position - direction * 7.0 + side * 7.0
	var right := position - direction * 7.0 - side * 7.0
	draw_colored_polygon(PackedVector2Array([tip, left, right]), Color("#1768b5"))

func _sample_path(path: PackedVector2Array) -> PackedVector2Array:
	var samples := PackedVector2Array()
	if path.size() < 2:
		return samples
	var points := PackedVector2Array()
	for point in path:
		points.append(Vector2(point.x * size.x, point.y * size.y))
	var lengths: Array[float] = []
	var total_length := 0.0
	for index in range(points.size() - 1):
		var segment_length := points[index].distance_to(points[index + 1])
		lengths.append(segment_length)
		total_length += segment_length
	var sample_count := 72
	for sample_index in range(sample_count):
		var target_distance := total_length * float(sample_index) / float(sample_count - 1)
		var travelled := 0.0
		for segment_index in range(lengths.size()):
			var segment_length: float = lengths[segment_index]
			if target_distance <= travelled + segment_length or segment_index == lengths.size() - 1:
				var portion := 0.0 if segment_length <= 0.0 else clampf((target_distance - travelled) / segment_length, 0.0, 1.0)
				samples.append(points[segment_index].lerp(points[segment_index + 1], portion))
				break
			travelled += segment_length
	return samples

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_stroke(event.position)
		else:
			_finish_stroke(event.position)
		accept_event()
	elif event is InputEventMouseMotion and is_drawing:
		_extend_stroke(event.position)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_stroke(event.position)
		else:
			_finish_stroke(event.position)
		accept_event()
	elif event is InputEventScreenDrag and is_drawing:
		_extend_stroke(event.position)
		accept_event()

func _input(event: InputEvent) -> void:
	# Continúa capturando el trazo si el niño mueve el dedo o mouse fuera del panel.
	if not is_drawing:
		return
	if event is InputEventMouseMotion:
		var mouse_local := make_canvas_position_local(event.position)
		if not Rect2(Vector2.ZERO, size).has_point(mouse_local):
			_extend_stroke(mouse_local)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var release_local := make_canvas_position_local(event.position)
		if not Rect2(Vector2.ZERO, size).has_point(release_local):
			_finish_stroke(release_local)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag_local := make_canvas_position_local(event.position)
		if not Rect2(Vector2.ZERO, size).has_point(drag_local):
			_extend_stroke(drag_local)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed:
		var touch_local := make_canvas_position_local(event.position)
		if not Rect2(Vector2.ZERO, size).has_point(touch_local):
			_finish_stroke(touch_local)
			get_viewport().set_input_as_handled()

func _begin_stroke(position: Vector2) -> void:
	if not drawing_enabled or current_stroke_index >= guide_strokes.size():
		return
	var samples := _sample_path(guide_strokes[current_stroke_index])
	var tolerance := _trace_tolerance()
	var resume_index := clampi(furthest_sample, 0, samples.size() - 1)
	if furthest_sample > 0 and position.distance_to(samples[resume_index]) <= tolerance * 1.5:
		if current_line.is_empty() or current_line[current_line.size() - 1].distance_to(position) >= 3.0:
			current_line.append(position)
	elif position.distance_to(samples[0]) <= tolerance * 1.5:
		furthest_sample = 0
		current_line = PackedVector2Array([samples[0]])
	else:
		return
	is_drawing = true
	grab_focus()
	queue_redraw()

func _extend_stroke(position: Vector2) -> void:
	if not is_drawing or current_stroke_index >= guide_strokes.size():
		return
	var samples := _sample_path(guide_strokes[current_stroke_index])
	var nearest_index := -1
	var nearest_distance := INF
	var search_start: int = maxi(furthest_sample - 4, 0)
	for sample_index in range(search_start, samples.size()):
		var distance := position.distance_to(samples[sample_index])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = sample_index
	var tolerance := _trace_tolerance()
	if nearest_index >= furthest_sample - 4 and nearest_distance <= tolerance:
		furthest_sample = maxi(furthest_sample, nearest_index)
		if current_line.is_empty() or current_line[current_line.size() - 1].distance_to(position) >= 3.0:
			current_line.append(position)
		queue_redraw()

func _finish_stroke(position: Vector2) -> void:
	if not is_drawing:
		return
	_extend_stroke(position)
	is_drawing = false
	var samples := _sample_path(guide_strokes[current_stroke_index])
	var required_index: int = int((samples.size() - 1) * 0.74)
	var tolerance := _trace_tolerance()
	if furthest_sample >= required_index and position.distance_to(samples[samples.size() - 1]) <= tolerance * 2.0:
		completed_lines.append(current_line.duplicate())
		current_stroke_index += 1
		current_line.clear()
		furthest_sample = 0
		if current_stroke_index >= guide_strokes.size():
			drawing_enabled = false
			completed.emit()
	queue_redraw()

func _trace_tolerance() -> float:
	# Margen más amplio para manos pequeñas y movimientos con saltos entre eventos.
	return maxf(32.0, minf(size.x, size.y) * 0.105)
