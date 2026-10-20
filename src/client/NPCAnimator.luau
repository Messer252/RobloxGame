-- Cosmetic animation stays on each client; the server owns walking physics.
local Collection = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Rules = require(game:GetService("ReplicatedStorage").CookieTycoon.NPCMotionRules)
local Animator = {}
function Animator.start(player)
	local rigs={}
	local function add(model)
		rigs[model]={phase=0,amount=0,yaw=0,joints={}}
	end
	Collection:GetInstanceAddedSignal("CookieNPC"):Connect(add)
	Collection:GetInstanceRemovedSignal("CookieNPC"):Connect(function(model) rigs[model]=nil end)
	for _,model in ipairs(Collection:GetTagged("CookieNPC")) do add(model) end
	RunService.PreSimulation:Connect(function(delta)
		local camera=workspace.CurrentCamera
		if not camera then return end
		local dt=math.min(delta,.1)
		local target=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		for model,rig in pairs(rigs) do
			local root,torso=model:FindFirstChild("HumanoidRootPart"),model:FindFirstChild("Torso")
			if not root or not torso or not model:IsDescendantOf(workspace) then continue end
			if (root.Position-camera.CFrame.Position).Magnitude>150 then continue end
			if not rig.joints.Neck or not rig.joints.Neck.Parent then
				for _,motor in ipairs(torso:GetChildren()) do if motor:IsA("Motor6D") then rig.joints[motor.Name]=motor end end
			end
			local velocity=root.AssemblyLinearVelocity
			local speed=Vector3.new(velocity.X,0,velocity.Z).Magnitude
			local walking=not root.Anchored and speed>.35
			rig.amount+=(math.clamp(walking and speed/Rules.Speed or 0,0,1)-rig.amount)*(1-math.exp(-dt*10))
			rig.phase+=dt*math.clamp(speed,0,12)*1.5
			local pose=Rules.pose(rig.phase,rig.amount)
			local values={ ["Left Hip"]=pose.leftHip,["Right Hip"]=pose.rightHip,["Left Shoulder"]=pose.leftShoulder,["Right Shoulder"]=pose.rightShoulder }
			for name,angle in pairs(values) do
				local motor=rig.joints[name]
				if motor then motor.Transform=CFrame.Angles(angle,0,0) end
			end
			local yaw=0
			if target and rig.amount<.15 and (target.Position-root.Position).Magnitude<12 then
				local point=root.CFrame:PointToObjectSpace(target.Position)
				if point.Z<0 then yaw=math.clamp(math.atan2(-point.X,-point.Z),-.55,.55) end
			end
			rig.yaw+=(yaw-rig.yaw)*(1-math.exp(-dt*5))
			local neck=rig.joints.Neck
			if neck then neck.Transform=CFrame.Angles(math.sin(os.clock()*1.5)*.018*(1-rig.amount),rig.yaw,0) end
		end
	end)
end
return Animator
