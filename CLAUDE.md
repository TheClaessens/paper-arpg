## Agent skills

### Issue tracker

Issues live as local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), recorded as a `Status:` line in each issue file. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `GLOSSARY.md` + `docs/adr/`. See `docs/agents/domain.md`.

## Working agreement

The prototype is built one README step at a time, and each step is **perfected before the next begins**: the developer must understand every line of shipped code. Stay inside the current step, explain the code you write, and start the next step only when the developer says so.

### Godot conventions

Composition, call-down/signal-up, editor-built scenes, static typing, autoloads, and tests: read `docs/agents/godot-conventions.md` before writing or reviewing any Godot code.
