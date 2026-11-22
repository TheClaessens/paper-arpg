class_name HealthBar
extends MeshInstance3D
## A Character's Health bar (see GLOSSARY.md): the flat strip over its Standee, filled by its
## Health's share of the maximum. It shows only while Health is below its maximum. The
## Character connects its Health's `changed` to show_health().
## The quad is 100×9 viewport units on screen: the camera shows 6 world units over the
## viewport's 648, so 0.926×0.083 in the world. Change the camera's size, change the quad.

## How full the bar is: current Health over the maximum, 0 to 1.
var fraction := 1.0:
	set(value):
		fraction = value
		set_instance_shader_parameter(&"fraction", value)


## Shows `current` of `max_health`, or hides the bar at the maximum.
func show_health(current: float, max_health: float) -> void:
	fraction = current / max_health
	visible = current < max_health
