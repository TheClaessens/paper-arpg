class_name CooldownSweep
extends Control
## The dark pie over a Skill slot's button while its Skill cools down. It starts full and
## empties clockwise, from 12 o'clock, as the Skill comes back.

## Points along the pie's curve; enough to look round at slot sizes.
const ARC_POINTS := 48
const SHADE := Color(0.05, 0.04, 0.03, 0.65)

## How much of the cooldown is left, 1 (all) to 0 (ready).
var left := 0.0:
	set(value):
		if not is_equal_approx(value, left):
			left = value
			queue_redraw()


func _draw() -> void:
	if left <= 0.0:
		return
	var centre := size / 2.0
	var radius := minf(size.x, size.y) / 2.0
	# What's still cooling runs from the hand at 12 o'clock back round, anticlockwise, to 12.
	var points := PackedVector2Array([centre])
	var start := -PI / 2.0
	var sweep := TAU * left
	for i in ARC_POINTS + 1:
		var angle := start - sweep * i / ARC_POINTS
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, SHADE)
