local Shared=game:GetService("ReplicatedStorage").CookieTycoon
local Catalog,Town=require(Shared.CardCatalog),require(Shared.TownCatalog)
local W,Avatar=require(script.Parent.WorldWidgets),require(script.Parent.BakerAvatar)
local Tools=require(script.Parent.CookieTools)
local TownWorld={}
function TownWorld.create(world,action)
	local folder=Instance.new("Folder")
	folder.Name,folder.Parent="Cookie Corner Market",world
	local cocoa,wood,gold=Color3.fromRGB(74,48,36),Color3.fromRGB(133,97,67),Color3.fromRGB(213,170,87)
	for _,path in ipairs(Town.Paths) do
		local dx,dz=path.x2-path.x1,path.z2-path.z1
		local length=math.sqrt(dx*dx+dz*dz)
		local a,b=Vector3.new(path.x1,.5,path.z1),Vector3.new(path.x2,.5,path.z2)
		local road=W.part(folder,"Fast Market Road",Vector3.new(Town.PathHalfWidth*2,.3,length+Town.PathHalfWidth*2),(a+b)/2,Color3.fromRGB(72,76,77),Enum.Material.Asphalt)
		road.CFrame=CFrame.lookAt((a+b)/2,b)
		for distance=12,length-8,20 do
			local stripe=W.part(folder,"Market Road Stripe",Vector3.new(.4,.04,6),a:Lerp(b,distance/length)+Vector3.new(0,.17,0),gold)
			stripe.CFrame=CFrame.lookAt(stripe.Position,stripe.Position+(b-a).Unit)
			stripe.CanCollide,stripe.CanTouch,stripe.CanQuery=false,false,false
		end
	end
	local spawnGuide=W.part(folder,"Spawn Market Guide",Vector3.new(.7,5,.7),Vector3.new(16,2.5,-30),wood,Enum.Material.Wood)
	W.label(spawnGuide,"PACKS & FORGE\nFollow this road to the market turn",55)
	local guide=W.part(folder,"Market Direction Sign",Vector3.new(1,6,1),Vector3.new(18,3,Town.PathZ-9),wood,Enum.Material.Wood)
	W.label(guide,"MARKET →\nPacks • Gear • Enchant",75)
	-- Low lighting marks the branch without crowding the plot entrances.
	for x=40,365,65 do
		local post=W.part(folder,"Market Path Lantern",Vector3.new(.6,3,.6),Vector3.new(x,1.5,Town.PathZ+9),wood,Enum.Material.Wood)
		local lamp=Instance.new("PointLight")
		lamp.Color,lamp.Range,lamp.Brightness,lamp.Parent=Color3.fromRGB(255,214,156),16,.4,post
	end
	local function pavilion(point,title,color)
		local center=Vector3.new(point.x,0,point.z)
		local floor=W.part(folder,title.." Foundation",Vector3.new(Town.MarketWidth,.5,Town.MarketDepth),center+Vector3.new(0,.4,0),Color3.fromRGB(136,133,119),Enum.Material.Slate)
		for _,x in ipairs({-20,20}) do for _,z in ipairs({-14,14}) do
			W.part(folder,"Market Timber Post",Vector3.new(.8,13,.8),center+Vector3.new(x,6.7,z),wood,Enum.Material.Wood)
		end end
		W.part(folder,title.." Roof",Vector3.new(45,.7,35),center+Vector3.new(0,13.5,0),color,Enum.Material.WoodPlanks)
		local counter=W.part(folder,title.." Counter",Vector3.new(27,3,5),center+Vector3.new(0,2,8),cocoa,Enum.Material.Wood)
		W.part(folder,"Counter Worktop",Vector3.new(28,.35,5.5),counter.Position+Vector3.new(0,1.7,0),wood,Enum.Material.WoodPlanks)
		local sign=W.part(folder,title.." Sign",Vector3.new(22,3,.5),center+Vector3.new(0,11.5,14.4),cocoa,Enum.Material.Wood)
		local name=W.label(sign,title,100)
		name.Parent.StudsOffset,name.Parent.Size=Vector3.new(0,1,0),UDim2.fromOffset(240,45)
		return center,counter,floor
	end
	local packCenter,packCounter=pavilion(Town.PackStand,"CRUMBKIN PACK HOUSE",Color3.fromRGB(70,112,103))
	W.prompt(packCounter,"Browse packs & claim daily crumbs",0,function(player) action(player,"OpenPackShop") end)
	for index,pack in ipairs(Catalog.Packs) do
		local rarity=Catalog.Rarities[index]
		local tint=Color3.fromRGB(table.unpack(Catalog.Colors[rarity]))
		local box=W.part(folder,pack.Name.." Display",Vector3.new(3.2,4,.8),packCenter+Vector3.new(-12+index*4,5.5,8),tint)
		local stripe=W.part(folder,"Pack Foil Stripe",Vector3.new(3.3,.3,.9),box.Position+Vector3.new(0,1.4,0),gold,Enum.Material.Metal)
		stripe.CanCollide=false
	end
	local smithCenter,smithCounter=pavilion(Town.Blacksmith,"CRUSTFORGE • ARMOR & PINS",Color3.fromRGB(106,82,71))
	W.prompt(smithCounter,"Gear & enchantments",0,function(player) action(player,"OpenBlacksmith") end)
	W.part(folder,"Forge Hearth",Vector3.new(8,4,7),smithCenter+Vector3.new(11,2.5,-7),Color3.fromRGB(83,82,80),Enum.Material.Brick)
	local coals=W.part(folder,"Warm Forge Coals",Vector3.new(5,.2,4),smithCenter+Vector3.new(11,4.6,-7),Color3.fromRGB(218,103,48),Enum.Material.Neon)
	local light=Instance.new("PointLight")
	light.Color,light.Range,light.Brightness,light.Parent=Color3.fromRGB(255,173,91),12,.35,coals
	W.part(folder,"Anvil Pedestal",Vector3.new(3,2.5,3),smithCenter+Vector3.new(-10,2,-5),wood,Enum.Material.Wood)
	W.part(folder,"Cookie Anvil",Vector3.new(5,1,2.5),smithCenter+Vector3.new(-10,3.7,-5),Color3.fromRGB(83,99,108),Enum.Material.Metal)
	W.part(folder,"Anvil Horn",Vector3.new(2.5,.55,1.5),smithCenter+Vector3.new(-13,4,-5),Color3.fromRGB(109,126,135),Enum.Material.Metal)
	for display,tier in ipairs({1,7,13}) do
		local armor=Town.Armor[tier]
		local base=smithCenter+Vector3.new(-20+display*10,0,-11)
		local plate=W.part(folder,armor.Name.." Display",Vector3.new(2.8,3,.4),base+Vector3.new(0,6,0),Color3.fromRGB(table.unpack(armor.Color)),Enum.Material.Metal)
		plate.CanCollide=false
		W.part(folder,"Armor Display Stand",Vector3.new(.3,5,.3),base+Vector3.new(0,3,0),wood,Enum.Material.Wood)
		Tools.displayPin(tier,folder,CFrame.new(base+Vector3.new(2,9,0)))
	end
	local function shopkeeper(role,name,center,actionName,promptText)
		Avatar.create(function(model)
			model.Name,model.Parent=name,folder
			Avatar.place(model,center+Vector3.new(0,0,1),Vector3.zAxis)
			W.prompt(model.HumanoidRootPart,promptText,0,function(player) action(player,actionName) end).ObjectText=name
			local label=W.label(model.Head,name,28)
			label.Parent.StudsOffset,label.Parent.Size=Vector3.new(0,2.2,0),UDim2.fromOffset(180,30)
			label.BackgroundTransparency=1
		end,role)
	end
	shopkeeper("Smith","Bruno Crustforge",smithCenter,"OpenBlacksmith","Gear & enchantments")
	shopkeeper("PackHost","Poppy Crumbkeeper",packCenter,"OpenPackShop","Packs & daily gift")
	local pickups={}
	for id,point in ipairs(Town.Pickups) do
		local crumb=W.part(folder,"Trail Star Crumb",Vector3.new(1.4,1.4,1.4),Vector3.new(point[1],2,point[3]),gold,Enum.Material.Metal)
		crumb.CFrame*=CFrame.Angles(0,.5,math.pi/4)
		crumb.CanCollide,crumb.CanTouch=false,false
		crumb:SetAttribute("CrumbPickupId",id)
		local prompt=W.prompt(crumb,"Gather "..Town.PickupCrumbs.." Star Crumbs",0,function(player) action(player,"TrailCrumb",id) end)
		prompt.Name="TrailCrumbPrompt"
		game:GetService("CollectionService"):AddTag(crumb,"TrailStarCrumb")
		pickups[id]=crumb
	end
	return {folder=folder,pickups=pickups}
end
return TownWorld
