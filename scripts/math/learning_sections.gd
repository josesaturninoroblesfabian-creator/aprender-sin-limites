extends RefCounted

const Numbers = preload("res://scripts/math/numbers_catalog.gd")
const Mathematics = preload("res://scripts/math/mathematics_catalog.gd")
const Geometry = preload("res://scripts/math/geometry_catalog.gd")

static func get_section(id: String) -> Dictionary:
	match id:
		"mathematics":
			return {"title": "Matemáticas", "greeting": "¡Hola! ¡Aprendamos matemáticas!", "background": "res://assets/ui/math/mathematics-menu-background.png", "voice_catalog": "res://data/math/mathematics_voice_lines.json", "voice_folder": "res://assets/audio/llama/mathematics/", "progress_path": "user://progreso_matematicas.cfg", "total": 16, "per_topic": 4, "topics": Mathematics.TOPICS}
		"geometry":
			return {"title": "Geometría", "greeting": "¡Hola! ¡Juguemos con las formas!", "background": "res://assets/ui/math/geometry-menu-background.png", "voice_catalog": "res://data/math/geometry_voice_lines.json", "voice_folder": "res://assets/audio/llama/geometry/", "progress_path": "user://progreso_geometria.cfg", "total": 20, "per_topic": 5, "topics": Geometry.TOPICS}
		_:
			return {"title": "Números", "greeting": "¡Hola! ¡Juguemos con los números!", "background": "res://assets/ui/math/numbers-menu-background.png", "voice_catalog": "res://data/math/numbers_voice_lines.json", "voice_folder": "res://assets/audio/llama/numbers/", "progress_path": "user://progreso_numeros.cfg", "total": 20, "per_topic": 5, "topics": Numbers.TOPICS}

static func find_topic(section: Dictionary, id: String) -> Dictionary:
	for topic in section.topics:
		if topic.id == id:
			return topic
	return {}
