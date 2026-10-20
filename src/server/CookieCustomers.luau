local Avatar = require(script.Parent.BakerAvatar)
local W = require(script.Parent.WorldWidgets)
local Polish = require(game:GetService("ReplicatedStorage").CookieTycoon.BakeryPolish)
local Movement = require(script.Parent.NPCMovement)
local Customers = {}
function Customers.create(world,offer)
	local result,random={},Random.new()
	for index,name in ipairs({"Coco","Hazel","Maple","Chip","Ginger","Almond"}) do
		local customer={id=index,name=name,reservedUntil=0,traits=Polish.customer(random:NextNumber(),random:NextNumber(),random:NextNumber())}
		table.insert(result,customer)
		Avatar.create(function(model)
			model.Name,model.Parent="Customer "..name,world
			local hum,root=model:FindFirstChildOfClass("Humanoid"),model.HumanoidRootPart
			Avatar.place(model,Vector3.new(index%2==0 and -5 or 5,0,({-240,-150,-65,70,160,250})[index]),Vector3.zAxis)
			customer.model,customer.root,customer.humanoid=model,root,hum
			customer.label=W.label(root,name.." • "..customer.traits.Style.."\nCookie customer",32)
			local gui=customer.label.Parent
			gui.StudsOffset,gui.Size=Vector3.new(0,3.5,0),UDim2.fromOffset(174,40)
			customer.label.BackgroundTransparency=.28
			local corner=Instance.new("UICorner"); corner.CornerRadius,corner.Parent=UDim.new(0,8),customer.label
			W.prompt(root,"Offer held cookie",.2,function(player) offer(player,customer) end).ObjectText=name
			local function traits()
				model:SetAttribute("Personality",customer.traits.Style)
				model:SetAttribute("FavoriteCookie",customer.traits.Favorite)
				model:SetAttribute("Patience",customer.traits.Patience)
				customer.label.Text=name.." • "..customer.traits.Style.."\nCookie customer"
			end
			traits()
			Movement.start(customer,world,index,function()
				customer.traits=Polish.customer(random:NextNumber(),random:NextNumber(),random:NextNumber())
				traits()
			end)
		end,"Customer",index)
	end
	return result
end
return Customers
