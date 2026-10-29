extends RefCounted

const PLANES := ["circle", "triangle", "square", "rectangle", "pentagon", "hexagon"]
const SOLIDS := ["cube", "sphere", "cylinder", "cone"]
const NAMES := {"circle": "Círculo", "triangle": "Triángulo", "square": "Cuadrado", "rectangle": "Rectángulo alargado", "pentagon": "Pentágono", "hexagon": "Hexágono", "cube": "Cubo", "sphere": "Esfera", "cylinder": "Cilindro", "cone": "Cono"}
const SIDES := {"circle": 0, "triangle": 3, "square": 4, "rectangle": 4, "pentagon": 5, "hexagon": 6}
const COLORS := {"red": Color("#e85458"), "blue": Color("#308bdb"), "gold": Color("#ffc642"), "green": Color("#4dbd76"), "violet": Color("#aa64d8"), "turquoise": Color("#26b9b7")}
const INK := Color("#174560")

static func token_shape(token: String) -> String:
	return token.split(":")[0]

static func token_color(token: String, fallback: String = "blue") -> Color:
	var pieces := token.split(":")
	return COLORS.get(pieces[1] if pieces.size() > 1 else fallback, COLORS.blue)

static func points(shape: String, center: Vector2, radius: float, angle: float = 0) -> PackedVector2Array:
	var vertices := PackedVector2Array()
	if shape == "rectangle":
		for p in [Vector2(-0.91, -0.49), Vector2(0.91, -0.49), Vector2(0.91, 0.49), Vector2(-0.91, 0.49)]:
			vertices.append(center + p.rotated(deg_to_rad(angle)) * radius)
	elif shape != "circle" and SIDES.has(shape):
		var count: int = SIDES[shape]
		var start := -PI * 0.5 if shape != "square" else -PI * 0.25
		for i in range(count): vertices.append(center + Vector2.from_angle(start + TAU * i / count + deg_to_rad(angle)) * radius)
	return vertices

static func hit(shape: String, at: Vector2, center: Vector2, radius: float, angle: float = 0) -> bool:
	return at.distance_to(center) <= radius if shape == "circle" else Geometry2D.is_point_in_polygon(at, points(shape, center, radius, angle))

static func paint(canvas: CanvasItem, shape: String, rect: Rect2, color: Color, angle: float = 0, outline: bool = false) -> void:
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.42
	if shape in SOLIDS:
		_solid(canvas, shape, center, radius, color)
		return
	if shape == "circle":
		if not outline: canvas.draw_circle(center, radius, color)
		canvas.draw_arc(center, radius, 0, TAU, 80, INK, 3, true)
	elif shape in PLANES:
		var polygon := points(shape, center, radius, angle)
		if not outline: canvas.draw_colored_polygon(polygon, color)
		polygon.append(polygon[0])
		canvas.draw_polyline(polygon, INK, 3, true)

static func _ellipse(canvas: CanvasItem, center: Vector2, rx: float, ry: float, color: Color) -> void:
	var polygon := PackedVector2Array()
	for i in range(48): polygon.append(center + Vector2(cos(TAU * i / 48) * rx, sin(TAU * i / 48) * ry))
	canvas.draw_colored_polygon(polygon, color)

static func _solid(canvas: CanvasItem, shape: String, c: Vector2, r: float, color: Color) -> void:
	if shape == "sphere":
		canvas.draw_circle(c, r, color.darkened(0.25))
		for i in range(18, 0, -1): canvas.draw_circle(c + Vector2(-r * 0.19, -r * 0.19), r * i / 22.0, color.lightened((18 - i) / 25.0))
	elif shape == "cube":
		var a := c + Vector2(-r * 0.7, -r * 0.4)
		var b := c + Vector2(r * 0.15, -r * 0.12)
		var d := c + Vector2(r * 0.15, r * 0.78)
		var e := c + Vector2(-r * 0.7, r * 0.5)
		var depth := Vector2(r * 0.62, -r * 0.42)
		canvas.draw_colored_polygon(PackedVector2Array([a, b, d, e]), color)
		canvas.draw_colored_polygon(PackedVector2Array([a, a + depth, b + depth, b]), color.lightened(0.35))
		canvas.draw_colored_polygon(PackedVector2Array([b, b + depth, d + depth, d]), color.darkened(0.25))
	elif shape == "cylinder":
		_ellipse(canvas, c + Vector2(0, r * 0.58), r * 0.7, r * 0.27, color.darkened(0.25))
		canvas.draw_rect(Rect2(c - Vector2(r * 0.7, r * 0.58), Vector2(r * 1.4, r * 1.16)), color)
		_ellipse(canvas, c - Vector2(0, r * 0.58), r * 0.7, r * 0.27, color.lightened(0.3))
	else:
		var base := c + Vector2(0, r * 0.66)
		_ellipse(canvas, base, r * 0.75, r * 0.24, color.darkened(0.25))
		canvas.draw_colored_polygon(PackedVector2Array([c - Vector2(0, r), base - Vector2(r * 0.75, 0), base + Vector2(r * 0.75, 0)]), color)
		_ellipse(canvas, base, r * 0.75, r * 0.18, color.darkened(0.1))
