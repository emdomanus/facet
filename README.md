# Facet

Client-side 3D UI surface primitives for Roblox.

Facet turns screen-space UI regions into camera-aware 3D `SurfaceGui` planes.
It is meant to stay small: lifecycle, component surfaces, projection math,
facing, pivot rotation, and shadow solving.

## Shape

```text
src/init.luau
src/facet/
  services/facetClient/client/facetClientClient.luau
  managers/facetManager/client/facetManagerClient.luau
  components/component3d/client/component3dClient.luau
  math/
  types/
```

The public package exposes handle types. Complete/internal shapes are exported
for adapters and package internals, but normal callers should hold handles.

## Quick Use

```luau
local Facet = require(Packages.Facet)

local component = Facet.createComponent({
    name = "BottomHud",
    parent = workspace.CurrentCamera,
    guiParent = game.Players.LocalPlayer.PlayerGui,
    screenRect = {
        position = UDim2.fromScale(0.5, 1),
        size = UDim2.fromScale(0.54, 0.235),
        anchor = Vector2.new(0.5, 1),
    },
    facing = {
        mode = "lookAtCamera",
        maxYawAngle = 0,
    },
    pivot = {
        point = Vector2.new(0.5, 1),
        rotation = CFrame.Angles(math.rad(8), 0, 0),
    },
})

local frame = component:getFrame()
```

## Build

```powershell
aftman install
wally install
rojo build default.project.json -o facet.rbxm
```

## Dev Harness

`dev.project.json` mounts Facet plus a Rojo-only client demo under
`StarterPlayerScripts`. It is excluded from the Wally package.

```powershell
rojo serve dev.project.json
```

In Studio, the demo includes a center-right angled control panel with an auto
stepping toggle, one-step button, and FOV slider. Press `M` to toggle manual
stepping and `N` to step once while manual stepping is active.
