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


func _ready() -> void:
	health.changed.connect(health_bar.show_health)
	if hurtbox:
		hurtbox.collision_layer = Faction.layer(faction)
	for skill in skills:
		skill.faction = faction # step 7 makes it skill.character = self


## Gives it `skill`: puts it under its Skills node, which stands where it stands and comes before
## whatever activates its Skills, and hands it its Faction. Before or after it enters the tree.
func add_skill(skill: Skill) -> void:
	$Skills.add_child(skill)
	skill.faction = faction # step 7 makes it skill.character = self
