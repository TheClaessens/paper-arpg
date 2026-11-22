# UI and the game root: findings checked against the code

Scope: `ui/`, `scenes/sandbox.tscn`, `autoloads/`, `rendering/`, `project.godot`, `tools/simulate.gd`, `tools/screenshot.gd`, `tools/bake_navmesh.gd`, `tools/deploy_ios.sh`, and the parts of `player.gd`, `controls.gd` and `aim_marker.gd` the UI calls into. Master at `8797660`. Nothing was run and nothing outside this file was changed.

Engine behaviour was checked against the Godot **4.7-stable** source (the local editor reports `4.7.stable.official.5b4e0cb0f`) and the 4.7 class reference. The source lines are listed under "Engine claims checked" at the end. Where only a device or desktop run can settle something, it says "needs a run" and what to run.

Names marked *(proposed)* are not in `GLOSSARY.md`.

## Summary

- **S5 is a real defect, but not the one Sol describes.** On iOS, Godot 4.7 reports a touch the system takes away (Control Center, a call, the lock button) as an ordinary lift at the screen's top-left corner, (-1, -1), with `canceled` left false. The Skill slot buttons read it as the thumb lifting there. A held Attack therefore stops cleanly and the Aim marker hides: they do **not** survive. What goes wrong is worse: **a Skill being aimed by drag is activated** on the way out, toward the top-left of the screen at full Range, or auto-aimed if the thumb hadn't left the deadzone. It fires the moment the game resumes. A fix that only listens for focus loss, as Sol shapes it, misses the likely order of events, because the engine delivers the queued lift *before* it tells nodes about focus loss.
- **The same "lost release" gap exists for keys, mouse and controller holds.** Neither report caught it. `SkillBar` lets go of held slots on pause only. On focus loss the engine clears its input state without sending release events, so `Controls` never emits `slot_released`. A held Attack probably keeps repeating after you switch apps and come back (needs a run).
- **S4 is overstated.** The HUD's references are relative exports that the scene which owns both sides injects. That is how Godot's docs say siblings get their dependencies, and it is not a child reaching its parent. The real coupling is a small, typed, public surface. Sol's intent-signal refactor would not remove what the HUD has to read. Keep direct typed calls, and add one rule with the level split: no HUD element points into a level. One real divergence sits underneath: touch decides whether a Skill is ready itself, so **a thumb held on the Attack's slot during its Cooldown never repeats it, while a held key or button does.**
- **The level split costs the same now as later, and it changes no script and no test.** If `game.tscn` keeps the path `PixelatedView/SubViewport/World/Player`, every HUD node path keeps its value. Doing it now is about settling where the next systems' nodes go (a host for things in flight, Enemy spawning, the player's death) before they are written. That is a decision for the developer (brief 1).
- **Fable's three "leave until needed" rows hold.** After a split, the camera belongs to the game scene.

---

## S5: Skill slot touches and focus loss (Sol)

### Verify

What Sol gets right: `TouchStick` lets go of its finger on `NOTIFICATION_PAUSED` and `NOTIFICATION_APPLICATION_FOCUS_OUT` (`ui/touch_stick.gd:63-67`). `SkillSlotButton` has no `_notification` at all, and its `_finger` is only ever cleared by a lift whose index matches (`ui/skill_slot_button.gd:106-109`). No HUD code cancels `_held_slot` or `_aiming_slot` (`ui/skill_bar_hud.gd:33-37`) except a lift.

What Sol gets wrong is the symptom. Here is what happens on iOS with Godot 4.7:

1. UIKit cancels the touches in progress. Godot turns each cancelled touch into `touch_press(index, -1, -1, pressed=false)`: an ordinary release at (-1, -1), with `canceled` **not** set. Android sets `canceled`; iOS doesn't.
2. The event is buffered (`use_accumulated_input`). On focus loss, `SceneTree` first calls `Input.release_pressed_events()`, which **flushes the buffered events into the game**, and only then propagates `NOTIFICATION_APPLICATION_FOCUS_OUT` to every node. If UIKit cancels the touch after resigning active, the release is flushed on the first frame back instead. Either way, it arrives.
3. `SkillSlotButton._input` sees a release with its own index, clears `_finger` and emits `touch_ended((-1, -1))` (`skill_slot_button.gd:106-109`). After the viewport's stretch transform the point is still slightly negative.
4. `SkillBarHud._on_touch_ended` handles it as a real lift (`skill_bar_hud.gd:126-141`):
   - **Held slot (the Attack):** `_held_slot` is cleared, `set_held(slot, false)` and `hide_aim()` run. It stops cleanly; nothing survives.
   - **Aiming slot (Fireball):** `_aiming_slot` is cleared and the marker hides. The game isn't paused, so:
     - if the thumb never left the 8-unit deadzone, `press(slot)` queues an **auto-aimed activation** (`:138-139`);
     - if it had dragged, `_over_cancel` is false because (-1, -1) isn't on the slot (`:160-161`), so `press(slot, aim_from_drag(skill, (-1,-1) - landed, …))` queues an activation **aimed toward the screen's top-left, at full Range**. A spot Skill also reaches full Range, since the drag is far longer than 177 units (`player.gd:131-134`).
   - The queued press is worked through on the next physics frame (`skill_bar.gd:78-94`). On iOS the main loop stops after focus loss (`stopRendering`), so that frame is the first one after the player returns.

**What the player sees on returning:** the Fireball they were aiming flies off toward the upper left (or at the nearest Enemy), its slot shows a full Cooldown sweep, and the player faces that way for 0.35 s. A held Attack has stopped, the Touch stick is released, and the Aim marker is gone. If the pause menu was open, `_on_touch_ended` returns early (`:136`) and nothing fires.

**When Sol's "survives" would be true:** only if the platform never delivers a release at all. iOS does deliver one, per Apple's `touchesCancelled` contract and the engine source; needs a run to confirm for each kind of interruption. In that case the button would keep `_finger`. The index is reused by the next finger (iOS hands out the lowest free index), so the Skill slot button would steal the next finger's drags, possibly the Touch stick's, until that finger lifted, and the lift would activate the aimed Skill there. `SkillBar._held` would also survive (see M1) and the Attack would keep repeating.

**Sol's fix shape is partly wrong:**
- "Runs on pause": `SkillBarHud` runs with `process_mode = ALWAYS` (`ui/skill_bar_hud.tscn:7`) and its buttons inherit it. Godot sends `NOTIFICATION_PAUSED` only to nodes whose ability to process changes, so these nodes never receive it. Copying TouchStick's `_notification` would silently do nothing on pause. Pause also doesn't need it: the buttons follow a held finger through the pause on purpose (`skill_slot_button.gd:97-98`), and a lift during the pause activates nothing (`skill_bar_hud.gd:136`).
- "Tree exit": the HUD only leaves the tree with the whole scene, or for an instant during the Console's `collisions` command (`console.gd:198-201`). Not needed.
- "Focus loss" only: it misses the case where the release is flushed inside the focus-loss handling, before any node hears about it (step 2). The fix must recognise the cancelled touch itself.
- "Releases SkillBar holds": needed, but for every input route, not only touch, and it belongs in `SkillBar` (M1).

### Judge

**Do now.** It is a current defect on the target device. It is also the second copy of the lost-finger rule, and the second copy dropped it; a third touch control would copy it again (M2).

### Shape

Sketch, not compiled. About 20 lines plus tests.

```gdscript
# ui/skill_slot_button.gd
## The finger was taken away before it lifted: the app lost focus, or the system cancelled the touch.
signal touch_cancelled

func _notification(what: int) -> void:
	# Pause never reaches this node (process_mode ALWAYS), and a finger held through a pause is followed.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_cancel()

# in _input's release branch:
		elif not touch.pressed and touch.index == _finger:
			get_viewport().set_input_as_handled()
			if _was_cancelled(touch):
				_cancel()
			else:
				_finger = NO_FINGER
				touch_ended.emit(touch.position)

func _cancel() -> void:
	if _finger == NO_FINGER:
		return
	_finger = NO_FINGER
	touch_cancelled.emit()

## Whether `touch` is a cancel, not a lift. Godot 4.7 on iOS reports a touch the system takes away
## as a release at (-1, -1) with `canceled` left false.
# ponytail: drop the position check once iOS sets `canceled` as Android does.
static func _was_cancelled(touch: InputEventScreenTouch) -> bool:
	return touch.canceled or touch.position.x < 0.0 or touch.position.y < 0.0
```

```gdscript
# ui/skill_bar_hud.gd, in _ready: button.touch_cancelled.connect(_on_touch_cancelled.bind(slot))
## The thumb on `slot` was taken away: its hold and its aim end, and nothing is activated.
func _on_touch_cancelled(slot: int) -> void:
	if slot == _held_slot:
		_held_slot = SkillBar.NONE
		player.skill_bar.set_held(slot, false)
		player.hide_aim()
	if slot == _aiming_slot:
		_aiming_slot = SkillBar.NONE
		player.hide_aim()
```

```gdscript
# skills/skill_bar.gd:72-75, one line wider (M1)
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_held.clear()
```

A real lift is never at a negative coordinate: iOS gives touch points inside the view. Checking only the negative side also avoids a false cancel at the right or bottom edge.

**Tests.** Each one can fail, because a normal lift in the same setup would activate the Skill.
- `tests/test_skill_slot_button.gd`
  - "A touch the system cancels is not a lift": push a press at the button's centre, then a release at (-1, -1), both with `get_viewport().push_input(event, true)`. Expect `touch_cancelled` and no `touch_ended` (`watch_signals`).
  - "Losing focus lets go of the finger": press, then `button.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)`, then a release with the same index at a real point. Expect `touch_cancelled` once and no `touch_ended`.
- `tests/test_skill_bar_hud.gd`, in the existing fixture:
  - "A cancelled aim activates nothing": `touch_started`, then `touch_moved` 120 units left (aimed), then `touch_cancelled.emit()`, then `_elapse(0.016)`. Expect `aims == []` and `AimMarker` hidden.
  - "A cancelled hold lets go": the main slot's `touch_started`, `_elapse(0.016)`, `touch_cancelled.emit()`, `_elapse(0.4)`. Expect one activation, not two.
- `tests/test_skill_bar.gd`: `test_losing_focus_lets_go`, the twin of `test_pausing_lets_go` (`:159-165`).

**Docs.**
- A small spec, `.scratch/touch-interruptions/spec.md`, that extends the rule in `.scratch/aiming/spec.md:64` ("A pause lets go of every slot") and `.scratch/touch-controls/spec.md:23` (the Touch stick's "Lost finger").
- One rule in `docs/agents/godot-conventions.md` › Input and UI (M2).

**Device check (needs a run).** Run with the editor's Remote Debug so prints show up. Temporarily print every `InputEventScreenTouch` and `NOTIFICATION_APPLICATION_FOCUS_OUT` in `SkillSlotButton`. Then, while dragging Fireball and while holding the Attack: pull down Control Center, pull down Notification Center, press the side button, swipe to the app switcher. First reproduce the stray Fireball on `master`, then confirm the fix in both orders of events.

**Edges to settle in that spec:**
1. Does an interruption open the pause menu? See brief 3.
2. A thumb held through a pause is dropped by the Touch stick (`touch-controls/spec.md:54`) but followed by the Skill slot buttons. After unpausing, the HUD still holds the slot while `SkillBar` has let go, so a held Attack resumes at the thumb's first movement. Keep both rules, or make them one? Low stakes; I'd keep them.
3. Optional: should a pause or focus loss also drop presses queued but not yet worked through (`SkillBar._pressed`)? It's one line. Only a same-frame key race reaches it once the fix is in.

---

## S4: the HUD reaches sideways into the Player (Sol). Fable: "don't move touch aiming into Controls"

### Map: every call the UI makes into the Player side, and every signal it listens to

| From | Call or connection | Into | Where |
|---|---|---|---|
| SkillBarHud | `player` export, a node path set in `sandbox.tscn` | Player | `skill_bar_hud.gd:15`, `sandbox.tscn:154-155` |
| SkillBarHud | `skill_bar.skill_in(slot)` | SkillBar | `skill_bar_hud.gd:52, 97, 122, 135, 152` |
| SkillBarHud | `skill_bar.press(slot[, aim])` | SkillBar | `:105, 139, 141` |
| SkillBarHud | `skill_bar.set_held(slot, held[, aim])` | SkillBar | `:108, 129, 149, 154` |
| SkillBarHud | connects `skill_bar.changed` | SkillBar | `:54` |
| SkillBarHud | connects `skill_activated` (presses the button in) | Player | `:55`; emitted at `player.gd:118` |
| SkillBarHud | `aim_from_drag(skill, drag, full_drag)` | Player → `Controls.ground_axes()`, `Skill.number(RANGE, modifiers)` | `:123, 141, 153` → `player.gd:122-124` |
| SkillBarHud | `show_aim(skill, aim, cancelling)` / `hide_aim()` | Player → AimMarker | `:123, 155` / `:130, 134, 150` → `player.gd:138-143`, `aim_marker.gd:25-41` |
| SkillBarHud | reads `is_ready()`, `aim`, `repeats_while_held` | Skill | `:98, 100, 106` |
| SkillSlotButton | connects `ready_again`; reads `icon`, `cooldown_fraction()` | Skill | `skill_slot_button.gd:62-68, 118` |
| PauseMenu | `player` and `hud` exports, node paths | Player, SkillBarHud | `pause_menu.gd:17-18`, `sandbox.tscn:150-152` |
| PauseMenu | `skill_bar.skill_in`, `skill_bar.set_skill` | SkillBar | `:124, 144` |
| PauseMenu | `player.skills` (fills the Skill drawer) | Player | `:126` |
| PauseMenu | reads `title`, `icon` | Skill | `:127, 136` |
| PauseMenu | `hud.slot_chosen`; `hud.set_editing / ring / focus_slot / modulate` | SkillBarHud | `:40, 100-105, 119, 146, 151, 153` |
| PauseMenu | `Console.is_open()`, `get_tree().paused` | Console, SceneTree | `:48-60` |
| TouchStick | `Input.action_press/release(move_*)` | Input, read by Controls | `touch_stick.gd:89-101` |
| Player → UI | nothing | none | none |

Signals the UI listens to from the game side: `SkillBar.changed`, `Player.skill_activated`, `Skill.ready_again`, `Settings.changed` (`pixelated_view.gd:23`), and `Viewport.size_changed`.

### Verify

- The calls exist as Sol quotes them, and the paths are where both reports say (`sandbox.tscn:150-155`).
- **Overstated:** "departs from the repository's parent-call-down/child-signal-up rule". The rule forbids a child reaching its *parent* by `get_parent()` or an absolute path (`godot-conventions.md` › Call down, signal up). These are relative exported references set by the scene that owns both the HUD and the Player. That is the injection Godot's scene-organization guidance describes, and the one `.scratch/skill-tags/research-skill-systems.md` cites for "a node reference".
- **Overstated:** "couples UI to Player's Skill storage and aiming implementation". The HUD touches the Skill bar and three documented aiming methods, not storage. Only PauseMenu reads `player.skills`.
- **Fable is right** that touch aiming belongs in the HUD. Sol's S4 agrees in its last bullet ("Keep aiming presentation local"). The reports disagree only on whether activation and editing should go out as intent signals.

### The real divergence underneath: touch decides readiness itself

`_on_touch_started` returns early if the Skill isn't ready (`skill_bar_hud.gd:98`). A thumb that lands on the Attack's slot during its 0.4 s Cooldown is therefore dead until it lifts and lands again. The `Controls` route registers the hold whatever the Cooldown (`player.gd:83-85` → `skill_bar.gd:65-69`), and `SkillBar.advance()` repeats it the moment the Cooldown ends (`:91-94`). The aiming spec says holding repeats "on every input" (`.scratch/aiming/spec.md:64`), so touch contradicts it today.

This is the contract worth fixing: **an input route forwards presses and holds, and `SkillBar` decides whether they count.** That also takes the HUD off Fable's list of four places that ask "can this Skill be activated?" (Fable F7). Its one remaining question is presentation: "show an Aim marker for this aimed Skill?"

### Judge: which interface survives what, in the least code

- **A second level:** today's interface survives unchanged, *if the player's Character lives in the game scene and not in the level*. Rule to add: **no HUD element points into a level.** Something a HUD element shows from a level, such as a boss's Health, reaches it from the game scene when the level loads, never by node path.
- **A replaceable player's Character** (character select, re-instancing on death): each HUD element would need a setter that reconnects. The cheapest answer is to avoid replacing it: respawn resets the same Character. If it must be replaced, one script on the `HUD` CanvasLayer with a `player` export hands it down to each element (brief 2, option B, ~10 lines).
- **A second kind of HUD element:** a typed `player` reference, from an export now or from the HUD root later. Intent signals (Sol) don't remove the reads. The Skill bar HUD still needs each slot's Skill (icon, Cooldown, ready flash, aim kind, whether it repeats while held), the drag-to-ground conversion (camera axes and the Skill's Range with the player's Modifiers) and the Aim marker. All of that would have to be pushed back in through a root script. That is roughly 30-40 lines of wiring that is only checked when it runs, and it makes a third route into `SkillBar`.

**Verdict:** keep option A now. Write the no-HUD-into-a-level rule with the split. Fix the readiness divergence now (tiny). Move to B at its trigger. Don't do Sol's intent refactor. See brief 2.

---

## The game scene and the level (both reports)

### Verify

`scenes/sandbox.tscn` is the main scene (`project.godot:14`). It holds all of the following:
- the pixelated view (`:28-38`) and the World (`:40`);
- light and environment (`:42-46`);
- the level: navmesh region, GridMap and 17 props (`:48-116`);
- the player's Character with the camera as a child of the instance, not of `player.tscn` (`:118-123`);
- seven Enemies (`:125-144`);
- the HUD with three node paths (`:146-155`).

Both reports describe it correctly.

**Corrections:**
- Fable: "a second level today means … re-pointing three node paths". The paths are relative inside one file, so they never need re-pointing, whether the file is copied or split, as long as the player's Character keeps the path `PixelatedView/SubViewport/World/Player`. The real cost of copying is a second HUD, camera and player's Character per level, and the player's Character being re-created with each level (Fable is right about that part).
- Fable: "it gets more expensive with each HUD element wired by node path". It doesn't. HUD elements move as one subtree and keep their paths. What raises the cost later is code written against "one scene holds everything": a level node pointing at the player's Character, or a host for things in flight placed on the wrong side.

### What has to move

| Piece | Goes to | Notes |
|---|---|---|
| `Sandbox` root, PixelatedView, SubViewport, World | `scenes/game.tscn` (new main scene) | same structure, same settings |
| Player instance + Camera child | `game.tscn` World | path unchanged: `PixelatedView/SubViewport/World/Player` |
| HUD (TouchStick, PauseMenu, SkillBarHud) | `game.tscn` | stays after PixelatedView, so touch routing is unchanged |
| Sun, WorldEnvironment + its Environment sub-resource | level | light belongs to the place |
| NavigationRegion3D, Dungeon GridMap, 17 props | level | the navmesh reference `sandbox_navmesh.tres` moves with it |
| 7 zombies | level | Aggro finds the player's Character by physics layer, not by path (`aggro.gd:4-5`) |

Keep the level in `scenes/sandbox.tscn`, re-rooted at a `Node3D`, and make `game.tscn` the new file. Then the level keeps its uid, its navmesh reference and its history.

**What re-points, and what assumes `sandbox.tscn`:**
- Node paths and exports: none change (`PauseMenu.player`, `PauseMenu.hud`, `SkillBarHud.player` keep their values).
- `project.godot:14`: `run/main_scene` → `game.tscn`. Edit with the editor closed; the editor reorders `project.godot` when it saves.
- `tools/simulate.gd:7`, `tools/screenshot.gd:6`: the usage line only. Both take a scene path and look up `Player` and `CharacterBody3D` with `owned = false` (`simulate.gd:37-39`), so they work with the level instanced inside the game scene.
- `tools/bake_navmesh.gd:5`: unchanged. It bakes every `NavigationRegion3D` in the scene it is given, and the level keeps the `sandbox.tscn` path.
- `tools/deploy_ios.sh`: unchanged. It exports the preset, which takes the main scene and `all_resources` (`export_presets.cfg:11-13`).
- `console.gd:198-205` (`collisions` re-adds `current_scene` and finds GridMaps with `owned = false`): works with the game scene.
- Tests: none load `sandbox.tscn`, so none move.
- Specs that name `sandbox.tscn` are historical records; leave them.

### What the player's Character surviving a level change needs

1. It must not be inside the level. The split does this.
2. At the second level: a `PlayerStart` marker in each level, and about 10 lines in a game-scene script. Free the old level, instance the next, move the player's Character to the marker (the same three lines as `_cmd_tp`, `player.gd:198-199`), and add a `level <path>` console command registered in `_enter_tree`. `simulate.gd` and `screenshot.gd` can then pick a level with no change to the tools.
3. Things in flight. Today a ball is a child of its Skill under the Character, so it would fly on into the next level. Whatever host the hit pipeline picks has to sit on one side of this boundary (seam H3).
4. Nothing else. The camera is the Character's child, the HUD is bound to the same Character, and Enemies, Aggro and their command are freed with the level.

### The two scene trees

```
TODAY: scenes/sandbox.tscn (main scene)
Sandbox (Node)
├─ PixelatedView (SubViewportContainer)
│  └─ SubViewport
│     └─ World (Node3D)
│        ├─ Sun, WorldEnvironment
│        ├─ NavigationRegion3D ─ Dungeon (GridMap), Props (17)
│        ├─ Player ─ Camera
│        └─ PackZombie ×5, CorridorZombie, DetourZombie
└─ HUD (CanvasLayer)
   ├─ TouchStick
   ├─ PauseMenu      player → ../../PixelatedView/SubViewport/World/Player, hud → ../SkillBarHud
   └─ SkillBarHud    player → ../../PixelatedView/SubViewport/World/Player
```

```
PROPOSED: scenes/game.tscn (main scene)        scenes/sandbox.tscn (the first level)
Game (Node)                                    Sandbox (Node3D)
├─ PixelatedView                               ├─ Sun, WorldEnvironment
│  └─ SubViewport                              ├─ NavigationRegion3D ─ Dungeon, Props
│     └─ World (Node3D)                        └─ PackZombie ×5, CorridorZombie, DetourZombie
│        ├─ Sandbox (instance of the level)       (PlayerStart marker: at the second level)
│        ├─ Player ─ Camera
│        └─ (Effects (proposed): only if the hit pipeline picks a game-owned host)
└─ HUD (CanvasLayer): TouchStick, PauseMenu, SkillBarHud    (same paths as today)
```

### Judge: cheaper now than later?

Honestly, **about the same**. Now it is:
- one new scene and one re-rooted scene,
- one project setting,
- two comment lines,
- two lines in the conventions,
- one smoke test (M4),
- no script or test changes.

Later it is the same, plus whatever was added in between that assumed one scene.

By the reports' yardstick it can wait: there is one level, and Skills, Modifiers and Enemy kinds don't touch it. Two things argue for now:
1. It settles where the next systems' nodes go before they are written. Those are the hit pipeline's host for things in flight (needed by the first Enemy Skill), Enemy spawning ("waits for session and level structure", `.scratch/enemies/spec.md:47`) and the player's death and respawn (`.scratch/factions-health/spec.md:41`, right after the Enemy Skill).
2. It makes a level the unit of content from the first content step.

Since the developer wants the foundation before content, my recommendation is brief 1, option A. Option B is a fine choice if the developer would rather keep strictly to YAGNI.

**Sol's `Effects`:** the split doesn't need it. The hit pipeline might. If the hit pipeline uses Fable's `add_sibling` (the ball goes beside the Character that fired it), the split needs nothing: an Enemy's balls live in the level and go with it, while the player's balls live in World and must be freed on a level change. If the hit pipeline wants one named host, put it in the game scene's World so no level can forget it, and free its children on a level change. Either way it lands in one file once, which is a reason to split before that work.

---

## Fable's "leave until needed" rows in this area

| Row | Verified | Verdict | Trigger, and the shape then |
|---|---|---|---|
| The pause menu and the Console agree on pausing through `Console.is_open()` (`pause_menu.gd:49, 57`; the Console restores the pause it found, `console.gd:105-117`) | yes; tested (`test_pause_menu.gd:117-133`) | leave | A third thing that pauses (an inventory, a reward screen, a death screen). Then one owner of `get_tree().paused` that holds a set of reasons. Static state on a small class is the least code and lets the Console join without a lookup. Brief 3, option B, doesn't count: it calls `PauseMenu.open()`. |
| Settings hold only booleans and forget on quit (`settings.gd:6, 59-68`) | yes | leave | A settings screen, or the first player-facing setting: the Touch stick's follow mode is earmarked (`touch-controls/spec.md:56, 64`). Callers only use `get_value` and `changed`, so a new type is one branch in `_parse` and saving is about 10 lines in `GameSettings`. No caller changes. |
| The camera is a bare child of the player's Character and shakes through its offsets (`sandbox.tscn:120-123`, `hit_feedback.gd:42-46, 56-58`) | yes; it is a child of the *instance* in the main scene, so `player.tscn` and its tests carry no camera | leave | A second camera behaviour (look-ahead, zoom), a second source of shake, or a player's Character that gets replaced. Then a camera rig *(proposed)* in the game scene that follows the player's Character and owns the shake. |

**Sol S6, who owns the camera after a split:** the game scene. It is never in a level, and never in `player.tscn`. Hit feedback keeps reaching it through `viewport.get_camera_3d()` (`hit_feedback.gd:42`), which still works after the split. When the hit pipeline moves Hit feedback's runtime into a scene-owned piece, the shake should go through the camera (or the rig), not straight to `h_offset` and `v_offset`.

**Sol S7 (`tools/load_all.gd`):** scenes add one thing. `load_all` instantiates each scene but never adds it to the tree (`load_all.gd:16-21`). Godot resolves exported node references at instantiate with `get_node_or_null` and silently stores null when the path is broken. So neither a broken HUD → Player path nor any `_ready` is checked: `tools/check.sh` never runs the main scene. The split re-points exactly those things. A smoke test closes the gap: `tests/test_game.gd` loads `application/run/main_scene`, adds it to the tree, waits one physics frame, and checks that the Skill bar HUD's `player` is the scene's player Character. It goes into package 4 and complements whatever the rules-engine analyst does to `load_all`.

---

## Missed by both reports (held to the same yardstick)

- **M1. Holds from keys, mouse and controller can survive focus loss.** `SkillBar` lets go only on `NOTIFICATION_PAUSED` (`skill_bar.gd:72-75`). On focus loss the engine runs `Input.release_pressed_events()`, which clears key and action state through `action_release` and **sends no input events**. `Controls._unhandled_input` (`controls.gd:39-45`) therefore never sees the release and never emits `slot_released`. Prediction (needs a run on the Mac): `bar 3 attack`, hold Q, switch app with Cmd-Tab, let go, switch back, and the Attack keeps repeating. Fix: the one line in `SkillBar` from S5. It is the shared place, so it covers every route.
- **M2. The lost-finger rule is copied by each touch control, and the second copy dropped it.** `TouchStick` and `SkillSlotButton` each follow a finger by index (`NO_FINGER`, `_finger`). Only the first handles a lost finger. Two traps wait for the third copy (a dodge button, a potion button):
  - a node with `process_mode = ALWAYS` never receives `NOTIFICATION_PAUSED`;
  - iOS reports a cancelled touch as a lift at (-1, -1).

  Now: one rule in `godot-conventions.md` › Input and UI: "A touch control that follows a finger lets go of it on `NOTIFICATION_APPLICATION_FOCUS_OUT`, and treats a lift that is `canceled` or off the screen as a cancel, never as a release (iOS reports a touch the system takes away as a release at (-1, -1)). A node that runs while paused never gets `NOTIFICATION_PAUSED`." At the third touch control: lift finger-following into one shared piece.
- **M3. Touch decides readiness itself** (S4 above): a thumb held through the Attack's Cooldown never repeats it. Each input route should forward to `SkillBar` and let it decide.
- **M4. Nothing checks the main scene's wiring** (S7 above): node-path exports silently become null, and no check runs the main scene's `_ready`.
- **M5. An interruption doesn't pause the game.** On iOS the game freezes while the app is inactive and resumes mid-fight on return. Up to 8 physics steps catch up in the first frame. Pausing on focus loss is the usual phone convention, and it is the developer's rule to set (brief 3). It does **not** replace S5's fix: a cancelled touch flushed before the pause still queues its activation, and a queued press survives a pause (`SkillBar._pressed` isn't cleared).

---

## Decision briefs

### Brief 1: Should the game get its own scene now, with the sandbox as its first level?

**Today.** `scenes/sandbox.tscn` is the main scene. It holds the pixelated view, the 3D world, the level (floor, walls, props, navmesh, light), the player's Character with the camera, seven Enemies, and the HUD. A second level would either copy all of it or split it first. A level isn't a glossary term yet. Proposed entry:

> **Level** *(proposed)*: One place the player plays through: its ground, walls, props, light and Enemies. The player's Character, the camera and the HUD carry over from one Level to the next.
> _Avoid_: Map, stage, zone, scene

**A. Split now, nothing more.**
- What it is: `scenes/game.tscn` becomes the main scene (pixelated view; World with the player's Character and camera; HUD). `scenes/sandbox.tscn` keeps only the level and is instanced under World.
- Second level: build a scene with floor, walls, props, navmesh, light and Enemies; point `game.tscn`'s instance at it to play it, until level changing is built.
- Fifth HUD element: goes into `game.tscn`; never touches a level.
- Touches: two scenes, one project setting, two tool comment lines, the conventions, one new smoke test. No scripts, no existing tests.

**B. Wait for the first of: a second level, a session with a start and an end, the player's death and respawn, or Enemy spawning** (what both reports say).
- Second level: first make A's edits (same size as today), plus whatever was added in between that assumed one scene, such as a host for things in flight placed in `sandbox.tscn`, or a spawner or death screen wired inside it.
- Fifth HUD element: goes into `sandbox.tscn` and moves with the HUD later.
- Touches: the same as A, later.

**C. Split now and build level changing.**
- What it is: A, plus a `PlayerStart` marker and a game-scene script that frees the level, instances the next and moves the player's Character to its marker, with a `level` console command and a test. About 25 lines.
- Second level: pure content.
- Fifth HUD element: as in A.
- Touches: A plus a script and a test, written before anything uses them.

**Recommendation: A.** The cost is small and fixed, and it is the same later; no script or test changes. It decides where the next systems' nodes go before those systems are written: things in flight for the first Enemy Skill, then spawning and the player's death. It makes a level the unit of content from the start. C builds code with no user yet. A is easy to reverse.

### Brief 2: How should the HUD reach the player's Character?

**Today.** The Skill bar HUD and the pause menu each have a `player` export, set by node path in the main scene. They call the Skill bar (`skill_in`, `press`, `set_held`, `set_skill`, `changed`), `skill_activated`, aiming (`aim_from_drag`, `show_aim`, `hide_aim`) and `skills`. Nothing calls the HUD back.

**A. Keep typed references and direct calls (today).**
- Second level: no change, if the player's Character lives in the game scene.
- Fifth HUD element, say a potion button: one `player` export plus one node path in `game.tscn`.
- A boss Health bar: it may not point into the level; the game scene hands it the boss when the level loads.
- Touches: nothing now. If the player's Character ever gets replaced, a setter is needed in every HUD element that holds it.

**B. The HUD's root hands the player's Character down.**
- What it is: a script on the `HUD` CanvasLayer with one `player` export; its setter gives the Character to each element (call down).
- Fifth HUD element: takes it from the HUD root, with no node path.
- Replacing the player's Character: one assignment.
- Touches: about 10 lines, plus small edits to the two current elements.

**C. Intents up, wired by the game scene** (Sol).
- What it is: HUD elements emit "press slot", "hold slot", "show aim", and a game-scene script connects them to the player's Character. That script must also push in each slot's Skill, its aim kind, and a way to turn a drag into an aim on the ground.
- Fifth HUD element: more wiring code for each.
- Touches: about 30-40 lines of connections that are only checked when they run, and a third route into the Skill bar beside `Controls` and the HUD.

**Recommendation: A now, B at its trigger** (a player's Character replaced while the game runs, or the third HUD element that needs it). Not C: it doesn't remove what the HUD must read, and it trades typed calls for wiring checked only at run time. Whatever the choice, add to the conventions now: **no HUD element points into a level**. Prefer resetting the player's Character on respawn over re-creating it, which keeps A valid longer.

### Brief 3: Does an interruption pause the game?

The question: on iOS, a call, Control Center, the lock button or the app switcher; on desktop, switching apps.

**A. No (today).**
- Pulling Control Center down mid-fight and dismissing it: the game resumes at once, with Enemies mid-chase and up to 8 physics steps of catch-up in the first frame.
- Touches: nothing.

**B. Open the pause menu on focus loss while playing.**
- The same moment: the player comes back to the pause menu with their thumbs off the screen and resumes when ready.
- Every later HUD element gets this for free.
- Touches: `pause_menu.gd`, three lines in `_notification`, which the menu receives even though it runs while paused, plus one test in `test_pause_menu.gd`.
- Variant: on phones only (`OS.has_feature("mobile")`), so switching to the editor while playtesting on the Mac doesn't pause.

**C. Pause with no menu, and resume on its own on return.**
- The same moment: like A, but no catch-up jump.
- Touches: a pause owner that "resume on return" can't confuse with the pause menu. That is the third pauser from Fable's row, built early.

**Recommendation: B, mobile-only if the developer finds it annoying on the Mac.** It is the convention players expect on a phone and the cheapest option. It does not replace the S5 fix (M5).

---

## Work packages, in order

### 1. Lost finger on the Skill slots (S5, M1, M2). Do now.

- **Files:**
  - `ui/skill_slot_button.gd` (`touch_cancelled`, focus loss, a cancelled lift)
  - `ui/skill_bar_hud.gd` (`_on_touch_cancelled`)
  - `skills/skill_bar.gd`, one line in `_notification` (that file is the Skill-contract analyst's area: coordinate)
  - `docs/agents/godot-conventions.md` (the M2 rule)
  - new `.scratch/touch-interruptions/spec.md`, which extends `aiming/spec.md:64` and `touch-controls/spec.md:23`
- **Tests:** +2 `test_skill_slot_button.gd`, +2 `test_skill_bar_hud.gd`, +1 `test_skill_bar.gd`. No existing test moves.
- **Depends on:** nothing. Brief 3, option B can ride along: `pause_menu.gd` plus one test.
- **Scene edits:** none.
- **Implementer:** Sonnet. The design is settled above.
- **Done when:** the new tests and `tools/check.sh` pass. On the iPhone, with Control Center or the side button pressed mid-drag and mid-hold, no Skill fires and the Attack doesn't repeat on return. On the Mac, the Cmd-Tab hold test stops the Attack.

### 2. Touch holds follow the Skill bar (M3). Do now; tiny. Same branch as 1, or right after it.

- **Files:** `ui/skill_bar_hud.gd:95-108`. The readiness check moves into the aimed branch only, as a presentation question; a press or hold is always forwarded and `SkillBar` ignores a press on a Skill still cooling down. Plus one line in `aiming/spec.md` › Decisions.
- **Tests:** +1 `test_skill_bar_hud.gd`: a thumb held on the Attack's slot during its Cooldown repeats it once the Cooldown ends. Control step: a tap during the Cooldown activates nothing.
- **Depends on:** package 1 (same files). Confirm the rule with the developer, who already felt touch on the device.
- **Seam:** when the Skill-contract analyst adds `can_activate()` (Fable F7), the HUD's one remaining question uses it.
- **Scene edits:** none.
- **Implementer:** Haiku, given the exact change.
- **Done when:** the test passes and holding the Attack through its Cooldown feels the same on touch as on a controller.

### 3. The game scene and the first level (if brief 1 is A).

- **Files:**
  - new `scenes/game.tscn`
  - `scenes/sandbox.tscn`, re-rooted at a `Node3D` with the level content only
  - `project.godot:14`
  - `tools/simulate.gd:7`, `tools/screenshot.gd:6` (the usage line)
  - `docs/agents/godot-conventions.md` › Levels and navigation (three lines: a level is its own scene; the player's Character, the camera and the HUD are the game scene's; nothing in a level and no HUD element points across the boundary)
  - `GLOSSARY.md` (Level, if accepted)
  - new `tests/test_game.gd` (the M4 smoke test)
- **Tests:** none move; one is added.
- **Depends on:** brief 1. Best landed **before** the hit pipeline places a host for things in flight. Independent of the Character work: no script overlap, and `player.tscn` isn't touched.
- **Scene edits:**
  - The re-root and the new scene are the developer's hands in the editor: Save As `game.tscn`; there, delete the level nodes and instance `sandbox.tscn` under World; in `sandbox.tscn`, make World the root and delete the pixelated view, the player's Character and the HUD. About 10 minutes.
  - Alternative: an agent writes both `.tscn` files as text with the editor *closed*. It is a mechanical move of node blocks that drops the `PixelatedView/SubViewport/World/` prefix from `parent=`. The developer then opens and saves both once and commits that resave on its own. The HUD nodes at `sandbox.tscn:146-155` have no `unique_id` yet, so the first editor save will add them.
  - `project.godot` only with the editor closed.
  - Tool comments, docs and the test are safe as text.
- **Implementer:** the developer for the editor steps; Sonnet for the rest and for checking the diff (no node lost, the three exports unchanged).
- **Done when:**
  - The main scene is `game.tscn` and `sandbox.tscn` holds only level nodes.
  - `tests/test_game.gd` passes.
  - Needs a run: `simulate.gd -- res://scenes/game.tscn 6 "tp 16 7.5"` prints the same positions as on `master`; `bake_navmesh.gd -- res://scenes/sandbox.tscn` (with a window) reports the same walkable area; the iPhone build plays.

### At their triggers, not now

| Work | Trigger |
|---|---|
| Level changing: `PlayerStart` marker, ~10 lines in a game-scene script, a `level` command, clearing things in flight | the second level |
| HUD root hands the player's Character down (brief 2, B) | a replaceable player's Character, or the third HUD element that needs it |
| One owner of the pause | a third thing that pauses |
| Camera rig *(proposed)* | a second camera behaviour or source of shake, or a replaceable player's Character; together with the hit pipeline's Hit feedback move |
| Settings types and saving | a settings screen, or the first player-facing setting |
| Shared finger-following for touch controls | a third touch control |

---

## Seams with the other analysts, and what I assume about their work

**Character and Enemy structure**
- **C1.** The HUD and pause menu use this public surface on the player's Character: `skill_bar`, `skill_activated`, `aim_from_drag`, `show_aim`, `hide_aim`, `skills`. I assume it stays on `Player` (or `Character`) with the same meaning.
- **C2.** If Skills move under a `Skills` child, these change: `pause_menu.gd:126` (`player.skills`), `test_skill_bar_hud.gd:24` and `test_pause_menu.gd:60` (`player.get_node("Fireball")`), and `test_skill_bar_hud.gd:36`.
- **C3.** If the console commands move off the Player (Fable F8), `tp`, `bar` and `activate` must keep their names. `simulate.gd`, `screenshot.gd` and `godot-conventions.md` › Tests and checks rely on them, as does the HUD's own `touch`, which stays in the HUD.
- **C4.** If respawn re-creates the player's Character instead of resetting it, brief 2 moves to option B.

**Hit pipeline and the Skill contract**
- **H1.** Aim's shape (R2). `skill_bar_hud.gd:100, 123, 141, 153`, `aim_marker.gd:25-41` and `player.gd:122-143` pass an Aim through. The HUD only carries an Aim from `aim_from_drag` to `press`, `set_held` and `show_aim`. If Aim becomes a value type, the types change but the structure doesn't.
- **H2.** `can_activate()` (Fable F7): after package 2, the HUD asks only for presentation.
- **H3.** The host for things in flight must sit on one side of the game/level boundary (see "Sol's `Effects`"). My preference: the game scene's World, freed on a level change. `add_sibling` also works but leaves the player's balls in World across a level change.
- **H4.** Hit feedback reaches the camera through `viewport.get_camera_3d()`. The camera is the game scene's; route the shake through it when the runtime moves.
- **H5.** `skills/skill_bar.gd` gets one line from package 1. The S2 work on process order may touch the same file.

**Rules engine and content checks**
- **R1.** `load_all` can't check node-path exports or `_ready` (S7 above). `tests/test_game.gd` covers the main scene. My area adds nothing else to `load_all`: `scenes/*.tres` are loaded through the level scene.

---

## Needs a run

1. iPhone (Remote Debug for prints): reproduce the stray Fireball on `master`, then the order of the cancelled touch and focus loss for Control Center, Notification Center, the side button and the app switcher. Then confirm package 1.
2. Mac: hold Q with the Attack in slot 3 (`bar 3 attack`), Cmd-Tab away, let go, switch back. Does the Attack keep repeating? (M1)
3. After package 3: `simulate.gd` and `bake_navmesh.gd` outputs match `master`, `screenshot.gd -- res://scenes/game.tscn` looks the same, and the iPhone build plays.

## Engine claims checked

Godot 4.7-stable source:
- `drivers/apple_embedded/godot_view_apple_embedded.mm:387-394`: `touchesCancelled` → `touches_canceled(tid)`. Lines 315-333: touch indices are reused, lowest free first.
- `drivers/apple_embedded/display_server_apple_embedded.mm:272-281, 304-306`: a cancelled touch becomes `touch_press(idx, -1, -1, false)`; `canceled` is never set.
- `platform/android/android_input_handler.cpp:144-163`: Android sets `canceled`.
- `core/input/input.cpp:1549-1557`: input events are buffered.
- `core/input/input.cpp:1600-1645`: `release_pressed_events()` flushes buffered events first, then releases keys and actions with no events.
- `core/input/input.cpp:1428-1444`: `action_release` sends no event.
- `scene/main/scene_tree.cpp:934-947`: on focus in and out, `release_pressed_events()` runs first, then the notification is propagated to every node.
- `drivers/apple_embedded/os_apple_embedded.mm:774-790`: focus out sends the notification, then stops rendering.
- `drivers/apple_embedded/os_apple_embedded.mm:221-240`: each frame flushes buffered events before `Main::iteration`.
- `scene/main/node.cpp:727-742`: `NOTIFICATION_PAUSED` is sent only to nodes whose ability to process changes, so never to `PROCESS_MODE_ALWAYS` nodes.
- `scene/resources/packed_scene.cpp:597-640`: exported node references resolve at instantiate with `get_node_or_null`; a broken path is silently null.
- `scene/gui/subviewport_container.cpp:174-216`: positional events reach the SubViewport in the GUI phase, after every `_input`, which is why the HUD's buttons claim touches first.

Class reference 4.7:
- `Node.NOTIFICATION_PAUSED`: "received when the node is paused. See process_mode." It doesn't state the exception for nodes that always process; the source does.
- `NOTIFICATION_APPLICATION_FOCUS_OUT`: "Implemented on desktop and mobile platforms."
- `InputEventScreenTouch.canceled`: "If true, the touch event has been canceled."

Unverified, so needs a run: whether UIKit sends `touchesCancelled` before or after `applicationWillResignActive` for each kind of interruption. The fix covers both orders.
