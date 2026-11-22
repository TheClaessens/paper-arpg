# Modifier stacking

Status: ready-for-agent

The open rules below follow their recommended answers; the developer confirms them when reading this step's PR.

Step 4 of the future-proofing plan (`.scratch/future-proofing-review/plan.md`, decisions 1 and 2, decided by the developer on 2026-11-22), on its own branch `modifier-stacking`, stacked on the steps before it (plan.md, decision 8). It needs step 1, `number-bounds` (`.scratch/number-bounds/spec.md`), which changes the same file. Sources: `.scratch/future-proofing-review/analysis/rules-engine.md` §3, §4, Briefs 1 and 2, WP-3 and "Missed by both reports" item 5, checked against the code at `master` (`8797660`). Nothing changes in play.

## What changes and why

Two rules of how Modifiers stack change. Neither was a design decision: one came from reading three words of a spec literally while building it, the other from a review fix that carried the tag pass's wording over to numbers.

**1. A Modifier that changes Skill tags stops stacking its number changes on their own.** Today `Snapshot.of` puts the number changes of each Modifier that applies in `tag_pool` if the Modifier has any tag change and in `number_pool` if not (`snapshot.gd:39`), stacks each number fully on the first list, then stacks that result fully again on the second (`:42`). So a tag-changing Modifier's Increased percentage isn't added to the others', and its More comes before every other Modifier's flat additions. The glossary says the opposite: an Increased percentage "is added to every other increased or reduced percentage on the same number", and More comes "after every Increased percentage". Fireball's Range 10 with "Projectiles pierce an Enemy and have 50% increased Range" and "+2 Range" is 10 × 1.5 + 2 = 17 today, and (10 + 2) × 1.5 = 18 by the glossary.

Where it came from: skill-tags rule 6 lists the pools as "tag changes (with all their effects), added damage, …", and ticket 03 restated it as "Modifiers that change tags apply (with all their effects) before any other pool". The ticket's commit (`cb64acb`, "Tag changes and the tag pass") built that as worded. The words came from the Skill Tag Rules sandbox (https://claude.ai/artifact/CPo9u5o4VqzvxPbCE7CVQH): its step 2 says "Modifiers that add or replace a tag go first, with all their effects", but its code runs one effect early, the damage conversion of a Modifier that replaces a tag, and stacks every other effect of such a Modifier with everyone else's. Rule 6 itself names the glossary's Increased and More. Nobody noted the clash.

**2. Each entry in the Character's list of Modifiers counts.** Today `Snapshot.of` keeps a `counted` list and adds a Modifier's number changes only the first time it meets that object (`snapshot.gd:33`, `:37-38`). One saved file loaded twice is one object, and a copy is another, so two rings that point at one Modifier file with "+2 Range" give Fireball Range 12, and two rings that each keep a copy give 14: how an item was saved decides a game rule. The why lines are written per entry (`:35-36`), so a Modifier listed twice shows two "applied" lines and counts once.

Where it came from: skill-tags rule 4 says "Each Modifier applies at most once per activation, so the tag pass always ends". Its reason is the tag pass ending, and the tag pass ends by its own record of applied Modifiers (`tag_pass.gd:20`, `:33-34`, `:39`). The review fix `82792ad` ("Review fixes: a Modifier listed twice applies once, …") added `counted` so the numbers followed the same words. The sandbox's rule 4 says the same for the same reason, and its Modifiers could never be listed twice. No rule about two copies of an item was ever recorded.

After this step the tag pass still settles the tags and which Modifiers apply; then the number changes of every entry that applies stack together, one stack per number. Whatever hands out Modifiers decides what stacks, by how many entries it adds. No shipped Modifier changes both tags and numbers (`pierce.tres` only adds a tag, `spell_cooldown.tres` only changes a number), and the Console never lists a Modifier twice (`player.gd:259-261`), so nothing changes in play.

## The rules

A *tag-changing Modifier* has at least one tag change; a *plain* one has none. Fireball's own numbers: Cooldown 4 s, Range 10, Damage 20.

1. **The tag pass comes first, as today.** It settles the final tags and which Modifiers apply, and touches no number. A tag-changing Modifier that applied stays applied even if its filter misses the final tags (ADR 0003), and its number changes count. ADR 0003's example with numbers: "Fire Skills are blessed" (filter Fire, adds Holy) with 50% increased Range, "Blessed Skills lose Fire" (filter Holy, removes Fire), and a plain "+2 Range". Fireball ends Spell, Projectile, Holy; "Fire Skills are blessed" misses the final tags but stays applied; Range is (10 + 2) × 1.5 = **18** (today 17).
2. **One stack per number.** The number changes of every Modifier that applies go into one stack per number, whether or not the Modifier changes tags: flat additions summed, then the sum of every Increased percentage, then each More on its own, in any order of the list.
   - Flat first: a tag-changing "Projectiles pierce an Enemy and have 50% increased Range" and a plain "+2 Range": (10 + 2) × 1.5 = **18** (today 17).
   - Increased adds up: a tag-changing Modifier with "20% increased Damage" and a plain "Spells deal 10% increased Damage": 20 × (1 + 0.2 + 0.1) = **26** (today 20 × 1.2 × 1.1 = 26.4).
   - More comes last: a tag-changing Modifier with "50% more Range" and a plain "+2 Range": (10 + 2) × 1.5 = **18** (today 17).
   - All three: a tag-changing Modifier with 20% increased and 50% more Range, a plain "+2 Range" and a plain "10% increased Range": (10 + 2) × 1.3 × 1.5 = **23.4**, the skill-tags spec's own example with no tag change (today 10 × 1.2 × 1.5 = 18, then (18 + 2) × 1.1 = 22).
   - Reductions add up: a plain "Spells have 50% reduced cooldown" and a tag-changing "Fire spells are now Holy and have 25% reduced cooldown" (Fireball stays a Spell): 4 × (1 − 0.5 − 0.25) = **1 s** (today 4 × 0.75 × 0.5 = 1.5 s).
   - Step 1's floor applies once, to the one stack: a tag-changing Modifier with a flat −15 Range and a plain "+12 Range": 10 − 15 + 12 = **7**. On step 1's branch before this step it is 12 (number-bounds open rule 1, answer a): the tag-changing Modifier's stack stops at 0 before the +12 is added. On `master`, 7. No other example here goes below 0, so the floor changes none of them.
3. **Each entry applies at most once.** The same Modifier listed twice applies twice, whether both entries are one saved file or two copies.
   - Two rings with "+2 Range": 10 + 2 + 2 = **14** (today 12 for one file, 14 for two copies).
   - "50% increased Range" twice: 10 × (1 + 0.5 + 0.5) = **20**. "50% more Range" twice: 10 × 1.5 × 1.5 = **22.5** (today 15 each, for one file; open rule 1).
   - Both rules: "Projectiles pierce an Enemy and have 50% increased Range" twice and a plain "+2 Range": (10 + 2) × (1 + 0.5 + 0.5) = **24** (today 17).
   - "Spells have 50% reduced cooldown" twice: 4 × (1 − 0.5 − 0.5) = **0** in the Snapshot (today 2 s). Step 1's shortest Cooldown runs it for 0.1 s (number-bounds rule 4); this step adds nothing for it.
4. **A tag-changing Modifier listed twice changes the tags as one entry would.** Both entries match in the same round of the tag pass and both apply; a tag added, removed or replaced twice ends up as once; neither entry applies again, so the pass ends. Its number changes count twice. "Fire spells are now Holy" (filter Fire, replaces Fire with Holy) with "+2 Range", listed twice: Fireball is Spell, Projectile, Holy, with Range **14** (today 12). Two "Projectiles pierce an Enemy" give Pierce once: the ball passes through one Enemy, not two (a count would be a number change, skill-tags requirement 3).
5. **The why list has one line per entry**, in list order, as today, and each "applied" line is now one application whose number changes counted. A Modifier listed twice shows its line twice and counts twice. The listed-twice "Fire spells are now Holy" shows "Fire spells are now Holy: applied, replaces Fire with Holy" twice: both entries replaced Fire, because a round's changes apply together at its end (ADR 0003).

## The change, file by file

### `skills/snapshot.gd`: `of()` only

**Before** (`:29-43`): run the tag pass; walk the list, writing each entry's why line, and the first time an applying Modifier comes up, record it in `counted` and put its number changes in `tag_pool` (it changes tags) or `number_pool` (it doesn't); stack each number on `tag_pool`, then stack that result on `number_pool`.

```gdscript
	var tag_pool: Array[NumberChange] = []
	var number_pool: Array[NumberChange] = []
	var counted: Array[Modifier] = []
	...
		if modifier not in counted and tag_pass.applies(modifier):
			counted.append(modifier)
			(number_pool if modifier.tag_changes.is_empty() else tag_pool).append_array(modifier.number_changes)
	...
		result[name] = _stack(_stack(own_numbers[name], name, tag_pool), name, number_pool)
```

**After**: run the tag pass; walk the list, writing each entry's why line and adding the number changes of each entry that applies to one list; stack each number once, on that list.

```gdscript
static func of(...) -> Snapshot: # signature as now
	var tag_pass := TagPass.new(own_tags, modifiers)
	var changes: Array[NumberChange] = []
	var why: Array[String] = []
	for modifier in modifiers:
		# step 1's ponytail: comment about the why lines stays here
		why.append(tag_pass.explain(modifier))
		if tag_pass.applies(modifier):
			changes.append_array(modifier.number_changes)
	var result: Dictionary[StringName, float] = {}
	for name in own_numbers:
		result[name] = _stack(own_numbers[name], name, changes)
	return Snapshot.new(tag_pass.tags, result, why)
```

Ticket 01 makes the one list and the one `_stack` call and keeps `counted`: the `if` stays `modifier not in counted and tag_pass.applies(modifier)`, followed by `counted.append(modifier)`. Ticket 02 deletes `counted`. The code of `of()` ends three lines shorter. `_stack` doesn't change here (step 1 floors it), nor does `of()`'s signature. An entry applies when `TagPass.applies()` says so: it changed tags in the pass, or its filter matches the final tags.

The doc comment (`:25-28`) after ticket 01:

```gdscript
## The Snapshot of a Skill whose own tags are `own_tags` and own numbers `own_numbers`, with the
## Character's `modifiers`. The tag pass (see TagPass) settles the tags and which Modifiers
## apply; then the number changes of every Modifier that applies stack together, one stack per
## number, whether or not it changes tags (see docs/adr/0002). Each Modifier applies at most
## once, even if listed twice.
```

After ticket 02, its last sentence becomes: "Each entry of `modifiers` counts: the same Modifier listed twice applies twice (see docs/adr/0003)."

### `skills/tag_pass.gd`: unchanged

What its record of applied Modifiers, `_applied`, does with one Modifier listed twice, on `master`:

1. `changers` (`:29`) keeps both entries: `filter()` drops none.
2. A round's `matching` (`:33-34`) is worked out before any of its entries is recorded. Both entries are one object, with one filter and one answer to `m not in _applied`, so both match in the same round or neither does.
3. Both run (`:38-51`). Each is appended to `_applied` (`:39`), which then holds the Modifier twice. The second entry clears `_changes_made` and `_skipped` for it (`:40-41`) and records the same changes again, because both entries read the same `working`, which changes only after the loop (`:52-56`).
4. The tags come out as one entry's: an added tag joins `working` only if it is missing (`:53-54`); a removed tag is erased, and erasing it again does nothing (`:55-56`; `_removed` holds it twice, and `explain()` and `_describe()` only ask whether a tag is in it); a replace is a removal and an addition.
5. In the next round, `m not in _applied` is false for both entries. Every round applies at least one Modifier that hadn't applied, and there are finitely many, so the pass ends, as before.
6. `applies()` (`:71-72`) is true for each entry, so `of()` adds the number changes once per entry once `counted` is gone.

So a tag change does run once per entry, it makes no difference to the tags, and the pass still ends. Rule 4 already holds on `master` for the tags; only the numbers change, in `of()`. The class doc's "Each applies at most once" (`:7`) counts entries, since `changers` is made of the list's entries; it stays as written.

### The why lines

No code changes (`snapshot.gd:35-36`, `tag_pass.gd:78-90`). What changes is what a line stands for: each line is one entry, and each "applied" line now matches number changes that counted. Before, a Modifier listed twice showed two "applied" lines and counted once (analysis, "Missed by both reports" item 5). Rule 1 changes no line: a line says whether its Modifier applied and what it did to the tags, not how its numbers stacked. See rule 5 and open rule 2.

### Unchanged on purpose

- `Snapshot._stack`: step 1's floor stays; this step calls it once per number.
- `skills/tag_pass.gd`, `skills/modifier.gd`, `skills/number_change.gd`, `skills/tag_change.gd` and the two Modifier files.
- `Snapshot.why`'s doc, "One line per Modifier the Character has" (`:12`, which step 1 may move): one line per entry, as before.
- `Skill.snapshot()` and `Skill.number()` (`skill.gd:118-125`): aiming and activating still read the same Snapshot, so aiming shows the Range the activation uses.
- The Console's `modifier` command (`player.gd:246-262`): open rule 3.

## Tests

Flip or write each test first: it must fail before its ticket's change and pass after. All are in `tests/test_snapshot.gd`.

| Test | Ticket | Proves | On `master` |
|---|---|---|---|
| `test_a_tag_changers_number_changes_are_a_pool_of_their_own` (`:186-194`), renamed `test_a_tag_changers_number_changes_stack_with_everyone_elses` | 01 | Range 10, a tag-changing Modifier with 50% increased Range, a plain "+2 Range": 17, "10 × 1.5, then + 2", becomes 18, "(10 + 2) × 1.5". The body is otherwise as now. | Fails: 17 |
| new `test_numbers_stack_the_same_whichever_modifier_changes_tags`, after the one above | 01 | Range 10; a tag-changing Modifier (filter Projectile, adds Pierce) with two number changes on Range, 20% increased and 50% more, set as `:157-160` sets one; `_modifier([], Skill.RANGE, NumberChange.Kind.FLAT, 2.0)`; `_modifier([], Skill.RANGE, NumberChange.Kind.INCREASED, 10.0)`. Range is 23.4 (`assert_almost_eq`, 0.0001), "(10 + 2) × 1.3 × 1.5, as with no tag change". The only test where a tag-changing Modifier's Increased meets another Modifier's Increased, and its More meets another's flat addition. | Fails: 22 |
| `test_a_modifier_listed_twice_applies_once` (`:230-232`), renamed `test_a_modifier_listed_twice_applies_twice` | 02 | `[farther, farther]`: 12 becomes 14, "10 + 2 + 2". A second assertion: two Modifiers made by two `_modifier([], Skill.RANGE, NumberChange.Kind.FLAT, 2.0)` calls give 14, "two copies count the same". | The first fails: 12. The second passes: 14 |
| new `test_a_tag_changer_listed_twice_changes_the_tags_once_and_its_numbers_twice`, after the one above, at the end of the file | 02 | `_tagger("Fire spells are now Holy", [&"Fire"], TagChange.Kind.REPLACE, &"Fire", &"Holy")`, given a flat +2 Range as `:157-160` does, listed twice, on `SPELL`: tags `[&"Spell", &"Projectile", &"Holy"]`; Range 14, "10 + 2 + 2"; `why` is that one line twice, "Fire spells are now Holy: applied, replaces Fire with Holy". | Fails on Range: 12. The tags and the why lines already hold |

Unchanged and still passing: `test_flat_then_increased_summed_then_each_more` (`:45-52`); `test_a_tag_changer_stays_applied_when_a_later_change_removes_its_tag` (`:155-168`, 12: its tag-changing Modifier has only a flat change, which comes first either way); `test_tag_changes_come_before_number_changes` (`:171-174`); `test_a_tag_changer_applies_its_number_changes_too` (`:177-183`); `test_two_modifiers_that_switch_each_other_off_still_end` (`:197-201`); step 1's `test_a_flat_cut_stops_at_zero` (no tag change, nothing listed twice); and `test_modifier_switches_a_proof_modifier_on_and_off` (`test_player.gd:213-224`, "switching on twice adds it once"). No other test lists a Modifier twice or gives a tag-changing Modifier a number change (`test_skill.gd`, `test_projectile.gd`, `test_aim_modes.gd`, `test_player.gd` checked). The file's header (`:2-5`) stays as step 1 words it.

## Docs this reopens

**`.scratch/skill-tags/spec.md`**

- `:18`, rule 6 (ticket 01). Becomes: "6. **Modifiers apply in pools, one pool at a time**: tag changes, added damage, conversion, scaling, other numbers. A pool holds one kind of effect, whichever Modifier it comes from: a Modifier that changes tags has its tag changes in the first pool and its number changes in the later ones, with every other Modifier's (decided 2026-11-22; see `.scratch/modifier-stacking/spec.md`). Inside a pool, a number takes flat additions first, then the sum of every **Increased** percentage, then each **More** percentage on its own. Conversions from one type cap at 100% in total and are shared proportionally above that. Whether a Modifier that replaces a damage-type tag converts its damage as it replaces the tag waits for damage (see Deferred decisions)."
- After `:64`, a new deferred decision (ticket 01): "- Whether a Modifier that replaces a damage-type tag converts its damage as it replaces the tag, in the tag pass, as the Skill Tag Rules sandbox did, or in the conversion pool with every other conversion (with damage; see `.scratch/modifier-stacking/spec.md`)."
- `:16`, rule 4's last bullet (ticket 02). Becomes: "   - Each entry in the Character's list of Modifiers applies at most once per activation, so the tag pass always ends. The same Modifier listed twice applies twice, both times in the same round, and its tag changes leave the tags as one entry's would (decided 2026-11-22; see `.scratch/modifier-stacking/spec.md`)."
- Rule 4's first bullet (`:13`) keeps "stays applied, with all its effects": it says whether a Modifier applies, which this step doesn't change.
- Left as is, and still true: requirement 5 (`:31`, "tag pass, then the pools for the numbers that exist today") and `.scratch/deepen-skills/spec.md:9` ("puts the number changes in the pools in ADR 0002's order"). Every number today is in the last pool, other numbers, and one stack is that pool.

**`docs/adr/0002-skill-modifiers-resolve-in-pools.md`** gains a third consequence after `:14` (ticket 01). Its decision, fixed pools so that a Modifier's effect never depends on the order it was picked up in, stands; the consequence says what a pool holds: "- A pool holds one kind of effect, whichever Modifier it comes from. A Modifier that changes tags has its tag changes in the first pool, and its number changes stack with every other Modifier's: Fireball's Range 10 with "Projectiles pierce an Enemy and have 50% increased Range" and "+2 Range" is (10 + 2) × 1.5 = 18 (decided 2026-11-22, `.scratch/modifier-stacking/spec.md`). Whether a Modifier that replaces a damage-type tag also converts its damage as it replaces the tag is decided with damage."

**`docs/adr/0003-tag-changes-apply-in-rounds.md`** is amended in place at `:6` and gains a third consequence after `:34` (ticket 02). In place, because the bullet's rule for the tag pass is what the pass always did (both entries of one Modifier already apply, in one round) and only its words now say so; this ADR was reworded in place before, when "waves" became "rounds" (`0173765`). The consequence records today's decision with its date.

- `:6` becomes: "- Each entry in the Character's list of Modifiers applies at most once. Once it has applied, it stays applied, with all its effects, even if a later round removes a tag its filter needs."
- New consequence: "- The same Modifier listed twice, such as one Modifier file shared by two rings, applies twice: whatever hands out Modifiers decides what stacks (decided 2026-11-22, `.scratch/modifier-stacking/spec.md`). Both entries match in the same round, so its tag changes leave the tags as one entry's would, and both entries' number changes count."

**`GLOSSARY.md`**: unchanged. Checked word by word:

| Entry | Before this step | After |
|---|---|---|
| Modifier | True: it says nothing about stacking or counting. | True. Two rings that hand out the same Modifier make two changes, and each counts. |
| Tag pass | True: it says when tags change and that each Modifier applies once, not when numbers stack. | True. "Each once" counts each Modifier the Character has, as listed: two entries of one Modifier apply once each, in the same round. |
| Increased | False for a tag-changing Modifier's percentage, stacked apart, and for a Modifier listed twice, counted once. | True as written. |
| More | False for a tag-changing Modifier's More, which came before other Modifiers' flat additions. | True as written. Each entry's More changes the number on its own, so the same More twice is ×2.25 (open rule 1). |

## Open rules for the developer

Settle these before code. The tickets follow the recommended answers, and none of them needs code.

1. **The same percentage, listed twice.** Each entry counts and Increased percentages add up, so "50% increased Range" twice on Range 10 gives 10 × (1 + 0.5 + 0.5) = 20. For "50% more Range" twice:
   - a. 10 × 1.5 × 1.5 = **22.5**: each entry's More changes the number on its own, as the glossary's More says.
   - b. 10 × 2 = **20**: the two entries' More added up. `of()` would have to tell when two entries are the same Modifier, the identity rule decision 2 dropped.

   *Recommended:* **a**.
2. **The why list for a Modifier listed twice.**
   - a. One line per entry, as today: the same line twice, "Spells have 50% reduced cooldown: applied". It now agrees with the numbers.
   - b. One line per Modifier with a count, "…: applied, twice": `of()` groups entries, and the list stops matching the Character's list line for line.

   *Recommended:* **a**. The why list is for tests and the Console (skill-tags requirement 7).
3. **The Console keeps one entry per proof Modifier.** `modifier <name> on` erases the Modifier before adding it (`player.gd:259-261`), so switching it on twice still gives one entry (`test_player.gd:217`), and stacking shows only in tests.
   - a. Keep it: "on" means on, and gear is the first source that stacks.
   - b. Each `on` adds an entry and `off` removes them all: the command, its usage line and its test change.

   *Recommended:* **a**.

## Deferred

- **A tag-replacing Modifier's conversion.** Whether a Modifier that replaces a damage-type tag and converts its damage ("Fire spells are now frost spells", ADR 0002) converts as it replaces the tag, in the tag pass, as the Skill Tag Rules sandbox did, or in the conversion pool with every other conversion. It shows with added damage: a Skill dealing 50 fire, with that Modifier and "+5 fire damage to Spells". Converting in the tag pass gives 50 frost and 5 fire, because the +5 comes after; converting in the pool gives 55 frost. Nothing converts damage today. **Trigger:** the damage step, with Damage types and conversion. Recorded in the skill-tags spec's deferred decisions (ticket 01).

## Out of scope

- **Keeping a Modifier from stacking**, such as a unique item or a talent taken once: whatever hands it out keeps the second copy out of the Character's list. **Trigger:** the first source of Modifiers besides the Console (gear or talents), with "where Modifiers come from" (skill-tags deferred decisions; plan.md, at their triggers).
- **Stacking by where a Modifier comes from**, such as a Weapon's own bonuses applying to the Weapon before everyone else's. If it is ever wanted, it follows the Modifier's source, not whether it changes tags. **Trigger:** Weapons bringing Modifiers (skill-tags requirement 1).
- **Pierce as a count**, so two "pierce" Modifiers pass through two Enemies: a behaviour has no number, and a count is a number change (skill-tags requirement 3). **Trigger:** the first Modifier that adds pierces.
- **The damage pools** (added damage, conversion, scaling) in `Snapshot.of`; rule 2 holds in each. **Trigger:** the damage step.
- **Faster lookups.** `counted`'s `not in` scan goes with this step; the tag pass's `in` scans stay, marked by step 1's `ponytail:` comment. **Trigger:** a profile on the phone (plan.md).

## Seams

Lines as numbered on `master` (`8797660`). On the branch, step 1 has moved them down; find them by name.

- **`skills/snapshot.gd`**: this step changes `of()` and its doc only: `:25-28` (the doc), `:31-33` (three lists become one), `:37-39` (the `if` and what it appends), `:42` (one `_stack` call). Step 1 changes `:6`, `:8-22` (the fields and their docs become properties over private fields, and `_init`), `:46-48` and `:62` (`_stack`'s floor), and puts a `ponytail:` comment above `why.append(...)` (`:36`). Keep that comment where it is, and `_stack` as step 1 leaves it. If the developer chose step 1's open rule 1b instead (the floor once, in `of()`), keep that floor on the one stack.
- **`tests/test_snapshot.gd`**: `:186-194` and a new test after it (01); `:230-232` and a new test after it (02). Step 1 adds tests after `:61` and `:97` and rewords the header (`:4-5`); this step leaves them.
- **`skills/tag_pass.gd`**: not touched. Step 1 adds a `ponytail:` comment above `:33`; step 2, `content-checks`, changes `IMPLIED_TAGS` (`:12-15`).
- **`.scratch/skill-tags/spec.md`**: `:16`, `:18`, and a new line after `:64`. Step 1 rewrites `:34` and `:60`.
- **`docs/adr/0002-…`, `docs/adr/0003-…`**: no other step touches them. **`GLOSSARY.md`** is not touched here (step 1 rewrites Cooldown, `:112`).

## Done when

- Each flipped assertion and each new test failed before its ticket's change and passes after.
- Every other test passes unchanged.
- `skills/snapshot.gd` changes only in `of()` and its doc; `skills/tag_pass.gd` doesn't change.
- The docs above read as given, and `GLOSSARY.md` is unchanged.
- The search for the old words prints nothing. The dots stand for a space or an underscore, so the test names match too:

  ```sh
  # code and tests
  grep -rn -E "tag_pool|number_pool|counted|pool.of.their.own|listed.twice.applies.once|even if listed twice|two pools" autoloads characters skills ui scenes props rendering tests tools
  # docs: the analysis and this folder quote the old words, and closed tickets are history
  grep -rn -i -E "pool.of.their.own|listed.twice.applies.once|even if listed twice|two pools|with all their effects|each modifier applies at most once" GLOSSARY.md docs .scratch --exclude-dir=future-proofing-review --exclude-dir=modifier-stacking --exclude-dir=issues
  ```

  On `master` they print the 14 lines this step changes. Left as written on purpose: `.scratch/skill-tags/issues/03-tag-changes-and-the-tag-pass.md`, the record of what that ticket built, keeps "with all their effects" and "Each Modifier applies at most once".
- `tools/check.sh` passes after each ticket, and `/code-review` has run on the branch before its PR.
- Nothing to check in game: no shipped Modifier changes both tags and numbers, and the Console never lists a Modifier twice. The Console's `modifier` listing reads as on `master`.

## Tickets

1. `issues/01-one-stack-per-number.md`: rules 1 and 2; skill-tags rule 6 and its deferred line; ADR 0002.
2. `issues/02-each-entry-counts.md`: rules 3 to 5; skill-tags rule 4; ADR 0003; the search for the old words.
