--!strict
--!optimize 2
--!native

local MathTypes = require(script.math)
local Component3DTypes = require(script.components.component3d)
local FacetManagerTypes = require(script.managers.facetManager)
local FacetClientTypes = require(script.services.facetClient)

--[[
	Public re-export surface. Exports handle and helper/config types only.
	Require types/components, types/managers, or types/services directly when
	the full internal complete type with private state is needed.
]]

export type FacingMode = MathTypes.FacingMode
export type ScreenRectConfig = MathTypes.ScreenRectConfig
export type FacingConfig = MathTypes.FacingConfig
export type PivotConfig = MathTypes.PivotConfig
export type ShadowConfig = MathTypes.ShadowConfig
export type ShadowSolveResult = MathTypes.ShadowSolveResult
export type ShadowChangedCallback = Component3DTypes.ShadowChangedCallback
export type Disconnect = Component3DTypes.Disconnect

export type Component3DConfig = Component3DTypes.Component3DConfig
export type Component3DHandle = Component3DTypes.Component3DHandle

export type FacetManagerHandle = FacetManagerTypes.FacetManagerHandle

export type FacetClientHandle = FacetClientTypes.FacetClientHandle

return {}
