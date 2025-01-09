require "boiler"
require "vector"
require "keys"

local counts = 0

camera = {
    position = Vector2.new(0, 0), -- position of the camera
    r = 0,                        -- rotation of the camera
    z = 0.4,                      -- zoom of the camera, smaller = zoomed out, bigger = zoomed in
    mouse = Vector2.new(0, 0),    -- position of the mouse relative to the camera
    offset = function(self, dirvec, r, z)
        -- synopsis: offsets the camera
        -- camera:offset(dirvec [, r=0, z=0])
        -- dirvec: vector2  - position offset
        -- r: number        - rotation offset
        -- z: number        - zoom offset

        self.position = self.position + (dirvec or Vector2.new(0, 0))
        self.r = self.r + (r or 0)
        self.z = self.z + (z or 0)
    end,
    offrel = function(self, dirvec, r, z)
        -- synopsis: offsets the camera with respect to it's initial rotation
        -- camera:offrel(dirvec [, r=0, z=0])
        -- dirvec: vector2  - direction
        -- r: number        - rotation offset
        -- z: number        - zoom offset

        self:offset((dirvec or Vector2.new(0, 0)):rotaround(self.position, self.r), r, z)
    end,
    set = function(self, vec, r, z)
        -- synopsis: sets the camera
        -- camera:set(vec [, r=camera.r, z=camera.z])
        -- vec: vector2 - new position
        -- r: number    - new rotation
        -- z: number    - new zoom

        self.position = vec or self.position
        self.r = r or self.r
        self.z = z or self.z
    end,
    refresh = function(self)
        camera.mouse = (camera.position - Vector2.new(window.width / 2 / camera.z, window.height / -2 / camera.z):rotaround(camera.position, camera.r)) + Vector2.new(mouse.x / camera.z, mouse.y / -1 / camera.z):rotaround(camera.position, camera.r)
    end
}

function CamPoint(x, y, r, sx, sy)
    -- synopsis: returns new values as shown by the camera
    -- CamPoint(x, y [, r=0 [, sx=1 [, sy=1]]])
    -- x: number    - x position
    -- y: number    - y position
    -- r: number    - rotation
    -- sx: number   - x scaling
    -- sy: number   - y scaling
    -- returns: number, number, number, number, number

    local cam = camera

    local rad = cam.r * math.pi / 180
    local xo = x - cam.position.x
    local yo = y - cam.position.y

    if sy then
        r = (r or 0) * math.pi / 180
        return math.cos(rad) * xo * cam.z + math.cos(rad - math.pi / 2) * yo * cam.z + window.width / 2, math.sin(rad) * xo * cam.z + math.sin(rad - math.pi / 2) * yo * cam.z + window.height / 2, r + rad, (sx or 0) * cam.z, (sy or 0) * cam.z
    else
        return math.cos(rad) * xo * cam.z + math.cos(rad - math.pi / 2) * yo * cam.z + window.width / 2, math.sin(rad) * xo * cam.z + math.sin(rad - math.pi / 2) * yo * cam.z + window.height / 2, (r or 0) * cam.z, (sx or 0) * cam.z
    end
end

function CamPointInt(x, y, r, sx, sy)
    local x, y, r, sx, sy = CamPoint(x, y, r, sx, sy)
    return math.round(x), math.round(y), r, math.round(sx), math.round(sy)
end

function CamPoly(pols, vec, r, sx, sy, kx, ky)
    -- synopsis: returns new polygon points as shown by the camera
    -- CamPoly(pols, vec [, r=0 [, sx=1 [, sy=1 [, kx=0 [, ky=0]]]]])
    -- pols: table  - table of points
        -- point x, - point 1 x
        -- point y, - point 1 y
        -- point x, - point 2 x
        -- point y, - point 2 y
        -- ...
    -- vec: vector2 - position
    -- r: number    - rotation
    -- sx: number   - scale x
    -- sy: number   - scale y
    -- kx: number   - skew x percent (where 1 == 100%)
    -- ky: number   - skew y percent (where 1 == 100%)
    -- returns: table
    -- Note: origin is {0, 0} relative to the polygon
    -- Note: skewing is applied first, then scaling, then rotation

    assert(pols ~= nil and vec ~= nil, "CamPoly requires at least two arguments")
    assert(typeof(pols) == "table", "expected argument 1 to be a table, got '"..typeof(pols).."' instead")
    assert(typeof(vec) == "vector2", "expected argument 2 to be a Vector2, got '"..typeof(vec).."' instead")

    local poss = {}
    local pots = {}
    r  = r  or 0
    sx = sx or 1
    sy = sy or 1
    kx = kx or 0
    ky = ky or 0
    
    local w, h = 0, 0
    local minx, maxx, miny, maxy = 0, 0, 0, 0

    for i=1, #pols, 2 do
        local pos = Vector2.new(pols[i], pols[i+1])
        poss[#poss+1] = pos

        minx, maxx, miny, maxy = math.min(minx, pos.x), math.max(maxx, pos.x), math.min(miny, pos.y), math.max(maxy, pos.y)
    end
    w, h = maxx - minx, maxy - miny

    --[[

    ]]

    for i,v in ipairs(poss) do
        local fx, fy = (v.x) / maxx, (v.y) / maxy
        v = (Vector2.new(w * fy * kx, h * fx * ky)) + v
        v = (v * Vector2.new(sx, sy) + vec):rotaround(vec, r)

        pots[i*2-1], pots[i*2] = CamPoint(v.x, v.y, 0, 0, 0)
    end

    return pots
end

function CamUI(x, y)
    -- synopsis: moves an object to as if it was moving with the camera, like a ui object
    -- CamUI(x, y)
    -- x: number - screen X position, starting from left and going right
    -- y: number - screen Y position, starting from top and going down
    -- returns: vector2

    -- note: you will still need to offset it via CamPoint or CamPoly

    return (camera.position - Vector2.new(window.width / 2 / camera.z, window.height / -2 / camera.z):rotaround(camera.position, camera.r)) + Vector2.new(x / camera.z, y / -1 / camera.z):rotaround(camera.position, camera.r)
end