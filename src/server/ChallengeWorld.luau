-- Original part-built NPC and treasures. All discovery callbacks originate
-- from alive characters beside the actual server-owned item, never a client ID.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.CookieTycoon.ChallengeCatalog)
local ChallengeWorld = {}
local npcRoot = nil
local cooldowns = setmetatable({}, { __mode = "k" })
local cream = Color3.fromRGB(255, 243, 218)
local cocoa = Color3.fromRGB(83, 56, 43)

local function rgb(value) return Color3.fromRGB(value[1], value[2], value[3]) end

local function piece(parent, name, size, frame, tint, shape, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.CFrame = frame
	object.Color = tint
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Material = material or Enum.Material.SmoothPlastic
	if shape then object.Shape = shape end
	object.Parent = parent
	return object
end

local function aliveNear(player, target, distance)
	if not target or not target.Parent then return false end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return humanoid ~= nil and humanoid.Health > 0 and root ~= nil and root:IsA("BasePart")
		and (root.Position - target.Position).Magnitude <= distance
end

local function available(player)
	local now = os.clock()
	if now < (cooldowns[player] or 0) then return false end
	cooldowns[player] = now + 0.3
	return true
end

local function interaction(target, action, name, callback)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ChallengePrompt"
	prompt.ActionText = action
	prompt.ObjectText = name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = target
	prompt.Triggered:Connect(function(player)
		if aliveNear(player, target, 12) and available(player) then callback(player) end
	end)
	return prompt
end

local function createNPC(parent, onTalk)
	local model = Instance.new("Model")
	model.Name = Catalog.NPCName
	model.Parent = parent
	local pos = Catalog.NPCPosition
	local base = CFrame.new(pos[1], pos[2], pos[3])
	local function add(name, size, x, y, z, tint, shape, rotation)
		return piece(model, name, size, base * CFrame.new(x, y, z) * (rotation or CFrame.new()), tint, shape)
	end
	npcRoot = add("HumanoidRootPart", Vector3.new(2, 2, 1), 0, 2.7, 0, cream)
	npcRoot.Transparency = 1
	model.PrimaryPart = npcRoot
	local apron = Color3.fromRGB(143, 182, 162)
	local skin = Color3.fromRGB(221, 170, 116)
	add("Left Boot", Vector3.new(0.7, 0.6, 1), -0.47, 0.45, 0.15, cocoa)
	add("Right Boot", Vector3.new(0.7, 0.6, 1), 0.47, 0.45, 0.15, cocoa)
	add("Left Leg", Vector3.new(0.65, 1.3, 0.7), -0.47, 1.25, 0, cocoa)
	add("Right Leg", Vector3.new(0.65, 1.3, 0.7), 0.47, 1.25, 0, cocoa)
	add("Chef Shirt", Vector3.new(2.1, 2.0, 1.1), 0, 2.6, 0, cream)
	add("Apron", Vector3.new(1.5, 1.7, 0.12), 0, 2.42, 0.61, apron)
	add("Apron Pocket", Vector3.new(0.75, 0.45, 0.15), 0, 2.15, 0.72, Color3.fromRGB(114, 158, 137))
	add("Left Sleeve", Vector3.new(0.65, 1.3, 0.75), -1.35, 2.8, 0, cream)
	add("Left Hand", Vector3.new(0.6, 0.65, 0.6), -1.35, 1.9, 0, skin, Enum.PartType.Ball)
	add("Waving Sleeve", Vector3.new(0.65, 1.3, 0.75), 1.4, 3.0, 0, cream, nil, CFrame.Angles(0, 0, math.rad(-35)))
	add("Waving Hand", Vector3.new(0.65, 0.65, 0.65), 1.85, 3.8, 0, skin, Enum.PartType.Ball)
	add("Head", Vector3.new(1.7, 1.7, 1.6), 0, 4.4, 0, skin, Enum.PartType.Ball)
	for _, x in ipairs({ -0.32, 0.32 }) do
		add("Eye", Vector3.new(0.14, 0.2, 0.08), x, 4.55, 0.77, cocoa, Enum.PartType.Ball)
		add("Blush", Vector3.new(0.3, 0.16, 0.05), x * 1.6, 4.22, 0.72, Color3.fromRGB(224, 142, 119), Enum.PartType.Ball)
	end
	add("Smile", Vector3.new(0.35, 0.09, 0.07), 0, 4.12, 0.79, cocoa)
	add("Chef Hat Band", Vector3.new(0.35, 1.8, 1.8), 0, 5.2, 0, cream, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.pi / 2))
	for _, x in ipairs({ -0.5, 0, 0.5 }) do
		add("Chef Hat Puff", Vector3.new(1.15, 1.1, 1.1), x, 5.67, 0, cream, Enum.PartType.Ball)
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BakerName"
	billboard.Size = UDim2.fromOffset(190, 50)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.MaxDistance = 55
	billboard.Parent = npcRoot
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = Catalog.NPCName .. "\nHunts & cash rewards"
	text.TextColor3 = cream
	text.TextStrokeColor3 = cocoa
	text.TextStrokeTransparency = 0.15
	text.Font = Enum.Font.GothamBold
	text.TextSize = 16
	text.Parent = billboard
	interaction(npcRoot, "Talk", Catalog.NPCName, onTalk)
	return model
end

local function createTreasure(parent, itemId, questIndex, onFound)
	local item = Catalog.Items[itemId]
	local model = Instance.new("Model")
	model.Name = item.Name
	model:SetAttribute("ChallengeItemId", itemId)
	model:SetAttribute("ChallengeQuestIndex", questIndex)
	model.Parent = parent
	local pos = item.Position
	local base = CFrame.new(pos[1], pos[2], pos[3]) * CFrame.Angles(0, math.rad(18 * questIndex), 0)
	local tint = rgb(item.Color)
	local function add(name, size, x, y, z, shade, shape, rotation, material)
		return piece(model, name, size, base * CFrame.new(x, y, z) * (rotation or CFrame.new()), shade or tint, shape, material)
	end
	local root = add("ItemRoot", Vector3.new(1, 1, 1), 0, 0, 0)
	root.Transparency = 1
	model.PrimaryPart = root
	local vertical = CFrame.Angles(0, 0, math.pi / 2)
	if item.Kind == "Spoon" then
		add("Spoon Handle", Vector3.new(0.25, 0.16, 2.0), 0, 0, -0.5, tint, nil, nil, Enum.Material.Metal)
		add("Spoon Bowl", Vector3.new(1, 0.22, 1.2), 0, 0, 0.9, tint, Enum.PartType.Ball, nil, Enum.Material.Metal)
	elseif item.Kind == "Cube" then
		add("Sugar", Vector3.new(1.45, 1.45, 1.45), 0, 0, 0, tint, nil, nil, Enum.Material.Sand)
		for index = 1, 5 do add("Sugar Crystal", Vector3.new(0.18, 0.12, 0.2), (index % 3 - 1) * 0.4, 0.76, (index % 2 - 0.5) * 0.6, cream) end
	elseif item.Kind == "Whisk" then
		add("Pink Handle", Vector3.new(0.4, 0.4, 1.4), 0, 0, -0.7)
		for index = -1, 1 do
			add("Whisk Wire", Vector3.new(0.12, 0.12, 1.3), index * 0.3, 0, 0.45, cream, nil, CFrame.Angles(0, math.rad(index * 18), 0), Enum.Material.Metal)
		end
		add("Whisk Tip", Vector3.new(0.7, 0.12, 0.13), 0, 0, 1.1, cream, nil, nil, Enum.Material.Metal)
	elseif item.Kind == "RollingPin" then
		add("Rolling Pin Body", Vector3.new(2.2, 0.9, 0.9), 0, 0, 0, tint, Enum.PartType.Cylinder, nil, Enum.Material.Wood)
		for _, x in ipairs({ -1.45, 1.45 }) do add("Handle", Vector3.new(0.7, 0.35, 0.35), x, 0, 0, cocoa, Enum.PartType.Cylinder, nil, Enum.Material.Wood) end
	elseif item.Kind == "Tin" then
		add("Tin", Vector3.new(1.3, 1.7, 1.7), 0, 0, 0, tint, Enum.PartType.Cylinder, vertical, Enum.Material.Metal)
		add("Tin Lid", Vector3.new(0.16, 1.9, 1.9), 0, 0.72, 0, cream, Enum.PartType.Cylinder, vertical, Enum.Material.Metal)
		add("Cookie Emblem", Vector3.new(0.1, 0.65, 0.65), 0, 0.84, 0, Color3.fromRGB(202, 155, 98), Enum.PartType.Cylinder, vertical)
	elseif item.Kind == "Star" then
		for index = 0, 4 do
			add("Star Cutter Point", Vector3.new(0.32, 0.25, 1.6), 0, 0, 0, tint, nil, CFrame.Angles(0, math.rad(index * 72), 0), Enum.Material.Metal)
		end
	elseif item.Kind == "Jar" or item.Kind == "Bottle" then
		add("Bottle Body", Vector3.new(1.5, 1.25, 1.25), 0, 0, 0, tint, Enum.PartType.Cylinder, vertical)
		add("Cream Label", Vector3.new(0.8, 0.65, 0.1), 0, -0.05, 0.65, cream)
		add("Lid", Vector3.new(0.25, 0.9, 0.9), 0, 0.85, 0, cocoa, Enum.PartType.Cylinder, vertical)
		if item.Kind == "Jar" then
			for index, shade in ipairs({ tint, Color3.fromRGB(146, 184, 157), Color3.fromRGB(236, 191, 91) }) do
				add("Sprinkle", Vector3.new(0.1, 0.3, 0.1), (index - 2) * 0.24, 0, 0.72, shade, nil, CFrame.Angles(0, 0, index * 0.3))
			end
		end
	elseif item.Kind == "Mitten" then
		add("Oven Mitt", Vector3.new(1.4, 0.45, 2), 0, 0, 0, tint, Enum.PartType.Ball, nil, Enum.Material.Fabric)
		add("Thumb", Vector3.new(0.8, 0.4, 0.8), 0.7, 0, 0, tint, Enum.PartType.Ball, nil, Enum.Material.Fabric)
		add("Cuff", Vector3.new(1.25, 0.35, 0.35), 0, 0, -0.8, cream, nil, nil, Enum.Material.Fabric)
	elseif item.Kind == "Cup" then
		add("Cup", Vector3.new(1.4, 1.5, 1.3), 0, 0, 0)
		for index = 1, 3 do add("Measuring Mark", Vector3.new(index * 0.18 + 0.1, 0.07, 0.07), -0.3, index * 0.32 - 0.7, 0.67, cocoa) end
		add("Handle Top", Vector3.new(0.8, 0.16, 0.3), 1, 0.55, 0, cream)
		add("Handle Side", Vector3.new(0.16, 1.1, 0.3), 1.35, 0, 0, cream)
		add("Handle Bottom", Vector3.new(0.8, 0.16, 0.3), 1, -0.55, 0, cream)
	elseif item.Kind == "Book" then
		add("Book Cover", Vector3.new(2.1, 0.45, 1.65), 0, 0, 0)
		add("Pages", Vector3.new(1.9, 0.3, 1.5), 0, 0.08, 0, cream)
		add("Top Cover", Vector3.new(2.1, 0.08, 1.65), 0, 0.29, 0)
		add("Golden Bookmark", Vector3.new(0.3, 0.08, 1.8), 0.5, 0.35, 0, Color3.fromRGB(241, 193, 96))
	else
		add("Golden Chip", Vector3.new(1.6, 1.3, 1.6), 0, 0, 0, tint, Enum.PartType.Ball, nil, Enum.Material.Metal)
		add("Chocolate Tip", Vector3.new(0.7, 0.7, 0.7), 0, 0.65, 0, cocoa, Enum.PartType.Ball)
	end
	local light = Instance.new("PointLight")
	light.Name = "TreasureGlow"
	light.Color = cream
	light.Brightness = 0.15
	light.Range = 4
	light.Parent = root
	interaction(root, "Find", item.Name, function(player) onFound(player, itemId) end)
	return model
end

function ChallengeWorld.IsNearNPC(player)
	return aliveNear(player, npcRoot, 12)
end

function ChallengeWorld.create(parent, onTalk, onFound)
	local folder = Instance.new("Folder")
	folder.Name = "Challenges"
	folder.Parent = parent
	local npc = createNPC(folder, onTalk)
	local items = Instance.new("Folder")
	items.Name = "HiddenItems"
	items.Parent = folder
	for questIndex, quest in ipairs(Catalog.Challenges) do
		for _, itemId in ipairs(quest.Items) do createTreasure(items, itemId, questIndex, onFound) end
	end
	return { model = folder, npc = npc, npcRoot = npcRoot }
end

return ChallengeWorld
