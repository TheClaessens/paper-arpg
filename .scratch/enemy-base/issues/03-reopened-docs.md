# 03: The docs this step reopens

**What to build:** The doc changes in `.scratch/enemy-base/spec.md` › "Docs this reopens", word for word, but the glossary's, which ticket 01 committed with the spec: the conventions gain a section on Enemy kinds (with the way to add one) and two words in "Saved content"; the enemies spec's decision "No inherited enemy base scene" is replaced; the plan's decision 3 says how the zombie was rebuilt; the content-checks table names the base where it named the zombie.

**Files:** `docs/agents/godot-conventions.md` (a new section after "Saved content"; that section's second bullet); `.scratch/enemies/spec.md` (`:48`, `:49`, `:99`); `.scratch/future-proofing-review/plan.md` (decision 3's last sentence, row 8's "Needs"; under open rule 6 a only); `.scratch/content-checks/spec.md` (the rows under "Defaults files rely on" that name `zombie.tscn`, and the sentence after the table).

**Tests:** none.

**Blocked by:** 01 and 02 (the conventions name `tests/test_enemy_kinds.gd`). Open rules 2 and 6.

**Status:** ready-for-agent

Find each place by its text, not its line number: other steps edit these files.

- [x] `godot-conventions.md` has the "Enemy kinds" section between "Saved content" and "Static typing", as the spec words it, its five steps included; "Saved content"'s second bullet says "the scenes that instance or inherit those".
- [x] `.scratch/enemies/spec.md`: the decision reads as the spec gives it, "every Enemy kind reuses it", and "More Enemy kinds; elites, bosses and rarities."; requirement 6 and the commit list unchanged.
- [x] `plan.md` decision 3 and row 8 read as the spec gives them, or are unchanged under open rule 6 b.
- [x] The content-checks table's rows and the sentence after it read as the spec gives them.
- [x] `grep -rn "Enemy type" GLOSSARY.md docs .scratch/enemies` finds only the glossary's _Avoid_ line; `grep -rn "No inherited enemy base scene" docs .scratch/enemies` finds nothing now: the reopened decision paraphrases it.
- [x] `tools/check.sh` passes.

## Comments

The `grep -rn "Enemy type"` box was left open because the reopened decision quoted the old sentence. It now paraphrases it in the glossary's words, and the grep finds only the glossary's _Avoid_ line.
