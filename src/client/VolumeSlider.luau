local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Slider = {}

function Slider.create(parent, name, y, read, write)
	local row = Instance.new("Frame")
	row.Name, row.BackgroundTransparency = name .. "Volume", 1
	row.Position, row.Size, row.Parent = UDim2.fromOffset(14, y), UDim2.new(1, -28, 0, 30), parent
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.fromOffset(70, 30), 1
	label.TextColor3, label.Font, label.TextSize = Color3.fromRGB(255, 236, 209), Enum.Font.GothamBold, 11
	label.TextXAlignment, label.Parent = Enum.TextXAlignment.Left, row
	local function control(text, position, size)
		local button = Instance.new("TextButton")
		button.Text, button.Position, button.Size = text, position, size
		button.BackgroundColor3, button.TextColor3 = Color3.fromRGB(96, 76, 66), Color3.fromRGB(255, 236, 209)
		button.BorderSizePixel, button.TextSize, button.Parent = 0, 18, row
		local corner = Instance.new("UICorner")
		corner.CornerRadius, corner.Parent = UDim.new(0, 6), button
		return button
	end
	local minus = control("−", UDim2.fromOffset(72, 1), UDim2.fromOffset(28, 28))
	local plus = control("+", UDim2.new(1, -28, 0, 1), UDim2.fromOffset(28, 28))
	local track = control("", UDim2.fromOffset(108, 1), UDim2.new(1, -144, 0, 28))
	track.Name, track.BackgroundTransparency, track.AutoButtonColor = name .. "Slider", 1, false
	local bar = Instance.new("Frame")
	bar.Size, bar.Position = UDim2.new(1, 0, 0, 6), UDim2.fromOffset(0, 11)
	bar.BackgroundColor3, bar.BorderSizePixel, bar.Parent = Color3.fromRGB(103, 83, 74), 0, track
	local fill = Instance.new("Frame")
	fill.BorderSizePixel, fill.BackgroundColor3, fill.Parent = 0, Color3.fromRGB(133, 199, 173), bar
	local thumb = Instance.new("Frame")
	thumb.AnchorPoint, thumb.Size = Vector2.new(0.5, 0.5), UDim2.fromOffset(14, 20)
	thumb.BackgroundColor3, thumb.BorderSizePixel, thumb.Parent = Color3.fromRGB(255, 208, 92), 0, track
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 6), thumb
	local dragging
	local connections = {}
	local function at(x)
		if track.AbsoluteSize.X > 0 then write(math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)) end
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = input
			at(input.Position.X)
		end
	end)
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input == dragging or (dragging.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
			at(input.Position.X)
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input == dragging then dragging = nil end
	end))
	minus.Activated:Connect(function() write(read() - 0.05) end)
	plus.Activated:Connect(function() write(read() + 0.05) end)
	table.insert(connections, UserInputService.InputBegan:Connect(function(input)
		if GuiService.SelectedObject ~= track then return end
		if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.DPadLeft then write(read() - 0.05)
		elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.DPadRight then write(read() + 0.05) end
	end))
	track.SelectionGained:Connect(function() bar.BackgroundColor3 = Color3.fromRGB(213, 175, 118) end)
	track.SelectionLost:Connect(function() bar.BackgroundColor3 = Color3.fromRGB(103, 83, 74) end)
	row.Destroying:Connect(function()
		for _, connection in ipairs(connections) do connection:Disconnect() end
	end)
	return function()
		local value = read()
		label.Text = name .. " " .. math.floor(value * 100 + 0.5) .. "%"
		fill.Size = UDim2.fromScale(value, 1)
		thumb.Position = UDim2.new(value, 0, 0.5, 0)
	end
end

return Slider
