# SAFE-CHANGE-RULES.md

## Safe Change Rules

Before changing anything:

1. **Understand first** — inspect the relevant files, dependencies, data flow, APIs, and existing behavior.
2. **Minimal scope** — change only what is required for the requested task. Do not refactor, rename, restructure, or “improve” unrelated code.
3. **Preserve behavior** — existing features, contracts, permissions, UI behavior, database structure, and integrations must continue working.
4. **No guessing** — if the impact or correct implementation is unclear, stop and ask before modifying.
5. **Dependency awareness** — check imports, callers, shared components, API contracts, schemas, and side effects before changing them.
6. **No destructive changes** — never delete data, files, functionality, or configuration unless explicitly approved.
7. **Validate before finishing** — run relevant tests/checks and verify the requested change without introducing regressions.
8. **Stop on risk** — if the change may affect unrelated functionality or production behavior, explain the risk and get approval first.

**Rule:** Inspect → Scope → Change minimally → Validate → Report.  
Never trade existing stability for a cleaner or shorter implementation.
