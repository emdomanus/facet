--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.types.math)

type FacingConfig = Types.FacingConfig

local PLANE_EPSILON = 1e-6
local Facing = {}

local function applyYawPitchClamps(
	cameraCFrame: CFrame,
	flatDirection: Vector3,
	targetDirection: Vector3,
	config: FacingConfig
): Vector3
	local right = cameraCFrame.RightVector
	local up = cameraCFrame.UpVector
	local forwardAmount = math.max(PLANE_EPSILON, targetDirection:Dot(flatDirection))
	local yaw = math.atan2(targetDirection:Dot(right), forwardAmount)
	local pitchBase = math.sqrt(targetDirection:Dot(right) ^ 2 + forwardAmount ^ 2)
	local pitch = math.atan2(targetDirection:Dot(up), math.max(PLANE_EPSILON, pitchBase))

	if config.maxYawAngle then
		local maxYaw = math.max(0, config.maxYawAngle)
		yaw = math.clamp(yaw, -maxYaw, maxYaw)
	end
	if config.maxPitchAngle then
		local maxPitch = math.max(0, config.maxPitchAngle)
		pitch = math.clamp(pitch, -maxPitch, maxPitch)
	end
	yaw = yaw + (config.manualYawAngle or 0)
	pitch = pitch + (config.manualPitchAngle or 0)

	local cosPitch = math.cos(pitch)
	local direction = flatDirection * math.cos(yaw) * cosPitch
		+ right * math.sin(yaw) * cosPitch
		+ up * math.sin(pitch)
	return direction.Unit
end

function Facing.resolve(camera: Camera, worldCenter: Vector3, config: FacingConfig?): CFrame
	local cameraCFrame = camera.CFrame
	local resolved = config or {}
	local mode = resolved.mode or "lookAtCamera"
	local flatDirection = -cameraCFrame.LookVector
	local direction = flatDirection

	if mode == "manual" and resolved.manualCFrame then
		return CFrame.new(worldCenter) * resolved.manualCFrame * (resolved.rotation or CFrame.identity)
	elseif mode == "lookAtPoint" and resolved.lookAtPoint then
		local offset = resolved.lookAtPoint - worldCenter
		direction = if offset.Magnitude > PLANE_EPSILON then offset.Unit else flatDirection
	elseif mode == "lookAtCamera" then
		local offset = cameraCFrame.Position - worldCenter
		direction = if offset.Magnitude > PLANE_EPSILON then offset.Unit else flatDirection
	end

	direction = applyYawPitchClamps(cameraCFrame, flatDirection, direction, resolved)
	local cframe = CFrame.lookAt(worldCenter, worldCenter + direction, cameraCFrame.UpVector)
	if resolved.manualRollAngle then
		cframe *= CFrame.Angles(0, 0, resolved.manualRollAngle)
	end
	return cframe * (resolved.rotation or CFrame.identity)
end

return Facing
