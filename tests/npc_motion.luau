local Rules=require("../src/shared/NPCMotionRules")
return function(test,equal,near)
	test("NPC wandering stays on the public road and turns back at map ends",function()
		for _,side in ipairs({-1,1}) do
			for z=-520,520,13 do
				for _,roll in ipairs({0,.49,.5,1}) do
					for _,distance in ipairs({0,.5,1}) do
						local x,destination=Rules.destination(z,side,roll,distance)
						equal(x,side*5)
						assert(destination>=-520 and destination<=520)
						assert(math.abs(destination-z)>=28 and math.abs(destination-z)<=66)
						if z>450 then assert(destination<z) elseif z< -450 then assert(destination>z) end
					end
				end
			end
		end
	end)
	test("NPC arrival tolerates floor-to-root height but rejects another floor",function()
		local watch=Rules.watch(5,0,0)
		equal(Rules.check(watch,5,3.21,29,5,0,30,1),"arrived")
		equal(Rules.check(watch,5,12,30,5,0,30,1),"walking")
		equal(Rules.check(watch,5,3,25,5,0,30,1),"walking")
	end)
	test("NPC blocked progress triggers a new path without mistaking vertical jitter for walking",function()
		local watch=Rules.watch(5,0,0)
		equal(Rules.check(watch,5.1,3,0,5,0,30,2),"walking")
		equal(Rules.check(watch,5.1,3.8,.1,5,0,30,2.6),"blocked")
	end)
	test("NPC progress refreshes the stuck timer and path commands renew before Roblox timeout",function()
		local watch=Rules.watch(5,0,0)
		for i=1,8 do equal(Rules.check(watch,5,3,i,5,0,50,i*.5),"walking") end
		near(watch.movedAt,4)
		assert(Rules.Refresh<8 and Rules.Refresh<Rules.StuckAfter)
		equal(Rules.check(watch,5,3,8,5,0,50,6.6),"blocked")
	end)
	test("NPC waypoint timeout bounds recovery even when pushed in circles",function()
		local watch=Rules.watch(5,0,0)
		for i=1,14 do
			equal(Rules.check(watch,5+i%2*2,3,0,5,0,50,i),"walking")
		end
		equal(Rules.check(watch,7,3,0,5,0,50,15),"blocked")
		-- A fresh route after a conversation starts with a fresh progress clock.
		local resumed=Rules.watch(5,0,90)
		equal(Rules.check(resumed,5,3,0,5,0,50,90.1),"walking")
	end)
	test("NPC walk swings opposite arm and leg together and blends fully to rest",function()
		local pose=Rules.pose(math.pi/2,1)
		near(pose.leftHip,-pose.rightHip)
		near(pose.leftShoulder,-pose.rightShoulder)
		assert(pose.leftHip*pose.leftShoulder<0)
		assert(pose.leftHip*pose.rightShoulder>0)
		local idle=Rules.pose(2.5,0)
		for _,angle in pairs(idle) do equal(angle,0) end
		for _,angle in pairs(Rules.pose(math.pi/2,8)) do assert(math.abs(angle)<=.48) end
	end)
end
