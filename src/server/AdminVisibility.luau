local Players = game:GetService("Players")
local Visibility = {}

local function conceal(object, originals)
	if originals[object] then return end
	local property, value
	if object:IsA("BasePart") or object:IsA("Decal") or object:IsA("Texture") then property, value = "Transparency", 1
	elseif object:IsA("ForceField") then property, value = "Visible", false
	elseif object:IsA("Humanoid") then property, value = "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.None
	elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") or object:IsA("Fire")
		or object:IsA("Smoke") or object:IsA("Sparkles") or object:IsA("Highlight")
		or object:IsA("BillboardGui") or object:IsA("SurfaceGui") then property, value = "Enabled", false end
	if property then
		originals[object] = { property = property, value = object[property] }
		object[property] = value
	end
end

local function restore(object, originals)
	local saved = originals[object]
	if saved then
		object[saved.property] = saved.value
		originals[object] = nil
	end
end

local function clearCharacter(state)
	for _, connection in ipairs(state.connections or {}) do connection:Disconnect() end
	for object in pairs(state.originals or {}) do restore(object, state.originals) end
	state.connections, state.originals = {}, {}
end

local function applyCharacter(state, character)
	clearCharacter(state)
	if not state.enabled then return end
	for _, object in ipairs(character:GetDescendants()) do conceal(object, state.originals) end
	table.insert(state.connections, character.DescendantAdded:Connect(function(object) conceal(object, state.originals) end))
	-- Equipped tools/accessories must regain their original appearance when removed.
	table.insert(state.connections, character.DescendantRemoving:Connect(function(object) restore(object, state.originals) end))
end

function Visibility.new()
	local self = { states = {} }
	Players.PlayerRemoving:Connect(function(player)
		local state = self.states[player]
		if state then
			state.respawn:Disconnect()
			state.appearance:Disconnect()
			clearCharacter(state)
			self.states[player] = nil
		end
	end)
	return setmetatable(self, { __index = Visibility })
end

function Visibility:Set(player, enabled)
	local state = self.states[player]
	if not state then
		state = { enabled = false, originals = {}, connections = {} }
		state.respawn = player.CharacterAdded:Connect(function(character) applyCharacter(state, character) end)
		state.appearance = player.CharacterAppearanceLoaded:Connect(function(character)
			if state.enabled and player.Character == character then applyCharacter(state, character) end
		end)
		self.states[player] = state
	end
	state.enabled = enabled
	if player.Character then applyCharacter(state, player.Character) else clearCharacter(state) end
	player:SetAttribute("AdminInvisible", enabled)
end

return Visibility
