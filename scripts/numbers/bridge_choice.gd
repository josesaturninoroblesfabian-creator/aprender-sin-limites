extends Button

var value := 0

func _get_drag_data(_position: Vector2) -> Variant:
	if disabled: return null
	var label := Label.new()
	label.text = str(value)
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color("#075f89"))
	set_drag_preview(label)
	return {"type": "bridge_number", "value": value}
