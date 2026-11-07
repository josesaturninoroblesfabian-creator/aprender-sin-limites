extends Node

## One owner for word/letter narration and TTS callbacks across screens.
signal finished(clip_id: String, completed: bool)

const CATALOG_PATH := "res://data/audio/voice_lines.json"
const Q_TTS_PRONUNCIATION := "ku"
var clips: Dictionary = {}
var player: AudioStreamPlayer
var current_clip: String = ""
var utterance: int = 0
var spanish_voice: String = ""
var spanish_female_voice: String = ""
var spanish_fallback_voice: String = ""
var _voices_scanned := false
var _callbacks_registered := false

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.bus = "Voice"
	player.finished.connect(_on_audio_finished)
	add_child(player)
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if data is Dictionary:
		clips = data.get("clips", {})
	if not OS.has_feature("android"):
		ensure_voices()

func ensure_voices() -> void:
	if not _callbacks_registered:
		_callbacks_registered = true
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _on_tts_finished)
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, _on_tts_canceled)
	if _voices_scanned and not (spanish_voice.is_empty() and spanish_female_voice.is_empty() and spanish_fallback_voice.is_empty()):
		return
	var available_voices := DisplayServer.tts_get_voices()
	if available_voices.is_empty():
		return
	_voices_scanned = true
	var female_voice_score := -1
	for voice in available_voices:
		# Packaged clips work on every device. Only use a known male fallback;
		# choosing the first Spanish voice can change Conde to a female voice.
		var voice_id := String(voice.get("id", "")).to_lower()
		var voice_name := String(voice.get("name", "")).to_lower()
		var voice_language := String(voice.get("language", "")).to_lower()
		if not voice_language.begins_with("es"):
			continue
		if spanish_fallback_voice.is_empty():
			spanish_fallback_voice = String(voice.get("id", ""))
		if spanish_voice.is_empty() and ("raul" in voice_id or "raúl" in voice_id or "raul" in voice_name or "raúl" in voice_name):
			spanish_voice = String(voice.get("id", ""))
		# Godot no expone el género en todas las plataformas. Reconocemos nombres
		# femeninos conocidos y priorizamos una variante latinoamericana si existe.
		var voice_description := voice_id + " " + voice_name
		var gender := String(voice.get("gender", "")).to_lower()
		var female_hints := ["sabina", "helena", "paulina", "monica", "mónica", "lucia", "lucía", "laura", "sofia", "sofía", "elena", "female", "femen"]
		var is_female := "female" in gender or "femen" in gender
		for hint in female_hints:
			if hint in voice_description:
				is_female = true
				break
		if not is_female:
			continue
		var candidate_score := 10
		if "es-mx" in voice_language or "es_mx" in voice_language or "es-419" in voice_language or "es_419" in voice_language or "mexico" in voice_description or "latino" in voice_description:
			candidate_score += 100
		elif "es-us" in voice_language or "es_us" in voice_language:
			candidate_score += 40
		if candidate_score > female_voice_score:
			female_voice_score = candidate_score
			spanish_female_voice = String(voice.get("id", ""))

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
	ensure_voices()
	if spanish_voice.is_empty() or fallback_text.is_empty() or SoundSettings.tts_volume() == 0:
		return false
	current_clip = clip_id
	SoundSettings.notify_tts_started()
	DisplayServer.tts_speak(fallback_text, spanish_voice, SoundSettings.tts_volume(), 1.0, 0.92, utterance, true)
	return true

func speak_letter(clip_id: String, letter_name: String) -> bool:
	if SoundSettings.tts_volume() == 0:
		stop()
		return false
	ensure_voices()
	# La B se nombra "ve" en esta actividad. Fuerza TTS para no reproducir
	# el clip local defectuoso que la deletrea como "ebi".
	if clip_id == "letter_01":
		var b_voice := spanish_female_voice
		if b_voice.is_empty():
			b_voice = spanish_voice if not spanish_voice.is_empty() else spanish_fallback_voice
		if not b_voice.is_empty():
			stop()
			current_clip = clip_id
			SoundSettings.notify_tts_started()
			DisplayServer.tts_speak("ve", b_voice, SoundSettings.tts_volume(), 1.0, 0.88, utterance, true)
			return true
	var spoken_name := Q_TTS_PRONUNCIATION if clip_id == "letter_17" else letter_name
	# Para Q, evita el audio grabado que algunos motores interpretan como dos
	# letras y envía una guía fonética inequívoca al sintetizador español.
	if clip_id == "letter_17":
		var q_voice := spanish_female_voice if not spanish_female_voice.is_empty() else spanish_voice
		if not q_voice.is_empty():
			stop()
			current_clip = clip_id
			SoundSettings.notify_tts_started()
			DisplayServer.tts_speak(spoken_name, q_voice, SoundSettings.tts_volume(), 1.0, 0.88, utterance, true)
			return true
	# Si el sistema tiene una voz femenina española, úsala para los nombres de
	# letras. Sin una voz compatible, reproducimos el audio local ya incluido.
	if spanish_female_voice.is_empty():
		return speak(clip_id, spoken_name)
	stop()
	current_clip = clip_id
	SoundSettings.notify_tts_started()
	DisplayServer.tts_speak(spoken_name, spanish_female_voice, SoundSettings.tts_volume(), 1.0, 0.88, utterance, true)
	return true

func stop() -> void:
	# Invalidate callbacks before stopping; cancellation may arrive later.
	utterance += 1
	var canceled := current_clip
	current_clip = ""
	if is_instance_valid(player):
		player.stop()
		player.stream = null
	if SoundSettings._tts_active:
		SoundSettings.notify_tts_stopped()
		DisplayServer.tts_stop()
	if not canceled.is_empty():
		finished.emit(canceled, false)

func _on_audio_finished() -> void:
	if not player.playing:
		_complete(true)

func _on_tts_finished(id: int) -> void:
	SoundSettings.notify_tts_stopped()
	if id == utterance:
		_complete(true)

func _on_tts_canceled(id: int) -> void:
	SoundSettings.notify_tts_stopped()
	if id == utterance:
		_complete(false)

func _complete(completed: bool) -> void:
	var clip := current_clip
	current_clip = ""
	if not clip.is_empty():
		finished.emit(clip, completed)

func _exit_tree() -> void:
	stop()
