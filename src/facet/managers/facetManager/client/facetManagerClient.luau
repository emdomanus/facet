--!strict
--!optimize 2
--!native

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Component3D = require(script.Parent.Parent.Parent.Parent.components.component3d.client.component3dClient)
local Types = require(script.Parent.Parent.Parent.Parent.types.managers.facetManager)

type Component3DComplete = Types.Component3DComplete
type Component3DConfig = Types.Component3DConfig
type Component3DHandle = Types.Component3DHandle
type FacetManagerComplete = Types.FacetManagerComplete

local FacetManager = {}
FacetManager.__index = FacetManager

function FacetManager.new(): FacetManagerComplete
	local self: FacetManagerComplete = setmetatable({} :: any, FacetManager)
	self._components = {}
	self._renderConnection = nil
	self._autoSteppingEnabled = true
	return self
end

function FacetManager.createComponent(self: FacetManagerComplete, config: Component3DConfig): Component3DHandle
	local component = Component3D.new(config, self)
	if config.visible ~= false then
		component:setEnabled(true)
	end
	return component
end

function FacetManager.register(self: FacetManagerComplete, component: Component3DComplete)
	self._components[component] = true
	self:_syncRenderBinding()
end

function FacetManager.unregister(self: FacetManagerComplete, component: Component3DComplete)
	self._components[component] = nil
	self:_syncRenderBinding()
end

function FacetManager.setAutoSteppingEnabled(self: FacetManagerComplete, enabled: boolean)
	self._autoSteppingEnabled = enabled
	self:_syncRenderBinding()
end

function FacetManager.isAutoSteppingEnabled(self: FacetManagerComplete): boolean
	return self._autoSteppingEnabled
end

function FacetManager.startAutoStepping(self: FacetManagerComplete)
	self:setAutoSteppingEnabled(true)
end

function FacetManager.stopAutoStepping(self: FacetManagerComplete)
	self:setAutoSteppingEnabled(false)
end

function FacetManager._bind(self: FacetManagerComplete)
	if self._renderConnection then
		return
	end
	self._renderConnection = RunService.RenderStepped:Connect(function()
		self:step()
	end)
end

function FacetManager._unbind(self: FacetManagerComplete)
	if not self._renderConnection then
		return
	end
	self._renderConnection:Disconnect()
	self._renderConnection = nil
end

function FacetManager._syncRenderBinding(self: FacetManagerComplete)
	if self._autoSteppingEnabled and next(self._components) ~= nil then
		self:_bind()
	else
		self:_unbind()
	end
end

function FacetManager.step(self: FacetManagerComplete, camera: Camera?)
	camera = camera or Workspace.CurrentCamera
	for component in self._components do
		component:_update(camera)
	end
end

function FacetManager.deconstruct(self: FacetManagerComplete)
	local components = {}
	for component in self._components do
		table.insert(components, component)
	end
	for _, component in components do
		component:deconstruct()
	end
	self:_unbind()
	table.clear(self._components)
end

return FacetManager
