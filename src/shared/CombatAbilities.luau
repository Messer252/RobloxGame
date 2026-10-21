local Abilities={Order={"Dodge","Spin","Guard","JumpAttack","CocoaBurst","CrustBreaker"}}
Abilities.Moves={
 Dodge={Name="Crumb Dodge",Slot="E",Cost=100,Cooldown=6,Duration=.4,Range=0,Power=0,Description="Dash forward; briefly avoid combat damage."},
 Spin={Name="Rolling Spin",Slot="E",Cost=300,Cooldown=9,Duration=.85,Windup=.3,Range=10,Power=1.4,Description="Spin your pin through nearby enemies."},
 Guard={Name="Sugar Guard",Slot="E",Cost=500,Cooldown=14,Duration=2.5,Range=0,Power=0,Description="Take 45% less combat damage for 2.5 seconds."},
 JumpAttack={Name="Cookie Slam",Slot="Q",Cost=150,Cooldown=10,Duration=1.6,Range=11,Power=1.8,Description="Leap, then slam nearby enemies when you land."},
 CocoaBurst={Name="Cocoa Burst",Slot="Q",Cost=450,Cooldown=12,Duration=.9,Windup=.45,Range=13,Power=1.65,Description="Release a circle of cocoa energy."},
 CrustBreaker={Name="Crust Breaker",Slot="Q",Cost=800,Cooldown=16,Duration=1.1,Windup=.7,Range=15,Power=2.5,Cone=true,Description="Wind up a heavy strike in front of you."},
}
function Abilities.normalize(raw)
 raw=type(raw)=="table" and raw or {}
 local data={owned={},E="",Q=""}
 for id in pairs(Abilities.Moves) do if type(raw.owned)=="table" and raw.owned[id]==true then data.owned[id]=true end end
 for _,slot in ipairs({"E","Q"}) do
  local id=raw[slot]
  if type(id)=="string" and Abilities.Moves[id] and Abilities.Moves[id].Slot==slot and data.owned[id] then data[slot]=id end
 end
 return data
end
function Abilities.purchase(life,id)
 local move=type(id)=="string" and Abilities.Moves[id]
 if not move then return false,"Unknown ability." end
 local data=life.abilities
 if not data.owned[id] then
  if life.dough<move.Cost then return false,"Mine more dough first." end
  life.dough-=move.Cost; data.owned[id]=true
 end
 data[move.Slot]=id
 return true,move.Name.." equipped to "..move.Slot.."!"
end
function Abilities.cast(data,slot,state,now)
 if slot~="E" and slot~="Q" then return nil end
 local id=data[slot]; local move=Abilities.Moves[id]
 if not move or not data.owned[id] or move.Slot~=slot or now<(state[slot] or 0) or now<(state.busy or 0) then return nil end
 state[slot],state.busy=now+move.Cooldown,now+move.Duration
 return id,move
end
function Abilities.protection(now,dodge,guard)
 if now<(dodge or 0) then return 0 end
 return now<(guard or 0) and .55 or 1
end
function Abilities.inRange(x,y,z,range,dot,cone)
 return x*x+z*z<=range*range and math.abs(y)<=10 and (not cone or dot>0)
end
-- Normalized pose curves shared by R6/R15 visual animation; no asset IDs needed.
function Abilities.pose(id,t)
 t=math.clamp(t,0,1)
 local ease=math.sin(t*math.pi)
 if id=="Spin" then return {yaw=t*math.pi*2,pitch=0,arm=1.35*ease,leg=.25*ease} end
 if id=="Dodge" then return {yaw=0,pitch=-.9*ease,arm=-.7*ease,leg=.8*ease} end
 if id=="Guard" then return {yaw=0,pitch=.12*ease,arm=1.2*math.min(1,t*8,(1-t)*8),leg=0} end
 local slam=t<.45 and -t/.45 or (1-t)/.55
 return {yaw=0,pitch=slam*.6,arm=slam*1.6,leg=id=="JumpAttack" and -.65*ease or .15*ease}
end
return Abilities
