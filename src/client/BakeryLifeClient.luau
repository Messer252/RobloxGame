local Players, Lighting, RunService = game:GetService("Players"), game:GetService("Lighting"), game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").CookieTycoon
local Life, Recipes, Progression, Polish = require(Shared.BakeryLife), require(Shared.Recipes), require(Shared.Progression), require(Shared.BakeryPolish)
local CardUI = require(script.Parent.CardPacksClient)
local CollectionService = game:GetService("CollectionService")
local Enchant = require(Shared.Enchantments)
local Town,Blueprint=require(Shared.TownCatalog),require(Shared.BakeryBlueprint)
local Flow=require(script.Parent.UIFlow)
local Mine=require(Shared.MiningCatalog)
local MenuRows=require(script.Parent.MenuRows)
local Client = {}
function Client.start(player, remotes, gui, hud, openButton, audio)
	local action, stateRemote, open = remotes:WaitForChild("LifeAction"), remotes:WaitForChild("LifeState"), remotes:WaitForChild("OpenLife")
	local snapshot, tab, renameDraft = { life = Life.normalize(nil) }, "Bag", ""
	local connections = {}
	local showEnchant = false
	local announcement = Instance.new("Frame")
	announcement.Name, announcement.AnchorPoint = "MeteorAnnouncement", Vector2.new(.5, 0)
	announcement.Size, announcement.Position = UDim2.new(.9, 0, 0, 84), UDim2.new(.5, 0, 0, 22)
	announcement.BackgroundColor3, announcement.BorderSizePixel = Color3.fromRGB(55, 35, 30), 0
	announcement.Visible, announcement.ZIndex, announcement.Parent = false, 80, gui
	local announcementLimit = Instance.new("UISizeConstraint")
	announcementLimit.MaxSize, announcementLimit.Parent = Vector2.new(590, 84), announcement
	local announcementCorner = Instance.new("UICorner")
	announcementCorner.CornerRadius, announcementCorner.Parent = UDim.new(0, 14), announcement
	local announcementStroke = Instance.new("UIStroke")
	announcementStroke.Color, announcementStroke.Thickness, announcementStroke.Parent = Color3.fromRGB(255, 184, 87), 2, announcement
	local headline, detail
	for index = 1, 2 do
		local text = Instance.new("TextLabel")
		text.BackgroundTransparency, text.TextWrapped, text.TextScaled = 1, true, true
		text.Position, text.Size = UDim2.fromOffset(12, index == 1 and 8 or 39), UDim2.new(1, -24, 0, index == 1 and 27 or 36)
		text.Font, text.TextColor3, text.ZIndex, text.Parent = Enum.Font.GothamBold, Color3.fromRGB(255, 229, 184), 81, announcement
		local size = Instance.new("UITextSizeConstraint")
		size.MinTextSize, size.MaxTextSize, size.Parent = 11, index == 1 and 22 or 14, text
		if index == 1 then headline = text else detail = text end
	end
	local announcementVersion = 0
	table.insert(connections, remotes:WaitForChild("WorldAnnouncement").OnClientEvent:Connect(function(kind)
		if kind ~= "Incoming" and kind ~= "Impact" then return end
		announcementVersion += 1
		local version = announcementVersion
		local camera = workspace.CurrentCamera
		local compact = not camera or camera.ViewportSize.X < 1100
		announcement.AnchorPoint = Vector2.new(compact and .5 or 1, 0)
		announcement.Position = compact and UDim2.new(.5,0,0,hud.Position.Y.Offset+hud.AbsoluteSize.Y+10) or UDim2.new(1, -20, 0, 22)
		headline.Text = kind == "Incoming" and "COOKIE METEOR INCOMING!" or "COOKIE METEOR LANDED!"
		detail.Text = kind == "Incoming" and "Watch the sky! A Star Crumb meteor is falling." or "Follow the fire. Land 3 rolling-pin hits to earn Star Crumbs."
		announcement.Visible = true
		audio:PlayCue(kind == "Incoming" and "MeteorIncoming" or "MeteorCrash")
		task.delay(kind == "Incoming" and 6 or 9, function()
			if announcement.Parent and version == announcementVersion then announcement.Visible = false end
		end)
	end))
	CardUI.start(remotes, gui,audio)
	local shade = Instance.new("TextButton")
	shade.Size, shade.Text, shade.BackgroundTransparency, shade.BackgroundColor3, shade.ZIndex, shade.Visible, shade.Parent = UDim2.fromScale(1, 1), "", 0.35, Color3.new(), 25, false, gui
	local panel = Instance.new("Frame")
	panel:SetAttribute("BlocksCameraLock",true)
	panel.AnchorPoint, panel.Position, panel.Size, panel.BackgroundColor3, panel.ZIndex, panel.Visible, panel.Parent = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.94, 0.88), Color3.fromRGB(54, 39, 33), 26, false, gui
	local size = Instance.new("UISizeConstraint")
	size.MaxSize, size.Parent = Vector2.new(520, 650), panel
	local function label(parent, text)
		local t = Instance.new("TextLabel")
		t.Size, t.AutomaticSize, t.BackgroundTransparency, t.Text = UDim2.new(1, -8, 0, 0), Enum.AutomaticSize.Y, 1, text
		t.TextSize, t.Font, t.TextColor3, t.TextWrapped, t.ZIndex, t.Parent = 15, Enum.Font.GothamBold, Color3.fromRGB(255, 236, 209), true, 28, parent
		return t
	end
	local function button(parent, text, callback)
		local b = Instance.new("TextButton")
		b.Size, b.Text, b.TextWrapped, b.TextSize, b.Font = UDim2.new(1, -8, 0, 48), text, true, 14, Enum.Font.GothamBold
		b.BackgroundColor3, b.TextColor3, b.BorderSizePixel, b.ZIndex, b.Parent = Color3.fromRGB(75, 119, 103), Color3.fromRGB(255, 236, 209), 0, 28, parent
		local c = Instance.new("UICorner")
		c.CornerRadius, c.Parent = UDim.new(0, 9), b
		b:GetPropertyChangedSignal("Interactable"):Connect(function()
			b.BackgroundTransparency, b.TextTransparency = b.Interactable and 0 or .4, b.Interactable and 0 or .35
		end)
		b.Activated:Connect(callback)
		return b
	end
	local header = label(panel, "COOKIE BAG")
	header.Position, header.Size = UDim2.fromOffset(14, 12), UDim2.new(1, -70, 0, 28)
	header.AutomaticSize=Enum.AutomaticSize.None
	local close = button(panel, "X", function() panel.Visible, shade.Visible = false, false end)
	close.Position, close.Size = UDim2.new(1, -48, 0, 10), UDim2.fromOffset(34, 34)
	shade.Activated:Connect(function() panel.Visible, shade.Visible = false, false end)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Position, scroll.Size, scroll.BackgroundTransparency, scroll.BorderSizePixel = UDim2.fromOffset(14, 100), UDim2.new(1, -28, 1, -114), 1, 0
	scroll.CanvasSize, scroll.AutomaticCanvasSize, scroll.ScrollBarThickness, scroll.ZIndex, scroll.Parent = UDim2.new(), Enum.AutomaticSize.Y, 4, 27, panel
	local layout = Instance.new("UIListLayout")
	layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0, 9), Enum.SortOrder.LayoutOrder, scroll
	local function send(name, argument) action:FireServer(name, argument) end
	local rows = MenuRows.new(function(kind, activate)
		if kind == "Button" then return button(scroll, "", activate) end
		if kind == "Label" then return label(scroll, "") end
		local input = Instance.new("TextBox")
		input.Size, input.PlaceholderText, input.Text = UDim2.new(1,-8,0,40), "New bakery name (3–40 characters)", renameDraft
		input.ClearTextOnFocus, input.TextSize, input.ZIndex, input.Parent = false, 14, 28, scroll
		input.BackgroundColor3, input.TextColor3, input.PlaceholderColor3 = Color3.fromRGB(77,62,53), Color3.fromRGB(255,236,209), Color3.fromRGB(192,177,157)
		input.Font, input.BorderSizePixel = Enum.Font.Gotham, 0
		local corner=Instance.new("UICorner"); corner.CornerRadius,corner.Parent=UDim.new(0,9),input
		input:GetPropertyChangedSignal("Text"):Connect(function() renameDraft = input.Text end)
		return input
	end)
	local render
	local tabBar=Instance.new("Frame")
	tabBar.Position,tabBar.Size,tabBar.BackgroundTransparency,tabBar.ZIndex,tabBar.Parent=UDim2.fromOffset(14,53),UDim2.new(1,-28,0,38),1,28,panel
	local tabHeight=38
	local function placeContent()
		local market=tab=="PackShop" or tab=="Blacksmith"
		tabBar.Visible=not market
		local top=market and 58 or 65+tabHeight
		scroll.Position,scroll.Size=UDim2.fromOffset(14,top),UDim2.new(1,-28,1,-top-14)
	end
	local tabButtons={}
	for _, name in ipairs({ "Bag", "Mine", "Machines", "People", "Collection" }) do
		local b = button(panel, name, function() tab = name ; render() end)
		table.insert(tabButtons,b)
	end
	Flow.grid(tabBar,tabButtons,85,5,8,38,function(height) tabHeight=height; placeContent() end)
	render = function()
		placeContent()
		if rows:Begin(tab) then scroll.CanvasPosition = Vector2.zero end
		header.Text = ({ Bag = "COOKIE BAG", Mine = "DOUGH MINE", Machines = "BAKERY DESIGN", People = "COOKIES & COMPANY", Collection = "CARD COLLECTION",PackShop="CRUMBKIN PACK HOUSE",Blacksmith="BRUNO'S CRUSTFORGE" })[tab]
		local count = 0
		local function row(text, callback, key)
			count += 1
			local element = rows:Get(key or "row:" .. count, callback and "Button" or "Label", callback)
			element.Text, element.Visible, element.LayoutOrder = text, true, count
			element.Size = UDim2.new(1,-8,0,callback and 48 or 0)
			element.AutomaticSize = Enum.AutomaticSize.Y
			if callback then element.BackgroundColor3 = Color3.fromRGB(75,119,103) end
			if callback then element.Interactable = not snapshot.busy and (tab~="PackShop" or snapshot.nearPackShop) and (tab~="Blacksmith" or snapshot.nearBlacksmith) end
			return element
		end
		local data = snapshot.life
		local wallet = snapshot.cash or 0
		local nearby = snapshot.nearby or { decorations = {}, machines = {} }
		local function purchase(text, cost, balance, near, callback, key)
			local hint = balance < cost and (" • Need " .. Progression.format(cost - balance) .. " more") or not near and " • Visit pad" or ""
			local control = row(text .. hint, callback, key)
			control.Interactable = control.Interactable and near == true and balance >= cost
			return control
		end
		row(snapshot.busy and "Finishing a save. Please wait…" or "").Visible = snapshot.busy == true
		if tab == "Collection" then
			CardUI.renderCollection(player, data.cards, row, send, panel)
		elseif tab=="PackShop" then
			row(snapshot.nearPackShop and "Packs & daily gifts" or "Return to the Pack House in the side market to shop.")
			CardUI.renderPacks(data.cards,row,send)
		elseif tab=="Blacksmith" then
			row(snapshot.nearBlacksmith and ("Wallet $"..Progression.format(wallet)) or "Visit Bruno’s stall in the side market to purchase gear.")
			row("Rolling pin: "..Life.PinNames[data.pin].." • power "..string.format("%.1f",Life.miningPower(data)))
			row("Cave access: "..Mine.Zones[math.min(data.pin,#Mine.Zones)].Name)
			local pinCost=Life.PinCosts[data.pin+1]
			if pinCost then purchase("Buy "..Life.PinNames[data.pin+1].." rolling pin • $"..Progression.format(pinCost),pinCost,wallet,snapshot.nearBlacksmith,function() send("Pin") end,"pin-upgrade") else row("Best rolling pin owned") end
			local armor=Town.Armor[data.armor]
			row(armor and ("Wearing "..armor.Name.." • "..math.floor(armor.Defense*100).."% pin defense") or "No cookie armor equipped")
			local nextArmor=Town.Armor[data.armor+1]
			if nextArmor then purchase("Buy "..nextArmor.Name.." • $"..Progression.format(nextArmor.Cost).."\n"..math.floor(nextArmor.Defense*100).."% defense",nextArmor.Cost,wallet,snapshot.nearBlacksmith,function() send("Armor") end,"armor-upgrade") else row("Best cookie armor owned") end
			row("Gear & enchantments stay through upgrades and rebirth.")
			row((showEnchant and "Hide enchantments" or "Enchant equipment").." • "..data.cards.crumbs.." Star Crumbs",function() showEnchant=not showEnchant; render() end,"enchant-section")
			if showEnchant then
				row("100 crumbs per roll. Equal or weaker rolls still cost crumbs; your best result stays.")
				row("Odds: Common 50% • Uncommon 28% • Rare 15% • Legendary 6% • Mythical 1%")
				for _,slot in ipairs({"Pin","Armor"}) do
					local rank=data.enchants[slot]
					local rarity=Enchant.Rarities[rank]
					local effect=Enchant.effect(data,slot)
					local bonus=slot=="Pin" and (" • +"..math.floor(effect.Mine*100).."% mining, +"..effect.Damage.." damage") or (" • +"..math.floor(effect.Defense*100).."% defense")
					row(slot..": "..(rarity and rarity.Name or "Unenchanted")..bonus)
					if rank<#Enchant.Rarities and (slot=="Pin" or data.armor>0) then
						local target=slot
						purchase("Enchant "..target.." • 100 Star Crumbs",Enchant.Cost,data.cards.crumbs,snapshot.nearBlacksmith,function() send("Enchant",target) end,"enchant-"..target)
					end
				end
			end
		elseif tab == "Bag" then
			row(#data.inventory .. "/" .. Life.capacity(data) .. " cookies • Hold a conveyor cookie's pickup prompt to store it.")
			if snapshot.held then row("Eat held cookie • recipe buff + cookie skin", function() send("Eat", snapshot.held) end) end
			if data.oven.id then row("Finishing oven: " .. math.max(0, data.oven.ready - os.time()) .. "s remaining",nil,"oven-timer") end
			for _, cookie in ipairs(data.inventory) do
				local item = cookie
				local held = snapshot.held == item.id
				local buff = Polish.buff(item.recipe)
				local entry = row(Recipes[item.recipe].Name .. " • $" .. Progression.format(Life.value(item)) .. (item.baked and " • Finished" or "") .. "\n" .. buff.Name .. ": " .. Polish.describe(item.recipe) .. "\n" .. (data.oven.id == item.id and "In finishing oven" or held and "Holding • click/tap tool to eat" or "Tap to hold"), function() send("Equip", item.id) end,"cookie:"..item.id)
				entry.Size = UDim2.new(1, -8, 0, 76)
				entry.Interactable = entry.Interactable and data.oven.id ~= item.id
			end
		elseif tab == "Mine" then
			row("Dough: " .. data.dough .. " • " .. Life.PinNames[data.pin] .. " rolling pin (" .. data.pin .. "/" .. #Life.PinNames .. ")")
			for tier,zone in ipairs(Mine.Zones) do row((tier<=data.pin and "✓ " or "Locked • ")..zone.Name.." • "..Life.PinNames[tier].." pin") end
			row("Deeper galleries have better ore pools. Ore rarity changes when a node respawns.")
			row("Left-click with your pin near cave ore. Buy better pins and armor from Bruno in the side market.")
			for _, key in ipairs({ "Mixing", "Flow", "Pockets" }) do
				local level, definition = data.upgrades[key], Life.DoughUpgrades[key]
				local bonus = ({ Mixing = "+10% cookie income", Flow = "+5% baking speed", Pockets = "+4 cookie slots" })[key]
				if level == definition.Max then row(key .. " • MAX", nil, "dough:"..key)
				else
					local cost = definition.Cost * 2^level
					purchase(key.." "..level.."/"..definition.Max.." • "..bonus.."\n"..cost.." dough",cost,data.dough,nearby.mine,function() send("Dough",key) end,"dough:"..key)
				end
			end
		elseif tab == "Machines" then
			row("Visit the pads beside your own conveyor to build, decorate, or install machines.")
			count += 1
			local name = rows:Get("shop-name", "Input")
			name.LayoutOrder = count
			purchase("Rename cookie shop • $20 million",20000000,wallet,snapshot.hasPlot,function() send("RenameShop",name.Text) end,"rename")
			local beltCost = Polish.BeltCosts[data.belt + 1]
			if beltCost then purchase("Build conveyor line "..(data.belt+1).." • "..(beltCost==0 and "FREE" or "$"..Progression.format(beltCost)),beltCost,wallet,nearby.build,function() send("BuildBelt") end,"build")
			else row("All three conveyor lines built",nil,"build") end
			for _, key in ipairs(Blueprint.available(data)) do
				local definition = Polish.Decorations[key]
				purchase(definition.Name.." • $"..Progression.format(definition.Cost),definition.Cost,wallet,nearby.decorations[key],function() send("Decoration",key) end,"decoration:"..key)
			end
			for _, key in ipairs({ "Packager", "Boxer", "FinishingOven" }) do
				local owned = data.machines[key]
				if Life.machineAvailable(data,key) then purchase(key.." • $"..Progression.format(Life.Machines[key].Cost),Life.Machines[key].Cost,wallet,nearby.machines[key],function() send("Machine",key) end,"machine:"..key)
				elseif owned then row(key.." installed") end
			end
			if data.machines.FinishingOven then
				local control=row("Finish held cookie • 20s • 3× value",function() send("Bake") end,"finish-cookie")
				local held=Life.find(data,snapshot.held)
				control.Interactable=control.Interactable and nearby.machines.FinishingOven==true and held~=nil and not held.baked and not data.oven.id
			end
		else
			local trade, bargain = snapshot.trade, snapshot.bargain
			if trade then
				row("FREE COOKIE GIFT\n@" .. trade.from .. " → @" .. trade.to .. "\n" .. trade.giveA .. "\nNo cash or return cookie is required.")
				row(trade.confirmed and "You confirmed • waiting for the other player" or (player.Name == trade.from and "Confirm sending gift" or "Accept free cookie"), function() send("ConfirmTrade", trade.id) end)
				row("Decline / cancel", function() send("CancelTrade") end)
			elseif bargain then
				row(bargain.name .. " • " .. bargain.personality .. "\nFavorite: " .. bargain.favorite .. "\nOffers $" .. Progression.format(bargain.price) .. " • " .. bargain.attempts .. " pitches")
				row("Sell for $" .. Progression.format(bargain.price), function() send("Sell") end)
				row("Pitch a higher price • risk annoying them", function() send("Pitch") end)
				row("Walk away", function() send("WalkAway") end)
			else row("Hold a cookie and approach a roaming customer to bargain. Too many pitches make them walk away.\n\nHold E on another player to ask 'Want a cookie?'. Both confirm the free gift. The recipient pays nothing and keeps their own cookies.") end
		end
		rows:Finish()
	end
	openButton.Activated:Connect(function() tab, panel.Visible, shade.Visible = "Bag", true, true ; render() end)
	table.insert(connections, stateRemote.OnClientEvent:Connect(function(data)
		snapshot = data
		if panel.Visible then render() end
	end))
	table.insert(connections, open.OnClientEvent:Connect(function(name)
		tab=({Bag="Bag",Mine="Mine",PackShop="PackShop",Blacksmith="Blacksmith",Decorations="Machines"})[name] or "People"
		if name=="Gift" then pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Cookie gift",Text="Someone wants to give you a cookie.",Duration=8}) end) end
		panel.Visible,shade.Visible=true,true
		render()
	end))
	table.insert(connections, player:GetAttributeChangedSignal("DataReady"):Connect(function() if player:GetAttribute("DataReady") then send("Snapshot") end end))
	send("Snapshot")
	local status = label(hud, "Star Crumbs")
	status.Position, status.Size, status.AutomaticSize, status.TextSize, status.ZIndex = UDim2.new(0,14,1,-26), UDim2.new(1, -28, 0, 22), Enum.AutomaticSize.None, 11, 2
	status.TextScaled = true
	local statusSize = Instance.new("UITextSizeConstraint")
	statusSize.MinTextSize, statusSize.MaxTextSize, statusSize.Parent = 9, 12, status
	local skyFolder = Instance.new("Folder")
	skyFolder.Name, skyFolder.Parent = "Local Cookie Sun", workspace
	local sun = Instance.new("Model")
	sun.Name, sun.Parent = "Cookie Sun", skyFolder
	local function sunPart(name, size, offset, color)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color = name, size, CFrame.new(offset), color
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow, p.Material, p.Parent = true, false, false, false, false, Enum.Material.Neon, sun
		return p
	end
	local disk = sunPart("Cookie Sun Disk", Vector3.new(4, 100, 100), Vector3.zero, Color3.fromRGB(246, 189, 105))
	disk.Shape, sun.PrimaryPart = Enum.PartType.Cylinder, disk
	for i = 1, 12 do
		local chip = sunPart("Sun Chocolate Chip", Vector3.new(5, 10, 9), Vector3.new(3, math.sin(i * 2.4) * 34, math.cos(i * 2.4) * 34), Color3.fromRGB(98, 57, 31))
		chip.Shape = Enum.PartType.Ball
	end
	local moon = Instance.new("Model")
	moon.Name, moon.Parent = "Chocolate Chip Cookie Moon", skyFolder
	local function moonPiece(name, size, offset, color, shape)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color, p.Shape = name, size, CFrame.new(offset), color, shape or Enum.PartType.Ball
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow, p.Material, p.Parent = true,false,false,false,false,Enum.Material.Neon,moon
		return p
	end
	local crust = moonPiece("Golden Baked Edge", Vector3.new(7,94,94),Vector3.zero,Color3.fromRGB(158,101,51),Enum.PartType.Cylinder)
	moon.PrimaryPart=crust
	moonPiece("Warm Cookie Face",Vector3.new(8,88,88),Vector3.new(1,0,0),Color3.fromRGB(225,182,118),Enum.PartType.Cylinder)
	for i=1,23 do
		local angle=i*2.399963
		local radius=math.sqrt(i/24)*36
		moonPiece("Chocolate Chunk",Vector3.new(2.5,5+(i%3),4+(i%4)),Vector3.new(5,math.sin(angle)*radius,math.cos(angle)*radius),Color3.fromRGB(69,42,28))
	end
	for i=1,32 do
		local angle=i*2.399963
		local radius=math.sqrt(i/33)*40
		moonPiece("Baked Sugar Pore",Vector3.new(.4,1.1,1.2),Vector3.new(5.1,math.cos(angle)*radius,math.sin(angle)*radius),Color3.fromRGB(183,137,78))
	end
	local elapsed, sunVisible, lastGuide, moonVisible = 0, nil, nil, nil
	table.insert(connections, RunService.RenderStepped:Connect(function(dt)
		local camera = workspace.CurrentCamera
		if camera then
			local direction = Lighting:GetSunDirection()
			local visible = direction.Y > -0.02
			if visible ~= sunVisible then
				sunVisible = visible
				for _, part in ipairs(sun:GetChildren()) do if part:IsA("BasePart") then part.Transparency = visible and 0 or 1 end end
			end
			local position = camera.CFrame.Position + direction * 1500
			sun:PivotTo(CFrame.lookAt(position, camera.CFrame.Position) * CFrame.Angles(0, math.pi / 2, 0))
			local moonDirection = -direction
			local showMoon = moonDirection.Y > .02
			if showMoon ~= moonVisible then
				moonVisible = showMoon
				for _, part in ipairs(moon:GetChildren()) do part.Transparency = showMoon and 0 or 1 end
			end
			local moonPosition = camera.CFrame.Position + moonDirection * 1400
			moon:PivotTo(CFrame.lookAt(moonPosition, camera.CFrame.Position) * CFrame.Angles(0,math.pi/2,0))
		end
		elapsed += dt
		if elapsed < 0.2 then return end
		elapsed = 0
		for _, other in ipairs(Players:GetPlayers()) do
			local body = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			local prompt = body and body:FindFirstChild("CookieTradePrompt")
			if prompt then prompt.Enabled = other ~= player and player:GetAttribute("HeldCookieId") ~= nil end
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		for _, sign in ipairs(CollectionService:GetTagged("BakeryOwnerSign")) do
			local anchor = sign.Parent
			local range = sign:GetAttribute("OwnerUserId") == player.UserId and 180 or 55
			sign.Enabled = root ~= nil and anchor and anchor:IsA("BasePart") and (root.Position - anchor.Position).Magnitude <= range or false
		end
		for _,gate in ipairs(CollectionService:GetTagged("MineGate")) do
			local tier=gate:GetAttribute("RequiredPin")
			local unlocked=Mine.allowed(snapshot.life.pin,tier)
			gate.LocalTransparencyModifier=unlocked and .9 or 0
			local sign=gate:FindFirstChildOfClass("BillboardGui")
			local label=sign and sign:FindFirstChildOfClass("TextLabel")
			if label then label.Text=Mine.Zones[tier].Name.."\n"..(unlocked and "Access unlocked" or Life.PinNames[tier].." pin required") end
		end
		for _,crumb in ipairs(CollectionService:GetTagged("TrailStarCrumb")) do
			local id=tostring(crumb:GetAttribute("CrumbPickupId"))
			local available=(snapshot.life.cards.pickups[id] or 0)<=os.time() and (snapshot.life.cards.pickupDay~=math.floor(os.time()/86400) or snapshot.life.cards.pickupEarned<Town.PickupDailyCap)
			crumb.LocalTransparencyModifier=available and 0 or 1
			local prompt=crumb:FindFirstChild("TrailCrumbPrompt")
			if prompt then prompt.Enabled=available end
		end
		if not root or not camera then return end
		local buff = player:GetAttribute("CookieBuffName") or ""
		local hill=player:GetAttribute("OwnsCookieHill") and (player:GetAttribute("CookieHillContested") and " • Hill contested" or " • Hill income") or ""
		status.Text=snapshot.life.cards.crumbs.." Star Crumbs"..hill..(player:GetAttribute("InCookiePVP") and " • PVP ON" or buff~="" and " • "..buff or "")
		if panel.Visible and tab == "Bag" and snapshot.life.oven.id then
			local second = os.time()
			if second ~= lastGuide then
				lastGuide = second
				local timer=rows.records["oven-timer"]
				if timer then timer.object.Text="Finishing oven: "..math.max(0,snapshot.life.oven.ready-second).."s remaining" end
			end
		end
	end))
	table.insert(connections, workspace.DescendantAdded:Connect(function(object)
		if object:IsA("ProximityPrompt") and object.Name == "CookieTradePrompt" and object:GetAttribute("TargetUserId") == player.UserId then object.Enabled = false end
	end))
	for _, object in ipairs(workspace:GetDescendants()) do if object:IsA("ProximityPrompt") and object.Name == "CookieTradePrompt" and object:GetAttribute("TargetUserId") == player.UserId then object.Enabled = false end end
	gui.Destroying:Connect(function()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		skyFolder:Destroy()
	end)
end
return Client
