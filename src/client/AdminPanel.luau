local Players = game:GetService("Players")
local Panel = {}

function Panel.start(player, remotes, gui, openButton)
	local actionRemote = remotes:WaitForChild("AdminAction")
	local resultRemote = remotes:WaitForChild("AdminResult")
	local connections, selected, confirmKick = {}, nil, nil
	local backdrop = Instance.new("TextButton")
	backdrop.Size, backdrop.Text, backdrop.BackgroundTransparency = UDim2.fromScale(1, 1), "", 0.35
	backdrop.BackgroundColor3, backdrop.ZIndex, backdrop.Visible, backdrop.Parent = Color3.new(0, 0, 0), 20, false, gui
	local frame = Instance.new("Frame")
	frame:SetAttribute("BlocksCameraLock",true)
	frame.AnchorPoint, frame.Position, frame.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.92, 0.85)
	frame.BackgroundColor3, frame.ZIndex, frame.Visible, frame.Parent = Color3.fromRGB(53, 36, 32), 21, false, gui
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize, limit.Parent = Vector2.new(460, 530), frame
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 14), frame
	local function label(parent, text)
		local object = Instance.new("TextLabel")
		object.Size, object.AutomaticSize = UDim2.new(1, -4, 0, 0), Enum.AutomaticSize.Y
		object.BackgroundTransparency, object.Text, object.TextSize = 1, text, 15
		object.Font, object.TextColor3, object.TextWrapped = Enum.Font.GothamBold, Color3.fromRGB(255, 236, 209), true
		object.TextXAlignment, object.ZIndex, object.Parent = Enum.TextXAlignment.Left, 22, parent
		return object
	end
	local function button(parent, text)
		local object = Instance.new("TextButton")
		object.Size, object.Text = UDim2.new(1, -4, 0, 40), text
		object.BackgroundColor3, object.TextColor3 = Color3.fromRGB(75, 112, 99), Color3.fromRGB(255, 236, 209)
		object.Font, object.TextSize, object.TextWrapped = Enum.Font.GothamBold, 14, true
		object.BorderSizePixel, object.ZIndex, object.Parent = 0, 22, parent
		local rounding = Instance.new("UICorner")
		rounding.CornerRadius, rounding.Parent = UDim.new(0, 8), object
		return object
	end
	local title = label(frame, "ADMIN TOOLS")
	title.Position, title.Size = UDim2.fromOffset(14, 16), UDim2.new(1, -74, 0, 26)
	local close = button(frame, "X")
	close.Size, close.Position = UDim2.fromOffset(32, 32), UDim2.new(1, -46, 0, 12)
	local content = Instance.new("ScrollingFrame")
	content.Position, content.Size = UDim2.fromOffset(14, 108), UDim2.new(1, -28, 1, -122)
	content.BackgroundTransparency, content.BorderSizePixel, content.ScrollBarThickness = 1, 0, 4
	content.CanvasSize, content.AutomaticCanvasSize, content.ZIndex, content.Parent = UDim2.new(), Enum.AutomaticSize.Y, 22, frame
	local layout = Instance.new("UIListLayout")
	layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0, 10), Enum.SortOrder.LayoutOrder, content
	local info = label(content, "Choose an account in this server.")
	info.LayoutOrder = 1
	local selectedLabel = label(content, "No player selected")
	selectedLabel.LayoutOrder = 2
	local playerList = Instance.new("ScrollingFrame")
	playerList.LayoutOrder, playerList.Size, playerList.BackgroundTransparency = 3, UDim2.new(1, -4, 0, 150), 1
	playerList.CanvasSize, playerList.AutomaticCanvasSize, playerList.ScrollBarThickness = UDim2.new(), Enum.AutomaticSize.Y, 4
	playerList.BorderSizePixel, playerList.ZIndex, playerList.Parent = 0, 22, content
	local playerLayout = Instance.new("UIListLayout")
	playerLayout.Padding, playerLayout.SortOrder, playerLayout.Parent = UDim.new(0, 5), Enum.SortOrder.Name, playerList
	local returnButton = button(content, "Return player to spawn")
	returnButton.LayoutOrder = 4
	local kickButton = button(content, "Kick player")
	kickButton.LayoutOrder, kickButton.BackgroundColor3 = 5, Color3.fromRGB(151, 74, 57)
	local goButton = button(content, "Teleport to player")
	goButton.LayoutOrder = 6
	local bringButton = button(content, "Bring player to me")
	bringButton.LayoutOrder = 7
	local amount = Instance.new("TextBox")
	amount.LayoutOrder, amount.Size, amount.Text = 8, UDim2.new(1, -4, 0, 40), "10000"
	amount.PlaceholderText, amount.ClearTextOnFocus, amount.TextSize = "Whole currency amount", false, 16
	amount.TextColor3, amount.BackgroundColor3 = Color3.fromRGB(255, 236, 209), Color3.fromRGB(89, 69, 60)
	amount.Font, amount.ZIndex, amount.Parent = Enum.Font.GothamBold, 22, content
	local walletButton = button(content, "Add amount to wallet")
	walletButton.LayoutOrder = 9
	local bankButton = button(content, "Add amount to ready earnings")
	bankButton.LayoutOrder = 10
	local chipButton = button(content, "Give Golden Chips")
	chipButton.LayoutOrder = 11
	local crumbButton = button(content, "Give Star Crumbs")
	crumbButton.LayoutOrder = 12
	local invisibilityButton = button(content, "My invisibility: OFF")
	invisibilityButton.LayoutOrder = 13
	local flyButton = button(content, "My flight: OFF")
	flyButton.LayoutOrder = 14
	require(script.Parent.AdminFlightClient).start(player, remotes, gui)
	local status = label(frame, "Admin actions apply to this server.")
	status.Position, status.Size, status.AutomaticSize = UDim2.fromOffset(14, 48), UDim2.new(1, -28, 0, 46), Enum.AutomaticSize.None
	status.TextSize = 13
	local lastSent = -math.huge
	local function resetConfirmation()
		confirmKick = nil
		kickButton.Text = "Kick player"
	end
	local function rebuild()
		if selected and not Players:GetPlayerByUserId(selected) then selected = nil end
		for _, child in ipairs(playerList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
		for _, target in ipairs(Players:GetPlayers()) do
			local choice = button(playerList, "@" .. target.Name .. (target == player and " (you)" or ""))
			choice.Name = target.Name
			choice.Size = UDim2.new(1, -8, 0, 34)
			choice.BackgroundColor3 = selected == target.UserId and Color3.fromRGB(137, 104, 46) or Color3.fromRGB(89, 69, 60)
			choice.Activated:Connect(function()
				selected = target.UserId
				resetConfirmation()
				rebuild()
			end)
		end
		local target = selected and Players:GetPlayerByUserId(selected)
		selectedLabel.Text = target and ("Selected: @" .. target.Name) or "No player selected"
		returnButton.Interactable, kickButton.Interactable = target ~= nil, target ~= nil
		goButton.Interactable, bringButton.Interactable = target ~= nil, target ~= nil
		walletButton.Interactable, bankButton.Interactable = target ~= nil, target ~= nil
		chipButton.Interactable, crumbButton.Interactable = target ~= nil, target ~= nil
	end
	local function visible(value)
		frame.Visible = value and player:GetAttribute("IsAdmin") == true
		backdrop.Visible = frame.Visible
		resetConfirmation()
		if frame.Visible then rebuild() end
	end
	local function send(action, argument)
		local targetId = (action == "SetInvisible" or action == "SetFlying") and player.UserId or selected
		if not targetId or player:GetAttribute("IsAdmin") ~= true then return end
		if os.clock() - lastSent < 1 then
			status.Text = "Wait a moment between actions."
			return
		end
		lastSent = os.clock()
		status.Text = "Sending..."
		actionRemote:FireServer(action, targetId, argument)
	end
	openButton.Activated:Connect(function() visible(true) end)
	close.Activated:Connect(function() visible(false) end)
	backdrop.Activated:Connect(function() visible(false) end)
	returnButton.Activated:Connect(function()
		resetConfirmation()
		send("ReturnToSpawn")
	end)
	goButton.Activated:Connect(function()
		resetConfirmation()
		send("GoToPlayer")
	end)
	bringButton.Activated:Connect(function()
		resetConfirmation()
		send("BringPlayer")
	end)
	walletButton.Activated:Connect(function()
		resetConfirmation()
		send("GiveWalletCash", tonumber(amount.Text:sub(1, 32)))
	end)
	bankButton.Activated:Connect(function()
		resetConfirmation()
		send("GiveBankCash", tonumber(amount.Text:sub(1, 32)))
	end)
	chipButton.Activated:Connect(function() resetConfirmation(); send("GiveGoldenChips",tonumber(amount.Text:sub(1,32))) end)
	crumbButton.Activated:Connect(function() resetConfirmation(); send("GiveStarCrumbs",tonumber(amount.Text:sub(1,32))) end)
	invisibilityButton.Activated:Connect(function()
		resetConfirmation()
		send("SetInvisible", player:GetAttribute("AdminInvisible") ~= true)
	end)
	flyButton.Activated:Connect(function() send("SetFlying", player:GetAttribute("AdminFlying") ~= true) end)
	table.insert(connections, player:GetAttributeChangedSignal("AdminFlying"):Connect(function() flyButton.Text = player:GetAttribute("AdminFlying") and "My flight: ON" or "My flight: OFF" end))
	kickButton.Activated:Connect(function()
		local target = selected and Players:GetPlayerByUserId(selected)
		if not target then return end
		if confirmKick ~= selected then
			confirmKick = selected
			kickButton.Text = "Confirm kick @" .. target.Name
			status.Text = "Click again to remove this player."
		else
			resetConfirmation()
			send("Kick")
		end
	end)
	table.insert(connections, resultRemote.OnClientEvent:Connect(function(success, message)
		status.Text = message
		status.TextColor3 = success and Color3.fromRGB(157, 221, 184) or Color3.fromRGB(255, 182, 155)
	end))
	local function refreshAccess()
		openButton.Visible = player:GetAttribute("IsAdmin") == true
		if not openButton.Visible then visible(false) end
	end
	table.insert(connections, player:GetAttributeChangedSignal("IsAdmin"):Connect(refreshAccess))
	local function refreshInvisible()
		invisibilityButton.Text = player:GetAttribute("AdminInvisible") == true and "My invisibility: ON" or "My invisibility: OFF"
	end
	table.insert(connections, player:GetAttributeChangedSignal("AdminInvisible"):Connect(refreshInvisible))
	table.insert(connections, Players.PlayerAdded:Connect(function() if frame.Visible then rebuild() end end))
	table.insert(connections, Players.PlayerRemoving:Connect(function(leaving)
		if selected == leaving.UserId then
			selected = nil
			resetConfirmation()
		end
		task.defer(function() if frame.Parent and frame.Visible then rebuild() end end)
	end))
	gui.Destroying:Connect(function() for _, connection in ipairs(connections) do connection:Disconnect() end end)
	refreshAccess()
	refreshInvisible()
end

return Panel
