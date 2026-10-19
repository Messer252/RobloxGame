-- Original accessories on standard Roblox rigs; no external catalog dependencies.
local Style = {}
function Style.apply(model, random)
	local skin = ({ Color3.fromRGB(239, 196, 154), Color3.fromRGB(161, 105, 72), Color3.fromRGB(111, 72, 52), Color3.fromRGB(250, 218, 183) })[random:NextInteger(1, 4)]
	local shirt, trousers = Color3.fromHSV(random:NextNumber(), 0.35, 0.7), Color3.fromHSV(random:NextNumber(), 0.18, 0.3)
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Color = part.Name:find("Leg") and trousers or (part.Name == "Torso" and shirt or skin)
		end
	end
	local function accessory(name, anchor, size, offset, color, shape, material)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color, p.Shape, p.Material = name, size, anchor.CFrame * offset, color, shape or Enum.PartType.Block, material or Enum.Material.SmoothPlastic
		p.CanCollide, p.CanTouch, p.Massless, p.Parent = false, false, true, model
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1, weld.Parent = anchor, p, p
		return p
	end
	local head, torso = model.Head, model.Torso
	local hair = Color3.fromHSV(random:NextNumber(0.04, 0.12), random:NextNumber(0.2, 0.7), random:NextNumber(0.15, 0.5))
	local kind = random:NextInteger(1, 4)
	local cap = accessory("Hair Cap", head, Vector3.new(2.05, 0.6, 1.08), CFrame.new(0, 0.45, 0), hair, Enum.PartType.Ball)
	if kind == 1 then
		accessory("Cap Brim", head, Vector3.new(2.1, 0.12, 0.8), CFrame.new(0, 0.55, -0.7), shirt)
		cap.Color = shirt
	elseif kind == 2 then
		for _, x in ipairs({ -0.8, 0.8 }) do accessory("Side Hair", head, Vector3.new(0.35, 1.2, 0.8), CFrame.new(x, 0, 0.1), hair, Enum.PartType.Ball) end
	elseif kind == 3 then
		for i = 1, 3 do accessory("Swept Hair", head, Vector3.new(0.6, 0.35, 0.5), CFrame.new((i - 2) * 0.5, 0.63, -0.35) * CFrame.Angles(0, 0, 0.2), hair, Enum.PartType.Ball) end
	end
	if random:NextNumber() < 0.45 then
		for _, x in ipairs({ -0.43, 0.43 }) do
			local glass = accessory("Glasses", head, Vector3.new(0.65, 0.35, 0.09), CFrame.new(x, 0.12, -0.57), Color3.fromRGB(54, 62, 68), nil, Enum.Material.Glass)
			glass.Transparency = 0.35
		end
		accessory("Glasses Bridge", head, Vector3.new(0.3, 0.06, 0.1), CFrame.new(0, 0.12, -0.6), Color3.fromRGB(68, 57, 46))
	end
	accessory("Jacket Collar", torso, Vector3.new(1.6, 0.18, 0.12), CFrame.new(0, 0.8, -0.55), Color3.fromRGB(239, 232, 213))
	for i = 1, 3 do accessory("Jacket Button", torso, Vector3.new(0.12, 0.12, 0.08), CFrame.new(0, 0.5 - i * 0.4, -0.56), Color3.fromRGB(217, 191, 119), Enum.PartType.Ball) end
	for _, side in ipairs({ "Left", "Right" }) do accessory("Shoe", model[side .. " Leg"], Vector3.new(1.04, 0.3, 1.15), CFrame.new(0, -0.85, -0.04), Color3.fromRGB(65, 48, 42)) end
	model:ScaleTo(random:NextNumber(0.9, 1.1))
end
return Style
