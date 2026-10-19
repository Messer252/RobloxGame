local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Layout = require(ReplicatedStorage.CookieTycoon.ConveyorLayout)
local Routing = require(ReplicatedStorage.CookieTycoon.ConveyorRouting)
local Conveyor = {}
local paths = Routing.paths()
local boundaryRails = Routing.rails(paths)
local surfaces = Routing.surfaces(paths)
local activePlots = {}
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

local function decoration(object)
	object.CanCollide, object.CanTouch, object.CanQuery = false, false, false
	return object
end

local function belt(plot, parent, size, frame, direction)
	local surface = part(parent, "Moving Belt", size, frame, Color3.fromRGB(53, 63, 69))
	surface.CustomPhysicalProperties = PhysicalProperties.new(1, 1, 0, 100, 1)
	surface.CanTouch = false
	surface:SetAttribute("Direction", direction)
	surface.AssemblyLinearVelocity = direction * Layout.CookieSpeed
	table.insert(plot.beltSurfaces, surface)
	return surface
end

local function rail(parent, a, b, joints)
	local center = (a + b) / 2
	local frame = CFrame.lookAt(center, b)
	local wall = part(parent, "Smooth Outer Rail", Vector3.new(Layout.RailThickness, Layout.RailHeight, (b - a).Magnitude + 0.05), frame, Color3.fromRGB(151, 169, 173))
	wall.Material = Enum.Material.Metal
	wall.CanTouch = false
	-- Low friction and rounded joints let a cookie slide past boundary contact.
	wall.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0, 100, 1)
	for _, point in ipairs({ a, b }) do
		local key = string.format("%.3f/%.3f", point.X, point.Z)
		if joints[key] then continue end
		joints[key] = true
		local cap = part(parent, "Rounded Rail Joint", Vector3.new(Layout.RailHeight, Layout.RailThickness, Layout.RailThickness),
			CFrame.new(point) * CFrame.Angles(0, 0, math.pi / 2), wall.Color)
		cap.Shape, cap.Material, cap.CustomPhysicalProperties = Enum.PartType.Cylinder, wall.Material, wall.CustomPhysicalProperties
		cap.CanTouch = false
	end
	local trim = decoration(part(parent, "Rail Top Trim", Vector3.new(Layout.RailThickness + 0.08, 0.08, (b - a).Magnitude),
		frame + Vector3.new(0, Layout.RailHeight / 2, 0), Color3.fromRGB(199, 211, 211)))
	trim.Material = Enum.Material.Metal
end

function Conveyor.create(plot, position)
	plot.beltSurfaces = {}
	local model = Instance.new("Model")
	model.Name = "Merging Cookie Conveyors"
	model.Parent = plot.model
	plot.beltSpeed = Layout.CookieSpeed
	activePlots[plot] = true
	for _, section in ipairs(surfaces) do
		local center = position(plot, section.x, Layout.BeltTop - 0.3, section.z)
		local direction = Vector3.new(section.dx, 0, section.dz * plot.direction)
		if section.round then
			-- Flat infill closes both edges of every curve without a raised lip.
			local join = belt(plot, model, Vector3.new(0.6, section.width, section.width),
				CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2), direction)
			join.Shape = Enum.PartType.Cylinder
		else
			belt(plot, model, Vector3.new(section.width, 0.6, section.length), CFrame.lookAt(center, center + direction), direction)
		end
	end
	for _, path in ipairs(paths) do
		for distance = 4, path[#path].s - 1, 10 do
			local point = Routing.pointAt(path, distance)
			-- One set of arrows on the shared outlet, all derived from flow.
			if point.z >= Layout.MainStartZ and path ~= paths[2] then continue end
			local center = position(plot, point.x, Layout.BeltTop + 0.035, point.z)
			local direction = Vector3.new(point.dx, 0, point.dz * plot.direction)
			local side = direction:Cross(Vector3.yAxis)
			local tip = center + direction * 0.8
			local back = center - direction * 0.5
			line(model, "Forward Arrow", tip, back + side * 0.5, 0.15, Color3.fromRGB(245, 204, 124))
			line(model, "Forward Arrow", tip, back - side * 0.5, 0.15, Color3.fromRGB(245, 204, 124))
		end
		for distance = 8, path[#path].s - 2, 18 do
			local point = Routing.pointAt(path, distance)
			local center = position(plot, point.x, (Layout.BeltTop - 0.8) / 2, point.z)
			decoration(part(model, "Recessed Conveyor Support", Vector3.new(6.2, Layout.BeltTop - 0.8, 0.7),
				CFrame.new(center), Color3.fromRGB(112, 133, 142)))
		end
	end
	local joints = {}
	for _, edge in ipairs(boundaryRails) do
		local y = Layout.BeltTop + Layout.RailHeight / 2 - 0.1
		rail(model, position(plot, edge.a.x, y, edge.a.z), position(plot, edge.b.x, y, edge.b.z), joints)
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
	plot.beltSpeed = Layout.speed(interval)
	for _, surface in ipairs(plot.beltSurfaces) do
		surface.AssemblyLinearVelocity = surface:GetAttribute("Direction") * plot.beltSpeed
	end
end

function Conveyor.makePhysical(model)
	local pivot = model:GetPivot()
	local hull = Instance.new("Part")
	hull.Name = "Cookie Collision Body"
	hull.Shape = Enum.PartType.Cylinder
	hull.Size = Vector3.new(0.52, Layout.CookieRadius * 2, Layout.CookieRadius * 2)
	hull.CFrame = pivot * CFrame.Angles(0, 0, math.pi / 2)
	hull.Transparency = 1
	hull.CanCollide, hull.CanTouch, hull.CanQuery = true, true, true
	hull.CollisionGroup = "CookieBodies"
	hull.CustomPhysicalProperties = PhysicalProperties.new(0.35, 0.35, 0, 10, 1)
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
	local attachment = Instance.new("Attachment")
	attachment.Parent = hull
	local upright = Instance.new("AlignOrientation")
	upright.Name, upright.Mode = "Keep Cookie Flat", Enum.OrientationAlignmentMode.OneAttachment
	upright.Attachment0, upright.CFrame = attachment, hull.CFrame.Rotation
	upright.MaxTorque, upright.MaxAngularVelocity, upright.Responsiveness = 10000, 20, 25
	upright.Parent = hull
	Debris:AddItem(model, 30)
	return hull
end

function Conveyor.track(plot, model, hull, lane)
	plot.visuals[model] = { hull = hull, lane = lane, progress = 0 }
end

-- Physical assemblies remain collidable and unanchored. Gentle server-side
-- steering supplies reliable drive through merges instead of relying on two
-- competing contact velocities to choose the cookie's next direction.
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.05 then return end
	local alpha = 1 - math.exp(-12 * math.min(elapsed, 0.2))
	elapsed = 0
	for plot in pairs(activePlots) do
		if not plot.model.Parent then
			activePlots[plot] = nil
			continue
		end
		for model, state in pairs(plot.visuals) do
			if not model.Parent then
				plot.visuals[model] = nil
				continue
			end
			if type(state) ~= "table" or model:GetAttribute("Collected") then continue end
			local hull = state.hull
			if not hull.Parent then
				model:Destroy()
				plot.visuals[model] = nil
				continue
			end
			local p = hull.Position - plot.origin
			if p.Y < Layout.BeltTop - 0.1 or p.Y > Layout.BeltTop + 1.1 then continue end
			local drive = Routing.drive(paths[state.lane], p.X, p.Z * plot.direction, state.progress, plot.beltSpeed)
			if drive then
				state.progress = drive.s
				local current = hull.AssemblyLinearVelocity
				local target = Vector3.new(drive.vx, current.Y, drive.vz * plot.direction)
				hull.AssemblyLinearVelocity = current:Lerp(target, alpha)
			end
		end
	end
end)

return Conveyor
