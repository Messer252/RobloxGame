local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local AudioController = require(script:WaitForChild("AudioController"))
local VolumeSlider = require(script:WaitForChild("VolumeSlider"))
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("CookieTycoon")
local Recipes = require(shared:WaitForChild("Recipes"))
local Progression = require(shared:WaitForChild("Progression"))
local Crafting = require(shared:WaitForChild("CookieCrafting"))
local Catalog = require(shared:WaitForChild("ShopCatalog"))
local Boosts = require(shared:WaitForChild("Boosts"))
local Challenges = require(shared:WaitForChild("ChallengeCatalog"))
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
hud.Size = UDim2.new(0.94, 0, 0, 238)
hud.Position = UDim2.fromOffset(12, 12)
hud.BackgroundColor3 = Color3.fromRGB(53, 36, 32)
hud.BackgroundTransparency = 0.06
hud.Parent = gui
round(hud, 16)
local hudStroke = finish(hud, gold)
local hudLimit = Instance.new("UISizeConstraint")
hudLimit.MaxSize = Vector2.new(420, 238)
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
local brand = fixedLabel(hud, 8, 30, 21, gold)
brand.Position = UDim2.fromOffset(58, 8)
brand.Size = UDim2.new(1, -72, 0, 30)
brand.Text = "COOKIE CORNER"
local wallet = fixedLabel(hud, 38, 22, 17)
wallet.TextScaled = true
wallet.TextWrapped = false
local walletTextSize = Instance.new("UITextSizeConstraint")
walletTextSize.MinTextSize = 10
walletTextSize.MaxTextSize = 17
walletTextSize.Parent = wallet
local progress = fixedLabel(hud, 62, 18, 14)
progress.TextScaled = true
progress.TextWrapped = false
local progressTextSize = Instance.new("UITextSizeConstraint")
progressTextSize.MinTextSize = 10
progressTextSize.MaxTextSize = 15
progressTextSize.Parent = progress
local saveStatus = fixedLabel(hud, 82, 16, 11)
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
title.Text = "BAKERY"
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
local toggle = button(hud, "Bakery", Color3.fromRGB(130, 87, 49))
toggle.Position = UDim2.fromOffset(14, 106)
toggle.Size = UDim2.new(0.44, -16, 0, 30)
toggle.Activated:Connect(function() menu.Visible = not menu.Visible end)
local musicToggle = button(hud, "Music ON", Color3.fromRGB(66, 114, 100))
musicToggle.Name = "MusicToggle"
musicToggle.Position = UDim2.new(0.44, 4, 0, 106)
musicToggle.Size = UDim2.new(0.28, -12, 0, 30)
musicToggle.TextSize = 12
local effectsToggle = button(hud, "SFX ON", Color3.fromRGB(66, 114, 100))
effectsToggle.Name = "EffectsToggle"
effectsToggle.Position = UDim2.new(0.72, 0, 0, 106)
effectsToggle.Size = UDim2.new(0.28, -14, 0, 30)
effectsToggle.TextSize = 12
local drawMusicVolume = VolumeSlider.create(hud, "Music", 166,
	function() return audio.musicVolume end, function(value) audio:SetVolume("music", value) end)
local drawEffectsVolume = VolumeSlider.create(hud, "SFX", 200,
	function() return audio.effectsVolume end, function(value) audio:SetVolume("effects", value) end)
local function renderAudio()
	musicToggle.Text = audio.music and "Music ON" or "Music OFF"
	effectsToggle.Text = audio.effects and "SFX ON" or "SFX OFF"
	musicToggle.BackgroundColor3 = audio.music and Color3.fromRGB(66, 114, 100) or Color3.fromRGB(95, 75, 69)
	effectsToggle.BackgroundColor3 = audio.effects and Color3.fromRGB(66, 114, 100) or Color3.fromRGB(95, 75, 69)
	drawMusicVolume()
	drawEffectsVolume()
end
musicToggle.Activated:Connect(function() audio:SetMusicEnabled(not audio.music) end)
effectsToggle.Activated:Connect(function() audio:SetEffectsEnabled(not audio.effects) end)
audio.Changed.Event:Connect(renderAudio)
renderAudio()
local boostStatus = fixedLabel(hud, 143, 19, 12, gold)
boostStatus.TextScaled = true
local boostTextSize = Instance.new("UITextSizeConstraint")
boostTextSize.MinTextSize, boostTextSize.MaxTextSize, boostTextSize.Parent = 10, 12, boostStatus
local bakeryTab = button(menu, "Bakery", Color3.fromRGB(130, 87, 49))
local robuxTab = button(menu, "Shop", Color3.fromRGB(92, 66, 48))
local workshopTab = button(menu, "Toppings", Color3.fromRGB(92, 66, 48))
local challengesTab = button(menu, "Quests", Color3.fromRGB(92, 66, 48))
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
for index, tab in ipairs({ bakeryTab, workshopTab, challengesTab, robuxTab }) do
	tab.Parent = tabBar
	tab.LayoutOrder = index
	tab.Size = UDim2.new(0.25, -6, 1, 0)
	tab.TextSize = 13
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
local challengesScroll = scroll:Clone()
challengesScroll.Name = "Challenges"
challengesScroll.Visible = false
challengesScroll.Parent = menu
local function showTab(tabName)
	scroll.Visible = tabName == "Bakery"
	workshopScroll.Visible = tabName == "Workshop"
	shopScroll.Visible = tabName == "Robux"
	challengesScroll.Visible = tabName == "Challenges"
	title.Text = ({ Bakery = "YOUR BAKERY", Workshop = "COOKIE TOPPINGS", Robux = "ROBUX SHOP", Challenges = "BAKER'S QUESTS" })[tabName] or "YOUR BAKERY"
	for tab, name in pairs({ [bakeryTab] = "Bakery", [workshopTab] = "Workshop", [robuxTab] = "Robux", [challengesTab] = "Challenges" }) do
		tab.BackgroundColor3 = name == tabName and Color3.fromRGB(130, 87, 49) or Color3.fromRGB(92, 66, 48)
	end
end
bakeryTab.Activated:Connect(function() showTab("Bakery") end)
workshopTab.Activated:Connect(function() showTab("Workshop") end)
robuxTab.Activated:Connect(function() showTab("Robux") end)
challengesTab.Activated:Connect(function() showTab("Challenges") end)
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
local ovenButton = ordered(button(scroll, "Faster conveyor", Color3.fromRGB(103, 82, 147)))
local goldenToggle = ordered(button(scroll, "Golden Chips & rebirth  +", Color3.fromRGB(113, 87, 39)))
goldenToggle.Size = UDim2.new(1, 0, 0, 44)
local goldenSection = ordered(Instance.new("Frame"))
goldenSection.Name = "GoldenUpgrades"
goldenSection.Size = UDim2.new(1, 0, 0, 0)
goldenSection.AutomaticSize = Enum.AutomaticSize.Y
goldenSection.BackgroundTransparency = 1
goldenSection.Visible = false
goldenSection.Parent = scroll
list(goldenSection)
local rebirthInfo = ordered(text(goldenSection, ""))
local rebirthButton = ordered(button(goldenSection, "Rebirth", Color3.fromRGB(145, 94, 31)))
local confirmation = ordered(Instance.new("Frame"))
confirmation.Size = UDim2.new(1, 0, 0, 0)
confirmation.AutomaticSize = Enum.AutomaticSize.Y
confirmation.BackgroundTransparency = 1
confirmation.Visible = false
confirmation.Parent = goldenSection
list(confirmation)
local confirmationText = text(confirmation, "")
confirmationText.LayoutOrder = 1
local confirmButton = button(confirmation, "Confirm rebirth", Color3.fromRGB(154, 65, 51))
confirmButton.LayoutOrder = 2
local cancelButton = button(confirmation, "Keep baking")
cancelButton.LayoutOrder = 3
cancelButton.Size = UDim2.new(1, 0, 0, 40)
local confirmCount
goldenToggle.Activated:Connect(function()
	goldenSection.Visible = not goldenSection.Visible
	goldenToggle.Text = "Golden Chips & rebirth  " .. (goldenSection.Visible and "−" or "+")
	if not goldenSection.Visible then confirmation.Visible = false end
end)

ordered(text(goldenSection, "KEEP FOREVER", 16, gold))
local permanentButtons = {}
for _, key in ipairs(Progression.PermanentOrder) do
	local upgradeButton = ordered(button(goldenSection, "", Color3.fromRGB(113, 87, 39)))
	upgradeButton.Size = UDim2.new(1, 0, 0, 72)
	permanentButtons[key] = upgradeButton
	upgradeButton.Activated:Connect(function() requestAction:FireServer("UpgradePermanent", key) end)
end

ordered(text(workshopScroll, "Upgrade this recipe's future cookies. Toppings stack; reset on rebirth.", 13))
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
local workshopDetails = ordered(text(workshopScroll, "", 18, gold))
local toppingSummary = ordered(text(workshopScroll, "", 13))
local modifierButtons = {}
for _, key in ipairs(Crafting.ModifierOrder) do
	local definition = Crafting.Modifiers[key]
	local rgb = definition.Color
	local addButton = ordered(button(workshopScroll, definition.Name, Color3.fromRGB(rgb[1] * 0.35, rgb[2] * 0.35, rgb[3] * 0.35)))
	addButton.Size = UDim2.new(1, 0, 0, 56)
	modifierButtons[key] = addButton
	addButton.Activated:Connect(function()
		requestAction:FireServer("BuyModifier", { Recipe = selectedRecipe, Modifier = key })
	end)
end

local challengeName = ordered(text(challengesScroll, "Baker Biscuit", 21, gold))
local challengeHint = ordered(text(challengesScroll, "Find Baker Biscuit in the plaza."))
local challengeProgress = ordered(text(challengesScroll, "", 17, gold))
local challengeItems = {}
for index = 1, 3 do
	local row = ordered(text(challengesScroll, "", 15))
	table.insert(challengeItems, row)
end
local challengeButton = ordered(button(challengesScroll, "Visit Baker Biscuit", Color3.fromRGB(66, 114, 100)))
local challengeStatus = ordered(text(challengesScroll, "", 13))
challengeButton.Activated:Connect(function() requestAction:FireServer("ChallengeAction") end)

ordered(text(shopScroll, "Optional. Roblox confirms every purchase and its final price.", 13))
local shopStatus = ordered(text(shopScroll, "Loading shop...", 15, gold))
ordered(text(shopScroll, "PASSES • KEEP FOREVER", 16, gold))
local shopRows = {}
local priceMetadata = {}
local pricesLoading = false
local function shopRow(kind, key, entry)
	local purchaseButton = ordered(button(shopScroll, entry.Name, Color3.fromRGB(101, 113, 65)))
	purchaseButton.Size = UDim2.new(1, 0, 0, 70)
	table.insert(shopRows, { Kind = kind, Key = key, Entry = entry, Button = purchaseButton })
	purchaseButton.Activated:Connect(function() requestPurchase:FireServer(kind, key) end)
end
for _, key in ipairs(Catalog.PassOrder) do shopRow("Pass", key, Catalog.Passes[key]) end
ordered(text(shopScroll, "PERMANENT INCOME • NEXT STAGE", 16, gold))
ordered(text(shopScroll, "Stacks with passes. Stays after rebirth.", 13))
for _, key in ipairs(Catalog.ProductOrder) do
	if Catalog.Products[key].BoostTier then shopRow("Product", key, Catalog.Products[key]) end
end
ordered(text(shopScroll, "CASH • RESETS ON REBIRTH", 16, gold))
for _, key in ipairs(Catalog.ProductOrder) do
	if Catalog.Products[key].Cash then shopRow("Product", key, Catalog.Products[key]) end
end
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
			Now = math.floor(workspace:GetServerTimeNow()),
		},
		boosts = {
			paidTier = player:GetAttribute("PaidBoostTier") or 0,
			obbyBonus = player:GetAttribute("ObbyBonus") or 0,
			obbyExpires = player:GetAttribute("ObbyExpires") or 0,
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

local function renderChallenges(ready, purchasePending)
	local index = player:GetAttribute("ChallengeIndex") or 1
	local challenge = Challenges.Challenges[index]
	local active = player:GetAttribute("ChallengeActive") == true
	local mask = player:GetAttribute("ChallengeFound") or 0
	local nearNPC = player:GetAttribute("NearChallengeNPC") == true
	if player:GetAttribute("ChallengeComplete") == true or not challenge then
		challengeName.Text = "Excellent detective!"
		challengeHint.Text = "You found all of Baker Biscuit's hidden treasures."
		challengeProgress.Text = "All quests complete"
		for _, row in ipairs(challengeItems) do row.Visible = false end
		challengeButton.Text = "All done!"
		challengeStatus.Text = "Completed quests stay complete after rebirth."
		enable(challengeButton, false)
		return
	end
	challengeName.Text = challenge.Name
	challengeHint.Text = challenge.Hint
	local found = 0
	for itemIndex, row in ipairs(challengeItems) do
		local item = Challenges.Items[challenge.Items[itemIndex]]
		row.Visible = active and item ~= nil
		if item then
			local collected = bit32.band(mask, bit32.lshift(1, itemIndex - 1)) ~= 0
			if collected then found += 1 end
			row.Text = (collected and "✓ " or "○ ") .. item.Name .. (collected and "" or "\n" .. item.Hint)
			row.TextColor3 = collected and Color3.fromRGB(151, 218, 182) or cream
		end
	end
	challengeProgress.Text = "$" .. Progression.format(challenge.Reward) .. " reward"
		.. (active and "  •  " .. found .. "/" .. #challenge.Items .. " found" or "")
	local canClaim = active and found == #challenge.Items
	if not ready then challengeButton.Text = "Loading..."
	elseif not nearNPC then challengeButton.Text = "Visit Baker Biscuit"
	elseif not active then challengeButton.Text = "Start quest"
	elseif canClaim then challengeButton.Text = "Claim $" .. Progression.format(challenge.Reward)
	else challengeButton.Text = "Find " .. (#challenge.Items - found) .. " more" end
	enable(challengeButton, ready and not purchasePending and nearNPC and (not active or canClaim))
	challengeStatus.Text = active and (canClaim and "Return to Baker Biscuit in the plaza." or "Find each hidden item and interact with it.")
		or "Visit Baker Biscuit in the plaza to begin."
end

-- Quest props are shared world instances; hide collected and inactive items
-- locally so every player can finish their own hunt without affecting others.
local function refreshChallengeItems()
	local world = workspace:FindFirstChild("CookieTycoonWorld")
	local questWorld = world and world:FindFirstChild("Challenges")
	local hidden = questWorld and questWorld:FindFirstChild("HiddenItems")
	if not hidden then return end
	local current = player:GetAttribute("ChallengeIndex") or 1
	local active = player:GetAttribute("ChallengeActive") == true
	local mask = player:GetAttribute("ChallengeFound") or 0
	for _, model in ipairs(hidden:GetChildren()) do
		local questIndex = model:GetAttribute("ChallengeQuestIndex")
		local definition = Challenges.Challenges[questIndex]
		local itemIndex = definition and table.find(definition.Items, model:GetAttribute("ChallengeItemId"))
		local visible = active and questIndex == current and itemIndex ~= nil
			and bit32.band(mask, bit32.lshift(1, itemIndex - 1)) == 0
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then descendant.LocalTransparencyModifier = visible and 0 or 1
			elseif descendant:IsA("ProximityPrompt") or descendant:IsA("BillboardGui") or descendant:IsA("PointLight") then descendant.Enabled = visible end
		end
	end
end

local saveMessages = {
	Loading = "Loading...",
	Saved = "Saved",
	Saving = "Saving...",
	SaveFailed = "Save delayed • retrying",
	SessionOnly = "Preview • not saved",
	PurchasePending = "Saving purchase...",
}
local function render()
	local data = currentData()
	local ready = player:GetAttribute("DataReady") == true
	local ownsBakery = ready and player:GetAttribute("HasBakery") == true
	local purchasePending = player:GetAttribute("PurchasePending") == true
	local canManage = ownsBakery and not purchasePending
	local format = Progression.format
	local remaining = math.max(0, data.boosts.obbyExpires - data.perks.Now)
	boostStatus.Text = "Permanent income x" .. Boosts.paidMultiplier(data.boosts)
		.. (remaining > 0 and string.format(" • Obby +%d%% %d:%02d", math.floor(data.boosts.obbyBonus * 100), math.floor(remaining / 60), remaining % 60)
			or " • Obbys in the east meadow")
	if lastWorkshopRebirth ~= data.rebirths then
		selectedRecipe = math.min(selectedRecipe, data.unlocked)
		lastWorkshopRebirth = data.rebirths
	end
	wallet.Text = "Cash $" .. format(data.cash) .. "  |  Ready $" .. format(data.bank)
	progress.Text = data.unlocked .. "/" .. #Recipes .. " cookies  •  " .. data.chips .. " Golden Chips"
	menuWallet.Text = "$" .. format(data.cash) .. "  •  " .. data.chips .. " Golden Chips"
	local status = player:GetAttribute("DataStatus") or "Loading"
	saveStatus.Text = saveMessages[status] or status
	saveStatus.TextColor3 = (status == "SaveFailed" or status == "SessionOnly") and gold or cream
	if not ready then
		bakeryInfo.Text = "Loading your bakery..."
	elseif purchasePending then
		bakeryInfo.Text = "Saving purchase..."
	elseif not ownsBakery then
		bakeryInfo.Text = "Claim a free bakery at a green pad."
	else
		bakeryInfo.Text = string.format("$%s per batch  •  Every %.2fs",
			format(Progression.batchValue(data, data.perks)), Progression.interval(data, data.perks))
	end
	collectButton.Text = "Collect $" .. format(data.bank)
	enable(collectButton, canManage and data.bank > 0 and data.cash < Progression.MAX_CASH)
	local nextRecipe = Recipes[data.unlocked + 1]
	recipeButton.Text = nextRecipe and (nextRecipe.Name .. "  •  $" .. format(nextRecipe.Cost) .. "\nUnlock next cookie") or "All 30 cookies unlocked!"
	enable(recipeButton, canManage and nextRecipe ~= nil and data.cash >= (nextRecipe and nextRecipe.Cost or 0))
	local ovenMax = data.level >= Progression.MAX_OVEN_LEVEL
	ovenButton.Text = ovenMax and "Conveyor speed maxed!" or ("Faster conveyor  •  $" .. format(Progression.ovenCost(data)) .. "\nSpeed level " .. data.level .. " → " .. (data.level + 1))
	enable(ovenButton, canManage and not ovenMax and data.cash >= Progression.ovenCost(data))
	local requirement = Progression.rebirthRequirement(data)
	local rebirthMax = data.rebirths >= Progression.MAX_REBIRTHS
	local canRebirth = canManage and not rebirthMax and data.unlocked >= requirement.Recipes and data.cash + data.bank >= requirement.Cash
	rebirthInfo.Text = rebirthMax and "All 50 rebirths completed!"
		or string.format("Rebirth #%d  •  +%d Golden Chips\n%d/%d cookies  •  $%s/$%s cash + ready",
			data.rebirths + 1, requirement.Reward, data.unlocked, requirement.Recipes, format(data.cash + data.bank), format(requirement.Cash))
	rebirthButton.Text = rebirthMax and "Rebirths complete" or "Review rebirth"
	enable(rebirthButton, canRebirth)
	if confirmation.Visible then
		if data.rebirths ~= confirmCount or not ownsBakery then confirmation.Visible = false end
		confirmationText.Text = "Start over for " .. requirement.Reward .. " Golden Chips and +15% income?\nReset: cash, ready earnings, cookies, conveyor levels and toppings.\nKeep: Golden Chips, permanent upgrades, quests and passes."
		enable(confirmButton, canRebirth)
	end
	for key, upgradeButton in pairs(permanentButtons) do
		local upgrade = Progression.Permanent[key]
		local cost = Progression.permanentCost(data, key)
		local effect = key == "Yield" and "+25% income" or key == "Speed" and "+8% baking speed"
			or "$" .. format(500 * math.min(upgrade.Max, data.permanent[key] + 1) ^ 2) .. " after rebirth"
		upgradeButton.Text = upgrade.Name .. "  " .. data.permanent[key] .. "/" .. upgrade.Max .. "\n"
			.. (cost and cost .. " chips • " .. effect or "MAXED")
		enable(upgradeButton, canManage and cost ~= nil and data.chips >= (cost or math.huge))
	end
	local selected = Recipes[selectedRecipe]
	local rarity = Crafting.rarity(selected)
	local flags = data.modifiers[tostring(selectedRecipe)]
	local unlocked = selectedRecipe <= data.unlocked
	recipeTitle.Text = selectedRecipe .. "/" .. #Recipes .. " • " .. selected.Name
	recipeTitle.TextColor3 = Color3.fromRGB(table.unpack(rarity.Color))
	workshopDetails.Text = rarity.Name .. "  •  " .. (unlocked and "$" .. format(Progression.recipeValue(data, selectedRecipe, data.perks)) .. " / cookie"
		or "Unlock for $" .. format(selected.Cost))
	toppingSummary.Text = "Toppings: " .. Crafting.summary(flags)
	enable(previousCookie, selectedRecipe > 1)
	enable(nextCookie, selectedRecipe < #Recipes)
	for key, addButton in pairs(modifierButtons) do
		local definition = Crafting.Modifiers[key]
		local cost = Crafting.cost(selected, key)
		local applied = flags and flags[key] == true
		addButton.Text = definition.Name .. "  +" .. math.floor(definition.Bonus * 100 + 0.5) .. "%\n"
			.. (applied and "✓ Added" or "$" .. format(cost) .. (unlocked and "" or " • Recipe locked"))
		enable(addButton, canManage and unlocked and not applied and data.cash >= cost)
	end
	local commerceReady = ready and player:GetAttribute("CommerceReady") == true
	local promptOpen = player:GetAttribute("ShopPromptOpen") == true
	local configured = false
	for _, row in ipairs(shopRows) do
		local offer = Catalog.offer(row.Kind, row.Key)
		configured = configured or offer ~= nil
		local metadata = priceMetadata[row.Kind .. ":" .. row.Key]
		local tier = row.Entry.BoostTier
		row.Button.Visible = not tier or tier == data.boosts.paidTier + 1 or (data.boosts.paidTier == Boosts.MaxPaidTier and tier == Boosts.MaxPaidTier)
		local owned = row.Kind == "Pass" and player:GetAttribute(row.Key .. "Owned") == true
			or tier ~= nil and data.boosts.paidTier >= tier
		local priceLine
		if owned then priceLine = "Owned • Permanent"
		elseif not offer then priceLine = "Coming soon"
		elseif not metadata or metadata.State == "Loading" then priceLine = "Checking price..."
		elseif metadata.State ~= "Ready" then priceLine = "Currently unavailable"
		else priceLine = "R$ " .. metadata.Price .. (tier and " • Permanent" or row.Kind == "Pass" and " • Buy once" or " • Repeatable") end
		if row.Kind == "Pass" or tier then
			row.Button.Text = row.Entry.Name .. "\n" .. priceLine
		else
			row.Button.Text = "$" .. format(row.Entry.Cash) .. " Cookie Cash\n" .. priceLine
		end
		local ownershipReady = row.Kind ~= "Pass" or player:GetAttribute("PassesReady") == true
		enable(row.Button, commerceReady and not purchasePending and not promptOpen and not owned and offer ~= nil
			and ownershipReady and metadata ~= nil and metadata.State == "Ready")
	end
	if purchasePending then shopStatus.Text = "Saving purchase..."
	elseif not configured then shopStatus.Text = "Coming soon • Keep baking for free!"
	elseif not ready then shopStatus.Text = "Loading your bakery..."
	elseif not commerceReady then shopStatus.Text = "Purchases unavailable this session."
	elseif promptOpen then shopStatus.Text = "Finish the Roblox purchase window."
	else
		shopStatus.Text = "Active: " .. (data.perks.DoubleIncome and "2x income" or "standard income")
			.. " • " .. (data.perks.DoubleSpeed and "2x speed" or "standard speed")
	end
	enable(refreshShopButton, not pricesLoading and not purchasePending and not promptOpen)
	renderChallenges(ready, purchasePending)
	refreshChallengeItems()
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
	if tabName == "Workshop" or tabName == "Bakery" or tabName == "Challenges" or tabName == "Robux" then showTab(tabName) end
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
task.spawn(function()
	while gui.Parent do
		task.wait(1)
		scheduleRender()
	end
end)
workspace.DescendantAdded:Connect(function(descendant)
	if descendant:GetAttribute("ChallengeItemId") ~= nil or descendant:FindFirstAncestor("HiddenItems") then scheduleRender() end
end)
render()
showNotice()
refreshPrices()
