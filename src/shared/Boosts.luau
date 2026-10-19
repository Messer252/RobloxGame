-- Pure income bonuses. Timed obby rewards use wall-clock seconds; paid tiers
-- are permanent. Neither multiplier applies to purchased cash or quest prizes.
local Boosts = { Duration = 300, MaxPaidTier = 12 }
Boosts.ObbyBonuses = { Easy = 0.1, Medium = 0.3, Hard = 0.5 }

function Boosts.normalize(raw)
	local result = { paidTier = 0, obbyBonus = 0, obbyExpires = 0 }
	if type(raw) ~= "table" then return result end
	if type(raw.paidTier) == "number" and raw.paidTier == raw.paidTier and math.abs(raw.paidTier) < math.huge then
		result.paidTier = math.clamp(math.floor(raw.paidTier), 0, Boosts.MaxPaidTier)
	end
	if raw.obbyBonus == 0.1 or raw.obbyBonus == 0.3 or raw.obbyBonus == 0.5 then
		result.obbyBonus = raw.obbyBonus
	end
	if type(raw.obbyExpires) == "number" and raw.obbyExpires == raw.obbyExpires and math.abs(raw.obbyExpires) < math.huge then
		result.obbyExpires = math.clamp(math.floor(raw.obbyExpires), 0, 4102444800)
	end
	return result
end

function Boosts.paidMultiplier(state) return 2 ^ (state and state.paidTier or 0) end

function Boosts.obbyMultiplier(state, now)
	return state and state.obbyExpires > now and 1 + state.obbyBonus or 1
end

function Boosts.multiplier(state, now)
	return Boosts.paidMultiplier(state) * Boosts.obbyMultiplier(state, now)
end

function Boosts.awardObby(data, difficulty, now)
	local bonus = Boosts.ObbyBonuses[difficulty]
	if not bonus then return false, "Unknown course." end
	local state = Boosts.normalize(data.boosts)
	if state.obbyExpires > now and state.obbyBonus > bonus then
		return false, "Your stronger obby boost is still active."
	end
	state.obbyBonus, state.obbyExpires = bonus, now + Boosts.Duration
	data.boosts = state
	return true, "+" .. math.floor(bonus * 100) .. "% cookie income for 5 minutes!"
end

function Boosts.grantPaid(data, tier)
	if type(tier) ~= "number" or tier % 1 ~= 0 or tier < 1 or tier > Boosts.MaxPaidTier then return false, "invalid_reward" end
	local state = Boosts.normalize(data.boosts)
	-- Older/delayed receipts cannot downgrade an entitlement already delivered.
	state.paidTier = math.max(state.paidTier, tier)
	data.boosts = state
	return true
end

return Boosts
