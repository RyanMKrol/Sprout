# TASKS — implementation backlog

This is the execution backlog for **Sprout**. Each task is atomic, ordered by dependency, and
bounded by explicit acceptance criteria so it is achievable by a single build pass of the
pinned model. It is executed by a **single sequential loop** — the next eligible task, one at
a time — described in [`docs/HARNESS.md`](./docs/HARNESS.md).

See [`CLAUDE.md`](./CLAUDE.md) for the repo conventions (branch + self-merge, no PRs; docs in
lockstep) and [`docs/HARNESS.md`](./docs/HARNESS.md) for the autonomous build harness.

## How the loop works

The build harness is a **single sequential loop** — one `claude -p` per task, fresh context,
all durable state in the repo (this file's statuses, `worklog/`, git). The authoritative
design is [`docs/HARNESS.md`](./docs/HARNESS.md); this section is just how to *read this
file*. Each iteration the loop:

1. **Picks the next eligible task** — the first not-done task (per the Status index) whose
   `Depends on:` are all `done` **and merged into `main`**.
2. **Resumes, never restarts.** If a `tNNN` branch or uncommitted work exists from an
   interrupted attempt, it continues that — reads `worklog/TNNN.md`, inspects the working
   tree, and reconciles the delta against the task's `Done-when:` before coding.
3. **Implements only the outstanding delta**, within the task's `Scope:`, and verifies
   prerequisites are real (deps present in code, not just a ticked box).
4. **Passes the LOCAL Definition of Done** ([`docs/HARNESS.md`](./docs/HARNESS.md) §5): the
   project's format/lint/test plus the empirical simulator-screenshot check where the task's
   `Verify:` asks for it — flipping the index box and the `README.md` row in the **same
   commit**. (This project is local-only: `REQUIRE_CI=0`, no GitHub Actions.)
5. **Branches off `main`, pushes; the loop fast-forwards `main`** once the local DoD passes,
   and records the result. On failure it appends a `worklog/TNNN.md` entry (what failed, why,
   what's left) and stops.

Rules:
- **One task per iteration.** Do not batch.
- **Finish completely.** Never mark `done` with a failing `Done-when:` or partial scope.
- Tasks tagged **🔒 needs-human** need a one-time manual step (credentials, provisioning);
  author + validate as far as possible, then record `failed:blocked` — do **not** mark done.
  Tasks tagged **🚦 Gate** additionally need an explicit human review of the deliverable.

### Work log & retries

Loops must never spin forever burning tokens. The mechanics:

- **Status vocabulary:** `pending` → `done`, or `failed` (carries an **attempt count** and a
  **reason**). `failed` is written by the loop at runtime; the index/specs below start
  everything `pending`.
- **Per-task work log `worklog/TNNN.md`** (append-only): every attempt appends a dated entry —
  what it tried, what passed/failed, the reason/blocker, and what's left. **Read it before
  every (re)attempt.**
- **Failure taxonomy:**
  - `failed:soft` — transient (token/quota exhaustion, flaky network, partial progress
    checkpointed) → eligible for retry.
  - `failed:blocked` — hard blocker (🔒 needs-human, unmet/abandoned prerequisite, missing
    gate decision) → **not** retried; surface to the human.
- **Caps:** `MAX_ATTEMPTS` per task (default 3) of `failed:soft` → then `failed:blocked`. A
  global iteration/wall-clock cap bounds total spend (and naturally handles running out of
  tokens — `claude -p` simply can't run). Waiting on deps consumes no attempt.

---

## Execution order & gates

There are no tracks, waves, or parallel worktrees — the loop walks the backlog in
**dependency order**, one task at a time ([`docs/HARNESS.md`](./docs/HARNESS.md)). A task
becomes eligible once its `Depends on:` are merged into `main`.

**Gates (the loop must not skip them).** A task marked **🚦 Gate** needs its `Done-when:` met
**and** an explicit human review of the deliverable before any dependent task proceeds. A
task marked **🔒 needs-human** needs a one-time human step (credentials, provisioning, a live
go/no-go) and is recorded `failed:blocked`, never auto-completed.

---

## Status index

> The checkbox is the **only** source of done/not-done. Group by phase as the backlog grows.

- [ ] T001 Project scaffold + local Definition of Done passes on an empty build

---

## Tasks

### T001 — Project scaffold + local Definition of Done passes on an empty build
- **Depends on:** (none)
- **Scope:** `Sprout.xcodeproj`, `Sprout/` app sources, `SproutTests/`, `.swiftlint.yml`,
  `.swiftformat`, `README.md`
- **Verify:** simulator-screenshot
- **Do:** Create a minimal SwiftUI iOS app named **Sprout** as an Xcode project with a
  `Sprout` app target and a `SproutTests` unit-test target containing one trivial passing
  test. Add baseline `.swiftlint.yml` and `.swiftformat` configs and make the sources pass
  `swiftformat --lint .` and `swiftlint --strict`. Confirm the test `-destination`
  (`platform=iOS Simulator,name=iPhone 17`) resolves against the local Xcode install; if not,
  pick a simulator that exists and update `CLAUDE.md`, `README.md`, and `docs/HARNESS.md` §5
  together. Empirically verify per the `Verify:` recipe in `CLAUDE.md`: boot the simulator,
  build/install/launch the app, capture `worklog/T001-verify.png`, and confirm the default
  SwiftUI screen renders.
- **Done-when:** `swiftformat --lint .`, `swiftlint --strict`, and `xcodebuild test` (iPhone 17
  simulator) all pass locally on a clean tree; the screenshot observation is recorded in
  `worklog/T001.md`; `README.md` documents how to open/build/run with the exact local DoD
  commands; the DoD commands in `docs/HARNESS.md` §5 match; the T001 index box and README
  status row are flipped to done in the same commit.
