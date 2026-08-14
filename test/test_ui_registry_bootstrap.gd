extends GutTest

const _SHELL_ALIASES := [
	"AetheriaButtonType", "AetheriaLabelType", "AetheriaScreenShellType", "UiCopyType",
]
const _SHELL_FORBIDDEN := [
	"\\bAetheriaButton\\b", "\\bAetheriaLabel\\b",
	"\\bAetheriaScreenShell\\b", "\\bUiCopy\\b",
]
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
	{
		"path": "res://sim/campaign_promotion.gd",
		"aliases": [
			"CAMPAIGN_CODEC_SCRIPT", "CAMPAIGN_HASH_SCRIPT",
			"CAMPAIGN_PROGRESSION_SCRIPT", "CANONICAL_JSON_SCRIPT",
		],
		"forbidden": [
			"\\bCampaignCodec\\b", "\\bCampaignHash\\b",
			"\\bCampaignProgression\\b", "\\bCanonicalJson\\b",
		],
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
