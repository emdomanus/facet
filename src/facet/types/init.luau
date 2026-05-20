--!strict
--!optimize 2
--!native

local MathTypes = require(script.math)
local Component3DTypes = require(script.components.component3d)
local FacetManagerTypes = require(script.managers.facetManager)
local FacetClientTypes = require(script.services.facetClient)

export type FacingMode = MathTypes.FacingMode
export type ScreenRectConfig = MathTypes.ScreenRectConfig
export type FacingConfig = MathTypes.FacingConfig
export type PivotConfig = MathTypes.PivotConfig
export type ShadowConfig = MathTypes.ShadowConfig
export type ShadowSolveResult = MathTypes.ShadowSolveResult

export type Component3DConfig = Component3DTypes.Component3DConfig
export type Component3DHandle = Component3DTypes.Component3DHandle
export type Component3DComplete = Component3DTypes.Component3DComplete

export type FacetManagerHandle = FacetManagerTypes.FacetManagerHandle
export type FacetManagerComplete = FacetManagerTypes.FacetManagerComplete

export type FacetClientHandle = FacetClientTypes.FacetClientHandle
export type FacetClientComplete = FacetClientTypes.FacetClientComplete

return {}
