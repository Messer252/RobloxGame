local Life=if script then require(script.Parent.BakeryLife) else require("./BakeryLife")
local Cards=if script then require(script.Parent.CardEconomy) else require("./CardEconomy")
local Earnings=if script then require(script.Parent.Earnings) else require("./Earnings")
local Rewards={}
-- Called inside the same durable receipt transaction as its unique defeat ID.
function Rewards.grant(data,reward,cookieId)
 local amount=math.min(reward.cash,Life.MaxCurrency-data.bank)
 Earnings.record(data,amount); data.bank+=amount
 data.life.dough=math.min(1e9,data.life.dough+reward.dough)
 data.life.cards.crumbs=math.min(Cards.MaxCrumbs,data.life.cards.crumbs+reward.crumbs)
 if reward.cookie then
  local added=Life.add(data.life,{id=cookieId,recipe=reward.cookie,mask=0})
  if not added then data.life.dough=math.min(1e9,data.life.dough+5) end
 end
 return true
end
return Rewards
