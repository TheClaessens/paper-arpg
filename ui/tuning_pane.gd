class_name TuningPane
extends PanelContainer
## A debug pane of sliders for tuning combat while playing. The `hitfeel` console command
## toggles it, and it stays open after the Console closes. Each slider changes the live value,
## so the next hit already feels different. Temporary: it goes once the values settle
## (see .scratch/combat/spec.md).

@export var hit_feedback: HitFeedback
@export var attack: Attack
@export var skill_slot: SkillSlot

var _tunables: Array[Dictionary] = []
var _sliders: Dictionary[StringName, HSlider] = {}

@onready var _rows: VBoxContainer = %Rows


func _enter_tree() -> void:
	Console.register(&"hitfeel", _cmd_hitfeel, "hitfeel: toggle the tuning pane and list its values. hitfeel <name> <value>: set one.")


func _ready() -> void:
	hide()
	_tunables = [
		_tunable(&"hitstop", hit_feedback, 0.0, 0.3, 0.01),
		_tunable(&"flash", hit_feedback, 0.0, 0.3, 0.01),
		_tunable(&"squash", hit_feedback, 0.0, 0.6, 0.02),
		_tunable(&"knockback", hit_feedback, 0.0, 3.0, 0.05),
		_tunable(&"shake", hit_feedback, 0.0, 0.5, 0.01),
		_tunable(&"shake_time", hit_feedback, 0.0, 0.5, 0.01),
		_tunable(&"stagger", hit_feedback, 0.0, 1.0, 0.01),
		_tunable(&"attack_arc", attack, 30.0, 360.0, 5.0, &"arc"),
		_tunable(&"attack_reach", attack, 0.5, 4.0, 0.1, &"reach"),
		_tunable(&"attack_use_time", attack, 0.1, 1.5, 0.05, &"use_time"),
		_tunable(&"buffer", skill_slot, 0.0, 0.4, 0.01),
	]
	for tunable in _tunables:
		_add_row(tunable)


## One tuned value: shown as `key`, stored in `target`'s `property` (the key itself if empty).
func _tunable(key: StringName, target: Object, low: float, high: float, step: float, property := &"") -> Dictionary:
	return {key = key, target = target, property = property if property else key, low = low, high = high, step = step}


func _add_row(tunable: Dictionary) -> void:
	var target: Object = tunable.target
	var property: StringName = tunable.property
	var name_label := Label.new()
	name_label.text = tunable.key
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value_label := Label.new()
	var head := HBoxContainer.new()
	head.add_child(name_label)
	head.add_child(value_label)
	var slider := HSlider.new()
	slider.min_value = tunable.low
	slider.max_value = tunable.high
	slider.step = tunable.step
	slider.allow_greater = true # a typed value may go past the slider's end
	slider.focus_mode = Control.FOCUS_NONE # arrow keys keep walking the player
	var start: float = target.get(property)
	slider.value = start
	value_label.text = _format(slider.value)
	slider.value_changed.connect(func(value: float) -> void:
		target.set(property, value)
		value_label.text = _format(value))
	_rows.add_child(head)
	_rows.add_child(slider)
	_sliders[tunable.key] = slider


func _cmd_hitfeel(args: PackedStringArray) -> String:
	if args.is_empty():
		visible = not visible
		return _listing()
	if args.size() != 2 or not args[1].is_valid_float():
		return "Usage: hitfeel [<name> <value>]"
	var key := StringName(args[0])
	if not _sliders.has(key):
		return "Unknown value '%s'. Type 'hitfeel' to list them." % key
	_sliders[key].value = args[1].to_float() # its value_changed sets the live value
	return "hitfeel %s %s" % [key, _format(_sliders[key].value)]


## Every value as a hitfeel command, ready to paste into the spec.
func _listing() -> String:
	var lines := PackedStringArray()
	for key: StringName in _sliders:
		lines.append("hitfeel %s %s" % [key, _format(_sliders[key].value)])
	return "\n".join(lines)


func _format(value: float) -> String:
	return str(snappedf(value, 0.001))
