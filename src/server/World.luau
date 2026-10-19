local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Recipes = require(ReplicatedStorage.CookieTycoon.Recipes)
local Progression = require(ReplicatedStorage.CookieTycoon.Progression)
local Crafting = require(ReplicatedStorage.CookieTycoon.CookieCrafting)
local Layout = require(ReplicatedStorage.CookieTycoon.ConveyorLayout)
local Map = require(ReplicatedStorage.CookieTycoon.MapLayout)
local Conveyor = require(script.Parent.ConveyorWorld)
local Assets = require(script.Parent.AssetLibrary)
local Presentation = require(script.Parent.Presentation)
local StepPads = require(script.Parent.StepPads)
local Mirror = require(script.Parent.PlotMirror)
local Valley = require(script.Parent.ValleyWorld)
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
	gui.Size = UDim2.fromOffset(190, 46)
	gui.StudsOffset = Vector3.new(0, 3.1, 0)
	gui.MaxDistance = distance or 30
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
	interaction.HoldDuration = 0
	interaction.MaxActivationDistance = 12
	interaction.RequiresLineOfSight = false
	interaction.Parent = target
	interaction.Triggered:Connect(function(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 and (root.Position - target.Position).Magnitude <= 16 then callback(player) end
	end)
	return interaction
end

local function position(plot, x, y, z)
	return plot.origin + Vector3.new(x * (plot.mirrorX or 1), y, z * plot.direction)
end

local function frame(plot, x, y, z)
	return CFrame.new(position(plot, x, y, z))
		* CFrame.Angles(0, plot.direction == 1 and 0 or math.pi, 0)
end

local function prop(plot, name, x, z, y)
	return Assets.prop(name, plot.model, frame(plot, x, y or 0.5, z))
end

local function detail(plot, name, size, x, y, z, tint, parent)
	local object = part(name, size, position(plot, x, y, z), tint, parent or plot.model)
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	return object
end

local function clearCookies(plot)
	for model in pairs(plot.visuals) do
		model:Destroy()
		plot.visuals[model] = nil
	end
end


function World.updateBank(plot, data)
	plot.bankText.Text = "Collect $" .. Progression.format(data and data.bank or 0)
end

function World.refresh(plot, data, perks)
	local reset = plot.lastUnlocked and (not data or data.unlocked < plot.lastUnlocked)
	plot.data = data
	Conveyor.update(plot, data and Progression.interval(data, perks) or 3)
	plot.lastUnlocked = data and data.unlocked or 0
	if reset then clearCookies(plot) end
	plot.sign.Text = plot.owner and (plot.owner.DisplayName .. "'s Bakery") or "Unclaimed Bakery"
	plot.claimPrompt.Enabled = plot.owner == nil
	plot.claimPrompt.ObjectText = plot.owner and ("@" .. plot.owner.Name .. "'s bakery") or "Unclaimed bakery"
	plot.claimText.Text = plot.owner and ("@" .. plot.owner.Name .. "'s bakery") or "Claim bakery"
	plot.claimSurface.Color = plot.owner and plot.theme or Color3.fromRGB(129, 219, 175)
	plot.claimSurface.Material = plot.owner and Enum.Material.SmoothPlastic or Enum.Material.Neon
	World.updateBank(plot, data)
	plot.upgradePad.Color = data and data.level < Progression.MAX_OVEN_LEVEL and Color3.fromRGB(183, 160, 229) or Color3.fromRGB(118, 114, 121)
	plot.upgradeText.Text = not data and "Baking speed" or data.level == Progression.MAX_OVEN_LEVEL and "Speed MAX"
		or "Faster baking\n$" .. Progression.format(Progression.ovenCost(data))
	plot.shopPrompt.Enabled = data ~= nil
	plot.workshopPrompt.Enabled = data ~= nil
	for index, station in ipairs(plot.stations) do
		local unlocked = data ~= nil and index <= data.unlocked
		local nextRecipe = data ~= nil and index == data.unlocked + 1
		local visible = unlocked or nextRecipe or (not data and index == 1)
		station.model.Parent = visible and plot.model or nil
		station.purchaseModel.Parent = nextRecipe and station.model or nil
		local rarity = Crafting.rarity(Recipes[index])
		station.pad.Color = nextRecipe and Color3.fromRGB(255, 214, 139) or plot.theme
		station.text.Text = Recipes[index].Name .. "\n$" .. Progression.format(Recipes[index].Cost)
		station.ovenText.Parent.Enabled = unlocked or not data and index == 1
		station.ovenText.Text = Recipes[index].Name
		station.ovenText.TextColor3 = color(rarity.Color)
		if station.steam then station.steam.Enabled = unlocked end
		station.oven.Color = unlocked and color(rarity.Color) or Color3.fromRGB(106, 112, 119)
		station.window.Color = unlocked and Color3.fromRGB(246, 151, 61) or Color3.fromRGB(48, 59, 66)
		station.window.Material = unlocked and Enum.Material.Neon or Enum.Material.Glass
	end
	local nextStation = data and plot.stations[data.unlocked + 1]
	plot.nextMarker.Adornee = nextStation and nextStation.purchaseModel or nil
	plot.nextMarker.Enabled = nextStation ~= nil
end

function World.spawnPlayer(player, plot)
	if not plot or plot.owner ~= player then return end
	-- The disabled plot spawn is a marker, outside the random neutral spawn pool.
	-- CharacterAdded calls this scripted relocation after each plaza respawn.
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
	if not root or player.Character ~= character or plot.owner ~= player or not player.Parent then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local destination = position(plot, Layout.SpawnX, 4.1, Layout.SpawnZ)
	local nextOven = position(plot, Layout.PadX, 4.1, Layout.station(2).z)
	character:PivotTo(CFrame.lookAt(destination, nextOven))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

function World.releasePlayer(player, plot)
	if player.RespawnLocation == plot.spawn then player.RespawnLocation = nil end
	plot.stepPads:ResetOwner(player)
	clearCookies(plot)
end

function World.create(onClaim, onAction, onShop, onWorkshop)
	Presentation.lighting()
	local world = Instance.new("Folder")
	world.Name = "CookieTycoonWorld"
	world.Parent = workspace
	local stepPads = StepPads.new(world)
	local plots = {}
	-- Four ground slabs leave an actual opening for the swimmable terrain lake.
	for _, region in ipairs({ { -450, -355, -610, 610 }, { -215, 450, -610, 610 }, { -355, -215, -610, -425 }, { -355, -215, -315, 610 } }) do
		local meadow = part("Meadow", Vector3.new(region[2] - region[1], 1, region[4] - region[3]), Vector3.new((region[1] + region[2]) / 2, -1, (region[3] + region[4]) / 2), Color3.fromRGB(111, 166, 111), world)
		meadow.Material = Enum.Material.Grass
		Assets.texture(meadow, "MeadowGrass")
	end
	for segment = -14, 14 do
		Assets.prop("PathSegment", world, CFrame.new(0, 0, segment * 40))
	end
	Assets.prop("SpawnPlaza", world, CFrame.new(0, 0.2, 0))
	for _, x in ipairs({ -191, 191 }) do
		for _, z in ipairs({ -510, -360, -225, -85, 85, 225, 360, 510 }) do
			Assets.prop("CookieTree", world, CFrame.new(x, 0, z))
		end
	end
	for _, x in ipairs({ -10, 10 }) do
		for _, z in ipairs({ -510, -360, -220, -70, 70, 220, 360, 510 }) do
			Assets.prop("Lamppost", world, CFrame.new(x, 0.15, z))
		end
	end
	Presentation.world(world)
	Valley.create(world)
	local sculpture = Assets.cookie(1, world, CFrame.new(0, 7.6, 19) * CFrame.Angles(math.rad(75), 0, 0))
	sculpture.Name = "Cookie Corner Monument"
	sculpture:ScaleTo(2.9)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Plaza Spawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 1, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = world
	label(spawn, "COOKIE CORNER\nClaim a bakery to start", 80)
	for slot = 1, Map.PlayerCount do
		local placement = Map.plot(slot)
		local model = Instance.new("Model")
		model.Name = "Bakery" .. slot
		model.Parent = world
		local plot = {
			model = model, stations = {}, owner = nil, data = nil, visualCursor = 0, visuals = {}, stepPads = stepPads,
			origin = Vector3.new(placement.x, 0, placement.z),
			direction = placement.direction,
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
		Conveyor.create(plot, position)
		local counter = prop(plot, "PrepCounter", -49, -45)
		local worktop = counter:FindFirstChild("Texture_CounterMarble")
		label(worktop, "Cookie toppings", 35)
		plot.workshopPrompt = prompt(worktop, "Open toppings", function(player) onWorkshop(player, plot) end, "Cookie Workshop")
		prop(plot, "IngredientBins", 24, -115)
		prop(plot, "DoughMixer", 42, -115)
		prop(plot, "CoolingRack", 59, -115)
		prop(plot, "Planter", -75, 102)
		prop(plot, "Planter", 75, 102)
		prop(plot, "WoodenFence", -64, 120)
		prop(plot, "WoodenFence", 64, 120)
		local sign = prop(plot, "BakerySign", 0, 120)
		plot.sign = label(Assets.anchor(sign), "Unclaimed Bakery", 85)
		local claim = prop(plot, "ClaimPad", -63, 109)
		plot.claimSurface = claim:FindFirstChild("Claim Surface")
		plot.claimPrompt = prompt(Assets.anchor(claim), "Claim free bakery", function(player) onClaim(player, plot) end, "Cookie Bakery")
		plot.claimText = label(Assets.anchor(claim), "Claim bakery", 65)
		local personalSpawn = Instance.new("SpawnLocation")
		personalSpawn.Name = "Bakery Spawn"
		personalSpawn.Size = Vector3.new(5, 0.15, 5)
		personalSpawn.CFrame = frame(plot, Layout.SpawnX, 0.66, Layout.SpawnZ)
		personalSpawn.Anchored = true
		personalSpawn.Enabled = false
		personalSpawn.Transparency = 0.65
		personalSpawn.CanCollide = false
		personalSpawn.CanTouch = false
		personalSpawn.Duration = 0
		personalSpawn.Parent = model
		plot.spawn = personalSpawn
		local collect = prop(plot, "CollectionRegister", 23, 128)
		plot.bankText = label(Assets.anchor(collect), "Collect $0", 45)
		prompt(Assets.anchor(collect), "Collect cash", function(player) onAction(player, "Collect", nil, plot) end, "Bakery Register")
		local collectionPad = detail(plot, "Cash Collection Pad", Vector3.new(8, 0.15, 8), 23, 0.65, 120, Color3.fromRGB(233, 194, 92))
		label(collectionPad, "COLLECT CASH", 35)
		stepPads:Register(collectionPad, { Owner = function() return plot.owner end,
			Available = function(player) return plot.owner == player and plot.data ~= nil and plot.data.bank > 0 and plot.data.cash < Progression.MAX_CASH end,
			Activate = function(player) return onAction(player, "Collect", nil, plot) end })
		local upgrade = prop(plot, "UpgradeConsole", -60, Layout.FirstStationZ + 6)
		local speedPadModel = prop(plot, "ClaimPad", -60, Layout.FirstStationZ - 2)
		speedPadModel:ScaleTo(0.6)
		plot.upgradePad = speedPadModel:FindFirstChild("Claim Surface")
		plot.upgradeText = label(Assets.anchor(upgrade), "Baking speed", 35)
		stepPads:Register(plot.upgradePad, {
			Owner = function() return plot.owner end,
			Available = function(player)
				local data = plot.data
				return plot.owner == player and data ~= nil and data.level < Progression.MAX_OVEN_LEVEL and data.cash >= Progression.ovenCost(data)
			end,
			Activate = function(player) return onAction(player, "UpgradeOven", nil, plot) end,
		})
		local shop = prop(plot, "RebirthPedestal", 63, 109)
		label(Assets.anchor(shop), "Golden Chips", 40)
		plot.shopPrompt = prompt(Assets.anchor(shop), "Open upgrades", function(player) onShop(player, plot) end, "Golden Chip Shop")
		for index, recipe in ipairs(Recipes) do
			local geometry = Layout.station(index)
			local stationModel = Instance.new("Model")
			stationModel.Name = string.format("%02d %s", index, recipe.Name)
			stationModel.Parent = model
			local ovenModel = prop(plot, "Oven", geometry.x, geometry.z)
			ovenModel:ScaleTo(geometry.scale)
			-- Original oven doors face +Z; these ovens feed sideways onto the belt.
			ovenModel:PivotTo(CFrame.new(position(plot, geometry.x, 2.3, geometry.z)) * CFrame.Angles(0, math.pi / 2, 0))
			ovenModel.Parent = stationModel
			local bench = detail(plot, "Oven Counter", Vector3.new(6, 1.8, 6.6), geometry.x, 1.4, geometry.z, Color3.fromRGB(127, 100, 83), stationModel)
			bench.CanCollide = true
			local oven = ovenModel:FindFirstChild("RecipeBadge")
			local chute = detail(plot, "Cookie Feed Tray", Vector3.new(1.1, 0.2, 2.8), geometry.laneX - 5.05, Layout.BeltTop - 0.3, geometry.z,
				Color3.fromRGB(126, 143, 150), stationModel)
			chute.Material = Enum.Material.Metal
			local buyModel = prop(plot, "ClaimPad", geometry.padX, geometry.z, 0.55)
			buyModel.Name = "Buy " .. recipe.Name
			buyModel:ScaleTo(0.55)
			buyModel.Parent = stationModel
			local buy = buyModel:FindFirstChild("Claim Surface")
			local station = {
				model = stationModel, ovenModel = ovenModel, oven = oven, window = ovenModel:FindFirstChild("Window"),
				x = geometry.x, z = geometry.z, laneX = geometry.laneX, pad = buy, purchaseModel = buyModel,
				text = label(buy, recipe.Name, 26), ovenText = label(oven, recipe.Name, 24), steam = Presentation.oven(ovenModel),
			}
			station.ovenText.Parent.StudsOffset = Vector3.new(0, 1.5, 0)
			station.ovenText.Parent.Size = UDim2.fromOffset(160, 26)
			stepPads:Register(buy, {
				Owner = function() return plot.owner end,
				Available = function(player)
					local data = plot.data
					return plot.owner == player and data ~= nil and index == data.unlocked + 1 and data.cash >= recipe.Cost
				end,
				Activate = function(player) return onAction(player, "BuyRecipe", index, plot) end,
			})
			table.insert(plot.stations, station)
		end
		Presentation.plot(plot, slot)
		if placement.x > 0 then Mirror.apply(plot) end
		World.refresh(plot, nil)
	end
	return plots
end

function World.animate(plot, data, perks)
	local active = 0
	for model in pairs(plot.visuals) do
		if model.Parent then active += 1 else plot.visuals[model] = nil end
	end
	local count = math.min(2, data.unlocked, Layout.MaxVisualCookies - active)
	for number = 1, count do
		plot.visualCursor = plot.visualCursor % data.unlocked + 1
		local index = plot.visualCursor
		local station = plot.stations[index]
		local start = position(plot, station.laneX + (number - 1) * 0.25, Layout.CookieY, station.z)
		local model = Assets.cookie(index, plot.model, CFrame.new(start), data.modifiers[tostring(index)])
		model.Name = "Physical " .. model.Name
		plot.visuals[model] = true
		model:SetAttribute("CashValue", Progression.recipeValue(data, index, perks))
		local hull = Conveyor.makePhysical(model)
		Conveyor.track(plot, model, hull, math.floor((index - 1) / 10) + 1)
		if World.OnCookie then World.OnCookie(plot, model, index, data) end
		hull.AssemblyLinearVelocity = Vector3.new(0, 0, Layout.speed(Progression.interval(data, perks)) * plot.direction)
	end
end

return World
