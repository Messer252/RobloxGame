local Earnings = if script then require(script.Parent.Earnings) else require("./Earnings")
local Catalog = if script then require(script.Parent.ChallengeCatalog) else require("./ChallengeCatalog")
local Challenges = {}

-- Only the current hunt's known item flags are saved. There is no client
-- supplied count or reward, and older/inactive flags cannot skip a later hunt.
function Challenges.normalize(raw)
	local state = { index = 1, active = false, found = {} }
	if type(raw) ~= "table" then return state end
	local index = raw.index
	if type(index) == "number" and index == index and math.abs(index) ~= math.huge then
		state.index = math.clamp(math.floor(index), 1, #Catalog.Challenges + 1)
	end
	local quest = Catalog.Challenges[state.index]
	state.active = quest ~= nil and raw.active == true
	if state.active and type(raw.found) == "table" then
		for _, itemId in ipairs(quest.Items) do
			if raw.found[itemId] == true then state.found[itemId] = true end
		end
	end
	return state
end

function Challenges.current(state)
	return Catalog.Challenges[state and state.index or 1]
end

function Challenges.count(state)
	local quest = Challenges.current(state)
	if not quest or not state or not state.active then return 0 end
	local count = 0
	for _, itemId in ipairs(quest.Items) do
		if state.found and state.found[itemId] == true then count += 1 end
	end
	return count
end

function Challenges.encode(state)
	local quest = Challenges.current(state)
	if not quest or not state or not state.active then return 0 end
	local mask = 0
	for index, itemId in ipairs(quest.Items) do
		if state.found and state.found[itemId] == true then mask += 2 ^ (index - 1) end
	end
	return mask
end

function Challenges.isComplete(state)
	return state ~= nil and state.index == #Catalog.Challenges + 1
end

function Challenges.ready(state)
	local quest = Challenges.current(state)
	return quest ~= nil and state.active == true and Challenges.count(state) == #quest.Items
end

function Challenges.find(data, itemId)
	local state = Challenges.normalize(data.challenges)
	local quest = Challenges.current(state)
	if not quest or not state.active then return false, "Talk to Baker Biscuit to start a hunt." end
	local wanted = false
	for _, targetId in ipairs(quest.Items) do
		if itemId == targetId then
			wanted = true
			break
		end
	end
	if not wanted then return false, "That item belongs to a different hunt." end
	if state.found[itemId] then return false, "You already found this item." end
	state.found[itemId] = true
	data.challenges = state
	local message = "Found " .. Catalog.Items[itemId].Name .. "! " .. Challenges.count(state) .. "/" .. #quest.Items
	if Challenges.ready(state) then message ..= " • Return to Baker Biscuit!" end
	return true, message
end

function Challenges.interact(data, maxCash)
	local state = Challenges.normalize(data.challenges)
	local quest = Challenges.current(state)
	if not quest then return false, "You found every treasure! Thanks for helping, baker." end
	if not state.active then
		state.active = true
		data.challenges = state
		return true, "Hunt started: " .. quest.Name .. ". Check your quest clues!", 0
	end
	if not Challenges.ready(state) then
		return false, "Found " .. Challenges.count(state) .. "/" .. #quest.Items .. ". Follow the clues to find the rest!"
	end
	local limit = maxCash or Earnings.Limit
	-- Preserve the entire reward. Overflow goes to the register; if both balances
	-- are full, leave the completed hunt untouched so the player can claim later.
	local walletRoom = math.max(0, limit - data.cash)
	local bankRoom = math.max(0, limit - data.bank)
	if walletRoom + bankRoom < quest.Reward then
		return false, "Spend some cash to make room for your reward. Your hunt is complete!"
	end
	local walletReward = math.min(quest.Reward, walletRoom)
	Earnings.record(data,quest.Reward)
	data.cash += walletReward
	data.bank += quest.Reward - walletReward
	data.challenges = { index = state.index + 1, active = false, found = {} }
	return true, quest.Name .. " complete! +$" .. quest.Reward, quest.Reward
end

return Challenges
