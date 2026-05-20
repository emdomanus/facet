--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.types.math)

type ShadowConfig = Types.ShadowConfig
type ShadowSolveResult = Types.ShadowSolveResult

local DEFAULT_DEPTH = 0.12
local DEFAULT_SCALE = 0.08
local DEFAULT_MAX_OFFSET = 24
local SHADOW_EPSILON = 1e-4

local Shadow = {}

local function compressVector2Magnitude(value: Vector2, maxMagnitude: number): Vector2
	local magnitude = value.Magnitude
	if magnitude <= SHADOW_EPSILON or maxMagnitude <= 0 then
		return value
	end
	local compressedMagnitude = maxMagnitude * (1 - math.exp(-magnitude / maxMagnitude))
	return value / magnitude * compressedMagnitude
end

local function snapPixel(value: number): number
	if value >= 0 then
		return math.floor(value + 0.5)
	end
	return math.ceil(value - 0.5)
end

local function snapPixelVector2(value: Vector2): Vector2
	return Vector2.new(snapPixel(value.X), snapPixel(value.Y))
end

function Shadow.solve(
	camera: Camera,
	cframe: CFrame,
	worldSize: Vector3,
	canvasSize: Vector2,
	config: ShadowConfig?
): ShadowSolveResult
	local resolved : ShadowConfig = config or {}
	local depth = resolved.depth or DEFAULT_DEPTH
	local scale = resolved.scale or DEFAULT_SCALE
	local maxOffset = resolved.maxOffset or DEFAULT_MAX_OFFSET
	if depth <= 0 or worldSize.X <= 0 or worldSize.Y <= 0 then
		return {
			offset = Vector2.zero,
			direction = Vector2.zero,
			strength = 0,
		}
	end

	local shadowVector = -camera.CFrame.LookVector * depth
	local canvasDelta = Vector2.new(
		shadowVector:Dot(cframe.RightVector) * canvasSize.X / worldSize.X,
		-shadowVector:Dot(cframe.UpVector) * canvasSize.Y / worldSize.Y
	) * scale
	local offset = snapPixelVector2(compressVector2Magnitude(canvasDelta, maxOffset))
	local direction = if offset.Magnitude > SHADOW_EPSILON then offset.Unit else Vector2.zero
	local strength = math.clamp(offset.Magnitude / math.max(1, maxOffset), 0, 1)

	return {
		offset = offset,
		direction = direction,
		strength = strength,
	}
end

return Shadow
