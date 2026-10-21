local Physics=game:GetService("PhysicsService")
local Mine=require(game:GetService("ReplicatedStorage").CookieTycoon.MiningCatalog)
local Access={}
for tier=1,5 do
	local name="MineTier"..tier
	if not Physics:IsCollisionGroupRegistered(name) then Physics:RegisterCollisionGroup(name) end
end
for gate=2,5 do
	local group="MineGate"..gate
	if not Physics:IsCollisionGroupRegistered(group) then Physics:RegisterCollisionGroup(group) end
	for tier=1,5 do Physics:CollisionGroupSetCollidable(group,"MineTier"..tier,not Mine.allowed(tier,gate)) end
end
if not Physics:IsCollisionGroupRegistered("CookieCustomers") then Physics:RegisterCollisionGroup("CookieCustomers") end
for tier=1,5 do Physics:CollisionGroupSetCollidable("MineTier"..tier,"CookieCustomers",false) end
function Access.update(player,runtime,tier)
	local character=player.Character
	if not character or runtime.mineCharacter==character and runtime.mineTier==tier then return end
	if runtime.mineConnection then runtime.mineConnection:Disconnect() end
	runtime.mineCharacter,runtime.mineTier=character,tier
	local function assign(part)
		if part:IsA("BasePart") and (part.CollisionGroup=="Default" or part.CollisionGroup=="CookiePlayers" or part.CollisionGroup:match("^MineTier%d$")) then
			part.CollisionGroup="MineTier"..math.min(tier,#Mine.Zones)
		end
	end
	for _,part in ipairs(character:GetDescendants()) do assign(part) end
	runtime.mineConnection=character.DescendantAdded:Connect(assign)
	player:SetAttribute("MiningPinTier",tier)
end
return Access
