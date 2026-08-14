extends GutTest

const _SHELL_ALIASES := [
	"AetheriaButtonType", "AetheriaLabelType", "AetheriaScreenShellType", "UiCopyType",
]
const _SHELL_FORBIDDEN := [
	"\\bAetheriaButton\\b", "\\bAetheriaLabel\\b",
	"\\bAetheriaScreenShell\\b", "\\bUiCopy\\b",
]
const STALE_PROBE_PATH := "res://tools/probes/stale_class_registry_boot.gd"
const CONTRACTS := [
	{
		"path": "res://autoloads/i18n.gd",
		"aliases": ["UiCopyType"],
		"forbidden": ["\\bUiCopy\\b"],
	},
	{
		"path": "res://scripts/ui/components/aetheria_button.gd",
		"aliases": ["AetheriaLabelType"],
		"forbidden": ["\\bAetheriaLabel\\b"],
	},
	{
		"path": "res://scripts/ui/components/aetheria_locale_selector.gd",
		"aliases": ["UiCopyType"],
		"forbidden": ["\\bUiCopy\\b"],
	},
	{
		"path": "res://scripts/ui/title.gd",
		"aliases": [
			"AetheriaButtonType", "AetheriaLabelType", "AetheriaLocaleSelectorType",
			"AetheriaScreenShellType", "UiCopyType",
		],
		"forbidden": [
			"\\bAetheriaButton\\b", "\\bAetheriaLabel\\b",
			"\\bAetheriaLocaleSelector\\b", "\\bAetheriaScreenShell\\b", "\\bUiCopy\\b",
		],
	},
	{
		"path": "res://scripts/ui/staging.gd",
		"aliases": _SHELL_ALIASES,
		"forbidden": _SHELL_FORBIDDEN,
	},
	{
		"path": "res://scripts/ui/stage_select.gd",
		"aliases": _SHELL_ALIASES,
		"forbidden": _SHELL_FORBIDDEN,
	},
	{
		"path": "res://scripts/ui/squad_select.gd",
		"aliases": _SHELL_ALIASES,
		"forbidden": _SHELL_FORBIDDEN,
	},
	{
		"path": "res://scripts/ui/results.gd",
		"aliases": _SHELL_ALIASES,
		"forbidden": _SHELL_FORBIDDEN,
	},
]
const SIMULATION_CONTRACTS := [
	{
		"path": "res://sim/campaign_promotion.gd",
		"aliases": [
			"CampaignCodecType", "CampaignProgressionType", "CampaignHashType",
			"CanonicalJsonType",
		],
		"forbidden": [
			"\\bCampaignCodec\\b", "\\bCampaignProgression\\b", "\\bCampaignHash\\b",
			"\\bCanonicalJson\\b",
		],
	},
	{
		"path": "res://sim/campaign_codec.gd",
		"aliases": [
			"CampaignHeroCodec", "CampaignProgression", "CanonicalJson",
			"HeroIdentity", "HeroNames",
		],
		"forbidden": [],
	},
	{
		"path": "res://sim/campaign_hash.gd",
		"aliases": [
			"CampaignCodec", "CampaignProgression", "CanonicalJson",
			"HeroIdentity", "HeroNames",
		],
		"forbidden": [],
	},
	{
		"path": "res://sim/campaign_hero_codec.gd",
		"aliases": ["CampaignProgression", "HeroIdentity", "HeroNames"],
		"forbidden": [],
	},
	{
		"path": "res://sim/hero_names.gd",
		"aliases": ["HeroIdentity", "HeroNamesV1"],
		"forbidden": [],
	},
	{
		"path": "res://sim/campaign_invariants.gd",
		"aliases": [
			"CampaignCodec", "CampaignHash", "CampaignProgression",
			"CampaignPromotionHistory", "CanonicalJson", "HeroIdentity",
		],
		"forbidden": [],
	},
	{
		"path": "res://sim/campaign_save_upgrade.gd",
		"aliases": ["CampaignMigration", "CanonicalJson"],
		"forbidden": [],
	},
	{
		"path": "res://sim/campaign_migration.gd",
		"aliases": ["CampaignCodec", "CampaignHash", "CampaignProgression"],
		"forbidden": [],
	},
	{
		"path": "res://sim/campaign_legacy_hash.gd",
		"aliases": ["HeroIdentity"],
		"forbidden": [],
	},
]


func test_shipped_ui_consumers_preload_scripts_instead_of_using_global_registry() -> void:
	for raw_contract: Variant in CONTRACTS:
		var contract := raw_contract as Dictionary
		var path := String(contract["path"])
		var source := FileAccess.get_file_as_string(path)
		assert_false(source.is_empty(), path)
		for raw_alias: Variant in contract["aliases"]:
			var alias := String(raw_alias)
			assert_true(
				source.contains("const %s := preload(" % alias),
				"%s is missing %s" % [path, alias],
			)
		for raw_pattern: Variant in contract["forbidden"]:
			var expression := RegEx.new()
			assert_eq(expression.compile(String(raw_pattern)), OK, path)
			assert_null(expression.search(source), "%s still uses %s" % [path, raw_pattern])


func test_stale_probe_requires_exact_shipped_locale_registry() -> void:
	var source := FileAccess.get_file_as_string(STALE_PROBE_PATH)
	assert_false(source.is_empty())
	assert_true(
		source.contains('PackedStringArray(["en-US", "zh-CN"])'),
		"stale-cache probe must require the exact shipped locale registry",
	)
	assert_false(source.contains('PackedStringArray(["en-US"])'))


func test_training_promotion_dependencies_preload_stale_cache_helpers() -> void:
	for raw_contract: Variant in SIMULATION_CONTRACTS:
		var contract := raw_contract as Dictionary
		var path := String(contract["path"])
		var source := FileAccess.get_file_as_string(path)
		assert_false(source.is_empty(), path)
		for raw_alias: Variant in contract["aliases"]:
			var alias := String(raw_alias)
			assert_true(
				source.contains("const %s := preload(" % alias),
				"%s is missing %s" % [path, alias],
			)
		for raw_pattern: Variant in contract["forbidden"]:
			var expression := RegEx.new()
			assert_eq(expression.compile(String(raw_pattern)), OK, path)
			assert_null(expression.search(source), "%s still uses %s" % [path, raw_pattern])
	var codec_source := FileAccess.get_file_as_string("res://sim/campaign_codec.gd")
	assert_true(codec_source.contains(
		'return load("res://sim/campaign_invariants.gd") as Script',
	))
