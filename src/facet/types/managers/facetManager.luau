--!strict
--!optimize 2
--!native

local Component3DTypes = require(script.Parent.Parent.components.component3d)

export type Component3DConfig = Component3DTypes.Component3DConfig
export type Component3DHandle = Component3DTypes.Component3DHandle
export type Component3DComplete = Component3DTypes.Component3DComplete

export type FacetManagerHandle = {
	createComponent: (self: FacetManagerHandle, config: Component3DConfig) -> Component3DHandle,
	register: (self: FacetManagerHandle, component: Component3DComplete) -> (),
	unregister: (self: FacetManagerHandle, component: Component3DComplete) -> (),
	setAutoSteppingEnabled: (self: FacetManagerHandle, enabled: boolean) -> (),
	isAutoSteppingEnabled: (self: FacetManagerHandle) -> boolean,
	startAutoStepping: (self: FacetManagerHandle) -> (),
	stopAutoStepping: (self: FacetManagerHandle) -> (),
	step: (self: FacetManagerHandle, camera: Camera?) -> (),
	deconstruct: (self: FacetManagerHandle) -> (),
}

export type FacetManagerComplete = FacetManagerHandle & {
	_components: { [Component3DComplete]: true },
	_renderConnection: RBXScriptConnection?,
	_autoSteppingEnabled: boolean,

	_bind: (self: FacetManagerComplete) -> (),
	_unbind: (self: FacetManagerComplete) -> (),
	_syncRenderBinding: (self: FacetManagerComplete) -> (),
}

return {}
