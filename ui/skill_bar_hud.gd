class_name SkillBarHud
extends Control
## The Skill bar on screen (see GLOSSARY.md): the main slot in the bottom right and the four
## small slots fanned around it, inside the phone's safe area. It follows the player's Skill bar.
## While the Skill bar is being changed (`editing`), each slot can be chosen; `slot_chosen` says
## which. Each slot shows its Skill's cooldown, presses in when used and flashes when ready.
##
## On touch, tapping a slot uses it (auto-aimed). Holding a Skill that repeats while held (the
## Attack) keeps using it, and dragging steers it. An aimed Skill can instead be dragged off its
## slot: the Player shows where it would go, and lifting the thumb uses it there. Dragging back
## onto the slot and lifting there cancels it. Sizes are in viewport units: on an iPhone 17 Pro, 1 pt is about 1.6 of them.

signal slot_chosen(slot: int)

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
## How far a thumb may wander from where it landed and still be a tap; past it, the drag aims. Kept just above a
## thumb's wobble: the spot follows the drag from the player outward, so a larger one would
## leave the ground right around the player out of reach.
@export var drag_deadzone := 8.0
## How far a thumb drags to aim a spot Skill its whole Range.
@export var drag_full_range := 177.0

var _buttons: Array[SkillSlotButton] = []
var _aiming_slot := SkillBar.NONE # the slot whose Skill is being dragged
var _aimed := false # the drag has left the deadzone, so lifting is no longer a tap
var _left_slot := false # the thumb has been off the slot, so coming back onto it cancels
var _held_slot := SkillBar.NONE # the slot held down to repeat its Skill
var _landed := Vector2.ZERO # where the thumb landed; drags are measured from here


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


func _on_touch_started(at: Vector2, slot: int) -> void:
	_landed = at
	var skill := player.skill_bar.skill_in(slot)
	if skill == null or not skill.is_ready():
		return
	if skill.aim == Skill.Aim.AIMED:
		_aiming_slot = slot # used when the thumb lifts
		_aimed = false
		_left_slot = false
	else:
		player.skill_bar.press(slot)
		if skill.repeats_while_held:
			_held_slot = slot
			player.skill_bar.set_held(slot, true)


func _on_touch_moved(at: Vector2, slot: int) -> void:
	if slot == _held_slot:
		_steer(slot, at)
	if slot != _aiming_slot:
		return
	var drag := at - _landed
	_aimed = _aimed or drag.length() > drag_deadzone
	_left_slot = _left_slot or not _buttons[slot].covers(at)
	if not _aimed:
		return
	var cancelling := _over_cancel(slot, at)
	var skill := player.skill_bar.skill_in(slot)
	player.show_aim(skill, player.aim_from_drag(skill, drag, drag_full_range), cancelling)


func _on_touch_ended(at: Vector2, slot: int) -> void:
	if slot == _held_slot:
		_held_slot = SkillBar.NONE
		player.skill_bar.set_held(slot, false)
		player.hide_aim()
	if slot != _aiming_slot:
		return
	_aiming_slot = SkillBar.NONE
	player.hide_aim()
	var skill := player.skill_bar.skill_in(slot)
	if get_tree().paused or skill == null:
		return
	if not _aimed:
		player.skill_bar.press(slot) # a tap: auto-aimed
	elif not _over_cancel(slot, at):
		player.skill_bar.press(slot, player.aim_from_drag(skill, at - _landed, drag_full_range))


## Steers a held slot's repeats along the drag, showing where they go; inside the deadzone
## they are auto-aimed again.
func _steer(slot: int, at: Vector2) -> void:
	var drag := at - _landed
	if drag.length() <= drag_deadzone:
		player.skill_bar.set_held(slot, true)
		player.hide_aim()
		return
	var skill := player.skill_bar.skill_in(slot)
	var aim := player.aim_from_drag(skill, drag, drag_full_range)
	player.skill_bar.set_held(slot, true, aim)
	player.show_aim(skill, aim, false)


## Whether a thumb at `at`, dragging `slot`, would cancel: back on the slot after leaving it.
## A short aim that never left the slot still counts.
func _over_cancel(slot: int, at: Vector2) -> bool:
	return _left_slot and _buttons[slot].covers(at)


func _layout() -> void:
	var safe := SafeArea.of(get_viewport())
	var centre := safe.end - edge_margin - Vector2.ONE * main_size / 2.0
	_buttons[0].place(centre, main_size)
	# 0° is straight left of the main slot, 90° straight up.
	var start := 45.0 - fan_spread / 2.0
	for i in range(1, SkillBar.SLOTS):
		var angle := deg_to_rad(start + (i - 1) * fan_spread / 3.0)
		_buttons[i].place(centre - fan_radius * Vector2(cos(angle), sin(angle)), small_size)
