local Shared = game:GetService("ReplicatedStorage").CookieTycoon
local Catalog = require(Shared.CardCatalog)
local FrameDesign, Tween = require(script.Parent.TradingCardFrame), game:GetService("TweenService")
local Client = {}
function Client.describe(card)
	local parts = {}
	for _, stat in ipairs({ "Cash", "Speed", "Sales", "Crumbs", "Mine" }) do
		local amount = card.Effects[stat]
		if amount then table.insert(parts, "+" .. (stat == "Mine" and amount or math.floor(amount*100+.5).."%") .. " " .. ({Cash="income",Speed="production",Sales="sales",Crumbs="Star Crumbs",Mine="mining damage"})[stat]) end
	end
	return table.concat(parts, " • ")
end
function Client.render(player, data, row, send, panel)
	local third = player:GetAttribute("ThirdCardSlotOwned") == true
	row(data.crumbs .. " STAR CRUMBS • " .. #data.equipped .. "/" .. (third and 3 or 2) .. " cards equipped")
	row("Earn crumbs through quests, ore, bakery milestones, meteors, and the PvP hill. Cards and crumbs survive rebirth.")
	row("Next meteor: about " .. math.ceil((player:GetAttribute("NextMeteorSeconds") or 300)/60) .. " minutes • Hill: west meadow")
	local buy = row(third and "Third slot owned" or "Optional third slot • configured as a 150 Robux pass", function() Shared.Remotes.RequestPurchase:FireServer("Pass", "ThirdCardSlot") end)
	buy.Interactable = not third and require(Shared.ShopCatalog).offer("Pass", "ThirdCardSlot") ~= nil
	for id, pack in ipairs(Catalog.Packs) do
		local odds = {}
		for i, weight in ipairs(pack.Weights) do table.insert(odds, Catalog.Rarities[i] .. " " .. string.format("%g%%", weight/100)) end
		row(pack.Name .. " • " .. pack.Cost .. " crumbs\n" .. table.concat(odds, " / "))
		local button = row("Rip " .. pack.Name, function() send("OpenPack", id) end)
		button.Interactable = button.Interactable and data.crumbs >= pack.Cost
	end
	row("Each animal within a rarity is equally likely. Duplicates are kept, but the same card cannot fill multiple slots.")
	for id, card in ipairs(Catalog.Cards) do
		local count = data.owned[tostring(id)]
		if not count then continue end
		local equipped = table.find(data.equipped, id)
		local button = row((equipped and "✓ " or "") .. card.Name .. " • " .. card.Rarity .. " ×" .. count .. "\n" .. Client.describe(card), function() send("EquipCard", id) end)
		button.Size = UDim2.new(1,-8,0,65)
		button.BackgroundColor3 = Color3.fromRGB(table.unpack(Catalog.Colors[card.Rarity])):Lerp(Color3.fromRGB(40,40,35),.55)
		local artButton = row("View " .. card.Animal .. " card", function() Client.reveal(panel.Parent, id, false) end)
		artButton.Size = UDim2.new(1,-8,0,30)
	end
end
function Client.reveal(gui, cardId, ripping)
	local old = gui:FindFirstChild("CardReveal")
	if old then old:Destroy() end
	local card = Catalog.Cards[cardId]
	if not card then return end
	local shade = Instance.new("TextButton")
	shade.Name, shade.Size, shade.Text, shade.BackgroundColor3, shade.BackgroundTransparency, shade.ZIndex, shade.Parent = "CardReveal", UDim2.fromScale(1,1), "", Color3.new(), .2, 50, gui
	local frame = FrameDesign.create(shade, card, Client.describe(card))
	frame.Position, frame.AnchorPoint = UDim2.fromScale(.5,.5),Vector2.new(.5,.5)
	local scale = Instance.new("UIScale")
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800,600)
	scale.Scale, scale.Parent = math.min(1, viewport.Y / 590, viewport.X / 390),frame
	local close = Instance.new("TextButton")
	close.Text,close.Position,close.Size,close.BackgroundColor3,close.TextColor3,close.Font,close.TextSize,close.ZIndex,close.Parent = "CLOSE",UDim2.new(1,-35,0,-15),UDim2.fromOffset(50,30),Color3.fromRGB(30,34,41),Color3.new(1,1,1),Enum.Font.GothamBold,11,60,frame
	close.Activated:Connect(function() shade:Destroy() end)
	if ripping then
		for side=0,1 do
			local flap=Instance.new("Frame")
			flap.Size,flap.Position,flap.BackgroundColor3,flap.ZIndex,flap.Parent=UDim2.fromScale(.5,1),UDim2.fromScale(side*.5,0),Color3.fromRGB(112,167,142),58,frame
			local label=Instance.new("TextLabel")
			label.Text,label.Size,label.BackgroundTransparency,label.TextColor3,label.TextSize,label.ZIndex,label.Parent = side==0 and "COOKIE" or "FRIENDS",UDim2.fromScale(1,1),1,Color3.fromRGB(255,238,197),19,59,flap
			Tween:Create(flap,TweenInfo.new(.65,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Position=UDim2.fromScale(side==0 and -.8 or 1.3,0),Rotation=side==0 and -12 or 12}):Play()
			game:GetService("Debris"):AddItem(flap,.8)
		end
	end
	shade.Activated:Connect(function() shade:Destroy() end)
end
function Client.start(remotes, gui)
	remotes:WaitForChild("PackResult").OnClientEvent:Connect(function(cardId) Client.reveal(gui,cardId,true) end)
end
return Client
