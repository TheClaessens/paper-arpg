## Agent skills

### Issue tracker

Issues live as local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), recorded as a `Status:` line in each issue file. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `GLOSSARY.md` + `docs/adr/`. See `docs/agents/domain.md`.

## Working agreement

The prototype is built one README step at a time, and each step is **perfected before the next begins**: the developer must understand every line of shipped code. Stay inside the current step, explain the code you write, and start the next step only when the developer says so. When a design or grilling session settles what to build, write it to `.scratch/<feature>/spec.md` before writing code, and commit the spec with the `GLOSSARY.md` changes it settled on that feature's branch. UI work gets a design pass in an artifact first (a sketch, a design canvas, then a clickable prototype) so the developer reacts to it before the spec. Each step gets its own branch off `master` and lands through a PR merged with a merge commit; run `/code-review` on the branch before opening its PR.

### Where code lives

Game code is in `autoloads/ characters/ skills/ ui/ scenes/ props/ rendering/`, tests in `tests/`, scripts in `tools/`. `assets/` and `addons/` are vendored: leave them out of searches.

### Godot conventions

Composition, call-down/signal-up, editor-built scenes, static typing, autoloads, tests and `tools/check.sh`: read `docs/agents/godot-conventions.md` before writing or reviewing any Godot code.
