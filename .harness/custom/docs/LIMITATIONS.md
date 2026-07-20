# custom/docs/LIMITATIONS.md — this project's trade-offs & limitations log (OPTIONAL)

Customization overlay for `.harness/docs/LIMITATIONS.md`. This is an **optional** place to keep your
project's own trade-off / limitation notes — the harness does NOT require you to maintain it and no task
is expected to update it (documentation is the maintainers' responsibility, not the loop's). If you *do*
choose to track project trade-offs, put the rows **here** — not in the pristine `docs/LIMITATIONS.md`,
which is plugin-owned and refreshed on upgrade. Harness upgrades never touch this file. (See
`.harness/custom/CLAUDE.md`.)

A useful row records: what it is, *why* it was chosen, its **impact**, and *when to revisit*.

<!-- Optional: add your project-specific limitation rows here. -->

### Redesigned screens use fixed custom font sizes (no Dynamic Type)

**What:** `SproutFont`'s `display`/`body`/`bodyItalic` helpers (used throughout the Botanical
Editorial redesign, T016–T048) build `Font.custom(name, size: fixedPoints)` — a literal point size,
not a `relativeTo:` text style — so none of the redesigned screens scale with the user's Dynamic
Type setting.

**Why:** the redesign's layouts (bento tiles, hero cards, fixed-height chips) were hand-tuned to
specific type sizes to hit the visual design; wiring `@ScaledMetric`/`relativeTo:` scaling through
every call site was out of scope for the visual sweep and would have re-opened layout work on
screens already signed off.

**Impact:** users who increase their system text size get no larger text on any redesigned screen —
an accessibility gap (WCAG 1.4.4 / App Store accessibility review) that predates this cleanup task
and is carried forward, not introduced by it.

**Revisit trigger:** before App Store submission, or the next time a Dynamic Type / accessibility
audit flags it — scale `SproutFont` to use `relativeTo:` text styles with `@ScaledMetric` overrides
at the tightest layouts, and re-verify each redesigned screen at the largest accessibility sizes.
