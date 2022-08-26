#!/usr/bin/env luajit
local range = require 'ext.range'
local gl = require 'gl'
local vec3d = require 'vec-ffi.vec3d'

local App = require 'imguiapp.withorbit'()

App.title = 'meh'

function App:initGL()
	App.super.initGL(self)
end

local function basisFor(v)
	local x = v:cross(vec3d(1,0,0))
	local y = v:cross(vec3d(0,1,0))
	local z = v:cross(vec3d(0,0,1))
	local xl = x:lenSq()
	local yl = y:lenSq()
	local zl = z:lenSq()
	if xl > yl then	-- x > y
		if xl > zl then	-- x > y, x > z
			return x
		else			-- z > x > y
			return z
		end
	else			-- y >= x
		if yl > zl then	-- y > z, y >= x
			return y
		else			-- z > y >= x
			return z
		end
	end
end

function App:update()
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

	local n = 100	-- num circle divs
	local phis = range(0,120,10)	-- sphere grid detail

	for _,a1 in ipairs{
		-- [[ cube
		vec3d(1,0,0),
		vec3d(-1,0,0),
		vec3d(0,1,0),
		vec3d(0,-1,0),
		vec3d(0,0,1),
		vec3d(0,0,-1),
		--]]
		--[[ 2D triangle
		vec3d(1,0,0),
		vec3d(math.cos(math.rad(120)),math.sin(math.rad(120)),0),
		vec3d(math.cos(math.rad(240)),math.sin(math.rad(240)),0),
		--]]
		--[[ 3D platonic solid -- tetrahedron
		vec3d(0,0,1),
		vec3d(-math.sqrt(2/3), -math.sqrt(2)/3, -1/3),
		vec3d(math.sqrt(2/3), -math.sqrt(2)/3, -1/3),
		vec3d(0, math.sqrt(8)/3, -1/3),
		--]]
	} do
		local a2 = basisFor(a1):normalize()
		local a3 = a1:cross(a2)
		-- re-ortho-normalize a3
		for _,phi in ipairs(phis) do
			local z = math.cos(math.rad(phi))
			local r = math.sin(math.rad(phi))
			
			gl.glBegin(gl.GL_LINE_LOOP)
			for i=1,n do
				local th = (i-.5)/n*2*math.pi
				local v = a1 * z + a2 * r*math.cos(th) + a3 * r*math.sin(th)
				gl.glVertex3dv(v.s)
			end
			gl.glEnd()
		end
	end

	App.super.update(self)
end

return App():run()
