extends Node3D

var avatar: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var mouth_closed: MeshInstance3D
var mouth_open: MeshInstance3D
var mouth_tongue: MeshInstance3D
var audio_player: AudioStreamPlayer
var walk_button: Button
var walking: bool = false
var mouth_is_open: bool = false
var elapsed: float = 0.0
var mouth_timer: float = 0.0

func _ready() -> void:
	_build_world()
	_build_girl()
	_build_audio()
	_build_controls()

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
	camera.position = Vector3(0, 2.12, 6.0)
	camera.fov = 42.0
	camera.look_at(Vector3(0, 1.85, 0))
	camera.current = true
	add_child(camera)

	var ground := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(30, 30)
	ground.mesh = floor_mesh
	ground.position = Vector3(0, -0.06, 0)
	ground.material_override = _material(Color("#86b96b"))
	add_child(ground)

	# Colinas sencillas para dar profundidad a la pequeña escena 3D.
	_add_sphere(self, "ColinaIzquierda", Vector3(-4.4, 0.85, -3.8), Vector3(3.8, 1.5, 0.5), Color("#65a76e"))
	_add_sphere(self, "ColinaDerecha", Vector3(4.3, 0.75, -3.5), Vector3(3.5, 1.3, 0.5), Color("#74b57b"))

func _build_girl() -> void:
	avatar = Node3D.new()
	avatar.name = "Nina3D"
	add_child(avatar)

	# Falda y bandas textiles.
	_add_cylinder(avatar, "Falda", Vector3(0, 0.82, 0), 0.42, 0.78, 0.92, Color("#25252c"))
	_add_cylinder(avatar, "BandaFalda", Vector3(0, 0.48, 0), 0.76, 0.78, 0.12, Color("#ed3857"))
	_add_cylinder(avatar, "BandaAmarilla", Vector3(0, 0.43, 0), 0.78, 0.80, 0.055, Color("#ffd449"))
	_add_cylinder(avatar, "Cuerpo", Vector3(0, 1.58, 0), 0.48, 0.52, 0.82, Color("#ed3659"))
	_add_cylinder(avatar, "Cinturon", Vector3(0, 1.22, 0), 0.53, 0.53, 0.12, Color("#ffd64b"))
	_add_sphere(avatar, "Blusa", Vector3(0, 1.78, 0.43), Vector3(0.19, 0.34, 0.08), Color("#fff1d9"))

	# Brazos articulados para la caminata.
	left_arm = _make_limb(avatar, "BrazoIzquierdo", Vector3(-0.49, 1.78, 0), Color("#ed3659"), true)
	right_arm = _make_limb(avatar, "BrazoDerecho", Vector3(0.49, 1.78, 0), Color("#ed3659"), true)
	_add_sphere(left_arm, "Mano", Vector3(0, -0.63, 0.02), Vector3(0.15, 0.18, 0.14), Color("#db895d"))
	_add_sphere(right_arm, "Mano", Vector3(0, -0.63, 0.02), Vector3(0.15, 0.18, 0.14), Color("#db895d"))

	left_leg = _make_limb(avatar, "PiernaIzquierda", Vector3(-0.25, 0.35, 0), Color("#d99563"), false)
	right_leg = _make_limb(avatar, "PiernaDerecha", Vector3(0.25, 0.35, 0), Color("#d99563"), false)
	_add_sphere(left_leg, "Zapato", Vector3(0, -0.48, 0.13), Vector3(0.24, 0.13, 0.34), Color("#63372d"))
	_add_sphere(right_leg, "Zapato", Vector3(0, -0.48, 0.13), Vector3(0.24, 0.13, 0.34), Color("#63372d"))

	# Trenzas, cabeza, ojos y sombrero andino.
	_add_capsule(avatar, "TrenzaIzquierda", Vector3(-0.58, 2.05, -0.02), Vector3(0.13, 0.48, 0.13), Color("#2c1b1a"))
	_add_capsule(avatar, "TrenzaDerecha", Vector3(0.58, 2.05, -0.02), Vector3(0.13, 0.48, 0.13), Color("#2c1b1a"))
	_add_sphere(avatar, "Cabeza", Vector3(0, 2.55, 0), Vector3(0.73, 0.78, 0.68), Color("#eaa16d"))
	_add_sphere(avatar, "Cabello", Vector3(0, 2.92, -0.23), Vector3(0.73, 0.40, 0.50), Color("#2b1d1c"))
	_add_sphere(avatar, "Flequillo", Vector3(0, 2.79, 0.48), Vector3(0.50, 0.22, 0.20), Color("#2b1d1c"))
	_add_sphere(avatar, "OjoIzquierdo", Vector3(-0.27, 2.56, 0.58), Vector3(0.19, 0.23, 0.10), Color.WHITE)
	_add_sphere(avatar, "OjoDerecho", Vector3(0.27, 2.56, 0.58), Vector3(0.19, 0.23, 0.10), Color.WHITE)
	_add_sphere(avatar, "IrisIzquierdo", Vector3(-0.25, 2.55, 0.67), Vector3(0.095, 0.13, 0.06), Color("#593729"))
	_add_sphere(avatar, "IrisDerecho", Vector3(0.29, 2.55, 0.67), Vector3(0.095, 0.13, 0.06), Color("#593729"))
	_add_sphere(avatar, "BrilloIzquierdo", Vector3(-0.28, 2.61, 0.72), Vector3(0.035, 0.045, 0.025), Color.WHITE)
	_add_sphere(avatar, "BrilloDerecho", Vector3(0.26, 2.61, 0.72), Vector3(0.035, 0.045, 0.025), Color.WHITE)
	_add_sphere(avatar, "Nariz", Vector3(0, 2.39, 0.67), Vector3(0.11, 0.08, 0.10), Color("#e58e65"))
	mouth_closed = _add_sphere(avatar, "BocaCerrada", Vector3(0, 2.22, 0.66), Vector3(0.17, 0.035, 0.045), Color("#8f3741"))
	mouth_open = _add_sphere(avatar, "BocaAbierta", Vector3(0, 2.22, 0.66), Vector3(0.16, 0.13, 0.055), Color("#702632"))
	mouth_tongue = _add_sphere(avatar, "Lengua", Vector3(0, 2.17, 0.70), Vector3(0.085, 0.035, 0.02), Color("#f16e79"))
	mouth_open.visible = false
	mouth_tongue.visible = false
	_add_cylinder(avatar, "AlaSombrero", Vector3(0, 3.25, 0), 0.90, 0.90, 0.12, Color("#dca84d"))
	_add_cylinder(avatar, "CopaSombrero", Vector3(0, 3.48, 0), 0.57, 0.62, 0.42, Color("#e4b55e"))
	_add_cylinder(avatar, "CintaSombrero", Vector3(0, 3.40, 0), 0.63, 0.64, 0.10, Color("#de3d54"))
	_add_cylinder(avatar, "CintaAzul", Vector3(0, 3.41, 0), 0.65, 0.66, 0.035, Color("#287faf"))

func _make_limb(parent: Node3D, node_name: String, origin: Vector3, color: Color, arm: bool) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = origin
	parent.add_child(pivot)
	var length := 0.70 if arm else 0.58
	_add_capsule(pivot, "Manga" if arm else "Pierna", Vector3(0, -length * 0.40, 0), Vector3(0.18 if arm else 0.16, length * 0.55, 0.18 if arm else 0.16), color)
	return pivot

func _build_audio() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = load("res://assets/audio/saludo-nina.mp3")
	audio_player.finished.connect(_on_audio_finished)
	add_child(audio_player)

func _build_controls() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var title := Label.new()
	title.text = "PRUEBA 3D: LA NIÑA ANDINA"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 24
	title.offset_bottom = 76
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#064c83"))
	ui.add_child(title)

	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.anchor_left = 0.12
	bar.anchor_right = 0.88
	bar.offset_top = -92
	bar.offset_bottom = -18
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 18)
	ui.add_child(bar)

	var greet := _make_button("▶  Escuchar saludo")
	greet.pressed.connect(_on_greet_pressed)
	bar.add_child(greet)
	walk_button = _make_button("Caminar")
	walk_button.pressed.connect(_on_walk_pressed)
	bar.add_child(walk_button)
	var back := _make_button("Volver al menú")
	back.pressed.connect(_on_back_pressed)
	bar.add_child(back)

	var instructions := Label.new()
	instructions.text = "Prueba los movimientos y el audio sin conexión"
	instructions.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	instructions.offset_top = -137
	instructions.offset_bottom = -105
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 17)
	instructions.add_theme_color_override("font_color", Color("#17455f"))
	ui.add_child(instructions)

func _make_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(230, 62)
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

func _on_greet_pressed() -> void:
	audio_player.stop()
	_set_mouth(false)
	audio_player.play()

func _on_walk_pressed() -> void:
	walking = not walking
	walk_button.text = "Detener caminata" if walking else "Caminar"

func _on_back_pressed() -> void:
	audio_player.stop()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_audio_finished() -> void:
	_set_mouth(false)

func _set_mouth(open: bool) -> void:
	mouth_is_open = open
	mouth_closed.visible = not open
	mouth_open.visible = open
	mouth_tongue.visible = open

func _process(delta: float) -> void:
	elapsed += delta
	if walking:
		avatar.position.x = sin(elapsed * 1.4) * 0.55
		avatar.position.y = abs(sin(elapsed * 2.8)) * 0.06
		left_arm.rotation.z = sin(elapsed * 5.6) * 0.55
		right_arm.rotation.z = -sin(elapsed * 5.6) * 0.55
		left_leg.rotation.z = -sin(elapsed * 5.6) * 0.42
		right_leg.rotation.z = sin(elapsed * 5.6) * 0.42
	else:
		avatar.position.x = move_toward(avatar.position.x, 0.0, delta * 0.8)
		avatar.position.y = sin(elapsed * 1.8) * 0.025
		left_arm.rotation.z = move_toward(left_arm.rotation.z, 0.0, delta * 1.8)
		right_arm.rotation.z = move_toward(right_arm.rotation.z, 0.0, delta * 1.8)
		left_leg.rotation.z = move_toward(left_leg.rotation.z, 0.0, delta * 1.8)
		right_leg.rotation.z = move_toward(right_leg.rotation.z, 0.0, delta * 1.8)

	if audio_player.playing:
		mouth_timer += delta
		if mouth_timer >= 0.16:
			mouth_timer = 0.0
			_set_mouth(not mouth_is_open)
	elif mouth_is_open:
		_set_mouth(false)

func _add_sphere(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 24
	mesh.rings = 16
	instance.mesh = mesh
	instance.position = position
	instance.scale = size
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance

func _add_capsule(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.5
	mesh.height = 2.0
	mesh.radial_segments = 16
	instance.mesh = mesh
	instance.position = position
	instance.scale = size
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance

func _add_cylinder(parent: Node3D, node_name: String, position: Vector3, top_radius: float, bottom_radius: float, height: float, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 32
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.74
	return material
