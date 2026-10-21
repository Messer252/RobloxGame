local Gear = if script then require(script.Parent.GearCatalog) else require("./GearCatalog")
local Events = { HillX = -285, HillZ = 400, HillRadius = 24, CaptureSeconds = 8, PayoutSeconds = 10, HillReward = 10 }
function Events.onHill(x, y, z) return (x - Events.HillX)^2 + (z - Events.HillZ)^2 <= Events.HillRadius^2 and y >= 7 and y <= 21 end
function Events.damage(pin, attack, defense)
	pin=math.clamp(pin,1,#Gear.Pins)
	local base=10+math.min(pin,5)*2+math.max(0,pin-5)*.65
	return math.max(1,math.floor((base+(attack or 0))*(1-math.clamp(defense or 0,0,.60))))
end
function Events.meteorDelay(roll) return 300 + math.min(1500, math.floor(math.clamp(roll, 0, 1) * 1501)) end
function Events.meteorReward(roll) return 100 + math.min(250, math.floor(math.clamp(roll, 0, 1) * 251)) end
function Events.hillStep(state, occupants, online, now)
	if state.owner and not online[state.owner] then state.owner,state.nextPayout=nil,nil end
	if #occupants==1 and occupants[1]~=state.owner then
		local id=occupants[1]
		if state.candidate~=id then state.candidate,state.capture=id,now end
		if now-state.capture>=Events.CaptureSeconds then
			state.owner,state.nextPayout,state.candidate=id,now+Events.PayoutSeconds,nil
		end
	else state.candidate,state.capture=nil,nil end
	if #occupants>1 then
		-- Contesting pauses the next payment; there is no catch-up windfall.
		if state.owner then state.nextPayout=now+Events.PayoutSeconds end
	elseif state.owner and now>=(state.nextPayout or now+Events.PayoutSeconds) then
		state.nextPayout=now+Events.PayoutSeconds
		return state.owner
	end
	return nil
end
return Events
