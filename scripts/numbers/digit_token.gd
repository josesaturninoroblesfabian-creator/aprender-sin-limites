extends Button

var digit := 0

func _get_drag_data(_position: Vector2) -> Variant:
	if disabled: return null
	var preview := Label.new()
	preview.text = str(digit)
	preview.add_theme_font_size_override("font_size", 54)
	preview.add_theme_color_override("font_color", Color("#126a97"))
	set_drag_preview(preview)
	return {"type": "number_digit", "digit": digit}
