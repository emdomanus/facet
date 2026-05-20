--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.types.math)

type PivotConfig = Types.PivotConfig

local Pivot = {}

function Pivot.rotateAbout(cframe: CFrame, pivot: CFrame, rotation: CFrame): CFrame
	return pivot * rotation * pivot:Inverse() * cframe
end

function Pivot.apply(cframe: CFrame, worldSize: Vector3, config: PivotConfig?): CFrame
	if not config or not config.rotation then
		return cframe
	end

	local point = config.point or Vector2.new(0.5, 0.5)
	local pivot = cframe * CFrame.new(
		(0.5 - point.X) * worldSize.X,
		(0.5 - point.Y) * worldSize.Y,
		0
	)
	return Pivot.rotateAbout(cframe, pivot, config.rotation)
end

return Pivot
