extends RefCounted

## Menu labels, artwork and placement live together. Normalized rectangles preserve the current layout.
const ITEMS := [
	{
		"name": "Lenguaje", "detail": "Letras y palabras",
		"icon": "res://assets/ui/menu/01_lenguaje.png",
		"rect": Rect2(0.17, 0.33, 0.115, 0.13),
	},
	{
		"name": "Matemática", "detail": "Las 4 operaciones",
		"icon": "res://assets/ui/menu/02_matematica.png",
		"rect": Rect2(0.31, 0.33, 0.115, 0.13),
	},
	{
		"name": "Números", "detail": "De 1 a 4 cifras",
		"icon": "res://assets/ui/menu/03_numeros.png",
		"rect": Rect2(0.45, 0.33, 0.115, 0.13),
	},
	{
		"name": "Geometría", "detail": "Figuras y lados",
		"icon": "res://assets/ui/menu/04_geometria.png",
		"rect": Rect2(0.59, 0.33, 0.115, 0.13),
	},
	{
		"name": "Cuentos", "detail": "Escucha y juega",
		"icon": "res://assets/ui/menu/05_cuentos.png",
		"rect": Rect2(0.73, 0.33, 0.115, 0.13),
	},
	{
		"name": "Diccionario", "detail": "Palabras y significados",
		"icon": "res://assets/ui/menu/06_diccionario.png",
		"rect": Rect2(0.2125, 0.48, 0.125, 0.1375),
	},
	{
		"name": "Enciclopedia", "detail": "Ciencia e historia",
		"icon": "res://assets/ui/menu/07_enciclopedia.png",
		"rect": Rect2(0.3625, 0.48, 0.125, 0.1375),
	},
	{
		"name": "Configuración", "detail": "Sonido, idioma y accesibilidad",
		"icon": "res://assets/ui/menu/08_configuracion.png",
		"rect": Rect2(0.5125, 0.48, 0.125, 0.1375),
	},
	{
		"name": "Salir", "detail": "",
		"icon": "res://assets/ui/menu/09_salir.png",
		"rect": Rect2(0.6625, 0.48, 0.125, 0.1375),
	},
]
