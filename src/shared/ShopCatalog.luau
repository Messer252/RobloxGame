-- Create these passes/products for YOUR experience in Creator Dashboard.
-- Replace 0 with the numeric ID. A zero, invalid, or duplicated ID stays disabled.
-- Prices come from Roblox on the client; do not hardcode Robux prices here.
local Catalog = {
	PassOrder = { "DoubleIncome", "DoubleSpeed" },
	Passes = {
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
	if kind == "Product" and (not Catalog.validId(entry.Cash) or entry.Cash > 1e15) then return nil end
	return entry
end

return Catalog
