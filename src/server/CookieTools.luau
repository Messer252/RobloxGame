local Assets = require(script.Parent.AssetLibrary)
local Packaging = require(script.Parent.CookiePackaging)
local Tools = {}
function Tools.pin(player, level, onSwing)
	local tool = Instance.new("Tool")
	tool.Name, tool.CanBeDropped = "Rolling Pin " .. level, false
	local handle = Instance.new("Part")
	handle.Name, handle.Shape, handle.Size, handle.Material, handle.Color = "Handle", Enum.PartType.Cylinder, Vector3.new(4, 0.65, 0.65), Enum.Material.Wood, Color3.fromRGB(166 + level * 8, 111, 63)
	handle.CanCollide, handle.Massless, handle.Parent = false, true, tool
	for _, x in ipairs({ -2.35, 2.35 }) do
		local grip = Instance.new("Part")
		grip.Name, grip.Shape, grip.Size, grip.CFrame, grip.Color = "Rolling Pin Grip", Enum.PartType.Cylinder, Vector3.new(0.8, 0.3, 0.3), CFrame.new(x, 0, 0), Color3.fromRGB(96, 62, 36)
		grip.CanCollide, grip.Massless, grip.Parent = false, true, tool
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = handle, grip, grip
	end
	tool.Grip = CFrame.Angles(0, 0, math.pi / 2)
	local idle, swinging = tool.Grip, false
	tool.Activated:Connect(function()
		if swinging or tool.Parent ~= player.Character then return end
		swinging = true
		local tween = game:GetService("TweenService")
		tween:Create(tool, TweenInfo.new(0.1), { Grip = idle * CFrame.Angles(-1.1, 0, 0) }):Play()
		task.delay(0.1, function()
			if tool.Parent == player.Character then
				tween:Create(tool, TweenInfo.new(0.12), { Grip = idle * CFrame.Angles(0.9, 0, 0) }):Play()
				onSwing()
			end
		end)
		task.delay(0.3, function() if tool.Parent then tween:Create(tool, TweenInfo.new(0.12), { Grip = idle }):Play() end end)
		task.delay(0.5, function() swinging = false end)
	end)
	tool.Parent = player:FindFirstChildOfClass("Backpack")
	return tool
end
function Tools.bag(player, onOpen)
	local tool = Instance.new("Tool")
	tool.Name, tool.ToolTip, tool.RequiresHandle, tool.CanBeDropped = "Cookie Bag", "Open your cookie inventory", false, false
	tool:SetAttribute("CookieBag", true)
	tool.Equipped:Connect(function()
		onOpen()
		task.defer(function()
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum and tool.Parent == player.Character then hum:UnequipTools() end
		end)
	end)
	tool.Parent = player:FindFirstChildOfClass("Backpack")
	return tool
end
function Tools.cookie(player, cookie, onHeld, onEat)
	local tool = Instance.new("Tool")
	tool.Name, tool.CanBeDropped = "Cookie: " .. require(game:GetService("ReplicatedStorage").CookieTycoon.Recipes)[cookie.recipe].Name, false
	tool:SetAttribute("InventoryCookieId", cookie.id)
	local handle = Instance.new("Part")
	handle.Name, handle.Size, handle.Transparency, handle.CanCollide, handle.Massless, handle.Parent = "Handle", Vector3.new(0.3, 0.3, 0.3), 1, false, true, tool
	local flags = require(game:GetService("ReplicatedStorage").CookieTycoon.CookieCrafting).decode(cookie.mask)
	local model = Assets.cookie(cookie.recipe, tool, CFrame.new(), flags)
	model:ScaleTo(0.6)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored, part.CanCollide, part.CanTouch, part.Massless = false, false, false, true
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = handle, part, handle
		end
	end
	if cookie.wrapped then Packaging.wrap(model, handle, 0.6) end
	if cookie.boxed then Packaging.box(model, handle, 0.6) end
	tool.Equipped:Connect(function() onHeld(cookie.id) end)
	tool.Unequipped:Connect(function() onHeld(nil) end)
	tool.Activated:Connect(onEat)
	tool.Parent = player:FindFirstChildOfClass("Backpack")
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:EquipTool(tool) end
	return tool
end
return Tools
