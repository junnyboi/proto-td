class_name SlowFieldState
extends RefCounted

## Authoritative persistent spell area. Plain integer data only: BattleModel
## owns lifecycle and movement queries; BattleView merely projects instances.

var id: int = 0
var spell_id: StringName = &""
var center: Vector2i = Vector2i.ZERO
var radius: int = 0
var slow_permille: int = 0
var expires_tick: int = 0


func covers(cell: Vector2i) -> bool:
	return maxi(absi(cell.x - center.x), absi(cell.y - center.y)) <= radius
