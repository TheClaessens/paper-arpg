# Number bounds

Status: ready-for-agent

The open rules below follow their recommended answers; the developer confirms them when reading this step's PR.

Step 1 of the future-proofing plan (`.scratch/future-proofing-review/plan.md`), on its own branch `number-bounds` off `master` (`8797660`). The later steps stack on it (plan.md, decision 8); `modifier-stacking` (step 4) rewrites `Snapshot.of` on top of it. Sources: `.scratch/future-proofing-review/analysis/rules-engine.md` §5, §6, §7, Brief 3 and WP-1, and `character-enemy.md` §10 item 4, checked against the code. Nothing changes in play.

## What changes and why

The code makes three promises it doesn't keep, and lacks one rule:

- **A number below 0.** `Snapshot._stack` stops Increased and each More at −100%, and the skill-tags spec concludes "so a number never goes below 0" (`.scratch/skill-tags/spec.md:60`). But a flat change adds straight to the number: Range 10 with a flat −15 is −5, and 50% increased on top makes it −7.5.
- **Health going the wrong way.** Factions-health rule 4 says Damage lowers Health and healing raises it. `Health.damage(-5)` heals. `Health.heal(-50)` lowers Health and can bring it to 0 without `died`, which only `damage()` emits; from then on Health ignores every hit, so an Enemy would stand at 0 and never die.
- **A Snapshot that changes.** A Snapshot is "fixed from that moment" (GLOSSARY.md) and its lists are read-only, but `snapshot.numbers = {…}` replaces a whole field. No code does it today.
- **A Cooldown of 0.** Two different "50% reduced cooldown" Modifiers add up to −100% and take a Cooldown to 0 (the same file listed twice counts once today, and twice once `modifier-stacking` lands). At 0, a held Attack activates every physics frame, 60 times a second, though the glossary says the Cooldown "is the only thing that limits how often a Skill is activated". The skill-tags spec deferred a minimum Cooldown "with attack speed".

Nothing shipped reaches any of this: no Modifier has a negative flat change or cuts a Cooldown that far, and the Console refuses a negative amount. The step closes these doors before gear and talents bring Modifiers that walk through them.

Words are the glossary's. A *flat change* is a Modifier's change that adds its amount to a number (`NumberChange.Kind.FLAT`), as the skill-tags spec uses it.

## The rules

1. **No number `Snapshot.of` makes is below 0.** A number takes its flat changes first, summed, and the sum stops at 0; then Increased (no lower than −100%) and each More (no lower than −100%) scale it, as today. Range 10 with a flat −15 gives 0, and with 50% increased on top still 0, not −7.5. Range 10 with a flat −15 and a flat +10 gives 5, whichever Modifier came first. A Skill whose own number is below 0 in its scene gets 0 too.
2. **Health ignores Damage and healing of 0 or less.** Damage never raises Health and healing never lowers it, so Health reaches 0 only through Damage, and `died` comes with it (factions-health rule 5). At 40 of 50, `damage(-5)` and `heal(-50)` both leave it at 40.
3. **A Snapshot's fields can't be replaced.** Assigning to `tags`, `numbers` or `why` leaves the Snapshot as it was, and in a debug build the assignment fails an assert, "A Snapshot never changes". Its lists stay read-only, as now.
4. **No Cooldown runs shorter than 0.1 s** (`Skill.SHORTEST_COOLDOWN`), however short Modifiers make it. The Snapshot keeps the Cooldown its Modifiers made, 0 included; the Skill's clock starts at 0.1 s when that is longer. In play: a held Attack activates at most 10 times a second (about 8.6 at 60 physics frames a second, see open rule 7), four times as often as its own 0.4 s Cooldown allows, and a Fireball whose Modifiers took its Cooldown to 0 throws at most 10 balls a second. Rule 4 is ticket 04 alone, last, so it can be dropped or retuned without touching rules 1 to 3.

## Where each number goes

`Snapshot.of` runs `_stack` on every number the Skill has, with or without Modifiers (`snapshot.gd:41-42`), and game code makes Snapshots only through `Skill.snapshot()` (`skill.gd:118-119`), for activations and for aiming alike. So one bound in `_stack` covers every reader:

| Number | Read by, on `master` | Below 0 today | At 0, after this step |
|---|---|---|---|
| Cooldown | `try_activate` starts it (`skill.gd:111`, `:69-71`) | acts as 0 (`is_ready()`, `:64-65`) | a held Skill activates every physics frame: rule 4 |
| Range | Attack's swing and its query (`attack.gd:39-43`, `hurtbox.gd:49-50`), the ball's end (`projectile.gd:31`), aiming (`player.gd:191-192`) | the swing's wedge is mirrored and its query sphere gets a negative radius; the ball ends at once; Auto-aim aims behind the player | the ball ends at once; Attack breaks (Out of scope) |
| Damage | `enemy.gd:62`, into `Health.damage()` | heals | nothing happens (factions-health rule 4) |
| Knockback | `enemy.gd:66` | pulls the Enemy toward the player | no push |
| Stagger | `enemy.gd:64` | raised to 0.02 s there | 0.02 s, as today |
| The ball's speed (`Fireball.SPEED`, which `content-checks` renames) | `projectile.gd:28` | the ball flies backwards and never ends | the ball never moves and never ends (Out of scope) |
| Sweep | `attack.gd:40`, `in_sweep()` | hits only at point blank | hits only at point blank |

The readers keep only what is about 0 itself (`enemy.gd:64`) or about the clock (`skill.gd:78`, `:90`); none needs a guard against a number below 0. Health gets its own guard (rule 2) because Damage and healing will come from more than Skills: burns, leech, the Console.

## The change, file by file

### `skills/snapshot.gd`

**Ticket 01.** `_stack`'s return line (`:62`) floors the number once its flat changes are summed:

```gdscript
	return maxf(0.0, value) * maxf(0.0, 1.0 + increased / 100.0) * more
```

Flooring there gives the same result as flooring the end, because neither factor is ever below 0. The last line of `_stack`'s doc (`:48`) becomes: "No number comes out below 0: after its flat additions it is at least 0, Increased stops at -100%, and so does each More." The `numbers` doc (`:10`) gains a sentence: "of() makes none of them below 0." One `ponytail:` comment goes above `why.append(...)` in `of()` (`:36`):

```gdscript
		# ponytail: every Snapshot writes a why line per Modifier, even one made only to aim;
		# write them only when read, if a profile on the phone points here.
```

**Ticket 03.** Each field becomes a property over a private field: its getter returns the private field, its setter writes nothing and fails an assert. `_init` writes the private fields, then makes them read-only as now.

```gdscript
## The Skill's tags, implied ones included.
var tags: Array[StringName]:
	get:
		return _tags
	set(_value):
		assert(false, "A Snapshot never changes")
# numbers and why the same way, over _numbers and _why, keeping their docs

var _tags: Array[StringName]
var _numbers: Dictionary[StringName, float]
var _why: Array[String]


func _init(snapshot_tags: Array[StringName], snapshot_numbers: Dictionary[StringName, float], snapshot_why: Array[String]) -> void:
	_tags = snapshot_tags
	... # _numbers, _why, then make_read_only() on all three, as now
```

The class doc's last line (`:6`) becomes: "Its fields can't be replaced and its lists are read-only, so it never changes after it is made." Readers don't change: `snapshot.tags`, `.numbers`, `.why` and `number()` read as before, and `Snapshot.new(tags, numbers, why)` keeps its signature.

Why this shape, checked against the Godot 4.7 reference and source:

- A setter runs on every assignment, even inside the class, so `_init` can't write `tags` itself. The GDScript reference (Properties) says for this case: "use another variable for direct access and make the property code use that name". An initializer is written without the setter. These properties have none, so nothing should call the setter while a Snapshot is made; if something did, every test that makes a Snapshot would report "A Snapshot never changes", and ticket 03 checks that none does.
- A getter alone isn't enough: the reference doesn't say what assigning to a property with only a getter does. The setter makes the refusal certain.
- A failed assert generates an error "and the current method returns a default value", and the code inside `assert()` runs only in debug builds (@GDScript, `assert`). Either way the setter writes nothing: a release build ignores the write, and a debug build also reports it (and breaks into the debugger when run from the editor), as `Console.register` does for a command registered twice (`console.gd:62`).
- `assert(false, …)` with a literal `false` raises no "assert always false" warning: the analyzer exempts a literal bool (`resolve_assert` in `modules/gdscript/gdscript_analyzer.cpp`).
- GUT 9.7.1 fails a test on any engine error unless the test claims it with `assert_engine_error(text)`, as `test_console.gd:81` does. GUT's own `addons/gut/awaiter.gd:50-52` refuses writes to a property with the same shape (its setter calls `push_error`).

Cost: about 16 more lines in `snapshot.gd`, and one test (open rule 6).

### `skills/tag_pass.gd` (ticket 01)

One `ponytail:` comment above `var matching := ...` (`:33`), inside the loop:

```gdscript
		# ponytail: `in` scans over the Modifiers, here and in applies(), grow with the square of
		# their number; use a Dictionary as a set if a profile on the phone points here.
```

It sits here rather than in `Snapshot.of`, because the scan in `of()` (`counted`, `snapshot.gd:33`, `:37-38`) goes when `modifier-stacking` makes each entry count (plan.md, decision 2).

### `characters/health/health.gd` (ticket 02)

`damage()` and `heal()` return at once on an amount of 0 or less:

```gdscript
## Takes `amount` of Damage, no lower than 0, and dies on reaching it. An amount of 0 or less
## does nothing: Damage never raises Health.
func damage(amount: float) -> void:
	if amount <= 0.0 or is_dead():
		return
	... # as now


## Heals `amount`, no higher than the maximum. An amount of 0 or less does nothing: healing
## never lowers Health, so it can't bring Health to 0 without dying.
func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	_set_current(current + amount)
```

The class doc (`:3-5`) gains, after "It lies between 0 and its maximum.": "Damage or healing of 0 or less changes nothing, so only Damage brings it to 0." An early return reads as the rule; `maxf(amount, 0.0)` would do the same. A guard, not an assert: Health keeps its bounds in a release build too, and an amount of 0 is an ordinary hit (a Skill that knocks back without Damage).

### `skills/skill.gd` (ticket 04)

A constant after the number names (after `:22`), and the floor in `start_cooldown` (`:68-71`):

```gdscript
## The shortest a Cooldown runs, in seconds, however short Modifiers make it: a held Skill
## activates at most 10 times a second.
const SHORTEST_COOLDOWN := 0.1

## Starts a Cooldown `seconds` long, an activation's Snapshot's, but never shorter than
## SHORTEST_COOLDOWN.
func start_cooldown(seconds: float) -> void:
	cooldown_left = maxf(seconds, SHORTEST_COOLDOWN)
	_cooldown_length = cooldown_left
```

The `cooldown` export's doc (`:37-39`) ends "…the Cooldown that runs is the activation's Snapshot's, never shorter than SHORTEST_COOLDOWN.", wrapped onto one more line. The floor is in `start_cooldown`, not at `try_activate`'s call (`:111`): the clock is what has the floor, and `try_activate` is what `skill-character` reshapes. `try_activate`'s doc (`:104-106`, "starts the Snapshot's Cooldown") stays true as written.

### Unchanged on purpose

- `skills/number_change.gd`: a flat amount may still be negative (−2 Range is a real Modifier). Only the result stops at 0.
- `characters/enemy/enemy.gd`: keeps its 0.02 s Stagger (`:63-64`), which is about 0, not about numbers below it.
- `skills/fireball/projectile.gd`, `skills/attack/attack.gd`: readers; they need no guard.
- `characters/player/player.gd`: the Console's `damage` and `heal` keep refusing a negative amount with their usage line (`:240`). That is the Console's message; the rule is Health's.
- `skills/skill.gd:93-95`: the editor still warns about a Skill scene whose Cooldown is 0. The floor is a net under Modifiers, not a default for a Skill that forgot its own.

## Tests

Write each new test first: it must fail before its ticket's code change and pass after.

| Test | Ticket | Proves | On `master` |
|---|---|---|---|
| `test_snapshot.gd`: new `test_a_flat_cut_stops_at_zero`, after `:61` | 01 | Range 10 with a flat −15: 0. With 50% increased too: 0. With a flat −15 and a flat +10: 5. `Snapshot.of` with a Skill's own Knockback of −1 and no Modifier: 0. | Fails: −5, −7.5 and −1. The 5 passes on `master`; it fails if someone floors each flat change as it applies (that gives 10), which open rule 2 rules out. |
| `test_health.gd`: new `test_negative_damage_does_not_heal`, at the end | 02 | `damage(10)` then `damage(-5)`: 40, and `changed` emitted once | Fails: 45, `changed` twice |
| `test_health.gd`: new `test_negative_healing_does_not_hurt`, at the end | 02 | `damage(10)` then `heal(-50)`: 40, and Health isn't dead | Fails: 0, dead, and `died` never came |
| `test_snapshot.gd`: new `test_a_snapshots_fields_cannot_be_replaced`, after `:97` | 03 | Assigning a new value to each of `tags`, `numbers` and `why` reports "A Snapshot never changes" (three `assert_engine_error` calls, one per assignment) and leaves each field the same object as before (`assert_same`) | Fails: no error comes, and each field holds the new value |
| `test_skill.gd`: new `test_no_cooldown_runs_shorter_than_the_shortest`, after `:83` | 04 | A `RecordingSkill` with a 0.4 s Cooldown and a Modifier with no filter, Increased −100% on Cooldown: the Snapshot's Cooldown is 0, `cooldown_left` is `Skill.SHORTEST_COOLDOWN`, and a second `try_activate` at once returns false | Fails: no constant; with it but without the floor, `cooldown_left` is 0 and the second activation goes through |
| `test_skill.gd`: `test_it_runs_its_own_cooldown` (`:98-102`), changed | 04 | As before, that the Skill runs its own clock. Its Cooldown goes from 0.05 to 0.2 s, and the wait from 6 to 15 physics frames ("0.25 s at 60 Hz") | Passes on `master` too. Changed because 0.05 s now runs 0.1 s, which takes 7 frames, past the 6 the test waits. 0.2 s keeps it clear of the floor's value. |

Unchanged, and still passing: `test_no_modifier_takes_a_number_below_zero` (`test_snapshot.gd:55-61`, Increased and More), `test_a_snapshot_never_changes` (`:93-97`, the read-only lists), `test_nothing_changes_nothing_is_reported` (`test_health.gd:32-36`, 0 Damage and healing at full), `test_a_skill_without_a_cooldown_warns` (`test_skill.gd:45-49`).

Header docs: in `test_snapshot.gd:4-5`, "…then each More on its own." becomes "…then each More on its own, and none comes out below 0." (01). In `test_health.gd:2-3`, "a hit of 0 Damage leaves it alone" becomes "Damage or healing of 0 or less leaves it alone" (02).

## Docs this reopens

- **`.scratch/factions-health/spec.md:12`**, rule 4 (ticket 02). Becomes: "4. **Health lies between 0 and its maximum.** Damage lowers it, healing raises it, both clamped. Damage or healing of 0 or less leaves it alone, so Damage never raises it and healing never lowers it (`.scratch/number-bounds/spec.md`, 2026-11-22)."
- **`.scratch/skill-tags/spec.md:34`**, requirement 5 (ticket 04). Becomes: "   - The Cooldown that starts on an activation is the Snapshot's, but never shorter than the shortest Cooldown (`Skill.SHORTEST_COOLDOWN`; see `.scratch/number-bounds/spec.md`)."
- **`.scratch/skill-tags/spec.md:60`**, the deferred minimum Cooldown (ticket 04). Becomes: "- **A minimum Cooldown.** Settled in `.scratch/number-bounds/spec.md` (2026-11-22): no number goes below 0, and no Cooldown runs shorter than `Skill.SHORTEST_COOLDOWN`. Whether attack speed is a rate or a shorter Cooldown is deferred there." If ticket 04 is dropped, the line stays as it is; ticket 01 makes its first sentence true.
- **`GLOSSARY.md:112`**, Cooldown (ticket 04). Becomes: "How long after an activation starts before a Skill can be activated again, from any slot it sits in. Every Skill has one, and it is the only thing that limits how often a Skill is activated. Modifiers such as attack speed change it, down to a shortest Cooldown that is the same for every Skill." The value stays out of the glossary, so retuning it touches the constant and this spec only.

No ADR, no other glossary entry and nothing in `docs/agents/godot-conventions.md` changes. Skill-tags requirement 5's "The Snapshot never changes after it is made" (`.scratch/skill-tags/spec.md:33`) becomes true as written.

## Open rules for the developer

Settle these before code. The tickets follow the recommended answers.

1. **Where the floor sits while a number is stacked twice.** Today `Snapshot.of` stacks each number with the changes of Modifiers that change Skill tags, then stacks that result with every other Modifier's (ADR 0002; `snapshot.gd:39`, `:42`). Range 10, a tag-changing Modifier with a flat −15, and a plain Modifier with a flat +12:
   - a. The floor in `_stack`, so on each stacking: 10 − 15 stops at 0, then + 12 gives **12**.
   - b. The floor once, at the end of `of()`: 10 − 15 = −5, then + 12 gives **7**.

   *Recommended:* **a**. It treats a flat cut as Increased and More already are (a −150% More in the first stacking also leaves 0 for the second to add to), and it is one expression. Plan.md's decision 1 makes `modifier-stacking` stack each number once, and then a and b give the same answer, 7. Until that lands, no shipped Modifier changes both tags and numbers.
2. **Flat changes summed, then floored.** Range 10 with a flat −15 and a flat +10: summed first, 5, whichever came first. Floored as each applies, 10 if the −15 came first and 5 if the +10 did. *Recommended:* summed, since a Modifier's effect never depends on the order it was picked up in (ADR 0002). Ticket 01's test pins it.
3. **A Skill's own number below 0.** A scene sets Knockback −0.5 to pull Enemies in. Every own number passes through `_stack`, so it gives 0: no pull. Today it pulls. *Recommended:* 0. A pull, when one is designed, is a number or a behaviour of its own; until then a negative number in a scene is a typo.
4. **A Snapshot built by hand.** `Snapshot.new()` takes its numbers as given. Only tests call it (`test_projectile.gd:15`, `:55`; `test_enemy_death.gd:63`, `:73`), with numbers they choose.
   - a. Leave it: `of()` is the only maker in game code.
   - b. Assert in `_init` that no number is below 0: a loop over every number of every Snapshot, two Snapshots per activation, to catch a test.

   *Recommended:* **a**.
5. **Quiet or loud.** Health ignores an amount of 0 or less quietly: 0 is an ordinary hit, and after rule 1 no Skill sends a negative one. Replacing a Snapshot field is loud in a debug build (an assert, as `Console.register` is) and ignored in a release build. *Recommended:* as written.
6. **Keep the refusing setters?** About 16 lines and one test. What they protect: one Snapshot is shared by every hit of its activation (each Hurtbox one swing finds, both hits of a Pierce ball, later a burn), so a reader that replaced `numbers` for its own hit would change the hits after it. The read-only lists already stop the likelier mistake, changing one number in place. *Recommended:* **keep** (ticket 03). It is its own ticket, so it can be dropped alone.
7. **The shortest Cooldown's value.** The physics runs 60 frames a second, and a Cooldown that is a whole number of frames runs one frame longer: 0.1 − 6 × (1/60) leaves a rounding crumb above 0, so the clock runs out on the 7th frame. (Every Cooldown does this today: the Attack's 0.4 s is 25 frames, 2.4 swings a second.)
   - 0.05 s: 4 frames, 15 activations a second.
   - **0.1 s**: 7 frames, about 8.6 a second.
   - 0.15 s: 10 frames, 6 a second.
   - None: drop ticket 04 and keep the deferral; a Cooldown of 0 still means every frame.

   *Recommended:* **0.1 s**, plan.md's working answer. Retuning it changes the constant and its doc comment, and rule 4's numbers here.
8. **The floor belongs to the clock, for every Cooldown.** It applies to every Cooldown that starts, whatever made it short, a Skill's own included (a test Skill set to 0.05 s runs 0.1 s). The Snapshot keeps the number its Modifiers made, so its Cooldown can read 0 while the clock runs 0.1 s; the Skill slot's button sweeps and flashes by the clock. The other place, a floor on the Snapshot's Cooldown in `of()`, would keep "the Cooldown that starts is the Snapshot's" true word for word, but would give the stacking a rule for one number's name and tie ticket 04 to `snapshot.gd`, which `modifier-stacking` rewrites. *Recommended:* the clock.

## Deferred

- **Attack speed: a rate, or a shorter Cooldown.** The remove-use-time spec says attack speed and cast speed "arrive later as Modifiers on Cooldown", not how they count. As a shorter Cooldown, a speed Modifier is written as a reduced Cooldown, and reductions add up toward 0 and the floor. As a rate, the speed percentages add up and then divide the Cooldown, so speed alone never reaches 0. Attack's 0.4 s with two "20% increased attack speed": as a rate, 0.4 ÷ 1.4 = 0.29 s; written as reduced Cooldown (about −16.7% each, to match one of them), 0.27 s, and six of them reach 0. The analysis recommends the rate (`rules-engine.md`, Brief 3, option B), built as a fourth kind of number change added at the end of `NumberChange.Kind` (files save the kind as a number), or as a speed number every Skill has. **Trigger:** the first speed Modifier (plan.md lists it). Until then, no Modifier file writes speed as a reduced Cooldown, or it would have to be rewritten. Rule 4's floor holds either way.

## Out of scope

- **A ball whose speed is 0** never moves and never ends; only a Hurtbox that walks into it ends it. The ball's own step (`ball-in-world` in plan.md) fixes it. **Trigger,** if that step comes later than such a Modifier: the first Modifier that can cut the ball's speed by 100%.
- **Range 0 breaks Attack.** Its query sphere gets radius 0, which Jolt refuses to build (an engine error, and no hits; `_build()` in `modules/jolt_physics/shapes/jolt_sphere_shape_3d.cpp`). Auto-aimed, its Aim is a zero offset, and `Basis.looking_at` errors on a zero vector. The aim marker's ring gets an inner radius below 0 whenever Range is under its 0.07 line width (`aim_marker.gd:28-29`). Fireball's ball just ends at once. Rule 1 doesn't make this worse: a Range that would have gone below 0 now stops at 0, and below 0 was broken too. `skill-character`'s "an Aim needs a direction" may cover the zero Aim. **Trigger:** the first Modifier that can cut a Range to 0.
- **Numbers too large for their reader**: a ball fast enough to cross a wall in one physics frame, a Range that finds more than 32 Hurtboxes (`hurtbox.gd:58`). The `hit` step handles the 32; swept ball movement waits for the first speed Modifier (plan.md).
- **A Stagger of 0** stays 0.02 s here (`enemy.gd:63-64`). The `character` step's Stagger component makes it do nothing (plan.md's working answer).
- **Content checks for these numbers**: a number below 0 in a Skill scene, or a Skill's own Cooldown under the shortest. `content-checks` keeps "above 0" (its open rule 5); at run time rule 1 makes such a number 0 and rule 4 floors the Cooldown.

## Seams

The steps stack (plan.md, decision 8): every later branch starts from this one. Lines this step changes, as numbered on `master` (`8797660`), in files other steps also change:

- **`skills/snapshot.gd`.** Ticket 01: `:10` (the `numbers` doc), `:36` (a comment above `why.append`), `:46-48` (`_stack`'s doc), `:62` (`_stack`'s return). Ticket 03: `:6` (the class doc), `:8-13` (the fields become properties, and three private fields follow them), `:16-22` (`_init`). Nothing else: the code of `of()` and `number()` stays. `modifier-stacking` rewrites `of()` on top of this; it keeps `_stack`'s floor, the why-line `ponytail:` comment and `test_a_flat_cut_stops_at_zero` (whose Modifiers change no tags, so stacking once doesn't change its answers).
- **`skills/skill.gd`** (ticket 04 only): a constant inserted after `:22`, the doc at `:39` (one line more), and `start_cooldown` at `:68-71`. It stays off `try_activate` (`:104-113`), `faction` (`:53-55`), `hostile_mask` (`:141-143`) and the clock's tick (`:74-85`), which `skill-character` may change. `content-checks` leaves `skill.gd` alone.
- **`skills/tag_pass.gd`** (ticket 01): a comment above `:33`. `content-checks` changes `IMPLIED_TAGS` at `:13-15`.
- **`characters/health/health.gd`** and **`tests/test_health.gd`** (ticket 02): this step's alone; the `character` step leaves both untouched.
- **`tests/test_snapshot.gd`**: new tests after `:61` (01) and after `:97` (03), and the header at `:4-5` (01). `modifier-stacking` flips `:186-194` and `:230-232`.
- **`tests/test_skill.gd`** (ticket 04): a new test after `:83`, and `:98-102` changed. Both use `_recording()` and `RecordingSkill`; if `skill-character` changes how a test Skill is made (one that needs its Character, say), it carries these two along.
- **`Snapshot.new(tags, numbers, why)`** keeps its signature, so `test_projectile.gd:15`, `:55` and `test_enemy_death.gd:63`, `:73` are untouched (`content-checks` renames the speed constant in the first two).

## Done when

- Each new test fails before its ticket's change and passes after.
- Every other test passes unchanged, but for `test_it_runs_its_own_cooldown` (ticket 04).
- The doc comments and the docs above say rules 1 to 4.
- `tools/check.sh` passes after each ticket, and `/code-review` has run on the branch before its PR.

## Checking by hand

- `tools/check.sh`.
- Tickets 01 to 03 change nothing in play, so check that it plays as on `master`. With a window: `godot --path . --resolution 1280x720 --script res://tools/screenshot.gd -- res://scenes/sandbox.tscn "tp 18.8 4" "activate 1 1 0"`. The last shot shows a pack zombie's Health bar, down by a fifth. In game, the Console's `damage 10` prints `Health 90`, and then `heal 0` prints `Health 90` again. The Console refuses a negative amount, so rule 2 is checked by its tests only.
- Ticket 04: run the sandbox from the editor, select Player › Attack in the Scene dock's Remote tree, and set `cooldown` to 0. Hold the main slot (the left mouse button) away from zombies: the main slot's button keeps flashing and its Cooldown sweep keeps turning, about 8 times a second. Without ticket 04 it does neither, because a Cooldown of 0 never runs. Stop the game; nothing is saved.

## Tickets

1. `issues/01-no-snapshot-number-below-zero.md`: rule 1, and the two `ponytail:` comments.
2. `issues/02-health-ignores-0-or-less.md`: rule 2.
3. `issues/03-snapshot-fields-cannot-be-replaced.md`: rule 3.
4. `issues/04-shortest-cooldown.md`: rule 4, last.
