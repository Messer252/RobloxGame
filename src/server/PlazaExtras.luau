local Players = game:GetService("Players")
local Ranks = require(game:GetService("ReplicatedStorage").CookieTycoon.LeaderboardRanks)
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

function Extras.create(parent, getState)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Plaza Extras", parent
	local boards = {}
	for index, key in ipairs({ "cash", "rebirths" }) do
		local x = index == 1 and -53 or 53
		local frame = CFrame.lookAt(Vector3.new(x, 7, -5), Vector3.new(0, 7, 0))
		part(folder, "Leaderboard Post", Vector3.new(0.8, 10, 0.8), CFrame.new(x, 4, -5), Color3.fromRGB(92, 61, 46))
		local board = part(folder, "Most " .. key, Vector3.new(17, 15, 0.6), frame, Color3.fromRGB(68, 49, 43))
		boards[key] = writing(board, "Loading rankings...", 31)
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
			local records = {}
			for _, player in ipairs(Players:GetPlayers()) do
				local state = getState(player)
				if state and not state.closing then
					table.insert(records, { name = player.DisplayName, userId = player.UserId, cash = state.data.cash, rebirths = state.data.rebirths })
				end
			end
			for key, labelObject in pairs(boards) do
				local lines = { key == "cash" and "MOST CASH" or "MOST REBIRTHS", "THIS SERVER", "" }
				for rank, record in ipairs(Ranks.sort(records, key)) do
					table.insert(lines, rank .. ". " .. record.name .. "  " .. (key == "cash" and "$" or "") .. Progression.format(record[key]))
				end
				if #records == 0 then table.insert(lines, "Claim a bakery and join the ranks!") end
				labelObject.Text = table.concat(lines, "\n")
			end
			task.wait(2)
		end
	end)
end

return Extras
