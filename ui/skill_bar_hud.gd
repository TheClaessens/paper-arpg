class_name SkillBarHud
extends Control
## The Skill bar on screen (see GLOSSARY.md): the main slot in the bottom right and the four
## small slots fanned around it, inside the phone's safe area. It follows the player's Skill bar.
## While the Skill bar is being changed (`editing`), each slot can be chosen; `slot_chosen` says
## which. Each slot shows its Skill's cooldown, presses in when activated and flashes when ready.
##
## On touch, tapping a slot activates it (auto-aimed). Holding a Skill that repeats while held
## (the Attack) keeps activating it, and dragging steers it. A Skill whose Aim mode waits for the
## lift can instead be dragged off its slot: the Player shows where it would go, and lifting the
## thumb activates it there. Dragging back onto the slot and lifting there cancels it. A thumb
## taken away without lifting (the app losing focus, or the system cancelling the touch) ends its
## hold and its aim, and activates nothing. So does a change of the slot's Skill under the thumb.
## Sizes are in viewport units: on an iPhone 17 Pro, 1 pt is about 1.6 of them.

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
## How far a thumb may wander from where it landed and still be a tap; past it, the drag aims.
## Kept just above a thumb's wobble: the spot follows the drag from the player outward, so a
## larger one would leave the ground right around the player out of reach.
@export var drag_deadzone := 8.0
## How far a thumb drags to aim a spot Skill its whole Range.
@export var drag_full_range := 177.0

var _buttons: Array[SkillSlotButton] = []
var _aiming_slot := SkillBar.NONE # the slot whose Skill is being dragged
var _aimed := false # the drag has left the deadzone, so lifting is no longer a tap
var _left_slot := false # the thumb has been off the slot, so coming back onto it cancels
var _holding: Array[bool] = [] # per slot: its thumb holds it down to repeat its Skill
var _landed: Array[Vector2] = [] # where each slot's thumb landed; its drags are measured from here


func _enter_tree() -> void:
	Console.register(&"touch", _cmd_touch, "touch <1-5> [<dx> <dy>]: a finger lands on a Skill slot, moves by the offset and lifts (a tap without one).")


func _ready() -> void:
	_landed.resize(SkillBar.SLOTS)
	_holding.resize(SkillBar.SLOTS)
	for slot in SkillBar.SLOTS:
		var button := get_node("Slot%d" % slot) as SkillSlotButton
		button.chosen.connect(slot_chosen.emit.bind(slot))
		button.touch_started.connect(_on_touch_started.bind(slot))
		button.touch_moved.connect(_on_touch_moved.bind(slot))
		button.touch_ended.connect(_on_touch_ended.bind(slot))
		button.touch_lost.connect(_let_go.bind(slot))
		button.show_skill(player.skill_bar.skill_in(slot))
		_buttons.append(button)
	player.skill_bar.changed.connect(_on_slot_changed)
	player.skill_activated.connect(func(slot: int) -> void: _buttons[slot].press_in())
	get_viewport().size_changed.connect(_layout)
	_layout()


## While on, each slot can be chosen instead of activated.
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
	_let_go(slot)


func _cmd_touch(args: PackedStringArray) -> String:
	var dragged := args.size() == 3 and args[1].is_valid_float() and args[2].is_valid_float()
	if not (args.size() == 1 or dragged) or not args[0].is_valid_int() or args[0].to_int() not in range(1, SkillBar.SLOTS + 1):
		return "Usage: touch <1-5> [<dx> <dy>]"
	var slot := args[0].to_int() - 1
	var at := _buttons[slot].centre()
	var to := at + (Vector2(args[1].to_float(), args[2].to_float()) if dragged else Vector2.ZERO)
	# The same signals a real finger sends.
	_buttons[slot].touch_started.emit(at)
	if dragged:
		_buttons[slot].touch_moved.emit(to)
	_buttons[slot].touch_ended.emit(to)
	return "touch %d by %s %s" % [slot + 1, args[1], args[2]] if dragged else "touch %d" % (slot + 1)


func _on_touch_started(at: Vector2, slot: int) -> void:
	_landed[slot] = at
	var skill := player.skill_bar.skill_in(slot)
	if skill == null or not skill.is_ready():
		return
	if skill.aim_mode.waits_for_lift:
		if _aiming_slot == SkillBar.NONE: # one aim at a time: the first thumb keeps it
			_aiming_slot = slot # activated when the thumb lifts
			_aimed = false
			_left_slot = false
	else:
		player.skill_bar.press(slot)
		if skill.aim_mode.repeats_while_held:
			_holding[slot] = true
			player.skill_bar.set_held(slot, true)


func _on_touch_moved(at: Vector2, slot: int) -> void:
	if _holding[slot]:
		_steer(slot, at)
	if slot != _aiming_slot:
		return
	var drag := at - _landed[slot]
	_aimed = _aimed or drag.length() > drag_deadzone
	_left_slot = _left_slot or not _buttons[slot].covers(at)
	if not _aimed:
		return
	var cancelling := _over_cancel(slot, at)
	var skill := player.skill_bar.skill_in(slot)
	player.show_aim(skill, player.aim_from_drag(skill, drag, drag_full_range), cancelling)


## The thumb on `slot` is gone without lifting, or its Skill changed under it: its hold and its
## aim end, and nothing is activated. A lift runs it first, then activates the aim it ended.
func _let_go(slot: int) -> void:
	if _holding[slot]:
		_holding[slot] = false
		player.skill_bar.set_held(slot, false)
		player.hide_aim()
	if slot == _aiming_slot:
		_aiming_slot = SkillBar.NONE
		player.hide_aim()


func _on_touch_ended(at: Vector2, slot: int) -> void:
	var aiming := slot == _aiming_slot
	_let_go(slot)
	var skill := player.skill_bar.skill_in(slot)
	if not aiming or get_tree().paused or skill == null:
		return
	var drag := at - _landed[slot]
	if not _aimed or (not _left_slot and drag.is_zero_approx()):
		# A tap, or a drag that never left the slot and came back to where it began: auto-aimed.
		player.skill_bar.press(slot)
	elif not _over_cancel(slot, at):
		player.skill_bar.press(slot, player.aim_from_drag(skill, drag, drag_full_range))


## Steers a held slot's repeats along the drag, showing where they go; inside the deadzone
## they are auto-aimed again.
func _steer(slot: int, at: Vector2) -> void:
	var drag := at - _landed[slot]
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
