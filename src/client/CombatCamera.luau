local Input,Run,Actions=game:GetService("UserInputService"),game:GetService("RunService"),game:GetService("ContextActionService")
local GuiService=game:GetService("GuiService")
local Rules=require(game:GetService("ReplicatedStorage").CookieTycoon.CameraLockRules)
local Camera={}
function Camera.start(player,gui,button)
	local requested,focused,engaged=false,true,false
	local controlled,oldRotate,oldOffset,oldMouse,oldIcon
	local connections={}
	local dot=Instance.new("Frame")
	dot.Name,dot.AnchorPoint,dot.Position,dot.Size="AimReticle",Vector2.new(.5,.5),UDim2.fromScale(.5,.5),UDim2.fromOffset(5,5)
	dot.BackgroundColor3,dot.BorderSizePixel,dot.ZIndex,dot.Visible,dot.Parent=Color3.fromRGB(255,236,198),0,10,false,gui
	local corner=Instance.new("UICorner"); corner.CornerRadius,corner.Parent=UDim.new(1,0),dot
	local stroke=Instance.new("UIStroke"); stroke.Color,stroke.Thickness,stroke.Parent=Color3.fromRGB(51,39,29),1,dot
	local function release()
		if controlled and controlled.Parent then
			if player:GetAttribute("AdminFlying")~=true then controlled.AutoRotate=oldRotate end
			controlled.CameraOffset=oldOffset
		end
		if engaged then
			if Input.MouseBehavior==Enum.MouseBehavior.LockCenter then Input.MouseBehavior=oldMouse end
			Input.MouseIconEnabled=oldIcon
		end
		controlled,engaged=nil,false
		dot.Visible=false
	end
	local function menuOpen()
		if GuiService.MenuIsOpen or player:GetAttribute("ShopPromptOpen")==true then return true end
		for _,object in ipairs(gui:GetChildren()) do
			if object:IsA("GuiObject") and object.Visible and object:GetAttribute("BlocksCameraLock")==true then return true end
		end
		return false
	end
	local function toggle()
		requested=not requested
		if not requested then release() end
	end
	table.insert(connections,button.Activated:Connect(toggle))
	Actions:BindActionAtPriority("CookieCombatLock",function(_,state)
		if Input:GetFocusedTextBox() or menuOpen() or player:GetAttribute("AdminFlying")==true then return Enum.ContextActionResult.Pass end
		if state==Enum.UserInputState.Begin then toggle() end
		return Enum.ContextActionResult.Sink
	end,false,Enum.ContextActionPriority.High.Value+100,Enum.KeyCode.LeftShift,Enum.KeyCode.RightShift,Enum.KeyCode.LeftControl,Enum.KeyCode.RightControl,Enum.KeyCode.ButtonR3)
	table.insert(connections,Input.WindowFocusReleased:Connect(function() focused=false; release() end))
	table.insert(connections,Input.WindowFocused:Connect(function() focused=true end))
	table.insert(connections,player.CharacterRemoving:Connect(function() requested=false; release() end))
	Run:BindToRenderStep("CookieAimOffset",Enum.RenderPriority.Camera.Value-1,function()
		local camera,character=workspace.CurrentCamera,player.Character
		local hum=character and character:FindFirstChildOfClass("Humanoid")
		local active=Rules.active({requested=requested,alive=hum~=nil and hum.Health>0,focused=focused,
			typing=Input:GetFocusedTextBox()~=nil,menu=menuOpen(),flying=player:GetAttribute("AdminFlying")==true,
			seated=hum and hum.Sit,platform=hum and hum.PlatformStand,scripted=not camera or camera.CameraType~=Enum.CameraType.Custom})
		if not active then
			release()
			button.Text=requested and "Aim PAUSED" or "Aim • Shift/Ctrl"
			return
		end
		if controlled~=hum then
			release()
			controlled,oldRotate,oldOffset=hum,hum.AutoRotate,hum.CameraOffset
			oldMouse,oldIcon=Input.MouseBehavior,Input.MouseIconEnabled
			engaged=true
		end
		hum.AutoRotate=false
		local firstPerson=(camera.CFrame.Position-camera.Focus.Position).Magnitude<1
		hum.CameraOffset=firstPerson and Vector3.zero or Vector3.new(1.65,.3,0)
		button.Text="Aim ON • Shift/Ctrl"
	end)
	Run:BindToRenderStep("CookieAimFacing",Enum.RenderPriority.Camera.Value+1,function(dt)
		if not engaged then return end
		local camera=workspace.CurrentCamera
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not camera or not root then release(); return end
		if Input.MouseEnabled then Input.MouseBehavior=Enum.MouseBehavior.LockCenter; Input.MouseIconEnabled=false end
		local look=camera.CFrame.LookVector
		local flat=Vector3.new(look.X,0,look.Z)
		if flat.Magnitude>.05 then root.CFrame=root.CFrame:Lerp(CFrame.lookAt(root.Position,root.Position+flat),1-math.exp(-20*dt)) end
		local inset=gui.IgnoreGuiInset and Vector2.zero or GuiService:GetGuiInset()
		dot.Position=UDim2.fromOffset(camera.ViewportSize.X/2-inset.X,camera.ViewportSize.Y/2-inset.Y)
		dot.Visible=true
	end)
	gui.Destroying:Connect(function()
		release()
		Run:UnbindFromRenderStep("CookieAimOffset"); Run:UnbindFromRenderStep("CookieAimFacing")
		Actions:UnbindAction("CookieCombatLock")
		for _,connection in ipairs(connections) do connection:Disconnect() end
	end)
end
return Camera
