# Automatic window layout

The [Noobs layout Lua script](../macroquest/lua/noobs_layout.lua) arranges the
UI to match the monk layout shown in the README. It requires MacroQuest's Lua
plugin and the Noobs Blue Infinity skin.

## How to use

1. Copy `noobs_layout.lua` into your MacroQuest `lua` directory.
2. Set EverQuest to your preferred resolution and load the skin with
   `/loadskin Freq_di28889`.
3. In game, run one of these commands:

   ```
   /lua run noobs_layout
   /lua run noobs_layout 1440p
   /lua run noobs_layout 1080p
   /lua run noobs_layout 720p
   ```

The first command selects the preset from the current client width. The script
does not change your resolution. It positions the main windows for your character's class
and makes hotbars 2, 3, and 4 single horizontal rows of 12 buttons
with the page spinners disabled. Hotbutton assignments and chat tabs are
unchanged. The separate target-of-target window, Actions window, window
selector bar, and compass are hidden. The target window itself still contains
target-of-target information.

Use the same command again after changing resolutions. Apply the
[MacroQuest plugin layout settings](technical.md#macroquest-layout-settings)
for the target and group windows separately.

To check the planned positions without moving any windows:

```
/lua run noobs_layout 720p preview
```

## Layout differences

| Preset | Arrangement |
| --- | --- |
| 2560 x 1440 | Extended targets on the left, three horizontal hotbars below, chat, primary hotbar, target, group, and player panels along the bottom, buffs in the top right. |
| 1920 x 1080 | Same arrangement with a narrower chat window. |
| 1280 x 720 | Keeps the hotbars and buffs in place. Moves the player above the bottom dock and chat to the bottom right so the fixed-size controls fit. |

The script uses the actual drawable client dimensions instead of assuming
fullscreen, so typical window borders and title bars are accommodated. It
preserves native XML control sizes rather than shrinking text. The script
resizes the hotbar button grids directly, reads their actual snapped sizes,
and verifies every button is in the same row before stacking the bars.
It retains the user's button scale and leaves hotbar 1 unchanged.

- Pure casters: the spell bar sits on the far left, with extended targets
  beside it. The combat abilities window is hidden.
- Melee classes: extended targets are on the far left with combat abilities
  beside them; the spell bar is hidden.
- Hybrid classes (including bards): spell bar, extended targets, and combat
  abilities are all visible.

These arrangements use the native control sizes at normal UI scale.
If the predicted geometry does not fit, it reports the conflict before
moving windows. Preview reports the predicted sizes without changing settings.
The primary visible chat container is arranged; extra separate chat windows
are left alone, as are independent MacroQuest plugin overlays.

## Validation

From the repository root, run:

```sh
lua tools/tests/test_noobs_layout.lua
luajit tools/tests/test_noobs_layout.lua
```

The tests simulate the MacroQuest window API, check fullscreen and windowed
dimensions for all three resolutions, detect overlapping or off-screen
rectangles, and verify preview and error handling, including converting existing
two-row hotbars, preserving already-hidden spinners, and checking placement
and visibility for melee, pure caster, and hybrid layouts.

A live cleric test at 1920 x 1050 confirmed that the automatic preset
positioned all 13 active windows, hid all five requested windows, and
placed the spell bar directly left of extended targets. Three originally
two-row hotbars were converted to 516 x 56 single rows with all 12 buttons
visible and both spinner controls hidden. A repeat run preserved those
settings. The 1440p and 720p presets and hybrid/melee class variants have
passed offline tests but still need in-game verification.
