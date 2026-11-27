-- Run from the repository root with Lua or LuaJIT.
local script = 'macroquest/lua/noobs_layout.lua'

local function run(width, height, preset, mode, options)
    options = options or {}
    local state, messages, windows = {}, {}, {}
    local menuBar = nil
    local originalPrint = print
    print = function(message) messages[#messages + 1] = message end
    package.loaded.mq = {
        TLO = {
            EverQuest = {
                GameState = function() return options.gameState or 'INGAME' end,
                CurrentUI = function() return options.skin or 'Freq_di28889' end,
            },
            Me = {Class = {
                CanCast = function() return options.class == 'caster' or options.class == 'hybrid' end,
                PureCaster = function() return options.class == 'caster' end,
            }},
            Menu = {
                NumVisibleMenus = function() return menuBar and 1 or 0 end,
                NumItems = function() return menuBar and 2 or 0 end,
                Items = function(i)
                    return function() return i == 1 and not options.noMenuItem and 'Show Spinner' or 'Window' end
                end,
            },
            Window = function(name)
                if name == options.missing then
                    return {Open = function() return nil end, Width = function() return nil end, Height = function() return nil end}
                end
                local initial = options.initial and options.initial[name] or {}
                local isBar = name:match('^HotButtonWnd[234]$') ~= nil
                local r = windows[name] or {
                    open = initial.open or false, w = initial.w, h = initial.h,
                    spinner = isBar and not initial.noSpinner,
                    singleRow = isBar and initial.singleRow or false,
                }
                windows[name] = r

                return {
                    Open = function() return r.open end,
                    DoOpen = function() r.open = true; state[name] = r end,
                    DoClose = function()
                        if name ~= options.refuseHide then r.open = false end
                        state[name] = r
                    end,
                    Move = function(rect)
                        state[name] = r
                        local x, y, w, h = rect:match('^(%d+),(%d+),(%d+),(%d+)$')
                        r.x, r.y, r.w, r.h = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
                        if name == options.adjusted then r.x = r.x + 1 end
                    end,
                    X = function() return r.x end,
                    Y = function() return r.y end,
                    Width = function() return r.w end,
                    Height = function() return r.h end,
                    RightMouseUp = function()
                        assert(isBar)
                        menuBar = name
                    end,
                    Child = function(child)
                        assert(isBar)
                        if child == 'HB_HorizontalBarPageButtons' then
                            return {Open = function() return r.spinner end}
                        elseif child == 'HB_VerticalBarPageButtons' then
                            return {Open = function() return false end}
                        elseif child == 'HB_HotButtonLayout' then
                            return {
                                Open = function() return true end,
                                Move = function(rect)
                                    state[name] = r
                                    local w, h = rect:match('^4,4,(%d+),(%d+)$')
                                    assert(w and h)
                                    if name ~= options.refuseGrid then
                                        r.w, r.h = tonumber(w) + 16, tonumber(h) + 16
                                        r.singleRow = true
                                    end
                                end,
                            }
                        end
                        local i = tonumber(child:match('^HB_Button(%d+)$'))
                        assert(i and i <= 12, child)
                        return {
                            Open = function() return true end,
                            Width = function() return 40 end,
                            Height = function() return 40 end,
                            X = function() return r.singleRow and (i - 1) * 41 or ((i - 1) % 11) * 41 end,
                            Y = function() return r.singleRow and 0 or math.floor((i - 1) / 11) * 41 end,
                        }
                    end,
                }
            end,
        },
        cmd = function(command)
            assert(command == '/notify "Show Spinner" menuselect')
            assert(menuBar)
            local r = windows[menuBar]
            r.spinner = not r.spinner
            state[menuBar] = r
            menuBar = nil
        end,
        delay = function() end,
    }
    package.loaded.ImGui = {
        GetIO = function() return {DisplaySize = {x = width, y = height}} end,
    }
    local ok, err = pcall(assert(loadfile(script)), preset, mode)
    print = originalPrint
    assert(ok, err)
    return state, table.concat(messages, '\n')
end

local profiles = {
    {2560, 1440, '1440p'},
    {2550, 1394, '1440p'},
    {1920, 1080, '1080p'},
    {1910, 1034, '1080p'},
    {1280, 720, '720p'},
    {1270, 674, '720p'},
}
for _, p in ipairs(profiles) do
    for _, preset in ipairs({p[3], 'auto'}) do
        local windows, output = run(p[1], p[2], preset)
        assert(output:find('Applied 13/13 windows', 1, true), output)
        for i = 2, 4 do
            local bar = windows['HotButtonWnd' .. i]
            assert(bar.singleRow and not bar.spinner and bar.h == 56 and bar.w == 516)
        end
        assert(windows.HotButtonWnd4.y + windows.HotButtonWnd4.h == p[2])
        assert(windows.BuffWindow.x + windows.BuffWindow.w == p[1] - 2)
        assert(windows.PlayerWindow.w == 250 and windows.PlayerWindow.h == 250)
        assert(windows.HotButtonWnd.w == 187 and windows.HotButtonWnd.h == 275)
        assert(windows.GroupWindow.h >= 270)
        for name, r in pairs(windows) do
            assert(r.open and r.x >= 0 and r.y >= 0 and r.x + r.w <= p[1] and r.y + r.h <= p[2], name)
            for other, s in pairs(windows) do
                if name ~= other then
                    assert(not (r.x < s.x + s.w and r.x + r.w > s.x and r.y < s.y + s.h and r.y + r.h > s.y),
                        name .. ' overlaps ' .. other)
                end
            end
        end
    end
    print(string.format('%dx%d: %s layout fits', p[1], p[2], p[3]))
end


-- Tums's live client refused to resize these bars from 481x101.
local twoRow = {}
for i = 2, 4 do twoRow['HotButtonWnd' .. i] = {w = 481, h = 101} end
for _, p in ipairs(profiles) do
    local windows, output = run(p[1], p[2], p[3], nil, {initial = twoRow})
    assert(output:find('Applied 13/13 windows', 1, true), output)
    for i = 2, 4 do
        local bar = windows['HotButtonWnd' .. i]
        assert(bar.h == 56 and bar.w == 516 and bar.singleRow and not bar.spinner)
    end
    assert(windows.HotButtonWnd3.y == windows.HotButtonWnd2.y + 56)
    assert(windows.HotButtonWnd4.y + windows.HotButtonWnd4.h == p[2])
end
print('Existing two-row hotbars become spinner-free single rows at all resolutions.')

local already = {}
for i = 2, 4 do already['HotButtonWnd' .. i] = {w = 516, h = 56, noSpinner = true, singleRow = true} end
local ready, result = run(1920, 1080, 'auto', nil, {initial = already, noMenuItem = true})
assert(result:find('Applied 13/13 windows', 1, true), result)
for i = 2, 4 do assert(not ready['HotButtonWnd' .. i].spinner) end
local failed, failure = run(1920, 1080, 'auto', nil, {refuseGrid = 'HotButtonWnd2'})
assert(failure:find('did not create a spinner-free single row', 1, true) and not failed.PlayerWindow)
failed, failure = run(1920, 1080, 'auto', nil, {noMenuItem = true})
assert(failure:find('Show Spinner menu item unavailable', 1, true) and not failed.PlayerWindow)
print('Already-normalized bars remain spinner-free; unavailable controls stop placement.')

local initiallyVisible = {}
local alwaysHidden = {'TargetOfTargetWindow', 'ActionsWindow', 'SelectorWindow', 'CompassWindow'}
for _, name in ipairs(alwaysHidden) do initiallyVisible[name] = {open = true} end
initiallyVisible.CombatAbilityWnd = {open = true}
initiallyVisible.CastSpellWnd = {open = true}
for _, p in ipairs(profiles) do
    for _, class in ipairs({'melee', 'caster', 'hybrid'}) do
        local windows, output = run(p[1], p[2], p[3], nil, {class = class, initial = initiallyVisible})
        local expected = class == 'hybrid' and 14 or 13
        assert(output:find(string.format('Applied %d/%d windows', expected, expected), 1, true), output)
        assert(output:find(class == 'hybrid' and '4/4 hidden; 0 need checking' or '5/5 hidden; 0 need checking', 1, true), output)
        for _, name in ipairs(alwaysHidden) do assert(windows[name] and not windows[name].open, name) end
        assert(windows.CombatAbilityWnd.open == (class ~= 'caster'))
        assert(windows.CastSpellWnd.open == (class ~= 'melee'))
        if class ~= 'melee' then
            assert(windows.CastSpellWnd.w == 153 and windows.CastSpellWnd.h == 472)
            assert(windows.CastSpellWnd.x == 0)
            assert(windows.CastSpellWnd.y + windows.CastSpellWnd.h == windows.HotButtonWnd2.y - 2)
            assert(windows.ExtendedTargetWnd.x == 155)
            assert(windows.ExtendedTargetWnd.y + windows.ExtendedTargetWnd.h == windows.HotButtonWnd2.y - 2)
        end
        for name, r in pairs(windows) do
            if r.open then
                assert(r.x >= 0 and r.y >= 0 and r.x + r.w <= p[1] and r.y + r.h <= p[2], name)
                for other, s in pairs(windows) do
                    if name ~= other and s.open then
                        assert(not (r.x < s.x + s.w and r.x + r.w > s.x and r.y < s.y + s.h and r.y + r.h > s.y),
                            name .. ' overlaps ' .. other .. ' (' .. class .. ', ' .. p[3] .. ')')
                    end
                end
            end
        end
    end
end
print('Melee, pure caster, and hybrid layouts fit all resolutions with requested windows hidden.')
local state, output = run(1280, 720, '720p', 'preview', {class = 'caster', initial = initiallyVisible})
assert(next(state) == nil and output:find('Hide: CombatAbilityWnd', 1, true) and output:find('CastSpellWnd:', 1, true))
state, output = run(1920, 1080, 'auto', nil, {class = 'caster', initial = initiallyVisible, refuseHide = 'ActionsWindow'})
assert(output:find('Client refused to hide: ActionsWindow', 1, true) and output:find('1 need checking', 1, true))
state, output = run(1280, 720, '720p', 'preview')
assert(next(state) == nil and output:find('preview', 1, true) and output:find('ChatContainerWindow:', 1, true))
state, output = run(1280, 720, '1440p')
assert(next(state) == nil and output:find('Choose a smaller preset or enlarge the client', 1, true))
state, output = run(1280, 720, '720p', nil, {skin = 'Default'})
assert(next(state) == nil and output:find('Load the skin first', 1, true))
state, output = run(1280, 720, '720p', nil, {missing = 'HotButtonWnd2'})
assert(next(state) == nil and output:find('Required hotbar unavailable', 1, true))
state, output = run(1280, 720, '720p', nil, {missing = 'ChatContainerWindow'})
assert(output:find('Applied 12/13 windows', 1, true))
state, output = run(1280, 720, '720p', nil, {adjusted = 'PlayerWindow'})
assert(output:find('Applied 12/13 windows', 1, true))
state, output = run(1280, 720, '720p', nil, {gameState = 'CHARSELECT'})
assert(next(state) == nil and output:find('Enter the game', 1, true))
state, output = run(1280, 720, 'bogus')
assert(next(state) == nil and output:find('Usage:', 1, true))
print('Preview, invalid input, undersized client, wrong skin, missing window, and client adjustment checks passed.')
