extends "res://scripts/math/math_audio.gd"

func stop() -> void:
	super.stop()
	if is_instance_valid(effects): effects.stream = null

func speak(id: String) -> bool:
	id = id.get_file().get_basename() if id.begins_with("res://") else id
	current_id = ""
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	changed.emit()
	if muted or volume <= 0: return false
	var path := "res://assets/audio/llama/geometry_activities/" + id + ".mp3"
	if not ResourceLoader.exists(path): return false
	player.stream = load(path)
	player.volume_db = linear_to_db(volume / 100.0)
	current_id = id
	player.play()
	changed.emit()
	return true
