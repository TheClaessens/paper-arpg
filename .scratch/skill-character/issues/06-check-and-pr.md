# 06: The checks by hand, and the PR

**What to build:** Nothing new. The developer plays the branch against its base, then reviews it and opens its PR. No scene changes on this branch, so there is no resave. See `.scratch/skill-character/spec.md` ("Checking by hand").

**Files:** none. Results go under `## Comments` below.

**Blocked by:** 05.

**Status:** ready-for-human

In order:

1. On the base (`character`): the spec's checks 2 and 3, to compare with.
2. Take the branch where the editor opens it, then Project › Reload Current Project. Keep Save Before Running off.
3. The spec's checks 1 to 3 on the branch.
4. `/code-review` on the branch, then the PR against `character` (plan.md decision 8), merged with a merge commit once the steps before it have landed.

- [ ] A held Attack swings every 0.4 s; Fireball's sweep runs 4 s and flashes when ready; paused mid-sweep for three seconds, it goes on from where it stopped.
- [ ] Swings and a Pierce Fireball hit the pack as on the base.
- [ ] `activate 1 0 0`: nothing swings, and "Attack: an Aim needs a direction on the ground." shows in the output.
- [ ] `/code-review`'s findings are handled and the PR is open.
