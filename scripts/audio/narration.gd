extends Node

## One owner for word/letter narration and TTS callbacks across screens.
signal finished(clip_id: String, completed: bool)

const CATALOG_PATH := "res://data/audio/voice_lines.json"
var clips: Dictionary = {}
var player: AudioStreamPlayer
var current_clip: String = ""
var utterance: int = 0
var spanish_voice: String = ""

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.finished.connect(_on_audio_finished)
	add_child(player)
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if data is Dictionary:
		clips = data.get("clips", {})
	for voice in DisplayServer.tts_get_voices():
		# Packaged clips work on every device. Only use a known male fallback;
		# choosing the first Spanish voice can change Conde to a female voice.
		var voice_id := String(voice.get("id", "")).to_lower()
		if String(voice.get("language", "")).to_lower().begins_with("es") and ("raul" in voice_id or "raúl" in voice_id):
			spanish_voice = String(voice.get("id", ""))
			break
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _on_tts_finished)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, _on_tts_canceled)

func speak(clip_id: String, fallback_text: String) -> bool:
	stop()
	var entry: Dictionary = clips.get(clip_id, {})
	var path := String(entry.get("path", ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		var stream := load(path) as AudioStream
		if stream != null:
			current_clip = clip_id
			player.stream = stream
			player.play()
			return true
	if spanish_voice.is_empty() or fallback_text.is_empty():
		return false
	current_clip = clip_id
	DisplayServer.tts_speak(fallback_text, spanish_voice, 100, 1.0, 0.92, utterance, true)
	return true

func stop() -> void:
	# Invalidate callbacks before stopping; cancellation may arrive later.
	utterance += 1
	var canceled := current_clip
	current_clip = ""
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	DisplayServer.tts_stop()
	if not canceled.is_empty():
		finished.emit(canceled, false)

func _on_audio_finished() -> void:
	if not player.playing:
		_complete(true)

func _on_tts_finished(id: int) -> void:
	if id == utterance:
		_complete(true)

func _on_tts_canceled(id: int) -> void:
	if id == utterance:
		_complete(false)

func _complete(completed: bool) -> void:
	var clip := current_clip
	current_clip = ""
	if not clip.is_empty():
		finished.emit(clip, completed)

func _exit_tree() -> void:
	stop()
