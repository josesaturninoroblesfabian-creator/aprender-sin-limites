extends Control

signal back_requested

const REFERENCE_IMAGE := "res://assets/pantalla-cuentos-sin-progreso.png"
const REFERENCE_SIZE := Vector2(2096.0, 1120.0)
const PROGRESS_FILE := "user://progreso_cuentos.cfg"
const TOTAL_TOPICS := 20
const CARMELO_GREETING := "¡Hola! Soy Carmelo. ¡Descubramos cuentos increíbles!"

# Interactive areas are relative to the 2096 x 1120 reference image.
const HOTSPOTS := [
    {"id": "cuentos_ilustrados", "label": "Cuentos ilustrados", "rect": Rect2(0.291, 0.221, 0.228, 0.289)},
    {"id": "escucha_cuento", "label": "Escucha el cuento", "rect": Rect2(0.520, 0.221, 0.227, 0.289)},
    {"id": "ordena_historia", "label": "Ordena la historia", "rect": Rect2(0.289, 0.510, 0.228, 0.255)},
    {"id": "preguntas_retos", "label": "Preguntas y retos", "rect": Rect2(0.521, 0.510, 0.224, 0.255)},
    {"id": "elegir_personaje", "label": "Elegir personaje", "rect": Rect2(0.179, 0.802, 0.159, 0.198)},
    {"id": "completa_escena", "label": "Completa la escena", "rect": Rect2(0.343, 0.802, 0.166, 0.198)},
    {"id": "busca_objeto", "label": "Busca el objeto", "rect": Rect2(0.512, 0.802, 0.149, 0.198)},
    {"id": "reto_rapido", "label": "Reto rapido", "rect": Rect2(0.663, 0.802, 0.158, 0.198)},
    {"id": "menu_principal", "label": "Volver al menu principal", "rect": Rect2(0.010, 0.876, 0.148, 0.110)},
    {"id": "configuracion", "label": "Configuracion", "rect": Rect2(0.841, 0.010, 0.067, 0.113)},
    {"id": "ayuda", "label": "Ayuda", "rect": Rect2(0.918, 0.010, 0.070, 0.113)},
]

var design_frame: Control
var progress_label: Label
var progress_bar: ProgressBar
var progress_tween: Tween
var progress_stars: Array[Label] = []
var completed_topics: Dictionary = {}
var carmelo_avatar: TextureRect
var welcome_bubble: PanelContainer

func _ready() -> void:
    design_frame = Control.new()
    design_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    design_frame.clip_contents = true
    add_child(design_frame)

    var screenshot := TextureRect.new()
    screenshot.texture = load(REFERENCE_IMAGE)
    screenshot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screenshot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    screenshot.stretch_mode = TextureRect.STRETCH_SCALE
    screenshot.mouse_filter = Control.MOUSE_FILTER_IGNORE
    design_frame.add_child(screenshot)

    _add_carmelo_welcome()
    _add_listening_card_art()
    _animate_carmelo_idle()
    _speak_carmelo_greeting()

    for hotspot in HOTSPOTS:
        _add_hotspot(hotspot)

    _build_progress_meter()
    _load_progress()
    _refresh_progress_meter()

func _add_carmelo_welcome() -> void:
    # Carmelo uses the exact transparent PNG supplied by the user.
    carmelo_avatar = TextureRect.new()
    carmelo_avatar.name = "Carmelo"
    carmelo_avatar.texture = load("res://assets/carmelo-personaje.png")
    carmelo_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    carmelo_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    carmelo_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    carmelo_avatar.anchor_left = 0.005
    carmelo_avatar.anchor_top = 0.300
    carmelo_avatar.anchor_right = 0.265
    carmelo_avatar.anchor_bottom = 0.805
    design_frame.add_child(carmelo_avatar)

    welcome_bubble = PanelContainer.new()
    welcome_bubble.name = "PensamientoCarmelo"
    welcome_bubble.anchor_left = 0.105
    welcome_bubble.anchor_top = 0.155
    welcome_bubble.anchor_right = 0.285
    welcome_bubble.anchor_bottom = 0.285
    welcome_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var bubble_style := StyleBoxFlat.new()
    bubble_style.bg_color = Color("#fffdf4")
    bubble_style.border_color = Color("#087bd0")
    bubble_style.set_border_width_all(5)
    bubble_style.set_corner_radius_all(34)
    bubble_style.set_content_margin(SIDE_LEFT, 15)
    bubble_style.set_content_margin(SIDE_RIGHT, 15)
    bubble_style.set_content_margin(SIDE_TOP, 10)
    bubble_style.set_content_margin(SIDE_BOTTOM, 10)
    welcome_bubble.add_theme_stylebox_override("panel", bubble_style)
    design_frame.add_child(welcome_bubble)

    var greeting := RichTextLabel.new()
    greeting.name = "SaludoCarmelo"
    greeting.bbcode_enabled = true
    greeting.fit_content = true
    greeting.scroll_active = false
    greeting.mouse_filter = Control.MOUSE_FILTER_IGNORE
    greeting.text = "[center][color=#0a3388][b]¡Hola! Soy [color=#df2839]Carmelo.[/color][/b]\n¡Descubramos cuentos increíbles![/color][/center]"
    greeting.add_theme_font_size_override("normal_font_size", 24)
    welcome_bubble.add_child(greeting)

    # Two small dots make it read as Carmelo's thought bubble.
    for dot_spec in [Vector4(0.128, 0.286, 0.018, 0.025), Vector4(0.111, 0.310, 0.011, 0.016)]:
        var dot := Panel.new()
        dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
        dot.anchor_left = dot_spec.x
        dot.anchor_top = dot_spec.y
        dot.anchor_right = dot_spec.x + dot_spec.z
        dot.anchor_bottom = dot_spec.y + dot_spec.w
        var dot_style := StyleBoxFlat.new()
        dot_style.bg_color = Color("#fffdf4")
        dot_style.border_color = Color("#087bd0")
        dot_style.set_border_width_all(3)
        dot_style.set_corner_radius_all(20)
        dot.add_theme_stylebox_override("panel", dot_style)
        design_frame.add_child(dot)

func _add_listening_card_art() -> void:
    # Restore the original, correctly proportioned book and speaker artwork
    # from the reference image over the cleaned background image.
    var card := TextureRect.new()
    card.name = "ArteTarjetaEscucha"
    var card_texture := AtlasTexture.new()
    card_texture.atlas = load("res://assets/pantalla-cuentos-base.png")
    card_texture.region = Rect2(
        REFERENCE_SIZE.x * 0.520,
        REFERENCE_SIZE.y * 0.221,
        REFERENCE_SIZE.x * 0.227,
        REFERENCE_SIZE.y * 0.289
    )
    card.texture = card_texture
    card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    card.stretch_mode = TextureRect.STRETCH_SCALE
    card.anchor_left = 0.520
    card.anchor_top = 0.221
    card.anchor_right = 0.747
    card.anchor_bottom = 0.510
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    design_frame.add_child(card)

func _animate_carmelo_idle() -> void:
    # Animate both vertical offsets together so the anchored sprite stays in place.
    var idle_tween := create_tween().set_loops()
    idle_tween.tween_method(_set_carmelo_float, 0.0, -12.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    idle_tween.tween_method(_set_carmelo_float, -12.0, 12.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    idle_tween.tween_method(_set_carmelo_float, 12.0, 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _set_carmelo_float(offset: float) -> void:
    carmelo_avatar.offset_top = offset
    carmelo_avatar.offset_bottom = offset

func _speak_carmelo_greeting() -> void:
    var voices := DisplayServer.tts_get_voices_for_language("es")
    if voices.is_empty():
        var installed_voices := DisplayServer.tts_get_voices()
        for voice in installed_voices:
            if String(voice.get("language", "")).to_lower().begins_with("es"):
                voices.append(String(voice.get("id", "")))
        if voices.is_empty() and not installed_voices.is_empty():
            voices.append(String(installed_voices[0].get("id", "")))
    if voices.is_empty():
        return
    DisplayServer.tts_speak(CARMELO_GREETING, voices[0], 85, 1.08, 0.92, 304, true)

func _exit_tree() -> void:
    DisplayServer.tts_stop()

func _add_hotspot(data: Dictionary) -> void:
    var button := Button.new()
    button.name = "Hotspot_%s" % String(data.id)
    button.tooltip_text = String(data.label)
    button.text = ""
    button.focus_mode = Control.FOCUS_ALL
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    var area: Rect2 = data.rect
    button.anchor_left = area.position.x
    button.anchor_top = area.position.y
    button.anchor_right = area.position.x + area.size.x
    button.anchor_bottom = area.position.y + area.size.y
    button.add_theme_stylebox_override("normal", _hotspot_style(Color(0.0, 0.0, 0.0, 0.0)))
    button.add_theme_stylebox_override("hover", _hotspot_style(Color(1.0, 1.0, 1.0, 0.12)))
    button.add_theme_stylebox_override("pressed", _hotspot_style(Color(1.0, 1.0, 1.0, 0.2)))
    button.pressed.connect(_on_hotspot_pressed.bind(String(data.id)))
    design_frame.add_child(button)

func _hotspot_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(18)
    return style

func _build_progress_meter() -> void:
    var panel := PanelContainer.new()
    panel.name = "DynamicProgressMeter"
    # Keep a clear gutter after the title controls and before the first card row.
    panel.anchor_left = 0.775
    panel.anchor_top = 0.205
    panel.anchor_right = 0.985
    panel.anchor_bottom = 0.495
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("#eaf5ff")
    panel_style.border_color = Color("#168bd2")
    panel_style.set_border_width_all(5)
    panel_style.set_corner_radius_all(24)
    panel_style.set_content_margin_all(7)
    panel.add_theme_stylebox_override("panel", panel_style)
    design_frame.add_child(panel)

    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 4)
    panel.add_child(content)

    var heading := Label.new()
    heading.text = "Mi Progreso"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 18)
    heading.add_theme_color_override("font_color", Color("#0874c3"))
    content.add_child(heading)

    progress_label = Label.new()
    progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress_label.add_theme_font_size_override("font_size", 14)
    progress_label.add_theme_color_override("font_color", Color("#123b80"))
    content.add_child(progress_label)

    progress_bar = ProgressBar.new()
    progress_bar.min_value = 0
    progress_bar.max_value = TOTAL_TOPICS
    progress_bar.show_percentage = false
    progress_bar.custom_minimum_size.y = 14
    var track := StyleBoxFlat.new()
    track.bg_color = Color("#c7d9ec")
    track.set_corner_radius_all(12)
    var fill := StyleBoxFlat.new()
    fill.bg_color = Color("#20c943")
    fill.set_corner_radius_all(12)
    progress_bar.add_theme_stylebox_override("background", track)
    progress_bar.add_theme_stylebox_override("fill", fill)
    content.add_child(progress_bar)

    var levels := HBoxContainer.new()
    levels.add_theme_constant_override("separation", 2)
    content.add_child(levels)
    var names := ["Nivel 1\nIniciando", "Nivel 2\nPracticando", "Nivel 3\nExperto!"]
    for name in names:
        var level := VBoxContainer.new()
        level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        level.add_theme_constant_override("separation", 0)
        levels.add_child(level)

        var star := Label.new()
        star.text = "★"
        star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        star.add_theme_font_size_override("font_size", 26)
        star.custom_minimum_size = Vector2(30, 30)
        star.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        star.mouse_filter = Control.MOUSE_FILTER_IGNORE
        level.add_child(star)
        progress_stars.append(star)

        var caption := Label.new()
        caption.text = name
        caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        caption.add_theme_font_size_override("font_size", 10)
        caption.add_theme_color_override("font_color", Color("#123b80"))
        level.add_child(caption)

func _load_progress() -> void:
    var config := ConfigFile.new()
    if config.load(PROGRESS_FILE) != OK:
        return
    var saved: Variant = config.get_value("progreso", "temas", {})
    if saved is Dictionary:
        completed_topics = saved.duplicate()

func mark_topic_completed(topic_id: String) -> void:
    if topic_id.is_empty() or completed_topics.has(topic_id):
        return
    completed_topics[topic_id] = true
    var config := ConfigFile.new()
    config.set_value("progreso", "temas", completed_topics)
    config.save(PROGRESS_FILE)
    _refresh_progress_meter()

func _refresh_progress_meter() -> void:
    var completed: int = mini(completed_topics.size(), TOTAL_TOPICS)
    progress_label.text = "%d de %d temas" % [completed, TOTAL_TOPICS]
    if progress_tween != null and progress_tween.is_running():
        progress_tween.kill()
    progress_tween = create_tween()
    progress_tween.tween_property(progress_bar, "value", float(completed), 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    var thresholds := [1, 10, TOTAL_TOPICS]
    for index in range(progress_stars.size()):
        progress_stars[index].add_theme_color_override("font_color", Color("#ffc928") if completed >= thresholds[index] else Color("#8999aa"))

func _on_hotspot_pressed(id: String) -> void:
    if id == "menu_principal":
        back_requested.emit()
