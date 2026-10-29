extends RefCounted

const UI = preload("res://scripts/math/math_ui.gd")
static var props: Dictionary = {}
static var scenery: Dictionary = {}

static func object(index: int) -> Texture2D:
	if not props.has(index): props[index] = UI._cell("res://assets/ui/geometry/activities/props-atlas.png", index, 4, 2)
	return props[index]

static func backdrop(index: int) -> Texture2D:
	if not scenery.has(index): scenery[index] = UI._cell("res://assets/ui/geometry/activities/scenery-atlas.png", index, 2, 2)
	return scenery[index]
