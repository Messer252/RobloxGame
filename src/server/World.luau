local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Recipes = require(ReplicatedStorage.CookieTycoon.Recipes)
local Progression = require(ReplicatedStorage.CookieTycoon.Progression)
local Crafting = require(ReplicatedStorage.CookieTycoon.CookieCrafting)
local Assets = require(script.Parent.AssetLibrary)
local Presentation = require(script.Parent.Presentation)
local World = {}

local function color(rgb) return Color3.fromRGB(rgb[1], rgb[2], rgb[3]) end

local function part(name, size, position, tint, parent)
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.Position = position
	object.Color = tint
	object.Anchored = true
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function label(target, text, distance)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 58)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.MaxDistance = distance or 48
	gui.LightInfluence = 0
	gui.Parent = target
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundColor3 = Color3.fromRGB(64, 44, 39)
	textLabel.BackgroundTransparency = 0.12
	textLabel.Text = text
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 1
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = textLabel
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 7)
	padding.PaddingRight = UDim.new(0, 7)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = textLabel
	return textLabel
end

local function prompt(target, action, callback, objectText)
	local interaction = Instance.new("ProximityPrompt")
	interaction.ActionText = action
	interaction.ObjectText = objectText or target.Name
	interaction.HoldDuration = 0.2
	interaction.MaxActivationDistance = 12
	interaction.RequiresLineOfSight = false
	interaction.Parent = target
	interaction.Triggered:Connect(function(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - target.Position).Magnitude <= 16 then callback(player) end
	end)
	return interaction
end

local function position(plot, x, y, z)
	return plot.origin + Vector3.new(x, y, z * plot.direction)
end

local function prop(plot, name, x, z, y)
	local pivot = CFrame.new(position(plot, x, y or 0.5, z))
		* CFrame.Angles(0, plot.direction == 1 and 0 or math.pi, 0)
	return Assets.prop(name, plot.model, pivot)
end

function World.updateBank(plot, data)
	plot.bankText.Text = "Collect earnings\n$" .. Progression.format(data and data.bank or 0)
end

function World.refresh(plot, data, perks)
	plot.sign.Text = plot.owner and (plot.owner.DisplayName .. "'s Bakery") or "Unclaimed Bakery"
	plot.claimPrompt.Enabled = plot.owner == nil
	plot.claimSurface.Color = plot.owner and plot.theme or Color3.fromRGB(129, 219, 175)
	plot.claimSurface.Material = plot.owner and Enum.Material.SmoothPlastic or Enum.Material.Neon
	World.updateBank(plot, data)
	plot.upgradePrompt.Enabled = data ~= nil and data.level < Progression.MAX_OVEN_LEVEL
	plot.upgradeText.Text = not data and "Upgrade ovens" or data.level == Progression.MAX_OVEN_LEVEL and "Ovens MAXED!"
		or "Oven level " .. data.level .. "\n$" .. Progression.format(Progression.ovenCost(data))
	plot.shopPrompt.Enabled = data ~= nil
	plot.workshopPrompt.Enabled = data ~= nil
	local nextStation = data and plot.stations[data.unlocked + 1]
	plot.nextMarker.Adornee = nextStation and nextStation.purchaseModel or nil
	plot.nextMarker.Enabled = nextStation ~= nil
	for index, station in ipairs(plot.stations) do
		local unlocked = data ~= nil and index <= data.unlocked
		local rarity = Crafting.rarity(Recipes[index])
		local nextRecipe = data ~= nil and index == data.unlocked + 1
		station.purchase.Enabled = nextRecipe
		station.pad.Color = unlocked and plot.theme or nextRecipe and Color3.fromRGB(255, 214, 139) or Color3.fromRGB(132, 125, 120)
		station.pad.Material = nextRecipe and Enum.Material.Neon or Enum.Material.SmoothPlastic
		if station.steam then station.steam.Enabled = unlocked end
		station.text.Text = (nextRecipe and "NEXT • " or index .. ". ") .. Recipes[index].Name .. "\n" .. rarity.Name .. " x" .. rarity.Multiplier
			.. (unlocked and " • $" .. Progression.format(Progression.recipeValue(data, index, perks)) .. " / cookie" or "\nUnlock $" .. Progression.format(Recipes[index].Cost))
		station.text.TextColor3 = unlocked and color(rarity.Color) or Color3.fromRGB(210, 210, 210)
		station.oven.Color = unlocked and color(rarity.Color) or Color3.fromRGB(90, 96, 107)
		station.window.Color = unlocked and Color3.fromRGB(246, 151, 61) or Color3.fromRGB(48, 59, 66)
		station.window.Material = unlocked and Enum.Material.Neon or Enum.Material.Glass
	end
end

function World.create(onClaim, onAction, onShop, onWorkshop)
	Presentation.lighting()
	local world = Instance.new("Folder")
	world.Name = "CookieTycoonWorld"
	world.Parent = workspace
	local plots = {}
	local meadow = part("Meadow", Vector3.new(410, 1, 590), Vector3.new(0, -1, 0), Color3.fromRGB(111, 166, 111), world)
	meadow.Material = Enum.Material.Grass
	Assets.texture(meadow, "MeadowGrass")
	for segment = -6, 6 do
		Assets.prop("PathSegment", world, CFrame.new(0, 0, segment * 40))
	end
	Assets.prop("SpawnPlaza", world, CFrame.new(0, 0.2, 0))
	for _, x in ipairs({ -191, 191 }) do
		for _, z in ipairs({ -225, -85, 85, 225 }) do
			Assets.prop("CookieTree", world, CFrame.new(x, 0, z))
		end
	end
	for _, x in ipairs({ -10, 10 }) do
		for _, z in ipairs({ -220, -70, 70, 220 }) do
			Assets.prop("Lamppost", world, CFrame.new(x, 0.15, z))
		end
	end
	Presentation.world(world)
	local sculpture = Assets.cookie(1, world, CFrame.new(0, 7.6, 19) * CFrame.Angles(math.rad(75), 0, 0))
	sculpture.Name = "Cookie Corner Monument"
	sculpture:ScaleTo(2.9)
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 1, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = world
	label(spawn, "COOKIE CORNER\nClaim a bakery! Your progress follows you.", 95)
	for slot = 1, 4 do
		local model = Instance.new("Model")
		model.Name = "Bakery" .. slot
		model.Parent = world
		local plot = {
			model = model, stations = {}, owner = nil, visualCursor = 0,
			origin = Vector3.new(slot % 2 == 0 and 98 or -98, 0, slot <= 2 and -144 or 144),
			direction = slot <= 2 and 1 or -1,
		}
		local marker = Instance.new("Highlight")
		marker.Name = "Next Recipe"
		marker.DepthMode = Enum.HighlightDepthMode.Occluded
		marker.FillColor = Color3.fromRGB(255, 211, 129)
		marker.FillTransparency = 0.85
		marker.OutlineColor = Color3.fromRGB(255, 228, 168)
		marker.Enabled = false
		marker.Parent = model
		plot.nextMarker = marker
		table.insert(plots, plot)
		prop(plot, "BakeryFloor", 0, 0, 0)
		prop(plot, "BakeryShell", 0, 0, 0)
		prop(plot, "BakeryAwning", 0, 113)
		local counter = prop(plot, "PrepCounter", 0, -116)
		local worktop = counter:FindFirstChild("Texture_CounterMarble")
		label(worktop, "Cookie Workshop\nRarities & toppings", 65)
		plot.workshopPrompt = prompt(worktop, "Open workshop", function(player) onWorkshop(player, plot) end, "Cookie Workshop")
		prop(plot, "IngredientBins", -24, -116)
		prop(plot, "DoughMixer", 14, -116)
		prop(plot, "CoolingRack", 28, -116)
		prop(plot, "Planter", -75, 102)
		prop(plot, "Planter", 75, 102)
		prop(plot, "WoodenFence", -64, 120)
		prop(plot, "WoodenFence", 64, 120)
		local sign = prop(plot, "BakerySign", 0, 120)
		plot.sign = label(Assets.anchor(sign), "Unclaimed Bakery", 100)
		local claim = prop(plot, "ClaimPad", -63, 109)
		plot.claimSurface = claim:FindFirstChild("Claim Surface")
		plot.claimPrompt = prompt(Assets.anchor(claim), "Claim free bakery", function(player) onClaim(player, plot) end, "Cookie Bakery")
		label(Assets.anchor(claim), "Claim bakery", 65)
		local collect = prop(plot, "CollectionRegister", -21, 109)
		plot.bankText = label(Assets.anchor(collect), "Collect earnings\n$0", 65)
		prompt(Assets.anchor(collect), "Collect cash", function(player) onAction(player, "Collect", nil, plot) end, "Bakery Register")
		local upgrade = prop(plot, "UpgradeConsole", 21, 109)
		plot.upgradeText = label(Assets.anchor(upgrade), "Upgrade ovens", 65)
		plot.upgradePrompt = prompt(Assets.anchor(upgrade), "Upgrade speed", function(player) onAction(player, "UpgradeOven", nil, plot) end, "Oven Upgrades")
		local shop = prop(plot, "RebirthPedestal", 63, 109)
		label(Assets.anchor(shop), "Golden Chips\nRebirth & permanent upgrades", 65)
		plot.shopPrompt = prompt(Assets.anchor(shop), "Open bakery menu", function(player) onShop(player, plot) end, "Golden Chip Shop")
		for index, recipe in ipairs(Recipes) do
			local column = (index - 1) % 6
			local row = math.floor((index - 1) / 6)
			local x, z = -60 + column * 24, -100 + row * 40
			local ovenModel = prop(plot, "Oven", x, z)
			local oven = ovenModel:FindFirstChild("RecipeBadge")
			prop(plot, "Conveyor", x, z + 19)
			local buyModel = prop(plot, "ClaimPad", x, z + 29, 1.4)
			buyModel.Name = "Unlock " .. recipe.Name
			buyModel:ScaleTo(0.7)
			local buy = buyModel:FindFirstChild("Claim Surface")
			buy.Color = color(recipe.Color)
			local station = {
				oven = oven, window = ovenModel:FindFirstChild("Window"), x = x, z = z,
				text = label(oven, recipe.Name), pad = buy, purchaseModel = buyModel, steam = Presentation.oven(ovenModel),
			}
			station.purchase = prompt(buy, "Unlock recipe", function(player) onAction(player, "BuyRecipe", index, plot) end, recipe.Name)
			table.insert(plot.stations, station)
		end
		Presentation.plot(plot, slot)
		World.refresh(plot, nil)
	end
	return plots
end

function World.animate(plot, data, perks)
	-- Show at most four detailed cookies per visual batch. Income includes every oven.
	-- Keeping animations independent of oven speed bounds replicated part creation.
	for _ = 1, math.min(4, data.unlocked) do
		plot.visualCursor = plot.visualCursor % data.unlocked + 1
		local index = plot.visualCursor
		local station = plot.stations[index]
		local start = position(plot, station.x, 2.1, station.z + 9)
		local flags = data.modifiers[tostring(index)]
		local model = Assets.cookie(index, plot.model, CFrame.new(start), flags)
		local rarity = Crafting.rarity(Recipes[index])
		local value = Progression.recipeValue(data, index, perks)
		model:SetAttribute("CashValue", value)
		local toppingCount = 0
		for _, key in ipairs(Crafting.ModifierOrder) do if flags and flags[key] then toppingCount += 1 end end
		local badge = label(model.PrimaryPart, rarity.Name .. " • $" .. Progression.format(value)
			.. "\n" .. (toppingCount > 0 and toppingCount .. " topping upgrades" or Recipes[index].Name), 28)
		badge.TextColor3 = color(rarity.Color)
		badge.Parent.Size = UDim2.fromOffset(165, 44)
		badge.Parent.StudsOffset = Vector3.new(0, 1.7, 0)
		for _, object in ipairs(model:GetDescendants()) do
			if not object:IsA("BasePart") then continue end
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
			TweenService:Create(object, TweenInfo.new(1.3, Enum.EasingStyle.Linear), {
				Position = object.Position + Vector3.new(0, 0, 17 * plot.direction),
			}):Play()
		end
		Debris:AddItem(model, 1.4)
	end
end

return World
