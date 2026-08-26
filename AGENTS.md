# Repository Agent Instructions

## Constructive concurrent reconciliation and deployment

When `master`, another working branch, the shared WebDev branch, or either working copy advances during active work, **do not pause for routine direction or acceptance prompts**. Protect uncommitted changes, fetch the latest remote state, and fast-forward when possible. If a merge is required, reconcile forward immediately.

Preserve both sides of every compatible fast-forward or merge conflict. Resolve the result into one coherent implementation that retains both agents' functional intent, tests, assets, accessibility behavior, host architecture, loader/runtime mappings, and release records. Never discard newer compatible work, restore an older host snapshot over a newer base, rewrite shared history, or choose one feature merely because it landed first.

After every reconciliation, run one focused regression pass for the touched systems and scan its logs for parse, runtime, resource, and test errors. Escalate to the full repository suite only when the focused pass exposes broader risk or another repository instruction requires it. Do not repeat visual acceptance loops for compatible merges unless the changed area requires a visual check.

Once validation passes, commit the reconciled result, push it to `master`, export the latest Godot Web build when runtime content changed, layer it onto the newest forward-only `proto-td-web` host, run the normal WebDev type/build/runtime checks, restart the preview, and save/deploy the checkpoint.

If upstream advances again, repeat the same process automatically. Ask for direction only when a conflict is genuinely irreconcilable, destructive, security-sensitive, or would materially change intended product behavior.

> Standing rule: **keep both features, regress once, push, and deploy.**
