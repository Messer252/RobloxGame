local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Layout = require(ReplicatedStorage.CookieTycoon.ConveyorLayout)
local Conveyor = {}
pcall(function() PhysicsService:RegisterCollisionGroup("CookieBodies") end)
PhysicsService:CollisionGroupSetCollidable("CookieBodies", "CookieBodies", false)

local function part(parent, name, size, frame, tint)
	local object = Instance.new("Part")
	object.Name, object.Size, object.CFrame, object.Color = name, size, frame, tint
	object.Anchored = true
	object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function line(parent, name, a, b, width, tint)
	local object = part(parent, name, Vector3.new(width, 0.06, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), tint)
	object.CanCollide, object.CanTouch, object.CanQuery = false, false, false
	return object
end

local function text(target, value)
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(600, 200)
	surface.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(63, 43, 31)
	label.Text = value
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = surface
end

function Conveyor.create(plot, position)
	plot.beltSurfaces = {}
	local model = Instance.new("Model")
	model.Name = "Merging Cookie Conveyors"
	model.Parent = plot.model
	for _, segment in ipairs(Layout.segments()) do
		local a = position(plot, segment.ax, Layout.BeltTop - 0.3, segment.az)
		local b = position(plot, segment.bx, Layout.BeltTop - 0.3, segment.bz)
		local direction = (b - a).Unit
		local length = (b - a).Magnitude
		local surface = part(model, "Moving Belt", Vector3.new(Layout.BeltWidth, 0.6, length + 0.15),
			CFrame.lookAt((a + b) / 2, b), Color3.fromRGB(53, 63, 69))
		surface.CustomPhysicalProperties = PhysicalProperties.new(1, 1, 0, 100, 1)
		surface:SetAttribute("Direction", direction)
		surface.AssemblyLinearVelocity = direction * Layout.CookieSpeed
		table.insert(plot.beltSurfaces, surface)
		local side = direction:Cross(Vector3.yAxis)
		if segment.rails then
			for _, sign in ipairs({ -1, 1 }) do
				local rail = part(model, "Safety Rail", Vector3.new(0.25, 0.65, length - 2 * (segment.railInset or 0.5)),
					surface.CFrame + side * sign * (Layout.BeltWidth / 2 + 0.1) + Vector3.new(0, 0.4, 0), Color3.fromRGB(151, 169, 173))
				rail.Material = Enum.Material.Metal
			end
		end
		for offset = 2, length - 1, 10 do
			local center = a + direction * offset + Vector3.new(0, 0.325, 0)
			local tip = center + direction * 0.8
			local back = center - direction * 0.5
			line(model, "Forward Arrow", tip, back + side * 0.5, 0.15, Color3.fromRGB(245, 204, 124))
			line(model, "Forward Arrow", tip, back - side * 0.5, 0.15, Color3.fromRGB(245, 204, 124))
		end
		for offset = 3, length - 1, 18 do
			local center = a + direction * offset
			part(model, "Conveyor Support", Vector3.new(4.8, Layout.BeltTop - 0.8, 0.7),
				CFrame.new(center.X, (Layout.BeltTop - 0.8) / 2 + 0.5, center.Z), Color3.fromRGB(112, 133, 142))
		end
	end
	local center = position(plot, 0, 0, Layout.BoxZ)
	local wood = Color3.fromRGB(182, 133, 80)
	local box = Instance.new("Model")
	box.Name = "Cookie Collection Box"
	box.Parent = plot.model
	part(box, "Box Bottom", Vector3.new(12, 0.6, 14), CFrame.new(center + Vector3.new(0, 0.6, 0)), wood)
	for _, x in ipairs({ -6, 6 }) do
		part(box, "Box Side", Vector3.new(0.5, 3, 14), CFrame.new(center + Vector3.new(x, 2.2, 0)), wood)
	end
	for _, z in ipairs({ -7, 7 }) do
		local face = part(box, "Box End", Vector3.new(12, 3, 0.5), CFrame.new(center + Vector3.new(0, 2.2, z)), wood)
		text(face, "COOKIE DELIVERY")
	end
	local catch = part(box, "Cookie Catcher", Vector3.new(11, 1.8, 12), CFrame.new(center + Vector3.new(0, 1.6, 0)), wood)
	catch.Transparency, catch.CanCollide = 1, false
	catch.Touched:Connect(function(hit)
		local cookie = hit:FindFirstAncestorOfClass("Model")
		if cookie and plot.visuals[cookie] and not cookie:GetAttribute("Collected") then
			cookie:SetAttribute("Collected", true)
			-- Economy credit is computed once on the server's production clock;
			-- physics delivery never grants extra money from a touch event.
			Debris:AddItem(cookie, 0.7)
		end
	end)
	plot.conveyor = model
end

function Conveyor.update(plot, interval)
	for _, surface in ipairs(plot.beltSurfaces) do
		surface.AssemblyLinearVelocity = surface:GetAttribute("Direction") * Layout.speed(interval)
	end
end

function Conveyor.makePhysical(model)
	local pivot = model:GetPivot()
	local hull = Instance.new("Part")
	hull.Name = "Cookie Collision Body"
	hull.Shape = Enum.PartType.Cylinder
	hull.Size = Vector3.new(0.52, 3.45, 3.45)
	hull.CFrame = pivot * CFrame.Angles(0, 0, math.pi / 2)
	hull.Transparency = 1
	hull.CanCollide, hull.CanTouch, hull.CanQuery = true, true, true
	hull.CollisionGroup = "CookieBodies"
	hull.CustomPhysicalProperties = PhysicalProperties.new(0.35, 0.8, 0, 100, 1)
	hull.Parent = model
	for _, piece in ipairs(model:GetDescendants()) do
		if piece:IsA("BasePart") and piece ~= hull then
			piece.CanCollide, piece.CanTouch, piece.Massless = false, false, true
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1, weld.Parent = hull, piece, hull
			piece.Anchored = false
		end
	end
	model.PrimaryPart = hull
	hull.Anchored = false
	hull:SetNetworkOwner(nil)
	Debris:AddItem(model, 30)
	return hull
end

return Conveyor
