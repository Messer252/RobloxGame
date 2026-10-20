-- A complete local R6 rig: predictable joints, no web request or mid-walk swaps.
local Style = require(script.Parent.CustomerStyle)
local Avatar = {}
function Avatar.create(onReady, role, variant)
	local model = Instance.new("Model")
	local function body(name, size, position)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position = name, size, position
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Material, p.CanCollide, p.CanTouch = Enum.Material.SmoothPlastic, false, false
		p.Parent = model
		return p
	end
	local root = body("HumanoidRootPart", Vector3.new(2,2,1), Vector3.new(0,3,0))
	root.Transparency, root.Anchored, root.RootPriority = 1, true, 127
	local torso = body("Torso", Vector3.new(2,2,1), Vector3.new(0,3,0))
	local head = body("Head", Vector3.new(2,1,1), Vector3.new(0,4.5,0))
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Scale, mesh.Parent = Enum.MeshType.Head, Vector3.new(1.25,1.25,1.25), head
	local face = Instance.new("Decal")
	face.Name, face.Texture, face.Face, face.Parent = "face", "rbxasset://textures/face.png", Enum.NormalId.Front, head
	local function joint(name, a, b, c0, c1)
		local motor = Instance.new("Motor6D")
		motor.Name, motor.Part0, motor.Part1, motor.C0, motor.C1, motor.Parent = name,a,b,c0,c1,a
	end
	joint("RootJoint",root,torso,CFrame.identity,CFrame.identity)
	joint("Neck",torso,head,CFrame.new(0,1,0),CFrame.new(0,-.5,0))
	for _, side in ipairs({-1,1}) do
		local prefix = side == -1 and "Left" or "Right"
		local arm = body(prefix.." Arm",Vector3.new(1,2,1),Vector3.new(side*1.5,3,0))
		local leg = body(prefix.." Leg",Vector3.new(1,2,1),Vector3.new(side*.5,1,0))
		joint(prefix.." Shoulder",torso,arm,CFrame.new(side,.5,0),CFrame.new(-side*.5,.5,0))
		joint(prefix.." Hip",torso,leg,CFrame.new(side*.5,-1,0),CFrame.new(0,1,0))
	end
	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType, hum.BreakJointsOnDeath, hum.RequiresNeck = Enum.HumanoidDisplayDistanceType.None, false, true
	hum.WalkSpeed, hum.Parent = 0,model
	model.PrimaryPart = root
	Style.apply(model, role or "Baker", variant or 1)
	model:SetAttribute("NPCFootOffset",3*model:GetScale())
	game:GetService("CollectionService"):AddTag(model,"CookieNPC")
	onReady(model)
	return model
end
-- Place feet on the actual floor instead of embedding shoes in the plaza/stall.
function Avatar.place(model, point, facing)
	local params = RaycastParams.new()
	params.FilterType,params.FilterDescendantsInstances,params.RespectCanCollide=Enum.RaycastFilterType.Exclude,{model},true
	local hit=workspace:Raycast(Vector3.new(point.X,point.Y+10,point.Z),Vector3.new(0,-20,0),params)
	local y=(hit and hit.Position.Y or point.Y)+(model:GetAttribute("NPCFootOffset") or 3)+.03
	local position=Vector3.new(point.X,y,point.Z)
	local direction=Vector3.new(facing.X,0,facing.Z)
	model:PivotTo(CFrame.lookAt(position,position+direction))
end
return Avatar
