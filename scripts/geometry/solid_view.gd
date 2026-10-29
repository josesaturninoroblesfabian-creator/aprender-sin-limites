extends Control

signal turned
var shape := "cube"
var viewport: SubViewport
var pivot: Node3D
var mesh: MeshInstance3D
var interaction_count := 0
var dragging := false
var active := true
var yaw := 0.45
var pitch := -0.25

func _ready() -> void:
	custom_minimum_size = Vector2(240, 225)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport = SubViewport.new()
	viewport.size = Vector2i(384, 384)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#edf8ff")
	environment.environment.ambient_light_energy = 0.7
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38, -30, 0)
	light.light_energy = 1.2
	world.add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0.1, 4)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.8
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	pivot = Node3D.new()
	world.add_child(pivot)
	mesh = MeshInstance3D.new()
	pivot.add_child(mesh)
	var texture := TextureRect.new()
	texture.texture = viewport.get_texture()
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture)
	setup(shape)

func setup(id: String) -> void:
	shape = id if id in ["cube", "sphere", "cylinder", "cone"] else "cube"
	interaction_count = 0
	if not is_instance_valid(mesh): return
	var material := StandardMaterial3D.new()
	material.roughness = 0.32
	material.albedo_color = {"cube": Color("#e7a84c"), "sphere": Color("#27b8bb"), "cylinder": Color("#7c70d8"), "cone": Color("#ee7860")}[shape]
	match shape:
		"cube":
			var box := BoxMesh.new()
			box.size = Vector3.ONE * 1.45
			mesh.mesh = box
		"sphere":
			var ball := SphereMesh.new()
			ball.radius = 0.9
			ball.height = 1.8
			ball.radial_segments = 32
			ball.rings = 16
			mesh.mesh = ball
			var gradient := GradientTexture2D.new()
			gradient.width = 128
			gradient.height = 32
			gradient.gradient = Gradient.new()
			gradient.gradient.offsets = PackedFloat32Array([0, 0.35, 0.4, 0.6, 0.65, 1])
			gradient.gradient.colors = PackedColorArray([Color("#23b9bf"), Color("#23b9bf"), Color("#f5ad6c"), Color("#f5ad6c"), Color("#23b9bf"), Color("#23b9bf")])
			material.albedo_color = Color.WHITE
			material.albedo_texture = gradient
		_:
			var body := CylinderMesh.new()
			body.top_radius = 0 if shape == "cone" else 0.7
			body.bottom_radius = 0.8 if shape == "cone" else 0.7
			body.height = 1.8
			body.radial_segments = 40
			mesh.mesh = body
	mesh.material_override = material
	_update_rotation()

func turn(amount: float, vertical: float = 0) -> void:
	if not active: return
	yaw += amount
	pitch = clampf(pitch + vertical, -1.35, 1.35)
	interaction_count += 1
	_update_rotation()
	turned.emit()

func _update_rotation() -> void:
	if is_instance_valid(pivot): pivot.rotation = Vector3(pitch, yaw, 0)

func _gui_input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		accept_event()
	elif event is InputEventMouseMotion and dragging and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		turn(event.relative.x * 0.012, event.relative.y * 0.012)
		accept_event()
	elif event is InputEventScreenDrag:
		turn(event.relative.x * 0.012, event.relative.y * 0.012)
		accept_event()
