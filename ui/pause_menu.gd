class_name PauseMenu
extends Control
## Pausing, and changing the Skill bar (see GLOSSARY.md). The corner button (top left, inside the
## safe area), Esc or Start pauses the game and shows the pause menu. Its "Skill bar" item opens
## the Skill bar view: choosing a slot opens the Skill drawer, and choosing a tile there puts
## that Skill in the slot, or empties it. The corner button then reads Back. Back, Esc, Start
## and the controller's B step out one level: the drawer, then the view, then the menu.

enum View { PLAY, MENU, SKILL_BAR }

const SkillTileScene := preload("res://ui/skill_tile.tscn")
const PAUSE_ICON := preload("res://assets/kenney/kenney_mobile-controls/Sprites/Icons/Large (2×)/icon_pause.png")
const BACK_ICON := preload("res://assets/kenney/kenney_mobile-controls/Sprites/Icons/Large (2×)/icon_arrow.png")
## How dark the Skill bar shows behind the pause menu.
const HUD_BEHIND_MENU := Color(0.45, 0.45, 0.45)

@export var player: Player
@export var hud: SkillBarHud
## Gap between the corner button and the safe area's top-left corner. 56 across clears the
## debug Console's 40-unit button, which sits right in that corner.
@export var corner_margin := Vector2(56.0, 14.0)

var _view := View.PLAY
var _drawer_slot := SkillBar.NONE # the slot the drawer is open for

@onready var _corner: Button = %Corner
@onready var _corner_icon: TextureRect = %CornerIcon
@onready var _dim: Control = %Dim
@onready var _menu: Control = %Menu
@onready var _skill_bar_item: Button = %SkillBarItem
@onready var _hint: Label = %Hint
@onready var _drawer: Control = %Drawer
@onready var _tiles: GridContainer = %Tiles


func _ready() -> void:
	_corner.pressed.connect(_on_corner_pressed)
	_skill_bar_item.pressed.connect(_show.bind(View.SKILL_BAR))
	(%Resume as Button).pressed.connect(close)
	hud.slot_chosen.connect(_on_slot_chosen)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_show(View.PLAY)


## Pauses the game and shows the pause menu.
func open() -> void:
	get_tree().paused = true
	_show(View.MENU)


## Lets the game run again.
func close() -> void:
	get_tree().paused = false
	_show(View.PLAY)


## Steps out one level: the drawer, then the Skill bar view, then the pause menu.
func back() -> void:
	if _drawer_slot != SkillBar.NONE:
		_close_drawer()
	elif _view == View.SKILL_BAR:
		_show(View.MENU)
	elif _view == View.MENU:
		close()


# Runs while paused (process_mode ALWAYS).
func _unhandled_input(event: InputEvent) -> void:
	if _view == View.PLAY:
		if event.is_action_pressed(&"pause"):
			get_viewport().set_input_as_handled()
			open()
	elif event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		back()


func _on_corner_pressed() -> void:
	if _view == View.PLAY:
		open()
	else:
		back()


func _show(view: View) -> void:
	_view = view
	_close_drawer()
	_dim.visible = view != View.PLAY
	_menu.visible = view == View.MENU
	_hint.visible = view == View.SKILL_BAR
	_corner_icon.texture = PAUSE_ICON if view == View.PLAY else BACK_ICON
	_corner_icon.flip_h = view != View.PLAY # the arrow points right; Back points left
	_corner.tooltip_text = "Pause" if view == View.PLAY else "Back"
	hud.set_editing(view == View.SKILL_BAR)
	hud.modulate = HUD_BEHIND_MENU if view == View.MENU else Color.WHITE
	if view == View.MENU:
		_skill_bar_item.grab_focus()
	elif view == View.SKILL_BAR:
		hud.focus_slot(0)


func _on_slot_chosen(slot: int) -> void:
	if slot == _drawer_slot:
		_close_drawer()
	else:
		_open_drawer(slot)


## Opens the Skill drawer for `slot`: an Empty tile, then every Skill the player has.
## Rebuilt each time, so it always matches the slot.
func _open_drawer(slot: int) -> void:
	_drawer_slot = slot
	hud.ring(slot)
	_hint.text = "Pick a Skill for this slot"
	for old in _tiles.get_children():
		_tiles.remove_child(old) # now, so the new tiles get the same names
		old.queue_free()
	var current := player.skill_bar.skill_in(slot)
	_add_tile("Empty", null, current == null)
	for skill in player.skills:
		_add_tile(skill.title, skill, current == skill)
	_drawer.show()


func _add_tile(title: String, skill: Skill, current: bool) -> void:
	var tile: SkillTile = SkillTileScene.instantiate()
	tile.name = title
	tile.tooltip_text = title
	_tiles.add_child(tile)
	tile.show_skill(skill.icon if skill else null, current)
	tile.pressed.connect(_choose.bind(skill))
	if current:
		tile.grab_focus()


func _choose(skill: Skill) -> void:
	var slot := _drawer_slot
	player.skill_bar.set_skill(slot, skill)
	_close_drawer()
	hud.focus_slot(slot)


func _close_drawer() -> void:
	if _drawer_slot != SkillBar.NONE and _view == View.SKILL_BAR:
		hud.focus_slot(_drawer_slot)
	_drawer_slot = SkillBar.NONE
	hud.ring(SkillBar.NONE)
	_drawer.hide()
	_hint.text = "Choose a slot to change its Skill"


func _layout() -> void:
	var corner := SafeArea.of(get_viewport()).position + corner_margin
	_corner.position = corner
	_hint.position = corner + Vector2(_corner.size.x + 20.0, (_corner.size.y - _hint.size.y) / 2.0)
	_drawer.position = corner + Vector2(0.0, _corner.size.y + 20.0)
