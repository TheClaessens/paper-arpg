class_name SkillTag
## The Skill tags (see GLOSSARY.md), each declared once. Game code names a tag by its constant; a
## scene or a Modifier file writes its text, and tests/test_content.gd checks that text is in ALL.

const SPELL := &"Spell"
const ATTACK := &"Attack"
const MELEE := &"Melee"
const PROJECTILE := &"Projectile"
const FIRE := &"Fire"
## Only ever implied (see TagPass.IMPLIED_TAGS).
const ELEMENTAL := &"Elemental"
## Also a behaviour: a projectile with it passes through the first Hurtbox it hits.
const PIERCE := &"Pierce"

## Every Skill tag.
const ALL: Array[StringName] = [SPELL, ATTACK, MELEE, PROJECTILE, FIRE, ELEMENTAL, PIERCE]
