local Avatar = require(script.Parent.BakerAvatar)
local W = require(script.Parent.WorldWidgets)
local Polish = require(game:GetService("ReplicatedStorage").CookieTycoon.BakeryPolish)
local Style = require(script.Parent.CustomerStyle)
local Customers = {}
local physics = game:GetService("PhysicsService")
pcall(function() physics:RegisterCollisionGroup("CookieCustomers") end)
physics:CollisionGroupSetCollidable("CookieCustomers", "CookieCustomers", false)
function Customers.create(world, offer)
	local result, random = {}, Random.new()
	for index, name in ipairs({ "Coco", "Hazel", "Maple", "Chip", "Ginger", "Almond" }) do
		local customer = { id = index, name = name, reservedUntil = 0, traits = Polish.customer(random:NextNumber(), random:NextNumber(), random:NextNumber()) }
		table.insert(result, customer)
		Avatar.create(function(model)
			local previous = customer.model
			local position = customer.root and customer.root.Position or Vector3.new((index % 2 == 0 and -6 or 6), 3, (index - 3) * 90)
			model.Name, model.Parent = "Customer " .. name, world
			model:PivotTo(CFrame.new(position))
			local hum, root = model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("HumanoidRootPart")
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CollisionGroup = "CookieCustomers"
					part.CanCollide = part.Name == "Torso"
				end
			end
			for _, part in ipairs(model:GetChildren()) do if part.Name:find("Chef") or part.Name:find("Apron") then part:Destroy() end end
			hum.WalkSpeed = 8
			Style.apply(model, random)
			model:PivotTo(CFrame.new(position))
			model:SetAttribute("Personality", customer.traits.Style)
			model:SetAttribute("FavoriteCookie", customer.traits.Favorite)
			model:SetAttribute("Patience", customer.traits.Patience)
			root:SetNetworkOwner(nil)
			customer.model, customer.root, customer.humanoid = model, root, hum
			customer.joints = {}
			for _, joint in ipairs(model:GetDescendants()) do
				if joint:IsA("Motor6D") and (joint.Name:find("Hip") or joint.Name:find("Shoulder")) then table.insert(customer.joints, { joint = joint, original = joint.C0, sign = joint.Name:find("Left") and 1 or -1 }) end
			end
			customer.label = W.label(root, name .. " • " .. customer.traits.Style .. "\nCookie customer", 40)
			W.prompt(root, "Offer held cookie", 0.2, function(player) offer(player, customer) end)
			if previous then previous:Destroy() end
		end)
		task.spawn(function()
			local target, deadline
			while world.Parent do
				if customer.root and customer.model.Parent then
					if customer.reservedUntil > os.clock() then customer.humanoid:MoveTo(customer.root.Position)
					elseif customer.depart or not target or (customer.root.Position - target).Magnitude < 5 or os.clock() >= deadline then
						if customer.depart then
							customer.traits = Polish.customer(random:NextNumber(), random:NextNumber(), random:NextNumber())
							customer.model:SetAttribute("Personality", customer.traits.Style)
							customer.model:SetAttribute("FavoriteCookie", customer.traits.Favorite)
							customer.model:SetAttribute("Patience", customer.traits.Patience)
						end
						customer.depart = false
						target, deadline = Vector3.new((index % 2 == 0 and -6 or 6), 1, math.random(-480, 480)), os.clock() + 12
						customer.humanoid:MoveTo(target)
						customer.label.Text = name .. " • " .. customer.traits.Style .. "\nCookie customer"
					end
					local swing = customer.root.AssemblyLinearVelocity.Magnitude > 1 and math.sin(os.clock() * 8) * 0.3 or 0
					for _, entry in ipairs(customer.joints) do if entry.joint.Parent then entry.joint.C0 = entry.original * CFrame.Angles(swing * entry.sign, 0, 0) end end
				end
				task.wait(0.1)
			end
		end)
	end
	return result
end
return Customers
