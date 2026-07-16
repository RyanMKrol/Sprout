# Sprout build preamble — standing rules for every build

## Test destination — always the dedicated device, never the shared model

Every `xcodebuild test` / `build_run.sh` invocation targets the **`Sprout-Claude`** simulator
(ensured idempotently by `./tools/loop_sim.sh`). **This overrides any command text quoted in a
task's spec or `verify` array:** if a spec still says `name=iPhone 17 Pro` (or any generic model
name), substitute `name=Sprout-Claude` when you run it. Any **new** script or tool a task has you
create that boots or targets a simulator must default to `Sprout-Claude` via `tools/loop_sim.sh`,
never a generic model name.

Why: generic model names resolve to a device **shared** with other projects' harness loops running
on this Mac — two loops installing and relaunching their own apps onto the same simulator makes the
running app flip-flop and `xcodebuild test` flake. A uniquely-named dedicated device removes the
clash. (CI is deliberately **not** pinned — GitHub runners are isolated, and its
`resolve-simulator` step is correct there.)
