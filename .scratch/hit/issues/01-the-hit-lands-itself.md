# 01: The hit becomes a Hit, and lands itself

**What to build:** The branch's first commit is `.scratch/hit/` with the `GLOSSARY.md` changes from the spec's "Docs this reopens" (the new Hit entry; Damage, Damage type, Hit feedback and Stagger), as the working agreement asks. Then the hit's new shape everywhere at once, in one commit, since `take_hit`, `hit_taken`, their receiver and every Skill that lands hits must change together to compile:

- New `skills/hit.gd`: `class_name Hit extends RefCounted` with the spec's class doc (ticket 01's version), three plain fields `snapshot`, `dealer`, `freezes` with their docs, `_init(hit_snapshot, hit_dealer, hit_freezes)`, and `land(pushes)`, which calls `take_hit(self, direction)` on each Hurtbox, plays the impact once if any landed (as `_land_hits()` does today, through the viewport of a Hurtbox it landed on), and returns whether any landed.
- `Hurtbox`: `signal hit_taken(hit: Hit, direction: Vector3)` and `take_hit(hit: Hit, direction: Vector3) -> bool`, same body, with the spec's docs; the class doc's two phrases.
- `Character._on_hit_taken(hit: Hit, direction: Vector3)`: `var snapshot := hit.snapshot`, then step 6's body unchanged, with the spec's comment; the class doc says "a Hit".
- `Skill._hit(snapshot, freezes := true) -> Hit` replaces `_land_hits()`, with the spec's doc; one sentence at the end of `character`'s doc.
- `Attack._activate()`: the local `hits` becomes `pushes`, and the last line is `_hit(snapshot).land(pushes)`.
- `Fireball._activate()`: `var ball_hit := _hit(snapshot, FREEZES)` before the connection, and the lambda lands it, `ball_hit.land({hurtbox: facing})`. Every other line stays. The class doc's last sentence and `FREEZES`' doc as the spec gives them.
- `Projectile`: only the class doc's last sentence.

Nothing changes in play. See `.scratch/hit/spec.md` (rules 1, 2, 5 and 7; "The change, file by file", the parts marked ticket 01; "Tests" › Moved, A call only, and the first two rows of New).

**Files:** `GLOSSARY.md` (Hit new before Hit feedback; `:71-73`, `:75-77`, `:127-129`; Stagger as step 6 leaves it); new `skills/hit.gd` and its `.gd.uid`; `characters/hurtbox/hurtbox.gd` (`:3-6`, `:8-10`, `:13-20`); `characters/character.gd` (the class doc, `_on_hit_taken()`); `skills/skill.gd` (`_land_hits()` at the end of the file, `character`'s doc); `skills/attack/attack.gd` (`:42-48`); `skills/fireball/fireball.gd` (the class doc, `:10`, `:37`); `skills/fireball/projectile.gd` (`:7-8`); new `tests/test_hit.gd` and its `.gd.uid`; `tests/test_skill.gd` (`:1-40`); `tests/test_enemy_death.gd` (`:2-3`, `:59-74`); `tests/test_character.gd` (step 6's `test_without_a_stagger_a_hit_doesnt_push`); `tests/test_attack.gd` (a test at the end); `tests/test_projectile.gd` (a test at the end). Line numbers are `8797660`'s: find each by its text.

**Tests:** `test_skill.gd`'s two landing tests move to `test_hit.gd` with `_zombie_at()`, `ZombieScene`, the time-scale `after_each` and the `_snapshot()` helper the spec gives; `test_no_hits_no_impact` is renamed `test_landing_on_nothing_plays_no_impact`. `test_skill.gd`'s `before_each` loses its `knockback` and `stagger` lines and its header becomes the spec's. Three tests change only their call (spec, Tests › A call only); then `grep -rn "take_hit\|hit_taken\|_land_hits" tests/` and change any other the same way. New, written first: `test_one_swing_lands_one_hit_dealt_by_the_player` in `test_attack.gd` and `test_a_piercing_ball_lands_its_throws_one_hit_on_both` in `test_projectile.gd`, as the spec's table says.

**Blocked by:** None. The branch starts from step 8's (`enemy-base`). Open rule 1 (its working answer, "Hit" and `dealer`, unless the developer says otherwise).

**Status:** ready-for-agent

- [ ] The spec folder and the glossary changes are the branch's first commit.
- [ ] `skills/hit.gd` as the spec sketches it for ticket 01: plain fields, `land()` playing the impact once if any landed. No other field, no signal.
- [ ] `take_hit(hit, direction)` and `hit_taken(hit, direction)` are the only forms; `Character._on_hit_taken(hit, direction)` reads `hit.snapshot`.
- [ ] `skill.gd` has `_hit()` and no `_land_hits()`; Attack lands one Hit per swing and Fireball one per throw, made in `_activate()`, never inside the lambda.
- [ ] A search for `_land_hits`, `take_hit(direction` and `hit_taken(direction` in `characters/ skills/ ui/ scenes/ tests/` comes back clean.
- [ ] The moved tests and the two new ones pass; `tools/check.sh` passes.
