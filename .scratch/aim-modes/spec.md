# Aim modes

Status: ready-for-agent

Step 11 of `.scratch/future-proofing-review/plan.md`. Agreed in chat on 2026-11-22: how a Skill is aimed becomes one named, saved thing that Skills share, the **Aim mode**. Play stays the same, apart from three touch fixes listed under "The touch fixes".

## Why

Three settings on each Skill decide how it is aimed (`aim`, `aims_at_spot`, `repeats_while_held`), and four scripts read them (`Player`, `SkillBarHud`, `SkillBar`, `AimMarker`). They allow twelve combinations; the game uses two. A new Skill aimed like Fireball has to copy the right three values, and nothing names "aimed like Fireball".

## The rules

1. **An Aim mode says how a Skill is aimed.** It answers three questions:
   - **What its Aim holds:** nothing, a direction, or a spot (a direction and how far).
   - **Whether it waits for the lift:** on touch, a Skill that waits is activated when the thumb lifts, so a drag off its slot aims it by hand. One that doesn't is activated as the thumb lands. Keys, mouse and controller always activate on the press.
   - **Whether holding its slot repeats it**, on every input.
2. **An Aim mode is a saved file** in `skills/aim_modes/`, and a Skill names one in its scene. Skills aimed the same way name the same file.
3. **There are four Aim modes**, the ways of aiming that exist today:

   | Aim mode | Holds | Waits for the lift | Repeats while held | Named by |
   |---|---|---|---|---|
   | Steer | a direction | no | yes | Attack |
   | Line | a direction | yes | no | Fireball |
   | Spot | a spot | yes | no | no Skill yet (the old Mark) |
   | Around | nothing | no | no | no Skill yet (the old Nova) |

   Spot and Around are kept and proven by a test-only Skill, as their code is today.
4. **Auto-aim is not an Aim mode.** It is the Aim any Skill gets when the player gives none, and it stays the Player's.
5. **A Skill in a Skill slot needs an Aim mode.** The Skill bar refuses one without. A Skill that only an Enemy has needs none: nothing aims it by hand.
6. **The three settings leave the Skill.** `Skill.Aim`, `aim`, `aims_at_spot` and `repeats_while_held` are removed, with every file and line that sets them.

## The change, file by file

### `skills/aim_mode.gd` (new, ticket 01)

```gdscript
class_name AimMode
extends Resource
## An Aim mode (see GLOSSARY.md): how a Skill is aimed. A saved file in skills/aim_modes/ that a
## Skill names; Skills aimed the same way name the same one. It says what the Skill's Aim holds,
## whether on touch the Skill waits for the thumb to lift, and whether holding its slot repeats it.
## Auto-aim is not one: it is the Aim any Skill gets when the player gives none (see Player).

## What an Aim holds. NOTHING: the Skill is activated around the Character. DIRECTION: where it
## goes. SPOT: where it goes and how far.
enum Holds { NOTHING, DIRECTION, SPOT }

## What an Aim of this mode holds.
@export var holds := Holds.DIRECTION
## Whether on touch the Skill waits for the thumb to lift: a drag off its slot aims it by hand and
## the lift activates it. Otherwise it is activated as the thumb lands. Keys, mouse and controller
## activate on the press either way.
@export var waits_for_lift := false
## Whether holding the Skill's slot activates it again each time its Cooldown ends.
@export var repeats_while_held := false


## The Aim for a thumb `drag` on screen, as an offset on the ground from the Character. `right` and
## `back` are screen right and screen down on the ground. An Aim that holds a spot goes as far as
## the drag, reaching `skill_range` at `full_drag`; any other goes the whole `skill_range`.
func aim_from_drag(drag: Vector2, right: Vector3, back: Vector3, skill_range: float, full_drag: float) -> Vector3:
	var direction := (right * drag.x + back * drag.y).normalized()
	var reach := minf(drag.length() / full_drag, 1.0) if holds == Holds.SPOT else 1.0
	return direction * skill_range * reach
```

This is `Player.ground_aim` moved, with its `to_spot` argument replaced by the mode's own `holds`.

In the chat sketch this was an enum, `goes_off` (on press, on release). It is a yes/no here because it only means something on touch, which the name `waits_for_lift` and its comment say, and a file then reads `waits_for_lift = true` instead of `goes_off = 1`.

### `skills/aim_modes/*.tres` (new, ticket 01)

Four files. Each holds only the values that differ from the script's defaults:

| File | Lines under `[resource]`, after `script` |
|---|---|
| `steer.tres` | `repeats_while_held = true` |
| `line.tres` | `waits_for_lift = true` |
| `spot.tres` | `holds = 2`, `waits_for_lift = true` |
| `around.tres` | `holds = 0` |

Make them with `ResourceSaver.save()` from a throwaway headless script kept outside the repo, so each file gets the header and `uid` the editor would write. Import first, so `AimMode` is a known class. If a saved file has no `uid` in its header, say so in the report.

### `skills/skill.gd` (ticket 01)

- Remove `enum Aim`, `aim`, `aims_at_spot`, `repeats_while_held`.
- Add, where `aim` was:
  ```gdscript
  ## The Skill's Aim mode (see GLOSSARY.md): how the player aims it. A Skill in a Skill slot
  ## needs one (see SkillBar.set_skill()); a Skill only an Enemy has needs none.
  @export var aim_mode: AimMode
  ```
- `_activate`'s comment says "for a Skill that lands on a spot, its length is how far": reword to "for a Skill whose Aim mode holds a spot".
- `target_for` stays.

### `skills/attack/attack.tscn`, `skills/fireball/fireball.tscn` (ticket 01)

Attack: remove `repeats_while_held = true`, add `aim_mode` naming `steer.tres`. Fireball: remove `aim = 2`, add `aim_mode` naming `line.tres`. Each gets one `ext_resource` line of `type="Resource"` for its file, with the file's `uid`.

### `skills/skill_bar.gd` (ticket 01)

- `set_skill` starts by refusing a Skill without an Aim mode. An `if`, because the assertion's message reads `skill.name` and `skill` may be null (an emptied slot):
  ```gdscript
  if skill:
  	assert(skill.aim_mode != null, "%s has no Aim mode: a Skill in a Skill slot needs one." % skill.name)
  ```
- `advance` reads `skill.aim_mode.repeats_while_held`.
- The class comment's "a Skill that repeats while held" becomes "a Skill whose Aim mode repeats while held".

### `characters/player/player.gd` (ticket 01)

- `aim_from_drag` becomes `return skill.aim_mode.aim_from_drag(drag, axes[0], axes[1], _range_of(skill), full_drag)`.
- `ground_aim` is removed.
- `_aim_for` reads `skill.aim_mode.holds == AimMode.Holds.NOTHING` where it read `skill.aim == Skill.Aim.AROUND`.
- The class comment's "(see Skill.Aim)" becomes "(see AimMode)".

### `characters/player/aim_marker.gd` (ticket 01)

One local, `var spot := skill.aim_mode.holds == AimMode.Holds.SPOT`, replaces the two reads of `skill.aims_at_spot`. The class comment keeps its words.

### `ui/skill_bar_hud.gd` (tickets 01 to 04)

Ticket 01 only swaps the reads: `skill.aim == Skill.Aim.AIMED` becomes `skill.aim_mode.waits_for_lift`, `skill.repeats_while_held` becomes `skill.aim_mode.repeats_while_held`. Tickets 02 to 04 are under "The touch fixes".

### `tests/` (ticket 01)

- `test_skill_bar.gd`: `before_each` gives `sword` and `fire` each `AimMode.new()` (the defaults: a direction, no wait, no repeat). The four tests that set `sword.repeats_while_held = true` set `sword.aim_mode = preload("res://skills/aim_modes/steer.tres")`. New: `test_a_skill_without_an_aim_mode_is_refused` (see Tests).
- `test_aim_modes.gd`: `before_each` gives the test Skill `AimMode.new()`; the two Around tests name `around.tres`, the marker test names `spot.tres`. The two `ground_aim` tests move here from `test_player.gd`, calling `aim_from_drag` on `line.tres` and `spot.tres`. Update the file's header comment.
- `test_player.gd`: the two `ground_aim` tests and their comment leave. New: `test_every_skill_of_the_player_names_an_aim_mode`.
- Other tests that put a hand-made Skill into a Skill bar get `AimMode.new()`. Tests that never do (`test_skill.gd`, `test_character.gd`, `test_skill_slot_button.gd`) stay as they are.

### Docs (ticket 01)

- `GLOSSARY.md`: the Aim mode entry, already in this branch's first commit.
- `docs/agents/godot-conventions.md`, "Saved content":
  - First bullet: "`fireball.tscn` saves `aim = 2`" becomes "`spot.tres` saves `holds = 2`"; in "Exported today", `Skill.Aim` becomes `AimMode.Holds`.
  - Second bullet: "Attack auto-aims only because `Skill.aim` defaults to `AUTO`" becomes "`steer.tres` holds a direction only because `AimMode.holds` defaults to `DIRECTION`".
  - A new bullet at the end of the list: "**A Skill names its Aim mode**, a file in `skills/aim_modes/`. A Skill aimed like an existing one names that one's file. A new way of aiming is a new file there when today's three questions cover it (what the Aim holds, whether it waits for the lift, whether it repeats while held), and a glossary entry either way."
- `.scratch/aiming/spec.md`, appended to "Decisions made during the build": "**How a Skill aims moved into Aim modes** (2026-11-22). The three settings on the Skill (`aim`, `aims_at_spot`, `repeats_while_held`) are gone; a Skill names a file in `skills/aim_modes/` (`.scratch/aim-modes/spec.md`)."
- Search code, tests and living docs (`GLOSSARY.md`, `CODING_STANDARDS.md`, `docs/`, `README.md`) for `Skill.Aim`, `AIMED`, `aims_at_spot`, `ground_aim` and a bare `skill.repeats_while_held`: none may remain. Older specs under `.scratch/` are records and stay as written.

## The touch fixes

Each is its own commit and its own ticket, after ticket 01.

### Ticket 02: each slot's thumb is tracked by itself

`SkillBarHud` remembers one held slot (`_held_slot`) and one aiming slot (`_aiming_slot`). A second thumb overwrites the first:

- **Two holds.** Thumb A holds a repeating slot, thumb B lands on another repeating slot. A's lift no longer lets go of A's slot, so its Skill repeats with no thumb on it until a pause.
- **Two aims.** Thumb A aims a slot, thumb B lands on another slot that waits for the lift. A's aim is dropped without a word, its marker stays on screen, and B's lift activates B's Skill.

The rules:

1. **Holds are per slot.** `_held_slot` becomes `var _holding: Array[bool] = []`, sized like `_landed`. Each thumb's hold starts, steers and ends by itself.
2. **One aim at a time: the first thumb keeps it.** There is one Aim marker. While a slot is being aimed, a thumb that lands on another slot that waits for the lift does nothing, and neither does its lift.

```gdscript
func _on_touch_started(at: Vector2, slot: int) -> void:
	_landed[slot] = at
	var skill := player.skill_bar.skill_in(slot)
	if skill == null or not skill.is_ready():
		return
	if skill.aim_mode.waits_for_lift:
		if _aiming_slot == SkillBar.NONE: # one aim at a time: the first thumb keeps it
			_aiming_slot = slot # activated when the thumb lifts
			_aimed = false
			_left_slot = false
	else:
		player.skill_bar.press(slot)
		if skill.aim_mode.repeats_while_held:
			_holding[slot] = true
			player.skill_bar.set_held(slot, true)
```

`_on_touch_moved` steers `if _holding[slot]`. `_let_go` ends the hold `if _holding[slot]`. Nothing else changes.

### Ticket 03: a lift exactly where the thumb landed is a tap

A thumb that drags past the deadzone, comes back to the exact point it landed on and lifts there gives an Aim with no direction. Today the Skill prints an error and isn't activated. From now on that lift is a tap: the Skill is activated auto-aimed. In `_on_touch_ended`:

```gdscript
	var drag := at - _landed[slot]
	if not _aimed or drag.is_zero_approx():
		player.skill_bar.press(slot) # a tap, or a drag back to where it began: auto-aimed
	elif not _over_cancel(slot, at):
		player.skill_bar.press(slot, player.aim_from_drag(skill, drag, drag_full_range))
```

`Skill.try_activate` keeps its own check: the `activate` console command can still give an Aim with no direction.

### Ticket 04: a thumb held through a Cooldown repeats like a held key

This is ticket 05 of `.scratch/touch-interruptions/` (its open rule 1), which the developer leans towards. It is the last commit so that it reverts alone if it feels wrong on the phone.

The readiness check moves into the branch that waits for the lift:

```gdscript
	if skill == null:
		return
	if skill.aim_mode.waits_for_lift:
		if skill.is_ready() and _aiming_slot == SkillBar.NONE: # an aim only for a Skill that can be activated now
			...
	else:
		player.skill_bar.press(slot) # ignored while the Cooldown runs
		if skill.aim_mode.repeats_while_held:
			_holding[slot] = true
			player.skill_bar.set_held(slot, true) # activated the moment the Cooldown ends
```

Docs, as that ticket lists them: the HUD's class comment gains "even when the thumb lands during its Cooldown"; `.scratch/aiming/spec.md`'s "Holding repeats the Attack" decision gains "A thumb that lands on the slot while the Cooldown runs holds it too, as a key does: the Skill is activated the moment the Cooldown ends."; `.scratch/touch-interruptions/spec.md` gains a "Decisions" heading with "Open rule 1: yes, built in `.scratch/aim-modes/` (ticket 04), to be tried on the phone."; `.scratch/touch-interruptions/issues/05-holds-through-the-cooldown.md` gets `**Status:** ready-for-human` and a line pointing here.

## Tests

| # | Test | File | What it shows | Fails before its ticket? |
|---|---|---|---|---|
| 1 | `test_a_skill_without_an_aim_mode_is_refused` | `test_skill_bar.gd` | `bar.set_skill(2, a Skill with no aim_mode)` fails the assertion (claim it with `assert_engine_error`, as the Snapshot tests do). | Yes: the property doesn't exist. |
| 2 | `test_every_skill_of_the_player_names_an_aim_mode` | `test_player.gd` | Every Skill in `player.skills` has an `aim_mode`; Attack's is `steer.tres`, Fireball's is `line.tres`. | Yes |
| 3 | `test_a_drag_aims_a_direction_its_full_range`, `test_a_drag_aims_a_spot_as_far_as_it_goes` | `test_aim_modes.gd` | The two moved `ground_aim` tests, on `line.tres` and `spot.tres`, same numbers. | Moved |
| 4 | `test_each_aim_mode_file_says_what_the_spec_says` | `test_aim_modes.gd` | The four files' `holds`, `waits_for_lift` and `repeats_while_held` match the table in rule 3. | Yes |
| 5 | `test_a_second_hold_leaves_the_first_its_own` | `test_skill_bar_hud.gd` (ticket 02) | The Attack also sits in slot 2. A thumb lands on slot 0, another on slot 2, both lift. After `_elapse(0.5)` twice, no activation is asked for after the lifts. Record the slot each request names. | Yes: slot 0 goes on repeating. |
| 6 | `test_a_second_aiming_thumb_is_ignored` | same (ticket 02) | Fireball also sits in slot 2. A thumb on slot 1 drags 60 units right; a thumb taps slot 2; the marker still shows and nothing was activated; slot 1's thumb lifts: one activation, from slot 1, with the dragged Aim. | Yes: slot 2's tap throws the ball and slot 1's lift does nothing. |
| 7 | `test_a_drag_back_to_where_it_began_is_a_tap` | same (ticket 03) | `_touch(Vector2.ZERO, [Vector2(30.0, 0.0), Vector2.ZERO])` on Fireball: one activation, `SkillBar.NO_AIM`. | Yes: an engine error and no activation. |
| 8 | `test_a_thumb_held_through_the_cooldown_repeats_when_it_ends`, `test_an_aimed_skill_cooling_down_shows_no_aim` | same (ticket 04) | Tests 9 and 10 of `.scratch/touch-interruptions/spec.md`, as written there. | 9 yes, 10 no |

Every existing test passes, changed only where this spec says. `tools/check.sh` passes after every commit (the pre-commit hook runs it).

## Play is unchanged

Tickets 01 to 03 change nothing a key, mouse or controller player can reach. Check it with the play comparison in `tools/simulate.gd`'s header (`--fixed-fps 60`, the temporary `override.cfg`, removed afterwards): the swing must still print `fc6af6dbd110508d8e597824a4f40861` and the ball `53636a0a689c4a5707347e78441f5d67`, as on `master`. Run both on `master`'s commit first; if either differs there, say so and compare against what `master` prints.

## Open rules, built on the recommended answer

The developer confirms these when reading the PR.

1. **A second aiming thumb: the first keeps the aim** (ticket 02). The alternative is that the newer thumb takes the aim over and the first is dropped.
2. **A drag back to exactly where it began is a tap** (ticket 03). The alternative is that it activates nothing.
3. **A Skill that only an Enemy has needs no Aim mode** (rule 5). So no content check walks every Skill scene for one; the Skill bar's assertion and test 2 cover the player's.

## Out of scope, with what brings each back

| What | Trigger |
|---|---|
| A script or a marker scene per Aim mode | The first way of aiming whose drag or drawing isn't one of today's (a Skill that erupts at the end of its line) |
| An Aim that carries a picked Hurtbox | The first Skill that picks one (Mark's return) |
| What a held thumb does on a Skill that waits for the lift and repeats | The first Aim mode file with both (holding Fireball) |
| An Aim mode for a Skill tapped but never aimed by hand ("nearest target") | The first such Skill: a file with the script's defaults |

## Known limits

- A thumb steering the Attack and a thumb aiming Fireball share the one Aim marker: it shows whichever moved last, and either thumb's lift hides it until the other moves.
- `AimMode.new()` in a test is the plain mode no file has (a direction, no wait, no repeat).

## Done when

- The four tickets are built, one commit each, and `tools/check.sh` passes on the last.
- The two play checksums match `master`'s.
- `/code-review` ran on the branch and its findings are fixed or answered.
- The developer tried ticket 04 on the phone and kept it, or reverted its commit.
