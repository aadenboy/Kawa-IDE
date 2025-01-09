require "boiler"
require "vector"
require "camera"

function DOIT(program, glyphs)
    local padding = 15
    local flashycolor = 0.5
    local total = Vector2.new(#program * 30 + padding*2 - 10, 60 + padding*2)
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
    total.y = total.y + (miny + maxy) * 10
    center = miny * 10 + padding

    local export = love.graphics.newCanvas(total.x, total.y)
    love.graphics.setLineWidth(1)
    love.graphics.setCanvas(export)
    love.graphics.clear(1, 1, 1)
    function dg(glyph, pos)
        local nglyph = {}
        local x, y = pos.x, pos.y
        for i,v in ipairs(glyph) do
            if type(v) == "number" then
                nglyph[i] = v * 10 - 10 + (i % 2 == 1 and x or y)
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

        local off = Vector2.new(0, 70)
        for j=1, #v.ups, 1 do
            local mod = v.ups[j]
            local glyph = glyphs.diaud[mod] or glyphs.diaud.none
            local up = (glyph and glyph.top or 1) - 1
            love.graphics.setColor(0, 0, 0)
            if glyph == glyphs.diaud.none then love.graphics.setColor(0, 0, 0, flashycolor) end
            dg(glyph, pos + off)
            off = off + Vector2.new(0, up + 1) * 10
        end
        off = Vector2.new(0, 0)
        for j=#v.downs, 1, -1 do
            local mod = v.downs[j]
            local glyph = glyphs.diaud[mod] or glyphs.diaud.none
            local down = (glyph and glyph.top or 0) - 1
            love.graphics.setColor(0, 0, 0)
            if glyph == glyphs.diaud.none then love.graphics.setColor(0, 0, 0, flashycolor) end
            off = off - Vector2.new(0, down + 1) * 10
            dg(glyph, pos + off)
        end
        for j=#v.specials, 1, -1 do
            local mod = v.specials[j]
            local glyph = glyphs.special[mod] or glyphs.special.none
            local down = (glyph and glyph.top or 0) - 1
            love.graphics.setColor(0, 0, 0)
            if glyph == glyphs.special.none then love.graphics.setColor(0, 0, 0, flashycolor) end
            off = off - Vector2.new(0, down + 1) * 10
            dg(glyph, pos + off)
        end

        x = x + 30
    end

    love.graphics.setCanvas()
    export:newImageData():encode("png", "export.png")
    love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/export.png")
end

return DOIT