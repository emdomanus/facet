--!strict
--!optimize 2
--!native

export type FacingMode = "cameraPlane" | "lookAtCamera" | "lookAtPoint" | "manual"

export type ScreenRectConfig = {
	position: UDim2,
	size: UDim2,
	anchor: Vector2,
}

export type FacingConfig = {
	mode: FacingMode?,
	lookAtPoint: Vector3?,
	manualCFrame: CFrame?,
	rotation: CFrame?,
	maxYawAngle: number?,
	maxPitchAngle: number?,
	manualYawAngle: number?,
	manualPitchAngle: number?,
	manualRollAngle: number?,
}

export type PivotConfig = {
	point: Vector2?,
	rotation: CFrame?,
}

export type ShadowConfig = {
	depth: number?,
	scale: number?,
	maxOffset: number?,
}

export type ShadowSolveResult = {
	offset: Vector2,
	direction: Vector2,
	strength: number,
}

return {}
