local Rankings = require("../src/server/GlobalRankings")
return function(test, equal)
	local function harness()
		local now, saved, stores = 100, {}, {}
		for _, key in ipairs({"cash", "rebirths"}) do
			local store = {values = {}, writes = 0}
			function store:SetAsync(id, value)
				if self.failWrite then error("write outage") end
				self.values[id], self.writes = value, self.writes + 1
				if self.afterWrite then self.afterWrite() end
			end
			function store:GetSortedAsync(ascending, limit)
				assert(not ascending and limit == 8)
				if self.failRead then error("read outage") end
				local rows = {}
				for id, value in pairs(self.values) do table.insert(rows, {key=id,value=value}) end
				table.sort(rows,function(a,b) return a.value>b.value end)
				while #rows>limit do table.remove(rows) end
				return {GetCurrentPage=function() return rows end}
			end
			stores[key] = store
		end
		local index = Rankings.new(stores, function(id)
			if saved.fail then error("profile outage") end
			return saved[id]
		end, function(id)
			if saved.nameFail then error("name outage") end
			return "Baker"..id
		end, function() return now end)
		return index, saved, stores, function(seconds) now+=seconds end
	end
	local function profile(cash, rebirths) return {Version=8,Data={cash=cash,rebirths=rebirths}} end
	test("global boards show offline saved players across independent server caches", function()
		local a, saved, stores = harness()
		saved[101],saved[202]=profile(5000,3),profile(7000,1)
		a:Queue(101); a:Queue(202); assert(a:FlushOne()); assert(a:FlushOne())
		local b=Rankings.new(stores,function() error("no local players") end,function(id) return "Offline"..id end,function() return 0 end)
		assert(b:Refresh("cash")); assert(b:Refresh("rebirths"))
		local cash=b:Get("cash"); equal(cash[1].userId,202); equal(cash[2].name,"Offline101")
		local rebirths=b:Get("rebirths"); equal(rebirths[1].userId,101)
	end)
	test("queued rankings read the latest committed wallet and allow spending and rebirth decreases", function()
		local index,saved,stores,advance=harness()
		saved[1]=profile(10000,2); index:Queue(1); assert(index:FlushOne())
		index:Queue(1) -- An earlier request must not carry a stale score snapshot.
		saved[1]=profile(0,3); advance(31); assert(index:FlushOne())
		equal(stores.cash.values["1"],0); equal(stores.rebirths.values["1"],3)
	end)
	test("profile and partial index outages retain queued work without replacing scores with zero", function()
		local index,saved,stores,advance=harness()
		saved[1]=profile(123,4); saved.fail=true; index:Queue(1)
		assert(not index:FlushOne()); equal(stores.cash.writes,0); assert(index.pending[1])
		saved.fail=false; stores.rebirths.failWrite=true; advance(6)
		assert(not index:FlushOne()); equal(stores.cash.values["1"],123); assert(index.pending[1])
		stores.rebirths.failWrite=false; advance(6); assert(index:FlushOne())
		equal(stores.rebirths.values["1"],4); equal(index.pending[1],nil)
	end)
	test("new requests during an index write remain queued and preview IDs cannot be ranked", function()
		local index,saved,stores,advance=harness()
		equal(index:Queue(-1),nil); equal(index:Queue(0),nil); equal(index:Queue(1.5),nil)
		saved[1]=profile(10,1); index:Queue(1)
		stores.cash.afterWrite=function() stores.cash.afterWrite=nil; index:Queue(1) end
		assert(index:FlushOne()); assert(index.pending[1]); equal(index.completed[1],1)
		saved[1]=profile(20,2)
		advance(31); assert(index:FlushOne()); equal(stores.cash.values["1"],20); equal(index.completed[1],2)
	end)
	test("malformed or future saves never create scores and cannot stall the offline import", function()
		local index,saved,stores=harness()
		saved[1]={Version=99,Data={cash=1e9,rebirths=1}}
		saved[2]=profile(0/0,4); saved[3]=profile(math.huge,4)
		for id=1,3 do index:Queue(id) end
		for _=1,3 do assert(index:FlushOne()) end
		equal(stores.cash.writes,0); equal(next(index.pending),nil)
	end)
	test("a newer cross-server save during indexing repairs stale cash even without a local save event", function()
		local index,saved,stores,advance=harness()
		saved[1]=profile(1000,2); index:Queue(1)
		stores.cash.afterWrite=function() stores.cash.afterWrite=nil; saved[1]=profile(10,3) end
		local ok,reason=index:FlushOne()
		assert(not ok); equal(reason,"changed_during_write"); assert(index.pending[1])
		advance(6); assert(index:FlushOne())
		equal(stores.cash.values["1"],10); equal(stores.rebirths.values["1"],3)
	end)
	test("global read failures keep the last board and failed usernames retry without hiding offline rows", function()
		local index,saved,stores,advance=harness()
		stores.cash.values["7"]=800; saved.nameFail=true
		assert(index:Refresh("cash")); local rows=index:Get("cash"); equal(rows[1].name,"User 7")
		stores.cash.failRead=true; assert(not index:Refresh("cash"))
		local retained,status=index:Get("cash"); equal(retained,rows); equal(status,"Cached • reconnecting")
		stores.cash.failRead=false; saved.nameFail=false; advance(61)
		assert(index:Refresh("cash")); rows=index:Get("cash"); equal(rows[1].name,"Baker7")
	end)
	test("offline backfill checkpoints completed pages and resumes without skipping an interrupted next page", function()
		local index,saved,stores,advance=harness()
		for id=1,3 do saved[id]=profile(id*100,id) end
		local cursor,finished,interrupt="",false,true
		local source={}
		function source:ListKeysAsync(prefix,size,start,excludeDeleted)
			equal(prefix,"Player_"); equal(size,20); assert(excludeDeleted)
			local page={number=start=="page2" and 2 or 1,IsFinished=start=="page2",Cursor=start=="page2" and "" or "page2"}
			function page:GetCurrentPage()
				return self.number==1 and {{KeyName="Player_1"},{KeyName="Other_999"}} or {{KeyName="Player_2"},{KeyName="Player_3"}}
			end
			function page:AdvanceToNextPageAsync()
				if interrupt then error("interrupted page request") end
				self.number,self.IsFinished,self.Cursor=2,true,""
			end
			return page
		end
		local function lease(nextCursor,done) cursor=nextCursor or cursor; finished=done; return true end
		local function wait(seconds) advance(seconds); index:FlushOne() end
		assert(not index:Backfill(source,cursor,lease,wait,function() return false end))
		equal(cursor,"page2"); equal(stores.cash.values["1"],100); assert(not finished)
		interrupt=false
		assert(index:Backfill(source,cursor,lease,wait,function() return false end))
		equal(stores.cash.values["2"],200); equal(stores.cash.values["3"],300); assert(finished)
	end)
	test("global cash ranks lifetime earnings even after spending and across large offline profiles",function()
        local index,saved,stores,advance=harness()
        saved[1]=profile(0,75); saved[1].Data.lifetimeCash=1e100
        saved[2]=profile(999999,5); saved[2].Data.lifetimeCash=2e100
        index:Queue(1); index:Queue(2); assert(index:FlushOne()); assert(index:FlushOne())
        assert(stores.cash.values["2"]>stores.cash.values["1"])
        assert(index:Refresh("cash")); local rows=index:Get("cash")
        equal(rows[1].userId,2); equal(rows[1].cash,2e100); equal(rows[2].cash,1e100)
        saved[2].Data.cash=0; saved[2].Data.rebirths=6
        advance(31); index:Queue(2); assert(index:FlushOne()); assert(index:Refresh("cash"))
        rows=index:Get("cash"); equal(rows[1].cash,2e100)
    end)
	test("lost migration lease stops backfill before importing the following page", function()
		local index=harness()
		local source={ListKeysAsync=function() return {IsFinished=false,Cursor="next",GetCurrentPage=function() return {} end,AdvanceToNextPageAsync=function() error("must not advance") end} end}
		assert(not index:Backfill(source,"",function() return false end,function() error("must not wait") end,function() return false end))
	end)
end
