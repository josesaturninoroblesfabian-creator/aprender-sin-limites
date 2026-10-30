extends Control

signal back_requested

const Carmelo = preload("res://scripts/stories/carmelo_avatar.gd")
const Repo = preload("res://scripts/stories/story_repository.gd")
const Ink := Color("#173b70")
const Gold := Color("#ffd34f")
const LEVELS: Array[Dictionary] = [
	{"id":"caperucita_roja", "page":1, "targets":[
		{"name":"El letrero del camino", "icon":"🪧", "rect":Rect2(0.34,0.06,0.27,0.19)},
		{"name":"La canasta", "icon":"🧺", "rect":Rect2(0.06,0.57,0.27,0.23)},
		{"name":"El lobo", "icon":"🐺", "rect":Rect2(0.66,0.26,0.31,0.45)}]},
	{"id":"tres_chanchitos", "page":0, "targets":[
		{"name":"La paja", "icon":"🌾", "rect":Rect2(0.03,0.59,0.30,0.30)},
		{"name":"Las tablas", "icon":"🪵", "rect":Rect2(0.35,0.62,0.34,0.27)},
		{"name":"Los ladrillos", "icon":"🧱", "rect":Rect2(0.76,0.59,0.22,0.27)}]},
	{"id":"patito_feo", "page":2, "targets":[
		{"name":"Los juncos", "icon":"🌿", "rect":Rect2(0.02,0.02,0.24,0.21)},
		{"name":"El patito", "icon":"🐥", "rect":Rect2(0.06,0.29,0.43,0.58)},
		{"name":"La roca", "icon":"🪨", "rect":Rect2(0.74,0.62,0.25,0.26)}]}
]

var level_index := 0
var targets_found := 0
var target_panel: VBoxContainer
var target_list: VBoxContainer
var title_label: Label
var progress_label: Label
var image_area: Control
var feedback: Label
var next_button: Button
var carmelo: TextureRect
var source_frame: AtlasTexture
var illustration: TextureRect
var visible_region := Rect2()

func _ready() -> void:
	_build_ui()
	_show_level()
	StoryAudio.guide("welcome", self)

func _build_ui() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/backgrounds/fondo-paisaje-andino.png") as Texture2D
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.13,0.28,0.40)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",18)
	margin.add_theme_constant_override("margin_top",14)
	margin.add_theme_constant_override("margin_right",18)
	margin.add_theme_constant_override("margin_bottom",14)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation",8)
	margin.add_child(root)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y=76
	root.add_child(header)
	var back := _button("⌂\nVolver al menú",Color("#985128"),Vector2(148,66))
	back.pressed.connect(_go_back)
	header.add_child(back)
	var title_sign := PanelContainer.new()
	title_sign.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title_sign.add_theme_stylebox_override("panel",_style(Color("#0c83d5"),Gold,4,24))
	header.add_child(title_sign)
	title_label=_label("★ ¡Busca el objeto! ★",38,Color("#fff26b"),true)
	title_label.add_theme_color_override("font_outline_color",Color("#173eaa"))
	title_label.add_theme_constant_override("outline_size",7)
	title_sign.add_child(title_label)
	var progress_panel:=PanelContainer.new()
	progress_panel.custom_minimum_size.x=180
	progress_panel.add_theme_stylebox_override("panel",_style(Color("#0876c9"),Gold,4,20))
	header.add_child(progress_panel)
	progress_label=_label("Progreso 1 de 3\n⭐  🧩  🧩",17,Color.WHITE,true)
	progress_panel.add_child(progress_label)
	var instruction:=PanelContainer.new()
	instruction.add_theme_stylebox_override("panel",_style(Color("#92502c"),Gold,4,18))
	root.add_child(instruction)
	var hint := _label("Encuentra los objetos escondidos en el cuento",21,Color.WHITE,true)
	instruction.add_child(hint)
	var body:=HBoxContainer.new()
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	root.add_child(body)
	var left:=PanelContainer.new()
	left.custom_minimum_size.x=185
	left.add_theme_stylebox_override("panel",_style(Color("#fff5df"),Color("#db9c44"),4,23))
	body.add_child(left)
	var left_stack:=VBoxContainer.new()
	left_stack.alignment=BoxContainer.ALIGNMENT_CENTER
	left.add_child(left_stack)
	carmelo=Carmelo.new()
	carmelo.texture=load("res://assets/carmelo-personaje.png") as Texture2D
	carmelo.custom_minimum_size=Vector2(0,270)
	left_stack.add_child(carmelo)
	var bubble:=PanelContainer.new()
	bubble.add_theme_stylebox_override("panel",_style(Color.WHITE,Color("#087fd0"),3,22))
	left_stack.add_child(bubble)
	var speech:=_label("¡Mira con atención! ¿Puedes encontrar todos estos objetos?",17,Ink,true)
	speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(speech)
	var frame:=PanelContainer.new()
	frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel",_style(Color("#fff0c5"),Color("#b97232"),7,26))
	var scene_fit := AspectRatioContainer.new()
	scene_fit.name = "AjusteImagenCompleta"
	scene_fit.ratio = 1.0
	scene_fit.stretch_mode = AspectRatioContainer.STRETCH_FIT
	scene_fit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_fit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scene_fit)
	scene_fit.add_child(frame)
	image_area=Control.new()
	image_area.clip_contents = true
	image_area.name="EscenaInteractiva"
	image_area.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	image_area.size_flags_vertical=Control.SIZE_EXPAND_FILL
	frame.add_child(image_area)
	image_area.resized.connect(_layout_image)
	var right:=PanelContainer.new()
	right.custom_minimum_size.x=180
	right.add_theme_stylebox_override("panel",_style(Color("#fff5df"),Color("#db9c44"),4,23))
	body.add_child(right)
	target_panel=VBoxContainer.new()
	target_panel.add_theme_constant_override("separation",10)
	right.add_child(target_panel)
	target_panel.add_child(_label("Objetos",20,Ink,true))
	target_list=VBoxContainer.new()
	target_list.add_theme_constant_override("separation",12)
	target_panel.add_child(target_list)
	feedback=_label("Toca el objeto en la ilustración.",16,Color.WHITE,true)
	root.add_child(feedback)
	var footer:=HBoxContainer.new()
	footer.custom_minimum_size.y=52
	root.add_child(footer)
	var spacer:=Control.new()
	spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	next_button=_button("¡Siguiente! ➜",Color("#20b84c"),Vector2(205,54))
	next_button.visible=false
	next_button.pressed.connect(_next_level)
	footer.add_child(next_button)

func _show_level() -> void:
	if level_index >= LEVELS.size():
		feedback.text="¡Completaste las tres escenas! ¡Muy bien! ⭐⭐⭐"
		progress_label.text="¡Completado!\n⭐  ⭐  ⭐"
		next_button.text="Jugar de nuevo"
		next_button.visible=true
		return
	targets_found=0
	var level:Dictionary=LEVELS[level_index]
	var story:Dictionary=Repo.find_story(String(level.id))
	source_frame=Repo.page_texture(story,int(level.page))
	for child in image_area.get_children():
		image_area.remove_child(child)
		child.queue_free()
	illustration=TextureRect.new()
	illustration.name = "IlustracionCompleta"
	illustration.texture=source_frame
	illustration.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	# Preserve the whole scene and its original target coordinates.
	illustration.stretch_mode=TextureRect.STRETCH_SCALE
	illustration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	illustration.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image_area.add_child(illustration)
	title_label.text="★ ¡Busca el objeto! ★"
	progress_label.text="Progreso %d de 3\n%s" % [level_index+1,"⭐  🧩  🧩" if level_index==0 else ("⭐  ⭐  🧩" if level_index==1 else "⭐  ⭐  ⭐")]
	for child in target_list.get_children():
		target_list.remove_child(child)
		child.queue_free()
	for index in range(level.targets.size()):
		var target:Dictionary=level.targets[index]
		var row:=HBoxContainer.new()
		row.name="Objetivo_%d" % index
		var badge:=Label.new()
		badge.text=String(target.icon)
		badge.add_theme_font_size_override("font_size",28)
		row.add_child(badge)
		var name:=_label(String(target.name),16,Ink,false)
		name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		row.add_child(name)
		target_list.add_child(row)
		var spot:=Button.new()
		spot.name="Buscar_%d" % index
		spot.tooltip_text="Buscar: %s" % String(target.name)
		spot.anchor_left=target.rect.position.x
		spot.anchor_top=target.rect.position.y
		spot.anchor_right=target.rect.end.x
		spot.anchor_bottom=target.rect.end.y
		spot.add_theme_stylebox_override("normal",_style(Color(0,0,0,0),Color(1,1,1,0),0,30))
		spot.add_theme_stylebox_override("hover",_style(Color(1,0.83,0.15,0.32),Color.WHITE,4,30))
		spot.add_theme_stylebox_override("pressed",_style(Color(0.2,0.8,0.3,0.45),Color.WHITE,4,30))
		spot.pressed.connect(_on_target_found.bind(index))
		image_area.add_child(spot)
	feedback.text="Encuentra los tres objetos de «%s»." % String(story.get("title","este cuento"))
	next_button.visible=false
	_layout_image()

func _layout_image() -> void:
	if source_frame == null or not is_instance_valid(illustration) or level_index >= LEVELS.size(): return
	if image_area.size.x <= 0 or image_area.size.y <= 0: return
	var level: Dictionary = LEVELS[level_index]
	var source_size := source_frame.get_size()
	visible_region = Rect2(Vector2.ZERO, source_frame.region.size)
	illustration.texture = source_frame
	for index in range(level.targets.size()):
		var spot := image_area.get_node_or_null("Buscar_%d" % index) as Button
		if spot == null: continue
		var target: Rect2 = level.targets[index].rect
		var source_rect := Rect2(target.position * source_size, target.size * source_size)
		var shown := source_rect.intersection(visible_region)
		spot.visible = shown.has_area()
		if not spot.visible: continue
		var area := Rect2((shown.position - visible_region.position) / visible_region.size, shown.size / visible_region.size)
		spot.anchor_left = area.position.x
		spot.anchor_top = area.position.y
		spot.anchor_right = area.end.x
		spot.anchor_bottom = area.end.y
		spot.offset_left = 0
		spot.offset_top = 0
		spot.offset_right = 0
		spot.offset_bottom = 0

func _on_target_found(index:int) -> void:
	var row:=target_list.get_node_or_null("Objetivo_%d" % index) as HBoxContainer
	if row==null or row.has_meta("found"): return
	row.set_meta("found",true)
	row.modulate=Color(0.55,1.0,0.65)
	var badge := row.get_child(0) as Label
	badge.text = "✅"
	var target_name := row.get_child(1) as Label
	target_name.text = "✓ " + String(LEVELS[level_index].targets[index].name)
	target_name.add_theme_color_override("font_color", Color("#218a45"))
	var spot:=image_area.get_node_or_null("Buscar_%d" % index) as Button
	if spot:
		spot.disabled=true
		spot.add_theme_stylebox_override("disabled", _style(Color(0.12,0.72,0.28,0.58), Color.WHITE, 4, 30))
		var check := Label.new()
		check.text = "✓"
		check.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		check.add_theme_font_size_override("font_size", 38)
		check.add_theme_color_override("font_color", Color.WHITE)
		check.add_theme_color_override("font_outline_color", Color("#147b35"))
		check.add_theme_constant_override("outline_size", 5)
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spot.add_child(check)
	targets_found+=1
	if targets_found==3:
		feedback.text="¡Encontraste todos los objetos! ⭐"
		StoryAudio.guide("success",self)
		next_button.visible=true
	else:
		feedback.text="¡Sí! Encontraste %s. Busca otro." % String(LEVELS[level_index].targets[index].name)
		StoryAudio.guide("progress",self)

func _next_level() -> void:
	if level_index>=LEVELS.size(): level_index=0
	else: level_index+=1
	if level_index<LEVELS.size(): _show_level()
	else:
		_show_level()
		next_button.text="Jugar de nuevo"

func _go_back() -> void:
	StoryAudio.stop(self)
	back_requested.emit()

func _button(text:String,color:Color,minimum:Vector2)->Button:
	var button:=Button.new()
	button.text=text
	button.custom_minimum_size=minimum
	button.add_theme_font_size_override("font_size",18)
	button.add_theme_color_override("font_color",Color.WHITE)
	button.add_theme_stylebox_override("normal",_style(color,Color("#fff0b4"),3,19))
	button.add_theme_stylebox_override("hover",_style(color.lightened(0.12),Gold,4,19))
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	_font(button,700)
	return button

func _label(text:String,size:int,color:Color,centered:bool)->Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if centered: label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_font(label,700)
	return label

func _style(fill:Color,border:Color,width:int,radius:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=fill
	style.border_color=border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(9)
	return style

func _font(control:Control,weight:int)->void:
	var font:=SystemFont.new()
	font.font_names=PackedStringArray(["Baloo 2","Trebuchet MS","Arial"])
	font.font_weight=weight
	font.fallbacks=[ThemeDB.fallback_font]
	control.add_theme_font_override("font",font)
