local Players,Input,Run=game:GetService("Players"),game:GetService("UserInputService"),game:GetService("RunService")
local Prompts,Debris,Tween=game:GetService("ProximityPromptService"),game:GetService("Debris"),game:GetService("TweenService")
local Shared=game:GetService("ReplicatedStorage").CookieTycoon
local Abilities=require(Shared.CombatAbilities)
local Obbys=require(Shared.ObbyCatalog)
local Client={}
function Client.start(player,gui,remotes,audio)
 local cast,effect=remotes:WaitForChild("CastAbility"),remotes:WaitForChild("AbilityEffect")
 local connections,poses,prompts={}, {}, {}
 local bar=Instance.new("Frame")
 bar.Name,bar.AnchorPoint,bar.Position,bar.Size="CombatHotbar",Vector2.new(.5,1),UDim2.new(.5,0,1,-145),UDim2.fromOffset(196,60)
 bar.BackgroundTransparency,bar.Visible,bar.Parent=1,false,gui
 local buttons={}
 local function holding()
  local char=player.Character
  if not char then return false end
  for _,child in ipairs(char:GetChildren()) do if child:IsA("Tool") and child:GetAttribute("RollingPinTier") then return true end end
  return false
 end
 local function blocked()
  if Input:GetFocusedTextBox() or game:GetService("GuiService").MenuIsOpen then return true end
  for _,child in ipairs(gui:GetChildren()) do if child:IsA("GuiObject") and child.Visible and child:GetAttribute("BlocksCameraLock") then return true end end
  return false
 end
 local function use(slot)
  if holding() and not blocked() then cast:FireServer(slot) end
 end
 for i,slot in ipairs({"E","Q"}) do
  local button=Instance.new("TextButton")
  button.Name,button.Position,button.Size=slot.."Ability",UDim2.fromOffset((i-1)*102,0),UDim2.fromOffset(94,60)
  button.BackgroundColor3,button.TextColor3,button.TextSize,button.TextWrapped=Color3.fromRGB(65,44,34),Color3.fromRGB(255,231,187),12,true
  button.Font,button.BorderSizePixel,button.Parent=Enum.Font.GothamBold,0,bar
  local corner=Instance.new("UICorner"); corner.CornerRadius,corner.Parent=UDim.new(0,10),button
  local stroke=Instance.new("UIStroke"); stroke.Color,stroke.Thickness,stroke.Parent=Color3.fromRGB(190,145,84),1,button
  local pad=Instance.new("UIPadding"); pad.PaddingLeft,pad.PaddingRight,pad.Parent=UDim.new(0,4),UDim.new(0,4),button
  button.Activated:Connect(function() use(slot) end); buttons[slot]=button
 end
 table.insert(connections,Prompts.PromptShown:Connect(function(p) prompts[p]=true end))
 table.insert(connections,Prompts.PromptHidden:Connect(function(p) prompts[p]=nil end))
 table.insert(connections,Input.InputBegan:Connect(function(input,processed)
  if processed then return end
  local slot=({[Enum.KeyCode.E]="E",[Enum.KeyCode.Q]="Q",[Enum.KeyCode.ButtonL1]="E",[Enum.KeyCode.ButtonR1]="Q"})[input.KeyCode]
  if slot=="E" then
   -- Shop, pickup and gift prompts keep E when one is actually visible.
   for prompt in pairs(prompts) do if prompt.Parent and prompt.Enabled and prompt.KeyboardKeyCode==Enum.KeyCode.E then return end end
  end
  if slot then use(slot) end
 end))
 local function ring(position,range,color)
  local p=Instance.new("Part")
  p.Shape,p.Size,p.CFrame=Enum.PartType.Cylinder,Vector3.new(.12,2,2),CFrame.new(position-Vector3.new(0,2.5,0))*CFrame.Angles(0,0,math.pi/2)
  p.Material,p.Color,p.Transparency=Enum.Material.Neon,color,.65
  p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
  p.Parent=workspace
  Tween:Create(p,TweenInfo.new(.45),{Size=Vector3.new(.08,range*2,range*2),Transparency=1}):Play()
  Debris:AddItem(p,.5)
 end
 local function release(record)
  if record.bubble then record.bubble:Destroy() end
  for _,motor in ipairs(record.motors) do if motor.Parent then motor.Transform=CFrame.identity end end
 end
 table.insert(connections,effect.OnClientEvent:Connect(function(userId,id,started,phase,position)
  local target=Players:GetPlayerByUserId(userId)
  local model=target and target.Character
  local root=model and model:FindFirstChild("HumanoidRootPart")
  local camera=workspace.CurrentCamera
  if not root or not camera or (root.Position-camera.CFrame.Position).Magnitude>180 then return end
  local move=Abilities.Moves[id]
  if not move then return end
  if phase=="Impact" then
   ring(position,move.Range,Color3.fromRGB(204,145,83))
   if (root.Position-camera.CFrame.Position).Magnitude<65 then audio:PlayCue("OreHit") end
   if poses[target] and id=="JumpAttack" then poses[target].started=workspace:GetServerTimeNow()-move.Duration*.55 end
   return
  end
  if poses[target] then release(poses[target]) end
  local motors={}
  for _,item in ipairs(model:GetDescendants()) do if item:IsA("Motor6D") then table.insert(motors,item) end end
  poses[target]={id=id,model=model,started=started,motors=motors,rebirth=target:GetAttribute("Rebirths")}
  if (root.Position-camera.CFrame.Position).Magnitude<65 then audio:PlayCue("PinSwing") end
  if id=="Guard" then
   local bubble=Instance.new("Part")
   bubble.Shape,bubble.Size,bubble.CFrame=Enum.PartType.Ball,Vector3.new(6,7,6),root.CFrame
   bubble.Color,bubble.Material,bubble.Transparency=Color3.fromRGB(153,216,201),Enum.Material.ForceField,.65
   bubble.CanCollide,bubble.CanTouch,bubble.CanQuery,bubble.Massless=false,false,false,true
   bubble.Parent=model
   local weld=Instance.new("WeldConstraint"); weld.Part0,weld.Part1,weld.Parent=root,bubble,bubble
   poses[target].bubble=bubble
   Debris:AddItem(bubble,move.Duration)
  elseif id=="Dodge" then ring(root.Position,3,Color3.fromRGB(230,209,154)) end
 end))
 local elapsed=0
 table.insert(connections,Run.PreSimulation:Connect(function(dt)
  local now=workspace:GetServerTimeNow()
  for target,r in pairs(poses) do
   local hum=r.model:FindFirstChildOfClass("Humanoid")
   local move=Abilities.Moves[r.id]
   local t=(now-r.started)/move.Duration
   if t>=1 or target:GetAttribute("Rebirths")~=r.rebirth or target.Character~=r.model or not hum or hum.Health<=0 then release(r); poses[target]=nil; continue end
   local pose=Abilities.pose(r.id,t)
   for _,motor in ipairs(r.motors) do
    if not motor.Parent then continue end
    local name=motor.Name:lower():gsub(" ","")
    if name=="rootjoint" or name=="root" then motor.Transform=CFrame.Angles(pose.pitch,pose.yaw,0)
    elseif name:find("shoulder") then motor.Transform=CFrame.Angles(pose.arm,0,(name:find("left") and -1 or 1)*pose.arm*.25)
    elseif name:find("hip") then motor.Transform=CFrame.Angles(pose.leg*(name:find("left") and -1 or 1),0,0) end
   end
  end
  elapsed+=dt
  if elapsed<.1 then return end
  elapsed=0
  bar.Visible=holding() and not blocked()
  for slot,button in pairs(buttons) do
   local move=Abilities.Moves[player:GetAttribute("Ability"..slot)]
   local remaining=math.max(0,(player:GetAttribute("AbilityReady"..slot) or 0)-now)
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   local disabled=player:GetAttribute("InCookieObby")==true or player:GetAttribute("AdminFlying")==true or root and Obbys.inPit(root.Position.X,root.Position.Z,16)
   button.Text=slot.." • "..(move and move.Name or "Learn at mine")..(disabled and "\nUnavailable" or remaining>0 and string.format("\n%.1fs",remaining) or "")
   button.Interactable=move~=nil and remaining==0 and not disabled
   button.BackgroundTransparency=button.Interactable and .05 or .4
  end
 end))
 gui.Destroying:Connect(function()
  for _,c in ipairs(connections) do c:Disconnect() end
  for _,r in pairs(poses) do release(r) end
 end)
end
return Client
