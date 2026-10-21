local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.CookieTycoon.ObbyCatalog)
local Progress = require(ReplicatedStorage.CookieTycoon.ObbyProgress)
local Claims=require(ReplicatedStorage.CookieTycoon.ObbyClaims)
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

local function standing(player,surfaces)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or root.AssemblyLinearVelocity.Y > 5 then return nil end
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, surfaces
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
	local courses, runs, resets, completed, surfaces = {}, {}, {}, {}, {}
	local finish,land
	local claims=Claims.new()
	for _, definition in ipairs(Catalog) do
		local model = Instance.new("Model")
		model.Name, model.Parent = definition.Id .. " Obby", folder
		local tint = Color3.fromRGB(table.unpack(definition.Color))
		local start = platform(model, "Start", Vector3.new(230, 0.4, definition.Z), 10, tint)
		table.insert(surfaces,start)
		sign(start, definition.Id .. " • +" .. math.floor(definition.Bonus * 100) .. "% income\nAvoid red • falls restart")
		local bounds=Catalog.pit(definition)
		local floor=platform(model,"Restart Pit",Vector3.new((bounds[1]+bounds[2])/2,-9,definition.Z),1,Color3.fromRGB(60,48,45))
		floor.Size=Vector3.new(bounds[2]-bounds[1],1,bounds[4]-bounds[3])
		floor.Material=Enum.Material.Slate
		-- Tall stone walls make the excavated pit readable from the approach.
		for _,z in ipairs({bounds[3],bounds[4]}) do
			local wall=platform(model,"Pit Retaining Wall",Vector3.new((bounds[1]+bounds[2])/2,-4.5,z),1,Color3.fromRGB(110,107,101))
			wall.Size,wall.Material=Vector3.new(bounds[2]-bounds[1],8,1),Enum.Material.Slate
		end
		for _,x in ipairs({bounds[1],bounds[2]}) do
			local wall=platform(model,"Pit End Wall",Vector3.new(x,-4.5,definition.Z),1,Color3.fromRGB(110,107,101))
			wall.Size,wall.Material=Vector3.new(1,8,bounds[4]-bounds[3]),Enum.Material.Slate
		end
		local course={definition=definition,start=start,path={},hazards={}}
		for index = 1, definition.Count do
			local p = Catalog.platform(definition, index)
			local step = platform(model, "Landing Platform", Vector3.new(p.x, p.y, p.z), p.width, tint)
			step.Material = Enum.Material.Slate
			local trim = platform(model, "Platform Trim", step.Position - Vector3.new(0, 0.35, 0), p.width + 0.25, Color3.fromRGB(87, 67, 53))
			trim.Size, trim.CanCollide, trim.CanQuery = Vector3.new(p.width + 0.25, 0.2, p.width + 0.25), false, false
			table.insert(course.path, step)
			table.insert(surfaces,step)
			if p.hazard then
				local offset=p.hazard=="Edge" and Vector3.new(0,.85,(index%8==0 and -1 or 1)*2.6) or Vector3.new(0,.95,0)
				local hazard=platform(model,"Red Restart Zone",step.Position+offset,1,Color3.fromRGB(214,68,62))
				hazard.Size=p.hazard=="Edge" and Vector3.new(6.8,.7,1) or Vector3.new(.55,.9,6.4)
				hazard.Material, hazard.CanCollide, hazard.CanQuery=Enum.Material.SmoothPlastic,false,false
				local base=hazard.CFrame
				table.insert(course.hazards,{part=hazard,base=base,spin=p.hazard=="Sweeper",phase=index*.7})
			end
			if index == definition.Count then
				sign(step, "FINISH\nLand here to claim your boost")
				local back = Instance.new("ProximityPrompt")
				back.ActionText, back.ObjectText, back.HoldDuration = "Return to plaza", definition.Id .. " finish", 0
				back.MaxActivationDistance, back.RequiresLineOfSight, back.Parent = 8, false, step
				back.Triggered:Connect(function(player)
					local surface, root = standing(player,surfaces)
					if surface==step then land(player,course,definition.Count,os.clock()); finish(player,course,surface,os.clock()) end
					if surface ~= step or completed[player] ~= definition.Id then
						notify(player, "Start at the green pad and land on each platform. Finish rewards may wait briefly for saving.")
						return
					end
					completed[player],runs[player]=nil,nil
					player.Character:PivotTo(CFrame.new(0, 5, -9))
					root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
				end)
			end
		end
		table.insert(courses,course)
	end
    finish=function(player,course,surface,now)
        local run=runs[player]
        claims:Validate(player,run,course.definition,surface==course.path[course.definition.Count],now)
        local awarded,message=claims:Attempt(player,course.definition.Id,function() return onComplete(player,course.definition.Id) end)
        if awarded==true then
            if run then run.awarded=true end
            completed[player],runs[player]=course.definition.Id,nil
            player:SetAttribute("InCookieObby",false)
            notify(player,message or "Course complete! Your boost is active.")
        elseif awarded==false and run and not run.waitNotified then
            run.waitNotified=true; notify(player,message)
        end
    end
    land=function(player,course,index,now)
        if now<(resets[player] or 0) or player:GetAttribute("AdminFlying") then return end
        local char=player.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health<=0 then return end
        local run=runs[player]
        if run and run.character~=char then runs[player],run=nil,nil end
        if claims.pending[player] then return end
        if index==0 then
            if not run or run.course~=course.definition.Id or run.stage>0 then
                run=Progress.start(course.definition,now); run.character=char
                runs[player],completed[player]=run,nil
                player:SetAttribute("InCookieObby",true)
                notify(player,course.definition.Id.." started. Land on each platform; avoid red.")
            end
        elseif run and run.course==course.definition.Id then
            Progress.advance(run,course.definition,index,now)
            if index==course.definition.Count and run.stage<index and not run.missedNotified then
                run.missedNotified=true
                notify(player,"A platform was skipped. Return to the missing landing or restart at the green pad.")
            end
        elseif index==course.definition.Count and completed[player]~=course.definition.Id then
            if now>(resets[player] or 0) then
                resets[player]=now+3
                notify(player,"This run never started. Begin on the green start pad to earn the finish prize.")
            end
        end
    end
    -- Touch captures short landings; the raycast poll handles standing and
    -- retries. Only character body parts and feet over the platform top count.
    for _,course in ipairs(courses) do
        local steps={course.start}; for _,p in ipairs(course.path) do table.insert(steps,p) end
        for index,step in ipairs(steps) do
            step.Touched:Connect(function(part)
                local player=Players:GetPlayerFromCharacter(part.Parent)
                local root=player and player.Character:FindFirstChild("HumanoidRootPart")
                local hum=player and player.Character:FindFirstChildOfClass("Humanoid")
                if not root or not hum then return end
                local height=hum.HipHeight+root.Size.Y/2+(hum.RigType==Enum.HumanoidRigType.R6 and 2 or 0)
                local feet=root.Position.Y-height-(step.Position.Y+step.Size.Y/2)
                if math.abs(root.Position.X-step.Position.X)<=step.Size.X/2+.6 and math.abs(root.Position.Z-step.Position.Z)<=step.Size.Z/2+.6 and feet>=-.7 and feet<=1 then
                    land(player,course,index-1,os.clock())
                    finish(player,course,step,os.clock())
                end
            end)
        end
    end
	local function restart(player,course,root,now)
		if now<(resets[player] or 0) then return end
		resets[player],runs[player],completed[player]=now+.5,nil,nil
		player:SetAttribute("InCookieObby",false)
		player.Character:PivotTo(CFrame.new(course.start.Position+Vector3.new(0,4,0))*CFrame.Angles(0,-math.pi/2,0))
		root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
		notify(player,"Try again! Avoid red zones. Your active boost stays.")
	end
	local function watch(player)
		player.CharacterAdded:Connect(function() runs[player],resets[player],completed[player]=nil,nil,nil; player:SetAttribute("InCookieObby",false) end)
	end
	Players.PlayerAdded:Connect(watch)
	for _,player in ipairs(Players:GetPlayers()) do watch(player) end
	Players.PlayerRemoving:Connect(function(player) runs[player], resets[player], completed[player],claims.pending[player] = nil, nil, nil,nil end)
	task.spawn(function()
		while folder.Parent do
			local now=os.clock()
			for _,course in ipairs(courses) do for _,hazard in ipairs(course.hazards) do
				if hazard.spin then hazard.part.CFrame=hazard.base*CFrame.Angles(0,now*.85+hazard.phase,0) end
			end end
			for _,player in ipairs(Players:GetPlayers()) do
                if claims.pending[player] then for _,course in ipairs(courses) do finish(player,course,nil,now) end end
				local char=player.Character
				local root=char and char:FindFirstChild("HumanoidRootPart")
				local hum=char and char:FindFirstChildOfClass("Humanoid")
				if not root or not hum or hum.Health<=0 or player:GetAttribute("AdminFlying") then runs[player],completed[player]=nil,nil; player:SetAttribute("InCookieObby",false); continue end
				local run=runs[player]
				if run and run.character~=char then runs[player],completed[player],run=nil,nil,nil end
				local surface=standing(player,surfaces)
				for _,course in ipairs(courses) do
					local definition=course.definition
					local nearby=root.Position.X>=235 and root.Position.X<=450 and math.abs(root.Position.Z-definition.Z)<40
					local hit=nearby and root.Position.Y<1
					if nearby and not hit then
						local height=hum.HipHeight+root.Size.Y/2+(hum.RigType==Enum.HumanoidRigType.R6 and 2 or 0)
						local center=root.Position+Vector3.new(0,(2-height)/2,0)
						for _,hazard in ipairs(course.hazards) do
							local p=hazard.part.CFrame:PointToObjectSpace(center)
							local size=hazard.part.Size
							if Progress.hazardContact(p.X,p.Y,p.Z,size.X,size.Y,size.Z,height) then hit=true; break end
						end
					end
					if hit and not claims.pending[player] then restart(player,course,root,now); run=nil; break end
                    if surface==course.start then land(player,course,0,now)
                    else
                        local stage=table.find(course.path,surface)
                        if stage then land(player,course,stage,now) end
                    end
                    finish(player,course,surface,now)
                    run=runs[player]
				end
				-- Returning home or leaving the course cannot resume an old partial run.
				if run and not run.finishValidated then
					for _,course in ipairs(courses) do
						if course.definition.Id==run.course and (root.Position.X<220 or root.Position.X>455 or math.abs(root.Position.Z-course.definition.Z)>50) then runs[player]=nil; player:SetAttribute("InCookieObby",false) end
					end
				end
			end
			task.wait(.04)
		end
	end)
	return folder
end
return ObbyWorld
