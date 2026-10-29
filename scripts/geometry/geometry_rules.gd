extends RefCounted

const Shapes = preload("res://scripts/geometry/geometry_shapes.gd")

static func token_matches(token: String, expected: String, match_color: bool) -> bool:
	return token == expected if match_color else Shapes.token_shape(token) == Shapes.token_shape(expected)

static func matches(question: Dictionary, answer: Variant) -> bool:
	var expected: Variant = question.result
	if question.kind == "sky_pattern":
		return answer is String and (answer == expected if question.color_matters else Shapes.token_shape(answer) == expected)
	if expected is Array: return answer is Array and answer == expected
	if expected is String: return answer is String and answer == expected
	return (answer is int or answer is float) and int(answer) == answer and int(answer) == int(expected)

static func options(q: Dictionary) -> Array:
	if q.kind == "count":
		var correct := int(q.result)
		var choices: Array = [correct]
		for other in [3, 4, 5, 6, 0, 2, 7, 8]:
			if other not in choices and choices.size() < 4: choices.append(other)
		var offset := posmod(String(q.id).hash(), 4)
		for i in range(offset): choices.push_back(choices.pop_front())
		return choices
	return q.get("options", []).duplicate()

static func hint(q: Dictionary) -> String:
	match q.kind:
		"plane":
			var n: int = Shapes.SIDES[q.shape]
			return "El círculo tiene un borde curvo, sin lados rectos ni esquinas." if q.shape == "circle" else ("Busca %d lados rectos. Girar una figura no cambia sus lados ni sus esquinas." % n) + (" El cuadrado tiene cuatro lados iguales; el rectángulo alargado tiene dos largos y dos cortos." if q.shape in ["square", "rectangle"] else "")
		"solid": return String(q.fact) + "\nGira para mirar sus superficies. Una imagen plana representa un cuerpo que ocupa espacio."
		"count": return "Toca el borde curvo: no es un lado recto. Por eso la respuesta es cero." if q.shape == "circle" else "Un lado recto une dos vértices. Un vértice es una esquina. Toca cada parte una vez y observa la marca que deja."
		"pattern", "sky_pattern": return String(q.rule) + "\nRepite el grupo completo, también donde hay un hueco."
		"find": return "Busca la silueta del " + String(Shapes.NAMES[q.target]).to_lower() + ". No importa su color, tamaño ni hacia dónde apunte."
	return "Observa la forma y vuelve a intentar."
