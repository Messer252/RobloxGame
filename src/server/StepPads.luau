local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Layout = require(ReplicatedStorage.CookieTycoon.ConveyorLayout)
local StepPads = {}
StepPads.__index = StepPads

local function feet(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or humanoid.FloorMaterial == Enum.Material.Air then return nil end
	local height = humanoid.HipHeight + root.Size.Y / 2
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = character:FindFirstChild("Left Leg")
		height += leg and leg.Size.Y or 2
	end
	return { character = character, position = root.Position - Vector3.new(0, height, 0) }
end

function StepPads.new(world)
	local self = setmetatable({ world = world, pads = {}, cooldowns = {}, running = true }, StepPads)
	world.Destroying:Connect(function() self.running = false end)
	task.spawn(function()
		while self.running and world.Parent do
			self:Update(os.clock())
			task.wait(0.08)
		end
	end)
	return self
end

function StepPads:Register(surface, options)
	table.insert(self.pads, { surface = surface, options = options })
end

function StepPads:ResetOwner(player)
	self.cooldowns[player] = nil
	for _, entry in ipairs(self.pads) do
		if entry.owner == player then entry.owner, entry.character, entry.state = nil, nil, nil end
	end
end

function StepPads:Update(now)
	local characters = {}
	for _, entry in ipairs(self.pads) do
		local player = entry.options.Owner()
		if not player or not player.Parent or not entry.surface:IsDescendantOf(self.world) then
			entry.owner, entry.character, entry.state = nil, nil, nil
			continue
		end
		if characters[player] == nil then characters[player] = feet(player) or false end
		local character = characters[player]
		if entry.owner ~= player or entry.character ~= (character and character.character) then
			entry.state = nil
			entry.owner, entry.character = player, character and character.character
		end
		local inside = false
		if character then
			local point = entry.surface.CFrame:PointToObjectSpace(character.position)
			inside = Layout.insidePad(point.X, point.Y, point.Z, entry.surface.Size.X, entry.surface.Size.Z)
		end
		local available = inside and now >= (self.cooldowns[player] or 0) and entry.options.Available(player)
		local fire
		entry.state, fire = Layout.step(entry.state, now, inside, available)
		if fire then
			self.cooldowns[player] = now + Layout.StepCooldown
			-- The normal action handler still checks session ownership, current price,
			-- and progression before changing any money. No client touch event is trusted.
			local ok, result = pcall(entry.options.Activate, player)
			entry.state = Layout.resolveStep(entry.state, ok and result == true)
			if not ok then warn("Cookie Corner step pad failed: " .. tostring(result)) end
		end
	end
end

return StepPads
