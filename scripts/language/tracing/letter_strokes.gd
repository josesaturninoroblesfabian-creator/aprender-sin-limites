extends RefCounted

## Normalized paths (0..1). Keep data separate from drawing and screen layout.
static func for_letter(letter: String) -> Array:
	var shapes := {
		"A": [[Vector2(0.15, 0.88), Vector2(0.50, 0.12), Vector2(0.85, 0.88)], [Vector2(0.30, 0.58), Vector2(0.70, 0.58)]],
		"B": [[Vector2(0.25, 0.12), Vector2(0.25, 0.88)], [Vector2(0.25, 0.12), Vector2(0.58, 0.12), Vector2(0.78, 0.22), Vector2(0.80, 0.36), Vector2(0.70, 0.48), Vector2(0.25, 0.50)], [Vector2(0.25, 0.50), Vector2(0.64, 0.50), Vector2(0.80, 0.62), Vector2(0.79, 0.77), Vector2(0.63, 0.88), Vector2(0.25, 0.88)]],
		"C": [[Vector2(0.78, 0.20), Vector2(0.63, 0.12), Vector2(0.42, 0.14), Vector2(0.25, 0.30), Vector2(0.20, 0.50), Vector2(0.25, 0.72), Vector2(0.43, 0.86), Vector2(0.66, 0.87), Vector2(0.80, 0.78)]],
		"D": [[Vector2(0.28, 0.12), Vector2(0.28, 0.88)], [Vector2(0.28, 0.12), Vector2(0.52, 0.12), Vector2(0.73, 0.25), Vector2(0.82, 0.48), Vector2(0.77, 0.70), Vector2(0.59, 0.86), Vector2(0.28, 0.88)]],
		"E": [[Vector2(0.72, 0.12), Vector2(0.28, 0.12), Vector2(0.28, 0.88), Vector2(0.74, 0.88)], [Vector2(0.30, 0.50), Vector2(0.68, 0.50)]],
		"F": [[Vector2(0.28, 0.88), Vector2(0.28, 0.12), Vector2(0.75, 0.12)], [Vector2(0.30, 0.49), Vector2(0.67, 0.49)]],
		"G": [[Vector2(0.78, 0.22), Vector2(0.62, 0.12), Vector2(0.42, 0.15), Vector2(0.25, 0.31), Vector2(0.20, 0.52), Vector2(0.27, 0.73), Vector2(0.46, 0.87), Vector2(0.70, 0.84), Vector2(0.80, 0.70), Vector2(0.80, 0.55), Vector2(0.58, 0.55)]],
		"H": [[Vector2(0.25, 0.12), Vector2(0.25, 0.88)], [Vector2(0.75, 0.12), Vector2(0.75, 0.88)], [Vector2(0.26, 0.50), Vector2(0.74, 0.50)]],
		"I": [[Vector2(0.30, 0.12), Vector2(0.70, 0.12)], [Vector2(0.50, 0.12), Vector2(0.50, 0.88)], [Vector2(0.30, 0.88), Vector2(0.70, 0.88)]],
		"J": [[Vector2(0.32, 0.12), Vector2(0.75, 0.12)], [Vector2(0.68, 0.12), Vector2(0.68, 0.67), Vector2(0.60, 0.82), Vector2(0.43, 0.88), Vector2(0.28, 0.79), Vector2(0.25, 0.68)]],
		"K": [[Vector2(0.28, 0.12), Vector2(0.28, 0.88)], [Vector2(0.72, 0.12), Vector2(0.30, 0.52), Vector2(0.76, 0.88)]],
		"L": [[Vector2(0.30, 0.12), Vector2(0.30, 0.88), Vector2(0.75, 0.88)]],
		"M": [[Vector2(0.20, 0.88), Vector2(0.20, 0.12), Vector2(0.50, 0.52), Vector2(0.80, 0.12), Vector2(0.80, 0.88)]],
		"N": [[Vector2(0.24, 0.88), Vector2(0.24, 0.12), Vector2(0.76, 0.88), Vector2(0.76, 0.12)]],
		"Ñ": [[Vector2(0.24, 0.88), Vector2(0.24, 0.24), Vector2(0.76, 0.88), Vector2(0.76, 0.24)], [Vector2(0.34, 0.12), Vector2(0.50, 0.02), Vector2(0.67, 0.12)]],
		"O": [[Vector2(0.50, 0.12), Vector2(0.70, 0.17), Vector2(0.82, 0.34), Vector2(0.84, 0.53), Vector2(0.76, 0.73), Vector2(0.60, 0.86), Vector2(0.42, 0.86), Vector2(0.25, 0.73), Vector2(0.17, 0.53), Vector2(0.20, 0.34), Vector2(0.32, 0.17), Vector2(0.50, 0.12)]],
		# La panza vuelve al centro del asta; separarla evita que el punto final
		# se confunda con el mismo punto al pasar por el asta vertical.
		"P": [[Vector2(0.28, 0.88), Vector2(0.28, 0.12)], [Vector2(0.28, 0.12), Vector2(0.62, 0.12), Vector2(0.80, 0.24), Vector2(0.80, 0.40), Vector2(0.64, 0.51), Vector2(0.28, 0.51)]],
		"Q": [[Vector2(0.50, 0.12), Vector2(0.70, 0.17), Vector2(0.82, 0.34), Vector2(0.84, 0.53), Vector2(0.76, 0.73), Vector2(0.60, 0.86), Vector2(0.42, 0.86), Vector2(0.25, 0.73), Vector2(0.17, 0.53), Vector2(0.20, 0.34), Vector2(0.32, 0.17), Vector2(0.50, 0.12)], [Vector2(0.57, 0.65), Vector2(0.82, 0.90)]],
		# Igual que en la P, el asta y la curva son pasos separados para que
		# el final de la curva no coincida con un punto intermedio del asta.
		"R": [[Vector2(0.28, 0.88), Vector2(0.28, 0.12)], [Vector2(0.28, 0.12), Vector2(0.62, 0.12), Vector2(0.80, 0.24), Vector2(0.80, 0.40), Vector2(0.64, 0.51), Vector2(0.28, 0.51)], [Vector2(0.28, 0.51), Vector2(0.80, 0.88)]],
		"S": [[Vector2(0.78, 0.22), Vector2(0.62, 0.12), Vector2(0.40, 0.14), Vector2(0.25, 0.27), Vector2(0.28, 0.42), Vector2(0.47, 0.50), Vector2(0.67, 0.56), Vector2(0.80, 0.68), Vector2(0.75, 0.82), Vector2(0.58, 0.88), Vector2(0.36, 0.85), Vector2(0.22, 0.76)]],
		"T": [[Vector2(0.20, 0.12), Vector2(0.80, 0.12)], [Vector2(0.50, 0.12), Vector2(0.50, 0.88)]],
		"U": [[Vector2(0.24, 0.12), Vector2(0.24, 0.62), Vector2(0.30, 0.78), Vector2(0.44, 0.88), Vector2(0.60, 0.88), Vector2(0.75, 0.78), Vector2(0.80, 0.62), Vector2(0.80, 0.12)]],
		"V": [[Vector2(0.20, 0.12), Vector2(0.50, 0.88), Vector2(0.80, 0.12)]],
		"W": [[Vector2(0.15, 0.12), Vector2(0.30, 0.88), Vector2(0.50, 0.48), Vector2(0.70, 0.88), Vector2(0.85, 0.12)]],
		"X": [[Vector2(0.22, 0.12), Vector2(0.78, 0.88)], [Vector2(0.78, 0.12), Vector2(0.22, 0.88)]],
		"Y": [[Vector2(0.20, 0.12), Vector2(0.50, 0.50), Vector2(0.80, 0.12)], [Vector2(0.50, 0.50), Vector2(0.50, 0.88)]],
		"Z": [[Vector2(0.22, 0.12), Vector2(0.78, 0.12), Vector2(0.22, 0.88), Vector2(0.78, 0.88)]]
	}
	var raw_strokes: Array = shapes.get(letter, shapes["A"])
	var result: Array = []
	for raw_stroke in raw_strokes:
		var stroke := PackedVector2Array()
		for point in raw_stroke:
			stroke.append(point)
		result.append(stroke)
	return result

