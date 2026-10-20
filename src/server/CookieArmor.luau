local Town = require(game:GetService("ReplicatedStorage").CookieTycoon.TownCatalog)
local Armor = {}
function Armor.step(player, runtime)
	local character=player.Character
	local tier=runtime.data.life.armor
	if runtime.armorCharacter==character and runtime.armorTier==tier and (tier==0 or runtime.armorModel and runtime.armorModel.Parent==character) then return end
	if runtime.armorModel then runtime.armorModel:Destroy() end
	runtime.armorCharacter,runtime.armorTier=character,tier
	local definition=Town.Armor[tier]
	local torso=character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
	local head=character and character:FindFirstChild("Head")
	if not definition or not torso or not head then return end
	local model=Instance.new("Model")
	model.Name,model.Parent="CookieArmor",character
	runtime.armorModel=model
	local tint,trim=Color3.fromRGB(table.unpack(definition.Color)),Color3.fromRGB(table.unpack(definition.Trim))
	local material=({Enum.Material.WoodPlanks,Enum.Material.Slate,Enum.Material.Metal,Enum.Material.Metal,Enum.Material.Glass})[tier]
	local function piece(name,anchor,size,offset,color,surface,shape)
		local part=Instance.new("Part")
		part.Name,part.Size,part.CFrame,part.Color=name,size,anchor.CFrame*offset,color
		part.Material,part.Shape=surface or material,shape or Enum.PartType.Block
		part.CanCollide,part.CanTouch,part.CanQuery,part.Massless,part.Parent=false,false,false,true,model
		local weld=Instance.new("WeldConstraint")
		weld.Part0,weld.Part1,weld.Parent=anchor,part,part
		return part
	end
	local front=-torso.Size.Z/2-.12
	piece("Cookie Breastplate",torso,Vector3.new(torso.Size.X*.93,torso.Size.Y*.86,.22),CFrame.new(0,-.04,front),tint)
	piece("Armor Waist Band",torso,Vector3.new(torso.Size.X*.98,.17,.28),CFrame.new(0,-torso.Size.Y*.36,front),trim,Enum.Material.Metal)
	for i=1,6 do
		piece("Chocolate Rivet",torso,Vector3.new(.14,.14,.12),CFrame.new((i%2==0 and 1 or -1)*torso.Size.X*.35,(math.ceil(i/2)-2)*torso.Size.Y*.25,front-.17),trim,nil,Enum.PartType.Ball)
	end
	piece("Cookie Crest",torso,Vector3.new(.12,.55,.55),CFrame.new(0,.15,front-.16)*CFrame.Angles(0,math.pi/2,0),trim,tier==5 and Enum.Material.Neon or Enum.Material.Metal,Enum.PartType.Cylinder)
	for _,side in ipairs({"Left","Right"}) do
		local arm=character:FindFirstChild(side.."UpperArm") or character:FindFirstChild(side.." Arm")
		if arm then piece("Cookie Pauldron",arm,Vector3.new(arm.Size.X*1.1,arm.Size.Y*.4,arm.Size.Z*1.12),CFrame.new(0,arm.Size.Y*.28,0),tint) end
		local foot=character:FindFirstChild(side.."Foot") or character:FindFirstChild(side.." Leg")
		if foot then piece("Crust Greave",foot,Vector3.new(foot.Size.X*1.04,.25,foot.Size.Z*1.1),CFrame.new(0,-foot.Size.Y*.35,0),trim) end
	end
	piece("Cookie Helm Band",head,Vector3.new(.18,head.Size.X*1.04,head.Size.X*1.04),CFrame.new(0,head.Size.Y*.38,0)*CFrame.Angles(0,0,math.pi/2),trim,Enum.Material.Metal,Enum.PartType.Cylinder)
end
return Armor
