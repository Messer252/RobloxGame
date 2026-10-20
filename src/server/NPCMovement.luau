local Players = game:GetService("Players")
local Physics = game:GetService("PhysicsService")
local Paths = game:GetService("PathfindingService")
local Rules = require(game:GetService("ReplicatedStorage").CookieTycoon.NPCMotionRules)
local Avatar = require(script.Parent.BakerAvatar)
local Movement = {}
for _,name in ipairs({"CookieCustomers","CookiePlayers","CookieBodies"}) do
	if not Physics:IsCollisionGroupRegistered(name) then Physics:RegisterCollisionGroup(name) end
end
Physics:CollisionGroupSetCollidable("CookieCustomers","CookieCustomers",false)
Physics:CollisionGroupSetCollidable("CookieCustomers","CookiePlayers",false)
Physics:CollisionGroupSetCollidable("CookieCustomers","CookieBodies",false)
-- Players still collide with world geometry and conveyor cookies, but cannot
-- push a customer over or stand on their head while they are bargaining.
local function character(model)
	local function assign(part)
		if part:IsA("BasePart") and part.CollisionGroup=="Default" then part.CollisionGroup="CookiePlayers" end
	end
	for _,part in ipairs(model:GetDescendants()) do assign(part) end
	local added=model.DescendantAdded:Connect(assign)
	model.Destroying:Once(function() added:Disconnect() end)
end
local function player(player)
	player.CharacterAdded:Connect(character)
	if player.Character then character(player.Character) end
end
Players.PlayerAdded:Connect(player)
for _,present in ipairs(Players:GetPlayers()) do player(present) end

function Movement.start(customer,world,index,onDeparture)
	local model,root,hum=customer.model,customer.root,customer.humanoid
	local random,side=Random.new(index*719+os.time()),index%2==0 and -1 or 1
	for _,part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup="CookieCustomers"
			part.CanCollide=part.Name=="Torso" or part.Name=="Head"
			part.CanTouch=false
			part.Anchored=false
			if part.CanCollide then part.CustomPhysicalProperties=PhysicalProperties.new(.7,.15,0,100,100) end
		end
	end
	hum.WalkSpeed,hum.AutoRotate,hum.HipHeight=Rules.Speed,true,0
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
	root:SetNetworkOwner(nil)
	local function alive() return world.Parent~=nil and model.Parent~=nil and hum.Health>0 end
	local function reserved() return customer.reservedUntil>os.clock() end
	local function stop()
		hum:Move(Vector3.zero)
		hum:MoveTo(root.Position)
	end
	local function ground(x,z)
		local params=RaycastParams.new()
		local exclude={model}
		for _,p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(exclude,p.Character) end end
		for _,npc in ipairs(game:GetService("CollectionService"):GetTagged("CookieNPC")) do table.insert(exclude,npc) end
		params.FilterType,params.FilterDescendantsInstances,params.RespectCanCollide=Enum.RaycastFilterType.Exclude,exclude,true
		local hit=workspace:Raycast(Vector3.new(x,12,z),Vector3.new(0,-24,0),params)
		if hit and hit.Normal.Y>.75 then return hit.Position end
		return nil
	end
	local function follow(goal)
		local path=Paths:CreatePath({AgentRadius=2,AgentHeight=6.5,AgentCanJump=false,AgentCanClimb=false,WaypointSpacing=5})
		local ok=pcall(function() path:ComputeAsync(root.Position,goal) end)
		if not alive() or reserved() or customer.depart or not ok or path.Status~=Enum.PathStatus.Success then path:Destroy(); return false end
		local waypoints=path:GetWaypoints()
		local cursor,blocked=2,false
		local connection=path.Blocked:Connect(function(i) if i>=cursor then blocked=true end end)
		local arrived=true
		for i=2,#waypoints do
			cursor=i
			local waypoint=waypoints[i]
			-- Never take a computed shortcut into a bakery, shop or off-map area.
			if math.abs(waypoint.Position.X)>11 or math.abs(waypoint.Position.Z)>550 or waypoint.Action==Enum.PathWaypointAction.Jump then arrived=false; break end
			local watch=Rules.watch(root.Position.X,root.Position.Z,os.clock())
			local sent=-math.huge
			while alive() do
				if reserved() or customer.depart or blocked then arrived=false; break end
				local now,position=os.clock(),root.Position
				local state=Rules.check(watch,position.X,position.Y,position.Z,waypoint.Position.X,waypoint.Position.Y,waypoint.Position.Z,now)
				if state=="arrived" then break end
				if state=="blocked" then arrived=false; break end
				if now-sent>=Rules.Refresh then hum:MoveTo(waypoint.Position); sent=now end
				task.wait(.1)
			end
			if not arrived or not alive() then break end
		end
		connection:Disconnect(); path:Destroy()
		if alive() then stop() end
		return arrived
	end
	task.spawn(function()
		task.wait(index*.12) -- Stagger initial path requests across the six customers.
		while alive() do
			if reserved() then
				stop()
				task.wait(.1)
			else
				if customer.depart then customer.depart=false; onDeparture() end
				if root.Position.Y < -12 or math.abs(root.Position.X)>24 or math.abs(root.Position.Z)>580 then
					-- Recovery is only for a fallen/displaced NPC, never normal walking.
					local safe=ground(side*5,math.clamp(root.Position.Z,-500,500))
					if safe then
						root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
						Avatar.place(model,safe,Vector3.zAxis)
					end
				end
				local x,z=Rules.destination(root.Position.Z,side,random:NextNumber(),random:NextNumber())
				local goal=ground(x,z)
				local arrived=goal and follow(goal)
				local untilTime=os.clock()+(arrived and random:NextNumber(1,2.5) or 1)
				while alive() and not reserved() and not customer.depart and os.clock()<untilTime do task.wait(.1) end
			end
		end
	end)
end
return Movement
