extends Node
## Scratch scene for the prototype step in progress. Not a level.


func _ready() -> void:
	# TEMP: previews Standee animations until characters can move. Remove in the movement step.
	Console.register(&"anim", _cmd_anim, "TEMP anim <name>: play an animation on every Standee.")


func _exit_tree() -> void:
	Console.unregister(&"anim")


func _cmd_anim(args: PackedStringArray) -> String:
	if args.size() != 1:
		return "Usage: anim <name>"
	var standees := find_children("*", "Node3D").filter(func(node: Node) -> bool: return node is Standee)
	for standee: Standee in standees:
		if not standee.frames.has_animation(args[0]):
			return "No animation '%s'. Try idle or walk." % args[0]
		standee.play(args[0])
	return "%d Standees playing %s" % [standees.size(), args[0]]
