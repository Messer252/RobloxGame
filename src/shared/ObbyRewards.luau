-- Called only after the server validates a complete, ordered course run.
local Boosts = if script then require(script.Parent.Boosts) else require("./Boosts")
local Cards = if script then require(script.Parent.CardEconomy) else require("./CardEconomy")
local Contracts = if script then require(script.Parent.BakeryContracts) else require("./BakeryContracts")
local Rewards = {}

function Rewards.complete(data, difficulty, now, thirdSlot)
	if not Boosts.ObbyBonuses[difficulty] then return false, "Unknown course.", false end
	local boosted, message = Boosts.awardObby(data, difficulty, now)
	local crumbs = Cards.obby(data.life.cards, difficulty, now, thirdSlot)
	-- A completed course advances a job even when its financial rewards are
	-- cooling down or a stronger boost is already active.
	local progressed = Contracts.record(data, "Obby", 1)
	if crumbs > 0 then message ..= " +" .. crumbs .. " Star Crumbs!" end
	if progressed then message ..= " Quest progress updated." end
	return true, message, boosted or crumbs > 0 or progressed
end

return Rewards
