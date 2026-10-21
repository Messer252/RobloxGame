-- Wallet transfers never call record: lifetime earnings count each source once.
local Earnings={Limit=1e300}
function Earnings.valid(n) return type(n)=="number" and n==n and n>=0 and n<math.huge end
function Earnings.total(data)
	if Earnings.valid(data.lifetimeCash) then return math.min(Earnings.Limit,data.lifetimeCash) end
	return math.min(Earnings.Limit,(Earnings.valid(data.cash) and data.cash or 0)+(Earnings.valid(data.bank) and data.bank or 0))
end
function Earnings.record(data,amount)
	assert(Earnings.valid(amount),"Invalid earnings")
	data.lifetimeCash=math.min(Earnings.Limit,Earnings.total(data)+amount)
end
-- OrderedDataStore accepts integers only. Log encoding keeps very large
-- lifetime totals sortable; boards read the actual total from saved profiles.
function Earnings.score(amount)
	if not Earnings.valid(amount) then return nil end
	if amount<=1e12 then return math.floor(amount) end
	return math.floor(1e12+math.log10(math.min(amount,Earnings.Limit)/1e12)*1e12+.5)
end
function Earnings.decode(score)
	return score<=1e12 and score or math.min(Earnings.Limit,10^(12+(score-1e12)/1e12))
end
return Earnings
