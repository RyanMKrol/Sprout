# .harness/custom/CLAUDE.md — your project-specific harness instructions

This is the **customization overlay** for `.harness/CLAUDE.md`. Anything you add here loads automatically
(the pristine `.harness/CLAUDE.md` imports it with `@custom/CLAUDE.md`), and **harness upgrades never touch
this file** — so this is where your edits belong.

## Why this file exists — the overlay rule

The harness's own prose files (`.harness/CLAUDE.md`, `README.md`, and everything under `docs/`) are
**plugin-owned**: `implementation-harness:implementation-harness-upgrade` refreshes them from the latest plugin version. If you
edit them in place, your changes collide with every future upgrade and force a manual reconcile. Instead,
put project-specific additions in the matching file under `.harness/custom/` — this tree **mirrors** the
harness layout (`custom/CLAUDE.md`, `custom/README.md`, `custom/docs/HARNESS.md`, …). The pristine files
then stay byte-identical to the plugin and upgrade cleanly, while your customizations ride along untouched.

(Scripts and config are NOT covered by this prose overlay — customize the loop via `config/harness.env`,
and if you need a script change, flag it to upstream into the plugin rather than hand-editing in place.)

Add your project's harness-authoring conventions, house rules, and reminders below.

## Test destination in authored tasks — always `Sprout-Claude`

When authoring a task's `verify` commands or spec prose that runs `xcodebuild test` /
`build_run.sh`, always quote the **dedicated `Sprout-Claude` simulator** (ensured by
`./tools/loop_sim.sh`), never a generic model name like `iPhone 17 Pro` — generic names resolve
to a device shared with other projects' harness loops on this Mac and cause cross-loop flakes.
A spec that has the builder CREATE a new simulator-targeting script must instruct it to default
to `Sprout-Claude` via `tools/loop_sim.sh`, or it mints a new permanent leak. The build preamble
(`custom/build-preamble.md`) carries the runtime override for command text quoted in older specs;
this rule keeps new authoring from re-introducing the generic name in the first place. CI is
deliberately NOT pinned (isolated runners resolve their own simulator).
