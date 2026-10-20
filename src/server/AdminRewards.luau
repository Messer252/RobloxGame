local Progression = if script then require(game:GetService("ReplicatedStorage").CookieTycoon.Progression) else require("../shared/Progression")
local Cards = if script then require(game:GetService("ReplicatedStorage").CookieTycoon.CardEconomy) else require("../shared/CardEconomy")
local Rewards = {}

function Rewards.grant(data, action, amount, maximum)
	local fields = { GiveWalletCash = "cash", GiveBankCash = "bank", GiveGoldenChips = "chips", GiveStarCrumbs = "crumbs" }
	local field = fields[action]
	if not field then return false, "Unknown currency destination." end
	local target = field == "crumbs" and data.life.cards or data
	local cap = field == "crumbs" and Cards.MaxCrumbs or field == "chips" and Progression.MAX_CHIPS or Progression.MAX_CASH
	if type(maximum) ~= "number" or maximum <= 0 or maximum > cap or maximum % 1 ~= 0 then
		return false, "Admin grants need a valid configured limit."
	end
	if type(amount) ~= "number" or amount <= 0 or amount > maximum or amount % 1 ~= 0 then
		return false, "Enter a whole amount from 1 to " .. Progression.format(maximum) .. "."
	end
	if amount > cap - target[field] then return false, "That balance does not have room for the whole grant." end
	target[field] += amount -- Exact gifts; food, cards and passes never multiply them.
	local names = { cash = "wallet cash", bank = "uncollected earnings", chips = "Golden Chips", crumbs = "Star Crumbs" }
	return true, "Added " .. Progression.format(amount) .. " " .. names[field] .. "."
end

return Rewards
