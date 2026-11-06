extends Node

const Store = preload("res://scripts/storage/progress_store.gd")
const AndeanMusic = preload("res://scripts/audio/andean_music.gd")
const SETTINGS := "user://ajustes_sonido.cfg"
const LABELS := {"Master": "Volumen general", "Voice": "Voces y narración", "Music": "Música de fondo", "Effects": "Efectos de sonido"}
const DEFAULTS := {"Master": 100, "Voice": 100, "Music": 25, "Effects": 80}
const TRACKS := ["Camino de la sierra", "Amanecer andino"]

var levels := DEFAULTS.duplicate()
var silenced := false
var track := 0
var _background: AudioStreamPlayer
var _preview: AudioStreamPlayer
var _streams: Dictionary = {}
var _duck := 0.0
var _dialog: AcceptDialog

func _ready() -> void:
	for bus in ["Voice", "Music", "Effects"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	get_tree().node_added.connect(_register_player)
	var config := Store.read(SETTINGS)
	for bus in DEFAULTS:
		var value: Variant = config.get_value("audio", bus, DEFAULTS[bus])
		if value is float or value is int:
			levels[bus] = clampi(int(value), 0, 100)
	silenced = config.get_value("audio", "silenced", false) == true
	var saved_track: Variant = config.get_value("audio", "track", 0)
	if saved_track is int:
		track = clampi(saved_track, 0, TRACKS.size() - 1)
	_background = AudioStreamPlayer.new()
	_background.bus = "Music"
	_background.volume_db = -9.0
	add_child(_background)
	_preview = AudioStreamPlayer.new()
	_preview.bus = "Voice"
	add_child(_preview)
	_apply_levels()

func _register_player(node: Node) -> void:
	if node == _background:
		return
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		if node.bus == &"Voice":
			node.add_to_group("voice_players")
		elif node.bus == &"Music":
			node.add_to_group("local_music_players")

func start_background() -> void:
	if not _background.playing:
		_play_track()

func _play_track() -> void:
	if not _streams.has(track):
		_streams[track] = AndeanMusic.make_track(track)
	_background.stream = _streams[track]
	_background.play()

func _has_audio(group: StringName) -> bool:
	for player in get_tree().get_nodes_in_group(group):
		if player.playing and not player.stream_paused:
			return true
	return false

func _process(delta: float) -> void:
	var speaking := tts_volume() > 0 and (DisplayServer.tts_is_speaking() or _has_audio(&"voice_players"))
	_duck = move_toward(_duck, -15.0 if speaking else 0.0, delta * (110.0 if speaking else 30.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), _level_db("Music") + _duck)
	_background.stream_paused = _has_audio(&"local_music_players") or _has_audio(&"recording_players")

func _level_db(bus: String) -> float:
	return linear_to_db(maxf(float(levels[bus]) / 100.0, 0.0001))

func tts_volume() -> int:
	return 0 if silenced else roundi(levels["Master"] * levels["Voice"] / 100.0)

func _apply_levels() -> void:
	for bus in DEFAULTS:
		var index := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_volume_db(index, _level_db(bus) + (_duck if bus == "Music" else 0.0))
		AudioServer.set_bus_mute(index, levels[bus] == 0 or (bus == "Master" and silenced))
	if tts_volume() == 0 and DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()

func open_dialog(parent: Node) -> void:
	if is_instance_valid(_dialog):
		return
	var dialog := AcceptDialog.new()
	dialog.hide()
	_dialog = dialog
	dialog.title = "Configuración de sonido"
	dialog.ok_button_text = "Guardar y cerrar"
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 470
	column.add_theme_constant_override("separation", 12)
	dialog.add_child(column)
	var mute := CheckButton.new()
	mute.text = "Silenciar todo"
	mute.button_pressed = silenced
	mute.toggled.connect(func(enabled: bool):
		silenced = enabled
		_apply_levels()
	)
	column.add_child(mute)
	var sliders: Dictionary = {}
	for bus: String in DEFAULTS:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.custom_minimum_size.x = 155
		label.text = LABELS[bus]
		row.add_child(label)
		var slider := HSlider.new()
		slider.custom_minimum_size.y = 32
		slider.max_value = 100
		slider.step = 1
		slider.value = levels[bus]
		slider.tooltip_text = LABELS[bus]
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slider)
		var percent := Label.new()
		percent.custom_minimum_size.x = 50
		percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		percent.text = "%d %%" % levels[bus]
		row.add_child(percent)
		slider.value_changed.connect(func(value: float):
			levels[bus] = int(value)
			percent.text = "%d %%" % value
			_apply_levels()
		)
		sliders[bus] = slider
		column.add_child(row)
	var track_label := Label.new()
	track_label.text = "Pista de fondo"
	column.add_child(track_label)
	var selector := OptionButton.new()
	for title in TRACKS:
		selector.add_item(title)
	selector.select(track)
	selector.item_selected.connect(_select_track)
	column.add_child(selector)
	var hint := Label.new()
	hint.text = "La música baja automáticamente cuando alguien habla."
	column.add_child(hint)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	var preview := Button.new()
	preview.text = "Probar voz"
	preview.pressed.connect(func():
		_preview.stream = preload("res://assets/audio/bienvenida-nina.mp3")
		_preview.play()
	)
	actions.add_child(preview)
	var reset := Button.new()
	reset.text = "Restablecer valores"
	reset.pressed.connect(func():
		mute.button_pressed = false
		for bus in DEFAULTS:
			sliders[bus].value = DEFAULTS[bus]
		selector.select(0)
		_select_track(0)
	)
	actions.add_child(reset)
	dialog.visibility_changed.connect(func():
		if not dialog.visible and dialog.is_inside_tree():
			_preview.stop()
			_save()
			dialog.queue_free()
	)
	parent.add_child(dialog)
	dialog.popup_centered()

func _select_track(index: int) -> void:
	if track != index:
		track = index
		_play_track()

func _save() -> void:
	var config := ConfigFile.new()
	for bus in DEFAULTS:
		config.set_value("audio", bus, levels[bus])
	config.set_value("audio", "silenced", silenced)
	config.set_value("audio", "track", track)
	if Store.write(config, SETTINGS) != OK:
		push_warning("No se pudieron guardar los ajustes de sonido.")

func _exit_tree() -> void:
	_background.stop()
	_preview.stop()
