# Noobs Blue Infinity

A compact blue UI for EverQuest Live (November 2026).

<img width="2550" height="1394" alt="noob-ui" src="https://github.com/user-attachments/assets/a31171fe-fe20-46f2-a698-2f9f8b42cc47" />

## Install

1. Click **Code > Download ZIP** and extract it.
2. Copy `Freq_di28889` into EverQuest's `uifiles` folder. Keep the `default` folder.
3. In game, run `/loadskin Freq_di28889`.

## Automatic layout (MacroQuest)

1. Copy [noobs_layout.lua](macroquest/lua/noobs_layout.lua) into MacroQuest's `lua` folder.
2. Apply the [plugin layout settings](docs/technical.md#macroquest-layout-settings) if you use MQ2TargetInfo or MQ2GroupInfo.
3. In game, run:

   ```
   /lua run noobs_layout
   ```

Automatically detects 1440p, 1080p, or 720p and adjusts for your class.

To restore the default UI, run `/loadskin default`.

[Layout guide](docs/layout.md) | [Technical documentation](docs/technical.md)
