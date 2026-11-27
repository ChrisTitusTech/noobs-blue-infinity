-- Run from the repository root with Lua or LuaJIT.
local script = 'macroquest/lua/noobs_layout.lua'

local function run(width, height, preset, mode, options)
    options = options or {}
    local state, messages = {}, {}
    local originalPrint = print
    print = function(message) messages[#messages + 1] = message end
    package.loaded.mq = {
        TLO = {
            EverQuest = {
                GameState = function() return options.gameState or 'INGAME' end,
                CurrentUI = function() return options.skin or 'Freq_di28889' end,
            },
            Window = function(name)
                if name == options.missing then
                    return {Open = function() return nil end, Width = function() return nil end, Height = function() return nil end}
                end
                local initial = options.initial and options.initial[name] or {}
                local r = state[name] or {open = false, w = initial.w, h = initial.h}

                return {
                    Open = function() return r.open end,
                    DoOpen = function() r.open = true; state[name] = r end,
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
                }
            end,
        },
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
        assert(output:find('Applied 14/14 windows', 1, true), output)
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
    assert(output:find('Applied 14/14 windows', 1, true), output)
    assert(windows.HotButtonWnd2.h == 101 and windows.HotButtonWnd3.y == windows.HotButtonWnd2.y + 101)
    assert(windows.HotButtonWnd4.y + windows.HotButtonWnd4.h == p[2])
end
print('Existing two-row hotbars fit all three presets and windowed sizes.')

local state, output = run(1280, 720, '720p', 'preview')
assert(next(state) == nil and output:find('preview', 1, true) and output:find('ChatContainerWindow:', 1, true))
state, output = run(1280, 720, '1440p')
assert(next(state) == nil and output:find('Choose a smaller preset or enlarge the client', 1, true))
state, output = run(1280, 720, '720p', nil, {skin = 'Default'})
assert(next(state) == nil and output:find('Load the skin first', 1, true))
state, output = run(1280, 720, '720p', nil, {missing = 'ChatContainerWindow'})
assert(output:find('Applied 13/14 windows', 1, true))
state, output = run(1280, 720, '720p', nil, {adjusted = 'PlayerWindow'})
assert(output:find('Applied 13/14 windows', 1, true))
state, output = run(1280, 720, '720p', nil, {gameState = 'CHARSELECT'})
assert(next(state) == nil and output:find('Enter the game', 1, true))
state, output = run(1280, 720, 'bogus')
assert(next(state) == nil and output:find('Usage:', 1, true))
print('Preview, invalid input, undersized client, wrong skin, missing window, and client adjustment checks passed.')
