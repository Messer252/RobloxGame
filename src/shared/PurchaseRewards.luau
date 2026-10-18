-- Pure reward calculation. The server supplies the configured amount and limit.
local Rewards = {}
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

return Rewards
