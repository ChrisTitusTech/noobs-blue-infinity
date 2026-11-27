# Technical documentation

This update ports the original May 2020 Noobs Blue Infinity skin to
the November 2026 EverQuest Live client.

## Legacy files

The custom skin relies on the client's normal default-file fallback. Keep
the stock `uifiles/default` directory intact.

The old alternative XML files are retained for reference but have not been
ported. Do not rename them over the active files. [legacy-overrides/](../legacy-overrides/) contains
the old merchant, options, advanced display options, and confirmation dialog
overrides; the modern client supplies these windows instead.

## Compatibility changes

- Ported the shared Infiniti Blue Beimeith December 7, 2025 window and atlas
  revisions, including dynamically created buff, target, pet, and loot
  controls; AA, item inspection, and guild management changes.
- Updated inventory for additional bag slots, Krono, attributes, and alternate
  personas. The inventory uses the sister skin's compact layout; the original
  May 2020 inventory is available in the import commit.
- Adapted the bank to Live's January 2026 `BNK_*` control IDs and named
  inventory-slot EQType routes, preserving the compact Blue bank layout.
- Added animations and shared templates missing from the sister skin but
  present in the installed Live client; corrected two out-of-bounds animation
  frame rectangles.
- Retained the Noobs extended target layout (including all 23 target slots),
  player-panel styling, original spell icons, and other unmodified assets.
- Restored the standard mana and fatigue label template names used by
  MQ2XTarInfo, MQ2TargetInfo, and MQ2GroupInfo without changing their layout.
- Removed the duplicate self row from the group window and reserved space
  for the six MQ2GroupInfo controls. Separated target-of-target, target
  metadata, aggro, and buffs into distinct rows.
- Adjusted the group window's default and minimum height to 270 and removed
  its maximum height constraint to keep the action footer visible without
  collapsing the live window.

## MacroQuest layout settings

Merge the `[UI_Freq_di28889]` sections in
[MQ2TargetInfo.ini](../macroquest/MQ2TargetInfo.ini) and
[MQ2GroupInfo.ini](../macroquest/MQ2GroupInfo.ini) into the
corresponding MacroQuest configuration files, replacing only that skin's
section. These settings position the plugin-created controls to match the
skin's XML layout. Reload the skin with `/loadskin Freq_di28889 1` to keep
the existing window positions.

## Validation

From the repository root, run the standalone XML/reference validator against
a patched Live client's stock UI directory:

```sh
python3 tools/validate_ui.py "/path/to/EverQuest/uifiles/default"
python3 tools/validate_ui.py "/path/to/EverQuest/uifiles/default" --macroquest
```

The validator reads the stock UI's composite include list and resolves each
file from the custom skin or the stock fallback. It checks XML parsing,
references, texture availability, and animation frame bounds. It compares
results with the stock UI to distinguish existing stock discrepancies from
new skin issues.
The optional MacroQuest check covers the external control templates used by
the target, extended target, group, and item display plugins.

The November 12, 2026 client installed locally was used for static validation:
34 active overrides, no additional issues relative to the stock UI. This does
not prove that the game's runtime window initialization or rendering succeeds;
an in-game load test is still required.

## In-game testing

After loading the skin, test inventory, alternate personas, both buff
windows, target and pet windows, spell bar, loot, item inspection, and
the bank. If a window fails, switch back with `/loadskin default` and
inspect `UIErrors.txt` in the EverQuest installation directory.
