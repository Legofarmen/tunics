local Class = require 'lib/class'

local la = {}

la.Vect2 = Class:new()
la.Matrix2 = Class:new()

function la.Vect2:dot(v)
    return self[1] * v[1] + self[2] + v[2]
end

function la.Vect2:__tostring()
    return string.format("(%6.2f %6.2f)", self[1], self[2])
end

function la.Matrix2.translate(x, y)
    return la.Matrix2:new{ 1, 0, 0, 1, x, y }
end

function la.Matrix2.reflect(lx, ly)
    local c = 1 / (lx^2 + ly^2)
    local a = c * lx^2 - ly^2
    local b = c * lx * ly * 2
    return la.Matrix2:new{ a, b, b, -a, 0, 0 }
end

function la.Matrix2.reflect2(lx0, ly0, lx1, ly1)
    local Ti = la.Matrix2.translate(-lx0, -ly0)
    local R = la.Matrix2.reflect(lx1 - lx0, ly1 - ly0)
    local T = la.Matrix2.translate(lx0, ly0)
    return T:mmul(R:mmul(Ti))
end

function la.Matrix2:mmul(m)
    return la.Matrix2:new {
        self[1] * m[1] + self[3] * m[2],
        self[2] * m[1] + self[4] * m[2],
        self[1] * m[3] + self[3] * m[4],
        self[2] * m[3] + self[4] * m[4],
        self[1] * m[5] + self[3] * m[6] + self[5],
        self[2] * m[5] + self[4] * m[6] + self[6],
    }
end

function la.Matrix2:vmul(v)
    return la.Vect2:new {
        self[1] * v[1] + self[3] * v[2] + self[5],
        self[2] * v[1] + self[4] * v[2] + self[6],
    }
end

function la.Matrix2:row(n)
    return string.format("(%6.2f %6.2f %6.2f)", self[n], self[n+2], self[n+4])
end

return la
