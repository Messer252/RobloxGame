local Town = require(game:GetService("ReplicatedStorage").CookieTycoon.TownCatalog)
local Effects = require(script.Parent.GearEffects)
local Armor = {}
function Armor.step(player, runtime)
	local character=player.Character
	local tier=runtime.data.life.armor
	local enchant=runtime.data.life.enchants.Armor
	if runtime.armorCharacter==character and runtime.armorTier==tier and runtime.armorEnchant==enchant and (tier==0 or runtime.armorModel and runtime.armorModel.Parent==character) then return end
	if runtime.armorModel then runtime.armorModel:Destroy() end
	runtime.armorModel=nil
	runtime.armorCharacter,runtime.armorTier,runtime.armorEnchant=nil,tier,enchant
	local definition=Town.Armor[tier]
	local torso=character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
	local head=character and character:FindFirstChild("Head")
	if not definition then runtime.armorCharacter=character; return end
	if not torso or not head then return end
	runtime.armorCharacter=character
	local model=Instance.new("Model")
	model.Name,model.Parent="CookieArmor",character
	runtime.armorModel=model
	local tint,trim=Color3.fromRGB(table.unpack(definition.Color)),Color3.fromRGB(table.unpack(definition.Trim))
	local material=Enum.Material[definition.Material]
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
	local breastplate=piece("Cookie Breastplate",torso,Vector3.new(torso.Size.X*.93,torso.Size.Y*.86,.22),CFrame.new(0,-.04,front),tint)
	Effects.attach(breastplate,enchant)
	piece("Armor Waist Band",torso,Vector3.new(torso.Size.X*.98,.17,.28),CFrame.new(0,-torso.Size.Y*.36,front),trim,Enum.Material.Metal)
	for i=1,6 do
		piece("Chocolate Rivet",torso,Vector3.new(.14,.14,.12),CFrame.new((i%2==0 and 1 or -1)*torso.Size.X*.35,(math.ceil(i/2)-2)*torso.Size.Y*.25,front-.17),trim,nil,Enum.PartType.Ball)
	end
	piece("Cookie Crest",torso,Vector3.new(.12,.55,.55),CFrame.new(0,.15,front-.16)*CFrame.Angles(0,math.pi/2,0),trim,tier==5 and Enum.Material.Neon or Enum.Material.Metal,Enum.PartType.Cylinder)
	if tier>=6 then
		if tier==6 or tier==10 then
			for band=-1,1 do piece(tier==6 and "Candy Stripe" or "Moon Inlay",torso,Vector3.new(torso.Size.X*.82,.09,.08),CFrame.new(0,band*.38,front-.14)*CFrame.Angles(0,0,tier==6 and .22 or 0),trim) end
		elseif tier==7 or tier==12 then
			for row=-1,1 do for col=-1,1 do
				piece(tier==7 and "Honeycomb Scale" or "Dragon Scale",torso,Vector3.new(.32,.32,.08),CFrame.new(col*.5,row*.4,front-.16)*CFrame.Angles(0,0,math.pi/4),trim)
			end end
		else
			for side=-1,1,2 do
				piece(tier==9 and "Molten Chest Seam" or "Crystal Chest Rib",torso,Vector3.new(.12,torso.Size.Y*.74,.13),CFrame.new(side*.55,0,front-.15)*CFrame.Angles(0,0,side*.22),trim,tier==9 and Enum.Material.Neon or material)
			end
		end
	end
	for _,side in ipairs({"Left","Right"}) do
		local arm=character:FindFirstChild(side.."UpperArm") or character:FindFirstChild(side.." Arm")
		if arm then
			piece("Cookie Pauldron",arm,Vector3.new(arm.Size.X*1.1,arm.Size.Y*.4,arm.Size.Z*1.12),CFrame.new(0,arm.Size.Y*.28,0),tint)
			if tier>=8 then piece("Raised Shoulder Crest",arm,Vector3.new(.18,.5,arm.Size.Z*.75),CFrame.new(0,arm.Size.Y*.5,0)*CFrame.Angles(0,0,side=="Left" and -.35 or .35),trim) end
		end
		local foot=character:FindFirstChild(side.."Foot") or character:FindFirstChild(side.." Leg")
		if foot then piece("Crust Greave",foot,Vector3.new(foot.Size.X*1.04,.25,foot.Size.Z*1.1),CFrame.new(0,-foot.Size.Y*.35,0),trim) end
	end
	if tier==13 then
		for i=-2,2 do piece("Baker Crown Point",head,Vector3.new(.15,.35+(2-math.abs(i))*.12,.15),CFrame.new(i*.3,head.Size.Y*.65,-head.Size.Z*.46),trim,Enum.Material.Metal) end
	end
	piece("Cookie Helm Band",head,Vector3.new(.18,head.Size.X*1.04,head.Size.X*1.04),CFrame.new(0,head.Size.Y*.38,0)*CFrame.Angles(0,0,math.pi/2),trim,Enum.Material.Metal,Enum.PartType.Cylinder)
end
return Armor
