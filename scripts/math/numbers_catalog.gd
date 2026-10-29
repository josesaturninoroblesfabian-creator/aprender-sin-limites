extends RefCounted

## Original menu hotspots; Numbers now opens its eight native activities.
const TOPICS := [
	{"id": "one_digit", "title": "1 cifra", "detail": "Descubre los números del 0 al 9. Cuenta, reconoce y completa.", "example": "0 · 1 · 2 · 3 · 4 · 5 · 6 · 7 · 8 · 9", "color": Color("#ffa500"), "rect": Rect2(0.295, 0.263, 0.229, 0.275)},
	{"id": "two_digits", "title": "2 cifras", "detail": "Descubre los números del 10 al 99. Une las decenas y las unidades.", "example": "12 = 10 + 2", "color": Color("#38b62d"), "rect": Rect2(0.53, 0.263, 0.233, 0.275)},
	{"id": "three_digits", "title": "3 cifras", "detail": "Descubre los números del 100 al 999. Ordena centenas, decenas y unidades.", "example": "135 = 100 + 30 + 5", "color": Color("#9c43d9"), "rect": Rect2(0.295, 0.546, 0.229, 0.248)},
	{"id": "four_digits", "title": "4 cifras", "detail": "Descubre los números del 1000 al 9999. Explora las unidades de millar.", "example": "1024 = 1000 + 20 + 4", "color": Color("#f77b11"), "rect": Rect2(0.53, 0.546, 0.233, 0.248)},
	{"id": "count_objects", "title": "Contar objetos", "detail": "Cuenta los objetos y elige el número que corresponde.", "example": "● ● ●   =   3", "color": Color("#2bb637"), "rect": Rect2(0.19, 0.844, 0.152, 0.149)},
	{"id": "sequences", "title": "Completar secuencias", "detail": "Observa cómo cambian los números y descubre cuál sigue.", "example": "2 · 4 · 6 · ?", "color": Color("#078dcc"), "rect": Rect2(0.347, 0.844, 0.163, 0.149)},
	{"id": "compare", "title": "Mayor, menor o igual", "detail": "Compara cantidades y descubre cuál es mayor, menor o igual.", "example": "5 > 3    2 < 4    3 = 3", "color": Color("#ed2974"), "rect": Rect2(0.515, 0.844, 0.159, 0.149)},
	{"id": "quick_challenge", "title": "Reto rápido", "detail": "Viaja con el tren y encuentra números, posiciones y secuencias.", "example": "2 decenas y 3 unidades = 23", "color": Color("#9736d5"), "rect": Rect2(0.678, 0.844, 0.152, 0.149)},
]

static func find_topic(id: String) -> Dictionary:
	for topic in TOPICS:
		if topic.id == id:
			return topic
	return {}
