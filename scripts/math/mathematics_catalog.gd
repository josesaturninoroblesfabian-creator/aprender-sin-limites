extends RefCounted

const TOPICS := [
	{"id": "addition", "title": "Suma", "detail": "Junta cantidades y descubre cuántos objetos hay en total.", "example": "2 + 1 = 3", "color": Color("#ffa500"), "rect": Rect2(0.295, 0.263, 0.229, 0.24)},
	{"id": "subtraction", "title": "Resta", "detail": "Quita algunos objetos y cuenta cuántos quedan.", "example": "5 − 2 = 3", "color": Color("#38b62d"), "rect": Rect2(0.53, 0.263, 0.233, 0.24)},
	{"id": "multiplication", "title": "Multiplicación", "detail": "Forma grupos iguales y descubre cuánto suman entre todos.", "example": "3 grupos de 2 = 6", "color": Color("#9c43d9"), "rect": Rect2(0.295, 0.51, 0.229, 0.24)},
	{"id": "division", "title": "División", "detail": "Reparte objetos en grupos iguales, paso a paso.", "example": "6 ÷ 2 = 3", "color": Color("#078dcc"), "rect": Rect2(0.53, 0.51, 0.233, 0.24)},
	{"id": "count_objects", "title": "Contar objetos", "detail": "Cuenta las cantidades para preparar tus primeras operaciones.", "example": "● ● ●   =   3", "color": Color("#2bb637"), "rect": Rect2(0.19, 0.81, 0.152, 0.18)},
	{"id": "solve_exercises", "title": "Resolver ejercicios", "detail": "Practica suma, resta, multiplicación y división con ejemplos guiados.", "example": "3 + 2 = ?", "color": Color("#078dcc"), "rect": Rect2(0.347, 0.81, 0.163, 0.18)},
	{"id": "level_game", "title": "Juego por niveles", "detail": "Avanza paso a paso con desafíos de distintas dificultades.", "example": "Nivel 1 → Nivel 2 → Nivel 3", "color": Color("#ef9410"), "rect": Rect2(0.515, 0.81, 0.159, 0.18)},
	{"id": "quick_challenge", "title": "Reto rápido", "detail": "Pon a prueba lo que aprendiste con pequeños retos de operaciones.", "example": "7 + 5 = ?", "color": Color("#ed2974"), "rect": Rect2(0.678, 0.81, 0.152, 0.18)},
]
