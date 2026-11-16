class_name SkillBarHud
extends Control
## The Skill bar on screen (see GLOSSARY.md): the main slot in the bottom right and the four
## small slots fanned around it, inside the phone's safe area. It follows the player's Skill bar.
## While the Skill bar is being changed (`editing`), each slot can be chosen; `slot_chosen` says
## which. Each slot shows its Skill's cooldown, presses in when used and flashes when ready.
##
## On touch, tapping a slot uses it (auto-aimed). An aimed Skill can instead be dragged off its
## slot: the Player shows where it would go, and lifting the thumb uses it there. Lifting over the
## cancel zone cancels it: back on the slot, or on a cancel button, switched with `aim cancel`
## until a playtest picks one. Sizes are in viewport units: on an iPhone 17 Pro, 1 pt is about 1.6 of them.

signal slot_chosen(slot: int)

enum CancelStyle { SLOT, BUTTON }

@export var player: Player
## Diameter of the main slot and of the small slots.
@export var main_size := 136.0
@export var small_size := 88.0
## How far the small slots sit from the main slot's centre.
@export var fan_radius := 190.0
## The angle the four small slots spread over, centred on up-and-left.
@export_range(60.0, 130.0, 5.0, "suffix:°") var fan_spread := 110.0
## Gap between the main slot and the safe area's right and bottom edges.
@export var edge_margin := Vector2(26.0, 22.0)
## How far a thumb drags off a slot before it aims (closer, the lift is a tap).
@export var drag_deadzone := 22.0
## How far a thumb drags to aim a spot Skill its whole Range.
@export var drag_full_range := 177.0
## How a drag-aimed Skill is cancelled. Temporary: switched with the `aim` console command.
@export var cancel_style := CancelStyle.SLOT

var _buttons: Array[SkillSlotButton] = []
var _aiming_slot := SkillBar.NONE # the slot whose Skill is being dragged
var _aimed := false # the drag has left the deadzone, so lifting is no longer a tap
var _left_slot := false # the thumb has been off the slot, so coming back onto it cancels

@onready var _cancel_button: Control = $CancelButton


func _enter_tree() -> void:
	Console.register(&"aim", _cmd_aim, "aim cancel slot|button: lift on the slot, or on a cancel button, to cancel a dragged aim.")


func _ready() -> void:
	for slot in SkillBar.SLOTS:
		var button := get_node("Slot%d" % slot) as SkillSlotButton
		button.chosen.connect(slot_chosen.emit.bind(slot))
		button.touch_started.connect(_on_touch_started.bind(slot))
		button.touch_moved.connect(_on_touch_moved.bind(slot))
		button.touch_ended.connect(_on_touch_ended.bind(slot))
		button.show_skill(player.skill_bar.skill_in(slot))
		_buttons.append(button)
	player.skill_bar.changed.connect(_on_slot_changed)
	player.skill_bar.slot_used.connect(func(slot: int) -> void: _buttons[slot].press_in())
	player.skill_bar.ready_again.connect(_on_ready_again)
	get_viewport().size_changed.connect(_layout)
	_layout()


## While on, each slot can be chosen instead of used.
func set_editing(on: bool) -> void:
	for button in _buttons:
		button.set_editing(on)


## Rings `slot` as the one being changed; SkillBar.NONE rings none.
func ring(slot: int) -> void:
	for i in _buttons.size():
		_buttons[i].set_ringed(i == slot)


func focus_slot(slot: int) -> void:
	_buttons[slot].focus()


func _on_slot_changed(slot: int, skill: Skill) -> void:
	_buttons[slot].show_skill(skill)


## Flashes every slot holding `skill`.
func _on_ready_again(skill: Skill) -> void:
	for slot in _buttons.size():
		if player.skill_bar.skill_in(slot) == skill:
			_buttons[slot].flash()


func _cmd_aim(args: PackedStringArray) -> String:
	if args.size() != 2 or args[0] != "cancel" or args[1] not in ["slot", "button"]:
		return "Usage: aim cancel slot|button"
	cancel_style = CancelStyle.SLOT if args[1] == "slot" else CancelStyle.BUTTON
	return "aim cancel %s" % args[1]


func _on_touch_started(slot: int) -> void:
	var skill := player.skill_bar.skill_in(slot)
	if skill == null or skill.cooldown_left > 0.0:
		return
	if skill.aim == Skill.Aim.AIMED:
		_aiming_slot = slot # used when the thumb lifts
		_aimed = false
		_left_slot = false
	else:
		player.skill_bar.press(slot)


func _on_touch_moved(at: Vector2, slot: int) -> void:
	if slot != _aiming_slot:
		return
	var drag := at - _buttons[slot].centre()
	_aimed = _aimed or drag.length() > drag_deadzone
	_left_slot = _left_slot or not _buttons[slot].covers(at)
	_cancel_button.visible = _aimed and cancel_style == CancelStyle.BUTTON
	if not _aimed:
		return
	var cancelling := _over_cancel(slot, at)
	_cancel_button.modulate = Color(1.0, 0.45, 0.4) if cancelling else Color.WHITE
	var skill := player.skill_bar.skill_in(slot)
	player.show_aim(skill, player.aim_from_drag(skill, drag, drag_full_range), cancelling)


func _on_touch_ended(at: Vector2, slot: int) -> void:
	if slot != _aiming_slot:
		return
	_aiming_slot = SkillBar.NONE
	player.hide_aim()
	_cancel_button.hide()
	var skill := player.skill_bar.skill_in(slot)
	if get_tree().paused or skill == null:
		return
	if not _aimed:
		player.skill_bar.press(slot) # a tap: auto-aimed
	elif not _over_cancel(slot, at):
		var drag := at - _buttons[slot].centre()
		player.skill_bar.press(slot, player.aim_from_drag(skill, drag, drag_full_range))


## Whether a thumb at `at`, dragging `slot`, is over the cancel zone. The slot only cancels once
## the thumb has left it and come back, so a short aim that stays on the slot still counts.
func _over_cancel(slot: int, at: Vector2) -> bool:
	if cancel_style == CancelStyle.BUTTON:
		return _cancel_button.get_global_rect().grow(12.0).has_point(at)
	return _left_slot and _buttons[slot].covers(at)


func _layout() -> void:
	var safe := SafeArea.of(get_viewport())
	# The cancel button sits in the top right, away from the Skill bar.
	_cancel_button.position = Vector2(safe.end.x - edge_margin.x - _cancel_button.size.x, safe.position.y + edge_margin.y)
	var centre := safe.end - edge_margin - Vector2.ONE * main_size / 2.0
	_buttons[0].place(centre, main_size)
	# 0° is straight left of the main slot, 90° straight up.
	var start := 45.0 - fan_spread / 2.0
	for i in range(1, SkillBar.SLOTS):
		var angle := deg_to_rad(start + (i - 1) * fan_spread / 3.0)
		_buttons[i].place(centre - fan_radius * Vector2(cos(angle), sin(angle)), small_size)
