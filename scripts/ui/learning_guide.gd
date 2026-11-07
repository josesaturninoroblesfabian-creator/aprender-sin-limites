extends Node

const Voices = preload("res://scripts/audio/character_voices.gd")
const FaceShader = preload("res://scripts/ui/guide_face.gdshader")

var _player: AudioStreamPlayer
var _replay: Button
var _intro: AudioStream
var _female := false
var _using_tts := false
var _tts_poll_clock := 0.0
var _speech_start := 0
var _reading := ""
var _face: ShaderMaterial
var _pcm := PackedByteArray()
var _mix_rate := 0
var _mouth_level := 0.0
var _animation_clock := 0.0

func setup(female: bool, intro: AudioStream) -> void:
	_female = female
	_intro = intro
	_player = AudioStreamPlayer.new()
	_player.bus = "Voice"
	_player.pitch_scale = 1.0 if female else Voices.BOY_PITCH
	add_child(_player)

func animate_art(picture: TextureRect, mouth: Vector2, left_eye: Vector2, right_eye: Vector2) -> void:
	_face = ShaderMaterial.new()
	_face.shader = FaceShader
	_face.set_shader_parameter("mouth", mouth)
	_face.set_shader_parameter("left_eye", left_eye)
	_face.set_shader_parameter("right_eye", right_eye)
	_face.set_shader_parameter("rest_frame", load("res://assets/characters/guides/%s-rest.png" % ("girl" if _female else "boy")))
	_face.set_shader_parameter("blink_frame", load("res://assets/characters/guides/%s-blink.png" % ("girl" if _female else "boy")))
	picture.material = _face

func add_replay_to(container: Control) -> void:
	_replay = Button.new()
	_replay.custom_minimum_size.y = 48
	_replay.add_theme_font_size_override("font_size", 22)
	reset_reading()
	_replay.pressed.connect(_replay_current)
	container.add_child(_replay)

func play_intro() -> void:
	play_clip(_intro)

func reset_reading() -> void:
	_reading = ""
	if is_instance_valid(_replay):
		_replay.text = "Escuchar guía"

func _replay_current() -> void:
	if _reading.is_empty():
		play_intro()
	else:
		speak(_reading)

func play_clip(stream: AudioStream) -> void:
	if not is_inside_tree() or SoundSettings.tts_volume() == 0:
		return
	stop()
	_player.stream = stream
	var wav := stream as AudioStreamWAV
	if wav != null and wav.format == AudioStreamWAV.FORMAT_16_BITS and not wav.stereo:
		_pcm = wav.data
		_mix_rate = wav.mix_rate
	_player.play()

func speak(text: String, replayable := false) -> void:
	stop()
	Narration.ensure_voices()
	var voice: String = Narration.spanish_female_voice if _female else (Narration.spanish_voice if not Narration.spanish_voice.is_empty() else Narration.spanish_fallback_voice)
	if voice.is_empty():
		return
	if replayable:
		_reading = text
		if is_instance_valid(_replay):
			_replay.text = "Escuchar definición"
	if SoundSettings.tts_volume() == 0:
		return
	_using_tts = true
	_tts_poll_clock = 0.0
	_speech_start = Time.get_ticks_msec()
	var pitch := 1.0 if _female else Voices.BOY_TTS_PITCH
	SoundSettings.notify_tts_started()
	DisplayServer.tts_speak(text, voice, SoundSettings.tts_volume(), pitch, 0.94, 0, true)

func stop() -> void:
	if is_instance_valid(_player):
		_player.stop()
	_pcm.clear()
	_mix_rate = 0
	if _using_tts:
		_using_tts = false
		_tts_poll_clock = 0.0
		SoundSettings.notify_tts_stopped()
		DisplayServer.tts_stop()

func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	if _using_tts:
		_tts_poll_clock += delta
		if _tts_poll_clock >= 0.25 and Time.get_ticks_msec() - _speech_start > 300:
			_tts_poll_clock = 0.0
			if not DisplayServer.tts_is_speaking():
				_using_tts = false
				SoundSettings.notify_tts_stopped()
	var talking := _using_tts
	if _face == null:
		return
	_animation_clock += delta
	var target := 0.0
	if SoundSettings.tts_volume() > 0:
		if _player.playing and not _pcm.is_empty():
			target = _speech_level(_player.get_playback_position())
		elif talking or _player.playing:
			target = 0.35 + 0.3 * sin(_animation_clock * 20.0) * sin(_animation_clock * 8.0)
	_mouth_level = lerpf(_mouth_level, target, 1.0 - exp(-24.0 * delta))
	var blink_phase := fmod(_animation_clock + 1.8, 4.9)
	var blink := sin(PI * clampf(blink_phase / 0.19, 0.0, 1.0))
	_face.set_shader_parameter("speech", _mouth_level)
	_face.set_shader_parameter("blink", blink)
	_face.set_shader_parameter("expression", sin(_animation_clock * 7.0) * _mouth_level)

func _speech_level(position: float) -> float:
	var offset := int(position * _mix_rate) * 2
	var end := mini(offset + 640, _pcm.size() - 1)
	var energy := 0.0
	var samples := 0
	for sample in range(offset, end, 16):
		var amplitude := _pcm.decode_s16(sample) / 32768.0
		energy += amplitude * amplitude
		samples += 1
	return clampf(sqrt(energy / maxi(samples, 1)) * 7.0, 0.0, 1.0)

func _exit_tree() -> void:
	stop()
