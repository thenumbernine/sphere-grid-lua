#!/usr/bin/env luajit
local assertindex = require 'ext.assert'.index
local table = require 'ext.table'
local ig = require 'imgui'
local gl = require 'gl'

-- wow, if you use the pure-lua version, the js-emu impl runs a few orders faster
local vec3d = js
	and require 'vec.vec3'
	or require 'vec-ffi.vec3d'

local App = require 'imguiapp.withorbit'()
App.viewUseBuiltinMatrixMath = true
App.title = 'sphere grids'

function App:initGL()
	App.super.initGL(self)

	self.shader = require 'gl.program'{
		version = 'latest',
		precision = 'best',
		vertexCode = [[
in vec3 vertex;
uniform mat4 mvProjMat;
void main() {
	gl_Position = mvProjMat * vec4(vertex, 1.);
}
]],
		fragmentCode = [[
out vec4 fragColor;
void main() {
	fragColor = vec4(1., 1., 1., 1.);
}
]],
	}:useNone()

	self:updateGrid()
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

numCircleDivs = 100	-- num circle divs
gridAngleMax = 120
numGridLines = 12
gridBasisType = 1

local gridBasisTypes = table{
	'cube',
	'triangle',
	'tetrahedron',
}

local basisForGrid = {
	cube = {
		vec3d(1,0,0),
		vec3d(-1,0,0),
		vec3d(0,1,0),
		vec3d(0,-1,0),
		vec3d(0,0,1),
		vec3d(0,0,-1),
	},
	triangle = {
		vec3d(1,0,0),
		vec3d(math.cos(math.rad(120)),math.sin(math.rad(120)),0),
		vec3d(math.cos(math.rad(240)),math.sin(math.rad(240)),0),
	},
	tetrahedron = {
		vec3d(0,0,1),
		vec3d(-math.sqrt(2/3), -math.sqrt(2)/3, -1/3),
		vec3d(math.sqrt(2/3), -math.sqrt(2)/3, -1/3),
		vec3d(0, math.sqrt(8)/3, -1/3),
	},
}

function App:updateGrid()
	self.sceneobjs = table()
	for _,a1 in ipairs(basisForGrid[gridBasisTypes[gridBasisType]]) do
		local a2 = basisFor(a1):normalize()
		local a3 = a1:cross(a2)
		-- re-ortho-normalize a3
		for j=1,numGridLines do
			local phi = j/numGridLines*gridAngleMax
			local z = math.cos(math.rad(phi))
			local r = math.sin(math.rad(phi))

			local vertexes = table()
			for i=1,numCircleDivs do
				local th = (i-.5)/numCircleDivs*2*math.pi
				local v = a1 * z + a2 * r*math.cos(th) + a3 * r*math.sin(th)
				--vertexes:append{v:unpack()}
				local x, y, z = v:unpack()
				vertexes:insert(x)
				vertexes:insert(y)
				vertexes:insert(z)
			end

			self.sceneobjs:insert(require 'gl.sceneobject'{
				program = self.shader,
				vertexes = {
					data = vertexes,
					dim = 3,
				},
				geometry = {
					mode = gl.GL_LINE_LOOP,
				},
			})
		end
	end
end

function App:update()
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))
	for _,sceneobj in ipairs(self.sceneobjs) do
		sceneobj.uniforms.mvProjMat = self.view.mvProjMat.ptr
		sceneobj:draw()
	end
	App.super.update(self)
end

function App:updateGUI()
	if ig.luatableInputInt('circle resolution', _G, 'numCircleDivs')
	or ig.luatableInputFloat('grid angle max', _G, 'gridAngleMax')
	or ig.luatableInputInt('num grid lines', _G, 'numGridLines')
	or ig.luatableCombo('grid basis', _G, 'gridBasisType', gridBasisTypes)
	then
		self:updateGrid()
	end
end

return App():run()
