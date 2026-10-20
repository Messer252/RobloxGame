local Progression = require(game:GetService("ReplicatedStorage").CookieTycoon.Progression)
local Extras = {}

local function part(parent, name, size, frame, tint)
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame, object.Color = name, size, frame, tint
	object.Anchored = true
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function writing(target, text, size)
	local surface = Instance.new("SurfaceGui")
	surface.Face, surface.CanvasSize, surface.Parent = Enum.NormalId.Front, Vector2.new(700, 650), target
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency, label.Text = UDim2.fromScale(1, 1), 1, text
	label.TextColor3, label.Font, label.TextSize = Color3.fromRGB(255, 235, 199), Enum.Font.GothamBold, size or 32
	label.Parent = surface
	return label
end

local function ranking(board, key)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.CanvasSize, gui.LightInfluence, gui.Parent = Enum.NormalId.Front, Vector2.new(700, 650), 0, board
	local background = Instance.new("Frame")
	background.Size, background.BackgroundColor3, background.BorderSizePixel, background.Parent = UDim2.fromScale(1, 1), Color3.fromRGB(35, 52, 53), 0, gui
	local function text(value, x, y, width, height, size, color)
		local t = Instance.new("TextLabel")
		t.Text, t.Position, t.Size, t.TextSize = value, UDim2.fromOffset(x, y), UDim2.fromOffset(width, height), size
		t.Font, t.TextColor3, t.BackgroundTransparency, t.TextXAlignment, t.Parent = Enum.Font.GothamBold, color or Color3.fromRGB(247, 234, 209), 1, Enum.TextXAlignment.Left, background
		return t
	end
	text(key == "cash" and "BAKERY FORTUNES" or "GOLDEN LEGENDS", 34, 20, 640, 58, 39, Color3.fromRGB(242, 203, 128))
	text(key == "cash" and "MOST SAVED WALLET CASH • ALL SERVERS" or "MOST REBIRTHS • ALL SERVERS", 36, 83, 630, 30, 20)
	local rows = {}
	for i = 1, 8 do
		local y = 133 + (i - 1) * 55
		local strip = Instance.new("Frame")
		strip.Position, strip.Size, strip.BorderSizePixel, strip.BackgroundColor3, strip.BackgroundTransparency, strip.Parent = UDim2.fromOffset(24, y), UDim2.fromOffset(652, 49), 0, Color3.fromRGB(255, 244, 219), i % 2 == 0 and 0.96 or 0.91, background
		text(string.format("%02d", i), 37, y, 55, 49, 27, i <= 3 and Color3.fromRGB(242, 203, 128) or Color3.fromRGB(164, 195, 187))
		local name = text("—", 104, y, 330, 49, 24)
		name.TextTruncate = Enum.TextTruncate.AtEnd
		local amount = text("", 438, y, 220, 49, 27, Color3.fromRGB(164, 222, 191))
		amount.TextXAlignment = Enum.TextXAlignment.Right
		table.insert(rows, { name = name, amount = amount })
	end
	local status = text("Loading global rankings…", 36, 600, 640, 28, 18, Color3.fromRGB(155, 185, 179))
	return { rows = rows, status = status }
end

function Extras.create(parent, rankings)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Plaza Extras", parent
	local boards = {}
	for index, key in ipairs({ "cash", "rebirths" }) do
		local x = index == 1 and -53 or 53
		local frame = CFrame.lookAt(Vector3.new(x, 7, -5), Vector3.new(0, 7, 0))
		for _, side in ipairs({ -6.8, 6.8 }) do
			part(folder, "Leaderboard Post", Vector3.new(0.8, 12, 0.8), frame * CFrame.new(side, -3.5, 0.4), Color3.fromRGB(92, 61, 46))
		end
		part(folder, "Leaderboard Brass Frame", Vector3.new(17.7, 15.7, 0.65), frame * CFrame.new(0, 0, 0.15), Color3.fromRGB(189, 149, 88))
		part(folder, "Leaderboard Stone Footing", Vector3.new(19, 0.7, 4), CFrame.new(x, 0.2, -5), Color3.fromRGB(141, 146, 137))
		local board = part(folder, "Most " .. key, Vector3.new(17, 15, 0.6), frame, Color3.fromRGB(68, 49, 43))
		boards[key] = ranking(board, key)
	end
	local center = CFrame.lookAt(Vector3.new(25, 1.9, -16), Vector3.new(0, 1.9, 0))
	local cardboard = Color3.fromRGB(185, 143, 94)
	local box = part(folder, "Zach's Box", Vector3.new(5, 3.5, 4), center, cardboard)
	local label = writing(box, "Zach's Box", 68)
	label.TextColor3 = Color3.fromRGB(62, 44, 30)
	part(folder, "Packing Tape", Vector3.new(0.75, 0.03, 4.02), center * CFrame.new(0, 1.77, 0), Color3.fromRGB(223, 193, 139))
	for _, side in ipairs({ -1, 1 }) do
		part(folder, "Cardboard Fold", Vector3.new(0.04, 3.3, 0.04), center * CFrame.new(side * 2.3, 0, -2.02), Color3.fromRGB(125, 89, 55))
	end
	task.spawn(function()
		while folder.Parent do
			for key, board in pairs(boards) do
				local ordered, status = rankings:Get(key)
				board.status.Text = status
				for index, row in ipairs(board.rows) do
					local record = ordered[index]
					row.name.Text = record and record.name or "—"
					row.amount.Text = record and ((key == "cash" and "$" or "") .. Progression.format(record[key])) or ""
				end
			end
			task.wait(2)
		end
	end)
end

return Extras
