--!strict
--!optimize 2
--!native

local FacetClient = require(script.services.facetClient.client.facetClientClient)
local Math = require(script.math)
local Types = require(script.types)

type Component3DConfig = Types.Component3DConfig
type Component3DHandle = Types.Component3DHandle
type FacetClientHandle = Types.FacetClientHandle
type FacetManagerHandle = Types.FacetManagerHandle

local client = FacetClient.new()

return {
	client = client :: FacetClientHandle,
	math = Math,

	createComponent = function(config: Component3DConfig): Component3DHandle
		return client:createComponent(config)
	end,

	getManager = function(): FacetManagerHandle
		return client:getManager() :: FacetManagerHandle
	end,

	setAutoSteppingEnabled = function(enabled: boolean)
		client:setAutoSteppingEnabled(enabled)
	end,

	startAutoStepping = function()
		client:startAutoStepping()
	end,

	stopAutoStepping = function()
		client:stopAutoStepping()
	end,

	step = function(camera: Camera?)
		client:step(camera)
	end,

	deconstruct = function()
		client:deconstruct()
	end,
}
