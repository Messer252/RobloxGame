local Players = game:GetService("Players")
local Avatar = {}
local skin = Color3.fromRGB(245, 205, 140)
local cream = Color3.fromRGB(255, 246, 225)
local mint = Color3.fromRGB(112, 164, 144)

local function fallback()
	-- A standard R6 joint hierarchy keeps the NPC usable if avatar assets are
	-- temporarily unavailable. The normal path below asks Roblox for an R6 rig.
	local model = Instance.new("Model")
	local function body(name, size, pos, color)
		local part = Instance.new("Part")
		part.Name, part.Size, part.Position, part.Color = name, size, pos, color
		part.CanCollide, part.TopSurface, part.BottomSurface = false, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		part.Parent = model
		return part
	end
	local root = body("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), cream)
	root.Transparency = 1
	local torso = body("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), cream)
	local head = body("Head", Vector3.new(2, 1, 1), Vector3.new(0, 4.5, 0), skin)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType, mesh.Scale, mesh.Parent = Enum.MeshType.Head, Vector3.new(1.25, 1.25, 1.25), head
	local function joint(name, a, b, c0, c1)
		local motor = Instance.new("Motor6D")
		motor.Name, motor.Part0, motor.Part1, motor.C0, motor.C1 = name, a, b, c0, c1
		motor.Parent = a
	end
	joint("RootJoint", root, torso, CFrame.new(), CFrame.new())
	joint("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
	for _, side in ipairs({ -1, 1 }) do
		local prefix = side == -1 and "Left" or "Right"
		local arm = body(prefix .. " Arm", Vector3.new(1, 2, 1), Vector3.new(side * 1.5, 3, 0), skin)
		local leg = body(prefix .. " Leg", Vector3.new(1, 2, 1), Vector3.new(side * 0.5, 1, 0), mint)
		joint(prefix .. " Shoulder", torso, arm, CFrame.new(side, 0.5, 0), CFrame.new(-side * 0.5, 0.5, 0))
		joint(prefix .. " Hip", torso, leg, CFrame.new(side * 0.5, -1, 0), CFrame.new(0, 1, 0))
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	model.PrimaryPart = root
	return model
end

function Avatar.decorate(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	local head, torso = model:FindFirstChild("Head"), model:FindFirstChild("Torso")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root or not head or not torso or not humanoid then return false end
	root.Anchored = true
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.WalkSpeed = 0
	for _, piece in ipairs(model:GetDescendants()) do if piece:IsA("BasePart") then piece.CanCollide = false end end
	if not head:FindFirstChildOfClass("Decal") then
		local face = Instance.new("Decal")
		face.Name, face.Texture, face.Face, face.Parent = "face", "rbxasset://textures/face.png", Enum.NormalId.Front, head
	end
	local function accessory(name, size, anchor, offset, color, shape)
		local part = Instance.new("Part")
		part.Name, part.Size, part.CFrame, part.Color = name, size, anchor.CFrame * offset, color
		part.CanCollide, part.Massless = false, true
		part.Shape = shape or Enum.PartType.Block
		part.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = anchor, part, part
		return part
	end
	accessory("Chef Hat Band", Vector3.new(0.25, 1.8, 1.8), head, CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.pi / 2), cream, Enum.PartType.Cylinder)
	for _, x in ipairs({ -0.45, 0, 0.45 }) do
		accessory("Chef Hat", Vector3.new(1, 0.8, 1), head, CFrame.new(x, 0.95, 0), cream, Enum.PartType.Ball)
	end
	local apron = accessory("Chef Apron", Vector3.new(1.5, 1.7, 0.08), torso, CFrame.new(0, -0.12, -0.55), mint)
	apron.Material = Enum.Material.Fabric
	accessory("Apron Pocket", Vector3.new(0.65, 0.4, 0.08), torso, CFrame.new(0, -0.45, -0.62), cream)
	model.PrimaryPart = root
	return true
end

function Avatar.create(onReady)
	local initial = fallback()
	Avatar.decorate(initial)
	onReady(initial)
	task.spawn(function()
		local description = Instance.new("HumanoidDescription")
		description.HeadColor, description.LeftArmColor, description.RightArmColor = skin, skin, skin
		description.TorsoColor, description.LeftLegColor, description.RightLegColor = cream, mint, mint
		local ok, model = pcall(function() return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R6) end)
		description:Destroy()
		if ok and model and Avatar.decorate(model) then onReady(model)
		elseif ok and model then model:Destroy() end
	end)
end

return Avatar
