# 04: A thumb held through a Cooldown repeats like a held key

**What to build:** `../spec.md`, "Ticket 04": ticket 05 of `.scratch/touch-interruptions/`, built here because step 11 rewrites the same function. The last commit, so it reverts alone. Test 8 (two tests) and the docs the spec lists.

**Blocked by:** 03 (same file)

**Status:** done

**Done when:**

- [x] Both tests pass; the first fails on the commit before.
- [x] `tools/check.sh` passes.
- [x] On the iPhone, the developer taps the main slot, lands again at once and keeps holding: the Attack repeats as soon as its Cooldown ends. The developer keeps it, or reverts this commit.

Merged with PR #32 on 2026-11-22: the developer tested what could be tested on the phone and kept it.
