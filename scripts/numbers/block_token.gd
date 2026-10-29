extends Button

const Piece = preload("res://scripts/numbers/base_ten_piece.gd")
var place := 0
var board: Control

func _ready() -> void:
	pressed.connect(func():
		if not disabled and is_instance_valid(board):
			board.add_piece(place, 1, board.get_global_transform().affine_inverse() * get_global_rect().get_center())
	)

func _draw() -> void:
	Piece.paint(self, place, Vector2(27, size.y * 0.5), 43)

func _get_drag_data(_at: Vector2) -> Variant:
	if disabled: return null
	var preview := Piece.new()
	preview.place = place
	preview.custom_minimum_size = Vector2(72, 72)
	set_drag_preview(preview)
	return {"type": "base_ten_piece", "place": place, "source": null}

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return not disabled and data is Dictionary and data.get("type") == "base_ten_piece" and data.get("place") == place and is_instance_valid(board) and data.get("source") == board

func _drop_data(at: Vector2, data: Variant) -> void:
	if _can_drop_data(at, data): board.remove_piece(place)
