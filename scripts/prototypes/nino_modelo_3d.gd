extends Node3D

var character: Node3D
var animation_player: AnimationPlayer
var audio_player: AudioStreamPlayer
var walking := false
var elapsed := 0.0
var walk_button: Button
var status_label: Label
var walk_animation_name := ""
var talk_animation_name := ""

func _ready() -> void:
	_build_world()
	_load_character()
	_build_controls()
	_build_audio()

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#a8dcf4")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#fff1d7")
	environment.ambient_light_energy = 0.8
	world.environment = environment
	add_child(world)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38, -25, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.15, 4.2)
	camera.look_at(Vector3(0, 0.95, 0))
	camera.current = true
	add_child(camera)

	var ground := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(30, 30)
	ground.mesh = floor_mesh
	ground.position.y = -0.03
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("#86b96b")
	ground.material_override = floor_material
	add_child(ground)

func _load_character() -> void:
	var packed_character := load("res://assets/models/nino-andino-animado.glb") as PackedScene
	if packed_character == null:
		push_error("No se pudo importar el personaje 3D.")
		return
	character = packed_character.instantiate() as Node3D
	character.name = "NinoAndinoAnimado"
	character.position.y = 0.95
	add_child(character)
	animation_player = _find_animation_player(character)
	if animation_player != null:
		for animation_name in animation_player.get_animation_list():
			var animation := animation_player.get_animation(animation_name)
			if animation_name.to_lower().contains("caminar"):
				walk_animation_name = animation_name
				animation.loop_mode = Animation.LOOP_LINEAR
			elif animation_name.to_lower().contains("hablar"):
				talk_animation_name = animation_name
				animation.loop_mode = Animation.LOOP_LINEAR
	else:
		push_warning("No se encontró el reproductor de animaciones del modelo.")

func _find_animation_player(parent: Node) -> AnimationPlayer:
	for child in parent.get_children():
		if child is AnimationPlayer:
			return child
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _build_audio() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = load("res://assets/audio/audio-nino.mp3")
	audio_player.finished.connect(_on_audio_finished)
	add_child(audio_player)

func _build_controls() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	var title := Label.new()
	title.text = "EL NIÑO ANDINO 3D"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 20
	title.offset_bottom = 70
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#064c83"))
	ui.add_child(title)

	status_label = Label.new()
	status_label.text = "Prueba sus movimientos y su voz"
	status_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	status_label.offset_top = -135
	status_label.offset_bottom = -102
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color("#17455f"))
	ui.add_child(status_label)

	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.anchor_left = 0.08
	bar.anchor_right = 0.92
	bar.offset_top = -92
	bar.offset_bottom = -18
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 12)
	ui.add_child(bar)

	var talk_button := _make_button("Hablar")
	talk_button.pressed.connect(_on_talk_pressed)
	bar.add_child(talk_button)
	walk_button = _make_button("Caminar")
	walk_button.pressed.connect(_on_walk_pressed)
	bar.add_child(walk_button)
	var back := _make_button("Volver al menú")
	back.pressed.connect(_on_back_pressed)
	bar.add_child(back)

func _make_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(210, 62)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0878b5")
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color.WHITE
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style.duplicate())
	button.add_theme_stylebox_override("pressed", style.duplicate())
	return button

func _on_walk_pressed() -> void:
	walking = not walking
	walk_button.text = "Detener caminata" if walking else "Caminar"
	if walking:
		audio_player.stop()
		_set_face_expression()
		if animation_player != null and walk_animation_name != "":
			animation_player.play(walk_animation_name)
		status_label.text = "¡El niño está caminando!"
	else:
		if animation_player != null:
			animation_player.stop()
		_set_face_expression()
		status_label.text = "Listo para otra aventura"

func _on_talk_pressed() -> void:
	walking = false
	walk_button.text = "Caminar"
	if animation_player != null and talk_animation_name != "":
		animation_player.play(talk_animation_name)
	audio_player.stop()
	audio_player.play()
	status_label.text = "El niño está hablando"

func _on_audio_finished() -> void:
	if not walking and animation_player != null:
		animation_player.stop()
		_set_face_expression()
	status_label.text = "Prueba sus movimientos y su voz"

func _set_face_expression() -> void:
	if character == null:
		return
	for node in character.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if part == null or part.mesh == null:
			continue
		var mouth_index: int = part.mesh.find_blend_shape_by_name("Boca_Cerrada")
		var eyes_index: int = part.mesh.find_blend_shape_by_name("Ojos_Cerrados")
		if mouth_index >= 0:
			part.set_blend_shape_value(mouth_index, 1.0)
		if eyes_index >= 0:
			part.set_blend_shape_value(eyes_index, 0.0)

func _on_back_pressed() -> void:
	audio_player.stop()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _process(delta: float) -> void:
	elapsed += delta
	if walking and character != null:
		character.position.x = sin(elapsed * 0.9) * 0.38
