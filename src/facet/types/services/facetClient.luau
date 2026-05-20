--!strict
--!optimize 2
--!native

local Component3DTypes = require(script.Parent.Parent.components.component3d)
local FacetManagerTypes = require(script.Parent.Parent.managers.facetManager)

export type Component3DConfig = Component3DTypes.Component3DConfig
export type Component3DHandle = Component3DTypes.Component3DHandle
export type FacetManagerHandle = FacetManagerTypes.FacetManagerHandle
export type FacetManagerComplete = FacetManagerTypes.FacetManagerComplete

export type FacetClientHandle = {
	createComponent: (self: FacetClientHandle, config: Component3DConfig) -> Component3DHandle,
	getManager: (self: FacetClientHandle) -> FacetManagerHandle,
	setAutoSteppingEnabled: (self: FacetClientHandle, enabled: boolean) -> (),
	isAutoSteppingEnabled: (self: FacetClientHandle) -> boolean,
	startAutoStepping: (self: FacetClientHandle) -> (),
	stopAutoStepping: (self: FacetClientHandle) -> (),
	step: (self: FacetClientHandle, camera: Camera?) -> (),
	deconstruct: (self: FacetClientHandle) -> (),
}

export type FacetClientComplete = FacetClientHandle & {
	_manager: FacetManagerComplete,
}

return {}
