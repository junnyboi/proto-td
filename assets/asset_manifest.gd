class_name AssetManifest
extends Resource

## Logical asset id -> file mapping (parent plan §6.6). View code resolves
## every texture through this manifest so an art upgrade is a file swap +
## manifest edit, never a code change. Entries are written by
## tools/gen_assets.gd; each value is:
##   {"pattern": String ("%d" slot when frames > 1), "frames": int,
##    "size": Vector2i (native px, P12.1 — tiles are no longer uniform),
##    "placeholder": bool}

@export var entries: Dictionary = {}
