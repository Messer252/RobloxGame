local Progress=if script then require(script.Parent.ObbyProgress) else require("./ObbyProgress")
local Claims={}; Claims.__index=Claims
function Claims.new() return setmetatable({pending={}},Claims) end
function Claims:Validate(player,run,course,onFinish,now)
 if self.pending[player] or not Progress.canFinish(run,course,onFinish,now) then return false end
 self.pending[player]={course=course.Id}
 run.finishValidated=true
 return true
end
function Claims:Attempt(player,courseId,award)
 local pending=self.pending[player]
 if not pending or pending.course~=courseId or pending.busy then return nil end
 pending.busy=true
 local ok,awarded,message=pcall(award)
 pending.busy=false
 if ok and awarded==true then self.pending[player]=nil; return true,message end
 return false,"Course complete! Waiting for your current save before awarding the prize."
end
return Claims
