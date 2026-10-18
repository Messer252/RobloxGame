local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local AudioController = require(script:WaitForChild("AudioController"))
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("CookieTycoon")
local Recipes = require(shared:WaitForChild("Recipes"))
local Progression = require(shared:WaitForChild("Progression"))
local Crafting = require(shared:WaitForChild("CookieCrafting"))
local Catalog = require(shared:WaitForChild("ShopCatalog"))
local remotes = shared:WaitForChild("Remotes")
local requestAction = remotes:WaitForChild("RequestAction")
local openShop = remotes:WaitForChild("OpenShop")
local requestPurchase = remotes:WaitForChild("RequestPurchase")
local refreshPasses = remotes:WaitForChild("RefreshPasses")
local feedback = remotes:WaitForChild("Feedback")
local audio = AudioController.start(player, requestAction)

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

local function finish(object, borderColor)
	object.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = borderColor or Color3.fromRGB(225, 184, 138)
	stroke.Transparency = 0.65
	stroke.Thickness = 1
	stroke.Parent = object
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(210, 201, 198))
	gradient.Rotation = 90
	gradient.Parent = object
	return stroke
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
hud.Size = UDim2.new(0.94, 0, 0, 198)
hud.Position = UDim2.fromOffset(12, 12)
hud.BackgroundColor3 = Color3.fromRGB(53, 36, 32)
hud.BackgroundTransparency = 0.06
hud.Parent = gui
round(hud, 16)
local hudStroke = finish(hud, gold)
local hudLimit = Instance.new("UISizeConstraint")
hudLimit.MaxSize = Vector2.new(500, 198)
hudLimit.Parent = hud
local cookieIcon = Instance.new("Frame")
cookieIcon.Position = UDim2.fromOffset(15, 9)
cookieIcon.Size = UDim2.fromOffset(30, 30)
cookieIcon.BackgroundColor3 = Color3.fromRGB(232, 183, 113)
cookieIcon.BorderSizePixel = 0
cookieIcon.Rotation = -12
cookieIcon.Parent = hud
round(cookieIcon, 30)
for _, point in ipairs({ Vector2.new(7, 6), Vector2.new(20, 9), Vector2.new(11, 21), Vector2.new(22, 23) }) do
	local chip = Instance.new("Frame")
	chip.Size = UDim2.fromOffset(5, 5)
	chip.Position = UDim2.fromOffset(point.X, point.Y)
	chip.BackgroundColor3 = Color3.fromRGB(92, 53, 39)
	chip.BorderSizePixel = 0
	chip.Parent = cookieIcon
	round(chip, 2)
end
local brand = fixedLabel(hud, 8, 30, 23, gold)
brand.Position = UDim2.fromOffset(58, 8)
brand.Size = UDim2.new(1, -72, 0, 30)
brand.Text = "COOKIE CORNER"
local wallet = fixedLabel(hud, 40, 22, 17)
wallet.TextScaled = true
wallet.TextWrapped = false
local walletTextSize = Instance.new("UITextSizeConstraint")
walletTextSize.MinTextSize = 10
walletTextSize.MaxTextSize = 17
walletTextSize.Parent = wallet
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
finish(menu, gold)
local menuScale = Instance.new("UIScale")
menuScale.Parent = menu
local backdrop = Instance.new("TextButton")
backdrop.Name = "MenuBackdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(28, 20, 28)
backdrop.BackgroundTransparency = 0.4
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Selectable = false
backdrop.Visible = false
backdrop.ZIndex = 4
backdrop.Parent = gui
backdrop.Activated:Connect(function() menu.Visible = false end)
menu:GetPropertyChangedSignal("Visible"):Connect(function()
	backdrop.Visible = menu.Visible
	if menu.Visible then
		menuScale.Scale = 0.96
		TweenService:Create(menuScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
end)
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
	local stroke = finish(result)
	local scale = Instance.new("UIScale")
	scale.Parent = result
	local function focus(active)
		TweenService:Create(stroke, TweenInfo.new(0.12), { Transparency = active and 0.15 or 0.65 }):Play()
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = active and result.Interactable and 1.012 or 1 }):Play()
	end
	result.MouseEnter:Connect(function() focus(true) end)
	result.MouseLeave:Connect(function() focus(false) end)
	result.SelectionGained:Connect(function() focus(true) end)
	result.SelectionLost:Connect(function() focus(false) end)
	result.Activated:Connect(function()
		if result.Active and result.Interactable then audio:PlayCue("Click") end
	end)
	return result
end

local close = button(menu, "X")
close.Size = UDim2.fromOffset(38, 38)
close.Position = UDim2.new(1, -50, 0, 10)
close.Activated:Connect(function() menu.Visible = false end)
local toggle = button(hud, "Bakery • Workshop • Robux Shop", Color3.fromRGB(130, 87, 49))
toggle.Position = UDim2.fromOffset(14, 115)
toggle.Size = UDim2.new(1, -28, 0, 30)
toggle.Activated:Connect(function() menu.Visible = not menu.Visible end)
local musicToggle = button(hud, "Music: ON", Color3.fromRGB(66, 114, 100))
musicToggle.Name = "MusicToggle"
musicToggle.Position = UDim2.fromOffset(14, 154)
musicToggle.Size = UDim2.new(0.5, -18, 0, 30)
musicToggle.TextSize = 14
local effectsToggle = button(hud, "SFX: ON", Color3.fromRGB(66, 114, 100))
effectsToggle.Name = "EffectsToggle"
effectsToggle.Position = UDim2.new(0.5, 4, 0, 154)
effectsToggle.Size = UDim2.new(0.5, -18, 0, 30)
effectsToggle.TextSize = 14
local function renderAudio()
	musicToggle.Text = audio.music and "Music: ON" or "Music: OFF"
	effectsToggle.Text = audio.effects and "SFX: ON" or "SFX: OFF"
	musicToggle.BackgroundColor3 = audio.music and Color3.fromRGB(66, 114, 100) or Color3.fromRGB(95, 75, 69)
	effectsToggle.BackgroundColor3 = audio.effects and Color3.fromRGB(66, 114, 100) or Color3.fromRGB(95, 75, 69)
end
musicToggle.Activated:Connect(function() audio:SetMusicEnabled(not audio.music) end)
effectsToggle.Activated:Connect(function() audio:SetEffectsEnabled(not audio.effects) end)
audio.Changed.Event:Connect(renderAudio)
renderAudio()
local bakeryTab = button(menu, "Bakery", Color3.fromRGB(130, 87, 49))
local robuxTab = button(menu, "Robux Shop", Color3.fromRGB(92, 66, 48))
local workshopTab = button(menu, "Workshop", Color3.fromRGB(92, 66, 48))
local tabBar = Instance.new("Frame")
tabBar.Position = UDim2.fromOffset(14, 82)
tabBar.Size = UDim2.new(1, -28, 0, 32)
tabBar.BackgroundTransparency = 1
tabBar.Parent = menu
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabBar
for index, tab in ipairs({ bakeryTab, workshopTab, robuxTab }) do
	tab.Parent = tabBar
	tab.LayoutOrder = index
	tab.Size = UDim2.new(1 / 3, -6, 1, 0)
	tab.TextSize = 14
end

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
local workshopScroll = scroll:Clone()
workshopScroll.Name = "CookieWorkshop"
workshopScroll.Visible = false
workshopScroll.Parent = menu
local function showTab(tabName)
	scroll.Visible = tabName == "Bakery"
	workshopScroll.Visible = tabName == "Workshop"
	shopScroll.Visible = tabName == "Robux"
	for tab, name in pairs({ [bakeryTab] = "Bakery", [workshopTab] = "Workshop", [robuxTab] = "Robux" }) do
		tab.BackgroundColor3 = name == tabName and Color3.fromRGB(130, 87, 49) or Color3.fromRGB(92, 66, 48)
	end
end
bakeryTab.Activated:Connect(function() showTab("Bakery") end)
workshopTab.Activated:Connect(function() showTab("Workshop") end)
robuxTab.Activated:Connect(function() showTab("Robux") end)
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

ordered(text(workshopScroll, "COOKIE WORKSHOP", 20, gold))
ordered(text(workshopScroll, "Choose a recipe and add toppings with cookie cash. Each purchase upgrades all future cookies of that recipe. Toppings stack and reset on rebirth."))
local selectedRecipe = 1
local lastWorkshopRebirth
local selector = ordered(Instance.new("Frame"))
selector.Size = UDim2.new(1, 0, 0, 54)
selector.BackgroundTransparency = 1
selector.Parent = workshopScroll
local previousCookie = button(selector, "<")
previousCookie.Size = UDim2.fromOffset(42, 48)
local nextCookie = button(selector, ">")
nextCookie.Size = UDim2.fromOffset(42, 48)
nextCookie.Position = UDim2.new(1, -42, 0, 0)
local recipeTitle = fixedLabel(selector, 0, 50, 17)
recipeTitle.Position = UDim2.fromOffset(50, 0)
recipeTitle.Size = UDim2.new(1, -100, 0, 50)
recipeTitle.TextXAlignment = Enum.TextXAlignment.Center
local workshopDetails = ordered(text(workshopScroll, "", 16))
local toppingSummary = ordered(text(workshopScroll, ""))
local modifierButtons = {}
for _, key in ipairs(Crafting.ModifierOrder) do
	local definition = Crafting.Modifiers[key]
	local rgb = definition.Color
	local addButton = ordered(button(workshopScroll, definition.Name, Color3.fromRGB(rgb[1] * 0.35, rgb[2] * 0.35, rgb[3] * 0.35)))
	addButton.Size = UDim2.new(1, 0, 0, 76)
	modifierButtons[key] = addButton
	addButton.Activated:Connect(function()
		requestAction:FireServer("BuyModifier", { Recipe = selectedRecipe, Modifier = key })
	end)
end
ordered(text(workshopScroll, "RARITY TIERS", 18, gold))
for _, key in ipairs(Crafting.RarityOrder) do
	local rarity = Crafting.Rarities[key]
	ordered(text(workshopScroll, rarity.Name .. "  •  x" .. rarity.Multiplier .. " base value", 15, Color3.fromRGB(table.unpack(rarity.Color))))
end
ordered(text(workshopScroll, "Each recipe has a fixed rarity. Topping bonuses add together, then multiply with rarity, Golden Batter, rebirth bonuses, and the income pass. Each cookie's final value is rounded down to whole cash."))

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
local toastStroke = finish(toast, gold)
local toastLimit = Instance.new("UISizeConstraint")
toastLimit.MaxSize = Vector2.new(650, 72)
toastLimit.Parent = toast

local feedbackConnection = feedback.OnClientEvent:Connect(function(cue)
	audio:PlayCue(cue)
	if cue == "Error" or cue == "Click" then return end
	hudStroke.Color = gold
	hudStroke.Transparency = 0.05
	hudStroke.Thickness = 2
	TweenService:Create(hudStroke, TweenInfo.new(0.65), { Transparency = 0.65, Thickness = 1 }):Play()
	toastStroke.Color = cue == "Rebirth" and gold or Color3.fromRGB(151, 218, 182)
	local count = cue == "Rebirth" and 20 or cue == "BuyRecipe" and 12 or 7
	for index = 1, count do
		local spark = Instance.new("Frame")
		spark.AnchorPoint = Vector2.new(0.5, 0.5)
		spark.Size = UDim2.fromOffset(index % 2 == 0 and 7 or 4, 7)
		spark.Position = UDim2.fromScale(0.5, 0.42)
		spark.BackgroundColor3 = index % 3 == 0 and Color3.fromRGB(159, 222, 197) or gold
		spark.BorderSizePixel = 0
		spark.ZIndex = 12
		spark.Rotation = index * 47
		spark.Parent = gui
		round(spark, 2)
		local angle = index / count * math.pi * 2
		local radius = cue == "Rebirth" and 150 or 75
		TweenService:Create(spark, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(angle) * radius, 0.42, math.sin(angle) * radius + 25),
			BackgroundTransparency = 1, Rotation = spark.Rotation + 80,
		}):Play()
		Debris:AddItem(spark, 0.75)
	end
end)
gui.Destroying:Connect(function()
	feedbackConnection:Disconnect()
	audio:Destroy()
end)

local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
local function currentData()
	local data = {
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
		modifiers = {},
	}
	for index = 1, #Recipes do
		local flags = Crafting.decode(player:GetAttribute("RecipeModifiers_" .. index) or 0)
		if next(flags) then data.modifiers[tostring(index)] = flags end
	end
	return data
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
	if lastWorkshopRebirth ~= data.rebirths then
		selectedRecipe = math.min(selectedRecipe, data.unlocked)
		lastWorkshopRebirth = data.rebirths
	end
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
		bakeryInfo.Text = string.format("%d/%d recipes • Oven level %d/%d\n$%s per batch every %.2fs • %.2fx global income\nUse the Workshop to raise each recipe's value.",
			data.unlocked, #Recipes, data.level, Progression.MAX_OVEN_LEVEL, format(Progression.batchValue(data, data.perks)), Progression.interval(data, data.perks), Progression.multiplier(data, data.perks))
	end
	collectButton.Text = "Collect $" .. format(data.bank)
	enable(collectButton, canManage and data.bank > 0 and data.cash < Progression.MAX_CASH)
	local nextRecipe = Recipes[data.unlocked + 1]
	recipeButton.Text = nextRecipe and ("Unlock " .. nextRecipe.Name .. "\n" .. Crafting.rarity(nextRecipe).Name .. " • $" .. format(nextRecipe.Cost)) or "All 30 cookies unlocked!"
	enable(recipeButton, canManage and nextRecipe ~= nil and data.cash >= (nextRecipe and nextRecipe.Cost or 0))
	local ovenMax = data.level >= Progression.MAX_OVEN_LEVEL
	ovenButton.Text = ovenMax and "Ovens MAXED!" or ("Upgrade all ovens to level " .. (data.level + 1) .. "\n$" .. format(Progression.ovenCost(data)))
	enable(ovenButton, canManage and not ovenMax and data.cash >= Progression.ovenCost(data))
	local requirement = Progression.rebirthRequirement(data)
	local rebirthMax = data.rebirths >= Progression.MAX_REBIRTHS
	local canRebirth = canManage and not rebirthMax and data.unlocked >= requirement.Recipes and data.cash + data.bank >= requirement.Cash
	rebirthInfo.Text = rebirthMax and "You completed all 50 rebirths! Keep building your ultimate bakery."
		or string.format("Rebirth #%d earns %d Golden Chips.\nRecipes: %d/%d required\nCash + bank: $%s / $%s\nReset cash, uncollected earnings, recipes, oven levels, and recipe modifiers. Keep Golden Chips and permanent upgrades.",
			data.rebirths + 1, requirement.Reward, data.unlocked, requirement.Recipes, format(data.cash + data.bank), format(requirement.Cash))
	rebirthButton.Text = rebirthMax and "Maximum rebirths reached" or "Review rebirth  •  +" .. requirement.Reward .. " Golden Chips"
	enable(rebirthButton, canRebirth)
	if confirmation.Visible then
		if data.rebirths ~= confirmCount or not ownsBakery then confirmation.Visible = false end
		confirmationText.Text = "Start over for " .. requirement.Reward .. " Golden Chips? Your cash, bank, recipe unlocks, oven levels, and topping modifiers will reset. Golden Chips, permanent upgrades, rebirth bonuses, and owned passes stay."
		enable(confirmButton, canRebirth)
	end
	for key, upgradeButton in pairs(permanentButtons) do
		local upgrade = Progression.Permanent[key]
		local cost = Progression.permanentCost(data, key)
		upgradeButton.Text = upgrade.Name .. "  " .. data.permanent[key] .. "/" .. upgrade.Max .. "\n"
			.. (cost and cost .. " Golden Chips" or "MAXED") .. " • " .. upgrade.Description
		enable(upgradeButton, canManage and cost ~= nil and data.chips >= (cost or math.huge))
	end
	local selected = Recipes[selectedRecipe]
	local rarity = Crafting.rarity(selected)
	local flags = data.modifiers[tostring(selectedRecipe)]
	local unlocked = selectedRecipe <= data.unlocked
	recipeTitle.Text = selectedRecipe .. "/" .. #Recipes .. " • " .. selected.Name
	recipeTitle.TextColor3 = Color3.fromRGB(table.unpack(rarity.Color))
	workshopDetails.Text = rarity.Name .. " rarity • x" .. rarity.Multiplier .. " base value"
		.. "\nBase $" .. format(selected.Value) .. "  •  Toppings x" .. string.format("%.2f", Crafting.multiplier(flags))
		.. "  •  Global income x" .. string.format("%.2f", Progression.multiplier(data, data.perks))
		.. "\n" .. (unlocked and "Value: $" .. format(Progression.recipeValue(data, selectedRecipe, data.perks)) .. " per cookie"
			or "Locked • Unlock this recipe for $" .. format(selected.Cost))
	toppingSummary.Text = "Applied: " .. Crafting.summary(flags)
	enable(previousCookie, selectedRecipe > 1)
	enable(nextCookie, selectedRecipe < #Recipes)
	for key, addButton in pairs(modifierButtons) do
		local definition = Crafting.Modifiers[key]
		local cost = Crafting.cost(selected, key)
		local applied = flags and flags[key] == true
		addButton.Text = definition.Name .. "  +" .. math.floor(definition.Bonus * 100 + 0.5) .. "% value\n"
			.. (applied and "Applied to this recipe" or "$" .. format(cost) .. (unlocked and " to add" or " • Unlock recipe first"))
		enable(addButton, canManage and unlocked and not applied and data.cash >= cost)
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
previousCookie.Activated:Connect(function()
	selectedRecipe = math.max(1, selectedRecipe - 1)
	render()
end)
nextCookie.Activated:Connect(function()
	selectedRecipe = math.min(#Recipes, selectedRecipe + 1)
	render()
end)
openShop.OnClientEvent:Connect(function(tabName)
	if tabName == "Workshop" or tabName == "Bakery" then showTab(tabName) end
	menu.Visible = true
end)

local noticeVersion = 0
local function showNotice()
	local message = player:GetAttribute("Notice")
	if not message then return end
	noticeVersion += 1
	local version = noticeVersion
	toast.Text = message
	toast.Visible = true
	toast.Position = UDim2.new(0.5, 0, 1, 4)
	TweenService:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, -12),
	}):Play()
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
