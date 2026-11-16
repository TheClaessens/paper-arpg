class_name SkillBarHud
extends Control
## The Skill bar on screen (see GLOSSARY.md): the main slot in the bottom right and the four
## small slots fanned around it, inside the phone's safe area. It follows the player's Skill bar.
## While the Skill bar is being changed (`editing`), each slot can be chosen; `slot_chosen` says
## which. Each slot shows its Skill's cooldown, presses in when used and flashes when ready. Sizes are in viewport units: on an iPhone 17 Pro, 1 pt is about 1.6 of them.

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

var _buttons: Array[SkillSlotButton] = []


func _ready() -> void:
	for slot in SkillBar.SLOTS:
		var button := get_node("Slot%d" % slot) as SkillSlotButton
		button.chosen.connect(slot_chosen.emit.bind(slot))
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


func _layout() -> void:
	var safe := SafeArea.of(get_viewport())
	var centre := safe.end - edge_margin - Vector2.ONE * main_size / 2.0
	_buttons[0].place(0, centre, main_size)
	# 0° is straight left of the main slot, 90° straight up.
	var start := 45.0 - fan_spread / 2.0
	for i in range(1, SkillBar.SLOTS):
		var angle := deg_to_rad(start + (i - 1) * fan_spread / 3.0)
		_buttons[i].place(i, centre - fan_radius * Vector2(cos(angle), sin(angle)), small_size)
