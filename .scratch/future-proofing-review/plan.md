# Future-proofing: plan and decisions

Status: steps 1 to 10 merged into `master` on 2026-11-22 (#22 to #31, then one resave commit); step 11 is `.scratch/aim-modes/`

## Where it stands (2026-11-22)

Each PR is stacked on the one before it and is merged in this order, with a merge commit. `tools/check.sh` is green on every branch; the count is the passing tests on that branch (201 on `master`).

| # | Feature | PR | Tests | Left for the developer |
|---|---|---|---|---|
| 1 | `number-bounds` | #22 | 206 | Word the glossary's Activate entry; a look in game |
| 2 | `content-checks` | #23 | 211 | Confirm the name Projectile speed |
| 3 | `touch-interruptions` | #24 | 221 | Hand test on the iPhone and the Mac (ticket 04); decide ticket 05, a thumb held through a Cooldown |
| 4 | `modifier-stacking` | #25 | 223 | The glossary's Tag pass wording; one policy for amending ADRs |
| 5 | `game-scene` | #26 | 224 | Screenshots, the navmesh bake, the iPhone build |
| 6 | `character` | #27 | 236 | Confirm the slide lives in `Enemy`; a look in game |
| 7 | `skill-character` | #28 | 241 | The glossary's Aim entry |
| 8 | `enemy-base` | #29 | 244 | Confirm the Stagger is each Enemy kind's own |
| 9 | `hit` | #30 | 253 | Read ADR 0004; the glossary's Hit entry |
| 10 | `ball-in-world` | #31 | 261 | A look in game at a Fireball's new reach (10.0 where it was 10.65) |

**One resave in the editor, for every scene these steps wrote as text.** Steps 5, 6 and 8 each ask for a resave on their own branch. Do it once at the top of the stack: check out `ball-in-world`, **Project › Reload Current Project**, open and save `scenes/game.tscn`, `scenes/sandbox.tscn`, `characters/player/player.tscn`, `characters/enemy/enemy.tscn` (the base first) and `characters/enemy/zombie.tscn`, and commit that resave on its own. What the editor is expected to change, and what would be a warning sign, is in `.scratch/game-scene/issues/03-*.md`, `.scratch/character/issues/05-*.md` and `.scratch/enemy-base/issues/04-*.md`.

**How play was checked.** `tools/simulate.gd` with `--fixed-fps 60` and avoidance on one thread (its header says how) prints the same output run after run. From step 5 to step 10 the player's swing prints one checksum, `fc6af6dbd110508d8e597824a4f40861`, and from step 9 the Fireball's and the Pierce Fireball's are unchanged too. The one change in play is step 10's: how far a ball reaches.

**Changed in code review, against the specs.** Step 6: the slide moved from `Character` to `Enemy`. Step 9: the question "is this Hurtbox an Enemy's" moved into `Hurtbox.is_of()`. Each PR says so.

The two reviews (`fable-report.md`, `sol-report.md`, reviewed at `8797660`) were checked against the code by four analysts. Their findings, corrections and decision briefs are in `analysis/`. This file records what the developer decided on 2026-11-22 and the order of the steps. Each step has its own spec under `.scratch/<feature>/`, its own branch and its own PR.

## Decisions (developer, 2026-11-22)

1. **A tag-changing Modifier's numbers stack with everyone else's.** One stack per number. Fireball's Range 10 with "pierce and 50% increased Range" and "+2 Range" is 18, not 17. (`analysis/rules-engine.md`, Brief 1, option B.)
2. **Each entry in a Character's list of Modifiers counts.** Two rings that give "+2 Range" give +4 however their files were saved. Whatever hands out Modifiers decides what stacks. (Brief 2, option B.)
3. **Enemy kinds inherit one `enemy.tscn`, built now.** No `character.tscn` above it. The player's scene stays its own. An agent writes `enemy.tscn` and the inherited `zombie.tscn` in text, checked against today's zombie, and the developer resaves them once in the editor (`.scratch/enemy-base/spec.md`). (`analysis/character-enemy.md`, B1, option B.)
4. **The game gets its own scene now**, with the sandbox as its first Level, and nothing more: no level changing yet. (`analysis/ui-game-root.md`, Brief 1, option A.)
5. **How a Skill is aimed is an Aim mode** (settled 2026-11-22, step 11). The developer sees the ways of aiming as logic shared between Skills and separate from them. An Aim mode is a saved file a Skill names; it says what the Aim holds, whether on touch the Skill waits for the lift, and whether holding repeats it. Steer, Line, Spot and Around exist. Auto-aim is not one: it is the Aim any Skill gets when the player gives none. (`.scratch/aim-modes/spec.md`)
6. **`_activate` means what the Skill does happens at that moment.** No begin, land and end phases. An optional wind-up before the effect can be added later without touching existing Skills; whether Enemy Skills use one is decided with the first Enemy Skill. (`analysis/hit-pipeline.md`, Brief A.)
7. **Only hits on an Enemy freeze and shake the world.** A hit on the player flashes and squashes the player's Standee, and the game keeps running. (Brief C, option B.)
8. **Steps land as stacked PRs.** Each step is specced, built on its own branch, reviewed with `/code-review` and opened as a PR; the next step is built on top without waiting. The developer reads and merges in order.

Working answers, used unless the developer objects when reading the spec that holds them:

- "Hit" becomes a glossary term; the Character that dealt it is its `dealer` in code. (`hit` spec)
- A ball's front reaches exactly its Range from the Character's centre. (`ball-in-world` spec)
- A Stagger of 0 does nothing: no hold and no slide. (`character` spec)
- The shortest Cooldown is 0.1 s. (`number-bounds` spec)
- Fireball's `Speed` is renamed so the name means one thing on every Skill. (`content-checks` spec)

## Steps, in order

| # | Feature | What | Needs |
|---|---|---|---|
| 1 | `number-bounds` | No Snapshot number below 0; Health ignores amounts of 0 or less; Snapshot fields can't be replaced; a shortest Cooldown | |
| 2 | `content-checks` | Skill tags declared once; a test over every Skill and Modifier file; `.tres` loaded by the check; "Saved content" in the conventions | |
| 3 | `touch-interruptions` | A finger taken off a Skill slot without lifting activates nothing; a held thumb repeats like a held key | |
| 4 | `modifier-stacking` | Decisions 1 and 2 | step 1 |
| 5 | `game-scene` | Decision 4 | editor closed, or the developer's hands |
| 6 | `character` | `Character` base script, `Stagger` component, a `Skills` node (a `Node3D`) | |
| 7 | `skill-character` | A Skill knows its Character; its Cooldown can't be stopped by a subclass; an Aim needs a direction | step 6 |
| 8 | `enemy-base` | Decision 3 | step 6; the developer's resave |
| 9 | `hit` | `Hit` names its dealer and lands itself; decision 7; `Hurtbox.around` past 32 | step 7 |
| 10 | `ball-in-world` | The ball carries its Hit, lives in the world, measures Range from the Character | step 9 |
| 11 | `aim-modes` | How a Skill is aimed, as shared logic (decision 5): an Aim mode, a saved file a Skill names, replaces the three aim settings on the Skill; three touch fixes ride along | built after a design round on 2026-11-22 |

## At their triggers, not now

| What | Trigger |
|---|---|
| The player's Hurtbox; the Enemy's behaviour as its own node; a wind-up; whether the player is staggered; the player at 0 Health | The first Enemy Skill |
| A shared projectile folder | The second projectile Skill |
| Swept ball movement; speed as a rate on the Cooldown | The first Speed or speed Modifier |
| `can_activate()` | A second reason a Skill can't be activated |
| A Character's own numbers; where Modifiers come from | Gear |
| Changing Levels; the HUD root handing the Character down | The second Level |
| Size classes, one navmesh each | The first Enemy kind of another size |
| A Hurtbox that can be found but not hit | The first immunity |
| Hit feedback's runtime in a scene-owned piece | Slow motion, or a second camera effect |
| Standee updates, repathing, idle Skills, why lines | A profile on the phone |
| Opening the pause menu when the app loses focus | The developer asks for it |
| A script or a marker scene per Aim mode | The first way of aiming whose drag or drawing isn't one of today's |
| An Aim that carries a picked Hurtbox | The first Skill that picks one |
| What a held thumb does on a Skill that waits for the lift and repeats | The first Aim mode with both |
| Whether the navigation agent's avoidance callback nudges a zombie during its Stagger | The Enemy's behaviour as its own node |
| A Skill that lists the same Skill tag twice keeps one copy when a Modifier removes or replaces that tag | The first Modifier that removes or replaces a tag |
| A Range cut to 0 breaks the Attack's query | The first Modifier that can cut a Range to 0 |
