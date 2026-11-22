# A Skill knows its Character

Status: ready-for-agent

Tickets 01 to 05 are built on the recommended answers to the open rules, which the developer confirms when reading this step's PR. Ticket 06 is the developer's.

A **Skill** knows the **Character** that has it (`Skill.character`), instead of only a **Faction** that defaults to the player's. The Character sets it. A Skill hits what is hostile to its Character's Faction, and a Skill activated without a Character fails loudly. Two holes in the same file close with it: a Skill script with its own `_physics_process` can no longer stop its **Cooldown**, and an **Aim** with no direction is refused. `_activate`'s doc says that what a Skill does happens at the moment it is activated. Nothing changes in play, except that the Console's `activate 1 0 0` no longer swings.

Step 7 of `.scratch/future-proofing-review/plan.md`, on branch `skill-character`, stacked on step 6 (`character`, `.scratch/character/spec.md`), as the plan stacks every step (decision 8). Steps 9 (`hit`) and 10 (`ball-in-world`) build on it. Sources: `.scratch/future-proofing-review/analysis/hit-pipeline.md` section 1, section 10 ("Missed by both reports", items 1, 2 and 6) and work package HP1, and `.scratch/future-proofing-review/analysis/character-enemy.md` "Seams with the other analysts" (H2, H5), each claim checked against the code at `8797660`. Line numbers are that commit's. Step 1 (`number-bounds`) changes `skill.gd`'s line where the Cooldown starts (`:111`) and may move the lines below it: find lines by their text. Where this spec departs from the analysis is listed near the end.

## What changes and why

A Skill knows only a Faction today: `var faction: Faction.Id` (`skill.gd:53-55`), with no value of its own, so it holds the enum's first, the player's (`faction.gd:7`). After step 6 the Character hands it down when it is ready and in `add_skill()`. A Skill that misses the hand-down fights for the player without a word: the Attack and Fireball tests in four files activate their Skill with no Character at all, and hit zombies only because of that default. And a Skill has no way to its Character: a child reaching its parent is ruled out ("Call down, signal up"). Every Enemy Skill, a Blink or a Leap that moves its Character, and a cost would route around that gap; step 9's Hit has to name the Character that dealt it, and step 10 puts a ball beside its Character in the world.

So `Skill.character` replaces `Skill.faction`, and `Character._ready()` and `Character.add_skill()` set it where step 6 handed down the Faction. The Skill reads its Character's Faction at each activation.

Two holes in `skill.gd`, both open to every Skill script still to be written:

- **A Skill script that defines `_physics_process` stops its own Cooldown.** The base runs the Cooldown in its `_physics_process` (`skill.gd:83-85`), and in GDScript a subclass's function replaces its parent's of the same name. A channel, a beam or an orbit that forgets `super(delta)` is never ready again, and nothing says why. The Cooldown moves to internal physics processing, run from `_notification`, which Godot calls for every script that defines it.
- **An Aim with no direction reaches every Skill.** Each Skill goes where `aim.normalized()` points (`attack.gd:38`, `fireball.gd:31`). The Console's `activate 1 0 0` hands the Attack a zero Aim today (`player.gd:217-226`, `:111`), and so would a Range of 0, since every Aim the Player makes, except the mouse's, is Facing or a drag times the Range (`player.gd:134`, `:151`, `:160`, `:168`, `:174`). The swing then logs an engine error from `Basis.looking_at` and counts every hostile Hurtbox in Range as inside its Sweep. `try_activate` refuses such an Aim, once, for every Skill.

## The rules

1. **A Skill knows the Character that has it** (`Skill.character`). The Character sets it on each of its Skills when it is ready, and on a Skill given later with `add_skill()`. A Skill's own `_ready()` can run before it is set (a node's children are ready before it, and `add_skill()` sets it after adding the Skill), so a Skill script doesn't read it in `_ready()`.
2. **A Skill hits what is hostile to its Character's Faction**, as that Faction is at the activation (`hostile_mask()`). An Enemy's Skill hits the player's Faction, not the Enemies'.
3. **A Skill activated without a Character fails loudly.** In a debug build or the editor, `try_activate()` fails an assertion that names the Skill (the editor's debugger breaks), and nothing else happens: no Snapshot, no Cooldown, no effect, and it returns false. (Open rule 5: release builds.)
4. **A Skill runs its own Cooldown, whatever its script defines.** A Skill script with its own `_physics_process` still cools down, and `set_physics_process(false)` on a Skill doesn't stop its Cooldown. While the game is paused, the Cooldown waits, as today.
5. **An Aim needs a direction on the ground.** A ready Skill handed an Aim whose x and z are both zero (whatever its height) is not activated: `try_activate()` returns false, starts no Cooldown, does nothing, and prints an error naming the Skill. A Skill still on Cooldown returns false first, without the error (open rules 2 to 4).
6. **What a Skill does happens at the moment it is activated** (`_activate`'s doc; plan.md decision 6; open rule 1). Something it sets going, such as a ball, may go on by itself afterwards.

Nothing else changes in play.

## The change, file by file

### `skills/skill.gd`

- **The class doc** (`:4-8`) becomes:

  ```gdscript
  ## A Skill (see GLOSSARY.md): something a Character activates, the player from a Skill slot.
  ## Each Skill is a node under its Character's Skills node and knows that Character (see
  ## `character`), so it acts from where the Character stands and hits what is hostile to the
  ## Character's Faction. try_activate() is the one way to set it off. The Skill runs its own
  ## Cooldown, and a Skill script's own _physics_process() can't stop it. Subclasses do their work in
  ## _activate(). Each Skill script is a @tool, as this one is, so the editor shows its configuration
  ## warnings.
  ```

- **`:53-55`**, `faction`, becomes:

  ```gdscript
  ## The Character that has the Skill, set by that Character when it is ready and by
  ## Character.add_skill(). The Skill hits only Hurtboxes hostile to the Character's Faction, as it
  ## is at each activation. The Skill's own _ready() can run before it is set (a node's children are
  ## ready before it), so a Skill script doesn't read it there. A Skill without one can't be activated.
  var character: Character
  ```

- **`:83-85`**, `_physics_process`, goes. In its place:

  ```gdscript
  # The Cooldown runs on internal physics processing: a Skill script's own _physics_process()
  # replaces a parent script's, but _notification() is called for every script that defines it,
  # so a Skill script's own _physics_process() can't stop the Cooldown, by accident or with
  # set_physics_process(false).
  func _notification(what: int) -> void:
  	if what == NOTIFICATION_READY:
  		set_physics_process_internal(not Engine.is_editor_hint())
  	elif what == NOTIFICATION_INTERNAL_PHYSICS_PROCESS:
  		cool_down(get_physics_process_delta_time())
  ```

  The base then asks for no regular physics processing. A Skill script that defines `_physics_process` gets it as any script does. In the open editor a Skill doesn't tick, as today's `Engine.is_editor_hint()` check made sure; `@tool` stays (step 2 keeps it).

- **`:104-113`**, `try_activate`:

  ```gdscript
  ## Activates the Skill aimed at `aim` with the Character's `modifiers`: makes the activation's
  ## Snapshot, starts the Snapshot's Cooldown, then does what the Skill does. Whether it activated.
  ## A Skill still cooling down doesn't, and nor does one aimed with no direction on the ground,
  ## which also prints an error. A Skill without a Character fails an assertion.
  func try_activate(aim: Vector3, modifiers: Array[Modifier]) -> bool:
  	assert(character != null, "%s has no Character: give it to one with Character.add_skill()." % name)
  	if not is_ready():
  		return false
  	if Vector3(aim.x, 0.0, aim.z).is_zero_approx(): # every Skill goes where aim.normalized() points
  		push_error("%s: an Aim needs a direction on the ground." % name)
  		return false
  	# then today's three lines, :110-112, with step 1's Cooldown line as step 1 leaves it
  ```

  An assertion, as `standee.gd:46` and `console.gd:62` use for a mistake only code can make; a `push_error` for the Aim, which content can reach (a Range of 0). On a failed assertion the method returns its type's default, false ("the current method returns a default value", `@GDScript.assert`, 4.7).

- **`:128-133`**, `_activate`'s doc, gains one sentence, after "for a Skill that lands on a spot, its length is how far.":

  > What the Skill does happens in this call, at the moment it is activated; something it sets going, such as a ball, may go on by itself.

  And "an offset on the ground from the Character" becomes "an offset on the ground from the Character, with a direction".

- **`:141-143`**, `hostile_mask()`: its doc becomes "The layers of every Faction hostile to its Character's: where its hits look.", and it returns `Faction.hostile_mask(character.faction)`.

Unchanged: everything else. In particular `numbers()`, `snapshot()`, `number()`, `tags`, `cooldown`, `is_ready()`, `start_cooldown()`, `cool_down()` and `cooldown_fraction()` don't need a Character (step 2's content test reads Skills off the tree), and `_land_hits()` is step 9's.

### `characters/character.gd`

- In `_ready()` and in `add_skill()`, `skill.faction = faction` becomes `skill.character = self`.
- `add_skill()`'s doc: "and hands it its Faction" becomes "and becomes its Character (Skill.character)".
- The class doc stays: its Faction still "moves its Hurtbox and its Skills".

### Unchanged on purpose

`player.gd` (its own Auto-aim and ring read `Faction.hostile_mask(faction)`, the Character's own Faction), `enemy.gd`, `attack.gd`, `fireball.gd`, `projectile.gd`, every scene. No scene changes, so no resave.

## Process order

Step 6's `Skills` node puts every Skill ahead of the Skill bar, and with it each Skill's Cooldown ahead of the bar's requests in a frame (`.scratch/character/spec.md`, "Process order"). Moving the Cooldown to internal processing keeps that: Godot walks the nodes once per physics frame in the same order, and for each node sends the internal notification before the regular one (`SceneTree::_process_group`, 4.7-stable source). It skips a node that can't process before either, so a paused game stops the Cooldown as it does today.

## Tests

Run one file with `godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=test_<subject>.gd -gexit`, then `tools/check.sh`.

### Every test that activates a Skill, and how it gets a Character

| Tests | Lines | Activates | Its Character | Ticket |
|---|---|---|---|---|
| `test_attack.gd`: `test_a_swing_that_hits_two_enemies_freezes_the_world`, `test_a_swing_hits_a_zombie_and_not_the_players_faction_in_the_same_spot` | `:36-37`, `:55-56` | an Attack | the player's own, from `_players_attack()` | 01 |
| `test_projectile.gd`: `test_a_ball_in_flight_keeps_its_throws_snapshot`, `test_a_ball_in_flight_keeps_pierce_when_the_modifier_goes`, `test_a_fireball_hit_knocks_back_without_freezing_the_world`, `test_a_fireball_lowers_a_zombies_health_by_its_damage`, `test_a_piercing_ball_passes_through_the_zombie_it_kills_and_stops_at_the_next` | `:25-26`, `:113-114`, `:134-135`, `:161-162`, `:173-174` | a Fireball | the player's own, from `_players_fireball()`; the ball is still `fireball.get_child(0)` | 01 |
| `test_enemy_death.gd`, all five tests | `before_each`, `:12-13` | an Attack | the player's own | 01 |
| `test_health_bar.gd`, all four tests | `before_each`, `:10-11`; and `:31`, `:47` | an Attack | the player's own, kept in a `player` member that the two player tests use instead of adding their own | 01 |
| `test_skill.gd`: `test_activating_starts_the_cooldown_and_a_cooling_skill_does_not_activate`, `test_the_cooldown_is_the_snapshots`, `test_it_says_when_it_is_ready_again`, `test_it_runs_its_own_cooldown` | `_recording()`, `:63-68` | a recording Skill | a stand-in | 02 |
| `test_skill_bar.gd`, every test | `before_each`, `:13-27` | two bare Skills | one stand-in for both | 02 |

The helper, in `test_attack.gd` (and as `_players_fireball()` in `test_projectile.gd`, returning `Skills/Fireball`):

```gdscript
const PlayerScene := preload("res://characters/player/player.tscn")

## The player's own Attack, the player standing at the origin with its physics off (no camera here
## to read input against, as in test_player.gd).
func _players_attack() -> Attack:
	var player: Player = add_child_autofree(PlayerScene.instantiate())
	player.set_physics_process(false)
	return player.get_node("Skills/Attack")
```

The stand-in, in `_recording()` before it adds the Skill, and in `test_skill_bar.gd`'s `before_each` for `sword` and `fire`: `skill.character = autofree(Character.new())`. `test_skill_bar.gd`'s header says its stand-in for the Character also owns the Skills.

**Why the player's own Skills.** These tests are about the player's Attack and Fireball hitting zombies (`test_projectile.gd:49` already says "A ball the player's Fireball fired"), and the player is the one Character of the player's Faction. Its Skills stand at the origin, where the bare Skills stood. Its body changes nothing these tests check: it is on the `player` body layer, which no ball or Hurtbox query looks at, and a zombie that notices it doesn't move, because a test world has no navmesh and an agent without a path steers to where it already stands (`NavigationAgent3D.get_next_path_position()`, 4.7-stable source; `test_player.gd:251-259` already puts a zombie beside a player). **One Player per test:** a second registers the Console commands again, `Console.register()` asserts (`console.gd:62`, `test_console.gd:76`), and GUT fails the test on that error. Hence `test_health_bar.gd`'s two player tests use the `before_each` player.

**Why not a base scene.** There is no `character.tscn`: plan.md decision 3 puts none above `enemy.tscn`, and the analysis that assumed one for tests was assuming the other analyst's work, who has none. A test-only Character scene would be a third sort of Character that lives only in tests, in a file the editor resaves. A zombie set to the player's Faction would be the half-converted Enemy the glossary rules out ("A Character of the Enemies' Faction").

**Why a stand-in where the Skill never reaches its Character.** A recording Skill, and the base Skill's empty `_activate`, never read their Character; they need one only because activating without one fails (rule 3). A `Character.new()` kept out of the tree is enough: it never gets ready, so it looks nothing up. `test_skill_bar.gd` already stands in for the Character that answers its requests.

**Added by earlier steps.** Steps 1 to 5 may add tests that activate a bare Skill (step 1's shortest Cooldown is likely one). Step 3's tests appended to `test_skill_bar.gd` use its `before_each`, so they are covered. Ticket 02 runs `grep -n try_activate tests/` and gives every such Skill a Character the same way.

**Not changed:** `test_skill.gd`'s `before_each` Skill (`:11-15`) lands hits with `_land_hits()` and is never activated; `test_skill_slot_button.gd` cools Skills down and never activates them; `test_aim_modes.gd`'s test Skill has the player since step 6's `add_skill()`; `test_player.gd`, `test_skill_bar_hud.gd` and `test_pause_menu.gd` activate the player's own Skills.

### Changed assertions

In `test_character.gd` (ticket 01): `test_the_player_and_its_skills_are_of_the_players_faction` becomes `test_the_player_is_of_the_players_faction_and_its_skills_know_it` (`player.faction` is the player's; each Skill's `character` is the player, which now fails if `Player._ready()` forgets `super()`). `test_a_skill_given_later_takes_its_characters_faction` becomes `test_a_skill_given_later_knows_its_character` (its `character` is the zombie). The file's doc comment says "its Skills know it" where it said "its Faction reaches … its Skills".

### New tests

| Test | File, ticket | What it proves | On `master`, and on `character` |
|---|---|---|---|
| `test_an_enemys_swing_hits_the_players_faction_not_the_enemies` | `test_attack.gd`, 01 | Rule 2: an Attack given with `add_skill()` to a zombie at the origin, swung toward (1, 0, 0), hits a Hurtbox on the player's layer at (1, 0, 0.3) and not a second zombie at (1, 0, −0.3), nor its own zombie. | Fails on `master`: an Attack added to a zombie keeps the player's Faction and hits the zombie. Passes on `character`, where `add_skill()` hands the Faction down; it guards that a Skill hits by its Character's Faction once nothing hands a Faction down. |
| `test_a_skill_without_a_character_fails_loudly` | `test_skill.gd`, 02 | Rule 3: a recording Skill with a 1 s Cooldown and no Character, activated: `assert_engine_error("has no Character")`, no Snapshot recorded, `cooldown_left` still 0. | Fails: it activates. |
| `test_a_skill_with_its_own_physics_process_still_cools_down` | `test_skill.gd`, 03 | Rule 4: a Skill script that defines `_physics_process` (counting its frames), in the tree with a stand-in Character and the shortest Cooldown (`Skill.SHORTEST_COOLDOWN`, 0.1 s), activated: 8 physics frames later its own `_physics_process` has run and it is ready (0.1 s less six sixtieths leaves a crumb above 0, so it is ready on the 7th tick). | Fails: its `_physics_process` replaces the base's, and the Cooldown never runs. |
| `test_a_cooldown_waits_while_the_game_is_paused` | `test_skill.gd`, 03 | Rule 4: a recording Skill with a 1 s Cooldown, activated, then `get_tree().paused = true` for `wait_physics_frames(6)` (which counts the tree's frames, paused or not), unpaused before any assertion: `cooldown_left` is still 1.0; then 6 more physics frames, and it has gone down. | Passes: a guard. The reference says internal processing runs "even if the node is paused"; the 4.7-stable source skips a node that can't process. |
| `test_an_aim_with_no_direction_on_the_ground_is_refused` | `test_skill.gd`, 04 | Rule 5: a ready recording Skill activated with `Vector3.ZERO`, then with `Vector3(0, 0.3, 0)`: false both times, nothing recorded, no Cooldown, and two errors, each taken with `assert_push_error("direction on the ground")`. The second Aim fails a check on the whole vector. | Fails: it activates. |

## Checking by hand

On this branch, and the same on the base (`character`) where a comparison is asked for. The tools run `res://scenes/game.tscn`.

1. `tools/check.sh` passes.
2. **Play (F5).** Hold the Attack's key: it swings every 0.4 s, as on the base. Throw a Fireball: it hits a zombie, and its slot's sweep runs for 4 s and flashes when ready. Throw another, press Esc while the sweep runs, wait three seconds, close the menu: the sweep goes on from where it stopped. A swing and a Pierce Fireball (`modifier pierce on`) hit the pack as on the base.
3. **The zero Aim.** Console: `activate 1 0 0`. On the branch nothing swings, and the output (the editor's Debugger › Errors) shows "Attack: an Aim needs a direction on the ground." On the base, the Attack swings and an engine error from `Basis.looking_at` shows.

## Docs this reopens

**`GLOSSARY.md`**, committed with this spec on the branch (ticket 01's first commit). **Skill** (`:47-49`). Today: "Something the player activates from a Skill slot, such as Fireball or Attack. The Character has its Skills; the Skill bar is only where they are slotted." A Skill now belongs to any Character, and an Enemy's Skill is activated in a test. Becomes:

> **Skill**:
> Something a Character activates, such as Fireball or Attack; the player activates theirs from Skill slots. The Character has its Skills; the Skill bar is only where the player's are slotted.
> _Avoid_: Ability, spell, action, power

Faction, Character and Stagger still say what the code does. Activate stays as it is: refusing an Aim with no direction is a guard, not a step of activating.

**`docs/agents/godot-conventions.md`**: "Composition" gains two sentences after the `super()` rule, and "Call down, signal up" three (find them by their text):

> … `Player._ready()` and `Enemy._ready()` start with `super()`. The exception is `_notification`: the engine calls it on every script in the inheritance chain, base first, so never call `super()` in it, or the base's runs twice. `Skill` runs its Cooldown from `_notification`, so a Skill script may define `_physics_process()` freely: the Cooldown doesn't run there.
>
> … A parent may hand a child a reference to what the child needs, as a Character hands itself to each of its Skills (`Skill.character`), and the child may use what it was handed. What stays ruled out is a child finding its parent by itself, with `get_parent()` or a path. A Skill reads its Character's Faction through it today, to know what is hostile.

"Tests and checks", after the paragraph "A test that keeps a node's `_physics_process` from running …", gains a paragraph:

> … turns it back on when it becomes ready.
>
> A test that activates a Skill gives it a Character, as the game does: one of the player's own Skills (`player.get_node("Skills/Attack")`), or `add_skill()` on a Character in the tree. A Skill that never reaches its Character, such as one that only records its activations, may take a stand-in kept out of the tree: `skill.character = autofree(Character.new())`. One Player per test: a second registers the Player's Console commands again, and the Console's assertion fails the test.

**`.scratch/factions-health/spec.md`**, requirement 2 (`:20`), becomes: "**The Character calls down its Faction**: on `_ready` it puts its Hurtbox on `Faction.layer(faction)`, and each of its Skills knows it as its Character (`Skill.character`, set in `_ready` and by `add_skill()`), so the Skill queries `Faction.hostile_mask(character.faction)`. (Reopened by `.scratch/skill-character/spec.md`: a Skill knows its Character, not just its Faction.)"

**`.scratch/skill-tags/spec.md:44`**, the Skill bullet under "Where the code lives", becomes (keep whatever step 1 wrote there about the shortest Cooldown): "**Skill** (`skills/skill.gd`): `try_activate(aim, modifiers) -> bool` is the one path for an activation: no Character → an assertion fails; not ready → false; an Aim with no direction on the ground → false, with an error; otherwise build the Snapshot from `modifiers`, start the Snapshot's Cooldown, run the Skill's `_activate(snapshot, aim)` (Fireball's and Attack's override it), true. The Skill ticks its own Cooldown each physics frame, on internal physics processing so a Skill script's own `_physics_process` can't stop it, and emits `ready_again`. It keeps no list of Modifiers."

No ADR is touched.

## Seams

- **`skills/skill.gd`**: the class doc (`:4-8`), `:53-55`, `:83-85`, `try_activate` (`:104-113`), `_activate`'s doc (`:128-133`), `hostile_mask()` (`:141-143`). Step 1 changes the Cooldown line inside `try_activate` (`:111`), which this step keeps as step 1 leaves it, and may add lines above; step 2 leaves the file alone (and keeps `@tool`); step 3 reads `is_ready()`, `aim` and `repeats_while_held` from the HUD, none renamed here. **Step 9 (`hit`)** finds `character` to name a Hit's dealer, the only Character check in `try_activate()` (its `_hit()` may assert again), and `_land_hits()` (`:146-157`) untouched for it to replace. **Step 10 (`ball-in-world`)** finds `character` for putting a ball beside its Character; the Fireball tests already give their Fireball the player, in the tree.
- **`characters/character.gd`**: the two `skill.character = self` lines and `add_skill()`'s doc. Step 9 changes `_on_hit_taken()` only.
- **Tests:** `test_projectile.gd`'s five Fireball tests (step 2 changes `:15` and `:55`, step 10 rewrites the file); `test_enemy_death.gd`'s `before_each` (step 9 changes `:63-74`); `test_skill.gd`'s `_recording()` and the new tests at its end (step 9 moves `:11-40` to `test_hit.gd`); `test_skill_bar.gd`'s `before_each` (step 3 appends after `:166`); `test_attack.gd`, `test_health_bar.gd`, `test_character.gd`.
- **Docs:** `godot-conventions.md`, "Tests and checks", the `set_physics_process` paragraph (step 3 edits the touch paragraph, step 5 the tools paragraph, step 6 adds to "Composition"); `GLOSSARY.md` Skill; factions-health requirement 2 (step 6 took 1 and 7, step 9 takes rule 3 and requirements 3-4); `skill-tags/spec.md:44` (step 1 may edit the same bullet; steps 2 and 6 edit other lines).

## Open rules for the developer

1. **What `_activate` means.** Decided by the developer on 2026-11-22 (plan.md decision 6); listed to confirm against this wording. From the analysis's brief A:
   - **A. Instant only.** A Skill that wants a delay builds its own, and nothing cancels it unless that Skill does.
   - **B. An optional delay before the effect, run by the base Skill later**, 0 for every existing Skill. A Stagger or the Character's death cancels it.
   - **C. Phases: begin, land, end**, and a tick for channels. Attack and Fireball rewritten into them now.

   *In play:* under A, a zombie's swing hits the moment it decides to swing; under B, a red wedge shows where it will land and the swing lands half a second later, and a player who steps out takes nothing; under C, B's swings plus channels. *For the twentieth Skill script:* A and B, one method; C, up to three. *Recommended: confirm.* The sentence rules out C and keeps A and B open: a later delay runs between the Cooldown starting and `_activate`, and every existing Skill keeps a delay of 0. Without the confirmation, the sentence goes and nothing else in this spec changes.
2. **What counts as an Aim with no direction.** *Recommended:* the ground only: x and z both zero as `is_zero_approx()` tells, whatever the height, so an Aim straight up is refused too (`Basis.looking_at` fails on it as on zero). A non-finite Aim isn't this rule's: `SkillBar.NO_AIM` never reaches a Skill in the game (the Player replaces it, `player.gd:111`), and `test_skill_bar.gd`'s stand-in passes it to a Skill that ignores it.
3. **A Skill activated around its Character, with a zero Aim.** The Player hands such a Skill Facing times its Range (`player.gd:150-151`), and the Skill ignores it; with a Range of 0 that Aim is zero. *Recommended:* refused like any other: no Skill activated around its Character ships, and one with a Range of 0 reaches nothing. Revisit with the first such Skill whose Range can be 0; the fix then is the Player handing it Facing alone. The other way, an exception for `Skill.Aim.AROUND` in `try_activate`, puts a Skill setting into the one guard every Skill shares.
4. **Which check comes first, the Cooldown or the Aim.** *Recommended:* the Cooldown: a Skill still cooling down returns false with no error, since it wasn't going to activate. The other order prints an error for a press that was never going to do anything.
5. **A Skill without a Character in a release build.** The assertion is compiled out of release builds ("only executed in debug builds or when running the project from the editor", `@GDScript.assert`, 4.7). Such a Skill then fails where it first uses its Character (an Attack or a Fireball, with an error), or activates (a Skill that never reads it). *Recommended:* accept, as `standee.gd:46` and `console.gd:62` do: only code can make a Skill without a Character, and the tests and every debug run catch it. The other way, `push_error` and `return false`, refuses in every build but loses the debugger break.

Settled by the plan or the brief, not open: `Skill.character` replaces `Skill.faction`; `Character.add_skill()` sets it; a Skill activated without one fails loudly; `can_activate()` isn't built; no process priorities.

## Out of scope

| What | Trigger that brings it back |
|---|---|
| `can_activate()`: one question for the four places that ask whether a Skill can be activated | A second reason a Skill can't be activated: a cost, a staggered Character, a delay running |
| A delay before a Skill's effect, with its warning and its cancel (open rule 1, option B) | The first Skill with a warning, likely the first Enemy Skill |
| What an Aim holds | Step 11, designed with the developer (plan.md decision 5) |
| A floor on Range above 0, so the Player's Aims never come out zero | The first Modifier that can take a Range to 0. Until then the refused activation is what shows. |
| A Hit that names its dealer; a ball beside its Character in the world | Steps 9 and 10 |
| A ready Skill that stops ticking its Cooldown | A profile on the phone with packs of Enemies with Skills |
| A Hurtbox that follows a Faction changed in play | Charm |

### Found in review

- A Skill moved from one Character to another with `reparent()` keeps its old Character, with no assert. Nothing does this today.
- `add_skill()` on a Skill that already has a parent fails to add it but still sets `character`. Nothing does this today.
- A touch-aimed Skill dragged past the deadzone and lifted exactly where the thumb landed gets an Aim of zero length from the HUD. Before this step that threw a ball that never moved; now it is refused, with an error in the output. Left for the step that reworks how a Skill is aimed.
- The glossary's Aim entry says a Skill activated around the player has no Aim, while `try_activate` now needs every Aim to have a direction. The Player hands such a Skill its Facing, so nothing breaks. The entry's wording is left to the developer.

## Where this departs from the analysis

- A Skill without a Character fails at `try_activate()`, as the brief settles, not where it first uses the Character. So `test_skill.gd`'s recording Skills and `test_skill_bar.gd`'s Skills need a Character too; the analysis kept them unchanged.
- No base scene for tests: the hit-pipeline analysis assumed one from the Character analysis, which has none. The player's own Skills serve, with an out-of-tree stand-in for Skills that never reach their Character.
- `test_health_bar.gd`'s two player tests must use the `before_each` player, or the Console's assertion fails them. The analysis didn't see that.
- "A Skill added to an Enemy after it is ready hits a player-Faction Hurtbox" passes on the `character` branch already (step 6's `add_skill()` hands the Faction); it fails on `master`. It stays, as the test that a Skill hits by its Character's Faction.
- The analysis left the order of internal and regular processing, and the pause, to a run. The 4.7-stable source settles both, and a test pins the pause.
- `character` is set after the Skill is ready; its doc says so.

## Engine facts

Godot 4.7 class reference and manual, read on 2026-11-22, and the 4.7-stable source where marked.

1. **`_notification()` runs at every level.** `Object._notification`: "Unlike other virtual methods, this method is called automatically for every script that overrides it." `Object.notification()`: it sends the notification to every class the object inherits, "starting from the highest ancestor (the Object class) and going down to the object's script"; most notifications go "in the forward order (i.e. Object class first, most derived class last)".
2. **A subclass's function replaces its parent's.** GDScript reference: "functions in extending classes replace functions with the same name in their super classes". That is why a Skill script's `_physics_process` stops today's Cooldown.
3. **Internal physics processing is separate.** `Node.set_physics_process_internal()`: "Internal physics processing happens in isolation from the normal _physics_process() calls and is used by some nodes internally to guarantee proper functioning even if the node is paused or physics processing is disabled for scripting (set_physics_process())." `NOTIFICATION_INTERNAL_PHYSICS_PROCESS`: "received from the tree every physics frame when is_physics_processing_internal() returns true". `get_physics_process_delta_time()`: "identical to _physics_process()'s delta parameter", so a frozen frame (time scale 0) cools nothing, as today.
4. **Pause and order (4.7-stable source, `SceneTree::_process_group`).** A node that `!can_process()` is skipped before both notifications, so a paused Skill gets neither, whatever the reference's "even if the node is paused" suggests. For each node the internal notification is sent before the regular one, node by node in the order of fact 5 of step 6's spec.
5. **Overriding `_physics_process` switches it on.** `Node.set_physics_process()`: "If _physics_process() is overridden, this will be automatically enabled before _ready() is called." The base Skill no longer overrides it, so it gets no regular physics processing.
6. **A node's children are ready first.** `Node._ready()`: "If the node has children, their _ready() callbacks get triggered first". Hence rule 1's "set after the Skill itself is ready".
7. **A failed assertion.** `@GDScript.assert`: "If the condition is false, an error is generated and the current method returns a default value. When running from the editor, failed asserts also cause a debugger break"; the code inside it "is only executed in debug builds or when running the project from the editor". The 4.7-stable `gdscript_vm.cpp` returns the declared return type's default after the error.
8. **An agent without a path stands.** `NavigationAgent3D.get_next_path_position()` returns its parent's own position when the path is empty (4.7-stable source), so a zombie that notices a test's player doesn't move in a test world without a navmesh.
9. **GUT 9.7.1** fails a test on an unexpected engine error or `push_error`, and `assert_engine_error()` and `assert_push_error()` take one as expected (`addons/gut/test.gd`). `wait_physics_frames()` counts the tree's `physics_frame` signal (`addons/gut/awaiter.gd:58`, `:71-78`), which keeps coming while the game is paused; `wait_seconds()` doesn't.

## Done when

- [ ] `Skill.faction` is gone: a search for `.faction` under `skills/` finds only `character.faction`, and the Character's two lines set `skill.character`.
- [ ] Every Skill in the game knows its Character; a Skill activated without one fails its assertion and does nothing.
- [ ] A Skill script's own `_physics_process` can't stop its Cooldown; the Cooldown still waits while paused.
- [ ] An Aim with no direction on the ground is refused with an error; `_activate`'s doc says the effect happens at that moment.
- [ ] Every test listed is changed as listed, the new tests pass, and `tools/check.sh` passes.
- [ ] The docs above say what the code does, and "Checking by hand" matches the base, except `activate 1 0 0`.

## Tickets

1. `issues/01-skill-knows-its-character.md`: `Skill.character` replaces `faction`; the Attack and Fireball tests use the player's own Skills.
2. `issues/02-no-character-fails-loudly.md`: the assertion, and stand-ins for Skills that never reach their Character.
3. `issues/03-cooldown-on-internal-physics.md`: no Skill script can stop its Cooldown.
4. `issues/04-an-aim-needs-a-direction.md`: the zero Aim refused; `_activate` means now.
5. `issues/05-reopened-docs.md`: the conventions and the other specs.
6. `issues/06-check-and-pr.md`: the developer's checks by hand, `/code-review` and the PR.
