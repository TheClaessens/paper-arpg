# 05: The editor's resave, the checks by hand, and the PR

**What to build:** Nothing new. The developer lets the editor write `player.tscn` and `zombie.tscn` in its own format once and commits that alone, so they stop churning; checks by hand that the game plays as on the base; then reviews the branch and opens its PR. See `.scratch/character/spec.md` ("The scene edits and the open editor"; "Checking by hand").

**Files:** `characters/player/player.tscn` and `characters/enemy/zombie.tscn` (the resave), and the first line of any file the resave now names a uid for. Results go under `## Comments` below.

**Blocked by:** 04.

**Status:** ready-for-human

In order:

1. On the base (`game-scene`), before taking the branch: the base's results for the spec's checks 2 and 3, the `simulate.gd` output saved to a file and the screenshots copied out of `user://screenshots/`.
2. Take the branch where the editor opens it, then Project › Reload Current Project. If the editor asks about files newer on disk, choose Reload, never Resave. Keep Save Before Running off.
3. Open `characters/player/player.tscn` and `characters/enemy/zombie.tscn` and save each (Scene › Save Scene). Run the spec's resave check: it prints nothing. Commit the two files alone, as "Editor resave: uids, unique_ids and its own property order", with any first line they now depend on (the spec says when).
4. The spec's checks 1 to 4 on the branch, compared with step 1's results.
5. `/code-review` on the branch, then the PR against `game-scene` (plan.md decision 8), merged with a merge commit once the steps before it have landed.

- [ ] The resave is one commit, and the resave check printed nothing.
- [ ] `simulate.gd`'s output matches the base line for line (or within 0.05, if two runs of the base differ).
- [ ] The swing screenshots match, the wedge drawn at the player.
- [ ] Played: a zombie hit slides back and walks back; five swings kill one, which sinks where it stood; a Pierce Fireball passes one zombie and stops at the second; the Skill drawer lists Attack and Fireball; `bar 2 fireball` and `damage 10` work.
- [ ] `/code-review`'s findings are handled and the PR is open.
