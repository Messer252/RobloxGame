local Shared=game:GetService("ReplicatedStorage").CookieTycoon
local Catalog,Town=require(Shared.CardCatalog),require(Shared.TownCatalog)
local FrameDesign,Tween=require(script.Parent.TradingCardFrame),game:GetService("TweenService")
local Preview=require(script.Parent.PurchasePreview)
local Client={odds={}}
function Client.describe(card)
	local parts={}
	for _,stat in ipairs({"Cash","Speed","Sales","Crumbs","Mine"}) do
		local amount=card.Effects[stat]
		if amount then table.insert(parts,"+"..(stat=="Mine" and amount or math.floor(amount*100+.5).."%").." "..({Cash="income",Speed="production",Sales="sales",Crumbs="Star Crumbs",Mine="mining damage"})[stat]) end
	end
	return table.concat(parts," • ")
end
function Client.renderPacks(data,row,send)
	row(data.crumbs.." STAR CRUMBS")
	local daily=row(data.claimDay<math.floor(os.time()/86400) and ("Claim daily gift • +"..Town.DailyCrumbs.." crumbs") or "Daily gift claimed • back tomorrow",function() send("DailyCrumbs") end)
	daily.Interactable=daily.Interactable and data.claimDay<math.floor(os.time()/86400)
	row("Daily gift, trail crumbs, jobs, ore and obbys all help you earn packs.")
	for id,pack in ipairs(Catalog.Packs) do
		row(pack.Name.." • "..pack.Cost.." crumbs")
		local buy=row("Buy & rip "..pack.Name,function() send("OpenPack",id) end)
		Preview.attach(buy,"Pack:"..id)
		buy.Interactable=buy.Interactable and data.crumbs>=pack.Cost
		local odds={}
		for index,weight in ipairs(pack.Weights) do table.insert(odds,Catalog.Rarities[index].." "..string.format("%g%%",weight/100)) end
		local detail=row(table.concat(odds," • "))
		detail.Visible=Client.odds[id]==true
		local toggle
		toggle=row(detail.Visible and "Hide odds" or "Show odds",function()
			Client.odds[id]=not Client.odds[id]
			detail.Visible=Client.odds[id]
			toggle.Text=detail.Visible and "Hide odds" or "Show odds"
		end)
		toggle.Size=UDim2.new(1,-8,0,32)
		toggle.Interactable=true
	end
	row("One card per pack. The server saves the card before the reveal. Duplicates stay in your collection.")
end
function Client.renderCollection(player,data,row,send,panel)
	local third=player:GetAttribute("ThirdCardSlotOwned")==true
	row(#data.equipped.."/"..(third and 3 or 2).." cards equipped • "..data.crumbs.." crumbs")
	row("Open packs at the Crumbkin Pack House in the side market (follow the fast-road branch).")
	local buy=row(third and "Third slot owned" or "Optional third card slot",function() Shared.Remotes.RequestPurchase:FireServer("Pass","ThirdCardSlot") end)
	Preview.attach(buy,"Pack:5")
	buy.Interactable=buy.Interactable and not third and player:GetAttribute("CommerceReady")==true and player:GetAttribute("PassesReady")==true and player:GetAttribute("ShopPromptOpen")~=true and require(Shared.ShopCatalog).offer("Pass","ThirdCardSlot")~=nil
	local count=0
	for id,card in ipairs(Catalog.Cards) do
		local copies=data.owned[tostring(id)]
		if not copies then continue end
		count+=1
		local equipped=table.find(data.equipped,id)
		local button=row((equipped and "✓ " or "")..card.Name.." • "..card.Rarity.." ×"..copies.."\n"..Client.describe(card),function() send("EquipCard",id) end,"equip-card:"..id)
		button.Size=UDim2.new(1,-8,0,65)
		button.Interactable=button.Interactable and (equipped~=nil or #data.equipped<(third and 3 or 2))
		button.BackgroundColor3=Color3.fromRGB(table.unpack(Catalog.Colors[card.Rarity])):Lerp(Color3.fromRGB(40,40,35),.55)
		local view=row("View "..card.Animal.." card",function() Client.reveal(panel.Parent,id,false,nil,copies) end,"view-card:"..id)
		view.Size=UDim2.new(1,-8,0,34)
		view.Interactable=true
	end
	if count==0 then row("Your collection starts with your first pack. Claim the daily gift at the Pack House!") end
end
function Client.reveal(gui,cardId,ripping,packId,copies)
	local old=gui:FindFirstChild("CardReveal")
	if old then old:Destroy() end
	local card=Catalog.Cards[cardId]
	if not card then return end
	local shade=Instance.new("TextButton")
	shade:SetAttribute("BlocksCameraLock",true)
	shade.Name,shade.Size,shade.Text,shade.BackgroundColor3,shade.BackgroundTransparency,shade.ZIndex,shade.Parent="CardReveal",UDim2.fromScale(1,1),"",Color3.fromRGB(14,18,24),.18,50,gui
	shade.AutoButtonColor=false
	local viewport=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800,600)
	local targetScale=math.min(1,viewport.Y/650,viewport.X/400)
	local frame=FrameDesign.create(shade,card,Client.describe(card))
	frame.AnchorPoint,frame.Position,frame.Visible=Vector2.new(.5,.5),UDim2.fromScale(.5,.5),not ripping
	local scale=Instance.new("UIScale")
	scale.Scale,scale.Parent=targetScale,frame
	local tweens,version,opened,animating,celebrated={},0,not ripping,false,false
	local canDismissAt=0
	local function animate(object,time,properties,easing)
		local tween=Tween:Create(object,TweenInfo.new(time,easing or Enum.EasingStyle.Quad,Enum.EasingDirection.Out),properties)
		table.insert(tweens,tween); tween:Play(); return tween
	end
	local function later(time,callback)
		local expected=version
		task.delay(time,function() if shade.Parent and version==expected then callback() end end)
	end
	local function text(parent,value,position,size,fontSize,z)
		local label=Instance.new("TextLabel")
		label.Text,label.Position,label.Size,label.TextSize=value,position,size,fontSize
		label.Font,label.TextColor3,label.TextWrapped=Enum.Font.GothamBold,Color3.fromRGB(255,237,199),true
		label.BackgroundTransparency,label.ZIndex,label.Parent=1,z or 65,parent
		return label
	end
	local function button(parent,value,position,size,callback)
		local control=Instance.new("TextButton")
		control.Text,control.Position,control.Size,control.BackgroundColor3=value,position,size,Color3.fromRGB(61,94,85)
		control.Font,control.TextSize,control.TextColor3,control.BorderSizePixel=Enum.Font.GothamBold,15,Color3.fromRGB(255,239,207),0
		control.ZIndex,control.Parent=72,parent
		local corner=Instance.new("UICorner"); corner.CornerRadius,corner.Parent=UDim.new(0,9),control
		control.Activated:Connect(callback)
		return control
	end
	local close=button(frame,"CLOSE",UDim2.new(1,-90,0,-38),UDim2.fromOffset(90,30),function() shade:Destroy() end)
	close.Visible=not ripping
	local rarityColor=Color3.fromRGB(table.unpack(Catalog.Colors[card.Rarity]))
	local result=text(frame,(not ripping and ("OWNED • "..(copies or 1).." COPIES") or copies and copies>1 and "DUPLICATE • "..copies.." COPIES" or "NEW COLLECTION CARD").."  /  "..string.upper(card.Rarity),UDim2.new(0,0,1,12),UDim2.new(1,0,0,28),14,57)
	result.TextColor3=rarityColor
	local wrapper,skip,top,bob
	local function showCard(instant)
		canDismissAt=os.clock()+.3
		if wrapper then wrapper.Visible=false end
		if skip then skip.Visible=false end
		frame.Visible,close.Visible=true,true
		frame.Position,frame.Rotation=UDim2.fromScale(.5,instant and .5 or .59),instant and 0 or -8
		scale.Scale=instant and targetScale or targetScale*.55
		if not instant then
			animate(frame,.6,{Position=UDim2.fromScale(.5,.5),Rotation=0},Enum.EasingStyle.Back)
			animate(scale,.6,{Scale=targetScale},Enum.EasingStyle.Back)
		end
		if ripping and not celebrated then
			celebrated=true
			if Client.audio then Client.audio:PlayCue((table.find(Catalog.Rarities,card.Rarity) or 1)>=3 and "UpgradePermanent" or "Claim") end
		end
		animating=false
	end
	local function sparkleBurst()
		local glow=Instance.new("Frame")
		glow.Size,glow.BackgroundColor3,glow.BorderSizePixel,glow.ZIndex,glow.Parent=UDim2.fromScale(1,1),rarityColor,0,51,shade
		glow.BackgroundTransparency=.65
		animate(glow,.6,{BackgroundTransparency=1})
		for index=1,26 do
			local particle=Instance.new("Frame")
			local angle=index/26*math.pi*2
			particle.AnchorPoint,particle.Position,particle.Size=Vector2.new(.5,.5),UDim2.fromScale(.5,.5),UDim2.fromOffset(5+index%3*2,5+index%3*2)
			particle.BackgroundColor3,particle.BorderSizePixel,particle.Rotation,particle.ZIndex,particle.Parent=rarityColor,0,45,69,shade
			animate(particle,.65+index%4*.12,{Position=UDim2.new(.5,math.cos(angle)*(100+index%5*24),.5,math.sin(angle)*(120+index%7*19)),Rotation=index*35,BackgroundTransparency=1})
		end
	end
	if ripping then
		local pack=Catalog.Packs[packId] or Catalog.Packs[1]
		local packColor=Color3.fromRGB(table.unpack(Catalog.Colors[Catalog.Rarities[packId or 1]] or Catalog.Colors.Common))
		wrapper=Instance.new("Frame")
		wrapper.Name,wrapper.AnchorPoint,wrapper.Position,wrapper.Size="BoosterWrapper",Vector2.new(.5,.5),UDim2.fromScale(.5,.5),UDim2.fromOffset(280,390)
		wrapper.BackgroundColor3,wrapper.BorderSizePixel,wrapper.ZIndex,wrapper.Parent=packColor:Lerp(Color3.fromRGB(29,46,52),.35),0,61,shade
		local wrapperScale=Instance.new("UIScale"); wrapperScale.Scale,wrapperScale.Parent=targetScale,wrapper
		local corner=Instance.new("UICorner"); corner.CornerRadius,corner.Parent=UDim.new(0,14),wrapper
		local outline=Instance.new("UIStroke"); outline.Color,outline.Thickness,outline.Parent=packColor,3,wrapper
		local gradient=Instance.new("UIGradient")
		gradient.Color,gradient.Rotation,gradient.Parent=ColorSequence.new(Color3.fromRGB(229,224,196),Color3.fromRGB(59,80,87)),35,wrapper
		top=Instance.new("Frame")
		top.Size,top.BackgroundColor3,top.BorderSizePixel,top.ZIndex,top.Parent=UDim2.new(1,0,0,30),Color3.fromRGB(192,170,117),0,66,wrapper
		for index=0,17 do
			local crimp=Instance.new("Frame")
			crimp.Position,crimp.Size,crimp.BackgroundColor3,crimp.BorderSizePixel,crimp.ZIndex,crimp.Parent=UDim2.fromOffset(index*16,3),UDim2.fromOffset(2,24),Color3.fromRGB(124,108,79),0,67,top
		end
		text(wrapper,"CRUMBKIN",UDim2.fromOffset(18,48),UDim2.fromOffset(244,40),28)
		text(wrapper,"COOKIE COMPANIONS",UDim2.fromOffset(18,89),UDim2.fromOffset(244,20),12)
		local badge=Instance.new("Frame")
		badge.Position,badge.Size,badge.BackgroundColor3,badge.BorderSizePixel,badge.ZIndex,badge.Parent=UDim2.fromOffset(85,133),UDim2.fromOffset(110,110),Color3.fromRGB(211,158,91),0,64,wrapper
		local round=Instance.new("UICorner"); round.CornerRadius,round.Parent=UDim.new(1,0),badge
		for index=1,8 do
			local chip=Instance.new("Frame")
			chip.Position,chip.Size,chip.BackgroundColor3,chip.BorderSizePixel,chip.Rotation,chip.ZIndex,chip.Parent=UDim2.fromOffset(43+math.cos(index*2.4)*35,43+math.sin(index*2.4)*35),UDim2.fromOffset(12,10),Color3.fromRGB(83,49,33),0,index*15,65,badge
		end
		text(wrapper,pack.Name,UDim2.fromOffset(16,258),UDim2.fromOffset(248,40),20)
		text(wrapper,"ONE COOKIE-ANIMAL CARD",UDim2.fromOffset(16,301),UDim2.fromOffset(248,20),11)
		bob=Tween:Create(wrapper,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Rotation=2})
		table.insert(tweens,bob); bob:Play()
		local rip
		rip=button(wrapper,"RIP OPEN",UDim2.fromOffset(24,337),UDim2.fromOffset(232,38),function()
			if opened then return end
			opened,animating=true,true
			version+=1
			bob:Cancel(); rip.Visible=false
			if Client.audio then Client.audio:PlayCue("Click") end
			animate(wrapper,.1,{Rotation=-5})
			later(.12,function() animate(wrapper,.1,{Rotation=5}) end)
			later(.25,function()
				animate(top,.3,{Position=UDim2.new(-.2,0,-.35,0),Rotation=-25})
				animate(wrapper,.25,{Rotation=-3})
			end)
			later(.5,function() top.Visible=false; animate(wrapper,.45,{Position=UDim2.fromScale(.5,1.3),Rotation=18}) end)
			later(.65,function() sparkleBurst(); showCard(false) end)
		end)
		skip=button(shade,"Skip animation",UDim2.new(.5,-85,1,-48),UDim2.fromOffset(170,32),function()
			version+=1
			for _,tween in ipairs(tweens) do tween:Cancel() end
			opened=true; showCard(true)
		end)
	end
	shade.Activated:Connect(function() if opened and not animating and os.clock()>=canDismissAt then shade:Destroy() end end)
	shade.Destroying:Connect(function() version+=1; for _,tween in ipairs(tweens) do tween:Cancel() end end)
end
function Client.start(remotes,gui,audio)
	Client.audio=audio
	remotes:WaitForChild("PackResult").OnClientEvent:Connect(function(id,packId,copies) Client.reveal(gui,id,true,packId,copies) end)
end
return Client
