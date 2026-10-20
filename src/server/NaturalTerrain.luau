local Shape = require(game:GetService("ReplicatedStorage").CookieTycoon.TerrainShape)
local Mine=require(game:GetService("ReplicatedStorage").CookieTycoon.MiningCatalog)
local Natural = {}
function Natural.create()
	local terrain = workspace.Terrain
	terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(106, 143, 76))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(122, 131, 136))
	terrain:SetMaterialColor(Enum.Material.Snow, Color3.fromRGB(229, 237, 239))
	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover, clouds.Density, clouds.Color, clouds.Parent = 0.48, 0.35, Color3.fromRGB(247, 249, 251), terrain
	task.spawn(function()
		-- Bounded chunks keep peak memory low; yield so joining players can load.
		for chunkX = -1056, 1024, 32 do
			for chunkZ = -1248, 1216, 32 do
				local heights, surfaces, highest = {}, {}, 0
				for x = 1, 8 do
					heights[x], surfaces[x] = {}, {}
					for z = 1, 8 do
						local wx, wz = chunkX + (x - 0.5) * 4, chunkZ + (z - 0.5) * 4
						local h = Shape.height(wx, wz)
						heights[x][z] = h
						surfaces[x][z] = Shape.grassAllowed(wx, wz) and Enum.Material.Grass or Enum.Material.Ground
						-- Dirt walking trails through the outer forest.
						if math.abs(wx) > 210 and math.abs(wx) < 420 and math.abs(wx - (wx < 0 and -205 or 205) - math.sin(wz / 70) * 12) < 5 then surfaces[x][z] = Enum.Material.Ground end
						highest = math.max(highest, h)
					end
				end
				local top = math.ceil((highest + 4) / 4) * 4
				local ny = (top + 20) / 4
				local materials, occupancy = {}, {}
				for x = 1, 8 do
					materials[x], occupancy[x] = {}, {}
					for y = 1, ny do
						materials[x][y], occupancy[x][y] = {}, {}
						for z = 1, 8 do
							local wx, wz, bottom = chunkX + (x - 0.5) * 4, chunkZ + (z - 0.5) * 4, -20 + (y - 1) * 4
							local h, material = heights[x][z], surfaces[x][z]
							if Shape.lake(wx, wz) then
								h = 0; material = bottom > -12 and Enum.Material.Water or Enum.Material.Rock
							elseif h > 58 and h - bottom < 9 then material = Shape.snow(wx, wz, h) and Enum.Material.Snow or Enum.Material.Rock
							elseif h - bottom > 8 or Mine.interior(wx,wz) and h-bottom>3 then material = Enum.Material.Rock end
							materials[x][y][z], occupancy[x][y][z] = material, Mine.carve(wx,wz,bottom) and 0 or math.clamp((h - bottom) / 4, 0, 1)
						end
					end
				end
				terrain:WriteVoxels(Region3.new(Vector3.new(chunkX, -20, chunkZ), Vector3.new(chunkX + 32, top, chunkZ + 32)), 4, materials, occupancy)
			end
			 task.wait()
		end
	end)
end
return Natural
