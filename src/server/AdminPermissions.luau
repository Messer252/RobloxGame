-- Pure permissions. Roblox resolves configured account names on the server;
-- client attributes, display names, and remote arguments never grant a role.
local Permissions = {}
local Actions = { Kick = true, ReturnToSpawn = true, GiveWalletCash = true, GiveBankCash = true,
	SetInvisible = true, GoToPlayer = true, BringPlayer = true }

function Permissions.validId(value)
	return type(value) == "number" and value > 0 and value < 2^53 and value % 1 == 0
end

function Permissions.username(value)
	if type(value) ~= "string" then return nil end
	local name = value:match("^%s*(.-)%s*$"):gsub("^@", "")
	if #name < 1 or #name > 20 or not name:match("^[%w_]+$") then return nil end
	return string.lower(name)
end

function Permissions.resolve(config, lookup, ownerId)
	local admins, errors, seen = {}, {}, {}
	if config.AutoExperienceOwner and Permissions.validId(ownerId) then admins[ownerId] = true end
	for _, id in ipairs(config.UserIds or {}) do
		if Permissions.validId(id) then admins[id] = true else table.insert(errors, "Invalid configured admin user ID") end
	end
	for _, value in ipairs(config.Usernames or {}) do
		local name = Permissions.username(value)
		if not name then table.insert(errors, "Invalid configured admin username: " .. tostring(value))
		elseif not seen[name] then
			seen[name] = true
			local ok, id = pcall(lookup, name)
			if ok and Permissions.validId(id) then admins[id] = true
			else table.insert(errors, "Could not resolve admin @" .. name .. "; check the username and rejoin a restarted server") end
		end
	end
	return admins, errors
end

function Permissions.authorize(admins, actorId, action, targetId)
	if admins[actorId] ~= true then return false, "Admin access required." end
	if type(action) ~= "string" or not Actions[action] then return false, "Unknown admin action." end
	if type(targetId) ~= "number" or targetId % 1 ~= 0 or math.abs(targetId) >= 2^53 then return false, "Invalid target account." end
	if action == "Kick" and admins[targetId] == true then return false, "Admins cannot be kicked with these tools." end
	if action == "SetInvisible" and actorId ~= targetId then return false, "Invisibility changes your own character only." end
	return true
end

return Permissions
