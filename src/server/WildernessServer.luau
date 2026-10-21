local Players=game:GetService("Players")
local Paths=game:GetService("PathfindingService")
local Http=game:GetService("HttpService")
local Shared=game:GetService("ReplicatedStorage").CookieTycoon
local Rules,Polish=require(Shared.WildernessRules),require(Shared.BakeryPolish)
local Town,Enchant,Rewards=require(Shared.TownCatalog),require(Shared.Enchantments),require(Shared.WildernessRewards)
local W,Models=require(script.Parent.WorldWidgets),require(script.Parent.CookieBeastModel)
local Abilities=require(Shared.CombatAbilities)
local Server={}; Server.__index=Server

function Server.start(context)
	local self=setmetatable({context=context,creatures={},pending={},nextBoss=os.clock()+Rules.BossInterval,nextNightSpawn=0,born={}},Server)
	self.folder=Instance.new("Folder"); self.folder.Name,self.folder.Parent="Cookie Wilderness",context.World
	local arena=W.part(self.folder,"Colossus Arena",Vector3.new(1,Rules.BossRadius*2,Rules.BossRadius*2),Vector3.new(Rules.BossX,.5,Rules.BossZ),Color3.fromRGB(123,111,95),Enum.Material.Slate)
	arena.Shape,arena.CFrame=Enum.PartType.Cylinder,arena.CFrame*CFrame.Angles(0,0,math.pi/2)
	local marker=W.part(self.folder,"Boss Notice Board",Vector3.new(1,5,1),Vector3.new(Rules.BossX-45,3,Rules.BossZ-25),Color3.fromRGB(91,64,44),Enum.Material.Wood)
	self.sign=W.label(marker,"CRUMB COLOSSUS\nReturns every 30 minutes",100)
	self.sign.Parent.Size=UDim2.fromOffset(280,75)
	for i=1,12 do
		local angle=i*math.pi/6
		W.part(self.folder,"Arena Chocolate Marker",Vector3.new(2,.3,2),Vector3.new(Rules.BossX+math.cos(angle)*47,1.15,Rules.BossZ+math.sin(angle)*47),Color3.fromRGB(79,48,33))
	end
	local function watch(player)
		self.born[player]=os.clock()
		player.CharacterAdded:Connect(function() self.born[player]=os.clock() end)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(p) self.born[p]=nil end)
	for _,p in ipairs(Players:GetPlayers()) do watch(p) end
	task.spawn(function() while self.folder.Parent do self:Step(); task.wait(.2) end end)
	return self
end
function Server:Player(player)
	local char=player.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	local state=self.context.GetState(player)
	if not root or not hum or hum.Health<=0 or not state or state.closing or state.profile.lost or state.profile.closed
		or player:GetAttribute("AdminFlying") or player:GetAttribute("AdminInvisible") then return nil end
	return root,hum,state
end
function Server:Ground(x,z)
	local filter={self.folder}
	for _,p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(filter,p.Character) end end
	local params=RaycastParams.new()
	params.FilterType,params.FilterDescendantsInstances,params.RespectCanCollide=Enum.RaycastFilterType.Exclude,filter,true
	local hit=workspace:Raycast(Vector3.new(x,40,z),Vector3.new(0,-65,0),params)
	if hit and hit.Normal.Y>.7 and hit.Position.Y<12 then return hit.Position end
	return nil
end
function Server:Spawn(boss,zone,index)
	local ground=boss and Vector3.new(zone.x,1,zone.z) or nil
	-- A tree or rock must not permanently block a whole wilderness spawn area.
	for attempt=1,8 do
		if ground then break end
		local angle=(index+attempt)*2.399
		ground=self:Ground(zone.x+math.cos(angle)*zone.radius*.4,zone.z+math.sin(angle)*zone.radius*.4)
	end
	if not ground then return end
	local model,hum=Models.create(self.folder,boss,index)
	local root=model.HumanoidRootPart
	model:PivotTo(CFrame.new(ground+Vector3.new(0,boss and 9 or 3,0)))
	local count=math.max(1,#Players:GetPlayers())
	local maximum=boss and (1400+650*(count-1)) or 70+index%3*25
	hum.MaxHealth,hum.Health=maximum,maximum
	local record={model=model,root=root,hum=hum,boss=boss,zone=zone,home=ground,hp=maximum,maximum=maximum,damage={},
		cashPool=boss and 2000000*count or 750,doughPool=boss and 250+100*count or 8,crumbPool=boss and 20+5*count or 0,
		expires=os.clock()+(boss and Rules.BossLifetime or 600),nextMove=0,nextAttack=0,position=root.Position,progressAt=os.clock()}
	record.label=W.label(root,model.Name, boss and 180 or 60)
	record.label.Parent.StudsOffset,record.label.Parent.Size=Vector3.new(0,boss and 12 or 5,0),UDim2.fromOffset(boss and 300 or 200,65)
	table.insert(self.creatures,record)
	if boss then self.boss=record; self.context.Announce("Boss") end
end
function Server:Move(record,goal)
	if record.pathBusy then return end
	record.pathBusy=true
	task.spawn(function()
		local path=Paths:CreatePath({AgentRadius=record.boss and 5 or 2,AgentHeight=record.boss and 18 or 7,AgentCanJump=false,WaypointSpacing=6})
		local ok=pcall(function() path:ComputeAsync(record.root.Position,goal) end)
		if record.model.Parent and record.hp>0 and not record.windup and ok and path.Status==Enum.PathStatus.Success then
			local points=path:GetWaypoints()
			local waypoint=points[2]
			if waypoint and Rules.inside(waypoint.Position.X,waypoint.Position.Z,record.zone) then record.hum:MoveTo(waypoint.Position) end
		end
		path:Destroy(); record.pathBusy=false
	end)
end
function Server:Sight(a,b,ignore,target)
	local params=RaycastParams.new()
	params.FilterType,params.FilterDescendantsInstances,params.RespectCanCollide=Enum.RaycastFilterType.Exclude,{ignore},true
	local hit=workspace:Raycast(a,b-a,params)
	return not hit or hit.Instance:IsDescendantOf(target)
end
function Server:Swing(player)
	local root,_,state=self:Player(player)
	if not root then return false end
	local best,distance
	for _,r in ipairs(self.creatures) do
		local delta=r.root.Position-root.Position
		if r.hp>0 and Rules.inside(root.Position.X,root.Position.Z,r.zone) and delta.Magnitude<=(r.boss and 17 or 9)
			and delta:Dot(root.CFrame.LookVector)>-1 and (not distance or delta.Magnitude<distance)
			and self:Sight(root.Position,r.root.Position,player.Character,r.model) then best,distance=r,delta.Magnitude end
	end
	if not best then return false end
	local damage=Rules.damage(state.data.life.pin,Polish.active(state.data.life,os.time()).Damage+Enchant.effect(state.data.life,"Pin").Damage)
	Rules.hit(best,player.UserId,damage)
	best.hum.Health=math.max(1,best.hp) -- Death and rewards are controlled by the server ledger.
	if best.hp<=0 then self:Defeat(best) end
	return true
end
function Server:Strike(player,range,multiplier,cone)
 local root,_,state=self:Player(player)
 if not root then return end
 for _,r in ipairs(self.creatures) do
  local d=r.root.Position-root.Position
  if r.hp>0 and Rules.inside(root.Position.X,root.Position.Z,r.zone)
   and Abilities.inRange(d.X,d.Y,d.Z,range,d:Dot(root.CFrame.LookVector),cone)
   and self:Sight(root.Position,r.root.Position,player.Character,r.model) then
   local damage=Rules.damage(state.data.life.pin,Polish.active(state.data.life,os.time()).Damage+Enchant.effect(state.data.life,"Pin").Damage)*multiplier
   Rules.hit(r,player.UserId,damage); r.hum.Health=math.max(1,r.hp)
   if r.hp<=0 then self:Defeat(r) end
  end
 end
end
function Server:Defeat(record)
	if record.defeated then return end
	record.defeated=true
	record.hum:Move(Vector3.zero); record.root.Anchored=true
	if record.ring then record.ring:Destroy() end
	record.label.Text="DEFEATED • Rewards earned!"
	record.expires=os.clock()+4
	for _,player in ipairs(Players:GetPlayers()) do
		local reward=Rules.reward(record,player.UserId)
		if reward then
			reward.cookie=not record.boss and Rules.drop(math.random(),math.random()) or nil
			table.insert(self.pending,{player=player,reward=reward,id="beast:"..Http:GenerateGUID(false),cookieId=Http:GenerateGUID(false),boss=record.boss})
		end
	end
end
function Server:Pay(entry)
	local player=entry.player
	local state=self.context.Usable(player)
	if not state or entry.busy then return false end
	entry.busy=true
	local function grant(data) return Rewards.grant(data,entry.reward,entry.cookieId) end
	local function notify()
		self.context.Changed(player,state)
		self.context.Notify(player,(entry.boss and "Colossus" or "Monster")..": $"..self.context.Format(entry.reward.cash).." to collect • "..entry.reward.dough.." dough • "..entry.reward.crumbs.." Star Crumbs"..(entry.reward.cookie and " • Cookie drop (5 extra dough if bag full)" or ""))
	end
	if state.profile.sessionOnly then grant(state.data); notify(); entry.done=true; return true end
	state.receiptWorkers+=1
	task.spawn(function()
		local ok,reason
		for _=1,6 do
			ok,reason=self.context.Profiles:GrantReceipt(state.profile,entry.id,1,grant)
			if ok or (reason~="busy" and reason~="unavailable") then break end
			task.wait(1)
		end
		state.receiptWorkers-=1; entry.done=true
		if ok then
			if player.Parent then notify() else self.context.Profiles:Save(state.profile,true) end
		elseif player.Parent then self.context.Notify(player,"Reward save could not finish. Rejoin to recover any committed reward.") end
	end)
	return true
end
function Server:Attack(record,now)
	local radius=record.boss and 18 or 6
	record.windup={at=now+(record.boss and 1.15 or .65),center=record.root.Position,radius=radius}
	record.hum:MoveTo(record.root.Position)
	local ring=W.part(self.folder,"Avoid the red attack zone",Vector3.new(.1,radius*2,radius*2),Vector3.new(record.root.Position.X,record.boss and 1.1 or record.root.Position.Y-2.8,record.root.Position.Z),Color3.fromRGB(231,96,67),Enum.Material.Neon)
	ring.Shape,ring.CFrame=Enum.PartType.Cylinder,ring.CFrame*CFrame.Angles(0,0,math.pi/2)
	ring.CanCollide,ring.CanQuery,ring.Transparency=false,false,.65
	record.ring=ring
end
function Server:Step()
	local now=os.clock()
	local night=Rules.night(game:GetService("Lighting").ClockTime)
	if now>=self.nextBoss then
		self.nextBoss=now+Rules.BossInterval
		if not self.boss then self:Spawn(true,Rules.bossZone(),1) end
	end
	if night and now>=self.nextNightSpawn then
		self.nextNightSpawn=now+Rules.RespawnSeconds
		for i,zone in ipairs(Rules.Zones) do
			local count=0
			for _,r in ipairs(self.creatures) do if r.zone==zone and r.hp>0 then count+=1 end end
			if count<2 then self:Spawn(false,zone,i+count) end
		end
	end
	self.sign.Text=self.boss and "CRUMB COLOSSUS • ACTIVE\nRolling pins deal damage • Jump over red stomps" or ("CRUMB COLOSSUS\nNext arrival "..math.floor(math.max(0,self.nextBoss-now)/60)..":"..string.format("%02d",math.floor(math.max(0,self.nextBoss-now)%60)))
	for i=#self.creatures,1,-1 do
		local r=self.creatures[i]
		if now>=r.expires or not night and not r.boss or r.root.Position.Y< -20 then
			if r.ring then r.ring:Destroy() end
			r.model:Destroy(); table.remove(self.creatures,i)
			if self.boss==r then self.boss=nil end
			continue
		end
		if r.hp<=0 then continue end
		r.label.Text=r.model.Name.."\n"..math.ceil(r.hp).." / "..r.maximum.." HP"..(r.boss and " • Deal 1% to earn a share" or "")
		if r.windup then
			if now>=r.windup.at then
				for _,p in ipairs(Players:GetPlayers()) do
					local root,hum,state=self:Player(p)
					if root and now-(self.born[p] or now)>5 and Rules.inside(root.Position.X,root.Position.Z,r.zone) then
						local center=r.windup.center
						local delta=Vector3.new(root.Position.X-center.X,0,root.Position.Z-center.Z)
						if delta.Magnitude<=r.windup.radius and root.Position.Y< (r.boss and 8 or center.Y+2)
							and self:Sight(center,root.Position,r.model,p.Character) then
							local defense=Town.defense(state.data.life)+Enchant.effect(state.data.life,"Armor").Defense+Polish.active(state.data.life,os.time()).Defense
							local protection=Abilities.protection(workspace:GetServerTimeNow(),p:GetAttribute("DodgeUntil"),p:GetAttribute("GuardUntil"))
							hum:TakeDamage((r.boss and 26 or 10)*(1-math.clamp(defense,0,.6))*protection)
						end
					end
				end
				r.ring:Destroy(); r.ring=nil; r.windup=nil; r.nextAttack=now+(r.boss and 3 or 1.7)
			end
			continue
		end
		local target,nearest=nil,math.huge
		for _,p in ipairs(Players:GetPlayers()) do
			local root=self:Player(p)
			if root and now-(self.born[p] or now)>5 and Rules.inside(root.Position.X,root.Position.Z,r.zone) then
				local d=(root.Position-r.root.Position).Magnitude
				if d<nearest then target,nearest=root,d end
			end
		end
		if target and nearest<(r.boss and 20 or 7) and now>=r.nextAttack then self:Attack(r,now)
		elseif now>=r.nextMove then
			r.nextMove=now+(target and .9 or 2.5)
			local goal=target and target.Position
			if not goal then
				local a=math.random()*math.pi*2
				goal=self:Ground(r.zone.x+math.cos(a)*r.zone.radius*.6,r.zone.z+math.sin(a)*r.zone.radius*.6)
			end
			if (r.root.Position-r.position).Magnitude>1 then r.position,r.progressAt=r.root.Position,now end
			if not Rules.inside(r.root.Position.X,r.root.Position.Z,r.zone) or now-r.progressAt>15 then
				goal=r.home
				-- Recover a blocked creature inside its home area, never at a player.
				if now-r.progressAt>25 then r.model:PivotTo(CFrame.new(goal+Vector3.new(0,r.boss and 9 or 4,0))); r.progressAt=now end
			end
			if goal then self:Move(r,goal) end
		end
	end
	for i=#self.pending,1,-1 do
		local e=self.pending[i]
		if e.done or not e.player.Parent and not e.busy then table.remove(self.pending,i)
		elseif not e.busy then self:Pay(e) end
	end
end
return Server
