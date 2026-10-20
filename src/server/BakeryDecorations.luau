local W,Assets=require(script.Parent.WorldWidgets),require(script.Parent.AssetLibrary)
local Shared=game:GetService("ReplicatedStorage").CookieTycoon
local Polish,B=require(Shared.BakeryPolish),require(Shared.BakeryBlueprint)
local Decor={}
function Decor.create(plot)
	local groups={}
	for _,key in ipairs(Polish.DecorationOrder) do
		local model=Instance.new("Model")
		model.Name,model.Parent=key.." Decoration",plot.model
		groups[key]=model
	end
	if plot.shell then plot.shell:Destroy() end
	for _,object in ipairs(plot.model:GetChildren()) do
		if object.Name=="Window Frame" or object.Name=="Pastel Window" or object.Name=="Window Mullion" or object.Name=="Planter" then object:Destroy() end
		if object.Name:find("String") or object.Name=="Light Cable" or object.Name=="Warm String Bulb" then object:Destroy() end
	end
	local plaster,wood,gold=Color3.fromRGB(184,170,147),Color3.fromRGB(107,76,53),Color3.fromRGB(179,142,78)
	local cream=Color3.fromRGB(193,179,151)
	local function p(key,name,size,x,y,z,tint,material,collide)
		local part=W.part(groups[key],name,size,W.position(plot,x,y,z),tint or wood,material or Enum.Material.Wood)
		part.Reflectance,part.CanCollide=0,collide~=false
		return part
	end
	local function trim(key,name,size,x,y,z,tint,material)
		return p(key,name,size,x,y,z,tint,material,false)
	end
	-- Dimensions share a single footprint with the floor and upgrade-pad planner.
	p("Walls","Back Sill",Vector3.new(B.Width,5,1.5),0,3,B.BackZ,plaster,Enum.Material.Brick)
	p("Walls","Back Lintel",Vector3.new(B.Width,5,1.5),0,16,B.BackZ,plaster,Enum.Material.Brick)
	for _,x in ipairs({-73.5,-42,-14,14,42,73.5}) do
		p("Walls","Window Pier",Vector3.new(math.abs(x)==73.5 and 17 or 10,8,1.5),x,9.5,B.BackZ,plaster,Enum.Material.Brick)
	end
	p("Walls","Garden Wall",Vector3.new(1.5,18,B.Depth),-B.WallX,9.5,0,plaster,Enum.Material.Brick)
	p("Walls","Road Wall",Vector3.new(1.5,18,205),B.WallX,9.5,-18.5,plaster,Enum.Material.Brick)
	p("Walls","Entrance End",Vector3.new(1.5,18,20),B.WallX,9.5,112,plaster,Enum.Material.Brick)
	p("Walls","Door Lintel",Vector3.new(1.5,5,18),B.WallX,16,93,plaster,Enum.Material.Brick)
	for _,x in ipairs({-81,81}) do
		trim("Walls","Oak Cornice",Vector3.new(1.8,.6,244),x,18.5,0,wood)
		if x<0 then trim("Walls","Oak Skirting",Vector3.new(.3,.7,242),x+.85,.9,0,wood) end
	end
	for _,x in ipairs(B.Windows) do
		for _,side in ipairs({-9.2,9.2}) do p("Windows","Fitted Window Jamb",Vector3.new(.55,8,1.9),x+side,9.5,B.BackZ,wood) end
		for _,y in ipairs({5.6,13.4}) do p("Windows","Fitted Window Rail",Vector3.new(19,.55,1.9),x,y,B.BackZ,wood) end
		local glass=p("Windows","Inset Window Pane",Vector3.new(17.8,7.4,.18),x,9.5,B.BackZ,Color3.fromRGB(129,170,174),Enum.Material.Glass)
		glass.Transparency=.68
		trim("Windows","Window Mullion",Vector3.new(.2,7.4,.3),x,9.5,B.BackZ+.2,cream)
		trim("Windows","Deep Window Sill",Vector3.new(19,.4,2.5),x,5.5,B.BackZ+.35,wood)
	end
	-- One leaf rotates around the same jamb axis as its visible hinge barrels.
	local leaf=Instance.new("Model")
	leaf.Name,leaf.Parent="Fitted Hinged Door",groups.Door
	local hinge=W.position(plot,81,.5,B.DoorStart+.7)
	leaf.WorldPivot=CFrame.new(hinge)
	for _,z in ipairs({85,101}) do p("Door","Door Jamb",Vector3.new(1.8,13,.7),81,7,z,wood) end
	p("Door","Door Frame Header",Vector3.new(1.8,.7,16.8),81,13.5,93,wood)
	local glass=p("Door","Door Glass",Vector3.new(.2,11.4,14.1),81,7,93,Color3.fromRGB(133,174,173),Enum.Material.Glass)
	glass.Transparency,glass.Parent=.7,leaf
	for _,z in ipairs({85.7,100.3}) do local rail=p("Door","Door Stile",Vector3.new(.45,12,.45),81,7,z,wood); rail.Parent=leaf end
	for _,y in ipairs({1,13}) do local rail=p("Door","Door Cross Rail",Vector3.new(.45,.5,15),81,y,93,wood); rail.Parent=leaf end
	local handle=p("Door","Brass Door Pull",Vector3.new(.3,1.8,.3),80.5,7,98.5,gold,Enum.Material.Metal)
	handle.Parent=leaf
	for _,y in ipairs({3,11}) do p("Door","Fixed Door Hinge",Vector3.new(.7,.85,.7),81,y,85.7,gold,Enum.Material.Metal) end
	local pivot,opened,busy=Instance.new("CFrameValue"),false,false
	pivot.Value,pivot.Parent=CFrame.new(hinge),groups.Door
	pivot.Changed:Connect(function(value) leaf:PivotTo(value) end)
	W.prompt(handle,"Open / close door",0,function()
		if busy then return end
		busy,opened=true,not opened
		local target=CFrame.new(hinge)*CFrame.Angles(0,opened and math.rad(95)*(plot.mirrorX or 1)*plot.direction or 0,0)
		game:GetService("TweenService"):Create(pivot,TweenInfo.new(.4),{Value=target}):Play()
		task.delay(.45,function() busy=false end)
	end)
	for _,side in ipairs({-1,1}) do
		local roof=p("Roof","Fitted Roof Wing",Vector3.new(61,.7,247),side*51,23,0,wood,Enum.Material.WoodPlanks)
		roof.CFrame*=CFrame.Angles(0,0,-side*(plot.mirrorX or 1)*.14)
		trim("Roof","Skylight Curb",Vector3.new(.7,.8,247),side*21,27,0,gold,Enum.Material.Metal)
	end
	local skylight=p("Roof","Recessed Skylight",Vector3.new(41,.25,243),0,27.3,0,Color3.fromRGB(142,178,181),Enum.Material.Glass)
	skylight.Transparency=.7
	for _,z in ipairs({-120,-60,0,60,120}) do trim("Roof","Skylight Crossbar",Vector3.new(43,.6,.7),0,27.3,z,wood) end
	for _,x in ipairs({-48,0,48}) do for _,z in ipairs({-75,5,80}) do
		trim("Lights","Pendant Cable",Vector3.new(.07,4,.07),x,22,z,wood)
		local shade=trim("Lights","Copper Pendant Shade",Vector3.new(3,.45,3),x,19.9,z,gold,Enum.Material.Metal)
		local bulb=trim("Lights","Soft Pendant Bulb",Vector3.new(1.1,.25,1.1),x,19.6,z,Color3.fromRGB(229,190,125),Enum.Material.Neon)
		local light=Instance.new("PointLight")
		light.Color,light.Range,light.Brightness,light.Parent=Color3.fromRGB(255,215,155),24,.4,bulb
		shade.CanQuery=false
	end end
	-- The production floor and road-side entrance stay clear; amenities occupy
	-- the 30-stud garden/cafe strip outside the leftmost conveyor lane.
	for _,z in ipairs({-88,15,78}) do Assets.prop("CookieTree",groups.Trees,CFrame.new(W.position(plot,-74,.5,z))):ScaleTo(.5) end
	for _,z in ipairs({-110,105}) do Assets.prop("Planter",groups.Plants,CFrame.new(W.position(plot,-64,.5,z))):ScaleTo(.65) end
	p("Floor","Continuous Oak Floor",Vector3.new(160,.08,240),0,.63,0,Color3.fromRGB(139,112,84),Enum.Material.WoodPlanks,false)
	for row=0,19 do trim("Floor","Oak Floor Joint",Vector3.new(159,.015,.045),0,.68,-114+row*12,Color3.fromRGB(102,82,62)) end
	local plaque=trim("Signs","Fitted Bakery Plaque",Vector3.new(.3,2.5,14),80,16.5,93,gold)
	W.label(plaque,"FRESHLY BAKED",22)
	for _,z in ipairs({-16,55}) do
		p("Benches","Cafe Seat",Vector3.new(14,.5,4),-65,2.4,z,wood)
		p("Benches","Cafe Back",Vector3.new(14,2.2,.5),-65,3.5,z+1.8,wood)
		for _,x in ipairs({-70,-60}) do p("Benches","Bench Leg",Vector3.new(.65,1.7,3),x,1.35,z,wood) end
	end
	local bowl=p("Fountain","Slate Fountain Basin",Vector3.new(.8,11,11),-66,1.1,-58,Color3.fromRGB(122,136,132),Enum.Material.Slate)
	bowl.Shape,bowl.CFrame=Enum.PartType.Cylinder,bowl.CFrame*CFrame.Angles(0,0,math.pi/2)
	local water=trim("Fountain","Fountain Water",Vector3.new(.15,9.5,9.5),-66,1.6,-58,Color3.fromRGB(80,149,159),Enum.Material.Glass)
	water.Shape,water.CFrame,water.Transparency=Enum.PartType.Cylinder,water.CFrame*CFrame.Angles(0,0,math.pi/2),.35
	Assets.cookie(1,groups.Fountain,CFrame.new(W.position(plot,-66,3.3,-58))):ScaleTo(.9)
	p("Display","Display Cabinet Base",Vector3.new(13,2.5,5),-61,1.8,-105,wood)
	local case=p("Display","Fitted Glass Display",Vector3.new(13,3,5),-61,4.5,-105,Color3.fromRGB(153,184,181),Enum.Material.Glass)
	case.Transparency=.8
	for i=1,4 do Assets.cookie(i,groups.Display,CFrame.new(W.position(plot,-67+i*2.5,3.5,-105))):ScaleTo(.4) end
	for _,z in ipairs({-32,38,102}) do
		p("FlowerBeds","Garden Border Box",Vector3.new(4,.7,16),-77,.9,z,wood)
		for i=1,5 do local flower=trim("FlowerBeds","Garden Flower",Vector3.new(.7,.6,.7),-77,1.7,z-7+i*2.5,Color3.fromHSV(i/8,.4,.7)); flower.Shape=Enum.PartType.Ball end
	end
	for _,z in ipairs({-32,38,102}) do Assets.prop("WoodenFence",groups.Fence,CFrame.new(W.position(plot,-79,.5,z))):ScaleTo(.6) end
	return groups
end
function Decor.refresh(plot,groups)
	for key,model in pairs(groups) do model.Parent=plot.data and plot.data.life.decorations[key] and plot.model or nil end
end
return Decor
