local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.CookieTycoon.ObbyCatalog)
local Progress = require(ReplicatedStorage.CookieTycoon.ObbyProgress)
local ObbyWorld = {}

local function platform(parent, name, position, width, tint)
	local object = Instance.new("Part")
	object.Name, object.Size, object.Position = name, Vector3.new(width, 1, width), position
	object.Color, object.Anchored = tint, true
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function sign(target, value)
	local gui = Instance.new("BillboardGui")
	gui.Size, gui.StudsOffset, gui.MaxDistance = UDim2.fromOffset(220, 65), Vector3.new(0, 4, 0), 75
	gui.Parent = target
	local text = Instance.new("TextLabel")
	text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 0.15
	text.BackgroundColor3, text.TextColor3 = Color3.fromRGB(62, 45, 40), Color3.fromRGB(255, 238, 204)
	text.Text, text.TextSize, text.Font = value, 16, Enum.Font.GothamBold
	text.Parent = gui
end

local function feet(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return nil end
	local height = humanoid.HipHeight + root.Size.Y / 2
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = character:FindFirstChild("Left Leg")
		height += leg and leg.Size.Y or 2
	end
	return root, humanoid, root.Position - Vector3.new(0, height, 0)
end

local function onTop(point, surface)
	local p = surface.CFrame:PointToObjectSpace(point)
	return math.abs(p.X) <= surface.Size.X / 2 + 0.15 and math.abs(p.Z) <= surface.Size.Z / 2 + 0.15
		and math.abs(p.Y - surface.Size.Y / 2) <= 1
end

function ObbyWorld.create(parent, onComplete, notify)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Cookie Obbys", parent
	local courses, runs, resets = {}, {}, {}
	for _, definition in ipairs(Catalog) do
		local model = Instance.new("Model")
		model.Name, model.Parent = definition.Id .. " Obby", folder
		local tint = Color3.fromRGB(table.unpack(definition.Color))
		local start = platform(model, "Start", Vector3.new(230, 0.4, definition.Z), 10, tint)
		sign(start, definition.Id .. " Obby\n+" .. math.floor(definition.Bonus * 100) .. "% income • 5 minutes")
		local floor = platform(model, "Soft Reset Floor", Vector3.new(325, 0.05, definition.Z), 1, Color3.fromRGB(209, 172, 150))
		floor.Size = Vector3.new(185, 0.2, 55)
		local path = {}
		for index = 1, definition.Count do
			local p = Catalog.platform(definition, index)
			local step = platform(model, "Checkpoint " .. index, Vector3.new(p.x, p.y, p.z), definition.Width, tint)
			table.insert(path, step)
			if index == definition.Count then
				sign(step, "FINISH\n" .. definition.Id .. " • Cash boost")
				local back = Instance.new("ProximityPrompt")
				back.ActionText, back.ObjectText, back.HoldDuration = "Return to plaza", definition.Id .. " finish", 0
				back.MaxActivationDistance, back.RequiresLineOfSight, back.Parent = 8, false, step
				back.Triggered:Connect(function(player)
					local root, _, point = feet(player)
					if root and onTop(point, step) and not runs[player] then
						runs[player] = nil
						player.Character:PivotTo(CFrame.new(0, 5, -9))
						root.AssemblyLinearVelocity = Vector3.zero
					end
				end)
			end
		end
		table.insert(courses, { definition = definition, start = start, floor = floor, path = path })
	end
	Players.PlayerRemoving:Connect(function(player) runs[player], resets[player] = nil, nil end)
	task.spawn(function()
		while folder.Parent do
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				local root, humanoid, point = feet(player)
				local run = runs[player]
				if run and (not root or run.character ~= player.Character) then runs[player], run = nil, nil end
				if root and humanoid.FloorMaterial ~= Enum.Material.Air then
					for _, course in ipairs(courses) do
						local definition = course.definition
						if onTop(point, course.start) and (not run or run.course ~= definition.Id) then
							run = Progress.start(definition, now)
							run.character = player.Character
							runs[player] = run
							notify(player, definition.Id .. " obby started. Land on each platform!")
						elseif run and run.course == definition.Id then
							local nextStep = course.path[run.stage + 1]
							if nextStep and onTop(point, nextStep) then
								local advanced, complete = Progress.advance(run, definition, run.stage + 1, now)
								if advanced and complete then
									runs[player], run = nil, nil
									onComplete(player, definition.Id)
								end
							elseif not onTop(point, course.start) and onTop(point, course.floor) and now >= (resets[player] or 0) then
								resets[player] = now + 1
								runs[player], run = nil, nil
								player.Character:PivotTo(CFrame.new(course.start.Position + Vector3.new(0, 4, 0)))
								root.AssemblyLinearVelocity = Vector3.zero
								notify(player, "Try again! Your current cash boost is safe.")
							end
						end
					end
				end
			end
			task.wait(0.08)
		end
	end)
	return folder
end

return ObbyWorld
