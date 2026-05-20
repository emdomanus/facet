--!strict
--!optimize 2

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Facet = require(ReplicatedStorage:WaitForChild("Facet"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FOV_MIN = 1
local FOV_MAX = 120
local autoStepping = true
local connections: { RBXScriptConnection } = {}
local cleanupInstances: { Instance } = {}
local autoSteppingChangedCallbacks: { (boolean) -> () } = {}

local setAutoStepping: (enabled: boolean) -> ()

local function notifyAutoSteppingChanged()
	for _, callback in autoSteppingChangedCallbacks do
		callback(autoStepping)
	end
end

local function getCamera(): Camera
	local camera = Workspace.CurrentCamera
	while not camera do
		Workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
		camera = Workspace.CurrentCamera
	end
	return camera
end

local function styleFrame(frame: Frame, color: Color3)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(20, 20, 24)
	stroke.Thickness = 2
	stroke.Transparency = 0.15
	stroke.Parent = frame
end

local function addLabel(parent: Frame, text: string, yScale: number, textSize: number?)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Position = UDim2.fromScale(0.08, yScale)
	label.Size = UDim2.fromScale(0.84, 0.24)
	label.Text = text
	label.TextColor3 = Color3.fromRGB(246, 248, 252)
	label.TextScaled = false
	label.TextSize = textSize or 24
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function addButton(parent: Frame, name: string, text: string, position: UDim2, size: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.BackgroundColor3 = Color3.fromRGB(28, 31, 38)
	button.BackgroundTransparency = 0.05
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Position = position
	button.Size = size
	button.Text = text
	button.TextColor3 = Color3.fromRGB(246, 248, 252)
	button.TextSize = 18
	button.TextWrapped = true
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(8, 9, 12)
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = button

	return button
end

local function getWorldPointFromCanvas(surfaceGui: SurfaceGui, canvasPosition: Vector2): Vector3?
	local adornee = surfaceGui.Adornee
	if not adornee or not adornee:IsA("BasePart") then
		return nil
	end

	local canvasSize = surfaceGui.CanvasSize
	local partSize = adornee.Size
	if partSize.X <= 0 or partSize.Y <= 0 or canvasSize.X <= 0 or canvasSize.Y <= 0 then
		return nil
	end

	local localX = (0.5 - canvasPosition.X / canvasSize.X) * partSize.X
	local localY = (0.5 - canvasPosition.Y / canvasSize.Y) * partSize.Y
	return adornee.CFrame:PointToWorldSpace(Vector3.new(localX, localY, -partSize.Z / 2))
end

local function addScreenAnchorMarker(name: string, position: UDim2)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = name
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local marker = Instance.new("Frame")
	marker.Name = "AnchorMarker"
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.BackgroundColor3 = Color3.fromRGB(245, 44, 54)
	marker.BorderSizePixel = 0
	marker.Position = position
	marker.Size = UDim2.fromOffset(18, 18)
	marker.ZIndex = 100
	marker.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = marker

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 236, 238)
	stroke.Thickness = 2
	stroke.Parent = marker

	table.insert(cleanupInstances, screenGui)
end

local function setCameraFovFromAlpha(alpha: number, fovLabel: TextLabel, fill: Frame, knob: TextButton)
	alpha = math.clamp(alpha, 0, 1)
	local fov = FOV_MIN + (FOV_MAX - FOV_MIN) * alpha
	getCamera().FieldOfView = fov
	fovLabel.Text = "FOV " .. tostring(math.round(fov))
	fill.Size = UDim2.fromScale(alpha, 1)
	knob.Position = UDim2.fromScale(alpha, 0.5)
	if not autoStepping then
		Facet.step(getCamera())
	end
end

local function getSliderAlpha(bar: Frame, canvasX: number): number
	local absolutePosition = bar.AbsolutePosition
	local absoluteSize = bar.AbsoluteSize
	if absoluteSize.X <= 0 then
		return 0
	end
	return (canvasX - absolutePosition.X) / absoluteSize.X
end

local function getScreenPositionFromCanvas(surfaceGui: SurfaceGui, canvasPosition: Vector2): Vector2?
	local worldPoint = getWorldPointFromCanvas(surfaceGui, canvasPosition)
	if not worldPoint then
		return nil
	end

	local viewportPoint, onScreen = getCamera():WorldToViewportPoint(worldPoint)
	if not onScreen then
		return nil
	end
	return Vector2.new(viewportPoint.X, viewportPoint.Y)
end

local function getSliderAlphaFromProjectedLine(surfaceGui: SurfaceGui, bar: Frame, screenPosition: Vector2): number?
	local barPosition = bar.AbsolutePosition
	local barSize = bar.AbsoluteSize
	if barSize.X <= 0 then
		return nil
	end

	local left = getScreenPositionFromCanvas(surfaceGui, Vector2.new(barPosition.X, barPosition.Y + barSize.Y / 2))
	local right = getScreenPositionFromCanvas(surfaceGui, Vector2.new(barPosition.X + barSize.X, barPosition.Y + barSize.Y / 2))
	if not left or not right then
		return nil
	end

	local axis = right - left
	local lengthSquared = axis:Dot(axis)
	if lengthSquared <= 0.0001 then
		return nil
	end
	return (screenPosition - left):Dot(axis) / lengthSquared
end

local function getCanvasPositionFromPointer(surfaceGui: SurfaceGui, screenPosition: Vector3): Vector2?
	local adornee = surfaceGui.Adornee
	if not adornee or not adornee:IsA("BasePart") then
		return nil
	end

	local camera = getCamera()
	local ray = camera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
	local planeCFrame = adornee.CFrame
	local planeNormal = planeCFrame.LookVector
	local denominator = ray.Direction:Dot(planeNormal)
	if math.abs(denominator) < 0.0001 then
		return nil
	end

	local distance = (planeCFrame.Position - ray.Origin):Dot(planeNormal) / denominator
	if distance < 0 then
		return nil
	end

	local worldPoint = ray.Origin + ray.Direction * distance
	local localPoint = planeCFrame:PointToObjectSpace(worldPoint)
	local canvasSize = surfaceGui.CanvasSize
	local partSize = adornee.Size
	if partSize.X <= 0 or partSize.Y <= 0 or canvasSize.X <= 0 or canvasSize.Y <= 0 then
		return nil
	end

	return Vector2.new(
		(0.5 - localPoint.X / partSize.X) * canvasSize.X,
		(0.5 - localPoint.Y / partSize.Y) * canvasSize.Y
	)
end

local function createBottomPanel()
	local component = Facet.createComponent({
		name = "FacetBottomPanel",
		parent = getCamera(),
		guiParent = playerGui,
		screenRect = {
			position = UDim2.fromScale(0.5, 0.965),
			size = UDim2.fromScale(0.42, 0.16),
			anchor = Vector2.new(0.5, 1),
		},
		depth = 8,
		facing = {
			mode = "lookAtCamera",
			maxYawAngle = 0,
		},
		pivot = {
			point = Vector2.new(0.5, 1),
			rotation = CFrame.Angles(math.rad(10), 0, 0),
		},
		shadow = {
			depth = 0.12,
			scale = 0.08,
			maxOffset = 24,
		},
	})

	local frame = component:getFrame()
	styleFrame(frame, Color3.fromRGB(45, 94, 145))
	addLabel(frame, "Facet bottom panel", 0.18, 28)
	addLabel(frame, "yaw locked | bottom pivot | +10deg pitch", 0.52, 18)
	return component
end

local function createCornerPanel()
	local component = Facet.createComponent({
		name = "FacetCornerPanel",
		parent = getCamera(),
		guiParent = playerGui,
		screenRect = {
			position = UDim2.fromScale(0.985, 0.985),
			size = UDim2.fromScale(0.24, 0.22),
			anchor = Vector2.new(1, 1),
		},
		depth = 8,
		facing = {
			mode = "lookAtCamera",
			maxYawAngle = 0,
		},
		pivot = {
			point = Vector2.new(0.5, 1),
			rotation = CFrame.Angles(math.rad(14), 0, 0),
		},
	})

	local frame = component:getFrame()
	styleFrame(frame, Color3.fromRGB(102, 69, 139))
	addLabel(frame, "Corner", 0.18, 24)
	addLabel(frame, "anchor != pivot", 0.52, 18)
	addScreenAnchorMarker("FacetCornerAnchorMarker", UDim2.fromScale(0.985, 0.985))
	return component
end

local function createAnimatedScreenPanel()
	local screenRect = {
		position = UDim2.fromScale(0.31, 0.48),
		size = UDim2.fromScale(0.22, 0.18),
		anchor = Vector2.new(0.5, 0.5),
	}
	local pivot = {
		point = Vector2.new(0.5, 0.5),
		rotation = CFrame.new(),
	}
	local config = {
		name = "FacetAnimatedScreenPanel",
		parent = getCamera(),
		guiParent = playerGui,
		screenRect = screenRect,
		depth = 8,
		facing = {
			mode = "cameraPlane",
		},
		pivot = pivot,
	}
	local component = Facet.createComponent(config)

	local frame = component:getFrame()
	styleFrame(frame, Color3.fromRGB(154, 76, 92))
	addLabel(frame, "Screen Lock", 0.16, 24)
	addLabel(frame, "animated local rotation", 0.52, 17)

	table.insert(connections, RunService.RenderStepped:Connect(function()
		local clock = os.clock()
		local offsetX = math.sin(clock * 1.4) * 0.025
		local offsetY = math.cos(clock * 1.1) * 0.018
		local angle = math.sin(clock * 2) * 0.5 + 0.5

		screenRect.position = UDim2.fromScale(0.31 + offsetX, 0.48 + offsetY)
		pivot.rotation = CFrame.Angles(
			math.rad(-8 - angle * 8),
			math.rad(-18 + angle * 36),
			math.rad(-4 + angle * 8)
		)
		component:setConfig(config)
	end))

	return component
end

local function createControlsPanel()
	local component = Facet.createComponent({
		name = "FacetControlsPanel",
		parent = getCamera(),
		guiParent = playerGui,
		screenRect = {
			position = UDim2.fromScale(0.66, 0.48),
			size = UDim2.fromScale(0.28, 0.32),
			anchor = Vector2.new(0.5, 0.5),
		},
		depth = 8,
		facing = {
			mode = "cameraPlane",
		},
		pivot = {
			point = Vector2.new(0.5, 0.5),
			rotation = CFrame.Angles(math.rad(8), math.rad(-28), math.rad(2)),
		},
	})

	local frame = component:getFrame()
	styleFrame(frame, Color3.fromRGB(55, 59, 70))
	addLabel(frame, "Facet Controls", 0.05, 25)

	local autoButton = addButton(
		frame,
		"AutoSteppingButton",
		"",
		UDim2.fromScale(0.08, 0.30),
		UDim2.fromScale(0.40, 0.18)
	)
	local stepButton = addButton(
		frame,
		"StepButton",
		"Step Once",
		UDim2.fromScale(0.52, 0.30),
		UDim2.fromScale(0.40, 0.18)
	)

	local fovLabel = addLabel(frame, "FOV", 0.55, 18)
	fovLabel.TextXAlignment = Enum.TextXAlignment.Left

	local bar = Instance.new("Frame")
	bar.Name = "FOVSlider"
	bar.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
	bar.BorderSizePixel = 0
	bar.Position = UDim2.fromScale(0.08, 0.78)
	bar.Size = UDim2.fromScale(0.84, 0.06)
	bar.Parent = frame

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.fromRGB(109, 162, 224)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local knob = Instance.new("TextButton")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.AutoButtonColor = false
	knob.BackgroundColor3 = Color3.fromRGB(246, 248, 252)
	knob.BorderSizePixel = 0
	knob.Position = UDim2.fromScale(0, 0.5)
	knob.Size = UDim2.fromOffset(18, 18)
	knob.Text = ""
	knob.Parent = bar

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local sliderHitArea = Instance.new("Frame")
	sliderHitArea.Name = "SliderHitArea"
	sliderHitArea.BackgroundTransparency = 1
	sliderHitArea.BorderSizePixel = 0
	sliderHitArea.Position = UDim2.fromScale(0.08, 0.72)
	sliderHitArea.Size = UDim2.fromScale(0.84, 0.18)
	sliderHitArea.Active = true
	sliderHitArea.ZIndex = 12
	sliderHitArea.Parent = frame

	local dragging = false
	local function updateAutoButton(enabled: boolean)
		autoButton.Text = if enabled then "Auto Step: ON" else "Auto Step: OFF"
	end
	local function updateSliderFromScreenPosition(screenPosition: Vector3)
		local surfaceGui = component:getSurfaceGui()
		local screenPosition2 = Vector2.new(screenPosition.X, screenPosition.Y)
		local alpha = getSliderAlphaFromProjectedLine(surfaceGui, bar, screenPosition2)
		if not alpha then
			local canvasPosition = getCanvasPositionFromPointer(surfaceGui, screenPosition)
			local canvasX = if canvasPosition then canvasPosition.X else screenPosition.X
			alpha = getSliderAlpha(bar, canvasX)
		end
		setCameraFovFromAlpha(alpha, fovLabel, fill, knob)
	end
	local function getPointerScreenPosition(input: InputObject): Vector3
		if input.UserInputType == Enum.UserInputType.Touch then
			return input.Position
		end

		local mouseLocation = UserInputService:GetMouseLocation()
		return Vector3.new(mouseLocation.X, mouseLocation.Y, 0)
	end
	local function isPointerInput(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end

	table.insert(connections, autoButton.Activated:Connect(function()
		setAutoStepping(not autoStepping)
	end))
	table.insert(connections, stepButton.Activated:Connect(function()
		Facet.step(getCamera())
	end))
	table.insert(connections, sliderHitArea.InputBegan:Connect(function(input)
		if not isPointerInput(input) then
			return
		end
		dragging = true
		updateSliderFromScreenPosition(getPointerScreenPosition(input))
	end))
	table.insert(connections, knob.InputBegan:Connect(function(input)
		if not isPointerInput(input) then
			return
		end
		dragging = true
		updateSliderFromScreenPosition(getPointerScreenPosition(input))
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		updateSliderFromScreenPosition(getPointerScreenPosition(input))
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if isPointerInput(input) then
			dragging = false
		end
	end))

	table.insert(autoSteppingChangedCallbacks, updateAutoButton)
	updateAutoButton(autoStepping)
	setCameraFovFromAlpha((getCamera().FieldOfView - FOV_MIN) / (FOV_MAX - FOV_MIN), fovLabel, fill, knob)
	return component
end

local components = {
	createBottomPanel(),
	createCornerPanel(),
	createAnimatedScreenPanel(),
	createControlsPanel(),
}

setAutoStepping = function(enabled: boolean)
	if autoStepping == enabled then
		return
	end

	autoStepping = enabled
	if enabled then
		Facet.startAutoStepping()
	else
		Facet.stopAutoStepping()
	end
	notifyAutoSteppingChanged()
end

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.M then
		setAutoStepping(not autoStepping)
	elseif input.KeyCode == Enum.KeyCode.N and not autoStepping then
		Facet.step(getCamera())
	end
end))

player.AncestryChanged:Connect(function()
	if player.Parent then
		return
	end
	for _, component in components do
		component:deconstruct()
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	for _, instance in cleanupInstances do
		instance:Destroy()
	end
	table.clear(connections)
	table.clear(cleanupInstances)
	table.clear(autoSteppingChangedCallbacks)
end)
