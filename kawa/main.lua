require "boiler"
require "keys"
require "vector"
require "camera"
local utf8 = require("utf8")
local DOIT = require("exportthing")

local bell = love.audio.newSource("Funk.mp3", "static")

local program =
--[[{ -- truth machine
    {base = "one", modifiers = {}, ups = {}, downs = {}, lefts = {}, rights = {}},
    {base = "input", modifiers = {"limit", "asone"}, ups = {}, downs = {}, lefts = {}, rights = {}},
    {base = "condif", modifiers = {"negate"}, ups = {}, downs = {}, lefts = {}, rights = {}},
    {base = "output", modifiers = {}, ups = {}, downs = {"flag", "astwo"}, lefts = {}, rights = {}},
    {base = "jumpback", modifiers = {}, ups = {}, downs = {}, lefts = {}, rights = {}},
    {base = "condend", modifiers = {}, ups = {}, downs = {}, lefts = {}, rights = {}},
    {base = "zero", modifiers = {}, ups = {}, downs = {}, lefts = {}, rights = {}},
    {base = "output", modifiers = {}, ups = {}, downs = {}, lefts = {}, rights = {}},
}--]]
--[[{ -- fibonacci
    {base = "zero", modifiers = {}, ups = {"pushtop"}, downs = {}, specials = {}},
    {base = "one", modifiers = {}, ups = {"pushtop"}, downs = {}, specials = {}},
    {base = "nop", modifiers = {}, ups = {"astwo", "pushbottom"}, downs = {"poptop"}, specials = {"flag"}},
    {base = "nop", modifiers = {"withtwo", "asone"}, ups = {"astwo", "pushbottom"}, downs = {"poptop"}, specials = {}},
    {base = "output", modifiers = {}, ups = {}, downs = {}, specials = {}},
    {base = "zero", modifiers = {}, ups = {}, downs = {}, specials = {}},
    {base = "one", modifiers = {}, ups = {}, downs = {}, specials = {}},
    {base = "nop", modifiers = {"asone"}, ups = {}, downs = {}, specials = {}},
    {base = "output", modifiers = {"asone"}, ups = {}, downs = {}, specials = {}},
    {base = "zero", modifiers = {}, ups = {}, downs = {}, specials = {}},
    {base = "zero", modifiers = {}, ups = {}, downs = {}, specials = {}},
    {base = "zero", modifiers = {}, ups = {}, downs = {}, specials = {}},
    {base = "one", modifiers = {}, ups = {}, downs = {}, specials = {}},
    {base = "nop", modifiers = {"asone"}, ups = {}, downs = {"sequentially"}, specials = {}},
    {base = "condif", modifiers = {"withtwo", "limit", "negate"}, ups = {}, downs = {"poptop", "astwo", "pushtop"}, specials = {}},
    {base = "jumpback", modifiers = {}, ups = {}, downs = {}, specials = {}},
    {base = "condend", modifiers = {}, ups = {}, downs = {}, specials = {}},
}--]]
--[[]]{
    {base = "input", modifiers = {}, ups = {}, downs = {}, specials = {}},
    {base = "output", modifiers = {}, ups = {}, downs = {}, specials = {}}
}
local glyphs = {
    meta = {
        endprog = {{2,7; 1,7; 1,5; 2,5;}, {1,6; 2,6;}, {2,3; 2,5; 3,3; 3,5;}, {1,1; 1,3; 2,3; 2,2; 1,1;}},
        NUL = {{1,5; 1,7; 2,5; 2,7;}, {2,5; 2,3; 3,4; 3,5;}, {1,3; 1,1; 2,1;}},
        SOH = {{2,7; 1,7; 1,6; 2,5; 1,5;}, {2,5; 3,5; 3,4; 2,3; 2,5;}, {1,3; 1,1;}, {1,2; 2,2;}, {2,3; 2,1;}},
        STX = {{2,7; 1,7; 1,6; 2,5; 1,5;}, {2,5; 3,5;}, {2.5,5; 2.5,3;}, {1,3; 2,2; 2,1;}, {1,1; 2,3;}},
        ETX = {{2,7; 1,7; 1,5; 2,5;}, {1,6; 2,6;}, {2,5; 3,5;}, {2.5,5; 2.5,3;}, {1,3; 2,2; 2,1;}, {1,1; 2,3;}},
    },
    base = {
        blank = {},
        none = {{1,4; 3,4;}, {2,5; 2,3;}},
        zero = {{3,1; 1,2; 1,6; 2,7; 3,7; 3,1;}, {1,2; 3,7;}},
        one = {1,1; 3,1; 2,1; 2,7; 1,6;},
        two = {1,6; 2,7; 3,7; 3,5; 1,2; 1,1; 3,1;},
        three = {1,6; 2,7; 3,7; 3,1; 1,2; 3,1; 3,5; 1,4;},
        four = {2,1; 3,7; 1,3; 3,3;},
        five = {1,2; 2,1; 3,3; 3,5; 1,5; 1,7; 3,7;},
        six = {3,7; 2,7; 1,6; 1,2; 3,1; 3,5; 2,5; 1,4;},
        seven = {1,7; 3,7; 2,1;},
        eight = {3,1; 3,3; 1,5; 1,6; 2,7; 3,7; 3,6; 2,4; 1,3; 1,2; 3,1;},
        nine = {1,2; 2,1; 3,3; 3,7; 2,7; 1,6; 3,5;},
        nop = {1.5,3.5; 2.5,3.5; 2.5,4.5; 1.5,4.5; 1.5,3.5;},
        input = {2,7; 2,1; 3,3;},
        output = {2,1; 2,7; 3,5;},
        condif = {1,4; 2,4; 3,7; 1,1;},
        condelse = {1,4; 3;4, 2,4; 3,7; 1,1;},
        condend = {3,4; 2,4; 3,7; 1,1;},
        jumpback = {{3,7; 1,4; 3,4;}, {3,3; 3,1;}},
        jumpforward = {{1,7; 3,4; 1,4;}, {1,3; 1,1;}},
        jumpend = {{1,7; 3,4; 1,4;}, {3,3; 3,1;}}
    },
    modifier = {
        withtwo = {
            blank = {1,7; 1,1;},
            input = {1,7; 1,1;},
            output = {1,7; 1,1;},
            nop = {1,5; 1,3;},
            condif = {1,5; 1,3;}
        },
        limit = {
            blank = {1,7; 3,7;},
            input = {1,7; 3,7;},
            output = {1,7; 3,7;},
            condif = {1,7; 3,7;},
            nop = {1,5; 3,5;}
        },
        asone = {
            blank = {3,1; 3,7;},
            input = {3,4; 3,2;},
            output = {3,6; 3,4;},
            condif = {2,1; 3,4;},
            nop = {3,5; 3,3;}
        },
        negate = {
            blank = {1,1; 3,1;},
            input = {1,1; 3,1;},
            output = {1,1; 3,1;},
            condif = {1,1; 3,1;},
            nop = {1,3; 3,3;}
        }
    },
    diaud = {
        blank = {top = 1},
        none = {top = 2, {1,1.5; 3,1.5;}, {2,2; 2,1;}},
        sequentially = {top = 2, {2,1; 1,2; 3,2;}},
        pushtop = {top = 2, {1,1; 2,2; 3,1;}},
        pushbottom = {top = 2, {1,1; 1,2; 3,2; 3,1;}},
        poptop = {top = 2, {1,2; 2,1; 3,2;}},
        popbottom = {top = 2, {1,2; 1,1; 3,1; 3,2;}},
        astwo = {top = 1, {1,1; 1.6667,1;}, {2.3333,1; 3,1;}},
        discard = {top = 2, {1,1; 2,2; 2,1; 3,2;}},
        swap = {top = 2, {2,1; 2.5,1.5; 2,2; 1.5,1.5; 2,1;}}
    },
    special = {
        none = {top = 2, {1,1.5; 3,1.5;}, {2,2; 2,1;}},
        flag1 = {top = 2, {1,2; 3,2;}, {2,2; 2,1;}},
        flag2 = {top = 2, {1,2; 3,2;}, {1.5,2; 1.5,1;}, {2.5,2; 2.5,1;}},
        flag3 = {top = 2, {1,2; 3,2;}, {1,2; 1,1;}, {2,2; 2,1;}, {3,2; 3,1;}},
        flag4 = {top = 2, {1,1; 3,1;}, {2,2; 2,1;}},
        flag5 = {top = 2, {1,1; 3,1;}, {1.5,2; 1.5,1;}, {2.5,2; 2.5,1;}},
        flag6 = {top = 2, {1,1; 3,1;}, {1,2; 1,1;}, {2,2; 2,1;}, {3,2; 3,1;}},
        flag7 = {top = 2, {1,2; 3,2;}, {1,1; 3,1;}, {2,2; 2,1;}},
        flag8 = {top = 2, {1,2; 3,2;}, {1,1; 3,1;}, {1.5,2; 1.5,1;}, {2.5,2; 2.5,1;}},
        flag9 = {top = 2, {1,2; 3,2;}, {1,1; 3,1;}, {1,2; 1,1;}, {2,2; 2,1;}, {3,2; 3,1;}},
    }
}
for i=1, 8 do
    table.insert(glyphs.base.blank, {
        math.cos(i/4*math.pi)*0.75 + 1.95,
        math.sin(i/4*math.pi)*0.75 + 4,
        math.cos(i/4*math.pi)*0.75 + 2.05,
        math.sin(i/4*math.pi)*0.75 + 4
    })
    table.insert(glyphs.diaud.blank, {
        math.cos(i/4*math.pi)*0.5 + 1.95,
        math.sin(i/4*math.pi)*0.5 + 1,
        math.cos(i/4*math.pi)*0.5 + 2.05,
        math.sin(i/4*math.pi)*0.5 + 1
    })
end
-- reverse the shape
function reversify(set) -- irrepairable damage! muahaha!
    for i=#set-1, 1, -2 do
         table.insert(set, set[i])
         table.insert(set, set[i+1])
    end
    return set
end

for i,v in pairs(glyphs.meta) do
    if type(v[1]) == "number" then reversify(v)
    else for _,b in ipairs(v) do   reversify(b)
    end end
end
for i,v in pairs(glyphs.base) do
    if type(v[1]) == "number" then reversify(v)
    else for _,b in ipairs(v) do   reversify(b)
    end end
end
for i,v in pairs(glyphs.diaud) do
    if type(v[1]) == "number" then reversify(v)
    else for _,b in ipairs(v) do   reversify(b)
    end end
end
for i,v in pairs(glyphs.special) do
    if type(v[1]) == "number" then reversify(v)
    else for _,b in ipairs(v) do   reversify(b)
    end end
end
for i,v in pairs(glyphs.modifier) do
    for o,b in pairs(v) do 
        if type(b[1]) == "number" then reversify(b)
        else for _,n in ipairs(b) do   reversify(n)
        end end
    end
end

local t, ldt, f = 0, 0, 0
local charfocus = 1
local subcfocus = 0
local zoom = 30

local running = false
local cin = love.thread.getChannel("in")
local cout = love.thread.getChannel("out")
local cplease = love.thread.getChannel("please")
local cstep = love.thread.getChannel("step")
local cdebug = love.thread.getChannel("debug")
local cstack = love.thread.getChannel("stack")
local ckill = love.thread.getChannel("kill")
local cping = love.thread.getChannel("ping")
local cdmove = love.thread.getChannel("dmove")
local interpreter = love.thread.newThread("interp.lua")

window:refresh()
local canvas = love.graphics.newCanvas(window.width - 0, window.height)
local canvas2 = love.graphics.newCanvas(window.width, 200)
function love.resize()
    window:refresh()
    canvas = love.graphics.newCanvas(window.width - 0, window.height - (running and 200 or 0))
    canvas2 = love.graphics.newCanvas(window.width, 200)
end

local candidates = {}
local candfocus = 1
local input = ""
local istart = 1
local iend = 1
local expomode = 0
function candidatify(set, condition)
    condition = condition or function() return true end
    for i,v in pairs(set) do
        if pcall(function() assert(i:match(input)) end) and i ~= "none" and condition(i, v) then
            table.insert(candidates, {name = i, glyph = v, set = set})
        end
    end
    table.sort(candidates, function(a, b)
        local astart, bstart = a.name:match("()"..input), b.name:match("()"..input)
        local alen,   blen   = #a.name, #b.name
        local gtstart, gtlen, gtname = astart <  bstart, alen <  blen, a.name < b.name
        local eqstart, eqlen         = astart == bstart, alen == blen
        
        return gtstart or (eqstart and gtlen) or (eqstart and eqlen and gtname)
    end)
end
function love.textinput(t)
    if not running and expomode == 0 then
        input = input..t:gsub("[^a-zA-Z0-9.]", ""):lower()
        candidates = {}
        candfocus = 1
        if subcfocus == 0 then
            local char = (program[charfocus] or {name = "none"})
            candidatify(glyphs.base)
            candidatify(glyphs.special)
            candidatify(glyphs.modifier, function(i, v)
                return v[char.base] ~= nil
            end)
        else
            candidatify(glyphs.diaud)
        end
    elseif not running and expomode > 0 then
        input = input..t:gsub("[^0-9]", ""):lower()
        input = tostring(math.clamp(tonumber(input) or 0, 0, 1000))
    elseif istart == iend then
        local ast = utf8.offset(input, istart)
        input = input:sub(0, ast - 1)..t..input:sub(ast)
        istart = istart + 1
        iend = istart
    else
        local ast, aen = utf8.offset(input, math.min(istart, iend)), utf8.offset(input, math.max(istart, iend))
        input = input:sub(0, ast - 1)..t..input:sub(aen)
        istart = math.min(istart, iend) + 1
        iend = istart
    end
end

local cmd   = false
local alt   = false
local shift = false
function love.update(dt)
    window:refresh()
    mouse:refresh()
    keyboard:refresh()
    
    t = t + dt
    ldt = dt
    f = f + 1

    cmd   = keyboard.lgui  .pressed or keyboard.rgui  .pressed
         or keyboard.lctrl .pressed or keyboard.rctrl .pressed
    alt   = keyboard.lalt  .pressed or keyboard.ralt  .pressed
    shift = keyboard.lshift.pressed or keyboard.rshift.pressed

    if not running then
        if keyboard.left .threshold and input == "" then charfocus = charfocus - (cmd and math.huge or 1) end
        if keyboard.right.threshold and input == "" then charfocus = charfocus + (cmd and math.huge or 1) end
        if keyboard.down .threshold and input == "" then subcfocus = subcfocus - (cmd and math.huge or 1) end
        if keyboard.up   .threshold and input == "" then subcfocus = subcfocus + (cmd and math.huge or 1) end
        
        charfocus = math.clamp(charfocus, 0, #program + 1)
        local char = program[charfocus]
        subcfocus = math.clamp(subcfocus, -#(char or {downs = {}}).downs - 1, #(char or {ups = {}}).ups + 1)
        if keyboard.backspace.threshold and input ~= "" then
            input = input:sub(1, utf8.offset(input, -1) - 1)
            love.textinput("")
        elseif keyboard.backspace.threshold and input == "" then
            if not char then charfocus = math.max(charfocus - 1, 0)
            elseif char and subcfocus == 0 then
                if char.base == "none" or cmd then
                    table.remove(program, charfocus)
                    charfocus = charfocus - 1
                else
                    char.base = "none"
                    char.modifiers = {}
                end
            elseif char and subcfocus < 0 then
                local actual = #char.downs + subcfocus + 1
                local subchar = char.downs[actual]
                if subchar == "none" or cmd then
                    table.remove(char.downs, actual)
                    subcfocus = subcfocus + 1
                else
                    char.downs[actual] = "none"
                end
            elseif char and subcfocus > 0 or cmd then
                local subchar = char.ups[subcfocus]
                if subchar == "none" then
                    table.remove(char.ups, subcfocus)
                    subcfocus = subcfocus - 1
                else
                    char.ups[subcfocus] = "none"
                end
            end
        end
        if keyboard["return"].clicked and input ~= "" and #candidates > 0  and expomode == 0 then
            if charfocus == 0 then
                charfocus = 1
                table.insert(program, 1, {base = "none", modifiers = {}, ups = {}, downs = {}, specials = {}})
                char = program[1]
            elseif charfocus == #program + 1 then
                charfocus = charfocus + 2
                table.insert(program, {base = "none", modifiers = {}, ups = {}, downs = {}, specials = {}})
                char = program[#program]
            end
            local candidate = candidates[1]
            if candidate.set == glyphs.base then
                char.base = candidate.name
            elseif candidate.set == glyphs.modifier then
                local set = false
                for i,v in ipairs(char.modifiers) do
                    if v == candidate.name then
                        set = true
                        table.remove(char.modifiers, i)
                        break
                    end
                end
                if not set then
                    table.insert(char.modifiers, candidate.name)
                end
            elseif candidate.set == glyphs.special then
                local set = false
                for i,v in ipairs(char.specials) do
                    if v == candidate.name then
                        set = true
                        table.remove(char.specials, i)
                        break
                    end
                end
                if not set then
                    table.insert(char.specials, candidate.name)
                end
            elseif candidate.set == glyphs.diaud and subcfocus > 0 then
                local off = 0
                if subcfocus > #char.ups then subcfocus = subcfocus + 1; off = -1 end
                char.ups[subcfocus + off] = candidate.name
            elseif candidate.set == glyphs.diaud and subcfocus < 0 then
                local off = 0
                if -subcfocus > #char.downs then
                    table.insert(char.downs, 1, "none")
                    subcfocus = subcfocus - 1
                    off = 1
                end
                local actual = #char.downs + subcfocus + 1 + off
                char.downs[actual] = candidate.name
            end
        end
        if cmd and keyboard.i.threshold and expomode == 0 and input == "" then
            if subcfocus == 0 then
                charfocus = charfocus + 1
                table.insert(program, charfocus, {base = "none", modifiers = {}, ups = {}, downs = {}, specials = {}})
            elseif subcfocus > 0 then
                subcfocus = subcfocus + 1
                table.insert(char.ups, subcfocus, "none")
            elseif subcfocus < 0 then
                local actual = math.max(#char.downs + subcfocus, 0) + 1
                subcfocus = subcfocus - 1
                table.insert(char.downs, actual, "none")
            end
        end
        if (keyboard["return"].threshold or keyboard.escape.clicked) and expomode == 0 then
            if not keyboard["return"].threshold or input ~= "" then goto nothanks end
            if charfocus == 0 then
                charfocus = 1
                table.insert(program, 1, {base = "none", modifiers = {}, ups = {}, downs = {}, specials = {}})
                char = program[1]
            elseif charfocus == #program + 1 then
                charfocus = charfocus + 1
                table.insert(program, {base = "none", modifiers = {}, ups = {}, downs = {}, specials = {}})
                char = program[#program]
            elseif subcfocus > #char.ups then
                subcfocus = subcfocus + 1
                table.insert(char.ups, "none")
            elseif -subcfocus > #char.downs then
                subcfocus = subcfocus - 1
                table.insert(char.downs, "none")
            end
            ::nothanks::
            input = ""
            candidates = {}
        end

        if cmd and keyboard.r.clicked and input == "" then
            running = true
            interpreter:start(program, shift and true or false)
            canvas = love.graphics.newCanvas(window.width, window.height - 200)
        end

        if cmd and keyboard.c.clicked and input == "" and expomode == 0 then
            local out = ""
            for _,v in ipairs(program) do
                out = out..v.base
                    ..";"..table.concat(v.modifiers, ",")
                    ..";"..table.concat(v.ups, ",")
                    ..";"..table.concat(v.downs, ",")
                    ..";"..table.concat(v.specials, ",").."\n"
            end
            love.system.setClipboardText(out)
        end
        if cmd and keyboard.v.clicked and input == "" and expomode == 0 then
            local newprog = "\n"..love.system.getClipboardText():trim()
            if newprog:match("[^a-z0-9,;\n]") then goto dontdothat end
            program = {}
            for thing in newprog:gmatch("\n([^\n]+)") do
                local things = thing:split(";")
                table.insert(program, {
                    base = things[1] or "",
                    modifiers = (things[2] or ""):split(",", true),
                    ups = (things[3] or ""):split(",", true),
                    downs = (things[4] or ""):split(",", true),
                    specials = (things[5] or ""):split(",", true)
                })
            end
        end
        ::dontdothat::
    else
        if keyboard.escape.clicked then
            running = false
            input = ""
            istart = 1
            iend = 0
            cin:push("")
            ckill:push(true)
            cdmove:pop()
            canvas = love.graphics.newCanvas(window.width, window.height)
        end
        if cmd and keyboard.x.clicked then
            cin:push("")
            input = ""
            istart = 1
            iend = 0
            ckill:push(true)
            cdmove:pop()
            canvas = love.graphics.newCanvas(window.width, window.height)
        end

        local state = cplease:peek()

        if state then
            if keyboard.left .threshold then istart = istart - (cmd and math.huge or 1); iend = shift and iend or 0 end
            if keyboard.right.threshold then istart = istart + (cmd and math.huge or 1); iend = shift and iend or 0 end
            if keyboard.down .threshold then istart = istart - (cmd and math.huge or 1); iend = shift and iend or 0 end
            if keyboard.up   .threshold then istart = istart + (cmd and math.huge or 1); iend = shift and iend or 0 end
            istart = math.clamp(istart, 1, utf8.len(input) + 1)
            iend = (iend == 0 and istart or iend)
            
            if keyboard.backspace.threshold and istart == iend then
                local asb = utf8.offset(input, istart - 1)
                local ast = utf8.offset(input, istart)
                input = input:sub(0, asb - 1)..input:sub(istart)
                istart = istart - 1
                iend = istart
            elseif keyboard.backspace.threshold then
                local ast, aen = utf8.offset(input, math.min(istart, iend)), utf8.offset(input, math.max(istart, iend))
                input = input:sub(0, ast - 1)..input:sub(aen)
                istart = math.min(istart, iend)
                iend = istart
            end
            if keyboard["return"].clicked then
                cin:push(input)
                input = ""
                istart = 1
                iend = 0
            end
            if cmd and keyboard.v.threshold and istart == iend then
                local ast = utf8.offset(input, istart)
                input = input:sub(0, ast - 1)..love.system.getClipboardText()..input:sub(ast)
                istart = istart + utf8.len(love.system.getClipboardText())
                iend = istart
            elseif cmd and keyboard.v.threshold then
                local ast, aen = utf8.offset(input, math.min(istart, iend)), utf8.offset(input, math.max(istart, iend))
                input = input:sub(0, ast - 1)..love.system.getClipboardText()..input:sub(aen)
                istart = math.min(istart, iend) + utf8.len(love.system.getClipboardText())
                iend = istart
            end
            if cmd and keyboard.c.threshold and istart ~= iend then
                local ast, aen = utf8.offset(input, math.min(istart, iend)), utf8.offset(input, math.max(istart, iend))
                love.system.setClipboardText(input:sub(at, aen - 1))
            end
        else
            input = ""
            istart = 1
            iend = 0
        end
    end
    if cping:pop() then
        bell:stop()
        bell:play()
    end
end

function love.wheelmoved(x, y)
    if mouse.x >= 300 then
        zoom = math.clamp(zoom + y, 1, 300)
    elseif cmd then
        consscale = math.clamp(consscale + (y/100), 0.1, 1)
    else
    end
end

function drawglyph(glyph, where)
    if not glyph then return end
    if type(glyph[1]) == "number" then love.graphics.polygon("line", CamPoly(glyph, where))
    else for _,b in ipairs(glyph) do   love.graphics.polygon("line", CamPoly(b,     where))
    end end
end

local radial = love.graphics.newShader([[
    uniform vec2 screen;

    vec4 effect(vec4 color, Image tex, vec2 tpos, vec2 spos) {
        vec2 diff = ((spos - screen)*(spos - screen));
        float ratio = sqrt(screen.x*screen.x + screen.y*screen.y);
        float dist = 0.5 + max(1 - sqrt(diff.x + diff.y) / ratio, 0) / 2;
        return vec4(dist, dist, dist, 1);
    }
]])

local nbsp = "\u{00A0}"
local space = "\u{0020}"
local block = "\u{2588}"
local firacode = love.graphics.newFont("FiraCodeNerdFont.ttf", 16, "light", 4)

local text = love.graphics.newText(firacode)
local stackdata = {stream = {}, boat = {}}
text:set("|")
local bw, bh = text:getWidth(), text:getHeight()

local ccnames = {
    [0] = "NUL", "SOH", "STX", "ETX", "EOT", "ENQ",
          "ACK", "BEL", "BS",  "TAB", "LF",  "VT",
          "FF",  "CR",  "SO",  "SI",  "DLE", "DC1",
          "DC2", "DC3", "DC4", "NAK", "SYN", "ETB",
          "CAN", "EM",  "SUB", "ESC", "FS",  "GS",
          "RS",  "US"
}

local gw, gb = 100, 0
function love.draw()
    local flashycolor = math.sin(t*math.pi/1.5) * 0.1 + 0.3

    window:refresh()
    window.height = window.height - (running and 200 or 0)
    love.graphics.setCanvas(canvas)
    love.graphics.setShader(radial)
    radial:send("screen", {window.width / 2, window.height / 2})
    love.graphics.rectangle("fill", 0, 0, window.width, window.height)
    love.graphics.setShader()

    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(12 * camera.z / 100)
    love.graphics.setLineJoin("none")

    local x = 0
    local exppos = camera.position
    if charfocus == 0 and not running then
        love.graphics.setColor(0, 0, 0, flashycolor)
        love.graphics.polygon("line", CamPoly({0.5,0.5;3.5,0.5;3.5,7.5;0.5,7.5;}, Vector2.new(-3, 0)))
        drawglyph(glyphs.base.none, Vector2.new(-3, 0))
        love.graphics.setColor(0, 0, 0)
        exppos = Vector2.new(-1, 4)
        subcfocus = 0
    end

    local prog = tonumber(cstep:peek())
    for i,v in ipairs(program) do
        local pos = Vector2.new(x, 0)
        if i == charfocus and subcfocus == 0 and not running then
            exppos = Vector2.new(x + 2, 4)
            love.graphics.setColor(0, 0, 0, flashycolor)
            love.graphics.polygon("line", CamPoly({0.5,0.5;3.5,0.5;3.5,7.5;0.5,7.5;}, pos))
        end
        if running and prog == i then
            exppos = Vector2.new(x + 2, 4)
            love.graphics.setColor(0.5 * flashycolor, 1, 1 - flashycolor, flashycolor)
            love.graphics.polygon("line", CamPoly({0.5,0.5;3.5,0.5;3.5,7.5;0.5,7.5;}, pos))
            love.graphics.setColor(0.5 * flashycolor, 1, 1 - flashycolor, flashycolor * 0.9)
            love.graphics.polygon("fill", CamPoly({0.5,0.5;3.5,0.5;3.5,7.5;0.5,7.5;}, pos))
        end
        love.graphics.setColor(0, 0, 0)
        if v.base == "none" then love.graphics.setColor(0, 0, 0, flashycolor) end
        drawglyph(glyphs.base[v.base] or glyphs.base.none, pos)

        for _,b in ipairs(v.modifiers) do
            drawglyph((glyphs.modifier[b] or {})[v.base], pos)
        end

        local off = Vector2.new(0, 7)
        for j=1, #v.ups, 1 do
            local mod = v.ups[j]
            local glyph = glyphs.diaud[mod] or glyphs.diaud.none
            local up = (glyph and glyph.top or 1) - 1
            if i == charfocus and j == subcfocus then
                exppos = pos + off + Vector2.new(2, up + 1)
                love.graphics.setColor(0, 0, 0, flashycolor)
                love.graphics.polygon("line", CamPoly({0.5,0.5;3.5,0.5;3.5,1.5+up;0.5,1.5+up;}, pos + off))
            end
            love.graphics.setColor(0, 0, 0)
            if glyph == glyphs.diaud.none then love.graphics.setColor(0, 0, 0, flashycolor) end
            drawglyph(glyph, pos + off)
            off = off + Vector2.new(0, up + 1)
        end
        if i == charfocus and subcfocus == #v.ups + 1 and not running then
            local up = glyphs.diaud.none.top - 1
            exppos = pos + off + Vector2.new(2, up + 1)
            love.graphics.setColor(0, 0, 0, flashycolor)
            love.graphics.polygon("line", CamPoly({0.5,0.5;3.5,0.5;3.5,1.5+up;0.5,1.5+up;}, pos + off))
            drawglyph(glyphs.diaud.none, pos + off)
        end
        off = Vector2.new(0, 0)
        for j=#v.downs, 1, -1 do
            local actual = #v.downs + subcfocus + 1
            local mod = v.downs[j]
            local glyph = glyphs.diaud[mod] or glyphs.diaud.none
            local down = (glyph and glyph.top or 0) - 1
            if i == charfocus and j == actual then
                exppos = pos + off + Vector2.new(2, down)
                love.graphics.setColor(0, 0, 0, flashycolor)
                love.graphics.polygon("line", CamPoly({0.5,0.5;3.5,0.5;3.5,1.5+down;0.5,1.5+down;}, pos + off - Vector2.new(0, down + 1)))
            end
            love.graphics.setColor(0, 0, 0)
            if glyph == glyphs.diaud.none then love.graphics.setColor(0, 0, 0, flashycolor) end
            off = off - Vector2.new(0, down + 1)
            drawglyph(glyph, pos + off)
        end
        if i == charfocus and subcfocus == -#v.downs - 1 and not running then
            local down = glyphs.diaud.none.top - 1
            exppos = pos + off + Vector2.new(2, down)
            love.graphics.setColor(0, 0, 0, flashycolor)
            love.graphics.polygon("line", CamPoly({0.5,0.5;3.5,0.5;3.5,1.5+down;0.5,1.5+down;}, pos + off - Vector2.new(0, down + 1)))
            off = off - Vector2.new(0, down + 1)
            drawglyph(glyphs.diaud.none, pos + off)
        end
        for j=#v.specials, 1, -1 do
            local mod = v.specials[j]
            local glyph = glyphs.special[mod] or glyphs.special.none
            local down = (glyph and glyph.top or 0) - 1
            love.graphics.setColor(0, 0, 0)
            if glyph == glyphs.special.none then love.graphics.setColor(0, 0, 0, flashycolor) end
            off = off - Vector2.new(0, down + 1)
            drawglyph(glyph, pos + off)
        end

        x = x + 3
    end

    if charfocus == #program + 1 and not running then
        love.graphics.setColor(0, 0, 0, math.sin(t*math.pi/1.5) * 0.1 + 0.3)
        love.graphics.polygon("line", CamPoly({0.5,0.5;3.5,0.5;3.5,7.5;0.5,7.5;}, Vector2.new(x, 0)))
        drawglyph(glyphs.base.none, Vector2.new(x, 0))
        love.graphics.setColor(0, 0, 0)
        exppos = Vector2.new(x + 2, 4)
        subcfocus = 0
    end
    if prog == #program + 1 and running then
        love.graphics.setColor(0.5 * flashycolor, 1, 1 - flashycolor, flashycolor)
        love.graphics.polygon("line", CamPoly({0.5,0.5;3.5,0.5;3.5,7.5;0.5,7.5;}, Vector2.new(x, 0)))
        love.graphics.setColor(0.5 * flashycolor, 1, 1 - flashycolor, flashycolor * 0.9)
        love.graphics.polygon("fill", CamPoly({0.5,0.5;3.5,0.5;3.5,7.5;0.5,7.5;}, Vector2.new(x, 0)))
        drawglyph(glyphs.meta.endprog, Vector2.new(x, 0))
        love.graphics.setColor(0, 0, 0)
        exppos = Vector2.new(x + 2, 4)
        subcfocus = 0
    end

    camera.position = camera.position + (exppos - camera.position) / 5
    camera.z = camera.z + (zoom - camera.z) / 5

    if input ~= "" and not running and expomode == 0 then
        local height = 16*1.5+16
        local px, py = CamPoint((exppos - Vector2.new(2, 4)):unpack())
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("fill", px, py, 300, height)
        love.graphics.rectangle("line", px, py, 300, height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(input, px + 8, py + 8, 0, 1.5, 1.5)

        -- lololol cheating here
        local oz = camera.z
        camera.z = (16*1.5+12)/7
        for i,v in ipairs(candidates) do
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", px, py + height*i, 275, height)
            love.graphics.rectangle("line", px, py + height*i, 275, height)
            love.graphics.setColor(1, 1, 1)
            drawglyph(v.glyph.nop or v.glyph, CamUI(px + 8, py + 20 + (16*1.5) + height*i))
            local from, to = v.name:match("()"..input.."()")
            love.graphics.print({
                {1, 1, 1}, v.name:sub(1, from - 1),
                {0.75, 0.8, 1}, v.name:sub(from, to - 1),
                {1, 1, 1}, v.name:sub(to)
            }, px + 36, py + 8 + height*i, 0, 1.5, 1.5)
        end
        camera.z = oz
    end

    if running then
        local b = window.height - 40
        love.graphics.polygon("line", reversify{10,b;10,b+30;120,b+30;120,b;})
        love.graphics.polygon("line", reversify{130,b;130,b+30;240,b+30;240,b;})
        stackdata = cstack:peek() or stackdata
        local b = window.height - 40
        for i=1, math.min(#stackdata.stream, 11) do
            local v = stackdata.stream[i]
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.polygon("line", {20,b;20,b+20;110,b+20;110,b;})
            love.graphics.polygon("fill", {20,b;20,b+20;110,b+20;110,b;})
            love.graphics.setColor(1, 1, 1)
            local char
            pcall(function() char = utf8.char(v) end)
            text:set(tostring(v).." "..(ccnames[v] or ("'"..(char or "???").."'") or "???"))
            if i == 11 and #stackdata.stream > 11 then text:set("+"..(#stackdata.stream - 11).."...") end
            love.graphics.draw(text, 65, b+10, 0, 0.8, 0.8, text:getWidth() / 2, text:getHeight() / 2)
            b = b - 30
        end
        local b = window.height - 40
        for i=1, math.min(#stackdata.boat, 11) do
            local v = stackdata.boat[i]
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.polygon("line", {140,b;140,b+20;230,b+20;230,b;})
            love.graphics.polygon("fill", {140,b;140,b+20;230,b+20;230,b;})
            love.graphics.setColor(1, 1, 1)
            local char
            pcall(function() char = utf8.char(v) end)
            text:set(tostring(v).." "..(ccnames[v] or ("'"..(char or "???").."'") or "???"))
            if i == 11 and #stackdata.boat > 11 then text:set("+"..(#stackdata.boat - 11).."...") end
            love.graphics.draw(text, 185, b+10, 0, 0.8, 0.8, text:getWidth() / 2, text:getHeight() / 2)
            b = b - 30
        end

        if cdmove:peek() then
            love.graphics.setColor(0, 0, 0, flashycolor)
            text:set("DEBUG - Press space to continue")
            love.graphics.draw(text, window.width - text:getWidth() - 20, window.height - text:getHeight() - 20)

            if keyboard.space.threshold then cdmove:pop() end
        end
    end

    if cmd and keyboard.s.clicked and expomode == 0 and input == "" and not running then
        expomode = 1
        input = "0"
    end
    if expomode > 0 then
        local w = window.width / 2
        local h = window.height / 2
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", w - 150, h - 25, 300, 50)
        love.graphics.rectangle("line", w - 150, h - 25, 300, 50)
        love.graphics.setColor(1, 1, 1)
        text:set(input)
        love.graphics.draw(text, w - 150 + 10, h, 0, 1.5, 1.5, 0, text:getHeight()/2)
        if expomode == 1 then
            text:set("Glyph width in pixels (default = 30)")
            if keyboard["return"].clicked then
                gw = tonumber(input)
                input = "0"
                expomode = 2
            end
        elseif expomode == 2 then
            text:set("Max line length (0 = ∞)")
            if keyboard["return"].clicked then
                gb = tonumber(input)
                input = ""
                expomode = 0
                DOIT(program, glyphs, gw, gb)
            end
        end
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.draw(text, w - 150 + 10, h - 24, 0, 1, 1, 0, text:getHeight())
        love.graphics.draw(text, w - 150 + 10, h - 26, 0, 1, 1, 0, text:getHeight())
        love.graphics.draw(text, w - 150 + 11, h - 25, 0, 1, 1, 0, text:getHeight())
        love.graphics.draw(text, w - 150 +  9, h - 25, 0, 1, 1, 0, text:getHeight())
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(text, w - 150 + 10, h - 25, 0, 1, 1, 0, text:getHeight())
        if keyboard.escape.clicked then expomode = 0; input = "" end
    end

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvas, 0, 0)

    window:refresh()
    if running then
        --love.graphics.print(tostring(cin:peek()).."\n"..tostring(cout:peek()).."\n"..tostring(cplease:peek()).."\n"..tostring(ckill:peek()).."\n"..tostring(cstep:peek()).."\n"..tostring(cdebug:peek()).."\n"..tostring(cstack:peek()))

        local nio = cout:peek()
        if not nio then goto endconsole end
        
        do
            love.graphics.setCanvas(canvas2)
            love.graphics.clear()
            
            --[[
            nio = nio..input.."-"
            local len = utf8.len(nio)
            local max = math.floor(window.width / bw)
            local may = math.floor(200 / bh)
            local total = math.max(math.floor(len / max) - may, 0) * max
            nio = nio:sub(utf8.offset(nio, -total) or 1)
            -- assuming all characters are a single glyph long... looking at you tab
            nio = nio:sub(1, -#input - 2)]]
            local inptxt = input
            --love.graphics.print(total)

            local ast, aen = utf8.offset(input, math.min(istart, iend)), utf8.offset(input, math.max(istart, iend))
            text:setf({
                {1, 1, 1}, nio:gsub(space, nbsp),
                {1, 1, 1}, (inptxt:gsub(space, nbsp))
            }, window.width / 1.1, "left")
            local off = -math.max((text:getHeight() * 1.1) - 200, 0)
            love.graphics.draw(text, 0, off, 0, 1.1, 1.1)
            --love.graphics.print(istart..", "..iend, 100, 0)

            if not cplease:peek() then goto endconsole end
            if ast == aen then love.graphics.setColor(1, 1, 1, math.round(math.sin(t*math.pi*1.8)/2+0.5)) end
            text:setf({
                {1, 1, 1, 0}, nio:gsub(space, nbsp),
                {1, 1, 1, 0}, (inptxt:sub(1, ast - 1):gsub(space, nbsp)),
                {1, 1, 1, 1}, (block:rep(math.max(math.abs(ast - aen), 1)))
            }, window.width / 1.1, "left")
            love.graphics.draw(text, 0, off, 0, 1.1, 1.1)
            text:setf({
                {1, 1, 1, 0}, nio:gsub(space, nbsp),
                {1, 1, 1, 0}, (inptxt:sub(1, ast - 1):gsub(space, nbsp)),
                {0, 0, 0, 1}, (inptxt:sub(ast, aen):gsub(space, nbsp))
            }, window.width / 1.1, "left")
            love.graphics.draw(text, 0, off, 0, 1.1, 1.1)
        end

        ::endconsole::
        love.graphics.setCanvas()
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(canvas2, 0, window.height - 200)
    end

    love.graphics.setCanvas()
end