extends RefCounted

const SYMBOLS := {"addition": "+", "subtraction": "−", "multiplication": "×", "division": "÷"}

static func answer(operation: String, a: int, b: int) -> int:
	if a < 0 or b < 0:
		return -1
	match operation:
		"addition": return a + b
		"subtraction": return a - b if a >= b else -1
		"multiplication": return a * b
		"division": return a / b if b > 0 and a % b == 0 else -1
	return -1

static func expression(question: Dictionary, reveal: bool = false) -> String:
	return "%d %s %d = %s" % [int(question.a), SYMBOLS.get(question.operation, "?"), int(question.b), str(int(question.result)) if reveal else "?"]

static func action_target(question: Dictionary) -> int:
	var a := int(question.a)
	var b := int(question.b)
	match question.operation:
		"addition", "subtraction": return (2 if b % 10 > 0 else 1) if b >= 10 else maxi(1, b)
		"multiplication": return a
		"division": return a / b if b > 0 else 0
	return 1

static func visible_value(question: Dictionary, step: int) -> int:
	var a := int(question.a)
	var b := int(question.b)
	var target := action_target(question)
	step = clampi(step, 0, target)
	var part := mini(step, b)
	if b >= 10 and question.operation in ["addition", "subtraction"]:
		part = 0 if step == 0 else (b / 10 * 10 if step == 1 else b)
	match question.operation:
		"addition": return a + part
		"subtraction": return a - part
		"multiplication": return step * b
		"division": return step
	return 0

static func action_label(question: Dictionary) -> String:
	if int(question.b) == 0 and question.operation in ["addition", "subtraction"]: return "Comprobar el cero"
	match question.operation:
		"addition": return "Agregar un salto" if int(question.b) < 10 else "Sumar una parte"
		"subtraction": return "Quitar un salto" if int(question.b) < 10 else "Restar una parte"
		"multiplication": return "Añadir un grupo"
		"division": return "Repartir una ronda"
	return "Descubrir"

static func explanation(question: Dictionary) -> Array[String]:
	var a := int(question.a)
	var b := int(question.b)
	var value := answer(question.operation, a, b)
	var lines: Array[String] = []
	match question.operation:
		"addition":
			if b == 0:
				lines = ["Tienes %d." % a, "Agregar cero no cambia la cantidad.", "El total sigue siendo %d." % a]
			elif a < 10 and a + b > 10:
				var to_ten := 10 - a
				lines = ["Empieza en %d." % a, "De %d toma %d para llegar a 10." % [b, to_ten], "Faltan %d: 10 + %d = %d." % [b - to_ten, b - to_ten, value]]
			elif a >= 10 or b >= 10:
				var units := a % 10 + b % 10
				lines = ["Separa decenas y unidades.", "Agrega %d: %d + %d = %d." % [b / 10 * 10, a, b / 10 * 10, a + b / 10 * 10], "Unidades: %d + %d = %d." % [a % 10, b % 10, units]]
				if units >= 10:
					lines.append("Cambia 10 unidades por 1 decena. Resultado: %d." % value)
				else:
					lines.append("Junta las partes: %d." % value)
			else:
				lines = ["Tienes %d. Agregas %d." % [a, b], "Empieza en %d y avanza %d saltos." % [a, b], "Llegas a %d. Ese es el total." % value]
		"subtraction":
			if b == 0:
				lines = ["Tienes %d." % a, "Si no quitas nada, la cantidad no cambia.", "Siguen quedando %d." % a]
			elif a >= 20 and a % 10 < b % 10:
				var intermediate := a - b / 10 * 10
				lines = ["Primero quita %d: quedan %d." % [b / 10 * 10, intermediate], "Cambia 1 decena: %d decenas y %d unidades." % [intermediate / 10 - 1, intermediate % 10 + 10], "Unidades: %d − %d = %d." % [intermediate % 10 + 10, b % 10, intermediate % 10 + 10 - b % 10], "Quedan %d decenas y %d unidades: %d." % [value / 10, value % 10, value]]
			else:
				lines = ["Empieza con %d." % a, "Retrocede %d en la recta." % b, "Quedan %d. Comprueba: %d + %d = %d." % [value, value, b, a]]
		"multiplication":
			var groups: Array[String] = []
			for index in range(a):
				groups.append(str(b))
			lines = ["Hay %d grupos. Cada grupo tiene %d." % [a, b], "Suma el mismo número: " + " + ".join(groups) + ".", "%d × %d = %d en total." % [a, b, value]]
		"division":
			lines = ["Reparte %d entre %d cestas." % [a, b], "En cada ronda, todas reciben una.", "Después de %d rondas, cada cesta tiene %d." % [value, value], "Comprueba: %d × %d = %d. No sobra ninguna." % [b, value, a]]
	return lines

static func feedback(question: Dictionary, submitted: int) -> String:
	var a := int(question.a)
	var b := int(question.b)
	if question.operation == "addition" and submitted == a:
		return "Todavía falta agregar la segunda cantidad."
	if question.operation == "subtraction" and submitted == a + b:
		return "Aquí quitamos una parte. Prueba restar en vez de sumar."
	if question.operation == "multiplication" and submitted == a + b:
		return "Son grupos iguales: repite la cantidad de cada grupo."
	if question.operation == "division" and submitted == b:
		return "Ese es el número de cestas. Buscamos cuánto recibe cada una."
	return "Todavía no. Observa el modelo o pide una pista y prueba otra vez."

static func options(question: Dictionary, salt: int = 0) -> Array[int]:
	var value := int(question.result)
	var values: Array[int] = [value]
	for candidate in [value + 1, maxi(0, value - 1), value + maxi(2, int(question.b)), value + 2]:
		if candidate not in values:
			values.append(candidate)
		if values.size() == 4:
			break
	var offset := posmod(String(question.get("id", "")).hash() + salt, 4)
	var rotated: Array[int] = []
	for index in range(4):
		rotated.append(values[(index + offset) % 4])
	return rotated
