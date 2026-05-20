--!strict
--!optimize 2
--!native

local Facet = require(script.facet)
local Types = require(script.facet.types)

export type Component3DHandle = Types.Component3DHandle
export type Component3DConfig = Types.Component3DConfig
export type Component3DComplete = Types.Component3DComplete
export type FacetClientHandle = Types.FacetClientHandle
export type FacetClientComplete = Types.FacetClientComplete
export type FacetManagerHandle = Types.FacetManagerHandle
export type FacetManagerComplete = Types.FacetManagerComplete

export type ScreenRectConfig = Types.ScreenRectConfig
export type FacingConfig = Types.FacingConfig
export type FacingMode = Types.FacingMode
export type PivotConfig = Types.PivotConfig
export type ShadowConfig = Types.ShadowConfig
export type ShadowSolveResult = Types.ShadowSolveResult

return Facet
