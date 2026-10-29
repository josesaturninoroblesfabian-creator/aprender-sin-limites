extends Node

signal changed
const Store = preload("res://scripts/storage/progress_store.gd")
const SETTINGS := "user://ajustes_numeros.cfg"
var player: AudioStreamPlayer
var effects: AudioStreamPlayer
var muted := false
var volume := 85.0
var current_id := ""
var tones: Dictionary = {}

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.finished.connect(func():
		current_id = ""
		changed.emit()
	)
	add_child(player)
	effects = AudioStreamPlayer.new()
	add_child(effects)
	reload_settings()
	for id in ["tap", "correct", "retry", "star", "finish", "jump"]:
		tones[id] = _tone(id)

func reload_settings() -> void:
	var config := Store.read(SETTINGS)
	muted = config.get_value("audio", "muted", false) == true
	volume = clampf(float(config.get_value("audio", "volume", 85.0)), 0, 100)
	if muted or volume <= 0:
		stop()

func speak(id: String) -> bool:
	stop()
	if muted or volume <= 0:
		return false
	var path := "res://assets/audio/llama/activities/" + id + ".mp3"
	if not ResourceLoader.exists(path):
		return false
	player.stream = load(path)
	player.volume_db = linear_to_db(volume / 100.0)
	current_id = id
	player.play()
	changed.emit()
	return true

func stop() -> void:
	current_id = ""
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	if is_instance_valid(effects):
		effects.stop()
	changed.emit()

func speaking() -> bool:
	return is_instance_valid(player) and player.playing

func effect(id: String) -> void:
	if muted or volume <= 0 or not tones.has(id):
		return
	effects.stream = tones[id]
	effects.volume_db = linear_to_db(volume / 100.0 * 0.42)
	effects.play()

func set_sound(enabled: bool, level: float) -> void:
	var config := Store.read(SETTINGS)
	config.set_value("audio", "muted", not enabled)
	config.set_value("audio", "volume", clampf(level, 0, 100))
	Store.write(config, SETTINGS)
	reload_settings()
	if is_instance_valid(player) and not muted and volume > 0:
		player.volume_db = linear_to_db(volume / 100.0)
	changed.emit()

func _tone(id: String) -> AudioStreamWAV:
	var frequencies: Array = {"tap": [440.0], "correct": [523.25, 659.25, 783.99], "retry": [330.0, 293.66], "star": [880.0, 1174.66], "finish": [523.25, 659.25, 783.99, 1046.5], "jump": [400.0, 650.0]}[id]
	var count := int(22050 * 0.12 * frequencies.size())
	var data := PackedByteArray()
	data.resize(count * 2)
	for sample in range(count):
		var t := float(sample) / 22050.0
		var note := mini(int(t / 0.12), frequencies.size() - 1)
		var phase := fmod(t, 0.12) / 0.12
		var value := sin(TAU * float(frequencies[note]) * t) * sin(PI * phase) * 0.55
		data.encode_s16(sample * 2, int(value * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	return stream

func _exit_tree() -> void:
	stop()
