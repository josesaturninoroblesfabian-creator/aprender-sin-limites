extends RefCounted

const PATH := "res://data/math/operation_tables.json"
const OPERATIONS := ["addition", "subtraction", "multiplication", "division"]
const SIGNS := {"addition": "+", "subtraction": "−", "multiplication": "×", "division": "÷"}
static var catalog: Dictionary = {}

static func table(operation: String, number: int) -> Array[Dictionary]:
	if operation not in OPERATIONS or number < 1 or number > 15: return []
	if catalog.is_empty():
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		for item in data.tables:
			var rows: Array[Dictionary] = []
			for row in item.rows:
				for field in ["a", "b", "result", "step"]: row[field] = int(row[field])
				rows.append(row)
			catalog[String(item.operation) + str(int(item.number))] = rows
	return catalog[operation + str(number)]

static func expression(operation: String, row: Dictionary) -> String:
	return "%d %s %d = %d" % [row.a, SIGNS[operation], row.b, row.result]

static func idea(operation: String, number: int) -> String:
	match operation:
		"addition": return "Empezamos con %d y añadimos otra cantidad. El total crece de uno en uno." % number
		"subtraction": return "Quitamos siempre %d. Mira cuánto había y cuántos quedan. Es la operación inversa de sumar." % number
		"multiplication": return "Cada grupo tiene %d. Al añadir otro grupo, el total aumenta en %d." % [number, number]
		"division": return "Repartimos entre %d por igual. Los totales son múltiplos de %d: no sobra ninguno." % [number, number]
	return ""
