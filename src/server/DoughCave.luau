local Shared=game:GetService("ReplicatedStorage").CookieTycoon
local W=require(script.Parent.WorldWidgets)
local Mine,Life=require(Shared.MiningCatalog),require(Shared.BakeryLife)
local Cave={}
local function rgb(color) return Color3.fromRGB(table.unpack(color)) end
function Cave.create(parent)
	local stone=workspace.Terrain:GetMaterialColor(Enum.Material.Rock)
	local wood=Color3.fromRGB(111,84,59)
	local function part(name,size,position,color,material)
		return W.part(parent,name,size,position,color or stone,material or Enum.Material.Rock)
	end
	part("Cavern Bedrock",Vector3.new(136,1,150),Vector3.new(-316,0,108))
	part("Entrance Stone Trail",Vector3.new(34,.5,22),Vector3.new(-235,.2,108),stone,Enum.Material.Ground)
	-- Local lining also keeps the cave usable while terrain chunks stream in.
	part("Cavern Back",Vector3.new(5,25,150),Vector3.new(-385,12,108))
	part("Cavern Roof Lining",Vector3.new(136,3,150),Vector3.new(-316,24,108))
	for _,z in ipairs({32,184}) do part("Cavern Side",Vector3.new(136,25,5),Vector3.new(-316,12,z)) end
	for _,z in ipairs({63,153}) do part("Mossy Entrance Face",Vector3.new(5,25,62),Vector3.new(-248,12,z)) end
	part("Stone Entrance Arch",Vector3.new(6,5,28),Vector3.new(-248,22,108))
	for _,z in ipairs({94,122}) do part("Entrance Timber",Vector3.new(2,18,2),Vector3.new(-243,9,z),wood,Enum.Material.Wood) end
	part("Entrance Timber Lintel",Vector3.new(2,2,30),Vector3.new(-243,18,108),wood,Enum.Material.Wood)
	for tier,zone in ipairs(Mine.Zones) do
		local color=rgb(zone.Color)
		if tier>1 then
			for _,z in ipairs({66,150}) do part("Cavern Partition",Vector3.new(3,23,62),Vector3.new(zone.GateX,11.5,z)) end
			part("Gallery Arch",Vector3.new(3,4,22),Vector3.new(zone.GateX,21,108))
			local gate=part("Rolling Pin Seal",Vector3.new(1.5,19,22),Vector3.new(zone.GateX,10,108),color,Enum.Material.Glass)
			gate.Transparency,gate.CanTouch,gate.CollisionGroup=.5,false,"MineGate"..tier
			gate:SetAttribute("RequiredPin",tier)
			game:GetService("CollectionService"):AddTag(gate,"MineGate")
			local label=W.label(gate,zone.Name.."\n"..Life.PinNames[tier].." pin required",28)
			label.Parent.StudsOffset,label.Parent.Size=Vector3.new(0,3,0),UDim2.fromOffset(200,48)
		end
		local sign=part(zone.Name.." Sign",Vector3.new(20,2.8,.3),Vector3.new(zone.X,14,41.5),wood,Enum.Material.Wood)
		local label=W.label(sign,zone.Name.." • "..Life.PinNames[tier],32)
		label.Parent.StudsOffset=Vector3.zero
		for _,z in ipairs({44,172}) do
			local lantern=part("Gallery Lantern",Vector3.new(1.1,1.7,1.1),Vector3.new(zone.X,12,z),Color3.fromRGB(228,185,119),Enum.Material.Neon)
			lantern.CanCollide=false
			local light=Instance.new("PointLight")
			light.Color,light.Brightness,light.Range,light.Parent=Color3.fromRGB(244,205,151),.85,32,lantern
			local brace=part("Timber Support",Vector3.new(1.2,20,1.2),Vector3.new(zone.X,10,z),wood,Enum.Material.Wood)
			brace.CanCollide=false
		end
		-- Rock ribs share the valley's material/color and leave the tunnel clear.
		for _,z in ipairs({37,179}) do
			for n=-1,1 do
				local rib=part("Natural Rock Rib",Vector3.new(7,18+n*2,6),Vector3.new(zone.X+n*7,10,z),stone:Lerp(Color3.fromRGB(95,109,98),.12))
				rib.Shape, rib.CanCollide=Enum.PartType.Ball,false
			end
		end
	end
end
function Cave.health(node)
	local gui=node.label.Parent
	gui.StudsOffsetWorldSpace,gui.StudsOffset,gui.AlwaysOnTop=Vector3.new(0,5.3,0),Vector3.zero,true
	gui.Size,gui.MaxDistance=UDim2.fromOffset(200,66),28
	node.label.Size,node.label.BackgroundTransparency,node.label.TextSize=UDim2.new(1,0,0,44),.2,12
	local track=Instance.new("Frame")
	track.Position,track.Size,track.BackgroundColor3,track.BorderSizePixel,track.Parent=UDim2.fromOffset(8,48),UDim2.new(1,-16,0,9),Color3.fromRGB(44,42,40),0,gui
	local bar=Instance.new("Frame")
	bar.Size,bar.BorderSizePixel,bar.Parent=UDim2.fromScale(1,1),0,track
	for _,element in ipairs({track,bar}) do local corner=Instance.new("UICorner"); corner.CornerRadius,corner.Parent=UDim.new(1,0),element end
	node.bar=bar
end
function Cave.refreshLabel(node)
	local ore=Mine.Ores[node.oreId]
	node.label.Text=ore.Name.." • "..ore.Rarity.."\n"..math.ceil(node.hp).."/"..node.maximum.." HP • "..node.reward.." dough"
	node.bar.Size=UDim2.fromScale(node.hp/node.maximum,1)
end
function Cave.roll(node,roll)
	node.oreId=Mine.roll(node.zone,roll)
	local ore=Mine.Ores[node.oreId]
	node.maximum,node.hp,node.reward,node.respawn=ore.HP,ore.HP,ore.Dough,ore.Respawn
	node.part.Color,node.part.Transparency,node.part.CanCollide=rgb(ore.Color),0,true
	node.part:SetAttribute("OreRarity",ore.Rarity)
	node.part:SetAttribute("RequiredPin",node.zone)
	node.bar.BackgroundColor3=rgb(Mine.Rarities[ore.Rarity])
	for index,piece in ipairs(node.chips) do
		piece.Transparency=0
		piece.Color=index<=3 and rgb(ore.Color):Lerp(Color3.fromRGB(94,100,101),.18) or rgb(Mine.Rarities[ore.Rarity])
		piece.Material=index<=3 and Enum.Material.Rock or Enum.Material.Glass
	end
	node.label.Parent.Enabled=true
	Cave.refreshLabel(node)
end
function Cave.ores(parent)
	local nodes,random={},Random.new()
	for index,point in ipairs(Mine.positions()) do
		local ore=W.part(parent,"Dough Ore",Vector3.new(6,4.6,6),Vector3.new(point.x,2.8,point.z),Color3.fromRGB(160,142,116),Enum.Material.Rock)
		ore.Shape=Enum.PartType.Ball
		ore:SetAttribute("DoughOre",true)
		local node={part=ore,zone=point.zone,chips={},ready=0}
		node.label=W.label(ore,"",28)
		Cave.health(node)
		for facet=1,7 do
			local angle=facet*2.4
			local piece=Instance.new(facet<=3 and "WedgePart" or "Part")
			piece.Name,piece.Size="Ore Facet",facet<=3 and Vector3.new(3.7,4,3.7) or Vector3.new(.65,1.5,.65)
			piece.CFrame=CFrame.new(ore.Position+Vector3.new(math.cos(angle)*2.2,facet<=3 and 0 or 1.7,math.sin(angle)*2.2))*CFrame.Angles(.2,angle,.25)
			piece.Anchored,piece.CanCollide,piece.CanTouch,piece.CanQuery,piece.Parent=true,false,false,false,parent
			table.insert(node.chips,piece)
		end
		ore:SetAttribute("OreNodeId",index)
		Cave.roll(node,random:NextNumber())
		table.insert(nodes,node)
	end
	return nodes
end
return Cave
