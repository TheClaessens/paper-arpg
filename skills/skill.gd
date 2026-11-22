@tool
class_name Skill
extends Node3D
## A Skill (see GLOSSARY.md): something a Character activates, the player from a Skill slot.
## Each Skill is a node under its Character's Skills node and knows that Character (see
## `character`), so it acts from where the Character stands and hits what is hostile to the
## Character's Faction. try_activate() is the one way to set it off. The Skill runs its own
## Cooldown, and no Skill script can stop it. Subclasses do their work in _activate(). Each Skill
## script is a @tool, as this one is, so the editor shows its configuration warnings.

## Its Cooldown has run out: it can be activated again.
signal ready_again

## How a Skill aims. AROUND: activated where the Character stands. AUTO: toward the nearest
## hostile Hurtbox near Facing. AIMED: auto-aimed too, and on touch it can also be aimed by hand.
enum Aim { AROUND, AUTO, AIMED }

## The names of the Skill's numbers (see numbers()), as Modifiers and Snapshots know them.
const COOLDOWN := &"Cooldown"
const RANGE := &"Range"
const DAMAGE := &"Damage"
const KNOCKBACK := &"Knockback"
const STAGGER := &"Stagger"

## The shortest a Cooldown runs, in seconds, however short Modifiers make it: a held Skill
## activates at most 10 times a second.
const SHORTEST_COOLDOWN := 0.1

## The Skill's Skill tags, as set in its scene: what kind of Skill it is. Implied tags are
## left out here; the tag pass works them out (see TagPass.with_implied()).
@export var tags: Array[StringName] = []
## The Skill's name, as the player sees it.
@export var title := ""
## The Skill's picture on its Skill slot's button and in the Skill drawer.
@export var icon: Texture2D
## How the Skill aims.
@export var aim := Aim.AUTO
## Whether it lands on a spot (aimed by how far, too) rather than going a direction.
@export var aims_at_spot := false
## Whether holding its slot activates it again each time its Cooldown ends.
@export var repeats_while_held := false
## The Skill's Cooldown: how long after an activation starts before it can be activated again,
## from any slot. The only thing that limits how often it is activated, so every Skill needs one
## above 0. Modifiers can change it: the Cooldown that runs is the activation's Snapshot's, never
## shorter than SHORTEST_COOLDOWN.
@export var cooldown := 0.0:
	set(value):
		cooldown = value
		update_configuration_warnings()
## The Skill's Range: how far it reaches from the Character's centre, in world units.
@export var range := 1.0
## How much Health a hit takes away (its Damage).
@export var damage := 0.0
## How far a hit pushes an Enemy, in world units.
@export var knockback := 0.0
## How long a hit Enemy slides without chasing (its Stagger), in seconds.
@export var stagger := 0.0

## The Character that has the Skill, set by that Character when it is ready and by
## Character.add_skill(). The Skill hits only Hurtboxes hostile to the Character's Faction, as it
## is at each activation. The Skill's own _ready() can run before it is set (a node's children are
## ready before it), so a Skill script doesn't read it there. A Skill without one can't be activated.
var character: Character

## Seconds until the Skill can be activated again. The Skill runs this clock itself.
var cooldown_left := 0.0

var _cooldown_length := 0.0 # how long the running cooldown is in all


## Whether its cooldown has run out.
func is_ready() -> bool:
	return cooldown_left <= 0.0


## Starts a Cooldown `seconds` long, an activation's Snapshot's, but never shorter than
## SHORTEST_COOLDOWN.
func start_cooldown(seconds: float) -> void:
	cooldown_left = maxf(seconds, SHORTEST_COOLDOWN)
	_cooldown_length = cooldown_left


## Runs the cooldown on by `delta` seconds, emitting ready_again the moment it runs out.
func cool_down(delta: float) -> void:
	if is_ready():
		return
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if is_ready():
		ready_again.emit()


# The Cooldown runs on internal physics processing: a Skill script's own _physics_process()
# replaces a parent script's, but _notification() is called for every script that defines it,
# so no Skill script can stop the Cooldown, by accident or with set_physics_process(false).
func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		set_physics_process_internal(not Engine.is_editor_hint())
	elif what == NOTIFICATION_INTERNAL_PHYSICS_PROCESS:
		cool_down(get_physics_process_delta_time())


## How much of the cooldown is left: 1 just activated, 0 ready.
func cooldown_fraction() -> float:
	return cooldown_left / _cooldown_length if _cooldown_length > 0.0 else 0.0


## Warns in the editor about a Skill without a Cooldown: nothing would limit its activations.
func _get_configuration_warnings() -> PackedStringArray:
	return ["Every Skill needs a Cooldown above 0."] if cooldown <= 0.0 else []


## The Skill's numbers by name, for Modifiers to change. A Skill with numbers of its own adds
## them to these.
func numbers() -> Dictionary[StringName, float]:
	return {COOLDOWN: cooldown, RANGE: range, DAMAGE: damage, KNOCKBACK: knockback, STAGGER: stagger}


## Activates the Skill aimed at `aim` with the Character's `modifiers`, unless it is cooling
## down: makes the activation's Snapshot, starts its Cooldown (the Snapshot's, never shorter than
## SHORTEST_COOLDOWN), then does what the Skill does. Whether it activated. A Skill without a
## Character fails an assertion.
func try_activate(aim: Vector3, modifiers: Array[Modifier]) -> bool:
	assert(character != null, "%s has no Character: give it to one with Character.add_skill()." % name)
	if not is_ready():
		return false
	var made := snapshot(modifiers)
	start_cooldown(made.number(COOLDOWN))
	_activate(made, aim)
	return true


## The Skill as one activation sees it: a Snapshot of its tags and numbers with every one of
## `modifiers` that applies (see Snapshot.of()).
func snapshot(modifiers: Array[Modifier]) -> Snapshot:
	return Snapshot.of(tags, numbers(), modifiers)


## The number called `name` as it stands now with `modifiers`, outside any activation: for
## aiming, which follows the Modifiers as they come and go.
func number(name: StringName, modifiers: Array[Modifier]) -> float:
	return snapshot(modifiers).number(name)


## What the Skill does when activated, as `snapshot` says, aimed at `aim`: an offset on the
## ground from the Character. Its direction is where the Skill goes; for a Skill that lands on a
## spot, its length is how far. A Skill reads its numbers from `snapshot`, not from itself.
## Each Skill overrides it; try_activate() calls it.
func _activate(_snapshot: Snapshot, _aim: Vector3) -> void:
	pass


## What an activation aimed at `aim` would pick out, to ring it while aiming; null for most Skills.
func target_for(_aim: Vector3) -> Node3D:
	return null


## The layers of every Faction hostile to its Character's: where its hits look.
func hostile_mask() -> int:
	return Faction.hostile_mask(character.faction)


## Lands one activation's hits: each Hurtbox in `hits` is hit pushing along its direction (a
## unit vector on the ground) with the activation's `snapshot`; its Character reads what the hit
## does from that. The impact (screen shake, and a hitstop if `freezes`) plays once per call,
## however many it hit, and only if at least one hit landed, so a Skill whose hits come at once
## lands them in one call. For the Skills themselves.
func _land_hits(hits: Dictionary[Hurtbox, Vector3], snapshot: Snapshot, freezes := true) -> void:
	var landed := false
	for hurtbox in hits:
		if hurtbox.take_hit(hits[hurtbox], snapshot):
			landed = true
	if landed:
		HitFeedback.shared().play_impact(get_viewport(), freezes)
