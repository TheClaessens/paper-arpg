# 02: Each slot's thumb is tracked by itself

**What to build:** `../spec.md`, "Ticket 02". `SkillBarHud._held_slot` becomes `_holding`, one yes/no per slot; a second thumb on a slot that waits for the lift is ignored while another slot is being aimed. Tests 5 and 6.

**Blocked by:** 01

**Status:** done

**Done when:**

- [x] Tests 5 and 6 pass, and each fails on the commit before.
- [x] `test_a_second_finger_on_another_slot_leaves_a_hold_alone` and the touch-interruption tests pass unchanged.
- [x] `tools/check.sh` passes.
