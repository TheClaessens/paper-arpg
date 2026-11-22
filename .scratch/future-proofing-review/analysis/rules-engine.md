# Rules engine and content data: analysis

Status: needs-triage

One of four analyses of `fable-report.md` and `sol-report.md`. This one covers the rules engine and content data: `skills/snapshot.gd`, `tag_pass.gd`, `modifier.gd`, `number_change.gd`, `tag_change.gd`, `skills/modifiers/*.tres`, the numbers, tags, Cooldown, `is_ready` and `@tool` parts of `skills/skill.gd`, Health's negative-number question, `tools/load_all.gd`, `tools/check.sh`, their tests, ADR 0002 and 0003, and the skill-tags and deepen-skills specs.

Reviewed `master` at `8797660`. Nothing was run and nothing but this file was written. Engine behaviour was checked against the Godot 4.7 class reference; what the reference doesn't state is marked *unverified engine claim* or *needs a run*. Words not in `GLOSSARY.md` are marked *(proposed)*.

## Verdicts at a glance

| Finding | Checked against the code | Judgment |
|---|---|---|
| Fable 6 / Sol S7: tags and number names are free text, `.tres` not loaded, enums saved as numbers | Confirmed; "`.tres` not loaded" overstated | Do now (WP-2) |
| Fable 7: `is_ready()` asked in four places | Confirmed | At a trigger: the second reason a Skill can't be activated |
| Sol D1 / Fable R3: a tag-changing Modifier's numbers stack on their own | Confirmed; it also breaks More and flat | Decide now (Brief 1), then WP-3 |
| Sol D2 / Fable R4: a Modifier listed twice applies once | Confirmed; the tag pass doesn't need it to end | Decide now (Brief 2), then WP-3 |
| Sol D3: a negative flat change escapes the 0 bound | Confirmed; and 0 itself is unsafe for two numbers | Do now (WP-1) |
| Sol D7: Snapshot fields can be reassigned | Confirmed; no code does | Optional ride-along in WP-1 |
| Fable: a number declared three times | Confirmed | Leave; trigger: Skills as settings on shared pieces |
| Fable: no stable Skill id | Confirmed | Leave; one more trigger (§7) |
| Fable: `modifiers` is a bare array | Confirmed | Leave (Character analyst); Brief 2 says what an entry means |
| Fable: why lines on every Snapshot; Sol: `Skill.number()` builds a whole Snapshot | Confirmed; only the why lines are waste | Ceiling |
| Fable: `not in` scans | Confirmed | Ceiling; one goes with Brief 2 |
| Sol: every ready Skill still runs `_physics_process` | Confirmed | Ceiling |
| Fable: `range` hides `range()` | Not shown, probably wrong | Needs a run; don't rename |
| Fable: `@tool` on every Skill script | Confirmed, minor today | Developer's call in WP-2; recommend dropping |

## 1. Skill tags and number names are free text; `.tres` not loaded; enums saved as numbers

Fable finding 6, Sol S7.

### Verify

- **Skill tags** are StringNames typed out in scenes (`attack.tscn:18`, `fireball.tscn:10`), Modifier files (`pierce.tres:9`, `:14`; `spell_cooldown.tres:16`) and code (`tag_pass.gd:14`, `projectile.gd:48`). No constant or list exists. A filter tag no Skill has never matches (`modifier.gd:18-23`), and the why line reads like an ordinary miss, "missed, not Projectiles" (`tag_pass.gd:90`). Confirmed.
- **Number names** are constants in code (`skill.gd:18-22`, `fireball.gd:18`, `attack.gd:13`) and text in Modifier files (`spell_cooldown.tres:9`). `_stack` skips a change whose name doesn't match (`snapshot.gd:53-54`); a number the Skill lacks is ignored by design (`number_change.gd:3-4`, skill-tags requirement 3). A Modifier on `Cooldwon` loads and does nothing. Confirmed.
- **`.tres` not loaded by the check.** `load_all.gd:34` takes only `gd` and `tscn`. **Overstated for today:** both shipped Modifier files are loaded on every check run anyway, because `player.gd:22-23` preloads them (load_all compiles `player.gd`) and tests load them (`test_snapshot.gd:221`, `test_skill.gd:81`, `test_projectile.gd:115`). The gap is a `.tres` nothing references yet, which is how gear and talent Modifiers will be written. Fable's test sketch has a hole here: `if modifier == null: continue` skips a Modifier file that fails to load, unless load_all loads `.tres` too.
- **Enums saved as numbers.** `spell_cooldown.tres:10` `kind = 1`, `fireball.tscn:8` `aim = 2`. Confirmed. Small correction: no scene saves a `Faction.Id` today (the Player and the zombie rely on their scripts' defaults); the risk starts when a scene overrides one.

Two more in the same family, missed by both reports:

- **A default is saved content too.** A file holds only the values it sets; everything else is the script's default. `pierce.tres` adds a tag only because `TagChange.kind` defaults to `ADD` (its TagChange has no `kind` line, `pierce.tres:7-9`). Attack auto-aims only because `Skill.aim` defaults to `AUTO` (`attack.tscn:15-25` has no `aim` line). Fireball's Speed of 12 and Attack's Sweep of 120 exist only as script defaults (`fireball.gd:21`, `attack.gd:16`). Changing a default silently changes every file that relies on it, the same way reordering an enum does. (That the editor never writes a value equal to the default fits these files but is an *unverified engine claim*; the files already show what matters.)
- **A number's name is shared by every Skill.** `_stack` matches a change to a number by name alone (`snapshot.gd:53`), so a Modifier on `&"Speed"` changes every Skill that has a number called Speed. Fireball names its ball's speed `&"Speed"` (`fireball.gd:18`), the most generic name there is: the attack speed the glossary promises (Cooldown entry), or a dash's speed, would collide with it. No Modifier file names Speed yet, so renaming it is free now and touches every Speed Modifier file later.

### Judge

Do now. It meets the yardstick: what it protects is every Modifier file and every Skill scene, and adding it later means auditing every file written in between.

The reports agree on more than they seem to. Both keep StringNames as what scenes and files store: Fable's `SkillTag` is a class of constants, not an enum, so Sol's "do not replace the system with enums" doesn't apply to it. The real difference is whether Skill tags form a declared list. **I side with Fable on the list, and take Sol's `.tres` loading:**

- Only a list catches a typo in a tag a Modifier *adds* (`ADD Peirce`). A check that infers valid tags ("some Skill has it, or some Modifier adds it") accepts it, and the projectile, which reads `Pierce`, never sees it.
- It costs one line per new tag, in a file the developer can read as the vocabulary.
- It checks this repository's content; at run time tags stay StringNames, so mods can still bring their own (Sol's moddability point holds).
- Number names need no list: a name that no Skill's `numbers()` has is a typo (Fable's approach).

### Shape (WP-2)

1. `tools/load_all.gd:34`: add `"tres"`, and say so in its header.
2. `skills/skill_tag.gd` *(new)*: `class_name SkillTag`, no `extends` (as `faction.gd`), one constant per tag in use (Spell, Attack, Melee, Projectile, Fire, Elemental, Pierce) and `const ALL: Array[StringName]`. `TagPass.IMPLIED_TAGS` (`tag_pass.gd:13-15`) and `projectile.gd:48` use the constants. Scenes and `.tres` files keep writing text; the inspector can't use constants, and the test checks them.
3. `tests/test_content.gd` *(new)*, in GUT because load_all can't name project classes (`load_all.gd:6-7`). Walk every `.tscn` and `.tres` outside `addons/`, `assets/` and dot-folders, as `load_all._find` does.
   - **Skills.** Instantiate each scene off the tree and check every node that `is Skill`, as that scene sets it, so a Character scene that overrides a Skill's export is covered too, not only `skills/*.tscn`: Cooldown above 0; title and icon set; its own tags all in `SkillTag.ALL`; none of its own tags is an implied one (a Skill that lists Elemental itself can never lose it, since `_why_skip` refuses with "it comes from another tag", `tag_pass.gd:96-99`). Collect every `numbers()` key. Free each scene.
   - **Modifiers.** Every `.tres` that `is Modifier`: title set; filter tags in `ALL`; no null in `number_changes` or `tag_changes` (a null crashes `_stack` and the tag pass); each number change names a collected number; each tag change's `tag` in `ALL`, and `into` set exactly when it replaces, and then in `ALL`.
   - **The implied table.** Every key and implied tag in `ALL`, and no implied tag is itself a key: `with_implied` is one level deep (`tag_pass.gd:59-67`) and would drop a second level silently.
   - So the test can fail (CODING_STANDARDS), put the Modifier checks in one function that the test also runs on a hand-made bad Modifier, asserting that each problem is reported.
4. `docs/agents/godot-conventions.md`, a short "Saved content" section:
   - An exported enum that scenes or resources save is only ever added to at the end.
   - An export's default is part of every file that doesn't set it. Before changing a default, write the old value into those files.
   - A new Skill tag goes into `SkillTag` before any scene or Modifier uses it.
5. `.scratch/skill-tags/spec.md:49` (number names): add "A number's name means the same thing on every Skill that has it, because a Modifier names it without knowing the Skill." Rename `&"Speed"` to a name that says what it is. *Projectile speed* is my suggestion; the developer picks. Where the constant lives is the hit-pipeline analyst's call (Fable 4 moves it to `Projectile`); its text is this package's.
6. Developer's call, see §7: drop `@tool`. If dropped: `skill.gd:1`, `:7-8` (doc), `:40-43` (the setter becomes a plain export), `:83-85` (the editor guard), `:93-95`; `attack.gd:1`; `fireball.gd:1`; and `test_skill.gd:43-49` goes, since the content test's Cooldown check replaces it.

Reopens: nothing recorded. Adds one conventions section and one spec line.

## 2. "Can this Skill be activated?" is asked in four places

Fable finding 7.

### Verify

Confirmed: `skill_bar.gd:58` (a press joins the queue only if its Skill is ready), `skill_bar.gd:101` (checked again when the queue is worked through), `skill_bar_hud.gd:98` (a touch on a Skill on Cooldown starts no aim), `skill.gd:108` (the check that counts). Today they ask the same thing, because the Cooldown is the only limit.

### Judge

At a trigger, not now. **I disagree with Fable placing this under "fix before adding content"**: by the report's own yardstick it is four lines in three files and touches no Skill script, Enemy scene or Modifier file. Meanwhile drift is harmless: `try_activate` stays the authority, so a pre-check that says yes where a cost would say no only spends a press that does nothing. A `can_activate()` with one reason is a second name for `is_ready()`. When the second reason arrives, the question will also be *why not*: the HUD may show "no mana" differently from a Cooldown, which a `bool` doesn't answer. Settle the shape then.

Trigger: the first second reason (a cost, a dead or staggered Character, a missing Weapon). Three of the four call sites belong to the Skill-contract and UI analysts.

## 3. A tag-changing Modifier's number changes stack on their own

Sol D1 ("blocker"), Fable R3 ("rule to confirm").

### What the code does

`Snapshot.of` puts each applying Modifier's number changes in one of two lists: `tag_pool` if the Modifier has any tag change, `number_pool` otherwise (`snapshot.gd:39`). Each number is stacked fully on the first list (flat, Increased summed, each More), and that result is stacked fully again on the second (`snapshot.gd:42`). `test_snapshot.gd:186-194` pins it. Confirmed.

Both reports speak only of Increased. It also breaks **More** and **flat**: a plain Modifier's flat addition lands *after* a tag-changing Modifier's More, so More no longer comes "after every Increased percentage" (glossary, More).

Worked examples ("TC" is a Modifier that changes tags, "plain" any other):

| Case | Today: two pools | One stack per number |
|---|---|---|
| Range 10. TC "Projectiles pierce an Enemy and have 50% increased Range". Plain "+2 Range". | 10 × 1.5 = 15, then + 2 = **17** | (10 + 2) × 1.5 = **18** |
| Damage 20. TC "…pierce, 20% increased Damage". Plain "Spells deal 10% increased Damage". | 20 × 1.2 × 1.1 = **26.4** | 20 × (1 + 0.2 + 0.1) = **26** |
| Range 10. TC "…pierce, 50% more Range". Plain "+2 Range". | 10 × 1.5, then + 2 = **17** | (10 + 2) × 1.5 = **18** |
| Cooldown 4 s. Plain "Spells have 50% reduced cooldown". TC "Fire spells are now Holy and have 25% reduced cooldown". | 4 × 0.75 × 0.5 = **1.5 s** | 4 × (1 − 0.25 − 0.5) = **1 s** |

No shipped Modifier has both kinds (`pierce.tres` only adds a tag; `spell_cooldown.tres` only changes a number), so no content depends on either answer yet.

### What was intended, and why

- **Skill-tags spec rule 6** (`.scratch/skill-tags/spec.md:18`): "tag changes (with all their effects), added damage, conversion, scaling, other numbers. Inside a pool, a number takes flat additions first, then the sum of every Increased percentage…". Read literally, that is the code. It was written in the same commit as the glossary's Increased and More entries (276b227), which say the opposite; nobody noted the clash.
- **ADR 0002** gives the pools one purpose: "a Modifier's effect never depends on the order it was picked up in". Both answers keep that. Its consequence "A Modifier that should change both what a Skill is and what it deals lists both effects" (line 13) expects such Modifiers to be ordinary.
- **ADR 0003** uses "with all its effects" about *whether* a tag-changing Modifier applies: once applied it stays applied, and "its own number changes count too" (lines 6, 24). That holds under both answers.
- **The Skill Tag Rules sandbox** (https://claude.ai/artifact/CPo9u5o4VqzvxPbCE7CVQH), where these rules were worked out before the spec. Its step 2 says Modifiers that change a tag "go first, with all their effects", but its code runs only one effect early: the damage **conversion** of a Modifier that *replaces* a tag ("Fire spells are now frost spells", commented "Pool 1: a modifier that changes what the Skill is applies all its effects now"). Every other effect of a tag-changing Modifier there, added damage, scaling and cost, goes into the shared pools with every other Modifier's. The page the developer reacted to stacked a tag-changing Modifier's percentages with everyone's, as the glossary says.
- **The separate pool for numbers** came with the tag-pass ticket (cb64acb: "tag changers' number changes are a pool before the others"), together with the 17-versus-18 test. No design page shows those numbers.

Reading of the evidence, not the developer's word: "with all their effects" was there so that a tag-replacing Modifier converts its damage as it changes the tag, and so that a tag-changing Modifier keeps its effects once applied. Stacking its percentages apart came from reading the spec literally in the implementing ticket. Brief 1 asks.

### Judge

Decide now. Sol's "blocker" is too strong for the code (nothing uses it), right for content: Modifiers that change both tags and numbers will be balanced against whichever arithmetic is in force, so it must be settled before they are written. What each answer changes is in Brief 1.

## 4. A Modifier listed twice applies once

Sol D2, Fable R4.

### Verify

`Snapshot.of` keeps a `counted` list and adds a Modifier's number changes only the first time it meets that object (`snapshot.gd:33`, `:37-38`); `test_snapshot.gd:230-232` pins it. Identity is the Resource object. Loading one path twice returns the cached object (the 4.7 reference: with the default `CACHE_MODE_REUSE`, resources "are retrieved from cache if present"), and `Resource.duplicate()` makes a new object whose sub-resources stay shared. So two items whose Modifier export points at one `.tres` count it once, and two items that each keep their own copy count it twice. Sol is right: how an item was saved decides a game rule.

A side effect neither report names: the why lines are written per entry (`snapshot.gd:35-36`) while numbers count per object, so a Modifier listed twice shows two "applied" lines and counts once.

### Does the tag pass need it to end?

No. The tag pass ends because of its own `_applied` list (`tag_pass.gd:20`, `:33-34`, `:39`): each round applies at least one tag-changing Modifier that hadn't applied, none applies twice, and the list is finite, so there are at most as many rounds as tag-changing Modifiers. `counted` runs after the pass and only affects how numbers stack.

Under "each entry applies once", `TagPass` needs no change. Two entries of one object have the same filter, so they match in the same round, and their tag changes come to the same thing (adding Pierce twice gives Pierce). The pass still ends.

### Where the rule came from

Spec rule 4: "Each Modifier applies at most once per activation, so the tag pass always ends" (`spec.md:16`). Its stated reason is the tag pass ending. Until 82792ad ("Review fixes: a Modifier listed twice applies once"), number changes counted per entry; that review fix carried the tag pass's wording over to numbers. No rule about two copies of an item was ever recorded.

### Judge

Decide now (Brief 2), with the first Modifier source in sight. What "each entry applies once" touches: delete `counted` in `snapshot.gd` (3 lines) and fix the comment at `snapshot.gd:28`; flip `test_snapshot.gd:230-232` to Range 14; reword spec rule 4 and ADR 0003 line 6. Unchanged: `TagPass`, the glossary (Tag pass, "each once"), and the console, which erases a Modifier before adding it (`player.gd:259-261`) and so never adds it twice. Sol's "definition versus occurrence" needs no new concept: the entry in the Character's list is the occurrence.

## 5. Negative numbers

Sol D3.

### Verify, tracing each path

- **The Snapshot.** In `_stack` (`snapshot.gd:49-62`) a flat change adds straight to `value` (`:57`). Increased stops at −100% and each More at −100% (`:61-62`), but nothing bounds `value`. Range 10 with a flat −15 gives −5; add 50% increased and it gives −7.5, since Increased makes a negative number more negative. The doc comment ("Neither takes a number below 0") and the spec ("so a number never goes below 0", `spec.md:60`) claim a bound the code doesn't have; `test_no_modifier_takes_a_number_below_zero` (`test_snapshot.gd:55-61`) covers only percentages. Confirmed.
- **Negative Damage heals.** `enemy.gd:62` calls `Health.damage(-5)`, which sets `current + 5` (`health.gd:28`), clamped to the maximum. Confirmed. It breaks factions-health rule 4, "Damage lowers it".
- **Negative healing.** `Health.heal()` with a negative amount lowers Health and can reach 0 without `died`, which only `damage()` emits (`health.gd:25-30` against `:34-35`). From then on `is_dead()` is true and every hit is ignored: the Character stays at 0 and never dies. Confirmed. Unreachable today: the only caller is the console, which refuses negatives (`player.gd:240`).
- **Negative Speed.** The ball flies backwards and `_flown` falls, so `_flown >= Range` never comes true (`projectile.gd:28-31`); only a wall or a Hurtbox ends it. Confirmed.
- **Negative Knockback** reverses the push (`enemy.gd:66`). Confirmed.
- **Negative Range** reaches `SphereShape3D.radius` (`hurtbox.gd:50`). What the engine does with it is an *unverified engine claim*.
- Corrections to Sol's list: a negative Stagger is already floored at 0.02 (`enemy.gd:64`), and a negative Cooldown acts as 0 (`skill.gd:64-65`, `:89-90`).

Missed by both reports: **0 itself breaks two numbers, and is reachable today without any negative.** 100% reduced Speed (Increased −100) gives a ball that never moves and never ends. A Cooldown of 0 lets a held Attack (`repeats_while_held`, `attack.tscn:17`) activate every physics frame, 60 times a second, against the glossary's "the only thing that limits how often a Skill is activated". Two "50% reduced cooldown" Modifiers get there. A bound at 0 doesn't fix either.

### Where the bound belongs

In the two doors every caller goes through:

1. **The Snapshot**, where every number of every Skill is made: no number leaves `_stack` below 0. One expression, `return maxf(0.0, value) * maxf(0.0, 1.0 + increased / 100.0) * more`. Bounding the value after the flat changes equals bounding the result, because the factors are never negative. With today's two pools it also bounds the first pool's result; with one stack (Brief 1, option B) there is no difference.
2. **Health**, which every source of Damage and healing will call (Skills, and later burns, leech, regeneration, the console): `damage()` and `heal()` ignore negative amounts, `_set_current(current - maxf(amount, 0.0))` and `+ maxf(amount, 0.0)`. A clamp rather than an `assert`, because the 4.7 reference says the code inside `assert()` "is only executed in debug builds", and Health must hold its bounds in a release build.

Not in each reader (the projectile, the Enemy): that is one guard per reader, forever.

A 0 that breaks its reader is that reader's to handle: the Cooldown's floor is Brief 3; a projectile that can't move should end, in the hit-pipeline analyst's projectile.

### Judge

Do now (WP-1). No decision is needed: the skill-tags spec and factions-health rule 4 already promise both bounds.

## 6. Snapshot immutability is shallow

Sol D7.

Confirmed: `tags`, `numbers` and `why` are plain members (`snapshot.gd:9-13`). `make_read_only()` locks their contents (none holds a nested container, which the reference says it would not cover), but nothing stops `snapshot.numbers = {…}`. No code assigns them: the only `.tags =` in the repository is a Skill's own export in `test_skill.gd:66`.

Judge: one file, no content → by the yardstick it can wait. It rides along in WP-1, which opens `snapshot.gd` anyway, and makes the documented promise true. Shape: each field becomes a getter over a private backing field, with a setter that asserts "A Snapshot never changes"; `_init` writes the backing fields. A getter alone isn't enough: the 4.7 reference says setters and getters "are always called … even when accessed inside the same class", and what an assignment to a getter-only property does isn't stated (*unverified engine claim*). Readers (`snapshot.tags`, `number()`, `why`) don't change. Optional: skip it if the developer prefers fewer lines.

## 7. The smaller rows

**A number declared three times**: an export, a name constant and a `numbers()` entry (`skill.gd:18-22`, `:40-51`, `:100-101`; `fireball.gd:18`, `:21`, `:24-27`; `attack.gd:13`, `:16`, `:31-34`). Confirmed. Leave, as Fable says; trigger: Skills become settings on shared pieces (deferred in `.scratch/deepen-skills/spec.md`). Meanwhile WP-2's test catches a Modifier naming a number no Skill has, and `Snapshot.number()` asserts on a number missing from `numbers()` (`snapshot.gd:67-69`). Nothing catches a Skill reading its own export instead of its Snapshot; `skill.gd:129-130` says not to.

**No stable Skill id.** Confirmed. Nothing in the rules engine needs one, since Modifiers pick Skills by Skill tags. One trigger to add to Fable's (saving, Skills gained in play): the first Modifier that names one Skill rather than tags. The scene's file path would serve without touching any Skill scene.

**`modifiers` is a bare array** (`player.gd:50`). Confirmed. The rules engine takes the list as an argument, so where it lives is the Character analyst's. What an entry in it means is Brief 2.

**Why lines on every Snapshot** (Fable) and **`Skill.number()` builds a whole Snapshot** (Sol). Confirmed: `Snapshot.of` formats a line per Modifier every time (`snapshot.gd:35-36`), aiming builds a Snapshot per question (`skill.gd:124-125`), and there are two per activation (`_aim_for` → `_range_of` at `player.gd:111`, `:149`, `:192`, then `try_activate`) and two per touch-move event (`skill_bar_hud.gd:123`, `:153-155`). Correction to Sol: only the why lines are waste. Aiming must run the tag pass, or a Range Modifier filtered on a tag another Modifier grants would show one Range while aiming and use another when activated. Ceiling; trigger: a profile on the phone, or Characters with hundreds of Modifiers. Shape then: write the why lines only when read.

**`not in` scans** (`snapshot.gd:37`, `tag_pass.gd:34`). Confirmed, quadratic in the number of Modifiers. Ceiling. `counted` goes away with Brief 2's recommended option.

**Every ready Skill still runs `_physics_process`** (Sol; `skill.gd:83-85`, which returns early through `cool_down`). Ceiling; trigger: packs of Enemies with Skills. The Skill-contract analyst's processing-order item (Sol S2) touches the same function.

**`range` hides `range()`** (Fable). Not shown, and probably wrong: a member variable isn't callable, the reference says nothing about a member named `range` stopping `range(3)`, the project doesn't raise `shadowed_global_identifier` to an error (`project.godot:25-28`), and `skill.gd:45` compiles. *Needs a run*: a test-only `class Probe extends Skill` whose method returns `range(3).size()`, run with `-gselect`. Don't rename either way: Range is the glossary word, and "reach" is on its avoid list.

**`@tool` on every Skill script** (Fable). Confirmed (`skill.gd:1`, `:7-8`; `attack.gd:1`; `fireball.gd:1`). It costs little today: the only code that runs in the editor is `Skill._physics_process`, which is guarded (`skill.gd:84`), and Attack's `@onready` lookups (`attack.gd:18-19`), which are harmless. The risk is each future Skill script that forgets the guard: its gameplay code runs in the open editor, which then saves what it did. `@tool` exists only for the configuration warning (`skill.gd:93-95`). Once WP-2's test checks every Skill's Cooldown, I recommend dropping it. Developer's call: the in-editor warning is what is lost.

## Missed by both reports

1. **A default is saved content**, as much as an enum's order (§1).
2. **A number's name is shared by every Skill**, and `&"Speed"` will collide; rename it before the first Speed Modifier (§1).
3. **0 breaks Speed and Cooldown**, and percentages alone reach it today (§5).
4. **How a speed Modifier changes a Cooldown** (a rate, or a shorter duration) is open while content depends on it (Brief 3).
5. **The why lines count entries while numbers count objects** (§4).
6. **A Skill scene that lists an implied tag can never lose it**, and implied tags stop one level deep without a word (§1, covered by the content test).
7. **A constraint for the damage step**, so today's content stays valid: a Modifier on `Damage` must keep meaning all of a hit's Damage once Damage types exist, or every "increased Damage" Modifier file changes meaning. One line in the skill-tags spec's deferred decisions.

## Decision briefs

### Brief 1: Does a Modifier that also changes Skill tags stack its numbers with everyone else's?

**The question.** A Modifier can change a Skill's Skill tags and its numbers at once: "Projectiles pierce an Enemy and have 50% increased Range". Today its number changes are stacked on their own, before every other Modifier's: its Increased percentage isn't added to the others, and its More comes before other Modifiers' flat additions. The glossary says an Increased percentage "is added to every other increased or reduced percentage on the same number", and More comes "after every Increased percentage". Which is the rule?

**In numbers.** Fireball's Range is 10. A ring: "Projectiles pierce an Enemy and have 50% increased Range". A talent: "+2 Range". Today: 10 × 1.5 = 15, then + 2 = **17**. By the glossary: (10 + 2) × 1.5 = **18**. With "20% increased Damage" on the ring and "10% increased Damage" on a talent, Fireball's 20 Damage becomes **26.4** today (×1.2, then ×1.1) and **26** by the glossary (×1.3).

**Options.**

- **A. Keep it: a Modifier that changes tags is a pool *(proposed)* of its own.**
  For the player, two "increased" bonuses add or multiply depending on whether one of them also changes a tag, which nothing they read says; such a ring is quietly worth more. For an author, balance its percentages as if they were More.
  Touches: no code. The glossary's Increased and More gain "in the same pool", and the glossary needs a pool entry, because the player must understand it to read their numbers. ADR 0002 gains a consequence. With damage, such a Modifier's added damage, conversion and scaling run as a sequence of their own before everyone else's.
- **B. One stack per number (recommended).**
  The tag pass settles the tags and which Modifiers apply; a Modifier that changed tags still stays applied with all its effects (ADR 0003). Then every applying Modifier's number changes stack together. For the player, every "increased" adds up, as the glossary says; for an author, no special case.
  Touches: `snapshot.gd` (one list and one stack, about 4 lines fewer); one test flips from 17 to 18; skill-tags spec rule 6 drops "(with all their effects)" and says a pool holds one kind of effect, whichever Modifier it comes from; ADR 0002 gains one consequence. The glossary is unchanged. Left to the damage step: whether a Modifier that replaces a damage-type tag converts its damage as it replaces the tag, as the design sandbox did.
- **C. A Modifier changes tags or numbers, never both.**
  For the player, as B. For an author, "pierce and 50% increased Range" becomes two Modifiers, and the Range half is judged on the final tags, so it can miss: in ADR 0003's example, "Fire Skills are blessed, +2 Range" would lose its +2 once Fire is removed.
  Touches: reverses ADR 0002's consequence ("lists both effects") and changes ADR 0003's example; the content test rejects mixed Modifiers.

**Recommendation: B.** It is what the glossary promises and what a player can work out, which is ADR 0002's own aim. The Skill Tag Rules sandbox, where the rules were worked out, stacked such a Modifier's scaling with everyone's; the separate pool came from reading the spec's "(with all their effects)" literally while building it. Nothing in the tag pass needs the numbers early, since filters read only tags. No shipped Modifier mixes both kinds, so it costs nothing now, and a rebalance of every such Modifier later. If stacking apart is ever wanted, such as a Weapon's own bonuses applying to the Weapon first, it would follow where the Modifier comes from, not whether it changes a tag.

### Brief 2: Does the same Modifier, had twice, count twice?

**The question.** When the Character's list of Modifiers holds the same Modifier twice, does it apply twice? Today: once if both entries are the same saved Resource, twice if they are two copies. The skill-tags spec says "Each Modifier applies at most once per activation, so the tag pass always ends", but the tag pass ends without this rule.

**Example.** Two rings, each "+2 Range", and Fireball's Range of 10. If both rings point at one file, `ring_reach.tres`, Range is **12** today. If each ring keeps its own copy of that Modifier, Range is **14** today. Which you get depends on how the item was saved in the editor.

**Options.**

- **A. Keep it: once per saved Resource.** Touches nothing. Whoever authors gear must know that sharing a Modifier file between items stops it stacking and copying it doesn't. The why lines keep showing two "applied" lines for one application.
- **B. Each entry counts (recommended).** Each entry in the Character's list applies at most once, so two rings give Range **14** however they were saved. Tag changes come to the same thing either way: two "Projectiles pierce an Enemy" give Pierce. A system whose items must not stack (a unique item) refuses the second copy where it hands Modifiers out. Touches: `snapshot.gd` (delete 3 lines), one test flips from 12 to 14, the wording of spec rule 4 and ADR 0003 ("each Modifier the Character has"). The tag pass is unchanged.
- **C. A Modifier never stacks with itself.** Two rings give **12** however saved. It needs a stable id on every Modifier, because a file path doesn't exist for a Modifier kept inside an item's file, so every Modifier file gains one, now. More rules than A or B.

**Recommendation: B.** How many rings count is for the gear or talent system that hands out Modifiers to decide, by how many entries it adds, not for the rules engine. It is the smallest change (a deletion), and it is how numbers counted before a review fix carried the tag pass's wording over to them.

### Brief 3: How short can a Cooldown get, and how does a Modifier make a Skill faster?

**The question.** The glossary says every Skill has a Cooldown and that it is "the only thing that limits how often a Skill is activated"; the remove-use-time spec says attack speed and cast speed "arrive later as Modifiers on Cooldown". Today a reduced Cooldown is an Increased percentage on the Cooldown, and reductions add up: two "50% reduced cooldown" give a Cooldown of 0, and Brief 1's option B makes that come sooner. At 0, a held Attack activates every physics frame, 60 times a second. The skill-tags spec deferred a minimum Cooldown "with attack speed". Two things are open: the floor, and the arithmetic of a speed Modifier, which decides how every such Modifier file is written.

**Example.** Attack's Cooldown is 0.4 s. "20% increased attack speed", twice:
- Written as a reduced Cooldown (today's arithmetic), each must say about −16.7%. Together −33.3%: **0.27 s**. Six of them reach 0.
- As a rate, the speed adds up to +40%: 0.4 ÷ 1.4 = **0.29 s**. No number of them reaches 0.

**Options.**

- **A. A floor, and speed written as a reduced Cooldown.** One line where the Cooldown starts (`skill.gd:111`): never shorter than the floor, such as 0.1 s. Authors write "faster" as a reduced Cooldown; reductions add up toward the floor.
- **B. Speed as a rate on the Cooldown, and the floor (recommended).** A speed bonus's percentages add up, then divide the Cooldown, so speed alone never reaches 0; a reduced Cooldown stays for "shorter Cooldown" content and needs the floor. Built either as a fourth kind of number change, added at the end of `NumberChange.Kind` (a Modifier on Cooldown, as the remove-use-time spec says), or as a speed number every Skill has (*attack speed*, proposed glossary term). Nothing to build today; built with the first speed Modifier.
- **C. Keep deferring.** Safe only while no content can reach 0 and nobody writes speed as a reduced Cooldown.

**Recommendation: decide B now and pick the floor's value.** Build the floor now (one line and a test, in WP-1) and the rate with the first speed Modifier. The code can wait; the decision can't, because a speed Modifier written today as −16.7% Cooldown would have to be rewritten.

## Work packages

Each starts with its spec under `.scratch/<feature>/`, per the working agreement.

### WP-1: No number goes below 0 (now; needs no decision)

- **Files**: `skills/snapshot.gd` (`_stack`'s return line and its doc comment; optionally the read-only fields of §6; `ponytail:` comments naming the two ceilings, the why lines per Snapshot and the `not in` scans), `characters/health/health.gd` (`damage`, `heal` and their doc comments). If Brief 3's floor has a value: `skills/skill.gd:111`.
- **Tests**: `test_snapshot.gd` gains flat cases: Range 10 with a flat −15 gives 0, and with 50% increased on top still 0, not −7.5. `test_health.gd` gains "negative Damage doesn't heal, negative healing doesn't hurt"; without the guard Health would go from 40 to 50 and from 50 to 40. With the floor: a Cooldown reduced past it starts at the floor.
- **Docs**: none reopened; `.scratch/skill-tags/spec.md:60` becomes true as written.
- **Depends on**: nothing. Seam: the Character analyst (Health stays a component, so the guard stays in it wherever hit reaction moves).
- **Implementer**: Sonnet. Small, but the tests must be able to fail.
- **Done when**: no Modifier can make a Snapshot number negative, Damage can't raise Health and healing can't lower it, and `tools/check.sh` passes.

### WP-2: Content is checked (now; Fable's tag list, Sol's `.tres` loading)

- **Files**: `tools/load_all.gd`; `skills/skill_tag.gd` (new); `skills/tag_pass.gd` (constants); `skills/fireball/projectile.gd:48` (constant); `tests/test_content.gd` (new); `docs/agents/godot-conventions.md` (Saved content); `.scratch/skill-tags/spec.md` (the number-name rule, and the deferred line on Damage); the Speed rename, at `fireball.gd:18` or wherever the hit-pipeline analyst moves it. Optional: drop `@tool` (§7).
- **Tests**: new `test_content.gd`; if `@tool` goes, so does `test_skill.gd:43-49`.
- **Docs**: adds a conventions section; no ADR reopened.
- **Depends on**: the developer picking the Speed name and choosing on `@tool`. Seams: the hit-pipeline analyst (`projectile.gd`, where Speed lives), the Character analyst (if the list of Modifiers moves to a Character, the content test checks that list for empty slots too).
- **Implementer**: Sonnet.
- **Done when**: each of these fails `tools/check.sh`: a filter on `Projectiles`, a number change on `Cooldwon`, a tag change adding `Peirce`, a replace with no `into`, an empty effect slot, a Skill with a Cooldown of 0 in any scene, a `.tres` that nothing references and that doesn't load. In game code a Skill tag is written as text only in `skill_tag.gd`.

### WP-3: How Modifiers stack (after Briefs 1 and 2)

- **Files**, for B and B: `skills/snapshot.gd` (`of()` with one list, one stack and no `counted`, and its doc comment); `tests/test_snapshot.gd` (`:186-194` becomes 18 and is renamed; `:230-232` becomes 14 and is renamed; optionally 20% and 10% increased giving ×1.3); `.scratch/skill-tags/spec.md` rules 4 and 6, plus a deferred line on a tag-replacing Modifier's conversion; `docs/adr/0002` (one consequence: a pool holds one kind of effect, not one kind of Modifier); `docs/adr/0003` line 6 (wording). Glossary unchanged. If Brief 1 goes to A instead: no code, and the glossary's Increased and More change, plus a pool entry.
- **Depends on**: Briefs 1 and 2; WP-1, which touches the same file.
- **Implementer**: Sonnet; the wording is in §3, §4 and the briefs.
- **Done when**: those tests pass; the spec, the ADRs and the glossary say what `Snapshot.of` does; a search for "pool of their own" and "listed twice applies once" comes back clean in code, tests and docs.

### At a trigger, not now

| What | Trigger | Section |
|---|---|---|
| One `can_activate()` for the four call sites | The second reason a Skill can't be activated | §2 |
| Speed as a rate | The first speed Modifier | Brief 3 |
| Why lines written only when read | A profile on the phone, or hundreds of Modifiers | §7 |
| Sets instead of `not in` scans | The same | §7 |
| A Skill stops processing while ready | Packs of Enemies with Skills | §7 |
| A stable Skill id | Saving, Skills gained in play, or a Modifier that names one Skill | §7 |
| One declaration per number | Skills as settings on shared pieces | §7 |

## Seams with the other analysts

- **Hit pipeline and the Skill contract**: `projectile.gd:48` reads `SkillTag.PIERCE`; where Speed lives and what it is called (WP-2); a projectile that can't move must end (§5); `try_activate`, where the Cooldown floor goes (`skill.gd:111`), and however its timing or signature changes, `Snapshot.of` stays a pure function of tags, numbers and Modifiers; the `is_ready()` call sites (§2); Skill processing order (§7).
- **Character**: Health's guard (WP-1); where the list of Modifiers lives, and that each entry counts (Brief 2); a Character's own numbers (Fable R8) would reuse `_stack` and with it WP-1's bound and Brief 1's arithmetic.
- **UI**: `skill_bar_hud.gd:98` (§2); two Snapshots per touch-move event (§7).

## Needs a run

- Whether `range(3)` inside a `Skill` subclass reaches the built-in function (§7).
- What `SphereShape3D` does with a negative radius (§5); moot after WP-1.
- Whether the editor writes a property whose value equals its default (§1); the saved files already show what matters.
