local Shared=game:GetService("ReplicatedStorage"):WaitForChild("CookieTycoon")
local Catalog=require(Shared.PreviewCatalog)
local Run=game:GetService("RunService")
local Preview={}
local records={}
local folder,remote
local function visible(object)
 local item=object
 while item do
  if item:IsA("GuiObject") and not item.Visible then return false end
  if item:IsA("ScrollingFrame") and (object.AbsolutePosition.Y+object.AbsoluteSize.Y<item.AbsolutePosition.Y or object.AbsolutePosition.Y>item.AbsolutePosition.Y+item.AbsoluteSize.Y) then return false end
  item=item.Parent
 end
 return true
end
function Preview.attach(button,key)
 if not Catalog.resolve(key) then return end
 button.AutomaticSize=Enum.AutomaticSize.Y
 button.Size=UDim2.new(button.Size.X.Scale,button.Size.X.Offset,0,110)
 button.TextXAlignment=Enum.TextXAlignment.Left
 button.TextSize=14
 local record=records[button]
 if record and record.key==key then return end
 if record then record.world:ClearAllChildren(); record.loaded=false; record.key=key; record.retry=0; record.status.Visible=true; return end
 local padding=Instance.new("UIPadding")
 padding.PaddingLeft,padding.PaddingRight,padding.PaddingTop,padding.PaddingBottom=UDim.new(0,110),UDim.new(0,12),UDim.new(0,12),UDim.new(0,12)
 padding.Parent=button
 -- Negative position offsets the text padding, keeping the model inside the card.
 local view=Instance.new("ViewportFrame")
 view.Name,view.Position,view.Size="ProductPreview",UDim2.fromOffset(-100,0),UDim2.fromOffset(88,86)
 view.BackgroundColor3,view.BorderSizePixel,view.ZIndex,view.Parent=Color3.fromRGB(46,35,30),0,button.ZIndex+1,button
 view.Ambient,view.LightColor,view.LightDirection=Color3.fromRGB(180,175,163),Color3.fromRGB(255,231,196),Vector3.new(-1,-1,-1)
 local corner=Instance.new("UICorner"); corner.CornerRadius,corner.Parent=UDim.new(0,10),view
 local camera=Instance.new("Camera"); camera.FieldOfView,camera.Parent=38,view; view.CurrentCamera=camera
 local world=Instance.new("WorldModel"); world.Parent=view
 local status=Instance.new("TextLabel")
 status.BackgroundTransparency,status.Size,status.Text,status.TextSize=1,UDim2.fromScale(1,1),"3D preview…",11
 status.TextColor3,status.ZIndex,status.Parent=Color3.fromRGB(219,202,173),view.ZIndex+1,view
 record={key=key,world=world,view=view,camera=camera,status=status,retry=0,angle=0}
 records[button]=record
 button.Destroying:Connect(function() records[button]=nil end)
end
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<1/20 then return end
 local step=elapsed; elapsed=0
 folder=folder or Shared:FindFirstChild("PreviewModels")
 local remotes=Shared:FindFirstChild("Remotes")
 remote=remote or remotes and remotes:FindFirstChild("RequestPreview")
 for button,r in pairs(records) do
  if not visible(button) then continue end
  if not r.loaded then
   local template=folder and folder:FindFirstChild(r.key)
   if template then
    local model=template:Clone(); model.Parent=r.world
    local cf,size=model:GetBoundingBox()
    r.center=cf.Position
    r.distance=math.max(size.Magnitude,.5)/(2*math.sin(math.rad(19)))*1.12
    r.loaded=true; r.status.Visible=false
   elseif remote and os.clock()>r.retry then remote:FireServer(r.key); r.retry=os.clock()+4 end
  end
  if r.loaded then
   r.angle+=step*.16
   local offset=Vector3.new(math.sin(r.angle+.4),.55,-math.cos(r.angle+.4)).Unit*r.distance
   r.camera.CFrame=CFrame.lookAt(r.center+offset,r.center)
  end
 end
end)
return Preview
