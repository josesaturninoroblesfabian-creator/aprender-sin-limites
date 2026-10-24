extends Node

signal ended(path: String, completed: bool)
signal settings_changed
const ProgressStore = preload("res://scripts/storage/progress_store.gd")
const SETTINGS := "user://ajustes_cuentos.cfg"
var player: AudioStreamPlayer
var owner_id := 0
var current_path := ""
var muted := false
var volume := 85.0

func _ready() -> void:
	var config := ProgressStore.read(SETTINGS)
	muted = config.get_value("audio", "muted", false) == true
	var stored: Variant = config.get_value("audio", "volume", 85.0)
	if stored is float or stored is int:
		volume = clampf(float(stored), 0, 100)
	player = AudioStreamPlayer.new()
	player.finished.connect(_finished)
	add_child(player)

func play(path: String, source: Node) -> bool:
	stop()
	if muted or volume <= 0 or not ResourceLoader.exists(path):
		return false
	var audio := load(path) as AudioStream
	if audio == null:
		return false
	owner_id = source.get_instance_id()
	current_path = path
	player.stream = audio
	player.volume_db = linear_to_db(volume / 100.0)
	player.stream_paused = false
	player.play()
	return true

func guide(id: String, source: Node) -> bool:
	return play("res://assets/audio/stories/guide/" + id + ".mp3", source)

func stop(source: Node = null) -> void:
	if source != null and owner_id != source.get_instance_id():
		return
	var previous := current_path
	current_path = ""
	owner_id = 0
	if is_instance_valid(player):
		player.stop()
		player.stream_paused = false
		player.stream = null
	if not previous.is_empty():
		ended.emit(previous, false)

func pause_or_resume(source: Node) -> void:
	if owns(source) and not current_path.is_empty():
		player.stream_paused = not player.stream_paused

func owns(source: Node) -> bool:
	return owner_id == source.get_instance_id()

func speaking() -> bool:
	return is_instance_valid(player) and player.playing and not player.stream_paused and not muted and volume > 0

func _finished() -> void:
	var previous := current_path
	current_path = ""
	owner_id = 0
	player.stream = null
	if not previous.is_empty():
		ended.emit(previous, true)

func set_sound(enabled: bool, level: float) -> void:
	muted = not enabled
	volume = clampf(level, 0, 100)
	if muted or volume <= 0:
		stop()
	else:
		player.volume_db = linear_to_db(volume / 100.0)
	var config := ProgressStore.read(SETTINGS)
	config.set_value("audio", "muted", muted)
	config.set_value("audio", "volume", volume)
	ProgressStore.write(config, SETTINGS)
	settings_changed.emit()

func _exit_tree() -> void:
	stop()
