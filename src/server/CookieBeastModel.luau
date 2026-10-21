local Avatar=require(script.Parent.BakerAvatar)
local Model={}
function Model.create(parent,boss,variant)
	local rig=Avatar.create(function() end,"Customer",1)
	rig["Tailored Outfit"]:Destroy()
	rig:ScaleTo(1)
	local dough=({Color3.fromRGB(190,133,73),Color3.fromRGB(129,82,53),Color3.fromRGB(177,185,132)})[(variant-1)%3+1]
	for _,p in ipairs(rig:GetChildren()) do
		if p:IsA("BasePart") then
			p.Color,p.Material=dough,Enum.Material.SmoothPlastic
			p.Transparency=(p.Name=="Head" or p.Name=="Torso" or p.Name=="HumanoidRootPart") and 1 or 0
		end
	end
	rig.Head:ClearAllChildren()
	local function piece(name,size,cf,color,shape)
		local p=Instance.new("Part")
		p.Name,p.Size,p.CFrame,p.Color=name,size,rig.Torso.CFrame*cf,color
		p.Shape,p.Material=shape or Enum.PartType.Block,Enum.Material.SmoothPlastic
		p.CanCollide,p.CanTouch,p.Massless=false,false,true
		p.Parent=rig
		local weld=Instance.new("WeldConstraint"); weld.Part0,weld.Part1,weld.Parent=rig.Torso,p,p
		return p
	end
	local chocolate=Color3.fromRGB(69,39,28)
	piece("Baked Cookie Body",Vector3.new(1.2,4.4,4.4),CFrame.new(0,.55,0)*CFrame.Angles(0,math.pi/2,0),dough,Enum.PartType.Cylinder)
	piece("Golden Cookie Rim",Vector3.new(1,4.65,4.65),CFrame.new(0,.55,.12)*CFrame.Angles(0,math.pi/2,0),dough:Lerp(chocolate,.2),Enum.PartType.Cylinder)
	for i=1,10 do
		local a=i*2.4
		piece("Chocolate Chunk",Vector3.new(.42,.34,.2),CFrame.new(math.cos(a)*1.65,.55+math.sin(a)*1.65,-.65)*CFrame.Angles(0,0,a),chocolate)
	end
	for _,side in ipairs({-1,1}) do
		piece("Icing Eye",Vector3.new(.6,.7,.2),CFrame.new(side*.72,1.15,-.72),Color3.fromRGB(255,230,178),Enum.PartType.Ball)
		piece("Chocolate Pupil",Vector3.new(.24,.32,.15),CFrame.new(side*.72,1.13,-.85),chocolate,Enum.PartType.Ball)
		piece("Angry Brow",Vector3.new(.8,.16,.22),CFrame.new(side*.72,1.63,-.72)*CFrame.Angles(0,0,side*.25),chocolate)
	end
	piece("Cookie Grin",Vector3.new(1.2,.23,.2),CFrame.new(0,.12,-.73),chocolate)
	if boss then
		for i=-2,2 do piece("Caramel Crown",Vector3.new(.33,.8+(2-math.abs(i))*.2,.5),CFrame.new(i*.6,2.6,0),Color3.fromRGB(225,175,76)) end
	end
	rig:ScaleTo(boss and 3 or 1)
	rig.Name=boss and "THE CRUMB COLOSSUS" or ({"Crumb Crawler","Cocoa Brute","Mint Muncher"})[(variant-1)%3+1]
	local hum=rig:FindFirstChildOfClass("Humanoid")
	hum.WalkSpeed,hum.AutoRotate,hum.BreakJointsOnDeath=boss and 10 or 12,true,false
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
	for _,p in ipairs(rig:GetDescendants()) do if p:IsA("BasePart") then
		p.Anchored=false
		p.CanCollide=p.Name=="Torso"
		if p.CanCollide then p.CustomPhysicalProperties=PhysicalProperties.new(.7,.15,0,100,100) end
		p.CanTouch=false
		p.CollisionGroup="CookieCustomers"
	end end
	rig.Parent=parent
	rig.HumanoidRootPart:SetNetworkOwner(nil)
	return rig,hum
end
return Model
