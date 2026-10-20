local Players = game:GetService("Players")
local Config = require(script.Parent.AdminConfig)
local Permissions = require(script.Parent.AdminPermissions)
local Visibility = require(script.Parent.AdminVisibility)
local Admin = {}

function Admin.start(remotes, context)
	local actionRemote = Instance.new("RemoteEvent")
	actionRemote.Name, actionRemote.Parent = "AdminAction", remotes
	local resultRemote = Instance.new("RemoteEvent")
	resultRemote.Name, resultRemote.Parent = "AdminResult", remotes
	local ownerId = game.CreatorType == Enum.CreatorType.User and game.CreatorId or nil
	local admins = Permissions.resolve({ AutoExperienceOwner = Config.AutoExperienceOwner, UserIds = Config.UserIds }, function() return nil end, ownerId)
	local cooldowns = {}
	local visibility = Visibility.new()
	local flight = require(script.Parent.AdminFlight).start(remotes, function(player) return admins[player.UserId] == true end)
	local function mark(player) player:SetAttribute("IsAdmin", admins[player.UserId] == true) end
	Players.PlayerAdded:Connect(mark)
	Players.PlayerRemoving:Connect(function(player) cooldowns[player] = nil end)
	for _, player in ipairs(Players:GetPlayers()) do mark(player) end
	task.spawn(function()
		local resolved, errors = Permissions.resolve(Config, function(name) return Players:GetUserIdFromNameAsync(name) end, ownerId)
		admins = resolved
		for _, message in ipairs(errors) do warn("Cookie Corner admin setup: " .. message) end
		for _, player in ipairs(Players:GetPlayers()) do mark(player) end
	end)
	actionRemote.OnServerEvent:Connect(function(actor, action, targetId, argument)
		-- Rate-limit every caller before looking up a target, including non-admins.
		local now = os.clock()
		if now < (cooldowns[actor] or 0) then return end
		cooldowns[actor] = now + 1
		local permitted, message = Permissions.authorize(admins, actor.UserId, action, targetId)
		if not permitted then
			resultRemote:FireClient(actor, false, message)
			return
		end
		local target = Players:GetPlayerByUserId(targetId)
		if not target then
			resultRemote:FireClient(actor, false, "That player has left this server.")
			return
		end
		local resultMessage
		local grantLimits = { GiveWalletCash = Config.MaxCashGrant, GiveBankCash = Config.MaxCashGrant, GiveGoldenChips = Config.MaxGoldenChipGrant or 10000, GiveStarCrumbs = Config.MaxStarCrumbGrant or 100000 }
		if grantLimits[action] then
			local success, grantMessage = context.GrantCurrency(target, action, argument, grantLimits[action])
			if not success then
				resultRemote:FireClient(actor, false, grantMessage)
				return
			end
			resultMessage = "@" .. target.Name .. ": " .. grantMessage
		elseif action == "SetFlying" then
			if type(argument) ~= "boolean" then return end
			flight:Set(actor, argument)
			resultMessage = argument and "Flight enabled. WASD to steer, Space up, Ctrl/Q down; touch buttons also available." or "Flight disabled."
		elseif action == "SetInvisible" then
			if type(argument) ~= "boolean" then return end
			visibility:Set(actor, argument)
			resultMessage = argument and "You are invisible until you turn it off or leave." or "Your normal appearance is restored."
		elseif action == "Kick" then
			target:Kick("You were removed from this server by a Cookie Corner admin.")
			resultMessage = "Removed @" .. target.Name .. " from this server."
		else
			local character = target.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root or not humanoid or humanoid.Health <= 0 then
				resultRemote:FireClient(actor, false, "Wait for that player to respawn.")
				return
			end
			if action == "ReturnToSpawn" then
				context.ReturnToSpawn(target)
				resultMessage = "Returned @" .. target.Name .. " to spawn."
			else
				local adminCharacter = actor.Character
				local adminRoot = adminCharacter and adminCharacter:FindFirstChild("HumanoidRootPart")
				local adminHumanoid = adminCharacter and adminCharacter:FindFirstChildOfClass("Humanoid")
				if not adminRoot or not adminHumanoid or adminHumanoid.Health <= 0 then
					resultRemote:FireClient(actor, false, "Wait for your character to respawn.")
					return
				end
				local moving, movingRoot, destination = adminCharacter, adminRoot, root.CFrame
				if action == "BringPlayer" then moving, movingRoot, destination = character, root, adminRoot.CFrame end
				moving:PivotTo(destination * CFrame.new(5, 1, 0))
				movingRoot.AssemblyLinearVelocity, movingRoot.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
				resultMessage = action == "BringPlayer" and ("Brought @" .. target.Name .. " to you.") or ("Teleported to @" .. target.Name .. ".")
			end
		end
		print(string.format("[Cookie Corner Admin] @%s (%d): %s @%s (%d) %s", actor.Name, actor.UserId, action, target.Name, target.UserId,
			grantLimits[action] and tostring(argument) or ""))
		resultRemote:FireClient(actor, true, resultMessage)
	end)
end

return Admin
