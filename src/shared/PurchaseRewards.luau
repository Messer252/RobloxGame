-- Pure reward calculation. The server supplies the configured amount and limit.
local Rewards = {}
local Boosts = if script then require(script.Parent.Boosts) else require("./Boosts")
type CashData = { cash: number, bank: number }

function Rewards.canFitCash(data: CashData, amount: number, limit: number)
	return type(amount) == "number" and amount > 0 and amount <= limit and amount == math.floor(amount)
		and (limit - data.cash) + (limit - data.bank) >= amount
end

function Rewards.cash(data: CashData, amount: number, limit: number)
	if not Rewards.canFitCash(data, amount, limit) then return false, "capacity" end
	local walletAmount = math.min(amount, limit - data.cash)
	data.cash += walletAmount
	data.bank += amount - walletAmount
	return true
end

function Rewards.product(data, product, limit)
	if product.BoostTier ~= nil then return Boosts.grantPaid(data, product.BoostTier) end
	return Rewards.cash(data, product.Cash, limit)
end

return Rewards
