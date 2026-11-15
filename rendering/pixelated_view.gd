class_name PixelatedView
extends SubViewportContainer
## Shows the 3D world of its child SubViewport. While the `pixelated` setting is on,
## the world renders at roughly `pixel_height` pixels tall and is upscaled with
## nearest-neighbour filtering. Anything outside this node (UI, HUD) stays sharp.
##
## Scaling is by a whole number (stretch_shrink), so every world pixel is the same size
## on screen. The real height is therefore the closest whole fraction of the window:
## a 1080p screen with pixel_height 240 shrinks by 5 (1080 / 240 = 4.5 rounds up) and renders 216 pixels tall.

## Target height of the world in pixels while pixelated. Tune in the editor.
@export_range(90, 720) var pixel_height := 240:
	set(value):
		pixel_height = value
		if is_inside_tree():
			_apply()


func _ready() -> void:
	stretch = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(_apply)
	Settings.changed.connect(_on_setting_changed)
	_apply()


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == &"pixelated":
		_apply()


func _apply() -> void:
	if Settings.get_value(&"pixelated"):
		stretch_shrink = maxi(1, roundi(size.y / pixel_height))
	else:
		stretch_shrink = 1
