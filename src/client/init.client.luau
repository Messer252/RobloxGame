local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("CookieTycoon")
local Recipes = require(shared:WaitForChild("Recipes"))
local Progression = require(shared:WaitForChild("Progression"))
local Catalog = require(shared:WaitForChild("ShopCatalog"))
local remotes = shared:WaitForChild("Remotes")
local requestAction = remotes:WaitForChild("RequestAction")
local openShop = remotes:WaitForChild("OpenShop")
local requestPurchase = remotes:WaitForChild("RequestPurchase")
local refreshPasses = remotes:WaitForChild("RefreshPasses")

local cream = Color3.fromRGB(255, 236, 209)
local gold = Color3.fromRGB(255, 208, 92)
local gui = Instance.new("ScreenGui")
gui.Name = "CookieTycoonHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function round(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = object
end

local function fixedLabel(parent, y, height, size, tint)
	local text = Instance.new("TextLabel")
	text.Position = UDim2.fromOffset(14, y)
	text.Size = UDim2.new(1, -28, 0, height)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = size
	text.TextColor3 = tint or cream
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextWrapped = true
	text.Parent = parent
	return text
end

local hud = Instance.new("Frame")
hud.Size = UDim2.new(0.94, 0, 0, 156)
hud.Position = UDim2.fromOffset(12, 12)
hud.BackgroundColor3 = Color3.fromRGB(53, 36, 32)
hud.BackgroundTransparency = 0.06
hud.Parent = gui
round(hud, 16)
local hudLimit = Instance.new("UISizeConstraint")
hudLimit.MaxSize = Vector2.new(500, 156)
hudLimit.Parent = hud
fixedLabel(hud, 8, 30, 23, gold).Text = "COOKIE CORNER"
local wallet = fixedLabel(hud, 40, 22, 17)
local progress = fixedLabel(hud, 65, 22, 15)
progress.TextScaled = true
progress.TextWrapped = false
local progressTextSize = Instance.new("UITextSizeConstraint")
progressTextSize.MinTextSize = 10
progressTextSize.MaxTextSize = 15
progressTextSize.Parent = progress
local saveStatus = fixedLabel(hud, 90, 19, 12)
wallet.Text = "Loading your bakery..."

local menu = Instance.new("Frame")
menu.Name = "BakeryMenu"
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Position = UDim2.fromScale(0.5, 0.5)
menu.Size = UDim2.fromScale(0.94, 0.86)
menu.BackgroundColor3 = Color3.fromRGB(53, 36, 32)
menu.Visible = false
menu.ZIndex = 5
menu.Parent = gui
round(menu, 16)
local menuLimit = Instance.new("UISizeConstraint")
menuLimit.MaxSize = Vector2.new(520, 680)
menuLimit.Parent = menu
local title = fixedLabel(menu, 12, 30, 23, gold)
title.Size = UDim2.new(1, -78, 0, 30)
title.Text = "YOUR BAKERY"
local menuWallet = fixedLabel(menu, 46, 30, 14)

local function button(parent, text, tint)
	local result = Instance.new("TextButton")
	result.Size = UDim2.new(1, 0, 0, 60)
	result.BackgroundColor3 = tint or Color3.fromRGB(109, 75, 59)
	result.TextColor3 = cream
	result.Text = text
	result.TextSize = 16
	result.TextWrapped = true
	result.Font = Enum.Font.GothamBold
	result.Parent = parent
	round(result, 10)
	return result
end

local close = button(menu, "X")
close.Size = UDim2.fromOffset(38, 38)
close.Position = UDim2.new(1, -50, 0, 10)
close.Activated:Connect(function() menu.Visible = false end)
local toggle = button(hud, "Bakery & Robux Shop", Color3.fromRGB(130, 87, 49))
toggle.Position = UDim2.fromOffset(14, 115)
toggle.Size = UDim2.new(1, -28, 0, 30)
toggle.Activated:Connect(function() menu.Visible = not menu.Visible end)
local bakeryTab = button(menu, "Bakery", Color3.fromRGB(130, 87, 49))
bakeryTab.Position = UDim2.fromOffset(14, 82)
bakeryTab.Size = UDim2.new(0.5, -18, 0, 32)
local robuxTab = button(menu, "Robux Shop", Color3.fromRGB(92, 66, 48))
robuxTab.Position = UDim2.new(0.5, 4, 0, 82)
robuxTab.Size = UDim2.new(0.5, -18, 0, 32)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(14, 124)
scroll.Size = UDim2.new(1, -28, 1, -138)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.Parent = menu
local padding = Instance.new("UIPadding")
padding.PaddingRight = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = scroll

local function list(parent)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
end
list(scroll)
local shopScroll = scroll:Clone()
shopScroll.Name = "RobuxShop"
shopScroll.Visible = false
shopScroll.Parent = menu
local function showTab(shop)
	scroll.Visible = not shop
	shopScroll.Visible = shop
	bakeryTab.BackgroundColor3 = shop and Color3.fromRGB(92, 66, 48) or Color3.fromRGB(130, 87, 49)
	robuxTab.BackgroundColor3 = shop and Color3.fromRGB(130, 87, 49) or Color3.fromRGB(92, 66, 48)
end
bakeryTab.Activated:Connect(function() showTab(false) end)
robuxTab.Activated:Connect(function() showTab(true) end)
local order = 0
local function ordered(object)
	order += 1
	object.LayoutOrder = order
	return object
end
local function text(parent, content, size, tint)
	local object = Instance.new("TextLabel")
	object.Size = UDim2.new(1, 0, 0, 0)
	object.AutomaticSize = Enum.AutomaticSize.Y
	object.BackgroundTransparency = 1
	object.Text = content
	object.TextSize = size or 15
	object.TextColor3 = tint or cream
	object.TextXAlignment = Enum.TextXAlignment.Left
	object.TextYAlignment = Enum.TextYAlignment.Top
	object.TextWrapped = true
	object.Font = Enum.Font.Gotham
	object.Parent = parent
	return object
end

local bakeryInfo = ordered(text(scroll, "Claim a green pad to start baking."))
local collectButton = ordered(button(scroll, "Collect earnings", Color3.fromRGB(134, 100, 35)))
local recipeButton = ordered(button(scroll, "Unlock next cookie"))
local ovenButton = ordered(button(scroll, "Upgrade ovens", Color3.fromRGB(103, 82, 147)))
ordered(text(scroll, "GOLDEN CHIPS & REBIRTH", 20, gold))
local rebirthInfo = ordered(text(scroll, ""))
local rebirthButton = ordered(button(scroll, "Rebirth", Color3.fromRGB(145, 94, 31)))
local confirmation = ordered(Instance.new("Frame"))
confirmation.Size = UDim2.new(1, 0, 0, 0)
confirmation.AutomaticSize = Enum.AutomaticSize.Y
confirmation.BackgroundTransparency = 1
confirmation.Visible = false
confirmation.Parent = scroll
list(confirmation)
local confirmationText = text(confirmation, "")
confirmationText.LayoutOrder = 1
local confirmButton = button(confirmation, "Confirm rebirth", Color3.fromRGB(154, 65, 51))
confirmButton.LayoutOrder = 2
local cancelButton = button(confirmation, "Keep baking")
cancelButton.LayoutOrder = 3
cancelButton.Size = UDim2.new(1, 0, 0, 40)
local confirmCount

ordered(text(scroll, "PERMANENT UPGRADES", 20, gold))
ordered(text(scroll, "Spend Golden Chips here. These upgrades survive every rebirth. Each rebirth also adds +15% income."))
local permanentButtons = {}
for _, key in ipairs(Progression.PermanentOrder) do
	local upgradeButton = ordered(button(scroll, "", Color3.fromRGB(113, 87, 39)))
	upgradeButton.Size = UDim2.new(1, 0, 0, 82)
	permanentButtons[key] = upgradeButton
	upgradeButton.Activated:Connect(function() requestAction:FireServer("UpgradePermanent", key) end)
end

ordered(text(shopScroll, "ROBUX SHOP", 20, gold))
ordered(text(shopScroll, "Optional upgrades. Roblox shows the final price and asks you to confirm every purchase. You can keep playing without buying anything."))
local shopStatus = ordered(text(shopScroll, "Loading shop...", 15, gold))
ordered(text(shopScroll, "PERMANENT PASSES", 18, gold))
ordered(text(shopScroll, "Buy once. Pass benefits stay when you leave or rebirth."))
local shopRows = {}
local priceMetadata = {}
local pricesLoading = false
local function shopRow(kind, key, entry)
	local purchaseButton = ordered(button(shopScroll, entry.Name, Color3.fromRGB(101, 113, 65)))
	purchaseButton.Size = UDim2.new(1, 0, 0, kind == "Pass" and 112 or 94)
	table.insert(shopRows, { Kind = kind, Key = key, Entry = entry, Button = purchaseButton })
	purchaseButton.Activated:Connect(function() requestPurchase:FireServer(kind, key) end)
end
for _, key in ipairs(Catalog.PassOrder) do shopRow("Pass", key, Catalog.Passes[key]) end
ordered(text(shopScroll, "COOKIE CASH BUNDLES", 18, gold))
ordered(text(shopScroll, "Repeatable purchases add the exact cash shown. This cash is spent like earned cash and resets on rebirth; it does not award Golden Chips directly."))
for _, key in ipairs(Catalog.ProductOrder) do shopRow("Product", key, Catalog.Products[key]) end
local refreshShopButton = ordered(button(shopScroll, "Refresh shop", Color3.fromRGB(109, 75, 59)))
refreshShopButton.Size = UDim2.new(1, 0, 0, 42)

local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -12)
toast.Size = UDim2.new(0.94, 0, 0, 72)
toast.BackgroundColor3 = Color3.fromRGB(53, 36, 32)
toast.TextColor3 = cream
toast.Font = Enum.Font.GothamBold
toast.TextSize = 16
toast.TextWrapped = true
toast.Visible = false
toast.ZIndex = 10
toast.Parent = gui
round(toast)
local toastLimit = Instance.new("UISizeConstraint")
toastLimit.MaxSize = Vector2.new(650, 72)
toastLimit.Parent = toast

local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
local function currentData()
	return {
		cash = cash.Value, bank = player:GetAttribute("Bank") or 0,
		unlocked = player:GetAttribute("RecipeCount") or 1, level = player:GetAttribute("OvenLevel") or 1,
		rebirths = player:GetAttribute("Rebirths") or 0, chips = player:GetAttribute("GoldenChips") or 0,
		permanent = {
			Yield = player:GetAttribute("YieldLevel") or 0,
			Speed = player:GetAttribute("SpeedLevel") or 0,
			Starter = player:GetAttribute("StarterLevel") or 0,
		},
		perks = {
			DoubleIncome = player:GetAttribute("DoubleIncomeOwned") == true,
			DoubleSpeed = player:GetAttribute("DoubleSpeedOwned") == true,
		},
	}
end
local function enable(target, enabled)
	target.Active = enabled
	target.Interactable = enabled
	target.Selectable = enabled
	target.AutoButtonColor = enabled
	target.TextTransparency = enabled and 0 or 0.4
end

local saveMessages = {
	Loading = "Loading saved progress...",
	Saved = "Progress saved • Autosaves every 45 seconds",
	Saving = "Saving progress...",
	SaveFailed = "Save delayed • Reconnecting automatically...",
	SessionOnly = "STUDIO SESSION ONLY • Progress will not save",
	PurchasePending = "Saving your purchase • Please wait...",
}
local function render()
	local data = currentData()
	local ready = player:GetAttribute("DataReady") == true
	local ownsBakery = ready and player:GetAttribute("HasBakery") == true
	local purchasePending = player:GetAttribute("PurchasePending") == true
	local canManage = ownsBakery and not purchasePending
	local format = Progression.format
	wallet.Text = "Cash $" .. format(data.cash) .. "  |  Ready $" .. format(data.bank)
	progress.Text = data.unlocked .. "/" .. #Recipes .. " cookies  •  " .. data.rebirths .. " rebirths  •  " .. data.chips .. " Golden Chips"
	menuWallet.Text = "$" .. format(data.cash) .. " wallet  •  $" .. format(data.bank) .. " bank  •  " .. data.chips .. " Golden Chips"
	local status = player:GetAttribute("DataStatus") or "Loading"
	saveStatus.Text = saveMessages[status] or status
	saveStatus.TextColor3 = (status == "SaveFailed" or status == "SessionOnly") and gold or cream
	if not ready then
		bakeryInfo.Text = "Loading your saved bakery before you can play..."
	elseif purchasePending then
		bakeryInfo.Text = "Saving your purchase. Bakery controls will resume automatically when it is confirmed."
	elseif not ownsBakery then
		bakeryInfo.Text = "Claim any free bakery on a green pad. Your saved recipes and upgrades come with you. If all four are taken, wait for a plot to open."
	else
		bakeryInfo.Text = string.format("%d/%d recipes • Oven level %d/%d\n$%s per batch every %.2fs • %.2fx income\nUse this menu anywhere, or the pads at your bakery.",
			data.unlocked, #Recipes, data.level, Progression.MAX_OVEN_LEVEL, format(Progression.batchValue(data, data.perks)), Progression.interval(data, data.perks), Progression.multiplier(data, data.perks))
	end
	collectButton.Text = "Collect $" .. format(data.bank)
	enable(collectButton, canManage and data.bank > 0 and data.cash < Progression.MAX_CASH)
	local nextRecipe = Recipes[data.unlocked + 1]
	recipeButton.Text = nextRecipe and ("Unlock " .. nextRecipe.Name .. "\n$" .. format(nextRecipe.Cost)) or "All 30 cookies unlocked!"
	enable(recipeButton, canManage and nextRecipe ~= nil and data.cash >= (nextRecipe and nextRecipe.Cost or 0))
	local ovenMax = data.level >= Progression.MAX_OVEN_LEVEL
	ovenButton.Text = ovenMax and "Ovens MAXED!" or ("Upgrade all ovens to level " .. (data.level + 1) .. "\n$" .. format(Progression.ovenCost(data)))
	enable(ovenButton, canManage and not ovenMax and data.cash >= Progression.ovenCost(data))
	local requirement = Progression.rebirthRequirement(data)
	local rebirthMax = data.rebirths >= Progression.MAX_REBIRTHS
	local canRebirth = canManage and not rebirthMax and data.unlocked >= requirement.Recipes and data.cash + data.bank >= requirement.Cash
	rebirthInfo.Text = rebirthMax and "You completed all 50 rebirths! Keep building your ultimate bakery."
		or string.format("Rebirth #%d earns %d Golden Chips.\nRecipes: %d/%d required\nCash + bank: $%s / $%s\nReset cash, uncollected earnings, recipes, and oven levels. Keep Golden Chips and permanent upgrades.",
			data.rebirths + 1, requirement.Reward, data.unlocked, requirement.Recipes, format(data.cash + data.bank), format(requirement.Cash))
	rebirthButton.Text = rebirthMax and "Maximum rebirths reached" or "Review rebirth  •  +" .. requirement.Reward .. " Golden Chips"
	enable(rebirthButton, canRebirth)
	if confirmation.Visible then
		if data.rebirths ~= confirmCount or not ownsBakery then confirmation.Visible = false end
		confirmationText.Text = "Start over for " .. requirement.Reward .. " Golden Chips? Your cash, bank, 30-cookie unlock progress, and oven levels will reset. Golden Chips, permanent upgrades, and rebirth bonuses stay."
		enable(confirmButton, canRebirth)
	end
	for key, upgradeButton in pairs(permanentButtons) do
		local upgrade = Progression.Permanent[key]
		local cost = Progression.permanentCost(data, key)
		upgradeButton.Text = upgrade.Name .. "  " .. data.permanent[key] .. "/" .. upgrade.Max .. "\n"
			.. (cost and cost .. " Golden Chips" or "MAXED") .. " • " .. upgrade.Description
		enable(upgradeButton, canManage and cost ~= nil and data.chips >= (cost or math.huge))
	end
	local commerceReady = ready and player:GetAttribute("CommerceReady") == true
	local promptOpen = player:GetAttribute("ShopPromptOpen") == true
	local configured = false
	for _, row in ipairs(shopRows) do
		local offer = Catalog.offer(row.Kind, row.Key)
		configured = configured or offer ~= nil
		local metadata = priceMetadata[row.Kind .. ":" .. row.Key]
		local owned = row.Kind == "Pass" and player:GetAttribute(row.Key .. "Owned") == true
		local priceLine
		if owned then priceLine = "Owned • Permanent"
		elseif not offer then priceLine = "Coming soon"
		elseif not metadata or metadata.State == "Loading" then priceLine = "Checking price..."
		elseif metadata.State ~= "Ready" then priceLine = "Currently unavailable"
		else priceLine = "R$ " .. metadata.Price .. (row.Kind == "Pass" and " • Buy once" or " • Repeatable") end
		if row.Kind == "Pass" then
			row.Button.Text = row.Entry.Name .. "\n" .. priceLine .. "\n" .. row.Entry.Description
		else
			row.Button.Text = row.Entry.Name .. " • $" .. format(row.Entry.Cash) .. "\n" .. priceLine .. "\nCash resets on rebirth."
		end
		local ownershipReady = row.Kind ~= "Pass" or player:GetAttribute("PassesReady") == true
		enable(row.Button, commerceReady and not purchasePending and not promptOpen and not owned and offer ~= nil
			and ownershipReady and metadata ~= nil and metadata.State == "Ready")
	end
	if purchasePending then shopStatus.Text = "Saving your purchase. Please wait; rewards are being confirmed."
	elseif not configured then shopStatus.Text = "The Robux shop is coming soon. Keep baking for free!"
	elseif not ready then shopStatus.Text = "Loading your bakery..."
	elseif not commerceReady then shopStatus.Text = "Purchases are unavailable in this play session."
	elseif promptOpen then shopStatus.Text = "Finish or cancel the Roblox purchase window to continue."
	else
		shopStatus.Text = "Passes: " .. (data.perks.DoubleIncome and "2x income active" or "standard income")
			.. " • " .. (data.perks.DoubleSpeed and "2x baking speed active" or "standard baking speed")
	end
	enable(refreshShopButton, not pricesLoading and not purchasePending and not promptOpen)
end

local lastPriceRefresh = -math.huge
local function refreshPrices()
	if pricesLoading or os.clock() - lastPriceRefresh < 5 then return end
	lastPriceRefresh = os.clock()
	pricesLoading = true
	refreshPasses:FireServer()
	for _, row in ipairs(shopRows) do priceMetadata[row.Kind .. ":" .. row.Key] = { State = "Loading" } end
	render()
	task.spawn(function()
		for _, row in ipairs(shopRows) do
			local offer = Catalog.offer(row.Kind, row.Key)
			local metadata = { State = "Unavailable" }
			if offer then
				-- Fetch on this client so Roblox's current personalized/regional
				-- PriceInRobux is shown. The native prompt remains the final price.
				local ok, info = pcall(function()
					return MarketplaceService:GetProductInfoAsync(offer.Id, row.Kind == "Pass" and Enum.InfoType.GamePass or Enum.InfoType.Product)
				end)
				if ok and info.IsForSale == true and type(info.PriceInRobux) == "number" and info.PriceInRobux >= 0 and info.PriceInRobux < 2 ^ 53 then
					metadata = { State = "Ready", Price = math.floor(info.PriceInRobux) }
				end
			end
			priceMetadata[row.Kind .. ":" .. row.Key] = metadata
			render()
		end
		pricesLoading = false
		render()
	end)
end
refreshShopButton.Activated:Connect(refreshPrices)

collectButton.Activated:Connect(function() requestAction:FireServer("Collect") end)
recipeButton.Activated:Connect(function() requestAction:FireServer("BuyRecipe") end)
ovenButton.Activated:Connect(function() requestAction:FireServer("UpgradeOven") end)
rebirthButton.Activated:Connect(function()
	confirmCount = currentData().rebirths
	confirmation.Visible = true
	render()
end)
confirmButton.Activated:Connect(function()
	if confirmCount ~= nil then requestAction:FireServer("Rebirth", confirmCount) end
	confirmation.Visible = false
end)
cancelButton.Activated:Connect(function() confirmation.Visible = false end)
openShop.OnClientEvent:Connect(function() menu.Visible = true end)

local noticeVersion = 0
local function showNotice()
	local message = player:GetAttribute("Notice")
	if not message then return end
	noticeVersion += 1
	local version = noticeVersion
	toast.Text = message
	toast.Visible = true
	task.delay(6, function() if noticeVersion == version then toast.Visible = false end end)
end

local queued = false
local function scheduleRender()
	if queued then return end
	queued = true
	task.defer(function()
		queued = false
		render()
	end)
end
cash.Changed:Connect(scheduleRender)
player.AttributeChanged:Connect(scheduleRender)
player:GetAttributeChangedSignal("NoticeId"):Connect(showNotice)
render()
showNotice()
refreshPrices()
