--!strict
--!optimize 2
--!native

local FacetManager = require(script.Parent.Parent.Parent.Parent.managers.facetManager.client.facetManagerClient)
local Types = require(script.Parent.Parent.Parent.Parent.types.services.facetClient)

type Component3DConfig = Types.Component3DConfig
type Component3DHandle = Types.Component3DHandle
type FacetClientComplete = Types.FacetClientComplete
type FacetManagerHandle = Types.FacetManagerHandle

local FacetClient = {}
FacetClient.__index = FacetClient

function FacetClient.new(): FacetClientComplete
	local self: FacetClientComplete = setmetatable({} :: any, FacetClient)
	self._manager = FacetManager.new()
	return self
end

function FacetClient.createComponent(self: FacetClientComplete, config: Component3DConfig): Component3DHandle
	return self._manager:createComponent(config)
end

function FacetClient.getManager(self: FacetClientComplete): FacetManagerHandle
	return self._manager
end

function FacetClient.setAutoSteppingEnabled(self: FacetClientComplete, enabled: boolean)
	self._manager:setAutoSteppingEnabled(enabled)
end

function FacetClient.isAutoSteppingEnabled(self: FacetClientComplete): boolean
	return self._manager:isAutoSteppingEnabled()
end

function FacetClient.startAutoStepping(self: FacetClientComplete)
	self._manager:startAutoStepping()
end

function FacetClient.stopAutoStepping(self: FacetClientComplete)
	self._manager:stopAutoStepping()
end

function FacetClient.step(self: FacetClientComplete, camera: Camera?)
	self._manager:step(camera)
end

function FacetClient.deconstruct(self: FacetClientComplete)
	self._manager:deconstruct()
end

return FacetClient
