--!strict
--!optimize 2
--!native

local Math = require(script.Parent.Parent.Parent.Parent.math)
local Types = require(script.Parent.Parent.Parent.Parent.types.components.component3d)

type Component3DConfig = Types.Component3DConfig
type Component3DComplete = Types.Component3DComplete
type Disconnect = Types.Disconnect
type ShadowChangedCallback = Types.ShadowChangedCallback
type ShadowSolveResult = Types.ShadowSolveResult

local DEFAULT_DEPTH = 8
local SOCKET_THICKNESS = 0.05
local MIN_STUD_SIZE = 0.01
local SHADOW_EPSILON = 1e-4
local DEFAULT_SHADOW: ShadowSolveResult = {
	offset = Vector2.zero,
	direction = Vector2.zero,
	strength = 0,
}

local Component3D = {}
Component3D.__index = Component3D

local function createPart(name: string): Part
	local part = Instance.new("Part")
	part.Name = `{name}Part`
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Locked = true
	part.Massless = true
	part.Size = Vector3.new(1, 1, SOCKET_THICKNESS)
	part.Transparency = 1
	return part
end

local function getSurfaceZOffset(config: Component3DConfig): number
	if config.displayOrder ~= nil then
		return config.displayOrder
	end
	return config.zOffset or 0
end

local function createSurfaceGui(name: string, part: Part, config: Component3DConfig): SurfaceGui
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = name
	surfaceGui.Adornee = part
	surfaceGui.AlwaysOnTop = true
	surfaceGui.Brightness = 2
	surfaceGui.Enabled = false
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.LightInfluence = 0
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	surfaceGui.ZOffset = getSurfaceZOffset(config)
	return surfaceGui
end

local function createFrame(name: string): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = false
	frame.Position = UDim2.fromScale(0, 0)
	frame.Size = UDim2.fromScale(1, 1)
	return frame
end

local function anchorCFrameToScreenPoint(
	camera: Camera,
	cframe: CFrame,
	size: Vector3,
	anchor: Vector2,
	screenPoint: Vector2,
	depth: number
): CFrame
	local targetWorldPoint = Math.viewportPlane.getGeometry(camera, screenPoint, depth)
	local localAnchorPoint = Vector3.new(
		(0.5 - anchor.X) * size.X,
		(0.5 - anchor.Y) * size.Y,
		-size.Z * 0.5
	)
	local centerPosition = targetWorldPoint - cframe:VectorToWorldSpace(localAnchorPoint)
	return CFrame.fromMatrix(centerPosition, cframe.RightVector, cframe.UpVector, -cframe.LookVector)
end

local function shadowsEqual(a: ShadowSolveResult, b: ShadowSolveResult): boolean
	return a.offset == b.offset
		and a.direction == b.direction
		and math.abs(a.strength - b.strength) <= SHADOW_EPSILON
end

function Component3D.new(config: Component3DConfig, manager: any?): Component3DComplete
	local name = config.name or "FacetComponent"
	local part = createPart(name)
	local surfaceGui = createSurfaceGui(name, part, config)
	local frame = createFrame("Content")
	frame.Parent = surfaceGui
	surfaceGui.Parent = config.guiParent

	local self: Component3DComplete = setmetatable({} :: any, Component3D)
	self._manager = manager
	self._part = part
	self._surfaceGui = surfaceGui
	self._frame = frame
	self._config = config
	self._enabled = false
	self._shadow = DEFAULT_SHADOW
	self._shadowChangedCallbacks = {}
	self:_setParent(config.parent)
	return self
end

function Component3D.getFrame(self: Component3DComplete): Frame
	return self._frame
end

function Component3D.getSurfaceGui(self: Component3DComplete): SurfaceGui
	return self._surfaceGui
end

function Component3D.getShadow(self: Component3DComplete): ShadowSolveResult
	return self._shadow
end

function Component3D.bindToShadowChanged(
	self: Component3DComplete,
	callback: ShadowChangedCallback,
	runInitially: boolean?
): Disconnect
	self._shadowChangedCallbacks[callback] = true
	local disconnected = false

	if runInitially == true then
		callback(self._shadow)
	end

	return function()
		if disconnected then
			return
		end
		disconnected = true
		self._shadowChangedCallbacks[callback] = nil
	end
end

function Component3D.setConfig(self: Component3DComplete, config: Component3DConfig)
	self._config = config
	self._surfaceGui.Name = config.name or self._surfaceGui.Name
	self._surfaceGui.ZOffset = getSurfaceZOffset(config)
	self._surfaceGui.Parent = config.guiParent
	self:_setParent(config.parent)
end

function Component3D.setEnabled(self: Component3DComplete, enabled: boolean)
	if self._enabled == enabled then
		return
	end
	self._enabled = enabled
	self._surfaceGui.Enabled = enabled
	if enabled then
		self:_setParent(self._config.parent)
		if self._manager then
			self._manager:register(self)
		end
	else
		self:_setParent(nil)
		if self._manager then
			self._manager:unregister(self)
		end
	end
end

function Component3D.isEnabled(self: Component3DComplete): boolean
	return self._enabled
end

function Component3D._setParent(self: Component3DComplete, parent: Instance?)
	self._part.Parent = parent
end

function Component3D._notifyShadowChanged(self: Component3DComplete)
	for callback in self._shadowChangedCallbacks do
		callback(self._shadow)
	end
end

function Component3D._setShadow(self: Component3DComplete, shadow: ShadowSolveResult)
	if shadowsEqual(self._shadow, shadow) then
		return
	end

	self._shadow = shadow
	self:_notifyShadowChanged()
end

function Component3D._update(self: Component3DComplete, camera: Camera?)
	if not camera or not self._enabled then
		return
	end

	local config = self._config
	local viewportSize = camera.ViewportSize
	if viewportSize.X <= 0 or viewportSize.Y <= 0 then
		return
	end

	local screenRect = config.screenRect
	local centerPixels, socketSizePixels = Math.viewportPlane.getRectPixels(screenRect, viewportSize)
	local anchorPixels = Math.viewportPlane.getAnchorPixels(screenRect, viewportSize)
	local canvasSize = config.canvasSize or Math.viewportPlane.getCanvasSizePixels(screenRect, viewportSize)
	local fittedSize = Math.viewportPlane.fitSizeToBounds(canvasSize, socketSizePixels)
	local fittedCenter = Math.viewportPlane.getFittedCenterPixels(screenRect, viewportSize, fittedSize)
	local depth = config.depth or DEFAULT_DEPTH
	local worldCenter, studSizePerPixel = Math.viewportPlane.getGeometry(camera, fittedCenter, depth)

	local worldSize = Vector3.new(
		math.max(MIN_STUD_SIZE, fittedSize.X * studSizePerPixel.X),
		math.max(MIN_STUD_SIZE, fittedSize.Y * studSizePerPixel.Y),
		SOCKET_THICKNESS
	)

	local cframe = Math.facing.resolve(camera, worldCenter, config.facing)
	cframe = Math.pivot.apply(cframe, worldSize, config.pivot)

	local finalSize = Math.viewportPlane.getMaxFitSize(camera, cframe, worldCenter, centerPixels, socketSizePixels, worldSize)
	cframe = anchorCFrameToScreenPoint(camera, cframe, finalSize, screenRect.anchor, anchorPixels, depth)

	self._part.Size = finalSize
	self._part.CFrame = cframe
	self._surfaceGui.CanvasSize = canvasSize
	self:_setShadow(Math.shadow.solve(camera, cframe, self._part.Size, canvasSize, config.shadow))
end

function Component3D.deconstruct(self: Component3DComplete)
	self:setEnabled(false)
	table.clear(self._shadowChangedCallbacks)
	self._surfaceGui:Destroy()
	self._part:Destroy()
end

return Component3D
