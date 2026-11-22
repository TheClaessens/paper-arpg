class_name Character
extends CharacterBody3D
## A Character (see GLOSSARY.md): the player's hero or an Enemy. It holds its Faction, its
## Modifiers and its Skills, and wires its components: its Health shows on its Health bar, and
## a hit on its Hurtbox lowers its Health, starts its Stagger and flashes and squashes its
## Standee. Wiring and identity only: Player and Enemy decide where it walks and what it
## activates. Without a Hurtbox it can't be hit; without a Stagger it is never staggered. Its
## Faction moves its Hurtbox and its Skills; its body's collision layers and its Aggro are its
## scene's.
## A script that extends it and has _ready() calls super() first: a subclass's _ready()
## replaces this one.

## Its Faction: its Hurtbox goes on that Faction's layer, and its Skills hit only Hurtboxes
## hostile to it. The Enemies' unless its scene says otherwise, as the player's scene does.
@export var faction := Faction.Id.ENEMIES
## Its Modifiers: every activation of its Skills is made with them.
@export var modifiers: Array[Modifier] = []

## The Skills it has: every Skill under its Skills node.
var skills: Array[Skill]:
	get:
		var found: Array[Skill] = []
		for child in $Skills.get_children():
			if child is Skill:
				found.append(child as Skill)
		return found

## How much more Damage it can take.
@onready var health: Health = $Health
## Shows its Health while it is below the maximum.
@onready var health_bar: HealthBar = $HealthBar
## The part of it that Skills hit, or null: then it can't be hit.
@onready var hurtbox: Hurtbox = get_node_or_null(^"Hurtbox")
@onready var _stagger: Stagger = get_node_or_null(^"Stagger") # null: never staggered
@onready var _standee: Standee = $Standee


func _ready() -> void:
	health.changed.connect(health_bar.show_health)
	if hurtbox:
		hurtbox.collision_layer = Faction.layer(faction)
		hurtbox.hit_taken.connect(_on_hit_taken)
	for skill in skills:
		skill.faction = faction # step 7 makes it skill.character = self


## Gives it `skill`: puts it under its Skills node, which stands where it stands and comes before
## whatever activates its Skills, and hands it its Faction. Before or after it enters the tree.
func add_skill(skill: Skill) -> void:
	$Skills.add_child(skill)
	skill.faction = faction # step 7 makes it skill.character = self


## Slides with its Stagger while it is staggered, and says whether it is: a staggered Character
## doesn't walk that frame. A frame the world is frozen in moves nothing, and the slide ends at
## rest. Enemy calls it first in _physics_process(); the player has no Stagger.
func _slide(delta: float) -> bool:
	if _stagger == null or not _stagger.is_active():
		return false
	velocity = _stagger.next_velocity(delta)
	if delta > 0.0: # not in a frozen frame, where move_and_slide() would only push it out of what presses on it
		move_and_slide()
	if not _stagger.is_active():
		velocity = Vector3.ZERO
	return true


# A hit on its Hurtbox, pushing along `direction` (a unit vector on the ground): the one place a
# hit lands on a Character. Damage first, then the Stagger, then the Standee.
func _on_hit_taken(direction: Vector3, snapshot: Snapshot) -> void:
	health.damage(snapshot.number(Skill.DAMAGE))
	if _stagger:
		_stagger.start(direction * snapshot.number(Skill.KNOCKBACK), snapshot.number(Skill.STAGGER))
	var feedback := HitFeedback.shared()
	_standee.flash(feedback.flash)
	_standee.squash(feedback.squash)
