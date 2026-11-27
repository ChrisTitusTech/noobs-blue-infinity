-- Restore the Noobs Blue Infinity class-aware layout.
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

-- Pure casters need the spellbar but not the discipline window. Hybrids
-- (including bards) use both, while non-casters use the discipline window.
local canCast = mq.TLO.Me.Class.CanCast()
local pureCaster = mq.TLO.Me.Class.PureCaster()
if canCast == nil or pureCaster == nil then
    log('Could not determine the current character class.')
    return
end

local hidden = {'TargetOfTargetWindow', 'ActionsWindow', 'SelectorWindow', 'CompassWindow'}
if pureCaster then hidden[#hidden + 1] = 'CombatAbilityWnd' end
if not canCast then hidden[#hidden + 1] = 'CastSpellWnd' end

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

-- The dynamic hotbar parent ignores programmatic size changes. Resize its
-- native tile layout instead; this lets EQ snap all twelve buttons to one row.
local bars = {}
local function spinnerVisible(wnd)
    local horizontal = wnd.Child('HB_HorizontalBarPageButtons').Open()
    local vertical = wnd.Child('HB_VerticalBarPageButtons').Open()
    if horizontal == nil or vertical == nil then return nil end
    return horizontal or vertical
end

local function singleRow(wnd)
    local previousX, firstY
    for i = 1, 12 do
        local button = wnd.Child('HB_Button' .. i)
        local x, y = button.X(), button.Y()
        if x == nil or y == nil or not button.Open()
            or (previousX and (x <= previousX or y ~= firstY)) then
            return false
        end
        previousX, firstY = x, y
    end
    return true
end

for i = 2, 4 do
    local name = 'HotButtonWnd' .. i
    local wnd = mq.TLO.Window(name)
    if wnd.Open() == nil then
        log('Required hotbar unavailable: ' .. name)
        return
    end
    local button = wnd.Child('HB_Button1')
    local bw, bh = button.Width(), button.Height()
    if not bw or bw <= 0 or not bh or bh <= 0
        or wnd.Child('HB_HotButtonLayout').Open() == nil or spinnerVisible(wnd) == nil then
        log('Required hotbar controls unavailable: ' .. name)
        return
    end
    -- The grid needs room for 12 buttons and their 1-pixel spacing. EQ
    -- adds its own border and snaps the parent to the actual resulting size.
    local gridWidth = 12 * bw + 20
    bars[#bars + 1] = {name = name, gridWidth = gridWidth, gridHeight = bh,
        w = gridWidth + 16, h = bh + 16}
end

local function configureBar(bar)
    local wnd = mq.TLO.Window(bar.name)
    if not wnd.Open() then
        wnd.DoOpen()
        mq.delay(150)
    end
    if spinnerVisible(wnd) then
        -- Select only the verified native hotbar menu item. /notify handles
        -- exact text matches correctly on clients where Menu.Select does not.
        if (mq.TLO.Menu.NumVisibleMenus() or 0) ~= 0 then
            log('Close the open context menu before running the layout.')
            return false
        end
        wnd.RightMouseUp()
        mq.delay(200)
        local found = false
        if mq.TLO.Menu.NumVisibleMenus() == 1 then
            for i = 0, (mq.TLO.Menu.NumItems() or 0) - 1 do
                if mq.TLO.Menu.Items(i)() == 'Show Spinner' then found = true; break end
            end
        end
        if not found then
            log('Show Spinner menu item unavailable: ' .. bar.name)
            return false
        end
        mq.cmd('/notify "Show Spinner" menuselect')
        mq.delay(250)
    end
    if spinnerVisible(wnd) ~= false then
        log('Could not hide spinner: ' .. bar.name)
        return false
    end
    wnd.Child('HB_HotButtonLayout').Move(string.format('4,4,%d,%d', bar.gridWidth, bar.gridHeight))
    mq.delay(250)
    if not singleRow(wnd) or spinnerVisible(wnd) ~= false then
        log('Client did not create a spinner-free single row: ' .. bar.name)
        return false
    end
    bar.w, bar.h = wnd.Width(), wnd.Height()
    if not bar.w or bar.w <= 0 or not bar.h or bar.h <= 0 then
        log('Invalid hotbar dimensions: ' .. bar.name)
        return false
    end
    return true
end

-- Fixed-size XML controls retain their native pixel dimensions.
-- Rectangles are {x, y, width, height}, not EQ's encoded INI positions.
local function buildLayout(w, h, profile)
    local windows = {}
    local function add(name, x, y, ww, hh)
        windows[#windows + 1] = {name = name, x = x, y = y, w = ww, h = hh}
    end

    local compact = profile == '720p'
    local barWidth, dockTop = 522, h
    for _, bar in ipairs(bars) do
        barWidth = math.max(barWidth, bar.w)
        dockTop = dockTop - bar.h
    end
    local xtarTop = dockTop - 302

    local barY = dockTop
    for _, bar in ipairs(bars) do
        add(bar.name, 0, barY, bar.w, bar.h)
        barY = barY + bar.h
    end
    -- Match Tums: the spell bar is docked above the leftmost hotbars,
    -- with extended targets immediately to its right.
    add('ExtendedTargetWnd', canCast and 155 or 0, xtarTop, 119, 300)
    if canCast then
        add('CastSpellWnd', 0, dockTop - 474, 153, 472)
    end
    if not pureCaster then
        add('CombatAbilityWnd', canCast and 276 or 121, dockTop - 142, 174, 140)
    end

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
        local hybrid = canCast and not pureCaster
        local playerY = math.min(h - 527, dockTop - (hybrid and 394 or 252))
        add('PlayerWindow', 298, playerY, 250, 250)
        if canCast then
            -- Keep the EQ button clear of the spellbar and hybrid disciplines.
            add('EQMainWnd', hybrid and 452 or 276, dockTop - 46, 44, 44)
        else
            add('EQMainWnd', 249, dockTop - 192, 44, 44)
        end
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

-- Validate predicted geometry before changing settings, and the actual
-- snapped geometry again before moving the rest of the windows.
local function validLayout(windows)
    for i, a in ipairs(windows) do
        if a.x < 0 or a.y < 0 or a.w <= 0 or a.h <= 0 or a.x + a.w > width or a.y + a.h > height
            or (a.name == 'ChatContainerWindow' and (a.w < 300 or a.h < 150)) then
            log(string.format('%s does not fit %dx%d (%s). Choose a smaller preset or enlarge the client.',
                a.name, width, height, preset))
            return false
        end
        for j = 1, i - 1 do
            local b = windows[j]
            if a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y then
                log(string.format('%s and %s overlap at %dx%d (%s). Choose a smaller preset or enlarge the client.',
                    a.name, b.name, width, height, preset))
                return false
            end
        end
    end
    return true
end

local windows = buildLayout(width, height, preset)
if not validLayout(windows) then return end
if mode ~= 'preview' then
    for _, bar in ipairs(bars) do
        if not configureBar(bar) then return end
    end
    windows = buildLayout(width, height, preset)
    if not validLayout(windows) then return end
end

log(string.format('%s layout for %dx%d%s', preset, width, height, mode == 'preview' and ' (preview)' or ''))

local applied, issues = 0, 0
local normalizedBars = {HotButtonWnd2 = true, HotButtonWnd3 = true, HotButtonWnd4 = true}
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
            if not wnd.Open() or wnd.X() ~= r.x or wnd.Y() ~= r.y or wnd.Width() ~= r.w or wnd.Height() ~= r.h
                or (normalizedBars[r.name] and (spinnerVisible(wnd) ~= false or not singleRow(wnd))) then
                log(string.format('Client adjusted %s: requested %s; actual %s,%s,%s,%s',
                    r.name, rect, tostring(wnd.X()), tostring(wnd.Y()), tostring(wnd.Width()), tostring(wnd.Height())))
                issues = issues + 1
            else
                applied = applied + 1
            end
        end
    end
end
local hiddenCount = 0
for _, name in ipairs(hidden) do
    if mode == 'preview' then
        log('Hide: ' .. name)
    else
        local wnd = mq.TLO.Window(name)
        if wnd.Open() then
            wnd.DoClose()
            mq.delay(50)
        end
        if wnd.Open() then
            log('Client refused to hide: ' .. name)
            issues = issues + 1
        else
            hiddenCount = hiddenCount + 1
        end
    end
end
if mode ~= 'preview' then
    log(string.format('Applied %d/%d windows; %d/%d hidden; %d need checking. Hotbuttons and chat tabs unchanged.',
        applied, #windows, hiddenCount, #hidden, issues))
end
