-- A standard Roblox character and original treasures. Discovery callbacks originate
-- from alive characters beside the actual server-owned item, never a client ID.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.CookieTycoon.ChallengeCatalog)
local BakerAvatar = require(script.Parent.BakerAvatar)
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
	local current
	BakerAvatar.create(function(model)
		if not parent.Parent then
			model:Destroy()
			return
		end
		model.Name = Catalog.NPCName
		local pos = Catalog.NPCPosition
		BakerAvatar.place(model, Vector3.new(pos[1], pos[2], pos[3]), Vector3.new(-pos[1], 0, -pos[3]))
		model.Parent = parent
		npcRoot = model:FindFirstChild("HumanoidRootPart")
		interaction(npcRoot, "Talk", Catalog.NPCName, onTalk)
		local gui = Instance.new("BillboardGui")
		gui.Size, gui.StudsOffset, gui.MaxDistance = UDim2.fromOffset(180, 44), Vector3.new(0, 3.8, 0), 55
		gui.Parent = npcRoot
		local label = Instance.new("TextLabel")
		label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		label.Text, label.Font, label.TextSize = Catalog.NPCName .. "\nBakery jobs", Enum.Font.GothamBold, 16
		label.TextColor3, label.TextStrokeTransparency = cream, 0.25
		label.Parent = gui
		if current then current:Destroy() end
		current = model
	end)
	return current
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
		local handle = add("Polished Spoon Handle", Vector3.new(1.8, 0.18, 0.18), 0, 0, -0.65, tint, Enum.PartType.Cylinder, CFrame.Angles(0, math.pi / 2, 0), Enum.Material.Metal)
		handle.Reflectance = 0.3
		add("Spoon Bowl Base", Vector3.new(0.85, 0.1, 1.15), 0, 0, 0.8, tint, Enum.PartType.Ball, nil, Enum.Material.Metal)
		for index = 1, 16 do
			local angle = index * math.pi / 8
			local rim = add("Rounded Spoon Rim", Vector3.new(0.25, 0.14, 0.25), math.cos(angle) * 0.42, 0.07, 0.8 + math.sin(angle) * 0.56, tint, Enum.PartType.Ball, nil, Enum.Material.Metal)
			rim.Reflectance = 0.25
		end
	elseif item.Kind == "Cube" then
		add("Sugar Cube", Vector3.new(1.35, 1.35, 1.35), 0, 0, 0, Color3.fromRGB(250, 247, 235), nil, nil, Enum.Material.Sand)
		for index = 1, 28 do
			local x, z = math.sin(index * 19.7) * 0.59, math.cos(index * 11.3) * 0.59
			add("Fine Sugar Grain", Vector3.new(0.1, 0.07, 0.1), x, 0.69, z, cream, nil, CFrame.Angles(0, index, 0))
		end
	elseif item.Kind == "Whisk" then
		add("Rounded Pink Handle", Vector3.new(1.3, 0.34, 0.34), 0, 0, -0.7, tint, Enum.PartType.Cylinder, CFrame.Angles(0, math.pi / 2, 0))
		local silver = Color3.fromRGB(195, 209, 213)
		for loop = 0, 2 do
			local rotation = CFrame.Angles(0, 0, loop * math.pi / 3)
			for index = 1, 16 do
				local a, b = (index - 1) * math.pi / 8, index * math.pi / 8
				local p1 = rotation * Vector3.new(math.sin(a) * 0.44, 0, math.cos(a) * 0.8 + 0.65)
				local p2 = rotation * Vector3.new(math.sin(b) * 0.44, 0, math.cos(b) * 0.8 + 0.65)
				local wire = piece(model, "Curved Whisk Wire", Vector3.new(0.06, 0.06, (p2 - p1).Magnitude), base * CFrame.lookAt((p1 + p2) / 2, p2), silver, nil, Enum.Material.Metal)
				wire.Reflectance = 0.25
			end
		end
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
