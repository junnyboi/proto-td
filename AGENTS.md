# Agent Instructions

## Constructive concurrent reconciliation

When `master`, a working branch, or the shared WebDev host advances during active work, **reconcile forward immediately**. Protect uncommitted changes, fetch the latest remote state, and fast-forward when possible. If a merge is required, do not choose one feature over the other by default: accept both compatible sides and integrate them into one coherent implementation. Preserve both agents' functional intent, tests, assets, accessibility behavior, loader mappings, and release records. Never rewrite shared history or restore an older snapshot over a newer compatible base.

After every fast-forward or conflict resolution, run one simple regression pass focused on the touched systems and scan its logs for parse, runtime, resource, and test errors. Escalate to the full repository suite only when the focused pass exposes wider risk or repository policy explicitly requires it. Do not repeat visual acceptance loops for compatible merges unless the changed area requires a visual check.

Once the regression pass succeeds, commit the reconciled result, push it to `master`, export the latest Godot Web build when runtime content changed, layer it onto the newest `proto-td-web` host, run the normal WebDev type/build/runtime checks, restart the preview, and save/deploy the resulting checkpoint. Do not pause for direction merely because a compatible concurrent change arrived.

Ask for user direction only when the conflict is genuinely irreconcilable, destructive, security-sensitive, or would materially change intended product behavior. Otherwise, the standing rule is: **keep both features, regress once, push, and deploy**.
