class_name GameSettings
extends Node
## Runtime settings: the single source of truth for values a developer or player may change.
## Every setting is declared once in DEFINITIONS; the console and a future settings HUD
## both read that list, so adding a setting there is all it takes to expose it.
## Values reset to their defaults on every launch.

signal changed(key: StringName, value: Variant)

const DEFINITIONS: Dictionary[StringName, Dictionary] = {
	&"pixelated": {
		type = TYPE_BOOL,
		default = true,
		description = "Render the world at low resolution with crisp, blocky upscaling.",
	},
	&"enemy_avoidance": {
		type = TYPE_BOOL,
		default = true,
		description = "Enemies steer around each other.",
	},
	&"enemy_collision": {
		type = TYPE_BOOL,
		default = true,
		description = "Enemies collide with each other.",
	},
}

var _values: Dictionary[StringName, Variant] = {}


func _init() -> void:
	for key: StringName in DEFINITIONS:
		_values[key] = DEFINITIONS[key].default


func has_setting(key: StringName) -> bool:
	return DEFINITIONS.has(key)


func get_value(key: StringName) -> Variant:
	assert(has_setting(key), "Unknown setting: %s" % key)
	return _values[key]


## Sets a value of the exact declared type. Emits `changed` only when the value differs.
func set_value(key: StringName, value: Variant) -> Error:
	if not has_setting(key):
		return ERR_DOES_NOT_EXIST
	if typeof(value) != DEFINITIONS[key].type:
		return ERR_INVALID_PARAMETER
	if _values[key] == value:
		return OK
	_values[key] = value
	changed.emit(key, value)
	return OK


## Parses text (as typed in the console) into the setting's declared type, then sets it.
func set_from_text(key: StringName, text: String) -> Error:
	if not has_setting(key):
		return ERR_DOES_NOT_EXIST
	var type: Variant.Type = DEFINITIONS[key].type
	var parsed: Variant = _parse(type, text)
	if parsed == null:
		return ERR_PARSE_ERROR
	return set_value(key, parsed)


## Returns null when the text doesn't fit the type. Only bool exists so far; add a branch per new type.
static func _parse(type: Variant.Type, text: String) -> Variant:
	match type:
		TYPE_BOOL:
			match text.to_lower():
				"1", "true", "on":
					return true
				"0", "false", "off":
					return false
	return null
