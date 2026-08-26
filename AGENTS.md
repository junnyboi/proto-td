# Repository Agent Instructions

## Concurrent reconciliation and deployment

When `master`, the shared WebDev branch, or either working copy advances during active work, **do not pause for routine direction or acceptance prompts**. Protect local work, fetch the newest upstream state, and reconcile immediately.

Preserve both sides of every compatible fast-forward or merge conflict. Resolve the result into one coherent implementation that retains both agents' functional intent, tests, assets, accessibility behavior, host architecture, loader/runtime mappings, and release records. Never discard newer compatible work, restore an older host snapshot, rewrite shared history, or choose one feature merely because it landed first.

After each reconciliation, run one focused regression pass for the touched systems and scan its logs for parse, runtime, resource, and test errors. Run the full suite when the focused pass exposes broader risk or another repository instruction requires it. Once validation passes, commit the reconciled result, push it to `master`, export runtime changes, layer them onto the newest forward-only WebDev host, run the normal type/build/runtime checks, and save/deploy the checkpoint.

If upstream advances again, repeat the same process automatically. Ask for direction only when a conflict is genuinely irreconcilable, destructive, security-sensitive, or would materially change intended product behavior.

> Standing rule: **keep both features, regress once, push, and deploy.**
