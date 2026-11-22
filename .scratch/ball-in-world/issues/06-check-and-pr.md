# 06: The checks by hand, and the PR

**What to build:** Nothing new. The developer plays the branch against its base, confirms the open rules, then reviews the branch and opens its PR. No scene changes on this branch, so there is no resave. See `.scratch/ball-in-world/spec.md` ("Checking by hand"; "Open rules for the developer").

**Files:** none. Results go under `## Comments` below.

**Blocked by:** 05.

**Status:** ready-for-human

In order:

1. On the base (`hit`), in `scenes/game.tscn`: the spec's check 3, to compare with. A zombie just outside Fireball's Range ring is still hit there.
2. Take the branch where the editor opens it, then Project › Reload Current Project. Keep Save Before Running off.
3. The spec's checks 1 to 6 on the branch.
4. Open rules 1 to 4: confirm the recommended answers, or say which to change.
5. `/code-review` on the branch, then the PR against `hit` (plan.md decision 8), merged with a merge commit once the steps before it have landed.

- [ ] A thrown ball vanishes where its front meets the Range ring; a zombie whose body crosses the ring is hit, one wholly outside it isn't.
- [ ] Paused mid-flight, the ball sits under `World`, right after `Player`, and flies on when the menu closes.
- [ ] A Pierce Fireball passes one zombie and stops at the second, and passes through one it kills.
- [ ] A ball freezes with a swing's hitstop and flies on.
- [ ] The open rules are answered.
- [ ] `/code-review`'s findings are handled and the PR is open.
