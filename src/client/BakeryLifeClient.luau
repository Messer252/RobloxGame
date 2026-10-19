local Players, Lighting, RunService = game:GetService("Players"), game:GetService("Lighting"), game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").CookieTycoon
local Life, Recipes, Progression, Quests = require(Shared.BakeryLife), require(Shared.Recipes), require(Shared.Progression), require(Shared.ChallengeCatalog)
local Client = {}
function Client.start(player, remotes, gui, hud, openButton)
	local action, stateRemote, open = remotes:WaitForChild("LifeAction"), remotes:WaitForChild("LifeState"), remotes:WaitForChild("OpenLife")
	local snapshot, tab = { life = Life.normalize(nil) }, "Bag"
	local connections = {}
	local shade = Instance.new("TextButton")
	shade.Size, shade.Text, shade.BackgroundTransparency, shade.BackgroundColor3, shade.ZIndex, shade.Visible, shade.Parent = UDim2.fromScale(1, 1), "", 0.35, Color3.new(), 25, false, gui
	local panel = Instance.new("Frame")
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
		b.Activated:Connect(callback)
		return b
	end
	local header = label(panel, "COOKIE BAG")
	header.Position, header.Size = UDim2.fromOffset(14, 12), UDim2.new(1, -70, 0, 28)
	local close = button(panel, "X", function() panel.Visible, shade.Visible = false, false end)
	close.Position, close.Size = UDim2.new(1, -48, 0, 10), UDim2.fromOffset(34, 34)
	shade.Activated:Connect(function() panel.Visible, shade.Visible = false, false end)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Position, scroll.Size, scroll.BackgroundTransparency, scroll.BorderSizePixel = UDim2.fromOffset(14, 100), UDim2.new(1, -28, 1, -114), 1, 0
	scroll.CanvasSize, scroll.AutomaticCanvasSize, scroll.ScrollBarThickness, scroll.ZIndex, scroll.Parent = UDim2.new(), Enum.AutomaticSize.Y, 4, 27, panel
	local layout = Instance.new("UIListLayout")
	layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0, 9), Enum.SortOrder.LayoutOrder, scroll
	local function send(name, argument) action:FireServer(name, argument) end
	local render
	for index, name in ipairs({ "Bag", "Mine", "Machines", "People" }) do
		local b = button(panel, name, function() tab = name ; render() end)
		b.Position, b.Size = UDim2.new((index - 1) * 0.25, 4, 0, 53), UDim2.new(0.25, -8, 0, 34)
	end
	render = function()
		for _, child in ipairs(scroll:GetChildren()) do if child ~= layout then child:Destroy() end end
		header.Text = ({ Bag = "COOKIE BAG", Mine = "DOUGH MINE", Machines = "BAKERY MACHINES", People = "COOKIES & COMPANY" })[tab]
		local count = 0
		local function row(text, callback)
			count += 1
			local element = callback and button(scroll, text, callback) or label(scroll, text)
			element.LayoutOrder = count
			if callback then element.Interactable = not snapshot.busy end
			return element
		end
		local data = snapshot.life
		if snapshot.busy then row("Saving cookie exchange. Please wait...") end
		if tab == "Bag" then
			row(#data.inventory .. "/" .. Life.capacity(data) .. " cookies • Hold a conveyor cookie's pickup prompt to store it.")
			if snapshot.held then row("Eat held cookie • 90-second speed + cookie skin", function() send("Eat", snapshot.held) end) end
			if data.oven.id then row("Finishing oven: " .. math.max(0, data.oven.ready - os.time()) .. "s remaining") end
			for _, cookie in ipairs(data.inventory) do
				local item = cookie
				local held = snapshot.held == item.id
				row(Recipes[item.recipe].Name .. " • $" .. Progression.format(Life.value(item)) .. (item.baked and " • Finished" or "") .. "\n" .. (data.oven.id == item.id and "In finishing oven" or held and "Holding • click/tap tool to eat" or "Tap to hold"), function() send("Equip", item.id) end)
			end
		elseif tab == "Mine" then
			row("Dough: " .. data.dough .. " • Rolling pin " .. data.pin .. "/5")
			row("West of the plaza: equip your rolling pin, then hold E on dough ore. Visit the mine workshop to buy upgrades.")
			local cost = Life.PinCosts[data.pin + 1]
			row(cost and ("Better rolling pin • $" .. Progression.format(cost)) or "Best rolling pin owned", function() send("Pin") end)
			for _, key in ipairs({ "Mixing", "Flow", "Pockets" }) do
				local level, definition = data.upgrades[key], Life.DoughUpgrades[key]
				local bonus = ({ Mixing = "+10% cookie income", Flow = "+5% baking speed", Pockets = "+4 cookie slots" })[key]
				row(key .. " " .. level .. "/" .. definition.Max .. " • " .. bonus .. "\n" .. (level == definition.Max and "MAX" or definition.Cost * 2^level .. " dough"), function() send("Dough", key) end)
			end
		elseif tab == "Machines" then
			row("Visit the pads beside your own conveyor to buy or use machines.")
			for _, key in ipairs({ "Packager", "Boxer", "FinishingOven" }) do
				local owned = data.machines[key]
				row(key .. " • " .. (owned and "Owned" or "$" .. Progression.format(Life.Machines[key].Cost)) .. "\n" .. ({ Packager = "+25% production and picked-cookie value", Boxer = "+50% production and picked-cookie value", FinishingOven = "20 seconds • finish one inventory cookie for 3x value" })[key], function() send("Machine", key) end)
			end
			if data.machines.FinishingOven then row("Finish held cookie (at your oven pad)", function() send("Bake") end) end
		else
			local trade, bargain = snapshot.trade, snapshot.bargain
			if trade then
				row("@" .. trade.from .. " offers " .. trade.giveA .. "\n@" .. trade.to .. " offers " .. trade.giveB)
				row(trade.confirmed and "You confirmed • waiting for the other player" or "Confirm this exact cookie exchange", function() send("ConfirmTrade", trade.id) end)
				row("Decline / cancel", function() send("CancelTrade") end)
			elseif bargain then
				row(bargain.name .. " offers $" .. Progression.format(bargain.price) .. " • " .. bargain.attempts .. " pitches")
				row("Sell for $" .. Progression.format(bargain.price), function() send("Sell") end)
				row("Pitch a higher price • risk annoying them", function() send("Pitch") end)
				row("Walk away", function() send("WalkAway") end)
			else row("Hold a cookie and approach a roaming customer to bargain. Too many pitches make them walk away.\n\nHold E on another player to ask 'Want a cookie?'. Both confirm the shown exchange; if they hold no cookie, yours is a gift.") end
		end
	end
	openButton.Activated:Connect(function() tab, panel.Visible, shade.Visible = "Bag", true, true ; render() end)
	table.insert(connections, stateRemote.OnClientEvent:Connect(function(data) snapshot = data ; if panel.Visible then render() end end))
	table.insert(connections, open.OnClientEvent:Connect(function(name) tab = (name == "Mine") and "Mine" or "People" ; panel.Visible, shade.Visible = true, true ; render() end))
	table.insert(connections, player:GetAttributeChangedSignal("DataReady"):Connect(function() if player:GetAttribute("DataReady") then send("Snapshot") end end))
	send("Snapshot")
	local compass = label(hud, "Cookie valley")
	compass.Position, compass.Size, compass.AutomaticSize, compass.TextSize, compass.ZIndex = UDim2.fromOffset(14, 236), UDim2.new(1, -28, 0, 22), Enum.AutomaticSize.None, 11, 2
	compass.TextScaled = true
	local compassSize = Instance.new("UITextSizeConstraint")
	compassSize.MinTextSize, compassSize.MaxTextSize, compassSize.Parent = 9, 12, compass
	local skyFolder = Instance.new("Folder")
	skyFolder.Name, skyFolder.Parent = "Local Cookie Sun and Quest Guide", workspace
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
	local target = Instance.new("Part")
	target.Name, target.Size, target.Transparency, target.Anchored, target.CanCollide, target.CanQuery, target.CanTouch, target.Parent = "Quest target", Vector3.one, 1, true, false, false, false, skyFolder
	local targetAttach, beam = Instance.new("Attachment"), Instance.new("Beam")
	targetAttach.Parent, beam.Attachment1, beam.FaceCamera, beam.Width0, beam.Width1, beam.Parent = target, targetAttach, true, 0.13, 0.13, target
	beam.Color, beam.Transparency = ColorSequence.new(Color3.fromRGB(138, 228, 191)), NumberSequence.new(0.2)
	local rootAttach, lastGuide, elapsed, sunVisible = nil, nil, 0, nil
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
		if not root or not camera then beam.Enabled = false ; return end
		if not rootAttach or rootAttach.Parent ~= root then
			if rootAttach then rootAttach:Destroy() end
			rootAttach = Instance.new("Attachment") ; rootAttach.Parent = root
			beam.Attachment0 = rootAttach
		end
		local index, found = player:GetAttribute("ChallengeIndex") or 1, player:GetAttribute("ChallengeFound") or 0
		local quest, item = Quests.Challenges[index], nil
		if quest and player:GetAttribute("ChallengeActive") then
			for itemIndex, id in ipairs(quest.Items) do if bit32.band(found, 2^(itemIndex-1)) == 0 then item = Quests.Items[id] ; break end end
		end
		local coords, name = item and item.Position or Quests.NPCPosition, item and item.Name or "Baker Biscuit"
		local destination = Vector3.new(table.unpack(coords)) + Vector3.new(0, 1, 0)
		target.Position, beam.Enabled = destination, quest ~= nil
		local delta = destination - root.Position
		local flat = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
		local angle = math.atan2(delta:Dot(camera.CFrame.RightVector), delta:Dot(flat))
		local arrows = { "↑", "↗", "→", "↘", "↓", "↙", "←", "↖" }
		local direction = arrows[math.floor((angle % (math.pi * 2)) / (math.pi / 4) + 0.5) % 8 + 1]
		local heading = math.floor((math.deg(math.atan2(-flat.X, -flat.Z)) + 360) % 360)
		compass.Text = quest and (heading .. "° • " .. direction .. " " .. name .. " • " .. math.floor(delta.Magnitude) .. " studs") or "All hunts complete • Explore the cookie valley"
		if panel.Visible and tab == "Bag" and snapshot.life.oven.id then
			local second = os.time()
			if second ~= lastGuide then lastGuide = second ; render() end
		end
	end))
	table.insert(connections, workspace.DescendantAdded:Connect(function(object)
		if object:IsA("ProximityPrompt") and object.Name == "CookieTradePrompt" and object:GetAttribute("TargetUserId") == player.UserId then object.Enabled = false end
	end))
	for _, object in ipairs(workspace:GetDescendants()) do if object:IsA("ProximityPrompt") and object.Name == "CookieTradePrompt" and object:GetAttribute("TargetUserId") == player.UserId then object.Enabled = false end end
	gui.Destroying:Connect(function()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if rootAttach then rootAttach:Destroy() end
		skyFolder:Destroy()
	end)
end
return Client
