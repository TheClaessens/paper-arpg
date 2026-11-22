class_name Projectile
extends Area3D
## A shot flying straight along `direction` at its Snapshot's Projectile speed until it has flown its
## Snapshot's Range or touches something. With Pierce among its Snapshot's tags it passes through
## the first Hurtbox it hits; a wall stops it always.
## It looks for walls and props on the `world` layer, and for Hurtboxes on the layers the Skill
## that fired it adds to its mask (the ones hostile to the Faction of the Character that threw it). It reports a Hurtbox it touched with
## `hit`; that Skill decides what the hit does.

signal hit(hurtbox: Hurtbox)

## A unit direction on the ground.
var direction := Vector3.FORWARD
## The Snapshot of the activation that fired it: its Projectile speed (world units per second), Range
## (world units) and whether it has Pierce. Set before it enters the tree.
var snapshot: Snapshot

var _flown := 0.0
var _hurtboxes_hit: Array[Hurtbox] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	var step := snapshot.number(Fireball.PROJECTILE_SPEED) * delta
	global_position += direction * step
	_flown += step
	if _flown >= snapshot.number(Skill.RANGE):
		queue_free()


## A wall or a prop: it stops the shot.
func _on_body_entered(_body: Node3D) -> void:
	queue_free()


func _on_area_entered(area: Area3D) -> void:
	if is_queued_for_deletion(): # touching two things in one frame hits only the first
		return
	var hurtbox := area as Hurtbox
	if not hurtbox or hurtbox in _hurtboxes_hit: # touching it again after knocking it ahead
		return
	_hurtboxes_hit.append(hurtbox)
	hit.emit(hurtbox)
	var passes_through := 1 if SkillTag.PIERCE in snapshot.tags else 0
	if _hurtboxes_hit.size() > passes_through:
		queue_free()
