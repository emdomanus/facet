--!strict
--!optimize 2
--!native

local MathTypes = require(script.Parent.Parent.math)

export type ScreenRectConfig = MathTypes.ScreenRectConfig
export type FacingConfig = MathTypes.FacingConfig
export type PivotConfig = MathTypes.PivotConfig
export type ShadowConfig = MathTypes.ShadowConfig
export type ShadowSolveResult = MathTypes.ShadowSolveResult

export type Component3DConfig = {
	name: string?,
	parent: Instance?,
	guiParent: Instance?,
	screenRect: ScreenRectConfig,
	depth: number?,
	canvasSize: Vector2?,
	zOffset: number?,
	visible: boolean?,
	facing: FacingConfig?,
	pivot: PivotConfig?,
	shadow: ShadowConfig?,
}

export type Component3DHandle = {
	getFrame: (self: Component3DHandle) -> Frame,
	getSurfaceGui: (self: Component3DHandle) -> SurfaceGui,
	getShadow: (self: Component3DHandle) -> ShadowSolveResult,
	setEnabled: (self: Component3DHandle, enabled: boolean) -> (),
	isEnabled: (self: Component3DHandle) -> boolean,
	setConfig: (self: Component3DHandle, config: Component3DConfig) -> (),
	deconstruct: (self: Component3DHandle) -> (),
}

export type Component3DComplete = Component3DHandle & {
	_manager: any?,
	_part: Part,
	_surfaceGui: SurfaceGui,
	_frame: Frame,
	_config: Component3DConfig,
	_enabled: boolean,
	_shadow: ShadowSolveResult,

	_update: (self: Component3DComplete, camera: Camera?) -> (),
	_setParent: (self: Component3DComplete, parent: Instance?) -> (),
}

return {}
