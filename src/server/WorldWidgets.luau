local W = {}
function W.part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position, p.Color = name, size, position, color
	p.Material, p.Anchored, p.TopSurface, p.BottomSurface = material or Enum.Material.SmoothPlastic, true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
function W.label(target, text, distance)
	local gui = Instance.new("BillboardGui")
	gui.Size, gui.StudsOffset, gui.MaxDistance, gui.Parent = UDim2.fromOffset(190, 45), Vector3.new(0, 3, 0), distance or 40, target
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundColor3, label.BackgroundTransparency = UDim2.fromScale(1, 1), Color3.fromRGB(54, 39, 32), 0.12
	label.TextColor3, label.TextWrapped, label.Font, label.TextSize, label.Text, label.Parent = Color3.fromRGB(255, 235, 202), true, Enum.Font.GothamBold, 14, text, gui
	return label
end
function W.near(player, point, distance)
	local char = player.Character
	local root, hum = char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChildOfClass("Humanoid")
	return root ~= nil and hum ~= nil and hum.Health > 0 and (root.Position - point).Magnitude <= (distance or 12)
end
function W.prompt(target, text, hold, callback)
	local p = Instance.new("ProximityPrompt")
	p.ActionText, p.ObjectText, p.HoldDuration, p.MaxActivationDistance, p.RequiresLineOfSight = text, target.Name, hold or 0, 9, false
	p.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
	p.Parent = target
	p.Triggered:Connect(function(player) if W.near(player, target.Position) then callback(player) end end)
	return p
end
function W.position(plot, x, y, z)
	return plot.origin + Vector3.new(x * (plot.mirrorX or 1), y, z * plot.direction)
end
return W
