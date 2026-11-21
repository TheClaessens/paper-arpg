class_name Projectile
extends Area3D
## A shot flying straight along `direction` at its Snapshot's Speed until it has flown its
## Snapshot's Range or touches something. With Pierce among its Snapshot's tags it passes through
## the first Enemy it hits; a wall stops it always.
## It looks for walls and props (`world` layer) and Enemies (`enemy` layer), and reports an
## Enemy it touched with `hit_enemy`; the Skill that fired it decides what the hit does.

signal hit_enemy(enemy: Enemy)

## A unit direction on the ground.
var direction := Vector3.FORWARD
## The Snapshot of the activation that fired it: its Speed (world units per second), Range
## (world units) and whether it has Pierce. Set before it enters the tree.
var snapshot: Snapshot

var _flown := 0.0
var _enemies_hit: Array[Enemy] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var step := snapshot.number(Fireball.SPEED) * delta
	global_position += direction * step
	_flown += step
	if _flown >= snapshot.number(Skill.RANGE):
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if is_queued_for_deletion(): # touching two things in one frame hits only the first
		return
	var enemy := body as Enemy
	if not enemy: # a wall or a prop
		queue_free()
		return
	if enemy in _enemies_hit: # touching it again after knocking it ahead
		return
	_enemies_hit.append(enemy)
	hit_enemy.emit(enemy)
	var passes_through := 1 if &"Pierce" in snapshot.tags else 0
	if _enemies_hit.size() > passes_through:
		queue_free()
