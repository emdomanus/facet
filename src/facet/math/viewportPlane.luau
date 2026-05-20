--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.types.math)

type ScreenRectConfig = Types.ScreenRectConfig

local MIN_STUD_SIZE = 0.01
local PLANE_EPSILON = 1e-6
local SIGN_PAIR = { 1, -1 }

local ViewportPlane = {}

local function roundPixel(value: number): number
	return math.round(value)
end

local function resolveUDim2(value: UDim2, viewportSize: Vector2): Vector2
	return Vector2.new(
		value.X.Scale * viewportSize.X + value.X.Offset,
		value.Y.Scale * viewportSize.Y + value.Y.Offset
	)
end

function ViewportPlane.getRectPixels(config: ScreenRectConfig, viewportSize: Vector2): (Vector2, Vector2, Vector2)
	local position = resolveUDim2(config.position, viewportSize)
	local size = resolveUDim2(config.size, viewportSize)
	local left = roundPixel(position.X - config.anchor.X * size.X)
	local top = roundPixel(position.Y - config.anchor.Y * size.Y)
	local width = math.max(1, roundPixel(size.X))
	local height = math.max(1, roundPixel(size.Y))
	return Vector2.new(left + width * 0.5, top + height * 0.5), Vector2.new(width, height), Vector2.new(left, top)
end

function ViewportPlane.getCanvasSizePixels(config: ScreenRectConfig, viewportSize: Vector2): Vector2
	local _, size = ViewportPlane.getRectPixels(config, viewportSize)
	return size
end

function ViewportPlane.getAnchorPixels(config: ScreenRectConfig, viewportSize: Vector2): Vector2
	local _, size, topLeft = ViewportPlane.getRectPixels(config, viewportSize)
	return topLeft + Vector2.new(size.X * config.anchor.X, size.Y * config.anchor.Y)
end

function ViewportPlane.fitSizeToBounds(designSize: Vector2, boundsSize: Vector2): Vector2
	if designSize.X <= 0 or designSize.Y <= 0 then
		return boundsSize
	end
	local fitScale = math.min(boundsSize.X / designSize.X, boundsSize.Y / designSize.Y)
	if fitScale <= 0 then
		return Vector2.new(1, 1)
	end
	return Vector2.new(
		math.max(1, math.min(boundsSize.X, roundPixel(designSize.X * fitScale))),
		math.max(1, math.min(boundsSize.Y, roundPixel(designSize.Y * fitScale)))
	)
end

function ViewportPlane.getFittedCenterPixels(config: ScreenRectConfig, viewportSize: Vector2, fittedSize: Vector2): Vector2
	local _, size, topLeft = ViewportPlane.getRectPixels(config, viewportSize)
	local anchorPoint = topLeft + Vector2.new(size.X * config.anchor.X, size.Y * config.anchor.Y)
	return anchorPoint + Vector2.new((0.5 - config.anchor.X) * fittedSize.X, (0.5 - config.anchor.Y) * fittedSize.Y)
end

function ViewportPlane.getGeometry(camera: Camera, screenPoint: Vector2, depth: number): (Vector3, Vector2)
	local viewportSize = camera.ViewportSize
	local cameraCFrame = camera.CFrame
	local tanHalfFovV = math.tan(math.rad(camera.FieldOfView * 0.5))
	local halfHeight = tanHalfFovV * depth
	local halfWidth = halfHeight * viewportSize.X / viewportSize.Y
	local x = screenPoint.X / viewportSize.X * 2 - 1
	local y = 1 - screenPoint.Y / viewportSize.Y * 2

	local worldCenter = cameraCFrame.Position
		+ cameraCFrame.LookVector * depth
		+ cameraCFrame.RightVector * x * halfWidth
		+ cameraCFrame.UpVector * y * halfHeight

	return worldCenter, Vector2.new(halfWidth * 2 / viewportSize.X, halfHeight * 2 / viewportSize.Y)
end

function ViewportPlane.getMaxFitSize(
	camera: Camera,
	cframe: CFrame,
	worldCenter: Vector3,
	socketCenter: Vector2,
	socketSize: Vector2,
	flatWorldSize: Vector3
): Vector3
	local cameraCFrame = camera.CFrame
	local cameraPosition = cameraCFrame.Position
	local cameraRight = cameraCFrame.RightVector
	local cameraUp = cameraCFrame.UpVector
	local cameraLook = cameraCFrame.LookVector
	local viewportSize = camera.ViewportSize

	local centerOffset = worldCenter - cameraPosition
	local u0 = centerOffset:Dot(cameraRight)
	local v0 = centerOffset:Dot(cameraUp)
	local w0 = centerOffset:Dot(cameraLook)
	if w0 <= PLANE_EPSILON then
		return flatWorldSize
	end

	local tanHalfFovV = math.tan(math.rad(camera.FieldOfView * 0.5))
	local aspect = viewportSize.X / viewportSize.Y
	local tanHalfFovH = tanHalfFovV * aspect
	local pxToRatioX = 2 / viewportSize.X
	local pxToRatioY = 2 / viewportSize.Y
	local kuLeft = ((socketCenter.X - socketSize.X * 0.5) * pxToRatioX - 1) * tanHalfFovH
	local kuRight = ((socketCenter.X + socketSize.X * 0.5) * pxToRatioX - 1) * tanHalfFovH
	local kvTop = (1 - (socketCenter.Y - socketSize.Y * 0.5) * pxToRatioY) * tanHalfFovV
	local kvBottom = (1 - (socketCenter.Y + socketSize.Y * 0.5) * pxToRatioY) * tanHalfFovV

	local rightPart = cframe.RightVector
	local upPart = cframe.UpVector
	local rU = rightPart:Dot(cameraRight)
	local rV = rightPart:Dot(cameraUp)
	local rW = rightPart:Dot(cameraLook)
	local uU = upPart:Dot(cameraRight)
	local uV = upPart:Dot(cameraUp)
	local uW = upPart:Dot(cameraLook)
	local hHalf = flatWorldSize.X * 0.5
	local vHalf = flatWorldSize.Y * 0.5
	local maxScale = math.huge

	local function constrain(candidate: number)
		if candidate >= 0 and candidate < maxScale then
			maxScale = candidate
		end
	end

	for _, signX in SIGN_PAIR do
		for _, signY in SIGN_PAIR do
			local du = signX * hHalf * rU + signY * vHalf * uU
			local dv = signX * hHalf * rV + signY * vHalf * uV
			local dw = signX * hHalf * rW + signY * vHalf * uW

			local denom = du - kuRight * dw
			if denom > PLANE_EPSILON then
				constrain((kuRight * w0 - u0) / denom)
			end
			denom = du - kuLeft * dw
			if denom < -PLANE_EPSILON then
				constrain((kuLeft * w0 - u0) / denom)
			end
			denom = dv - kvTop * dw
			if denom > PLANE_EPSILON then
				constrain((kvTop * w0 - v0) / denom)
			end
			denom = dv - kvBottom * dw
			if denom < -PLANE_EPSILON then
				constrain((kvBottom * w0 - v0) / denom)
			end
		end
	end

	if maxScale == math.huge then
		maxScale = 1
	end
	return Vector3.new(
		math.max(MIN_STUD_SIZE, flatWorldSize.X * maxScale),
		math.max(MIN_STUD_SIZE, flatWorldSize.Y * maxScale),
		flatWorldSize.Z
	)
end

return ViewportPlane
