extends RefCounted

const PLACES := ["unidades", "decenas", "centenas", "unidades de millar"]
const SHORT := ["U", "D", "C", "UM"]
const COLORS := [Color("#147cb2"), Color("#b87808"), Color("#25834c"), Color("#8344ad")]

static func digits(value: int, width: int) -> Array[int]:
	var result: Array[int] = []
	for place in range(width):
		result.append(value / int(pow(10, place)) % 10)
	return result

static func value(parts: Array) -> int:
	var total := 0
	for place in range(parts.size()): total += int(parts[place]) * int(pow(10, place))
	return total

static func canonical(parts: Array, width: int) -> bool:
	if parts.size() != width: return false
	for digit in parts:
		if not (digit is int or digit is float) or int(digit) != digit or digit < 0 or digit > 9: return false
	return true

static func decomposition(value_: int, width: int) -> String:
	var pieces: Array[String] = []
	var parts := digits(value_, width)
	for place in range(width - 1, -1, -1):
		pieces.append("%d %s" % [parts[place], PLACES[place]])
	return " · ".join(pieces)

static func numeric_parts(value_: int, width: int) -> String:
	var pieces: Array[String] = []
	for place in range(width - 1, -1, -1):
		var part := digits(value_, width)[place] * int(pow(10, place))
		if part > 0: pieces.append(str(part))
	return " + ".join(pieces) if not pieces.is_empty() else "0"

static func matches(question: Dictionary, answer: Variant) -> bool:
	if question.kind == "order":
		return answer is Array and answer == question.result
	return (answer is int or answer is float) and int(answer) == answer and int(answer) == int(question.result)

static func options(question: Dictionary) -> Array[int]:
	var result := int(question.result)
	var candidates: Array[int] = []
	var lower := 0 if int(question.width) == 1 or question.kind == "place" else int(pow(10, int(question.width) - 1))
	var upper := int(pow(10, int(question.width))) - 1
	if question.kind == "place":
		var digit := int(question.number) / int(pow(10, int(question.place))) % 10
		for multiplier in [1, 10, 100, 1000]: candidates.append(digit * multiplier)
		candidates.append(int(question.number))
	else:
		candidates.append(int(str(question.number).reverse()))
		for delta in [-10, 10, -1, 1, -100, 100]: candidates.append(result + delta)
	var wrong: Array[int] = []
	for n in candidates:
		if n >= lower and n <= upper and n != result and n not in wrong: wrong.append(n)
	var fallback := lower
	while wrong.size() < 3:
		if fallback != result and fallback not in wrong: wrong.append(fallback)
		fallback += 1
	var selected: Array[int] = [wrong[0], wrong[1], wrong[2]]
	selected.insert(posmod(String(question.id).hash(), 4), result)
	return selected

static func hint(question: Dictionary) -> String:
	match question.kind:
		"build", "compose", "read":
			return "%s.\nCada columna vale diez veces la de su derecha.\nUn cero conserva el lugar vacío." % decomposition(int(question.number), int(question.width))
		"place":
			var place := int(question.place)
			var digit := digits(int(question.number), int(question.width))[place]
			return "Mira la columna de %s.\nEl %d representa %d × %d = %d.\nLa cifra y su valor no siempre son iguales." % [PLACES[place], digit, digit, int(pow(10, place)), int(question.result)]
		"neighbor":
			return "Empieza en %d y da un paso %s.\n%s uno cambia el número en una unidad." % [int(question.number), "hacia delante" if int(question.offset) > 0 else "hacia atrás", "Agregar" if int(question.offset) > 0 else "Quitar"]
		"order":
			return "Busca primero el menor. Compara desde la columna izquierda.\nSi las cifras coinciden, mira la siguiente.\nNo ordenes solo por la última cifra."
	return "Observa cada posición del número."

static func sequence_hint(question: Dictionary) -> String:
	var step := int(question.step)
	return "Cada salto %s %d.\nLa misma regla une todas las piedras, también donde está el hueco." % ["suma" if step > 0 else "quita", absi(step)]

static func comparison_hint(question: Dictionary) -> String:
	var left := int(question.left)
	var right := int(question.right)
	if left == right: return "Todas sus columnas coinciden. Los números representan la misma cantidad: %d = %d." % [left, right]
	var width := int(question.width)
	var a := digits(left, width)
	var b := digits(right, width)
	for place in range(width - 1, -1, -1):
		if a[place] != b[place]:
			return "La primera diferencia está en %s: %d y %d.\nCompara esta columna antes de mirar las de su derecha.\nLa boca abierta del signo mira al mayor." % [PLACES[place], a[place], b[place]]
	return "Compara de izquierda a derecha."
