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

local function standing(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or root.AssemblyLinearVelocity.Y > 5 then return nil end
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, { character }
	local height = humanoid.HipHeight + root.Size.Y / 2 + (humanoid.RigType == Enum.HumanoidRigType.R6 and 2 or 0)
	for _, offset in ipairs({ Vector3.zero, Vector3.new(0.7, 0, 0), Vector3.new(-0.7, 0, 0), Vector3.new(0, 0, 0.7), Vector3.new(0, 0, -0.7) }) do
		local hit = workspace:Raycast(root.Position + offset, Vector3.new(0, -height - 0.9, 0), params)
		if hit and root.Position.Y - hit.Position.Y >= height - 1 then return hit.Instance, root end
	end
	return nil
end

function ObbyWorld.create(parent, onComplete, notify)
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Cookie Obbys", parent
	local courses, runs, resets, completed = {}, {}, {}, {}
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
			step.Material = Enum.Material.Slate
			local trim = platform(model, "Checkpoint Trim", step.Position - Vector3.new(0, 0.35, 0), definition.Width + 0.25, Color3.fromRGB(87, 67, 53))
			trim.Size, trim.CanCollide, trim.CanQuery = Vector3.new(definition.Width + 0.25, 0.2, definition.Width + 0.25), false, false
			table.insert(path, step)
			if index == definition.Count then
				sign(step, "FINISH\n" .. definition.Id .. " • Cash boost")
				local back = Instance.new("ProximityPrompt")
				back.ActionText, back.ObjectText, back.HoldDuration = "Return to plaza", definition.Id .. " finish", 0
				back.MaxActivationDistance, back.RequiresLineOfSight, back.Parent = 8, false, step
				back.ActionText = "Claim boost / return"
				back.Triggered:Connect(function(player)
					local surface, root = standing(player)
					if surface ~= step or completed[player] ~= definition.Id then
						notify(player, "Land on every checkpoint, then wait for your finish reward.")
						return
					end
					completed[player] = nil
					player.Character:PivotTo(CFrame.new(0, 5, -9))
					root.AssemblyLinearVelocity = Vector3.zero
				end)
			end
		end
		table.insert(courses, { definition = definition, start = start, floor = floor, path = path })
	end
	Players.PlayerRemoving:Connect(function(player) runs[player], resets[player], completed[player] = nil, nil, nil end)
	task.spawn(function()
		while folder.Parent do
			local now = os.clock()
			for _, player in ipairs(Players:GetPlayers()) do
				local surface, root = standing(player)
				local run = runs[player]
				if run and run.character ~= player.Character then runs[player], run = nil, nil end
				if surface then
					for _, course in ipairs(courses) do
						local definition = course.definition
						if surface == course.start and (not run or run.course ~= definition.Id or run.stage > 0) then
							run = Progress.start(definition, now)
							run.character = player.Character
							runs[player], completed[player] = run, nil
							notify(player, definition.Id .. " started. Land on each platform in order.")
						elseif run and run.course == definition.Id then
							if run.stage < definition.Count and surface == course.path[run.stage + 1] then
								Progress.advance(run, definition, run.stage + 1, now)
							end
							if run.stage == definition.Count and not run.awarded then
								if onComplete(player, definition.Id) == true then
									run.awarded = true
									completed[player], runs[player], run = definition.Id, nil, nil
									notify(player, definition.Id .. " complete! Check the HUD boost timer.")
								end
							elseif surface == course.floor and now >= (resets[player] or 0) then
								resets[player], runs[player], run = now + 1, nil, nil
								player.Character:PivotTo(CFrame.new(course.start.Position + Vector3.new(0, 4, 0)))
								root.AssemblyLinearVelocity = Vector3.zero
								notify(player, "Try again! Your current boost stays active.")
							end
						end
					end
				end
			end
			task.wait(0.04)
		end
	end)
	return folder
end
return ObbyWorld
