extends CanvasLayer

const UI = preload("res://scripts/math/math_ui.gd")
const ROBOT = preload("res://assets/ui/assistant-robot.svg")
const IDLE_SECONDS := 30.0

var read_context: Callable
var elapsed := 0.0
var offered := false
var context_id := ""
var focused := true
var suspended := false
var touches: Dictionary = {}
var placement := "corner"
var surface: Control
var launcher: Button
var card: PanelContainer
var hint_label: Label

func _ready() -> void:
	layer = 30
	surface = Control.new()
	surface.name = "Tuki"
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	launcher = UI.button("", Color("#185b72"))
	launcher.name = "AssistantButton"
	launcher.icon = ROBOT
	launcher.expand_icon = true
	launcher.tooltip_text = "Tuki · Mostrar u ocultar una pista"
	launcher.pressed.connect(_toggle_hint)
	surface.add_child(launcher)
	launcher.size = Vector2(62, 62)
	var content := UI.paper(surface, Color("#fff8e5"))
	card = content.get_parent()
	card.name = "AssistantHint"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UI.style(Color("#fff8e5"), Color("#1b6e7e"), 16, 11))
	card.size.x = 326
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 4)
	content.add_child(UI.text("Tuki · Una pista", 21, Color("#185b72")))
	hint_label = UI.text("", 19)
	content.add_child(hint_label)
	card.hide()
	surface.hide()
	surface.resized.connect(_layout_overlay)
	card.resized.connect(_position_hint)
	card.minimum_size_changed.connect(_fit_hint_height)
	get_window().focus_entered.connect(_set_focused.bind(true))
	get_window().focus_exited.connect(_set_focused.bind(false))

func _layout_overlay() -> void:
	if surface.size.x < 100:
		return
	var width := 326.0
	launcher.position = surface.size - launcher.size - Vector2(12, 14)
	match placement:
		"letters":
			launcher.position = Vector2(12, 18)
			width = 248.0
		"trace":
			launcher.position = Vector2(12, surface.size.y * 0.70)
			width = 226.0
		"reading":
			width = 300.0
	var available := surface.size.x - 24
	if placement in ["letters", "reading"]:
		available -= launcher.size.x + 8
	card.size.x = minf(width, available)
	_position_hint()

func _position_hint() -> void:
	match placement:
		"letters":
			card.position = launcher.position + Vector2(launcher.size.x + 8, 0)
		"reading":
			card.position = launcher.position + Vector2(-card.size.x - 8, launcher.size.y - card.size.y)
		_:
			var x := 12.0 if placement == "trace" else surface.size.x - card.size.x - 12
			card.position = Vector2(x, launcher.position.y - card.size.y - 8)

func _fit_hint_height() -> void:
	card.size.y = 0
	_position_hint()

func _sync_context() -> Dictionary:
	if not focused or suspended or not read_context.is_valid():
		surface.hide()
		return {}
	var context: Dictionary = read_context.call()
	var id: String = context.get("id", "")
	if id != context_id:
		context_id = id
		elapsed = 0.0
		offered = false
		card.hide()
		placement = context.get("placement", "corner")
		_layout_overlay()
	if id.is_empty() or context.get("busy", false):
		elapsed = 0.0
		card.hide()
		surface.hide()
		return {}
	surface.show()
	return context

func _process(delta: float) -> void:
	var context := _sync_context()
	if context.is_empty() or offered:
		return
	if not touches.is_empty() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or get_viewport().gui_is_dragging():
		elapsed = 0.0
		return
	elapsed += delta
	if elapsed >= float(context.get("wait", IDLE_SECONDS)):
		_show_hint(context.hint)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = true
		else:
			touches.erase(event.index)
	var dragging: bool = event is InputEventScreenDrag or (event is InputEventMouseMotion and event.button_mask != 0)
	if not dragging and (not event.is_pressed() or event.is_echo()):
		return
	elapsed = 0.0
	if not card.visible:
		return
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if launcher.get_global_rect().has_point(event.position):
			return
	if event is InputEventKey and launcher.has_focus() and event.is_action_pressed("ui_accept"):
		return
	card.hide()

func _toggle_hint() -> void:
	var context := _sync_context()
	if context.is_empty():
		return
	if card.visible:
		card.hide()
	else:
		_show_hint(context.hint)

func _show_hint(hint: String) -> void:
	offered = true
	hint_label.text = hint
	card.show()
	_fit_hint_height.call_deferred()

func _set_focused(active: bool) -> void:
	focused = active
	_reset_attention()

func _reset_attention() -> void:
	elapsed = 0.0
	touches.clear()
	card.hide()
	surface.hide()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_RESUMED:
		suspended = what == NOTIFICATION_APPLICATION_PAUSED
		_reset_attention()
