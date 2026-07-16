# CLAUDE.md — working conventions for this repo

This file defines how Claude should behave when making changes in this repository.
Follow these conventions on **every** task unless the user explicitly says otherwise in
the current conversation. They are the coding-conventions rulebook; the **build harness**
that drives autonomous runs is described in [`.harness/docs/HARNESS.md`](./.harness/docs/HARNESS.md).

## Project orientation

**Sprout** is an iOS app for tracking plant care. You add the plants you own; Sprout proposes a
per-plant **watering schedule** seeded from a bundled database of ~300 common UK houseplants,
personalises it from quick **check-ins** (soil knuckle-test, leaf droop) and room environment,
and sends watering-due notifications at the user's preferred time — always explaining *why* the
schedule is what it is.

- **What it is / what you're building:** see `README.md` and `docs/designs/`. `README.md` is the
  product document — read it first to understand what the app does today.
- **What's planned:** `.harness/tracking/TASKS.json` is the implementation backlog, executed one
  atomic task at a time by a **single sequential loop** (`.harness/scripts/loop.sh`; see
  [`.harness/docs/HARNESS.md`](./.harness/docs/HARNESS.md)).
- **How it's built:** [`.harness/docs/HARNESS.md`](./.harness/docs/HARNESS.md) is the authoritative design of
  the autonomous build harness — the Ralph loop, its Definition of Done, and its gates.
- **History:** the app's v1 was built by an earlier (pre-plugin) harness; its design docs live in
  `docs/designs/` and `docs/research/`, and its accumulated trade-offs in `docs/LIMITATIONS.md`.
  New limitations go in `.harness/custom/docs/LIMITATIONS.md`.

## Golden rules

### 1. Every change happens on a branch

- Never commit directly to `main`. Always `git pull` (or `git fetch`) first, then create a
  fresh branch off the latest `main` for **each atomic task**. Branches are what keep the
  CI gate and clean rollback possible.
- Suggested branch naming: `tNNN` (e.g. `t014`) for backlog tasks — this is what the loop
  expects — or `<type>/<short-slug>` (e.g. `fix/reconnect`) for off-backlog work.
- Keep each branch scoped to one logical unit of work; don't bundle unrelated changes.

### 2. Merge it yourself — no pull requests

- This project **doesn't use pull requests**. When the work is complete and **green**,
  integrate the branch into `main` and push. Under the autonomous harness, the *loop* does
  this for you (it fast-forwards `main` on green CI); when working by hand:
  ```sh
  git checkout main && git pull          # sync
  git merge --no-ff <branch>             # integrate the task
  git push                               # publish main
  git branch -d <branch>                 # clean up (also delete remote if pushed)
  ```
- Merge only when the change passes the Definition of Done ([`.harness/docs/HARNESS.md`](./.harness/docs/HARNESS.md) §5)
  and only when the work was asked for — don't merge speculative changes.

### 3. The loop owns task status; the README is a product doc

- **Task status** — under the autonomous loop (either isolation variant), the LOOP is the sole
  writer of `.harness/tracking/TASKS.json` `"status"`: it flips a task to `"done"` itself, in a
  follow-up commit, once the build clears the structural checks and the audit gate. **Never set
  `"status"` yourself while working on a harness-driven task** — doing so trips the scope gate. If
  you're working BY HAND (no harness / no loop running), set the task's `"status"` to `"done"` in
  the same commit as the work.
- **The `README.md` is a product document** — what the project IS and how a human uses it. It is
  **maintainer-owned**: the loop NEVER edits it, and it does **not** track implementation status,
  backlog size, or task progress (those live in `TASKS.json` and the dashboard, which stay current —
  a status section in the README would only go stale). Keeping the README accurate is a deliberate,
  by-hand act by the project's maintainers when the product's user-facing behaviour or usage
  genuinely changes — it is not the harness's job, and no task is expected to update it.

### 4. One atomic task at a time

- Keep each commit scoped to a single logical unit of work.
- If a task reveals additional needed work, prefer finishing the current task and committing
  the rest separately over expanding scope mid-task.

### 4a. Commit + push as you go — uncommitted work is NOT durable here (non-negotiable)

The in-place loop **hard-resets the working tree to `origin/main` (`git reset --hard`) between every
attempt** — so any uncommitted work in the checkout while a run is in progress can be discarded. (At
*startup* it refuses to run on a dirty tree rather than touch it, but once running it resets between
attempts.) So any uncommitted work — notably a `/implementation-harness-convert-ideas` sweep that just
authored a batch of new tasks, or a hand-edit to `TASKS.json` — is **not safe** until it's committed.
**Treat "uncommitted" as "not durable."** When a discrete unit of work is done (a conversion sweep, a
backlog edit, a recovery), **commit and push it immediately**, don't leave it sitting in the tree
across a session. (The `mark-*.sh` and `consolidate-ideas.sh` tools already commit+push for you; the
risk is hand-edits and multi-step flows that don't.)

### 5. Tests never touch production state

A task's Definition-of-Done **test** run must execute against a **scratch / throwaway** resource —
a temp database, a fake or sandboxed endpoint, a tmp working dir — **never** the project's real
database, live services, or real data/output files. In this repo that means: tests use in-memory
SwiftData containers / fixture data, never a booted device's real app container; nothing in the
test suite hits the network (the weather provider is faked in tests).

### 6. Backlog tasks carry facets (difficulty auto-tuning)

Every BUILDABLE task you add to `TASKS.json` MUST carry a `"facets": { "layer": …, "workType": …,
"risk": [...] }` object, with values chosen ONLY from `facets.json`'s controlled vocabulary (use the
task's `scope` paths to pick the `layer`). The loop's policy reads facets to choose each task's
STARTING model/effort from escalation history; the cold-start prior is the `harness.env`
`MODEL`/`EFFORT` floor. **Never add per-task `model`/`effort` fields — the loop ignores them**
(facets are the only per-task difficulty signal). `needs-human` (gated) tasks are **carved out** —
they get NO facets. Author through the
add-to-backlog skill when it's available (it assigns facets + runs the poor-fit / layer-evolution
gate), but the rule holds even on a direct `TASKS.json` edit: a buildable task without facets gets
no auto-tuning, and the loop **pre-flight WARNs** about facet-less buildable tasks. This same
mandate is restated in **`.harness/CLAUDE.md`**, which loads whenever you work inside `.harness/`
(i.e. exactly when authoring `TASKS.json`), so the rule surfaces at the authoring moment. (See
[`.harness/docs/HARNESS.md`](./.harness/docs/HARNESS.md) and `.harness/docs/designs/difficulty-autotune.md`.)

## Standard workflow for a change

1. `git checkout main && git pull` — **always** sync `main` first, so the new branch is based
   on the latest work and never a stale local `main`. *(Under the harness the loop reads
   `origin/main` and works in an isolation worktree — you don't switch branches yourself.)*
2. Create a fresh branch off `main` (or, under the harness, work in the worktree/branch the
   loop already checked out for you).
3. Read `README.md` (for product context) and the relevant `TASKS.json` entry.
4. Make the change, keeping it atomic and within the task's `Scope:`.
5. If working BY HAND (no loop running), set the task's `TASKS.json` `"status"` in the same commit —
   under the harness the loop owns status, so leave it alone (golden rule 3). Do NOT treat the root
   `README.md` as something to update per change — it is maintainer-owned product documentation, not a
   status log (golden rule 3).
6. **Verify the Definition of Done** ([`.harness/docs/HARNESS.md`](./.harness/docs/HARNESS.md) §5): your
   project's format/lint/test/build all pass, integration/empirical checks where the task asks.
7. Commit on the branch and push. Don't merge by hand under the harness — the loop watches
   CI and integrates on green. Working manually, merge per golden rule 2 once green.

## Before you start a task — prerequisites & gates

- **Every attempt is fully COLD — do NOT read prior worklogs or resume partial work.** The harness
  measures whether a model can build the task *from the spec alone, in one cold pass* — that signal
  drives the difficulty calibration and the audit gate (see [`.harness/docs/designs/audit-verification.md`](./.harness/docs/designs/audit-verification.md)).
  So each attempt starts blank: build only from the task's `spec` (`## Do` / `## Done when`), `scope`,
  and `verify`. **Never** read `worklog/TNNN.md` as guidance and **never** continue a previous
  attempt's partial work — the worklog is append-only, **for humans/observability only**. If a task
  can't be done in one cold pass, it is **mis-sized and should be split, not resumed.**
- **Verify prerequisites are real.** Each `Depends on:` task must be `done` **and actually
  merged into `main`**. Don't trust a status box — confirm the functions/types/modules you
  need actually exist and build. If a prereq is half-done, stop and finish/flag it rather
  than working around it.
- **Respect the gate.** Tasks marked **🔒 needs-human** need a one-time human step — prepare
  everything around it and record `failed:blocked`, never auto-complete it. (To require review of a
  deliverable before dependents proceed, that's a paired `needs-human` review task — see HARNESS.md §9.)
- **Record outcomes in the worklog.** On finishing or failing, append a dated entry: what you
  did, checks run, and (on failure) `failed:soft` (transient/retryable) or `failed:blocked`
  (needs-human / unmet prereq — do not retry).

## Working alongside other agents

Single-flight means the loop moves `main` only when *it* does, so you rarely race. But the
machine is shared and `main` can still move under you (another agent, a manual merge). If your
fast-forward to `main` is rejected, or `git merge origin/main` reports conflicts — **resolve
them, don't abandon the task:**

1. **Resolve on your own branch** (`git fetch origin && git merge origin/main`), preserving
   **both sides' intent** — union `TASKS.json` entries (keep every task), union dependency /
   manifest lines, and *integrate* (never discard) code changes. Read the other commit's
   `TASKS.json` spec + `worklog/` to understand what it was doing.
2. **Re-run the full Definition of Done** on the merged result. A resolution that builds but
   fails a test — yours *or* theirs — is not done. For lockfile conflicts, resolve the
   manifest first, then regenerate a consistent lock.
3. **Re-validate your own task still holds** on the merged code before you push.
4. **Be discoverable.** Clear `TNNN: <summary>` commit message, and commit your
   `worklog/TNNN.md` so the next agent can read your intent.

## Tooling notes

**Stack:** Swift / **SwiftUI + SwiftData** iOS app (deployment target iOS 18.0), generated with
**XcodeGen** from `project.yml`, verified on a **local iOS Simulator** (Xcode 26.x). This mirrors
the proven setup of the sibling **Basket** and **Enough** projects.

**Definition-of-Done commands** (mirrored verbatim in `.github/workflows/ci.yml`, which is the
authoritative gate, and in `LOCAL_DOD` in `.harness/config/harness.env`):

- **Lint:** `swiftlint lint` — errors gate, warnings are advisory. See `.swiftlint.yml`
  (excludes `.harness/`, `build/`, `tools/`, and the generated `Sprout.xcodeproj`).
- **Test:** `xcodegen generate && xcodebuild test -project Sprout.xcodeproj -scheme Sprout
  -destination 'platform=iOS Simulator,name=Sprout-Claude'` (CI resolves a simulator by name
  on the runner instead).
- **Build + screenshot (empirical check):** `./build_run.sh Sprout-Claude` — regenerates the
  project, builds, installs, launches, and saves `screenshots/latest.png`.

There is **no** swift-format step. Keep code clean by convention; verify behaviour with
XCTest + the screenshot.

- **The `.xcodeproj` is generated:** add files under `Sources/` and run `xcodegen generate`;
  **never hand-edit** the `.xcodeproj`.
- **Dedicated simulator:** `tools/loop_sim.sh` idempotently creates/returns the UDID of the
  **`Sprout-Claude`** simulator — a uniquely-named device so concurrent harness loops for other
  projects on this Mac never converge on the same "iPhone 17 Pro" and fight over it. Local test
  and build_run targets use it; CI resolves whatever iPhone the runner has.
- **Your tooling must not sweep the vendored harness tree.** `.swiftlint.yml` excludes
  `.harness/` (and `tools/`); any task that reconfigures a whole-repo tool must keep that
  exclusion intact.
- Before pushing, the code should pass the full suite locally — it mirrors CI exactly.
- One-time setup: `brew install xcodegen swiftlint jq`, plus an iOS **simulator runtime matching
  the SDK** (else `xcodebuild test` fails — fix with `xcodebuild -downloadPlatform iOS`).

### Empirical verification — the demo-seed hook & screenshot lore

For UI work, **observe it for real**: run `./build_run.sh Sprout-Claude -seedDemoData YES`, then
**Read `screenshots/latest.png`** and confirm the UI matches the intent (right screen, expected
elements, no error state).

- `Sources/DemoSeed.swift` defines a **DEBUG-only** launch hook so screenshots show real content
  instead of the empty first-run screen: launch with `-seedDemoData YES` (passed through by
  `build_run.sh`), gate on `DemoSeed.isActive`, read `DemoSeed.plants`. Pick a screen with the
  `SPROUT_SCREEN=<name>` env var (default `"list"`; e.g. `detail`, `checkin`, `settings`) via
  `xcrun simctl spawn <udid> launchctl setenv SPROUT_SCREEN detail` before launching. The hook is
  wrapped in `#if DEBUG` and never ships in release builds.
- **If a screenshot comes out blank/white, the build is almost certainly stale — not the code.**
  `build_run.sh` builds incrementally, and on this Xcode/simulator a view-only change sometimes
  isn't relinked/reinstalled (the sim keeps running the old binary). Also `simctl io screenshot`
  only captures a real frame with the **Simulator app window open**, and a mid-launch capture
  shows the white launch screen. To get a trustworthy shot:
  `rm -rf build ~/Library/Developer/Xcode/DerivedData/Sprout-*`, re-run `build_run.sh` with the
  Simulator open, capture ~7 s after launch, and sanity-check with
  `strings build/Debug-iphonesimulator/Sprout.app/Sprout | grep "<expected text>"`.

- Tasks marked **🔒 needs-human** require the user (credentials, provisioning, anything
  spending real money or touching production). Do not attempt the human-gated portion
  yourself; prepare everything around it and hand off.
