# 01: Each Character scene gets a `Skills` node

**What to build:** The branch's first commit is `.scratch/character/` with the two `GLOSSARY.md` entries from the spec's "Docs this reopens" (Character, and Stagger as open rule 1 is answered), as the working agreement asks. Then `player.tscn` gets a `Skills` `Node3D` ahead of `SkillBar`, with the Attack and Fireball moved under it, and `SkillBar.main_skill` follows them; `zombie.tscn` gets an empty `Skills` node. The Player's `skills` reads the `Skills` node's children, and the Console's `bar` finds a Skill by its node name. Nothing changes in play. See `.scratch/character/spec.md` (rules 3, 4 and 12; "The change, file by file" › `player.gd`, `player.tscn` edits 1-3, `zombie.tscn` edit 1; "The scene edits and the open editor"; "Process order").

**Files:** `GLOSSARY.md` (`:11-13`, `:131-133`); `characters/player/player.tscn` (a block after `:64-67`; `:69`, `:71`, `:75`); `characters/enemy/zombie.tscn` (a block at the end); `characters/player/player.gd` (`:35` and `:39`, the getter's doc and `get_children()`; `:211`, `:214`); `tests/test_player.gd` (`:132`, `:252`, `:263`, three tests after `:93-97`); `tests/test_pause_menu.gd:60`; `tests/test_skill_bar_hud.gd:24`.

**Tests:** five node paths (spec, Tests › A node path only). New in `test_player.gd`: `test_its_skills_stand_where_it_stands`, `test_its_skills_come_before_its_skill_bar`, `test_bar_finds_a_skill_by_its_node_name`.

**Blocked by:** None. The branch starts from step 5's (`game-scene`). The glossary's Stagger sentence takes open rule 1's recommended answer unless the developer says otherwise.

**Status:** ready-for-agent

The scene edits are made in text, in a worktree no editor has open, and checked with the spec's scene check before the commit. After the commit the developer reloads the project before saving anything in the editor.

- [ ] The spec folder and the two glossary entries are the branch's first commit.
- [ ] `player.tscn`: `Skills` (a `Node3D`, no transform, no `unique_id`) after `FacingArrow`'s `Mesh` and before `Attack`; `Attack` and `Fireball` under it, keeping `unique_id`s 1240203622 and 877120161; `main_skill = NodePath("../Skills/Attack")`. The scene check shows only the `Skills` line and `main_skill`'s new path.
- [ ] `zombie.tscn` ends with an empty `Skills` `Node3D`; the scene check shows only that line.
- [ ] `player.skills` lists the Skills under `Skills`. `bar 2 fireball` finds the node `Fireball` whatever its title, and "Unknown Skill" lists node names.
- [ ] The five path changes and the three new tests are in; `tools/check.sh` passes.
- [ ] `screenshot.gd` with `"tp 19 4" "activate 1 1 0"` (spec, Checking by hand, item 3) shows the swing at the player.
