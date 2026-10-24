extends RefCounted

const TOPICS := [
	{"id": "flat_shapes", "title": "Figuras planas", "detail": "Descubre círculos, cuadrados, triángulos y rectángulos.", "example": "Círculo · Cuadrado · Triángulo", "color": Color("#ffa500"), "rect": Rect2(0.295, 0.263, 0.229, 0.275)},
	{"id": "solid_shapes", "title": "Cuerpos geométricos", "detail": "Explora cubos, esferas, conos y cilindros. ¡Son formas con volumen!", "example": "Cubo · Esfera · Cono · Cilindro", "color": Color("#38b62d"), "rect": Rect2(0.53, 0.263, 0.233, 0.275)},
	{"id": "sides_vertices", "title": "Lados y vértices", "detail": "Cuenta los lados y las esquinas de cada figura.", "example": "Triángulo: 3 lados y 3 vértices", "color": Color("#9c43d9"), "rect": Rect2(0.295, 0.546, 0.229, 0.248)},
	{"id": "shape_patterns", "title": "Patrones y formas", "detail": "Observa las figuras que se repiten y descubre cuál sigue.", "example": "● ▲ ● ▲ ● ?", "color": Color("#f77b11"), "rect": Rect2(0.53, 0.546, 0.233, 0.248)},
	{"id": "find_shape", "title": "Busca la figura", "detail": "Escucha el nombre de una figura y encuéntrala entre las demás.", "example": "¡Encuentra el círculo!   ●", "color": Color("#2bb637"), "rect": Rect2(0.19, 0.844, 0.152, 0.149)},
	{"id": "build_pattern", "title": "Arma el patrón", "detail": "Completa una secuencia colocando la figura que falta.", "example": "● ■ ▲ ● ■ ?", "color": Color("#078dcc"), "rect": Rect2(0.347, 0.844, 0.163, 0.149)},
	{"id": "count_sides", "title": "Cuenta lados", "detail": "Mira cada figura y descubre cuántos lados y vértices tiene.", "example": "Pentágono: 5 lados", "color": Color("#ed2974"), "rect": Rect2(0.515, 0.844, 0.159, 0.149)},
	{"id": "quick_challenge", "title": "Reto rápido", "detail": "Resuelve pequeños desafíos de formas, lados y patrones.", "example": "¿Qué figura tiene 4 lados iguales?", "color": Color("#9736d5"), "rect": Rect2(0.678, 0.844, 0.152, 0.149)},
]
