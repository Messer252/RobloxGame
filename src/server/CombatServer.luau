local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").CookieTycoon
local Abilities,Obbys=require(Shared.CombatAbilities),require(Shared.ObbyCatalog)
local Hill,Polish,Enchant,Town=require(Shared.ValleyEvents),require(Shared.BakeryPolish),require(Shared.Enchantments),require(Shared.TownCatalog)
local Server={}; Server.__index=Server
function Server.start(context,life)
 local self=setmetatable({context=context,life=life,cooldowns={},lastRequest={}},Server)
 for _,name in ipairs({"CastAbility","AbilityEffect"}) do
  local remote=Instance.new("RemoteEvent"); remote.Name,remote.Parent=name,context.Remotes; self[name]=remote
 end
 self.CastAbility.OnServerEvent:Connect(function(p,slot)
  local now=os.clock()
  if now-(self.lastRequest[p] or -10)<.1 then return end
  self.lastRequest[p]=now; self:Cast(p,slot)
 end)
 local function watch(p)
  local function clear()
   p:SetAttribute("DodgeUntil",0); p:SetAttribute("GuardUntil",0); p:SetAttribute("CombatBusyUntil",0)
  end
  p.CharacterAdded:Connect(clear)
  p:GetAttributeChangedSignal("Rebirths"):Connect(clear)
 end
 Players.PlayerAdded:Connect(watch)
 for _,p in ipairs(Players:GetPlayers()) do watch(p) end
 Players.PlayerRemoving:Connect(function(p) self.cooldowns[p],self.lastRequest[p]=nil,nil end)
 return self
end
function Server:Ready(player)
 local state=self.context.Usable(player)
 local root,hum=self.life.events:Eligible(player)
 local runtime=self.life:Runtime(player)
 if not state or not root or not hum or not runtime.pinTool or runtime.pinTool.Parent~=player.Character
  or hum.Sit or hum.PlatformStand then return nil end
 if player:GetAttribute("InCookieObby") or Obbys.inPit(root.Position.X,root.Position.Z,16) then return nil end
 return state,root,hum
end
function Server:Damage(player,root,move)
 self.life.wilderness:Strike(player,move.Range,move.Power,move.Cone)
 if not Hill.onHill(root.Position.X,root.Position.Y,root.Position.Z) then return end
 local state=self.context.GetState(player)
 local attack=Polish.active(state.data.life,os.time()).Damage+Enchant.effect(state.data.life,"Pin").Damage
 for _,other in ipairs(Players:GetPlayers()) do
  if other==player then continue end
  local target,hum=self.life.events:Eligible(other)
  if not target or not Hill.onHill(target.Position.X,target.Position.Y,target.Position.Z) then continue end
  local delta=target.Position-root.Position
  if not Abilities.inRange(delta.X,delta.Y,delta.Z,move.Range,delta:Dot(root.CFrame.LookVector),move.Cone)
   or not self.life.wilderness:Sight(root.Position,target.Position,player.Character,other.Character) then continue end
  local data=self.context.GetState(other).data.life
  local defense=Polish.active(data,os.time()).Defense+Town.defense(data)+Enchant.effect(data,"Armor").Defense
  local protection=Abilities.protection(workspace:GetServerTimeNow(),other:GetAttribute("DodgeUntil"),other:GetAttribute("GuardUntil"))
  hum:TakeDamage(Hill.damage(state.data.life.pin,attack,defense)*move.Power*protection)
 end
end
function Server:Cast(player,slot)
 local state,root,hum=self:Ready(player)
 if not state then return end
 if hum.FloorMaterial==Enum.Material.Air then return end
 local now=workspace:GetServerTimeNow()
 local cooldown=self.cooldowns[player] or {}; self.cooldowns[player]=cooldown
 local id,move=Abilities.cast(state.data.life.abilities,slot,cooldown,now)
 if not id then return end
 player:SetAttribute("AbilityReady"..slot,cooldown[slot])
 player:SetAttribute("CombatBusyUntil",cooldown.busy)
 local character,origin,rebirth=player.Character,root.Position,state.data.rebirths
 self.AbilityEffect:FireAllClients(player.UserId,id,now,"Cast",origin)
 local function valid()
  local current,currentRoot=self:Ready(player)
  return current==state and currentRoot==root and player.Character==character and state.data.rebirths==rebirth
   and state.data.life.abilities[slot]==id and (root.Position-origin).Magnitude<28
 end
 local function strike()
  if not valid() then return end
  self:Damage(player,root,move)
  self.AbilityEffect:FireAllClients(player.UserId,id,workspace:GetServerTimeNow(),"Impact",root.Position)
 end
 if id=="Dodge" then
  player:SetAttribute("DodgeUntil",now+.4)
  local attachment=Instance.new("Attachment"); attachment.Parent=root
  local velocity=Instance.new("LinearVelocity")
  velocity.Attachment0,velocity.RelativeTo,velocity.MaxForce=attachment,Enum.ActuatorRelativeTo.World,root.AssemblyMass*10000
  local forward=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
  velocity.ForceLimitsEnabled=true
  velocity.ForceLimitMode=Enum.ForceLimitMode.Magnitude
  local direction=forward.Magnitude>.01 and forward.Unit or Vector3.new(0,0,-1)
  local params=RaycastParams.new()
  params.FilterType,params.FilterDescendantsInstances,params.RespectCanCollide=Enum.RaycastFilterType.Exclude,{character},true
  local wall=workspace:Blockcast(root.CFrame,Vector3.new(2,3,2),direction*12,params)
  local duration=wall and math.clamp((wall.Distance-.6)/42,0,.28) or .28
  velocity.VectorVelocity=direction*42; velocity.Parent=root
  task.delay(duration,function()
   velocity:Destroy(); attachment:Destroy()
   if root.Parent==character then local v=root.AssemblyLinearVelocity; root.AssemblyLinearVelocity=Vector3.new(v.X*.3,v.Y,v.Z*.3) end
  end)
 elseif id=="Guard" then player:SetAttribute("GuardUntil",now+move.Duration)
 elseif id=="JumpAttack" then
  root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,55,root.AssemblyLinearVelocity.Z)
  task.spawn(function()
   local launched=os.clock()
   repeat task.wait(.04)
    if not valid() then return end
    if os.clock()-launched>.22 and root.AssemblyLinearVelocity.Y<=4 and hum.FloorMaterial~=Enum.Material.Air then strike(); return end
   until os.clock()-launched>move.Duration
  end)
 else task.delay(move.Windup,strike) end
end
return Server
