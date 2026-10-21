local Shared=game:GetService("ReplicatedStorage").CookieTycoon
local Catalog=require(Shared.PreviewCatalog)
local Assets,W=require(script.Parent.AssetLibrary),require(script.Parent.WorldWidgets)
local Preview={}
function Preview.start(remotes)
 local folder=Instance.new("Folder"); folder.Name,folder.Parent="PreviewModels",Shared
 local request=Instance.new("RemoteEvent"); request.Name,request.Parent="RequestPreview",remotes
 local limits={}
 game:GetService("Players").PlayerRemoving:Connect(function(p) limits[p]=nil end)
 local function publish(model,key)
  -- No tools, prompts, scripts, moving assemblies or live NPC tags in a preview.
  for _,item in ipairs(model:GetDescendants()) do
   if item:IsA("BasePart") then item.Anchored,item.CanCollide,item.CanTouch,item.CanQuery=true,false,false,false
   elseif item:IsA("LuaSourceContainer") or item:IsA("ProximityPrompt") or item:IsA("BillboardGui") or item:IsA("Humanoid") or item:IsA("JointInstance") or item:IsA("WeldConstraint") or item:IsA("ParticleEmitter") then item:Destroy() end
  end
  game:GetService("CollectionService"):RemoveTag(model,"CookieNPC")
  model.Name,model.Parent=key,folder
 end
 local function build(kind,id)
  if kind=="Cookie" or kind=="Glaze" or kind=="Sprinkles" then return Assets.cookie(id,nil,CFrame.identity,kind~="Cookie" and {[kind]=true} or nil)
  elseif kind=="Oven" then return require(script.Parent.OvenDesign).create(id,nil,CFrame.Angles(0,math.pi,0))
  elseif kind=="Pin" then return require(script.Parent.CookieTools).displayPin(id,nil,CFrame.identity)
  elseif kind=="Armor" then
   local model=require(script.Parent.BakerAvatar).create(function() end,"Customer",1)
   model:ScaleTo(1)
   model["Tailored Outfit"]:Destroy()
   for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.Color=Color3.fromRGB(107,95,82) end end
   require(script.Parent.CookieArmor).step({Character=model},{data={life={armor=id,enchants={Armor=0}}}})
   return model
  elseif kind=="Decoration" then
   local dummy=Instance.new("Model")
   local groups=require(script.Parent.BakeryDecorations).create({model=dummy,origin=Vector3.zero,direction=1,mirrorX=1})
   for key,model in pairs(groups) do publish(model,"Decoration:"..key) end
   dummy:Destroy()
   return nil
  elseif kind=="Prop" then return Assets.prop(id,nil,CFrame.identity)
  elseif kind=="Machine" and id=="FinishingOven" then return Assets.prop("Oven",nil,CFrame.identity) end
  local model=Instance.new("Model")
  if kind=="Machine" then
   local color=id=="Packager" and Color3.fromRGB(112,181,172) or Color3.fromRGB(193,145,92)
   for _,x in ipairs({-7.3,7.3}) do W.part(model,"Arch leg",Vector3.new(.8,8,.8),Vector3.new(x,4,0),color,Enum.Material.Metal) end
   W.part(model,"Processing arch",Vector3.new(15.5,1.3,1.3),Vector3.new(0,8.4,0),color,Enum.Material.Metal)
  elseif kind=="Pack" then
   local cards=require(Shared.CardCatalog)
   local tint=Color3.fromRGB(table.unpack(cards.Colors[cards.Rarities[id]]))
   W.part(model,"Foil wrapper",Vector3.new(3,4.6,.45),Vector3.zero,tint,Enum.Material.Metal)
   for _,y in ipairs({-2.3,2.3}) do
    W.part(model,"Sealed edge",Vector3.new(3.2,.25,.5),Vector3.new(0,y,0),Color3.fromRGB(192,170,117),Enum.Material.Metal)
    for x=-1.4,1.4,.2 do W.part(model,"Crimp",Vector3.new(.04,.24,.03),Vector3.new(x,y,-.27),Color3.fromRGB(124,108,79)) end
   end
   Assets.cookie(1,model,CFrame.new(0,.2,-.38)*CFrame.Angles(math.pi/2,0,0)):ScaleTo(.62)
  end
  return model
 end
 request.OnServerEvent:Connect(function(player,key)
  local kind,id=Catalog.resolve(key)
  if not kind or folder:FindFirstChild(key) then return end
  local now=os.clock()
  local bucket=limits[player] or {tokens=25,at=now}
  bucket.tokens=math.min(25,bucket.tokens+(now-bucket.at)*8); bucket.at=now; limits[player]=bucket
  if bucket.tokens<1 then return end
  bucket.tokens-=1
  local ok,model=pcall(build,kind,id)
  if ok and model then publish(model,key) elseif not ok then warn("Preview failed for "..key..": "..tostring(model)) end
 end)
end
return Preview
