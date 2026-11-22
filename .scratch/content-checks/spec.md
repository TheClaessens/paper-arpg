# Content checks

Status: ready-for-agent

The open rules below follow their recommended answers; the developer confirms them when reading this step's PR.

A Skill scene or a Modifier file that names a Skill tag or a number that doesn't exist fails `tools/check.sh`, instead of loading and silently doing nothing. Step 2 of the future-proofing plan (`.scratch/future-proofing-review/plan.md`); its branch starts from step 1's, `number-bounds` (plan.md, decision 8). Sources: `.scratch/future-proofing-review/analysis/rules-engine.md` §1, §7, "Missed by both reports" and WP-2, checked against the code at `8797660`. Nothing changes in play.

## What changes and why

A **Modifier** saved as its own `.tres` (a *Modifier file* below) names **Skill tags** and numbers as text, and so does a **Skill**'s scene for its tags. A file that misspells one loads and applies to nothing: a filter on `Projectiles`, a number change on `Cooldwon`, a tag change adding `Peirce`. The **Snapshot**'s why line then reads "missed, not Projectiles", like any fair miss (`tag_pass.gd:90`). With two proof Modifiers you would notice; among a few hundred from gear and talents you would not.

After this step:

- Every Skill tag is declared once, in `skills/skill_tag.gd`. Game code names a tag by its constant; scenes and Modifier files keep writing text, and a test checks that text against the list. At run time a tag is still a `StringName`.
- `tests/test_content.gd` reads every Skill in every scene and every Modifier file, and fails on, among other faults, a tag that isn't declared, a number no Skill has, an empty effect, a tag change that can never act, or a Cooldown of 0 or less.
- `tools/load_all.gd` loads `.tres` files too, so a Modifier file nothing refers to yet (as gear and talent files will be) fails the check when it doesn't load.
- The conventions gain "Saved content": the ways a saved file goes wrong that no test can see (an enum saved as its number, a default a file relies on, a renamed export).
- A number's name means one thing on every Skill, because a Modifier file names a number without knowing which Skill has it. How fast Fireball's ball flies is called `Speed`, which a later attack speed or dash speed would share; it is renamed while no Modifier file names it (open rule 1).

Words: "game code" is what CLAUDE.md lists under Where code lives (`autoloads/ characters/ skills/ ui/ scenes/ props/ rendering/`). Tests and tools are not game code, and test files are not content.

## The rules

1. **Every Skill tag is declared once, in `skills/skill_tag.gd`**: one constant per tag, and `SkillTag.ALL` holding them all. A Skill's own tags, a Modifier file's filter, and each tag a tag change names are in `SkillTag.ALL`. In game code a tag is written as text only in `skill_tag.gd`. Tests may write any tag as text, declared or not.
2. **A Skill lists no tag that another tag implies.** Fireball lists Fire and gets Elemental from `TagPass.IMPLIED_TAGS`. A Skill that listed Elemental itself could never lose it: no Modifier can change an implied tag (`tag_pass.gd:95-99`). (Open rule 2.)
3. **Every Skill's own Cooldown is above 0, in every scene it sits in**: its own, and a Character's that instances it and may override it. (Open rule 5.)
4. **Every effect of a Modifier file is filled in and names something that exists.** No effect is empty (a null breaks every activation the Modifier applies to). A number change names a number some Skill in some scene has. A tag change's `tag` is a declared tag that no other tag implies. A tag change that replaces has an `into` that is likewise declared and not implied; one that doesn't replace has no `into`. (Open rules 3 and 4.)
5. **An implied tag implies nothing further.** `TagPass.with_implied()` looks one level deep (`tag_pass.gd:59-67`), so a second level would be dropped without a word.
6. **Every scene and resource file loads.** `tools/load_all.gd` loads `.gd`, `.tscn` and `.tres` files, leaving out dot folders, `res://addons` and `res://assets`.
7. **A number's name means one thing on every Skill that has it.** Fireball's `Speed` becomes `Projectile speed` (open rule 1). Checked through rule 4: once renamed, a Modifier file on `Speed` names a number no Skill has.

Three more rules about saved files are conventions a test can't check; they are in Docs this reopens, "Saved content".

## Where tags and number names are written today

The complete set in game code, scenes and resources (`grep '&"'` over the game folders):

| Where | Written | After this step |
|---|---|---|
| `skills/attack/attack.tscn:18` | `tags = …([&"Attack", &"Melee"])` | text, checked (rules 1–2) |
| `skills/fireball/fireball.tscn:10` | `tags = …([&"Spell", &"Projectile", &"Fire"])` | text, checked |
| `skills/modifiers/pierce.tres:9` | tag change `tag = &"Pierce"` | text, checked (rule 4) |
| `skills/modifiers/pierce.tres:14` | `filter = …([&"Projectile"])` | text, checked (rule 1) |
| `skills/modifiers/spell_cooldown.tres:16` | `filter = …([&"Spell"])` | text, checked |
| `skills/modifiers/spell_cooldown.tres:9` | `number = &"Cooldown"` | text, checked (rule 4) |
| `skills/tag_pass.gd:14` | `&"Fire": [&"Elemental"]` | `SkillTag.FIRE: [SkillTag.ELEMENTAL]` |
| `skills/fireball/projectile.gd:48` | `&"Pierce" in snapshot.tags` | `SkillTag.PIERCE in snapshot.tags` |
| `skills/skill.gd:18-22` | `COOLDOWN`, `RANGE`, `DAMAGE`, `KNOCKBACK`, `STAGGER` | unchanged: the names' one place in code |
| `skills/attack/attack.gd:13` | `SWEEP := &"Sweep"` | unchanged |
| `skills/fireball/fireball.gd:18` | `SPEED := &"Speed"` | `PROJECTILE_SPEED := &"Projectile speed"` |
| `skills/fireball/projectile.gd:28` | `snapshot.number(Fireball.SPEED)` | `Fireball.PROJECTILE_SPEED` |
| `tests/test_projectile.gd:15`, `:55` | `Fireball.SPEED` in hand-made Snapshots | `Fireball.PROJECTILE_SPEED` |

Not tags, so left alone: the console names `"pierce"` and `"spell-cooldown"` (`player.gd:21-23`), `title = "Attack"` (`attack.tscn:19`, the Skill's name), node names, and animation names. Tests write real tags as text in five files (`test_player`, `test_projectile`, `test_skill`, `test_skill_tags`, `test_snapshot`) and test-only ones (Holy, Chain, Cold) in two; they stay.

## The change, file by file

### `tools/load_all.gd` (ticket 01)

- Header (`:2-4`): loads every script, scene and `.tres` resource, outside dot folders, `addons/` and `assets/`. A resource fails on a parse error or a broken reference.
- `_initialize` (`:12`) walks `find_files("res://", ["gd", "tscn", "tres"])`. A `.tres` is loaded and not instantiated; `null` is a failure, as for the rest.
- `_find` (`:28-36`) becomes a static function, so the content test makes the same walk:

```gdscript
## Every file under `dir` whose extension is in `extensions`, leaving out dot folders and the
## vendored res://addons and res://assets. tests/test_content.gd makes the same walk, with its own extensions.
static func find_files(dir: String, extensions: PackedStringArray) -> PackedStringArray:
	...
		var path := dir.path_join(sub)
		if not sub.begins_with(".") and path not in ["res://addons", "res://assets"]:
	...
```

Today `_find` skips a folder named `addons` at any depth and walks `assets/`, which holds no `.gd`, `.tscn` or `.tres` (correcting the analysis, which says it leaves `assets/` out). Comparing whole paths skips only the two vendored folders.

What loading `.tres` brings in: seven files. Two SpriteFrames (`characters/standee/frames/`), a MeshLibrary (`scenes/dungeon_tiles.tres`), a NavigationMesh (`scenes/sandbox_navmesh.tres`), Hit feedback (`skills/hit_feedback.tres`) and the two Modifier files. Each already loads during a check run, through a scene, a `preload` in `player.gd:21-23`, or `HitFeedback.shared()` in tests. None runs game code when loaded: `HitFeedback`, `Modifier`, `NumberChange` and `TagChange` have no `_init` and no setters. So the change only catches a `.tres` nothing refers to.

`tools/check.sh`: the header (`:2-3`) and the step label (`:28`) say "script, scene and resource".

### `skills/skill_tag.gd`, new (ticket 02)

```gdscript
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
```

No `extends`, as `characters/faction.gd`. No test of its own: it holds constants, and the content test checks content against `ALL`.

### `skills/tag_pass.gd` (ticket 02)

`IMPLIED_TAGS` (`:13-15`) becomes `{SkillTag.FIRE: [SkillTag.ELEMENTAL]}`. Nothing else.

### `skills/fireball/projectile.gd` (tickets 02 and 04)

`:48` reads `SkillTag.PIERCE in snapshot.tags` (02). `:28` reads `Fireball.PROJECTILE_SPEED`, and the doc lines `:3` and `:14` say Projectile speed (04).

### `skills/fireball/fireball.gd` (ticket 04)

```gdscript
## The name of how fast the ball flies among the Skill's numbers (see GLOSSARY.md, Projectile speed).
const PROJECTILE_SPEED := &"Projectile speed"

## How fast the ball flies, in world units per second.
@export var projectile_speed := 12.0
```

`numbers()` (`:26`) adds `all[PROJECTILE_SPEED] = projectile_speed`; the doc line `:4` says "It flies at its Projectile speed". No scene sets `speed` (`fireball.tscn` relies on the default 12), so renaming the export loses nothing.

### `tests/test_content.gd`, new (ticket 03)

**How it finds files.** `const LoadAll := preload("res://tools/load_all.gd")`, then `LoadAll.find_files("res://", ["tscn", "tres"])`: the check's own walk, with no list of folders, so a new folder (a Level's, an item's) is covered the day it exists. It loads each file with `load()`:

- **`null`**: a problem, "doesn't load". Never skipped. The load step of `check.sh` has already failed on it, and GUT fails the test on the error Godot logs (below).
- **A `PackedScene`**: `instantiate()` (a `null` is "doesn't instantiate"). Every node of the instance, at any depth and the root included, that `is Skill` is checked *as that scene sets it*: instancing applies a scene's overrides to the scenes it holds, so the Attack in `player.tscn` is checked with `player.tscn`'s values, and again in `sandbox.tscn`. A Skill under a `Skills` node (step 6) is found the same way. Its `numbers()` keys join the list of every number some Skill has. The instance is then freed; it never enters the tree, so no `_ready` and no physics run.
- **A `Modifier`** (or a script extending it): kept, and checked once every scene has added its numbers.
- **Anything else** (SpriteFrames, MeshLibrary, NavigationMesh, Hit feedback): nothing to check.

Then `TagPass.IMPLIED_TAGS` is checked.

**Test-only Skills and Modifiers.** Other tests build theirs in code (`Skill.new()`, `RecordingSkill`, `TestSkill`, `Modifier.new()` with tags such as Holy, Chain and Cold). They never reach a file, so the walk never sees them and their tags need no declaring. The content test's own broken ones go straight to the problem functions, never through the walk.

Shape, which the implementer writes out:

```gdscript
func test_every_skill_and_modifier_file_is_well_made() -> void:
	var problems: Array[String] = []
	var numbers: Array[StringName] = [] # every number some Skill in some scene has
	var modifiers: Dictionary[String, Modifier] = {} # by path
	var skills_found := 0
	for path in LoadAll.find_files("res://", ["tscn", "tres"]):
		var resource := load(path)
		if resource == null: ...                      # "doesn't load"
		elif resource is PackedScene: ...             # instantiate, _skills_in(root), free
			# each problem: "%s%s: %s" % [path, place, problem], place being " › <path to the Skill>", or empty for the root
		elif resource is Modifier: ...                # modifiers[path] = resource as Modifier
	# then _modifier_problems for each Modifier file, and _implied_problems(TagPass.IMPLIED_TAGS)
	assert_gt(skills_found, 0, "found no Skill in any scene")
	assert_gt(modifiers.size(), 0, "found no Modifier file")
	assert_true(problems.is_empty(), "; ".join(problems))


## Each problem with `skill` as its scene sets it (rules 1–3), one line each.
func _skill_problems(skill: Skill) -> Array[String]
## Each problem with `modifier`, where `numbers` holds every number some Skill has (rules 1, 4).
func _modifier_problems(modifier: Modifier, numbers: Array[StringName]) -> Array[String]
## Each tag in `table` that is implied and implies more (rule 5).
func _implied_problems(table: Dictionary[StringName, Array]) -> Array[String]
## Every node of `node`'s tree, `node` included, that is a Skill.
func _skills_in(node: Node) -> Array[Skill]
```

- Problems are joined with `"; "` on one line: `check.sh` shows only GUT's `[Failed]` lines, and GUT prints an assert's message on that line, so every problem shows in the check's output.
- The two `assert_gt` lines keep a walk that finds nothing from passing.
- Each problem names the file, the place and the word: `res://characters/player/player.tscn › Attack: tag 'Meele' is not a Skill tag`. A Skill that is its scene's root has no place: `res://skills/fireball/fireball.tscn: tag 'Projectiles' is not a Skill tag`.
- "Implied" means: in any list of `TagPass.IMPLIED_TAGS.values()`, as `_why_skip` reads it.

**Typing and GUT.** `load()` returns `Resource`: test it with `is`, then cast with `as` before reading a property, so nothing is a Variant. `instantiate()` returns `Node`; the walk tests `is Skill` and casts. A typed dictionary's `keys()` and `values()` return untyped arrays: loop with a typed loop variable, as `tag_pass.gd:96` does. GUT's asserts take untyped arguments, so passing typed values needs no `@warning_ignore`. GUT 9.7.1 fails a test on any engine error or warning logged during it, push errors too (`failure_error_types`, `addons/gut/gut_config.gd:57`; `.gutconfig.json` doesn't change it): a file that doesn't load fails twice over, and so would a scene that logs a warning when instantiated (Needs a run).

### `tests/test_projectile.gd` (ticket 04)

`:15` and `:55`, as they stand after step 1: `Fireball.PROJECTILE_SPEED`.

## Saved content today

**Enums saved as numbers.** `fireball.tscn:8` saves `aim = 2` (`Skill.Aim.AIMED`); `spell_cooldown.tres:10` saves `kind = 1` (`NumberChange.Kind.INCREASED`). `player.tscn` saves `faction = 0` (`Faction.Id.PLAYER`); `TagChange.Kind` is exported but saved by no file today. All four fall under "only added to at the end".

**Defaults files rely on.** A file holds only the values written in it. Every other value is the script's default, so changing that default changes the file. `player.tscn:56` writes `max_health = 100.0`, equal to the default, so a file can hold one; but the files the editor has saved never do (`pierce.tres` has no `kind = 0`), which suggests it drops such a line when it resaves (unverified). Hence "in the same commit" in the convention below.

| Default | Relied on by (and through them, the scenes that instance them) |
|---|---|
| `Skill.aim` = `AUTO` | `attack.tscn`: Attack auto-aims only because of it |
| `Skill.aims_at_spot` = false | `attack.tscn`, `fireball.tscn` |
| `Skill.repeats_while_held` = false | `fireball.tscn` |
| `Attack.sweep` = 120 | `attack.tscn` |
| `Fireball.speed` = 12 | `fireball.tscn` |
| `TagChange.kind` = `ADD`, `into` empty | `pierce.tres`: it adds Pierce only because of them |
| `Modifier.number_changes`, `tag_changes` = empty | `pierce.tres`, `spell_cooldown.tres` |
| `HitFeedback` (all five) | `hit_feedback.tres` sets none: the defaults are the game's Hit feedback |
| `Character.faction` | `zombie.tscn` (`player.tscn` sets it since `.scratch/character/spec.md`) |
| `Character.modifiers` | `player.tscn`, `zombie.tscn` |
| `Enemy.reach_distance`, `resume_distance` | `zombie.tscn` |
| `Movement.speed`, `acceleration`, `deceleration` | `player.tscn` all three; `zombie.tscn` the last two (it sets speed 2.5) |
| `Aggro.radius` | `aggro.tscn`, and so `zombie.tscn` |
| `Standee.pixel_size`, `wobble_animation`, `wobble_angle`, `wobble_speed` | `standee.tscn`, and so `player.tscn`, `zombie.tscn` |
| `SkillBarHud`'s seven sizes, `PauseMenu.corner_margin`, `TouchStick.radius`, `follow` | their scenes in `ui/` |
| `PixelatedView.pixel_height` | `sandbox.tscn` |

Through instancing, `player.tscn` and `sandbox.tscn` carry the Skills' defaults too; they override nothing on a Skill. Nothing relies on `Skill.cooldown` (both Skills set it; rule 3 fails one that would) or `Health.max_health` (both Characters set it).

**What the convention asks of someone changing a default:** find the files above for it (the `.tscn` and `.tres` files that attach the script or a script extending it, without a line for the property, and the scenes that instance those without overriding it). Then write the old value into each that should keep it, in the same commit as the new default. Example: raising `Movement.speed` to 5 speeds up the player, whose scene relies on 4, and not the zombie, which sets 2.5; to keep the player at 4, `player.tscn`'s Movement gets `speed = 4.0` in that commit.

## Tests

Every check, and a broken file or scene that makes it fail. The implementer tries each by hand before committing, one at a time (revert with `git checkout -- <file>`; with the developer's editor open, reload it after), and lists them in the PR. Run the content test alone with `godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=test_content.gd -gexit`, then `tools/check.sh`. A break may fail other tests too (C1 fails `test_skill_tags.gd`, C10 the Pierce tests); what counts is the content test's own problem.

| # | Check (rule) | Break | Fails with |
|---|---|---|---|
| L1 | Every file loads (6) | Add `skills/modifiers/broken.tres`: `[gd_resource type="Resource" format=3]`, a blank line, `[resource]`, `script = ExtResource("1_missing")`. Delete it after. | `check.sh` at the load step: `FAILED TO LOAD: res://skills/modifiers/broken.tres`. The content test alone: "doesn't load", and GUT's unexpected error. |
| C1 | A Skill's own tag is declared (1) | `fireball.tscn:10`: `&"Projectile"` → `&"Projectiles"` | Three problems: `fireball.tscn`, `player.tscn › Fireball`, `sandbox.tscn › …/Player/Fireball` |
| C2 | …as a Character's scene sets it (1) | `player.tscn`, under the Attack node (`:69`): add `tags = Array[StringName]([&"Attack", &"Meele"])` | `player.tscn` and `sandbox.tscn`, not `attack.tscn` |
| C3 | No implied tag on a Skill (2) | `attack.tscn:18`: add `&"Elemental"` | "tag 'Elemental' is implied by another tag", three times |
| C4 | Cooldown above 0 (3) | `fireball.tscn`: delete `cooldown = 4.0` (`:9`); it then relies on the default 0 | Three problems |
| C5 | Filter tags declared (1) | `pierce.tres:14`: `&"Projectiles"` | `pierce.tres` |
| C6 | A number some Skill has (4) | `spell_cooldown.tres:9`: `&"Cooldwon"` | `spell_cooldown.tres` |
| C7 | No empty effect (4) | `spell_cooldown.tres:17`: `…([SubResource("halve_cooldown"), null])` | "has an empty effect" |
| C8 | A tag change's tag declared (1, 4) | `pierce.tres:9`: `&"Peirce"` | `pierce.tres` |
| C9 | …and not implied (4) | `pierce.tres:9`: `&"Elemental"` | `pierce.tres` |
| C10 | A replace has an `into` (4) | `pierce.tres`, in the `add_pierce` sub-resource: add `kind = 1` (REPLACE) | "replaces Pierce with nothing" |
| C11 | …declared and not implied (4) | C10 plus `into = &"Elemental"` | `pierce.tres` |
| C12 | No `into` without a replace (4) | `pierce.tres`, `add_pierce`: add `into = &"Fire"`, `kind` left at its default | `pierce.tres` |
| C13 | Implied tags one level deep (5) | `tag_pass.gd`, `IMPLIED_TAGS`: add `SkillTag.ELEMENTAL: [SkillTag.SPELL]` | `TagPass.IMPLIED_TAGS: Elemental …`; Fireball's Spell, now implied, shows too |
| C14 | The walk finds content | In the test, walk `["tscn"]` only; then `["tres"]` only | "found no Modifier file"; then "found no Skill in any scene" |
| C15 | Old number names close (7) | After ticket 04: `spell_cooldown.tres:9`: `&"Speed"` | "a number no Skill has" (before ticket 04 it passes) |

**Self-tests**, kept in the file so the problem functions can't quietly stop reporting (CODING_STANDARDS, "A test can fail"). Each builds one hand-made broken object holding one of each fault and asserts that exactly that many problems come back and that the lines say what is wrong, and none for a well-made one. A fourth builds a small tree with a Skill two nodes below the root and asserts `_skills_in` finds it:

- A Skill with tags `[&"Projectiles", SkillTag.ELEMENTAL]` and a Cooldown of 0: three problems. One with `[SkillTag.SPELL]` and a Cooldown of 1: none.
- A Modifier, checked against the numbers `[Skill.COOLDOWN]`, with nine problems: a filter on `&"Projectiles"`; number changes on `&"Cooldwon"` and a `null`; and tag changes adding `&"Peirce"`, adding Elemental, replacing Fire with no `into`, replacing Fire into Elemental, adding Pierce with an `into`, and a `null`. A Spell filter halving Cooldown (a More of −50), adding Melee and replacing Fire with Pierce: none.
- The table `{Fire: [Elemental], Elemental: [Spell]}`: one problem.

Unchanged: `test_skill.gd:43-49` (the editor's Cooldown warning; `@tool` stays) and every test that writes tags as text.

## Docs this reopens

**`docs/agents/godot-conventions.md:37`** (ticket 01). Was: "`tools/check.sh` loads every script and scene, then runs all tests; …". Becomes:

> `tools/check.sh` loads every script, scene and `.tres` resource (outside `addons/` and `assets/`), then runs all tests; it exits non-zero on any failure. The pre-commit hook runs it once enabled per clone with `git config core.hooksPath .githooks`.

**`docs/agents/godot-conventions.md`, a new section after "Scenes live in the editor"** (ticket 03 writes it; ticket 04 adds the last bullet):

> ## Saved content
>
> A scene or resource file holds only the values written in it, an enum as its number; every other value is the script's default. Both the saved numbers and the script's defaults are content, as much as the code:
>
> - **An exported enum is only added to at the end.** `fireball.tscn` saves `aim = 2` and `spell_cooldown.tres` saves `kind = 1`; inserting, reordering or removing an entry changes what every such file says. Exported today: `Skill.Aim`, `NumberChange.Kind`, `TagChange.Kind`, `Faction.Id`.
> - **A default is part of every file that doesn't set it.** Attack auto-aims only because `Skill.aim` defaults to `AUTO`; `pierce.tres` adds Pierce only because `TagChange.kind` defaults to `ADD`. Before changing a default, find the `.tscn` and `.tres` files that attach the script, or a script extending it, without a line for the property, and the scenes that instance those without overriding it. Write the old value into each one that should keep it, in the same commit as the new default.
> - **Renaming or removing an export** leaves every file that sets it with a line the script no longer has. Change those files in the same commit.
> - **A Skill tag is declared in `skills/skill_tag.gd`** before a scene or Modifier file writes it, and game code names it by its `SkillTag` constant, never as text.
> - **A number's name means one thing on every Skill that has it**, because a Modifier file names a number without knowing which Skill has it. Name a number for what it is: how fast Fireball's ball flies is `Projectile speed`, so a Modifier on it can't change another Skill's unrelated speed.
>
> `tests/test_content.gd` reads every Skill in every scene and every Modifier file, and fails on, among other faults, a tag that isn't declared, a number no Skill has, an empty effect and a Cooldown of 0 or less, among other faults. It can't see enums, defaults or a renamed export: keep those by hand. A renamed number or tag it does catch, in a Modifier file that still names the old one.

**`.scratch/skill-tags/spec.md:49`** (ticket 04). Was: "**Number names** are constants: `Skill.COOLDOWN`, `RANGE`, `KNOCKBACK`, `STAGGER`, `Fireball.SPEED`, `Attack.SWEEP`. A Modifier's `.tres` names them as text." Becomes (it also gains `DAMAGE`, added by factions-health):

> - **Number names** are constants: `Skill.COOLDOWN`, `RANGE`, `DAMAGE`, `KNOCKBACK`, `STAGGER`, `Fireball.PROJECTILE_SPEED`, `Attack.SWEEP`. A Modifier's `.tres` names them as text, so a number's name means one thing on every Skill that has it: how fast Fireball's ball flies is `Projectile speed`, not `Speed` (reopened by `.scratch/content-checks/spec.md`).

**`.scratch/skill-tags/spec.md:65`** (ticket 04; rules-engine "Missed by both reports" 7). Was: "What the Damage types are, how many, and their order (with damage)." Becomes:

> - What the Damage types are, how many, and their order (with damage). Whatever they are, `Damage` keeps meaning all of a hit's Damage, so a Modifier file written on Damage before then keeps its meaning.

**`GLOSSARY.md`**, a new entry after Range (`:119-121`) (ticket 04, if open rule 1 agrees):

> **Projectile speed**:
> How fast a Skill's projectile flies, such as Fireball's ball. A number of the Skill that Modifiers change, named the same on every Skill that has a projectile, so one Modifier can speed them all.
> _Avoid_: Speed, ball speed, velocity

No ADR is reopened.

## Seams

The steps stack (plan.md, decision 8); this branch starts from step 1's. Lines this step touches in files other steps also touch:

- `skills/fireball/projectile.gd`: `:3`, `:14` (doc), `:28` (`Fireball.PROJECTILE_SPEED`), `:48` (`SkillTag.PIERCE`). `ball-in-world` (step 10) rewrites `_physics_process` and `_on_area_entered` and keeps both names.
- `skills/fireball/fireball.gd`: `:4` (doc), `:17-21` (constant and export), `:26` (`numbers()`). `ball-in-world` rewrites `_activate` (`:30-39`), not these.
- `tests/test_projectile.gd`: `:15`, `:55`, as step 1 leaves them (it may change how a Snapshot is made). `ball-in-world` rewrites the file; whichever lands second writes `Fireball.PROJECTILE_SPEED`.
- `skills/tag_pass.gd:12-15`; `tools/load_all.gd` (the whole file); `tools/check.sh:2-3`, `:28`. No other step touches these.
- `docs/agents/godot-conventions.md:37` and the new section after "Scenes live in the editor"; `GLOSSARY.md` after Range; `.scratch/skill-tags/spec.md:49`, `:65`.
- Not touched: `skills/skill.gd` (step 1's Cooldown line; `@tool` stays), `skills/snapshot.gd` (steps 1, 4), `characters/` (steps 6–8), `ui/` (step 3).

What the content test assumes of later steps:

- Skills are nodes in scenes, found at any depth: the `Skills` node of step 6 changes nothing. A Skill a Character made in code at `_ready` would not be seen.
- It reads Modifier files from disk, never a Character's `modifiers` list: that list moving to `Character` (step 6) changes nothing.
- It calls `Skill.numbers()` and reads `tags` and `cooldown` on Skills outside the tree with no Character. A step that makes those need the tree or the Character (step 7 gives a Skill its Character) keeps them working there, or changes the test.
- After this step, game code names Pierce `SkillTag.PIERCE` and how fast the ball flies `Fireball.PROJECTILE_SPEED`. A spec written beside this one that quotes `&"Pierce"` or `Fireball.SPEED` follows.
- Step 1's shortest Cooldown and rule 3: open rule 5.

## Open rules for the developer

1. **How fast the ball flies: its name, and a glossary entry.** plan.md's working answer renames `&"Speed"` so a Modifier on it can't change a later Skill's unrelated speed: an attack speed (the glossary's Cooldown entry names one), a dash's, a Character's walk. No Modifier file names it yet, so the rename is free now.
   - **`Projectile speed`** *(recommended)*: says what moves, and is shared by every Skill that throws or shoots something (the glossary's bow), so one "projectiles fly faster" Modifier serves them all. It matches the Projectile tag and the usual term (Path of Exile's, quoted in `.scratch/skill-tags/research-skill-systems.md:46`).
   - `Flight speed`: shorter, but no glossary word, and it fits a leap or a flying Enemy as well.
   - `Ball speed`: Fireball's alone. An arrow would need its own name, and a Modifier for every projectile would have to name both.
   - Keep `Speed`: the clash the rule exists to stop.

   The constant and export follow the name (`PROJECTILE_SPEED`, `projectile_speed`). **Glossary entry: yes** *(recommended)*, as written above. The rule makes a number's name a word with one meaning, and the glossary is where meanings live; Range, Sweep, Cooldown, Damage and Stagger have entries. (Knockback is the one number name without one; not this step's.)
2. **A Skill that is Elemental without being Fire.** Rule 2 forbids a Skill listing Elemental itself, because it could never lose it ("Fire Skills are now Holy" would leave it Elemental).
   - *Recommended:* keep rule 2. A Skill that is elemental by nature gets a tag of its own that implies Elemental, added to the table (say Lightning → Elemental).
   - Alternative: allow it, and accept that such a Skill keeps Elemental through any tag change.
3. **A tag change that names an implied tag.** Adding Elemental, removing it, replacing Fire with it, or replacing it with Holy: the tag pass skips each, every time, with a why line ("can't change Elemental, it comes from another tag").
   - *Recommended:* rule 4 fails it, since in a file it can never do anything. (The analysis didn't list this check.)
   - Alternative: allow it, with the why line as its only sign.
4. **A Modifier file on a number no Skill has yet.**
   - Written before its Skill (a Projectile speed Modifier before any projectile Skill): fails.
   - On a number only an Enemy's Skill has: passes, since Enemy scenes are walked.
   - On a number only a test's Skill has: fails, since tests aren't content.
   - *Recommended:* as above. The Modifier file lands with or after its Skill.
   - Alternative: declare numbers ahead in a list, as tags are. That is a second list to keep, for a case nobody has hit.
5. **A saved Cooldown below the shortest Cooldown.** Step 1 makes 0.1 s the shortest Cooldown that starts (plan.md, working answers).
   - A Cooldown of 0, or none (the default 0): fails either way.
   - A Cooldown of 0.05: runs at 0.1 s. It passes "above 0" and fails "at least the shortest".
   - *Recommended:* above 0, as the editor's warning says (`skill.gd:95`). This step then doesn't depend on how step 1 names its floor, and the floor decides what runs.
   - Alternative: at least step 1's shortest Cooldown, read from its constant, so a value that never runs as saved fails at once.

## Out of scope

- **Dropping `@tool` from the Skill scripts** (the analysis's option). It stays. Dropping it would remove `skill.gd:1`, `:7-8`, the setter at `:40-43` (a plain export), the editor guard at `:83-85`, the warning at `:93-95`; `attack.gd:1`; `fireball.gd:1`; and `test_skill.gd:43-49`. Rule 3 already does at check time what the warning does in the editor. Trigger: the first Skill script with code that would run in the open editor beyond Skill's guarded tick (a `_ready` that builds nodes, a `_process`), or the developer no longer wanting the warning.
- **Scenes in the tree.** `load_all` and the content test instance scenes off the tree, so node-path exports and `_ready` go unchecked. Trigger: `game-scene` (step 5) adds a smoke test of the main scene.
- **A Modifier saved inside another file**: an item's or talent's file, or a Character scene that sets its `modifiers`. Only Modifier files are checked. Trigger: the first file that keeps a Modifier inside it (gear).
- **Checks that aren't about names**: titles and icons (both reports and the analysis list them), a Modifier with no effect, an amount of 0, an enum number past the last entry. A missing title or icon shows on screen the first time, and the enum convention keeps numbers in range. Trigger: Modifier files written in bulk that nobody reads one by one.
- **A Character's own numbers as Modifier targets** (maximum Health, Movement's speed): rule 4 knows only Skills' numbers. Trigger: the first such Modifier (plan.md: gear).
- **Binary `.res` files**: none exist. Trigger: the first one.
- **A file under `tests/`** is walked as content. Trigger: the first test that needs a broken file saved on disk; the walk then leaves `tests/` out.
- **Where the Projectile speed constant lives**: on Fireball. Trigger: the second projectile Skill (plan.md, a shared projectile folder).

## Needs a run

1. **Every scene instanced inside GUT.** `scenes/sandbox.tscn`, `scenes/dungeon_tiles.tscn` and the seven `props/*.tscn` are instanced by no test today, only by `load_all`, whose output `check.sh` filters. If one logs an engine error or warning off the tree, GUT fails the content test though the content is fine. Then stop and report the message; don't switch GUT's error tracking off.
2. **`LoadAll.find_files` from a GUT test**, through a `preload` of a script that extends `SceneTree`. Expected to work. If the analyzer refuses, copy the walk into the test with the same rules and say so in the PR. An array literal passed as a `PackedStringArray` argument may need `PackedStringArray([...])`.
3. **The empty slot in text** (C7): `…([SubResource("halve_cooldown"), null])`. If the loader refuses it, the developer makes the slot in the inspector (Number Changes, size 2) instead.

## Done when

- `tools/check.sh` passes, and each break in Tests fails it at the step named, then passes again once reverted. The PR lists them.
- `grep -rnE '&"(Spell|Attack|Melee|Projectile|Fire|Elemental|Pierce)"' autoloads characters skills ui scenes props rendering --include='*.gd'` prints only `skills/skill_tag.gd`.
- A search for `Fireball.SPEED`, `&"Speed"` and Fireball's `speed` export comes back clean in code, tests and docs. Only records of what was remain: `.scratch/combat/spec.md`, the two reports, `.scratch/future-proofing-review/`.
- The conventions have "Saved content"; the skill-tags spec and the glossary say what the developer settled.
- Checked once in game: after Project › Reload Current Project in the open editor, Fireball flies as before, and with `modifier pierce on` it passes through one zombie and stops at the next.

## Tickets

1. `issues/01-load-every-tres.md`: the check loads every `.tres` and leaves out `assets/`.
2. `issues/02-skill-tags-declared-once.md`: `SkillTag`, and game code names tags by constant.
3. `issues/03-content-test.md`: `tests/test_content.gd` and the conventions' "Saved content".
4. `issues/04-projectile-speed.md`: Fireball's `Speed` renamed.
