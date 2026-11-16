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


# Every Aggro registers the same static callback: the first registers the command and the rest
# do nothing. A static callback has no node to leave with, so the command outlives every Aggro.
func _enter_tree() -> void:
	Console.register(&"aggro", Aggro._toggle_rings, "Toggle drawing every Enemy's Aggro radius.")


func _ready() -> void:
	_sphere.radius = radius
	var ring := _ring.mesh as TorusMesh
	ring.outer_radius = radius
	ring.inner_radius = radius - 0.08
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	_ring.visible = rings_visible


static func _toggle_rings(_args: PackedStringArray) -> String:
	rings_visible = not rings_visible
	return "aggro %s" % ("on" if rings_visible else "off")


func _on_body_entered(body: Node3D) -> void:
	# Stop looking, so the player walking out and back in doesn't fire again. Physics is
	# mid-report here and won't let monitoring change, hence deferred.
	set_deferred(&"monitoring", false)
	aggroed.emit(body)
