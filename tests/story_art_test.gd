extends SceneTree
const Repo = preload("res://scripts/stories/story_repository.gd")
const Art = preload("res://scripts/stories/story_art.gd")
var checks := 0
var failures := 0
var pointer := Vector2.ZERO
func _initialize() -> void: _run.call_deferred()
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _settle() -> void:
	for frame in range(3): await process_frame
func _move(at: Vector2, held: bool = false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.relative = at - pointer
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	pointer = at
	Input.parse_input_event(event)
	await _settle()
func _button(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.pressed = pressed
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)
	await _settle()
func _click(at: Vector2) -> void:
	await _move(at)
	await _button(at, true)
	await _button(at, false)
func _drag(from: Vector2, to: Vector2) -> void:
	await _move(from)
	await _button(from, true)
	await _move(from + Vector2(18, -18), true)
	_check(root.gui_is_dragging(), "Puzzle drag did not start")
	for step in range(1, 6): await _move(from.lerp(to, step / 5.0), true)
	await _button(to, false)
	_check(not root.gui_is_dragging(), "Puzzle preview remained after release")
func _run() -> void:
	if OS.get_environment("APRENDE_VALIDATION") != "1":
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	for target in [Vector2(800, 500), Vector2(900, 360), Vector2(400, 600)]:
		var source := Vector2(443, 443)
		var fitted := Art.contain_rect(source, target)
		_check(Rect2(Vector2.ZERO, target).grow(0.01).encloses(fitted), "Whole illustration leaves its available area")
		_check(absf(fitted.size.aspect() - source.aspect()) < 0.001, "Whole illustration is distorted")
	for id in Art.catalog().characters:
		var texture := Art.character_texture(id)
		_check(texture != null and maxi(texture.get_width(), texture.get_height()) <= 256, "Character card texture missing/oversized")
		_check(absf(float(texture.get_width()) / texture.get_height() - 1) < 0.02, "Character portraits do not share a format")
		var entry: Dictionary = Art.catalog().characters[id]
		var crop: Array = entry.crop
		_check(crop[0] >= 0 and crop[1] >= 0 and crop[0] + crop[2] <= 1.001 and crop[1] + crop[3] <= 1.001, "Portrait outside story scene")
	var initial := Repo.totals().duplicate()
	var puzzle: Control = load("res://scenes/completa_escena.tscn").instantiate()
	root.add_child(puzzle)
	await _settle()
	var puzzle_panel: PanelContainer = puzzle.board.get_parent()
	_check(puzzle.board.size.is_equal_approx(puzzle_panel.size - puzzle_panel.get_theme_stylebox("panel").get_minimum_size()), "Puzzle image does not fill its frame")
	_check(absf(puzzle.scene_image.texture.region.size.aspect() - puzzle.board.size.aspect()) < 0.001, "Puzzle image is distorted")
	_check(puzzle.scene_image.texture.region == puzzle.source_scene.region, "Puzzle still crops the original scene")
	var visible := Rect2(Vector2.ZERO, puzzle.source_scene.region.size)
	for index in range(3):
		var slot_rect: Rect2 = puzzle.SLOT_RECTS[index]
		var expected := Rect2(puzzle.source_scene.region.position + visible.position + slot_rect.position * visible.size, slot_rect.size * visible.size)
		_check(puzzle.piece_textures[index].region.is_equal_approx(expected), "Puzzle piece does not match the visible crop")
	var slots: Array = puzzle.board.get_children().filter(func(child: Node): return child.has_meta("missing"))
	await _drag(puzzle.tray.get_child(0).get_global_rect().get_center(), slots[1].get_global_rect().get_center())
	_check(puzzle.placed_slots.is_empty(), "Wrong puzzle image accepted")
	for index in range(3):
		var piece: Control = puzzle.tray.get_child(0)
		var original_texture: Texture2D = piece.texture
		var slot: Control = slots[piece.piece_index]
		await _drag(piece.get_global_rect().get_center(), slot.get_global_rect().get_center())
		_check(puzzle.placed_slots.size() == index + 1, "Correct native puzzle drag did not place once")
		var image: Control = slot.get_child(0)
		_check(image is TextureRect and image.texture == original_texture, "Puzzle crop was replaced")
		await _settle()
		_check(image.size.is_equal_approx(slot.size), "Puzzle replacement has an inset seam")
	_check(puzzle.next_button.visible, "Completed image did not enable next round")
	for round_ in range(1, 3):
		puzzle._next_round()
		await _settle()
		for slot in puzzle.board.get_children():
			if slot.has_meta("missing"): puzzle.on_piece_dropped(slot, slot.get_meta("slot_index"))
		await _settle()
	puzzle._next_round()
	_check(puzzle.round_index == -1, "Teammate's three puzzle rounds changed")
	puzzle._back()
	puzzle.queue_free()
	await _settle()
	var search: Control = load("res://scenes/busca_objeto.tscn").instantiate()
	root.add_child(search)
	await _settle()
	for level in range(3):
		if level > 0:
			search._next_level()
			await _settle()
		var search_panel: PanelContainer = search.image_area.get_parent()
		_check(search.image_area.size.is_equal_approx(search_panel.size - search_panel.get_theme_stylebox("panel").get_minimum_size()), "Search image does not fill its frame")
		_check(absf(search.illustration.texture.region.size.aspect() - search.image_area.size.aspect()) < 0.001, "Search image is distorted")
		_check(search.illustration.texture.region == search.source_frame.region, "Search still crops the original scene")
		var targets: Array = search.LEVELS[level].targets
		for index in range(3):
			for other in range(index): _check(not targets[index].rect.intersects(targets[other].rect), "Search hit boxes overlap")
			var spot: Control = search.image_area.get_node("Buscar_" + str(index))
			_check(spot.visible and spot.size.x >= 44 and spot.size.y >= 44, "Cover crop hid a search objective")
			var source_size: Vector2 = search.source_frame.get_size()
			var original: Rect2 = targets[index].rect
			var shown := Rect2(original.position * source_size, original.size * source_size).intersection(search.visible_region)
			var expected_center: Vector2 = (shown.get_center() - search.visible_region.position) / search.visible_region.size * search.image_area.size
			_check(spot.get_rect().get_center().distance_to(expected_center) < 1, "Search target did not follow the covered illustration")
			await _click(spot.get_global_rect().get_center())
			_check(search.targets_found == index + 1, "Click on real image did not find its object")
			await _click(spot.get_global_rect().get_center())
			_check(search.targets_found == index + 1, "Repeated search click awarded again")
		_check(search.next_button.visible, "Search next button missing")
	search._next_level()
	_check(search.level_index == 3, "Teammate's search completion changed")
	search._go_back()
	search.queue_free()
	await _settle()
	var quiz: Control = load("res://scenes/reto_rapido.tscn").instantiate()
	root.add_child(quiz)
	quiz.set_process(false)
	for story in Repo.all_stories():
		for question in story.questions:
			var item: Dictionary = question.duplicate(true)
			item.story_id = story.id
			item.story_title = story.title
			quiz.questions[0] = item
			quiz.question_index = 0
			quiz._show_question()
			await _settle()
			_check(quiz.reference_art.texture.atlas.resource_path == story.atlas, "Quick quiz used another story's artwork")
			var expected: Rect2 = Repo.page_texture(story, int(question.evidence)).region
			_check(quiz.reference_art.source_frame.region == expected, "Quick quiz used unrelated evidence")
			_check(quiz.reference_art.texture.region == expected, "Quick quiz still crops the original scene")
			_check(quiz.options_grid.get_child_count() == 3, "Teammate's three answer cards changed")
	quiz._restart()
	for round_ in range(3):
		var answer: String = quiz.questions[quiz.question_index].answer
		var button: Button
		for candidate in quiz.options_grid.get_children():
			if candidate.get_meta("choice") == answer: button = candidate
		quiz._choose_answer(answer, button)
		quiz._choose_answer(answer, button)
		_check(quiz.score == round_ + 1, "Duplicate quick answer awarded a point")
		quiz._next_question()
		await _settle()
	_check(quiz.result_panel.visible and not quiz.reference_art.get_parent().visible, "Quick result still displays old question art")
	quiz._go_back()
	quiz.queue_free()
	await _settle()
	_check(Repo.totals() == initial, "Art changes modified saved story progress")
	await create_timer(0.5).timeout
	print("STORY ART TEST: %d checks, %d failure(s)" % [checks, failures])
	quit(0 if failures == 0 else 1)

