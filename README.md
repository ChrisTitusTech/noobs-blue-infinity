# Noobs Blue Infinity - Live compatibility update

This repository contains the original Noobs Blue Infinity skin (May 2020)
and its compatibility update for the November 2026 EverQuest Live client.

## Install

1. Copy the entire `Freq_di28889` directory into EverQuest's `uifiles`
   directory. Keep the existing `uifiles/default` directory intact; the
   custom skin relies on the client's normal default-file fallback.
2. In game, use `/loadskin Freq_di28889` (or select it in the Load UI Skin
   dialog).
3. Test inventory, alternate personas, both buff windows, target and pet
   windows, spell bar, loot, item inspection, and the bank. If a window fails,
   switch back with `/loadskin default` and inspect `UIErrors.txt` in the
   EverQuest installation directory.

The old alternative XML files are retained for reference but have not been
ported. Do not rename them over the active files. `legacy-overrides/` contains
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

## Validation

Run the standalone XML/reference validator against a patched Live client's
stock UI directory:

```sh
python3 tools/validate_ui.py "/path/to/EverQuest/uifiles/default"
```

The validator reads the stock UI's composite include list and resolves each
file from the custom skin or the stock fallback. It checks XML parsing,
references, texture availability, and animation frame bounds. It compares
results with the stock UI to distinguish existing stock discrepancies from
new skin issues.

The November 12, 2026 client installed locally was used for static validation:
34 active overrides, no additional issues relative to the stock UI. This does
not prove that the game's runtime window initialization or rendering succeeds;
an in-game load test is still required.
