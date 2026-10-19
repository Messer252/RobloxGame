local Players, Run = game:GetService("Players"), game:GetService("RunService")
local Flight = {}
local vectorType = "Vector3"
function Flight.start(remotes, isAdmin)
	local self = { active = {} }
	local input = Instance.new("RemoteEvent")
	input.Name, input.Parent = "AdminFlightInput", remotes
	function self:Stop(player)
		local state = self.active[player]
		self.active[player] = nil
		player:SetAttribute("AdminFlying", false)
		if not state then return end
		state.velocity:Destroy(); state.align:Destroy(); state.attachment:Destroy()
		if state.hum.Parent then state.hum.PlatformStand, state.hum.AutoRotate = false, state.autoRotate end
		if state.root.Parent then state.root.AssemblyLinearVelocity = Vector3.zero end
	end
	function self:Set(player, enabled)
		self:Stop(player)
		if not enabled or not isAdmin(player) then return end
		local character = player.Character
		local root, hum = character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
		if not root or not hum or hum.Health <= 0 then return end
		local attachment, velocity, align = Instance.new("Attachment"), Instance.new("LinearVelocity"), Instance.new("AlignOrientation")
		attachment.Parent = root
		velocity.Attachment0, velocity.MaxForce, velocity.RelativeTo, velocity.VectorVelocity, velocity.Parent = attachment, 1e7, Enum.ActuatorRelativeTo.World, Vector3.zero, root
		align.Mode, align.Attachment0, align.MaxTorque, align.Responsiveness, align.CFrame, align.Parent = Enum.OrientationAlignmentMode.OneAttachment, attachment, 1e7, 15, root.CFrame.Rotation, root
		self.active[player] = { character = character, root = root, hum = hum, autoRotate = hum.AutoRotate, velocity = velocity, align = align, attachment = attachment, last = os.clock(), direction = Vector3.zero }
		hum.PlatformStand, hum.AutoRotate = true, false
		player:SetAttribute("AdminFlying", true)
	end
	input.OnServerEvent:Connect(function(player, direction)
		local state = self.active[player]
		if not state or not isAdmin(player) or typeof(direction) ~= vectorType then return end
		local magnitude = direction.Magnitude
		if magnitude ~= magnitude or magnitude > 1.5 then return end
		if os.clock() - (state.lastInput or 0) < 0.035 then return end
		state.lastInput, state.last, state.direction = os.clock(), os.clock(), magnitude > 1 and direction.Unit or direction
	end)
	Run.Heartbeat:Connect(function()
		for player, state in pairs(self.active) do
			if not isAdmin(player) or player.Character ~= state.character or not state.root.Parent or state.hum.Health <= 0 then self:Stop(player)
			else
				local direction = os.clock() - state.last < 0.5 and state.direction or Vector3.zero
				state.velocity.VectorVelocity = direction * 55
				local flat = Vector3.new(direction.X, 0, direction.Z)
				if flat.Magnitude > 0.1 then state.align.CFrame = CFrame.lookAt(Vector3.zero, flat) end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player) self:Stop(player) end)
	return self
end
return Flight
