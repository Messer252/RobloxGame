local Enchant=require(game:GetService("ReplicatedStorage").CookieTycoon.Enchantments)
local Effects={}
function Effects.attach(part,rank)
	local rarity=Enchant.Rarities[rank]
	if not rarity then return end
	local anchor=Instance.new("Attachment")
	anchor.Name,anchor.Parent="EnchantmentAura",part
	local emitter=Instance.new("ParticleEmitter")
	emitter.Name,emitter.Texture="Enchant "..rarity.Name,"rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color=ColorSequence.new(Color3.fromRGB(table.unpack(rarity.Color)))
	emitter.Rate,emitter.Lifetime,emitter.Speed=rarity.Rate,NumberRange.new(.45,.85),NumberRange.new(.4,1.2)
	emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.10+rank*.035),NumberSequenceKeypoint.new(.5,.16+rank*.04),NumberSequenceKeypoint.new(1,0)})
	emitter.Transparency,emitter.LightEmission=NumberSequence.new(.15,1),.35
	emitter.SpreadAngle,emitter.Rotation,emitter.RotSpeed=Vector2.new(180,180),NumberRange.new(0,360),NumberRange.new(-60,60)
	emitter.Parent=anchor
	if rank>=4 then
		local a,b=Instance.new("Attachment"),Instance.new("Attachment")
		a.Position,b.Position=Vector3.new(0,-.3,0),Vector3.new(0,.3,0)
		a.Parent,b.Parent=part,part
		local trail=Instance.new("Trail")
		trail.Attachment0,trail.Attachment1,trail.Lifetime=a,b,.12+rank*.025
		trail.Color,trail.Transparency,trail.LightEmission=emitter.Color,NumberSequence.new(.55,1),.25
		trail.MinLength,trail.Parent=.1,anchor
	end
end
return Effects
