local Life = require(game:GetService("ReplicatedStorage").CookieTycoon.BakeryLife)
local Recipes = require(game:GetService("ReplicatedStorage").CookieTycoon.Recipes)
local Appearance = {}
function Appearance.clear(state)
	for part, color in pairs(state.foodColors or {}) do if part.Parent then part.Color = color end end
	for _, gui in ipairs(state.foodPatterns or {}) do gui:Destroy() end
	state.foodColors, state.foodPatterns, state.foodKey = {}, {}, nil
end
function Appearance.step(player, state)
	local char = player.Character
	local hum, root = char and char:FindFirstChildOfClass("Humanoid"), char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end
	local buff = state.data.life.buff
	local active = (buff.expires or 0) > os.time()
	local key = active and (tostring(char) .. ":" .. buff.seed .. ":" .. buff.expires) or nil
	if state.foodCharacter ~= char then Appearance.clear(state) ; state.foodCharacter = char end
	if state.foodKey ~= key then
		Appearance.clear(state)
		state.foodKey = key
		if active then
			local recipe = Recipes[buff.recipe]
			local random = Random.new(buff.seed)
			local tint = Color3.fromRGB(table.unpack(recipe.Color)):Lerp(Color3.fromHSV(random:NextNumber(), 0.35, 1), 0.18)
			for _, part in ipairs(char:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					state.foodColors[part] = part.Color
					part.Color = tint
					for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
						local gui = Instance.new("SurfaceGui")
						gui.Name, gui.Face, gui.CanvasSize, gui.LightInfluence, gui.Parent = "Cookie Skin Chips", face, Vector2.new(64, 64), 1, part
						table.insert(state.foodPatterns, gui)
						for _ = 1, 7 do
							local dot = Instance.new("Frame")
							dot.Size, dot.Position, dot.BackgroundColor3, dot.BorderSizePixel, dot.Parent = UDim2.fromOffset(7, 7), UDim2.fromOffset(random:NextInteger(1, 55), random:NextInteger(1, 55)), Color3.fromRGB(table.unpack(recipe.Accent)), 0, gui
							local corner = Instance.new("UICorner")
							corner.CornerRadius, corner.Parent = UDim.new(1, 0), dot
						end
					end
				end
			end
		end
	end
	local road = math.abs(root.Position.X) < 13 and math.abs(root.Position.Z) < 575 and root.Position.Y < 8
	hum.WalkSpeed = (road and 34 or 16) + Life.speed(state.data.life, os.time())
	player:SetAttribute("OnFastRoad", road)
end
return Appearance
