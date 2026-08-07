extends Node

## Debug-mode overlay shell. Real implementation lands in Phase 8 (a UI over
## the same seam-drivable verbs the tests use — architecture rule 5). The
## autoload is registered from Phase 0 so the autoload set never churns
## (--check-only cannot resolve late-added autoloads).
