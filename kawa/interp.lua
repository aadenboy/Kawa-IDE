require "boiler"
local utf8 = require("utf8")
local cin = love.thread.getChannel("in")
local cout = love.thread.getChannel("out")
local cplease = love.thread.getChannel("please")
local cdebug = love.thread.getChannel("debug")
local cstep = love.thread.getChannel("step")
local ckill = love.thread.getChannel("kill")
local cstack = love.thread.getChannel("stack")
local cping = love.thread.getChannel("cping")
require "love.timer"


local output = ""
local program = {}
local stream = {}
local boat = {}
local globali = 1

function package()
    local a = {stream = {}, boat = {}}
    for i,v in ipairs(stream) do a.stream[i] = v end
    for i,v in ipairs(boat)   do a.boat  [i] = v end
    return a
end

local floor,insert = math.floor, table.insert
function basen(n,b) -- stolen from https://stackoverflow.com/questions/3554315/lua-base-converter
    n = floor(n)
    if not b or b == 10 then return tostring(n) end
    local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local t = {}
    local sign = ""
    if n < 0 then
        sign = "-"
    n = -n
    end
    repeat
        local d = (n % b) + 1
        n = floor(n / b)
        insert(t, 1, digits:sub(d,d))
    until n == 0
    return sign .. table.concat(t,"")
end

function jumpnext(dir, cond)
    if not cond then dir, cond = 1, dir end
    if dir == 0 then return end
    for i=globali, (dir > 0 and #program or 1), dir do
        local v = program[i]
        if cond(v) then
            globali = i
            return
        end
    end
    globali = (dir > 0 and #program or 1)
end

function stream.push(self, v)
    table.insert(self, v)
end
function stream.pop(self)
    local a = self[#self]
    table.remove(self, #self)
    return a
end
function boat.pushtop(self, v)
    table.insert(self, v)
end
function boat.poptop(self)
    local a = self[#self]
    table.remove(self, #self)
    return a
end
function boat.pushbottom(self, v)
    table.insert(self, 1, v)
end
function boat.popbottom(self)
    local a = self[1]
    table.remove(self, 1)
    return a
end

local seq = false
local diauds = {
    sequentially = function()
        seq = true
    end,
    pushtop = function()
        repeat
            boat:pushtop(stream:pop())
        until #stream == 0 or not seq
    end,
    pushbottom = function()
        repeat
            boat:pushbottom(stream:pop())
        until #stream == 0 or not seq
    end,
    poptop = function()
        repeat
            stream:push(boat:poptop())
        until #boat == 0 or not seq
    end,
    popbottom = function()
        repeat
            stream:push(boat:popbottom())
        until #boat == 0 or not seq
    end,
    astwo = function()
        local i = #stream
        repeat
            table.insert(stream, stream[i])
            i = i - 1
        until i < 1 or not seq
    end,
    discard = function()
        repeat
            stream:pop()
        until #stream == 0 or not seq
    end
}

function single(func)
    if #stream < 1 then return end
    for i=#stream, 1, -1 do
        stream[i] = func(stream[i])
        if not seq then break end
    end
end
function tuple(amt, func)
    if #stream < amt then return end
    repeat
        local args = {}
        for i=1, amt do
            args[i] = stream:pop()
        end
        stream:push(func(unpack(args)) or 0)
    until #stream < amt or not seq
end
local commands = {
    zero = function() stream:push(0) end,
    one = function() stream:push(1) end,
    two = function() stream:push(2) end,
    three = function() stream:push(3) end,
    four = function() stream:push(4) end,
    five = function() stream:push(5) end,
    six = function() stream:push(6) end,
    seven = function() stream:push(7) end,
    eight = function() stream:push(8) end,
    nine = function() stream:push(9) end,
    nop = function(m)
        local _ = 0
        local type = (m.withtwo and 1 or 0)
                   + (m.limit   and 2 or 0)
                   + (m.asone   and 4 or 0)
                   + (m.negate  and 8 or 0)
        if     type == 1+_+_+_ then -- with two       - concat
            tuple(2, function(a, b)
                return tonumber(a..b)
            end)
        elseif type == _+2+_+_ then -- limit          - abs
            single(function(a)
                return math.abs(a)
            end)
        elseif type == _+_+4+_ then -- as one         - [0, 1]
            single(function(a)
                return math.clamp(a, 0, 1)
            end)
        elseif type == _+_+_+8 then -- negate         - mult -1
            single(function(a)
                return -a
            end)
        elseif type == 1+2+_+_ then -- wt, limit      - modulo 
            tuple(2, function(a, b)
                return a % b
            end)
        elseif type == 1+_+4+_ then -- wt, asone      - add
            tuple(2, function(a, b)
                return a + b
            end)
        elseif type == 1+_+_+8 then -- wt, negate     - split
            tuple(2, function(a, b)
                a = a:gsub("[^0-9]", "")
                b = math.round(b)
                return tonumber(b > 0 and a:sub(1, b) or a:sub(-b, -1))
            end)
        elseif type == _+2+4+_ then -- lim, asone     - first digit
            single(function(a)
                return tonumber(a:gsub("[^0-9]", ""):sub(1, 1))
            end)
        elseif type == _+2+_+8 then -- lim, negate    - round
            single(function(a)
                return math.round(a)
            end)
        elseif type == _+_+4+8 then -- asone, negate  - sign
            single(function(a)
                return math.sign(a, 0)
            end)
        elseif type == 1+2+4+_ then -- wt, lm, asone  - max
            tuple(2, function(a, b)
                return math.max(a, b)
            end)
        elseif type == 1+2+_+8 then -- wt, lm, negate - divide
            tuple(2, function(a, b)
                return a / b
            end)
        elseif type == 1+_+4+8 then -- wt, ao, negate - subtract
            tuple(2, function(a, b)
                return a - b
            end)
        elseif type == _+2+4+8 then -- lm, ao, negate - last digit
            single(function(a)
                return tonumber(a:gsub("[^0-9]", ""):sub(-1))
            end)
        elseif type == 1+2+4+8 then -- wt, lm, ao, nt - min
            tuple(2, function(a, b)
                return math.min(a, b)
            end)
        end
    end,
    input = function(m)
        -- with two - if limit, use two as [min, max]
        -- limit - limit characters
        -- as one - parse as number (limit is number range)
        -- negate - inverse limit to exclude rather than include
        -- sequentially - use all stream values as valid characters
        -- reprompts if invalid based on rules given

        local input
        local oput = ""
        local valid = {m.limit and stream:pop(), (m.limit and m.withtwo) and stream:pop()}
        while #stream > 0 and seq and m.limit do table.insert(valid, stream:pop()) end
        local vix = {}
        for _,v in ipairs(valid) do vix[v] = true end
        local exit = false
        repeat
            cplease:pop()
            cplease:push(math.random())
            cin:pop()
            local proc = cin:demand()
            oput = proc
            if ckill:peek() then exit = true break end
            cplease:pop()
            local min, max = valid[2] or -math.huge, valid[1] or math.huge
            if m.asone and not tonumber(proc) then cdebug:pop() cdebug:push("Fail by tonumber") goto redo end
            if m.asone and not seq then
                local cond = math.inside(tonumber(proc), min, max)
                if not seq and ((not cond and not m.negate) or (cond and m.negate)) then
                    cdebug:pop() cdebug:push("Fail by case 1")
                    goto redo
                end
                proc = {tonumber(proc)}
            end
            if m.asone and seq then proc = {tonumber(proc)} end
            if not m.asone and not seq then
                local cond = math.inside(utf8.len(proc), min, max)
                if not seq and ((not cond and not m.negate) or (cond and m.negate)) then
                    cdebug:pop() cdebug:push("Fail by case 2")
                    goto redo
                end
                local a = {utf8.codepoint(proc, 1, utf8.len(proc))}
                proc = {}
                for i=#a, 1, -1 do
                    table.insert(proc, a[i])
                end
            end
            if not m.asone and seq then
                local a = {utf8.codepoint(proc, 1, utf8.len(proc))}
                proc = {}
                for i=#a, 1, -1 do
                    table.insert(proc, a[i])
                end
            end
            if seq then
                local valid = true
                for _,v in ipairs(proc) do
                    if (vix[v] and m.negate) or (not vix[v] and not m.negate) then
                        valid = false
                        cdebug:pop() cdebug:push("Fail by case 3")
                        goto redo
                    end
                end
                if valid then
                    input = proc
                end
            else
                input = proc
            end

            ::redo::
        until input
        if exit then return end

        output = output..oput
        cout:pop()
        cout:push(output)
        for i,v in ipairs(input) do
            stream:push(v)
        end
    end,
    output = function(m)
        -- withtwo - convert to base
        -- limit - limit to ascii
        -- asone - utf8
        -- negate - ???????????
        -- sequentially - apply to entire stream

        if #stream < 1 then return end
        if seq or m.asone then m.withtwo = false end
        repeat
            local a = stream:pop()
            local b = m.withtwo and stream:pop() or 10
            if m.asone and a == 7 then
                cping:push(true)
            end
            output = output..(m.asone and utf8.char(m.limit and (a % 256) or a) or (b == 10 and a or basen(a, b)))
            cout:pop()
            cout:push(output)
        until #stream < (m.withtwo and 2 or 1) or not seq
    end,
    condif = function(m)
        -- withtwo - compare a and b
        -- limit - less than
        -- asone - AND all checks
        -- negate - reverse the condition
        -- sequentially - check all numbers (if withtwo, check against top number)

        if #stream < (m.withtwo and 2 or 1) then -- skip else case
            local c = 1
            jumpnext(function(v)
                c = c + (({condif = 1, condend = -1})[v.base] or 0)
                return c == 0
            end)
            return
        end
        
        if not seq then
            local a = stream:pop()
            local b = m.withtwo and stream:pop() or 0
            local mode = (m.limit  and 1 or 0) 
                       + (m.negate and 2 or 0)
            if not ((mode == 0 and a == b)
                 or (mode == 1 and a <  b)
                 or (mode == 2 and a ~= b)
                 or (mode == 3 and a >= b)) then
                local c = 0
                globali = globali + 1
                jumpnext(function(v)
                    c = c + (({condif = 1, condend = -1})[v.base] or 0)
                    return (c == 0 and v.base == "condelse") or c < 0
                end)
            end
            stream:push(m.withtwo and b or nil)
            stream:push(a)
        else
            local top = m.withtwo and stream:pop() or 0
            local checks = {top}
            local any = m.asone
            local mode = (m.limit  and 1 or 0) 
                       + (m.negate and 2 or 0)
            repeat
                local a = stream:pop()
                table.insert(checks, a)
                local cond = (mode == 0 and a == top)
                          or (mode == 1 and a <  top)
                          or (mode == 2 and a ~= top)
                          or (mode == 3 and a >= top)
                if m.asone and not cond then
                    any = false
                    break
                elseif not m.asone and cond then
                    any = true
                    break
                end
            until #stream < 1
            if not any then
                local c = 0
                globali = globali + 1
                jumpnext(function(v)
                    c = c + (({condif = 1, condend = -1})[v.base] or 0)
                    return (c == 0 and v.base == "condelse") or c < 0
                end)
            end
            for i=#checks, 1, -1 do
                stream:push(checks[i])
            end
        end
    end,
    condelse = function(m)
        -- just jump to end
        local c = 1
        jumpnext(function(v)
            c = c + (({condif = 1, condend = -1})[v.base] or 0)
            return c == 0
        end)
    end,
    jumpback = function(m)
        jumpnext(-1, function(v)
            for _,b in ipairs(v.specials) do
                if b == "flag" then return true end
            end
        end)
        globali = globali - 1
    end,
    jumpforward = function(m)
        jumpnext(function(v)
            for _,b in ipairs(v.specials) do
                if b == "flag" then return true end
            end
        end)
        globali = globali - 1
    end,
    jumpend = function(m)
        globali = #program
    end,
}

while cin:pop() do end
while cout:pop() do end
while cplease:pop() do end
while ckill:pop() do end
while cstep:pop() do end
while cdebug:pop() do end
while cstack:pop() do end
while stream:pop() do end
while boat:poptop() do end
output = ""
cout:pop()
cout:push(output)
program = ({...})[1]
globali = 1
ckill:pop()
cstack:pop()
cstack:push(package())
repeat
    cstep:pop()
    cstep:push(globali)
    cdebug:pop()
    cdebug:push(globali)
    if ckill:pop() then break end
    local command = program[globali]
    for i,v in ipairs(command.downs) do
        (diauds[v] or function() end)()
        seq = (diauds[v] == diauds.sequentially)
    end
    local mods = {}
    for _,v in ipairs(command.modifiers) do mods[v] = true end
    ;(commands[command.base] or function() end)(mods)
    seq = false
    for i,v in ipairs(command.ups) do
        (diauds[v] or function() end)()
        seq = (diauds[v] == diauds.sequentially)
    end
    cdebug:pop()
    cdebug:push(globali.."end")
    globali = globali + 1
    cstack:pop()
    cstack:push(package())
    cdebug:pop()
    cdebug:push(globali.."anew")
until globali > #program
::done::
ckill:push("Done, "..globali.."/"..#program)
cout:push(output)
cplease:pop()
cstep:pop()
cstep:push(globali)