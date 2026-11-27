-- Restore the Noobs Blue Infinity melee layout.
-- /lua run noobs_layout [auto|1440p|1080p|720p] [preview]
local mq = require('mq')
local imgui = require('ImGui')
local preset, mode = ...
preset = (preset or 'auto'):lower()

local function log(message)
    print('[Noobs Layout] ' .. message)
end

if preset ~= 'auto' and preset ~= '1440p' and preset ~= '1080p' and preset ~= '720p'
    or mode and mode ~= 'preview' then
    log('Usage: /lua run noobs_layout [auto|1440p|1080p|720p] [preview]')
    return
end

if mq.TLO.EverQuest.GameState() ~= 'INGAME' then
    log('Enter the game before running this script.')
    return
end

if (mq.TLO.EverQuest.CurrentUI() or ''):lower() ~= 'freq_di28889' then
    log('Load the skin first: /loadskin Freq_di28889')
    return
end

-- Use the actual drawable client size, including windowed-mode differences.
local display = imgui.GetIO().DisplaySize
local width, height = math.floor(display.x), math.floor(display.y)
if preset == 'auto' then
    if width >= 2300 then
        preset = '1440p'
    elseif width >= 1600 then
        preset = '1080p'
    else
        preset = '720p'
    end
end

-- Fixed-size XML controls retain their native pixel dimensions.
-- Rectangles are {x, y, width, height}, not EQ's encoded INI positions.
local function buildLayout(w, h, profile)
    local windows = {}
    local function add(name, x, y, ww, hh)
        windows[#windows + 1] = {name = name, x = x, y = y, w = ww, h = hh}
    end

    local compact = profile == '720p'
    local barWidth, barHeight = 522, 60
    local dockTop = h - 3 * barHeight
    local xtarTop = dockTop - 302

    add('HotButtonWnd2', 0, dockTop, barWidth, barHeight)
    add('HotButtonWnd3', 0, dockTop + barHeight, barWidth, barHeight)
    add('HotButtonWnd4', 0, dockTop + 2 * barHeight, barWidth, barHeight)
    add('ExtendedTargetWnd', 0, xtarTop, 119, 300)
    add('ActionsWindow', 0, xtarTop - 189, 124, 187)
    add('CombatAbilityWnd', 121, dockTop - 142, 174, 140)

    local buffWidth = compact and 186 or 192
    local shortWidth = compact and 182 or 186
    local buffX = w - buffWidth - 2
    local shortX = buffX - shortWidth - 2
    add('BuffWindow', buffX, 2, buffWidth, 480)
    add('ShortDurationBuffWindow', shortX, 2, shortWidth, 466)

    if compact then
        -- The full horizontal dock is wider than 1280 pixels. Reflow the
        -- player and chat rather than scaling fixed XML controls or buffs.
        local mainX = barWidth + 2
        local groupX = mainX + 189
        add('HotButtonWnd', mainX, h - 275, 187, 275)
        add('GroupWindow', groupX, h - 282, 182, 282)
        add('TargetWindow', mainX + 28, h - 435, 254, 149)
        add('PlayerWindow', 298, h - 527, 250, 250)
        add('EQMainWnd', 249, dockTop - 192, 44, 44)
        local chatX = groupX + 184
        local chatY = math.max(484, h - 198)
        add('ChatContainerWindow', chatX, chatY, w - chatX - 2, h - chatY)
    else
        -- Original bottom dock: hotbars, chat, primary hotbar, group, player.
        local chatX = barWidth + 2
        local chatWidth = profile == '1440p' and 468 or 400
        local mainX = chatX + chatWidth + 2
        local groupX = mainX + 189
        local chatY = h - 198
        add('ChatContainerWindow', chatX, chatY, chatWidth, 198)
        add('EQMainWnd', mainX - 46, chatY - 46, 44, 44)
        add('HotButtonWnd', mainX, h - 275, 187, 275)
        add('GroupWindow', groupX, h - 282, 194, 282)
        add('TargetWindow', mainX, h - 435, 254, 149)
        add('PlayerWindow', groupX + 196, h - 250, 250, 250)
    end

    return windows
end

local windows = buildLayout(width, height, preset)
-- Validate the complete geometry before adjusting any game windows.
for i, a in ipairs(windows) do
    if a.x < 0 or a.y < 0 or a.w <= 0 or a.h <= 0 or a.x + a.w > width or a.y + a.h > height
        or (a.name == 'ChatContainerWindow' and (a.w < 300 or a.h < 150)) then
        log(string.format('%s does not fit %dx%d (%s). Choose a smaller preset or enlarge the client.',
            a.name, width, height, preset))
        return
    end
    for j = 1, i - 1 do
        local b = windows[j]
        if a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y then
            log(string.format('%s and %s overlap at %dx%d (%s). Choose a smaller preset or enlarge the client.',
                a.name, b.name, width, height, preset))
            return
        end
    end
end

log(string.format('%s layout for %dx%d%s', preset, width, height, mode == 'preview' and ' (preview)' or ''))

local applied, issues = 0, 0
for _, r in ipairs(windows) do
    local rect = string.format('%d,%d,%d,%d', r.x, r.y, r.w, r.h)
    if mode == 'preview' then
        log(r.name .. ': ' .. rect)
    else
        local wnd = mq.TLO.Window(r.name)
        if wnd.Open() == nil then
            log('Window unavailable: ' .. r.name)
            issues = issues + 1
        else
            if not wnd.Open() then
                wnd.DoOpen()
                mq.delay(50)
            end
            wnd.Move(rect)
            mq.delay(50)
            if not wnd.Open() or wnd.X() ~= r.x or wnd.Y() ~= r.y or wnd.Width() ~= r.w or wnd.Height() ~= r.h then
                log('Client adjusted or refused the requested geometry: ' .. r.name)
                issues = issues + 1
            else
                applied = applied + 1
            end
        end
    end
end
if mode ~= 'preview' then
    log(string.format('Applied %d/%d windows; %d need checking. Your hotbank contents and chat tabs were not changed.',
        applied, #windows, issues))
end
