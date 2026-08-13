extends SceneTree

## Stage data lint (verify.sh rung R2.5). Phase 1 checks: path contiguity
## (4-connected, unit steps), starts on SPAWN, ends on BASE, every path cell
## enemy-walkable, wave enemy ids resolve, path_idx in range, sane limits.
## Phase 10 (td-phase-10.md §2.7): reward id resolution + no double grants,
## dense campaign_index 1..8, teach-before-use (requires ⊆ starting set ∪
## earlier rewards — the STARTING SET comes from the same LegacyCampaignAdapter
## derivation the runtime uses, so the two can't drift), difficulty
## monotonicity (Σ wave hp non-decreasing in campaign order), campaign
## hygiene (intro_hint, squad_size vs available operators, wave_starts ≥ 2).

const STAGES_DIR := "res://data/stages"
const ENEMIES_DIR := "res://data/enemies"
const CAMPAIGN_COUNT := 8
const KIND_DIRS := {
	&"operator": "res://data/operators",
	&"trap": "res://data/traps",
	&"spell": "res://data/spells",
}


func _initialize() -> void:
	var failures: Array[String] = []
	var stage_files := _list_tres(STAGES_DIR)
	if stage_files.is_empty():
		failures.append("no stages found under %s" % STAGES_DIR)
	var stages: Array = []
	for path: String in stage_files:
		var stage := _lint_stage(path, failures)
		if stage != null:
			stages.append(stage)
	_lint_campaign(stages, failures)
	if failures.is_empty():
		print("[stage-lint] OK (%d stages)" % stage_files.size())
		quit(0)
	else:
		for f: String in failures:
			printerr("[stage-lint] FAIL: " + f)
		quit(1)


## §2.7 campaign rules (key off campaign_index >= 1 — test stages opt out).
func _lint_campaign(stages: Array, failures: Array[String]) -> void:
	var campaign: Array = []
	for stage: StageDef in stages:
		if stage.campaign_index >= 1:
			campaign.append(stage)
	if campaign.is_empty():
		return
	campaign.sort_custom(func(a: StageDef, b: StageDef) -> bool:
		return a.campaign_index < b.campaign_index)
	if campaign.size() != CAMPAIGN_COUNT:
		failures.append("campaign: expected %d stages, found %d" % [CAMPAIGN_COUNT, campaign.size()])
	for i: int in campaign.size():
		if (campaign[i] as StageDef).campaign_index != i + 1:
			failures.append("campaign: indices not dense/unique at position %d" % i)
			return
	var granted: Dictionary = {}
	for stage: StageDef in campaign:
		var tag := String(stage.id)
		for reward: Dictionary in stage.rewards:
			var kind: StringName = reward.get("kind", &"")
			var item_id: StringName = reward.get("id", &"")
			if not KIND_DIRS.has(kind):
				failures.append("%s: reward kind '%s' unknown" % [tag, kind])
				continue
			var item_path := "%s/%s.tres" % [KIND_DIRS[kind], item_id]
			if not ResourceLoader.exists(item_path):
				failures.append("%s: reward id has no def: %s" % [tag, item_path])
			if granted.has(item_id):
				failures.append("%s: reward '%s' granted twice in the campaign" % [tag, item_id])
			granted[item_id] = true
	_lint_teach_before_use(campaign, failures)
	_lint_monotonic_and_hygiene(campaign, failures)


func _lint_teach_before_use(campaign: Array, failures: Array[String]) -> void:
	var catalogs := {
		"operators": _scan_ids(KIND_DIRS[&"operator"]),
		"traps": _scan_ids(KIND_DIRS[&"trap"]),
		"spells": _scan_ids(KIND_DIRS[&"spell"]),
	}
	var starting := LegacyCampaignAdapter.derive_starting_unlocks(catalogs, campaign)
	var available: Dictionary = {}
	for kind: String in starting:
		for item_id: StringName in starting[kind]:
			available[item_id] = true
	for stage: StageDef in campaign:
		var tag := String(stage.id)
		for req: StringName in stage.requires:
			if not available.has(req):
				failures.append("%s: requires '%s' but nothing earlier unlocks it" % [tag, req])
		for reward: Dictionary in stage.rewards:
			available[reward.get("id", &"")] = true


func _lint_monotonic_and_hygiene(campaign: Array, failures: Array[String]) -> void:
	var enemy_hp: Dictionary = {}
	var prev_total := -1
	var starting_ops: Array = LegacyCampaignAdapter.derive_starting_unlocks({
		"operators": _scan_ids(KIND_DIRS[&"operator"]),
		"traps": [], "spells": [],
	}, campaign)["operators"] as Array
	var available: Dictionary = {}
	for operator_id: StringName in starting_ops:
		available[operator_id] = true
	for stage: StageDef in campaign:
		var tag := String(stage.id)
		var total := 0
		for w: Dictionary in stage.waves:
			var enemy_id: StringName = w.get("enemy_id", &"")
			if not enemy_hp.has(enemy_id):
				var def := load("%s/%s.tres" % [ENEMIES_DIR, enemy_id]) as EnemyDef
				enemy_hp[enemy_id] = def.hp if def != null else 0
			total += int(enemy_hp[enemy_id])
		if total < prev_total:
			failures.append(
				"%s: difficulty not monotonic (hp %d < previous %d)" % [tag, total, prev_total]
			)
		prev_total = total
		if stage.intro_hint.strip_edges().is_empty():
			failures.append("%s: campaign stage needs an intro_hint" % tag)
		if stage.squad_size < 1:
			failures.append("%s: campaign stage needs squad_size >= 1" % tag)
		if stage.wave_starts.size() < 2:
			failures.append("%s: campaign stage needs wave_starts.size() >= 2" % tag)
		if available.size() < stage.squad_size:
			failures.append(
				"%s: only %d operators available for squad_size %d"
				% [tag, available.size(), stage.squad_size]
			)
		_lint_recovery_roster(stage, available, failures)
		for reward: Dictionary in stage.rewards:
			if reward.get("kind", &"") == &"operator":
				available[reward.get("id", &"")] = true


func _lint_recovery_roster(
	stage: StageDef,
	available: Dictionary,
	failures: Array[String],
) -> void:
	var tag := String(stage.id)
	if stage.recovery_roster.is_empty():
		failures.append("%s: campaign stage needs a recovery_roster" % tag)
		return
	if stage.recovery_roster.size() > stage.squad_size:
		failures.append(
			"%s: recovery_roster size %d exceeds squad_size %d"
			% [tag, stage.recovery_roster.size(), stage.squad_size]
		)
	var seen := {}
	for operator_id: StringName in stage.recovery_roster:
		if seen.has(operator_id):
			failures.append("%s: recovery_roster duplicates '%s'" % [tag, operator_id])
		seen[operator_id] = true
		if not available.has(operator_id):
			failures.append(
				"%s: recovery operator '%s' is not available before this stage"
				% [tag, operator_id]
			)


func _scan_ids(dir_path: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return ids
	for f: String in dir.get_files():
		var source := f.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var item_id := StringName(source.trim_suffix(".tres"))
			if not ids.has(item_id):
				ids.append(item_id)
	return ids


func _list_tres(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f: String in dir.get_files():
		var source := f.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var path := dir_path + "/" + source
			if not out.has(path):
				out.append(path)
	out.sort()
	return out


func _lint_stage(path: String, failures: Array[String]) -> StageDef:
	var stage := load(path) as StageDef
	if stage == null:
		failures.append("%s: not a StageDef" % path)
		return null
	var tag := String(stage.id)
	# P10 audit F4: filename<->id agreement is load-bearing (Game loads defs
	# by filename, LegacyCampaignAdapter/screens load by stage.id — a mismatch is
	# lint-green but breaks the campaign at runtime)
	if path.get_file().trim_suffix(".tres") != tag:
		failures.append("%s: file name does not match stage id '%s'" % [path, tag])
	# P10 audit F3: campaign metadata on non-campaign stages is dead data the
	# runtime silently skips; index 0 is neither campaign nor the -1 opt-out
	if stage.campaign_index == 0:
		failures.append("%s: campaign_index 0 (use -1 for non-campaign, 1..N for campaign)" % tag)
	if stage.campaign_index < 1 and (not stage.rewards.is_empty() or not stage.requires.is_empty()):
		failures.append("%s: rewards/requires on a non-campaign stage are dead data" % tag)
	if stage.music_act < 1 or stage.music_act > 3:
		failures.append("%s: music_act must be 1..3 (got %d)" % [tag, stage.music_act])
	if stage.campaign_index >= 1 and stage.campaign_index <= 8:
		var expected_act := 1 if stage.campaign_index <= 4 else 2
		if stage.music_act != expected_act:
			failures.append(
				"%s: campaign index %d must route to music act %d (got %d)"
				% [tag, stage.campaign_index, expected_act, stage.music_act]
			)
	if stage.grid_rows.is_empty():
		failures.append("%s: empty grid" % tag)
		return stage
	var width := stage.grid_rows[0].length()
	for row: String in stage.grid_rows:
		if row.length() != width:
			failures.append("%s: ragged grid rows" % tag)
	if stage.paths.is_empty():
		failures.append("%s: no paths" % tag)
	for i: int in stage.paths.size():
		_lint_path(stage, i, failures, tag)
	for w: Dictionary in stage.waves:
		var enemy_path := "%s/%s.tres" % [ENEMIES_DIR, w.get("enemy_id", "")]
		if not ResourceLoader.exists(enemy_path):
			failures.append("%s: wave enemy id has no def: %s" % [tag, enemy_path])
		var pi := int(w.get("path_idx", -1))
		if pi < 0 or pi >= stage.paths.size():
			failures.append("%s: wave path_idx out of range: %d" % [tag, pi])
		if int(w.get("tick", -1)) < 0:
			failures.append("%s: wave tick < 0" % tag)
	if stage.leak_limit < 0:
		failures.append("%s: leak_limit < 0" % tag)
	_lint_wave_starts(stage, failures, tag)
	_lint_music_route(stage, failures, tag)
	return stage


func _lint_music_route(stage: StageDef, failures: Array[String], tag: String) -> void:
	var boss_wave := stage.music_boss_wave_index
	if boss_wave < -1:
		failures.append("%s: music_boss_wave_index must be -1 or a wave index" % tag)
	elif boss_wave >= stage.wave_starts.size():
		failures.append(
			"%s: music boss wave %d out of range for %d wave windows"
			% [tag, boss_wave, stage.wave_starts.size()]
		)
	# The shipped campaign currently ends Acts I and II at S4 and S8.
	var expected_boss_wave: int = int({4: 1, 8: 2}.get(stage.campaign_index, -1))
	if stage.campaign_index >= 1 and stage.campaign_index <= 8 \
			and boss_wave != expected_boss_wave:
		failures.append(
			"%s: campaign index %d must use boss wave %d (got %d)"
			% [tag, stage.campaign_index, expected_boss_wave, boss_wave]
		)


## wave_starts (td-phase-6-7.md §4.4): empty is valid (one window); a
## non-empty list must start at 0 and ascend strictly.
func _lint_wave_starts(stage: StageDef, failures: Array[String], tag: String) -> void:
	if stage.wave_starts.is_empty():
		return
	if stage.wave_starts[0] != 0:
		failures.append("%s: wave_starts must start at 0 (got %d)" % [tag, stage.wave_starts[0]])
	for i: int in stage.wave_starts.size():
		if stage.wave_starts[i] < 0:
			failures.append("%s: wave_starts[%d] < 0" % [tag, i])
		if i > 0 and stage.wave_starts[i] <= stage.wave_starts[i - 1]:
			failures.append("%s: wave_starts not strictly ascending at index %d" % [tag, i])


func _lint_path(stage: StageDef, idx: int, failures: Array[String], tag: String) -> void:
	var cells := stage.path_cells(idx)
	if cells.size() < 2:
		failures.append("%s path %d: fewer than 2 cells" % [tag, idx])
		return
	if stage.tile_at(cells[0]) != StageDef.Tile.SPAWN:
		failures.append("%s path %d: does not start on SPAWN (%s)" % [tag, idx, cells[0]])
	if stage.tile_at(cells[cells.size() - 1]) != StageDef.Tile.BASE:
		failures.append("%s path %d: does not end on BASE (%s)" % [tag, idx, cells[cells.size() - 1]])
	for i: int in cells.size():
		if not stage.is_enemy_walkable(cells[i]):
			failures.append("%s path %d: cell %s not walkable" % [tag, idx, cells[i]])
		if i > 0:
			var d: Vector2i = (cells[i] - cells[i - 1]).abs()
			if d.x + d.y != 1:
				failures.append(
					"%s path %d: not contiguous at %s -> %s" % [tag, idx, cells[i - 1], cells[i]]
				)
