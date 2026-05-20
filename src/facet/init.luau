--!strict
--!optimize 2
--!native

local FacetClient = require(script.services.facetClient.client.facetClientClient)
local Math = require(script.math)

local client = FacetClient.new()

return {
	client = client,
	math = Math,

	createComponent = function(config)
		return client:createComponent(config)
	end,

	getManager = function()
		return client:getManager()
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
