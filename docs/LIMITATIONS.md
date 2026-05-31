# LIMITATIONS.md — trade-offs, bottlenecks & known limitations

The single place to evaluate the design's compromises later **without re-deriving them from
the code**. Per `CLAUDE.md` golden rule 5, every change that introduces or reveals a
trade-off, bottleneck, or known limitation **adds a row here in the same commit**.

Each entry: **what** it is · **why** we chose it · **impact** · **when to revisit**.

---

## Harness

These come from the build harness itself (mirror of [`docs/HARNESS.md`](./HARNESS.md) §12) —
keep them here so the design's compromises live in one place alongside your project's own.

- **Hardened Definition of Done makes each task longer.**
  *Why:* empirical + integration + CI-watch is what makes "done" trustworthy.
  *Impact:* more wall-clock and tokens per task; a single window may not finish a large one.
  *Revisit:* if tasks routinely overflow a window — split them smaller.

- **CI-green-before-merge adds minutes per task.**
  *Why:* it buys an always-green `main`.
  *Impact:* latency per integration.
  *Revisit:* acceptable while sequential; only a concern if throughput becomes the constraint.

- **Sequential, single-flight — no wall-clock parallelism.**
  *Why:* the binding constraint is tokens-per-window, and parallelism multiplies
  interruption + merge-reconciliation cost, not throughput.
  *Impact:* one task at a time.
  *Revisit:* if a large batch of genuinely independent, low-conflict tasks appears with spare
  budget (HARNESS.md §6).

- **`--dangerously-skip-permissions` removes per-action guardrails.**
  *Why:* a headless loop has no human to answer prompts.
  *Impact:* no per-action confirmation; the gates + reviewable per-task branches are the
  backstop.
  *Revisit:* if a task class needs tighter control, gate it 🔒.

---

## Project

> Add your project's own trade-offs and limitations below as they arise.

- **CI runs on `macos-latest` (required for iOS).**
  *Why:* `xcodebuild` + the iOS Simulator only exist on macOS runners.
  *Impact:* macOS GitHub-hosted minutes are billed at ~10× Linux and runs are slower; the
  per-task CI gate costs more wall-clock and money than a typical Linux project.
  *Revisit:* if CI minutes become a constraint — move pure-logic tests to a SwiftPM
  `swift test` job on Linux and reserve the macOS job for the UI/app target.

- **CI test destination pins a specific simulator (`iPhone 16, OS=latest`).**
  *Why:* `xcodebuild test` needs a concrete destination, not a generic one.
  *Impact:* if the `macos-latest` image stops shipping that simulator/runtime, the Test step
  breaks until the destination is updated.
  *Revisit:* T001 should confirm the destination resolves on the current runner image; pin an
  explicit Xcode/runtime version here if drift becomes a problem.
