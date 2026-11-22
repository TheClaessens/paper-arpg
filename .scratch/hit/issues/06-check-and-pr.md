# 06: The checks by hand, and the PR

**What to build:** Nothing new. The developer plays the branch against its base, then reviews it and opens its PR. No scene changes on this branch, so there is no resave. See `.scratch/hit/spec.md` ("Checking by hand", "Open rules for the developer").

**Files:** none. Results go under `## Comments` below.

**Blocked by:** 05.

**Status:** ready-for-human

In order:

1. On the base (`enemy-base`): the spec's checks 2 and 3, to compare with, the screenshot copied out of `user://screenshots/`.
2. Take the branch where the editor opens it, then Project › Reload Current Project. Keep Save Before Running off.
3. The spec's checks 1 to 3 on the branch.
4. Confirm or change the open rules, the working answer "Hit" and `dealer` (open rule 1) among them, and the ADR. A changed answer goes back to the ticket it names before the PR.
5. `/code-review` on the branch, then the PR against `enemy-base` (plan.md decision 8), merged with a merge commit once the steps before it have landed.

- [ ] A swing at a zombie freezes the world for an instant and shakes the screen; at two, one freeze; a Fireball shakes and doesn't freeze; a Pierce Fireball passes one zombie and stops at the second; the fifth swing that kills a zombie freezes, then it sinks. All as on the base.
- [ ] The swing screenshots match, the wedge drawn at the player.
- [ ] The open rules are answered, in the PR or here.
- [ ] `/code-review`'s findings are handled and the PR is open.
