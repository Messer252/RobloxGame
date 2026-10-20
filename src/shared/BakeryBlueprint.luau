local Polish=if script then require(script.Parent.BakeryPolish) else require("./BakeryPolish")
local Blueprint={Width=164,Depth=244,WallX=81,BackZ=-121,WallTop=18.5,DoorStart=85,DoorEnd=101,Windows={-56,-28,0,28,56}}
function Blueprint.available(life)
	local keys={}
	if life then for _,key in ipairs(Polish.DecorationOrder) do
		local item=Polish.Decorations[key]
		if not life.decorations[key] and (not item.Requires or life.decorations[item.Requires]) then table.insert(keys,key) end
	end end
	return keys
end
function Blueprint.pad(index)
	return {x=({14,48})[(index-1)%2+1],z=-96+math.floor((index-1)/2)*32,width=8,depth=8}
end
function Blueprint.machine(index) return {x=-18+(index-1)*34,z=-27} end
return Blueprint
