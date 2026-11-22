# 04: A thumb held through a Cooldown repeats like a held key

**What to build:** `../spec.md`, "Ticket 04": ticket 05 of `.scratch/touch-interruptions/`, built here because step 11 rewrites the same function. The last commit, so it reverts alone. Test 8 (two tests) and the docs the spec lists.

**Blocked by:** 03 (same file)

**Status:** ready-for-agent

**Done when:**

- [ ] Both tests pass; the first fails on the commit before.
- [ ] `tools/check.sh` passes.
- [ ] On the iPhone, the developer taps the main slot, lands again at once and keeps holding: the Attack repeats as soon as its Cooldown ends. The developer keeps it, or reverts this commit.
