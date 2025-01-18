require "boiler"
require "vector"
require "camera"

function SINGLEDRAW(program, glyphs, width)
    local padding = width / 2
    local unit    = width * (1/3)
    local awidth  = width - unit
    local height  = awidth * 3
    local flashycolor = 0.5
    local total = Vector2.new(#program * width + padding*2 - unit, height + padding*2)
    local miny, maxy = 0, 0
    local center = 0
    for _,v in ipairs(program) do
        local c = 0
        for _,b in ipairs(v.downs)    do c = c + glyphs.diaud  [b].top end
        for _,b in ipairs(v.specials) do c = c + glyphs.special[b].top end
        miny = math.max(miny, c)
        c = 0
        for _,b in ipairs(v.ups) do c = c + glyphs.diaud[b].top end
        maxy = math.max(maxy, c)
    end
    total.y = total.y + (miny + maxy) * unit
    center = miny * unit + padding

    local export = love.graphics.newCanvas(total.x, total.y)
    love.graphics.setLineWidth(width/30)
    love.graphics.setCanvas(export)
    love.graphics.clear(1, 1, 1)
    function dg(glyph, pos)
        local nglyph = {}
        local x, y = pos.x, pos.y
        for i,v in ipairs(glyph) do
            if type(v) == "number" then
                nglyph[i] = v * unit - unit + (i % 2 == 1 and x or y)
                if i % 2 == 0 then nglyph[i] = total.y - nglyph[i] end
            else
                dg(v, pos)
            end
        end
        if #nglyph > 2 then
            love.graphics.polygon("line", nglyph) 
        end
    end
    local x = padding
    for i,v in ipairs(program) do
        local pos = Vector2.new(x, center)
        love.graphics.setColor(0, 0, 0)
        if v.base == "none" then love.graphics.setColor(0, 0, 0, flashycolor) end
        dg(glyphs.base[v.base] or glyphs.base.none, pos)

        for _,b in ipairs(v.modifiers) do
            dg((glyphs.modifier[b] or {})[v.base], pos)
        end

        local off = Vector2.new(0, height + unit)
        for j=1, #v.ups, 1 do
            local mod = v.ups[j]
            local glyph = glyphs.diaud[mod] or glyphs.diaud.none
            local up = (glyph and glyph.top or 1) - 1
            love.graphics.setColor(0, 0, 0)
            if glyph == glyphs.diaud.none then love.graphics.setColor(0, 0, 0, flashycolor) end
            dg(glyph, pos + off)
            off = off + Vector2.new(0, up + 1) * unit
        end
        off = Vector2.new(0, 0)
        for j=#v.downs, 1, -1 do
            local mod = v.downs[j]
            local glyph = glyphs.diaud[mod] or glyphs.diaud.none
            local down = (glyph and glyph.top or 0) - 1
            love.graphics.setColor(0, 0, 0)
            if glyph == glyphs.diaud.none then love.graphics.setColor(0, 0, 0, flashycolor) end
            off = off - Vector2.new(0, down + 1) * unit
            dg(glyph, pos + off)
        end
        for j=#v.specials, 1, -1 do
            local mod = v.specials[j]
            local glyph = glyphs.special[mod] or glyphs.special.none
            local down = (glyph and glyph.top or 0) - 1
            love.graphics.setColor(0, 0, 0)
            if glyph == glyphs.special.none then love.graphics.setColor(0, 0, 0, flashycolor) end
            off = off - Vector2.new(0, down + 1) * unit
            dg(glyph, pos + off)
        end

        x = x + width
    end

    love.graphics.setCanvas()
    return export
    --:newImageData():encode("png", "export.png")
    --love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/export.png")
end

function DOIT(program, glyphs, width, max)
    local padding = width / 2
    local nprog = {}
    for i,v in ipairs(program) do
        local at = max == 0 and 1 or math.ceil(i/max)
        nprog[at] = nprog[at] or {}
        table.insert(nprog[at], v)
    end
    local canvases = {}
    local twidth, theight = 0, 0
    for i,v in ipairs(nprog) do
        local canvas = SINGLEDRAW(v, glyphs, width)
        table.insert(canvases, canvas)
        twidth = math.max(canvas:getWidth(), twidth)
        theight = theight + canvas:getHeight()
    end
    if twidth == 0 or theight == 0 then return error(twidth..", "..theight..", "..canvases) end
    local total = love.graphics.newCanvas(twidth, theight)
    local ocanvas = love.graphics.getCanvas()
    love.graphics.setCanvas(total)
    love.graphics.clear(1, 1, 1, 1)
    local y = 0
    for i,v in ipairs(canvases) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(v, 0, y)
        love.graphics.setColor(0, 0, 0)
        if         i > 1 then love.graphics.line(padding/2, y, twidth - padding/2, y) end
        y = y + v:getHeight()
        if #canvases > i then love.graphics.line(padding/2, y, twidth - padding/2, y) end
    end
    love.graphics.setCanvas(ocanvas)
    total:newImageData():encode("png", "export.png")
    love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/export.png")
end

return DOIT