class_name RosterGridLayout
extends RefCounted

## Pure width-driven packing for roster-heavy screens.


static func fitting_columns(
		available_width: float,
		minimum_item_width: float,
		gap: float,
		maximum_columns: int = 0,
		item_count: int = -1,
		force_single: bool = false,
	) -> int:
	if force_single:
		return 1
	var safe_minimum := maxf(1.0, minimum_item_width)
	var safe_gap := maxf(0.0, gap)
	var columns := maxi(
		1,
		floori((maxf(0.0, available_width) + safe_gap) / (safe_minimum + safe_gap)),
	)
	if maximum_columns > 0:
		columns = mini(columns, maximum_columns)
	if item_count >= 0:
		columns = mini(columns, maxi(1, item_count))
	return columns


static func fitted_item_width(
		available_width: float,
		columns: int,
		gap: float,
		minimum_item_width: float,
		preferred_item_width: float,
	) -> float:
	var safe_columns := maxi(1, columns)
	var safe_gap := maxf(0.0, gap)
	var gaps := safe_gap * float(safe_columns - 1)
	var fitted := (maxf(0.0, available_width) - gaps) / float(safe_columns)
	return minf(
		maxf(minimum_item_width, preferred_item_width),
		maxf(minimum_item_width, fitted),
	)
