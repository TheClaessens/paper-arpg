# Touch interruptions

Status: ready-for-agent

Tickets 01 to 03 are built on the recommended answers to open rules 2 and 3, which the developer confirms when reading this step's PR. Ticket 05 waits for open rule 1.

A finger on a Skill slot can be taken away without lifting: the app loses focus (Control Center, Notification Center, a call, the side button, the app switcher), or iOS cancels the touch. This spec calls that a **lost finger**, in plain words, as `.scratch/touch-controls/spec.md` does for the Touch stick. A lost finger ends its slot's hold and its aim, and nothing is activated.

Today Godot 4.7 on iOS reports a cancelled touch as a release at (-1, -1), just off the screen's top-left corner, and the Skill slot's button takes it for a lift. So a Skill being aimed by a drag (Fireball) is activated toward the upper left the moment the game comes back. This step fixes that, makes the Skill bar let go of held slots when the app loses focus (a key held on the Mac needs it too), and adds a rule to the conventions so the next touch control doesn't copy the gap. Last, and only if the developer wants it: a thumb held on a slot through its Skill's Cooldown repeats the Skill when the Cooldown ends, as a held key does.

From `.scratch/future-proofing-review/analysis/ui-game-root.md` (S5, M1 to M5, work packages 1 and 2), checked against the code at `8797660` and the Godot 4.7-stable source (see "Engine facts"). Step 3 of `.scratch/future-proofing-review/plan.md`. Nothing changes on screen, so there is no design pass, and no scene changes.

## The rules

1. **A lost finger activates nothing.** When the finger on a Skill slot's button is lost, the slot's hold ends (the Skill bar lets go of the slot), its aim ends, the aim marker hides, and nothing is activated, however far the finger had dragged. The button forgets the finger: whatever that finger does afterwards is ignored, and the next finger to land is taken as usual.
2. **A release the system makes is a lost finger, not a lift.** A release of the button's finger that is `canceled`, or that lies left of or above the screen (a negative x or y), is a lost finger. Godot 4.7 on iOS reports a touch the system cancels as a release at (-1, -1) with `canceled` false; Android sets `canceled`.
3. **The app losing focus loses every finger on the Skill slots.** Each button that has a finger loses it on `NOTIFICATION_APPLICATION_FOCUS_OUT`. On iOS the cancelled touch can arrive before the notification (the engine delivers it inside its focus-loss handling), after it (with the first frame back), or not at all. In every order each finger is lost exactly once.
4. **A pause or the app losing focus lets go of every slot the Skill bar holds**, whatever holds it: a key, a mouse button, a controller button or a thumb. The pause half is today's rule. The focus half is new: when the app loses focus the engine lets go of held keys without sending an event, so `Controls` never reports the release. Afterwards a binding holds its slot again only once it is pressed again.
5. **A pause loses no finger on a Skill slot.** The pause menu and the Console both pause the game. The Skill slots' buttons and the HUD (`SkillBarHud`) run while paused, so a finger already on a slot is followed to its lift. A lift during the pause activates nothing. A lift after it works as usual: an aimed Skill is activated where it was aimed. A slot the Skill bar let go of at the pause (rule 4) is held again at the thumb's next movement. A finger that lands on a slot during the pause isn't taken. All of this is today's behaviour, kept; see open rule 2.
6. **A Skill taken out from under a thumb ends its hold and its aim too.** When a slot's Skill changes while a thumb holds or aims that slot (the Skill drawer, or the `bar` command, both while paused), the hold and the aim end as in rule 1, and the thumb's lift activates nothing. Today the thumb's next movement aims whatever is now in the slot, its lift activates that, and an emptied slot raises a script error (`aim_from_drag` with a null Skill, `player.gd:122-124`).
7. **The HUD leaving the tree loses nothing.** It leaves only with the whole game scene, or for an instant inside the Console's `collisions` command (`console.gd:198-201`), which runs while paused, and no event can arrive between the remove and the add. The buttons and the HUD keep their state across it. No code.
8. **A thumb held through a Cooldown** is open rule 1 and ticket 05.

## What holds what, and what each loss does

After this step; "today" marks a change. Line numbers are on `master` at `8797660`.

| What | Where | A touch the system cancels | The app loses focus (iOS) | The app loses focus (Mac) | A pause (pause menu, Console) | The slot's Skill changes | The HUD leaves the tree |
|---|---|---|---|---|---|---|---|
| The button's finger | `SkillSlotButton._finger` | lost: `touch_lost` (today: `touch_ended` at (-1, -1)) | lost: `touch_lost`, in any order (today: kept until a release with its index) | the same for the mouse emulating a touch; otherwise no finger | kept, followed to its lift | kept; its moves and lift then do nothing | kept |
| The HUD's held slot | `SkillBarHud._held_slot` | ends | ends (today: kept until a cancel arrives) | the same for an emulated touch | kept; holds the Skill bar's slot again at the thumb's next movement | ends (today: kept, steering the new Skill) | kept |
| The HUD's aim | `_aiming_slot`, with `_aimed`, `_left_slot`, `_landed` | ends, nothing activated (today: activated toward the top-left, at full Range) | ends, nothing activated (today: activated toward the top-left when the cancel arrives, before the focus loss or with the first frame back) | the same for an emulated touch | kept; a lift during the pause activates nothing, a lift after it activates | ends, nothing activated (today: the new Skill is activated; a script error if the slot was emptied) | kept |
| The aim marker | `AimMarker`, on the Player | hidden | hidden (today: only once a cancel arrives) | hidden | kept as it was | hidden (today: shows the new Skill at the next move) | kept |
| The Skill bar's holds | `SkillBar._held` | the slot let go, through the HUD | every slot let go (today: only through a cancel read as a lift) | every slot let go (today: kept, so a held key's Attack repeats until the key is pressed again) | every slot let go (today, unchanged) | the slot let go, through the HUD | already let go: the Console paused the game |
| The Skill bar's presses not yet worked through | `SkillBar._pressed`, `_pressed_aims` | none added (today: one) | kept, worked through on the first physics frame back (open rule 3) | kept (open rule 3) | kept, worked through after the pause (open rule 3) | kept | kept |
| For comparison: the Touch stick | `TouchStick._finger`, the `move_*` actions it pressed | let go (read as a lift, which for a stick is the same) | let go | let go | let go; the thumb does nothing until it lifts and lands again | n/a | kept (it let go at the pause) |

## The change, file by file

### `skills/skill_bar.gd` (ticket 01)

- Line 11, the class doc comment: "Pausing lets go of every slot." becomes "Pausing, or the app losing focus, lets go of every slot."
- `_notification` (lines 72-75) lets go on both:

```gdscript
func _notification(what: int) -> void:
	# A binding held through a pause or a focus loss may be let go of unheard: Controls is
	# paused, or the engine releases keys without an event when the app loses focus.
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_held.clear()
```

`press`, `set_held` and `advance` keep their contracts. Presses not yet worked through are kept (open rule 3).

### `ui/skill_slot_button.gd` (ticket 02)

The button's signals after the change:
- `touch_started(at)` and `touch_moved(at)`: unchanged.
- `touch_ended(at)`: only for a lift, a release of the button's finger that isn't `canceled` and lies at x ≥ 0 and y ≥ 0.
- `touch_lost` (new): the button's finger was lost (rules 2 and 3). Once per finger, and never with `touch_ended` for the same finger.

Sketch:

```gdscript
## The finger was taken away without lifting: the system cancelled its touch, or the app lost focus.
signal touch_lost

# _input, the release branch (lines 106-109):
		elif not touch.pressed and touch.index == _finger:
			get_viewport().set_input_as_handled()
			if _is_lift(touch):
				_finger = NO_FINGER
				touch_ended.emit(touch.position)
			else:
				_lose_finger()


func _notification(what: int) -> void:
	# The app losing focus can take the finger with no lift this button hears. A pause can't:
	# the button runs while paused (it inherits the HUD's process_mode ALWAYS, so it never gets
	# NOTIFICATION_PAUSED) and follows its finger to the end.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_lose_finger()


func _lose_finger() -> void:
	if _finger == NO_FINGER:
		return
	_finger = NO_FINGER
	touch_lost.emit()


## Whether `touch`, a release, is a lift and not the system taking the touch away. Android marks
## a taken touch `canceled`; Godot 4.7 on iOS doesn't, and puts it at (-1, -1).
# ponytail: a lift left of or above the window (the Mac's mouse emulating touch) counts as lost;
# drop the position check once Godot on iOS sets `canceled`.
static func _is_lift(touch: InputEventScreenTouch) -> bool:
	return not touch.canceled and touch.position.x >= 0.0 and touch.position.y >= 0.0
```

Class doc comment (lines 3-8): "reports where it goes and where it lifts" becomes "reports where it goes and where it lifts, or that the finger was lost without lifting".

### `ui/skill_bar_hud.gd` (tickets 02 and 03)

- `_ready` (lines 49-51): `button.touch_lost.connect(_let_go.bind(slot))`.
- New `_let_go(slot)`: the first half of today's `_on_touch_ended` (lines 127-134), on its own. It ends the slot's hold and aim and hides the aim marker, and activates nothing. For a slot that is neither held nor aimed it does nothing.
- `_on_touch_ended` (lines 126-141) lets go through `_let_go`, then activates an aim as today. A lift behaves exactly as before; the existing tests in `test_skill_bar_hud.gd` guard it.
- Ticket 03: `_on_slot_changed` (lines 76-77) also calls `_let_go(slot)` (rule 6).
- Class doc comment (lines 8-11), one sentence more: "A thumb taken away without lifting (the app losing focus, or the system cancelling the touch) ends its hold and its aim, and activates nothing." Ticket 03 adds: "So does a change of the slot's Skill under the thumb."

```gdscript
## The thumb on `slot` is gone without lifting, or its Skill changed under it: its hold and its
## aim end, and nothing is activated.
func _let_go(slot: int) -> void:
	if slot == _held_slot:
		_held_slot = SkillBar.NONE
		player.skill_bar.set_held(slot, false)
		player.hide_aim()
	if slot == _aiming_slot:
		_aiming_slot = SkillBar.NONE
		player.hide_aim()


func _on_touch_ended(at: Vector2, slot: int) -> void:
	var aiming := slot == _aiming_slot
	_let_go(slot)
	var skill := player.skill_bar.skill_in(slot)
	if not aiming or get_tree().paused or skill == null:
		return
	if not _aimed:
		player.skill_bar.press(slot) # a tap: auto-aimed
	elif not _over_cancel(slot, at):
		player.skill_bar.press(slot, player.aim_from_drag(skill, at - _landed[slot], drag_full_range))
```

### Not changed

- `characters/player/controls.gd`: it reports bindings as they are pressed and let go. The Skill bar's let-go (rule 4) covers the release it never hears.
- `characters/player/player.gd`, `characters/player/aim_marker.gd`: the HUD keeps calling `hide_aim()`.
- `ui/touch_stick.gd`: it already lets go on a pause and on focus loss, and a cancelled touch reaches it as a release, which for a stick means the same.
- `ui/pause_menu.gd`, `autoloads/console/console.gd`, every scene.

## Tests

Modelled on `tests/test_touch_stick.gd`: a small helper per kind of event, one rule per test, and a control step where a test could otherwise pass by doing nothing. How the losses are simulated:
- A touch the button follows: `get_viewport().push_input(event, true)` (the conventions, "Tests and checks"), a new event object each time, finger index 0. Two helpers per file, `_push_touch(at, pressed, canceled := false)` and `_push_drag(to)`.
- The iOS cancel: a release pushed at `Vector2(-1, -1)`.
- Focus loss: `notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)` on the node, as `test_losing_focus_releases_the_actions` does for the stick, or `propagate_notification` on the HUD to reach its buttons.
- The HUD alone: emit the button's `touch_started`/`touch_moved`/`touch_ended`/`touch_lost` (the conventions).
- A pause: `get_tree().paused = true`, set back to false inside the test.

In `test_skill_slot_button.gd`, place the button clear of the Console's corner button first (`button.place(Vector2(300, 300), 88.0)`), so a pushed touch can't land on both. In `test_skill_bar_hud.gd`, append at the end, reach Skills through the fixture's `button` (Slot1, Fireball) or `player.skill_bar.skill_in(slot)`, never `player.get_node("Fireball")` (see Seams), and read the aim marker as `(player.get_node("AimMarker") as Node3D).visible`.

| # | Test | File | Proves | Fails on `master`? |
|---|---|---|---|---|
| 1 | `test_losing_focus_lets_go` | `test_skill_bar.gd`, after `test_pausing_lets_go` | Rule 4: after focus loss a held repeating Skill isn't activated again. The twin of `test_pausing_lets_go`, with `bar.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)`. | Yes: 2 activations, not 1. |
| 2 | `test_a_touch_the_system_cancels_is_not_a_lift` | `test_skill_slot_button.gd` | Rules 2 and 3, the cancel first: a pushed tap ends with `touch_ended` (control step); a press, then a release at (-1, -1), ends with `touch_lost`; the focus loss after it emits nothing more. `touch_ended` once, `touch_lost` once. | Yes: no `touch_lost`, and `touch_ended` twice. |
| 3 | `test_a_release_marked_canceled_is_not_a_lift` | same | Rule 2, the engine's own flag: a release at the button's centre with `canceled = true` emits `touch_lost`, not `touch_ended`. | Yes. |
| 4 | `test_losing_focus_lets_go_of_the_finger` | same | Rule 3, the focus loss first (the cancel late or never), and rule 1's "forgets the finger". With no finger, focus loss emits nothing. With one: one `touch_lost`; that finger's later drag and release (same index, at the centre) emit no `touch_moved` and no `touch_ended`. | Yes. |
| 5 | `test_a_touch_the_system_cancels_mid_aim_activates_nothing` | `test_skill_bar_hud.gd` | Rules 1 and 2 end to end, the reported defect: a press pushed at the Fireball slot's centre, a drag 120 units left (the aim marker shows), a release at (-1, -1), `_elapse(0.016)`. `aims` stays empty and the aim marker is hidden. | Yes: Fireball is asked for, aimed toward the top-left. |
| 6 | `test_losing_focus_lets_go_of_a_held_thumb` | same | Rules 1 and 3 for a hold: a press pushed on the main slot (the Attack, held), `_elapse(0.016)`, `hud.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)`, a 2-unit drag pushed with the same index, `_elapse(0.5)`: one activation. The notification goes to the HUD alone, so the Skill bar's own let-go (test 1) can't hide a broken HUD path; the drag shows the button no longer follows the finger (if it did, steering would hold the slot again). | Yes: nothing lets go, and the Attack repeats. |
| 7 | `test_a_lift_during_a_pause_activates_nothing` | same | Rule 5, through `_on_touch_ended`'s new shape: Fireball's `touch_started`, `touch_moved` 120 units left, pause, `touch_ended`, unpause, `_elapse(0.016)`: `aims` stays empty. | No: it guards today's behaviour. |
| 8 | `test_a_skill_changed_under_an_aim_activates_nothing` | same (ticket 03) | Rule 6: Fireball's `touch_started`, `touch_moved` 120 units left, `player.skill_bar.set_skill(1, player.skill_bar.skill_in(0))` (the Attack, as the Skill drawer would), `touch_ended`, `_elapse(0.016)`: `aims` stays empty and the aim marker is hidden. | Yes: the Attack is activated with the drag's aim. |
| 9 | `test_a_thumb_held_through_the_cooldown_repeats_when_it_ends` | same (ticket 05) | Open rule 1, on the main slot (the Attack, 0.4 s Cooldown). Control step: a tap during the Cooldown activates nothing, even once the Cooldown has ended (`_elapse(0.5)` after it). Then tap again to start a fresh Cooldown, and land a thumb that stays: nothing more after `_elapse(0.2)`, one more activation after another `_elapse(0.3)`. Elapse past the Cooldown's end with a margin, never exactly 0.4. | Yes: the held thumb is ignored. |
| 10 | `test_an_aimed_skill_cooling_down_shows_no_aim` | same (ticket 05) | Open rule 1's aimed case: tap Fireball, `_elapse(0.016)`; land again and drag 120 units: no aim marker; `_elapse(5.0)`, lift, `_elapse(0.016)`: still one activation. | No: it guards that ticket 05 keeps the aimed check. |

No test for rule 7: it needs no code.

## Hand tests

On the iPhone, with `tools/deploy_ios.sh` or the editor's Remote Debug (to see script errors). Run 1 on `master` first, to see the stray Fireball, then everything on the branch. No gesture reliably cancels a touch while the app keeps focus; tests 2, 3 and 5 cover that case.

1. **Aiming through an interruption.** In the Console, `bar 2 fireball`. Drag Fireball off its slot until the aim marker shows, and keep the thumb there. With the other hand: (a) swipe down from the top-right corner for Control Center, then dismiss it; (b) swipe down from the top centre for Notification Center, then dismiss it; (c) press the side button, unlock, and come back to the game; (d) swipe up from the bottom edge and hold for the app switcher, then tap the game. Swipe a second time if the first only shows a small tab. Each time, on return: no Fireball, no Cooldown sweep on its slot, no aim marker, and lifting the thumb (if it's still down) does nothing. On `master`, expect the sweep and a Fireball toward the upper left.
2. **Holding through an interruption.** Hold the main slot until the Attack repeats; do (a), then (c). On return the Attack isn't repeating, until the thumb lifts and lands again.
3. **A pause while aiming.** Drag Fireball until the marker shows, tap the pause button with the other thumb, lift the aiming thumb, tap Resume: no Fireball. Again, but tap Resume before lifting: Fireball goes where it was aimed. Then the same with the Console: open it with its corner button, lift, close it with the same button: no Fireball.
4. **A Skill taken out from under the thumb.** Drag Fireball (slot 2) until the marker shows. With the other hand: pause, Skill bar, slot 2, Empty, then Back twice. Move the aiming thumb and lift: no marker, nothing activated, no error in the debugger.

On the Mac, from the editor:

5. **A key held through Cmd-Tab.** In the Console, `bar 3 attack`. Hold Q until the Attack repeats, Cmd-Tab to another app, let go of Q, Cmd-Tab back: the Attack isn't repeating. On `master` it should keep repeating; confirm once.
6. **Mouse, controller, and the mouse as a finger.** As 5, holding the left mouse button over the ground instead of Q, then the controller's A if one is connected: the Attack isn't repeating on return. Then drag Fireball off its slot with the mouse, Cmd-Tab away with the button still down, let go, come back: no Fireball, no marker.

If an interruption still activates a Skill: add a temporary `print` of each `InputEventScreenTouch` and of `NOTIFICATION_APPLICATION_FOCUS_OUT` in `SkillSlotButton`, run with Remote Debug, and note which came first for that interruption.

## Docs this reopens

1. `.scratch/aiming/spec.md:64` (ticket 02) becomes:
   > - **Holding repeats the Attack** (device test, 2026-11-16). A Skill marked `repeats_while_held` (only Attack for now) is activated again each time its Cooldown ends while its slot is held, with keys, mouse, controller and touch alike. On touch, dragging while holding steers the following swings and shows the aim line. Inside the deadzone they auto-aim again. Lifting just stops: no extra activation, no cancel zone. A pause or the app losing focus lets go of every slot, because a release during either may never arrive. A thumb taken away without lifting ends its hold and its aim and activates nothing (`.scratch/touch-interruptions/spec.md`).

   The line's "is used again each time the Use time ends" was left behind when Use time was removed; the new wording fixes it. Ticket 05 appends: "A thumb that lands on the slot while the Cooldown runs holds it too, as a key does: the Skill is activated the moment the Cooldown ends."
2. `.scratch/touch-controls/spec.md:23` (ticket 02) becomes:
   > - **Lost finger:** on pause (the Console opening) or `NOTIFICATION_APPLICATION_FOCUS_OUT`, it releases the actions and hides. A touch the system takes away arrives as a release (at (-1, -1) on iOS) and lets go the same way. The Skill slots' buttons follow the same rule, but keep a finger through a pause: `.scratch/touch-interruptions/spec.md`.
3. `docs/agents/godot-conventions.md`, "Tests and checks", the paragraph that starts "A test that simulates a screen touch" (line 50 on `master`; `content-checks` adds a section above it, so find it by its text) (ticket 02): "emitting its `touch_started`/`touch_moved`/`touch_ended` signals tests the HUD without one." becomes "emitting its `touch_started`/`touch_moved`/`touch_ended`/`touch_lost` signals tests the HUD without one. A release pushed at (-1, -1) is a touch the system took away, as iOS reports it."
4. `docs/agents/godot-conventions.md`, "Input and UI" (ticket 02), a bullet appended after its last one, the `Basis.scaled()` bullet (line 69 on `master`):
   > - A touch control that follows a finger by its index (the Touch stick, a Skill slot's button) handles a lost finger. It lets go of the finger on `NOTIFICATION_APPLICATION_FOCUS_OUT`, and a release that is `canceled`, or at a negative x or y, never does what a lift does: Godot 4.7 on iOS reports a touch the system takes away as a release at (-1, -1) with `canceled` false, before the focus loss or after it. The Touch stick's lift only lets go, so it needs no check; a Skill slot's lift activates, so its button checks (`SkillSlotButton._is_lift`). A node that runs while paused (`process_mode` ALWAYS, its own or inherited) never gets `NOTIFICATION_PAUSED`, so it can't count on that to let go on a pause. Copy the tests in `test_skill_slot_button.gd`. The third such control gets a shared piece instead of a third copy.
5. `GLOSSARY.md`: no change. This spec uses its words, with "lost finger", "hold", "lift", "aim marker" and "pause menu" as plain words.

## Seams

This step is stacked on `content-checks` (step 2), which is stacked on `number-bounds` (step 1). `character` (step 6) and `skill-character` (step 7) come after it.

- `skills/skill_bar.gd`: line 11 (the class doc comment's "Pausing lets go of every slot.") and lines 72-75 (`_notification`). Nothing else. Ticket 05 doesn't touch it.
- `characters/player/player.gd`: no change. The HUD keeps using `skill_bar`, `skill_activated`, `aim_from_drag`, `show_aim` and `hide_aim`, which `character` and `skill-character` keep.
- `skills/skill.gd`: no change. The HUD reads `is_ready()`, `aim` and `repeats_while_held` in `_on_touch_started` (`skill_bar_hud.gd:97-106`); ticket 05 moves the `is_ready()` call into the aimed branch. If `skill-character` renames `is_ready()`, or the later aiming step renames `Skill.Aim.AIMED`, ticket 05 follows the new name.
- `tests/test_skill_bar_hud.gd`: tests and helpers appended at the end only. Lines 24 (`player.get_node("Fireball")`) and 36 are left to `character`, which moves the Skills under a `Skills` node. The new tests read the aim marker as `player.get_node("AimMarker")`; if `character` moves it, that line follows.
- `tests/test_skill_bar.gd` (after line 166) and `tests/test_skill_slot_button.gd` (after line 52): appended at the end.
- `docs/agents/godot-conventions.md`: one sentence in the "Tests and checks" paragraph on screen touches (line 50 on `master`) and one bullet at the end of "Input and UI" (after line 69 on `master`). `content-checks` edits line 37 and adds a "Saved content" section after "Scenes live in the editor", which moves both lines down; find them by their text. `character` adds lines in other sections. Don't reflow the paragraphs around these lines.
- `ui/skill_slot_button.gd`, `ui/skill_bar_hud.gd`, `.scratch/aiming/spec.md:64`, `.scratch/touch-controls/spec.md:23`: no other step touches them.

## Open rules (settle with the developer before code)

1. **A thumb held through a Cooldown repeats like a held key (ticket 05).** Today a thumb that lands on a slot while its Skill's Cooldown runs does nothing until it lifts and lands again (`skill_bar_hud.gd:98`). A held key or controller button holds its slot whatever the Cooldown, and the Skill bar activates a repeating Skill the moment the Cooldown ends (`skill_bar.gd:91-94`). The aiming spec already says holding repeats "on every input" (`aiming/spec.md:64`).

   | Case | Touch today | A held key or button | Touch, proposed |
   |---|---|---|---|
   | Tap during the Cooldown (Attack) | nothing | nothing: a press during a Cooldown is ignored | nothing |
   | Land during the Cooldown and hold (Attack) | nothing until the thumb lifts and lands again | activated the moment the Cooldown ends, then repeats | as the key |
   | Drag while that hold waits | nothing | n/a | steers it; the aim line shows before the first swing |
   | Land on Fireball, aimed by drag, during its Cooldown | no aim marker; its lift activates nothing, even after the Cooldown has ended | nothing: Fireball doesn't repeat | unchanged |

   **Recommendation: yes.** Touch then works as the controller does: the HUD passes presses and holds on, and the Skill bar alone decides whether they count. It changes how mashing the Attack feels on the phone (a thumb that lands a little early attacks as soon as it can, instead of doing nothing), so try it on the phone before keeping it. The aimed case stays: an aim kept through the Cooldown would be a buffered press, and the Skill bar buffers none.
2. **A thumb kept on a Skill slot through a pause.** Rule 5 keeps today's behaviour; the Touch stick instead drops a thumb held through a pause (`touch-controls/spec.md:54`).
   - A hold: today the Attack repeats again from the thumb's next movement, even one during the pause. The alternative: nothing until the thumb lifts and lands again, as the stick.
   - An aim: a lift during the pause activates nothing either way. A lift after the pause: today the aimed Skill is activated; the alternative activates nothing.
   - The alternative's cost: the HUD runs while paused and gets no pause notification, and `SceneTree` has no signal for a pause, so the Skill bar would have to signal its let-go for the HUD to drop holds and aims. About 6 lines and a test.

   **Recommendation: keep today's.** The stick drops its thumb because, paused, it can't hear the lift. The Skill slots run while paused and hear every lift, so nothing is lost. The case also takes a second hand on the pause button while a thumb stays on a slot.
3. **A press not yet worked through when the game pauses or the app loses focus.** A tap's press waits for the next physics frame (`SkillBar._pressed`). A pause or a focus loss in that same frame keeps it, and the Skill is activated on the first physics frame after.
   - Keep (today): the tap was real; it is activated late.
   - Drop: two lines in `SkillBar._notification` (`_pressed.clear()`, `_pressed_aims.clear()`) and a test.

   **Recommendation: keep.** Once rules 2 and 3 hold, only a tap lifted in the same frame as the interruption reaches it.

## Out of scope

- **Opening the pause menu when the app loses focus** (brief 3, option B in the analysis). It would take, in `ui/pause_menu.gd`, a `_notification` that calls `open()` on `NOTIFICATION_APPLICATION_FOCUS_OUT` while `_view == View.PLAY`. The menu gets the notification although it runs while paused, and `open()` already waits for the Console. Plus one test in `tests/test_pause_menu.gd`: the notification opens the menu and pauses; a second one while it is open changes nothing. For the phone only, add `OS.has_feature("mobile")`, so switching to the editor while playtesting on the Mac doesn't pause. It doesn't replace this step: on iOS the cancelled touch can arrive before the notification, so rules 1 to 3 are still needed. Trigger: the developer asks for it (the plan's table).
- **A shared piece that follows a finger for every touch control.** Trigger: a third touch control (a dodge button, a potion button). Until then the conventions rule carries the two traps.
- **Letting go when a touch control leaves the tree.** The Touch stick's `move_*` actions are global and would stay pressed. Trigger: the HUD can leave the tree while a thumb is down (a scene change while playing, a death screen).

## Known limits

- A lift left of or above the window counts as a lost finger. Only the Mac reaches it, with the mouse emulating touch: an aim dragged out of the window and let go there is dropped instead of activated.
- Which comes first on iOS, the cancelled touch or the focus loss, is unverified for each interruption. The rules hold in every order.

## Engine facts

Checked against the Godot `4.7-stable` source and its class reference (the tag's `doc/classes`, which docs.godotengine.org/en/4.7 is built from).

1. On iOS a touch the system cancels becomes a release at (-1, -1) with `canceled` false: `drivers/apple_embedded/godot_view_apple_embedded.mm:387-394` (`touchesCancelled`) calls `display_server_apple_embedded.mm:304-306`, which calls `touch_press(index, -1, -1, false)` (`:272-281`). Android sets `canceled` (`platform/android/android_input_handler.cpp:144-163`).
2. iOS hands out the lowest free touch index (`godot_view_apple_embedded.mm:315-333`), so a lost finger's index goes to a later finger.
3. Input events are buffered (`Input.use_accumulated_input`, on by default: `core/input/input.h:165`, `input.cpp:1549-1557`) and flushed each frame before it runs (on iOS, `os_apple_embedded.mm:221-240` calls `display_server_apple_embedded.mm:242-244`).
4. When the app loses focus, `SceneTree` marks it unfocused and calls `Input.release_pressed_events()`, which first flushes the buffered events into the game; only then does it send `NOTIFICATION_APPLICATION_FOCUS_OUT` to every node (`scene/main/scene_tree.cpp:934-947`, `core/input/input.cpp:1600-1606`). A cancel buffered before the focus loss reaches the buttons before the notification.
5. On iOS the focus loss stops the frames after the notification (`os_apple_embedded.mm:774-790`), and on focus in `release_pressed_events()` does nothing (`input.cpp:1602-1604`). A cancel that comes after the focus loss arrives with the first frame back.
6. `release_pressed_events()` releases keys, and actions held by keys or mouse buttons, with `action_release`, which sends no event (`input.cpp:1428-1444`, `:1611-1645`). With `input_devices/joypads/ignore_joypad_on_unfocused_application` off (the default, `input.cpp:2374`, not set in `project.godot`) it leaves actions held only by a controller pressed and keeps reading the controller while unfocused. **Unverified, needs a run on the Mac:** whether macOS delivers a controller button's release to an app in the background (hand test 6).
7. macOS sends the focus loss from `applicationDidResignActive` (`platform/macos/godot_application_delegate.mm:221-229`).
8. `NOTIFICATION_PAUSED` reaches only nodes whose ability to process changes, so never a node that runs with `process_mode` ALWAYS, its own or inherited (`scene/main/node.cpp:727-742`; the class reference only says "received when the node is paused"). `SceneTree` has no signal for the pause changing (class reference, SceneTree's signals).
9. `InputEventScreenTouch.canceled` ("If true, the touch event has been canceled") survives the viewport's transform (`core/input/input_event.cpp:1382-1396`).
10. A release at window pixel (-1, -1) stays negative in viewport units: with `canvas_items` and `expand` the root viewport's transform is a pure scale, with no margin (`scene/main/window.cpp:1394-1412`, `scene/main/viewport.cpp:1467-1480`). On the iPhone 17 Pro it lands near (-0.54, -0.54); the exact value is unverified.
11. `Viewport.push_input(event, true)` takes the position in viewport coordinates and applies no touch or mouse emulation (class reference).
12. **Unverified, needs a run on the device:** for each interruption (Control Center, Notification Center, the side button, the app switcher, a call), whether UIKit cancels the touches, and whether before or after the app resigns active. Tests 2 and 4 run both orders.
13. **Unverified, needs a run on the device:** that no real lift on the phone lies at a negative position. UIKit reports touches inside the full-screen view and the engine truncates to whole pixels, so a lift would have to land a third of a point off the screen. If one did, an aim would be dropped instead of activated.

## Done when

- Tickets 01 to 03 are on the branch with their tests, and `tools/check.sh` passes.
- Ticket 04's hand tests pass on the iPhone and the Mac, and hand test 1 showed the stray Fireball on `master` (or the developer noted that it didn't).
- The conventions, `aiming/spec.md:64` and `touch-controls/spec.md:23` carry the new wording.
- The developer's answers to the open rules are written into this spec under a "Decisions" heading, and ticket 05 is done or marked `wontfix`.
