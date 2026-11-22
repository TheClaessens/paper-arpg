# 02: `Character` holds the Faction, Modifiers, Skills and Health bar

**What to build:** `characters/character.gd`, `class_name Character extends CharacterBody3D`, with the spec's doc comment, `faction` (the Enemies' by default), `modifiers`, `skills` (moved from the Player), `health`, `health_bar`, `hurtbox` (or null), a `_ready()` that shows Health on the Health bar, puts the Hurtbox on its Faction's layer and hands each Skill the Faction, and `add_skill()`. `Player` and `Enemy` extend it, lose what moved, and call `super()` first in `_ready()`. `player.tscn` sets `faction = 0` in the same commit as the new default. The hit and the slide stay in `Enemy` until ticket 03: `Enemy._ready()` keeps connecting `hit_taken` to its own `_on_hit_taken`, and `Player` and `Enemy` keep their `_standee`. Nothing changes in play. See `.scratch/character/spec.md` (rules 1-3, 5, 6; "Why a base script"; "The change, file by file" › `character.gd` without its ticket-03 parts, `player.gd`, `enemy.gd`, `player.tscn` edit 4).

**Files:** new `characters/character.gd` and its `.gd.uid`; `characters/player/player.gd` (`:2`, `:3-7`, `:35-42`, `:44-50`, `:54-57`, `:77-80`); `characters/enemy/enemy.gd` (`:2`, `:9-11`, `:25-30`, `:36-37`, `:39`); `characters/player/player.tscn` (after `:42`); `tests/test_aim_modes.gd:32`; new `tests/test_character.gd` and its `.gd.uid`.

**Tests:** `test_aim_modes.gd:32` becomes `player.add_skill(skill)`. New `test_character.gd` with `test_an_enemys_hurtbox_is_on_the_enemies_layer`, `test_the_player_and_its_skills_are_of_the_players_faction` and `test_a_skill_given_later_takes_its_characters_faction`, as the spec's Tests table says. The existing tests check the move: `test_health_bar.gd` (both bars; `:46-52` fails if `Player._ready()` forgets `super()`), `test_hurtbox.gd` and the hitting tests in `test_attack.gd`, `test_projectile.gd` and `test_enemy_death.gd` (the zombie's Hurtbox on its layer), `test_player.gd` (the player's Faction in Auto-aim and the ring).

**Blocked by:** 01; open rule 2 (recommended: the Enemies' by default; under the other answer `zombie.tscn` sets `faction = 1` instead and `player.tscn` sets nothing).

**Status:** ready-for-agent

The scene edit is made in text and checked with the spec's scene check. After the commit the developer reloads the project.

- [ ] `Character` as the spec sketches it, without `_stagger`, `_standee`, `_slide()`, `_on_hit_taken()` and the `hit_taken` connection (ticket 03).
- [ ] `player.gd` and `enemy.gd` say `extends Character`, keep only what the spec lists as staying for this ticket, and start `_ready()` with `super()`. The Player's doc no longer says it has its Skills and Modifiers.
- [ ] `player.tscn` sets `faction = 0` on its root, in the same commit as the default; the scene check shows only that line.
- [ ] `test_aim_modes.gd` uses `add_skill()`; the three new tests pass; `tools/check.sh` passes.
