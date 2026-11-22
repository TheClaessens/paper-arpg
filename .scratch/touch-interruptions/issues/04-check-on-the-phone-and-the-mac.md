# 04: Check the interruptions on the iPhone and the Mac

**What to build:** Nothing; the developer plays the hand tests in `.scratch/touch-interruptions/spec.md` ("Hand tests" 1 to 6). First hand test 1 on `master`, to see the stray Fireball, then all six on the branch with tickets 01 to 03. Use the editor's Remote Debug on the phone, so a script error shows. If an interruption still activates a Skill, add the temporary prints the spec describes and note which came first, the cancelled touch or the focus loss. Write what each interruption did under `## Comments` below, and correct the spec's "Engine facts" 6, 12 and 13 if the phone or the Mac disagrees.

**Blocked by:** 01, 02 and 03.

**Status:** ready-for-human

**Files:** none; notes in this ticket, and the spec's "Engine facts" if a run disagrees.

**Tests:** hand tests only.

**Done when:**

- [ ] On the iPhone, Control Center, Notification Center, the side button and the app switcher, each in the middle of a Fireball drag, activate nothing and leave no aim marker; in the middle of a held Attack, the Attack isn't repeating on return.
- [ ] A lift during a pause or with the Console open activates nothing; a lift after Resume activates the aimed Fireball.
- [ ] Emptying a slot in the Skill drawer under an aiming thumb leaves no marker, activates nothing and raises no error.
- [ ] On the Mac, Q, the left mouse button and (if connected) a controller's A held through a Cmd-Tab no longer repeat the Attack, and a Fireball dragged with the mouse through a Cmd-Tab isn't activated.
