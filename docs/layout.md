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
does not change your resolution. It positions and shows the fourteen main
windows, without changing hotbutton assignments, chat tabs, or other settings.
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
| 2560 x 1440 | Original monk layout: actions and extended target on the left, three horizontal hotbars below, chat, primary hotbar, target, group, and player panels along the bottom, buffs in the top right. |
| 1920 x 1080 | Same arrangement with a narrower chat window. |
| 1280 x 720 | Keeps the hotbars and buffs in place. Moves the player above the bottom dock and chat to the bottom right so the fixed-size controls fit. |

The script uses the actual drawable client dimensions instead of assuming
fullscreen, so typical window borders and title bars are accommodated. It
preserves native XML control sizes rather than shrinking text. It is intended
for the monk/melee layout at normal UI scale, not a caster spell-bar layout.
If the geometry does not fit, it reports the conflict before moving anything.
The primary visible chat container is arranged; extra separate chat windows
are left alone.

## Validation

From the repository root, run:

```sh
lua tools/tests/test_noobs_layout.lua
luajit tools/tests/test_noobs_layout.lua
```

The tests simulate the MacroQuest window API, check fullscreen and windowed
dimensions for all three resolutions, detect overlapping or off-screen
rectangles, and verify preview and error handling. These are offline checks.
In-game verification is still needed to confirm the client accepts the
requested geometry and the skin renders its controls correctly.
