local Input, Run = game:GetService("UserInputService"), game:GetService("RunService")
local Flight = {}
function Flight.start(player, remotes, gui)
	local remote = remotes:WaitForChild("AdminFlightInput")
	local up, down, elapsed = false, false, 0
	local buttons = {}
	for i, title in ipairs({ "FLY UP", "FLY DOWN" }) do
		local b = Instance.new("TextButton")
		b.Text, b.Size, b.Position, b.BackgroundColor3, b.TextColor3, b.ZIndex, b.Parent = title, UDim2.fromOffset(110, 42), UDim2.new(1, -130, 1, -190 - i * 50), Color3.fromRGB(58, 96, 94), Color3.new(1, 1, 1), 15, gui
		b.Visible = false
		b.InputBegan:Connect(function(event) if event.UserInputType == Enum.UserInputType.Touch or event.UserInputType == Enum.UserInputType.MouseButton1 or event.KeyCode == Enum.KeyCode.ButtonA then if i == 1 then up = true else down = true end end end)
		b.InputEnded:Connect(function(event) if event.UserInputType == Enum.UserInputType.Touch or event.UserInputType == Enum.UserInputType.MouseButton1 or event.KeyCode == Enum.KeyCode.ButtonA then if i == 1 then up = false else down = false end end end)
		table.insert(buttons, b)
	end
	local connection = Run.Heartbeat:Connect(function(dt)
		local flying = player:GetAttribute("AdminFlying") == true
		for _, b in ipairs(buttons) do b.Visible = flying end
		if not flying then up, down = false, false; return end
		elapsed += dt
		if elapsed < 0.05 then return end
		elapsed = 0
		local camera, char = workspace.CurrentCamera, player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not camera or not hum then return end
		local direction = hum.MoveDirection
		if not Input:GetFocusedTextBox() then
			local x = (Input:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (Input:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
			local z = (Input:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (Input:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
			if x ~= 0 or z ~= 0 then direction = camera.CFrame.RightVector * x + camera.CFrame.LookVector * z end
		end
		local vertical = (up and 1 or 0) - (down and 1 or 0)
		if not Input:GetFocusedTextBox() then vertical += (Input:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - ((Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.Q)) and 1 or 0) end
		direction += Vector3.yAxis * vertical
		remote:FireServer(direction.Magnitude > 1 and direction.Unit or direction)
	end)
	gui.Destroying:Connect(function() connection:Disconnect() end)
end
return Flight
