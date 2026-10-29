extends PanelContainer

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("piece_index")

func _drop_data(_position: Vector2, data: Variant) -> void:
	if data is Dictionary:
		var ancestor: Node = get_parent()
		while ancestor != null and not ancestor.has_method("on_piece_dropped"):
			ancestor = ancestor.get_parent()
		if ancestor != null:
			ancestor.call("on_piece_dropped", self, int(data.piece_index))
