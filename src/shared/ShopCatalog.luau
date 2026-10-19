-- Create these passes/products for YOUR experience in Creator Dashboard.
-- Replace 0 with the numeric ID. A zero, invalid, or duplicated ID stays disabled.
-- Prices come from Roblox on the client; do not hardcode Robux prices here.
local Boosts = if script then require(script.Parent.Boosts) else require("./Boosts")
local Catalog = {
	PassOrder = { "DoubleIncome", "DoubleSpeed", "ThirdCardSlot" },
	Passes = {
		ThirdCardSlot = { Id = 0, Name = "Third Card Slot", Description = "Equip a third animal card on your bakery. Set this pass price to 150 Robux in Creator Dashboard.", SuggestedRobux = 150 },
		DoubleIncome = { Id = 0, Name = "2x Cookie Income", Description = "Double cookie earnings forever. Stacks with Golden Batter and rebirth bonuses." },
		DoubleSpeed = { Id = 0, Name = "2x Baking Speed", Description = "Bake twice as fast forever, including with fully upgraded ovens." },
	},
	ProductOrder = { "CashSmall", "CashMedium", "CashLarge" },
	Products = {
		CashSmall = { Id = 0, Name = "Pocket of Cookie Cash", Cash = 10000 },
		CashMedium = { Id = 0, Name = "Jar of Cookie Cash", Cash = 100000 },
		CashLarge = { Id = 0, Name = "Crate of Cookie Cash", Cash = 1000000 },
	},
	-- Keep retired products in Products with their original ID and reward; only
	-- remove their key from ProductOrder. Unresolved receipts must still be honored.
	MaxPromptedReceipts = 10000,
}

-- Each stage needs its own developer product because Roblox prices are set
-- per product, not dynamically per player. Extend MaxPaidTier with new IDs to
-- add more stages; never repurpose the IDs of existing paid entitlements.
local IncomeProductIds = {
	[1] = 0, -- 2x, 20 Robux
	[2] = 0, -- 4x, 40 Robux
	[3] = 0, -- 8x, 80 Robux
	[4] = 0, -- 16x, 160 Robux
	[5] = 0, -- 32x, 320 Robux
	[6] = 0, -- 64x, 640 Robux
	[7] = 0, -- 128x, 1280 Robux
	[8] = 0, -- 256x, 2560 Robux
	[9] = 0, -- 512x, 5120 Robux
	[10] = 0, -- 1024x, 10240 Robux
	[11] = 0, -- 2048x, 20480 Robux
	[12] = 0, -- 4096x, 40960 Robux
}
for tier = 1, Boosts.MaxPaidTier do
	local key = "IncomeTier" .. tier
	Catalog.Products[key] = { Id = IncomeProductIds[tier] or 0, Name = 2 ^ tier .. "x Permanent Income", BoostTier = tier, SuggestedRobux = 20 * 2 ^ (tier - 1) }
	table.insert(Catalog.ProductOrder, key)
end

function Catalog.validId(value)
	return type(value) == "number" and value > 0 and value < 2 ^ 53 and value == math.floor(value)
end

function Catalog.resolve(kind, id)
	if not Catalog.validId(id) then return nil end
	local entries = kind == "Pass" and Catalog.Passes or kind == "Product" and Catalog.Products or nil
	if not entries then return nil end
	local found, foundKey
	for key, entry in pairs(entries) do
		if entry.Id == id then
			if found then return nil end -- Ambiguous IDs must never award the wrong item.
			found, foundKey = entry, key
		end
	end
	return found, foundKey
end

function Catalog.offer(kind, key)
	local entries = kind == "Pass" and Catalog.Passes or kind == "Product" and Catalog.Products or nil
	local order = kind == "Pass" and Catalog.PassOrder or kind == "Product" and Catalog.ProductOrder or {}
	local listed = false
	for _, listedKey in ipairs(order) do if listedKey == key then listed = true end end
	if not listed or not entries or type(key) ~= "string" then return nil end
	local entry = entries[key]
	if not entry or Catalog.resolve(kind, entry.Id) ~= entry then return nil end
	if kind == "Product" and not Catalog.validProduct(entry) then return nil end
	return entry
end

function Catalog.validProduct(entry)
	if entry.BoostTier ~= nil then
		return entry.Cash == nil and type(entry.BoostTier) == "number" and entry.BoostTier % 1 == 0
			and entry.BoostTier >= 1 and entry.BoostTier <= Boosts.MaxPaidTier
	end
	return Catalog.validId(entry.Cash) and entry.Cash <= 1e15
end

return Catalog
