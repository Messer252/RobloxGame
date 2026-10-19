local Progression = if script then require(game:GetService("ReplicatedStorage").CookieTycoon.Progression) else require("../shared/Progression")
local Rewards = {}

function Rewards.grant(data, action, amount, maximum)
	local field = action == "GiveWalletCash" and "cash" or action == "GiveBankCash" and "bank" or nil
	if not field then return false, "Unknown cash destination." end
	if type(maximum) ~= "number" or maximum <= 0 or maximum > Progression.MAX_CASH or maximum % 1 ~= 0 then
		return false, "Admin cash grants need a valid configured limit."
	end
	if type(amount) ~= "number" or amount <= 0 or amount > maximum or amount % 1 ~= 0 then
		return false, "Enter a whole amount from 1 to " .. Progression.format(maximum) .. "."
	end
	if amount > Progression.MAX_CASH - data[field] then return false, "That balance does not have room for the whole grant." end
	data[field] += amount
	return true, "Added $" .. Progression.format(amount) .. (field == "cash" and " to the wallet." or " to uncollected earnings.")
end

return Rewards
