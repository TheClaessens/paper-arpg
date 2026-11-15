class_name Aggro
extends Area3D
## An Enemy's Aggro (see GLOSSARY.md). Notices the player within the Aggro radius, once.
## The sphere masks only the `player` physics layer, so the physics engine does the looking:
## anything it reports is the player.

## The player came within `radius`. Aggro never ends, so this fires once.
signal aggroed(target: Node3D)

## Shows every Aggro's ring on the ground. Toggled by the `aggro` console command.
static var rings_visible := false

## The Aggro radius, in world units.
@export var radius := 6.0

@onready var _sphere: SphereShape3D = ($Sphere as CollisionShape3D).shape
@onready var _ring: MeshInstance3D = $Ring


func _ready() -> void:
	_sphere.radius = radius
	var ring := _ring.mesh as TorusMesh
	ring.outer_radius = radius
	ring.inner_radius = radius - 0.08
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	_ring.visible = rings_visible


func _on_body_entered(body: Node3D) -> void:
	# Stop looking, so the player walking out and back in doesn't fire again. Physics is
	# mid-report here and won't let monitoring change, hence deferred.
	set_deferred(&"monitoring", false)
	aggroed.emit(body)
