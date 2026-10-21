-- One progression table drives purchases, models, mining and save limits.
local Gear = {}
Gear.Pins = {
	{Name="Maple",Cost=0,Power=1}, {Name="Copper",Cost=5000,Power=3},
	{Name="Steel",Cost=50000,Power=7}, {Name="Gilded",Cost=500000,Power=15},
	{Name="Starforged",Cost=5000000,Power=30},
	{Name="Peppermint",Cost=12000000,Power=36},
	{Name="Honeycomb",Cost=30000000,Power=43},
	{Name="Frosted Crystal",Cost=75000000,Power=51},
	{Name="Molten Cocoa",Cost=180000000,Power=60},
	{Name="Moon Sugar",Cost=450000000,Power=70},
	{Name="Prismatic",Cost=1100000000,Power=81},
	{Name="Dragon Crust",Cost=2700000000,Power=93},
	{Name="Celestial Baker",Cost=6500000000,Power=106},
}
Gear.Armor = {
	{Name="Oat Guard",Cost=1500,Defense=.05,Color={173,129,81},Trim={101,70,46},Material="WoodPlanks"},
	{Name="Cocoa Plate",Cost=15000,Defense=.10,Color={99,65,48},Trim={181,143,87},Material="Slate"},
	{Name="Sugarsteel",Cost=100000,Defense=.17,Color={148,174,184},Trim={82,111,129},Material="Metal"},
	{Name="Golden Crust",Cost=750000,Defense=.24,Color={205,154,67},Trim={110,77,43},Material="Metal"},
	{Name="Star Cookie",Cost=5000000,Defense=.32,Color={96,77,153},Trim={111,215,223},Material="Glass"},
	{Name="Peppermint Guard",Cost=12000000,Defense=.34,Color={216,230,218},Trim={190,68,78},Material="SmoothPlastic"},
	{Name="Honeycomb Mail",Cost=30000000,Defense=.36,Color={192,128,48},Trim={250,207,105},Material="Metal"},
	{Name="Frosted Crystal",Cost=75000000,Defense=.38,Color={121,179,211},Trim={212,241,247},Material="Glass"},
	{Name="Molten Cocoa",Cost=180000000,Defense=.40,Color={65,43,40},Trim={237,123,59},Material="Slate"},
	{Name="Moon Sugar",Cost=450000000,Defense=.42,Color={133,133,176},Trim={226,217,246},Material="Marble"},
	{Name="Prismatic Shell",Cost=1100000000,Defense=.44,Color={91,155,163},Trim={234,151,212},Material="Glass"},
	{Name="Dragon Crust",Cost=2700000000,Defense=.46,Color={107,52,67},Trim={216,168,91},Material="Metal"},
	{Name="Celestial Baker",Cost=6500000000,Defense=.48,Color={62,64,108},Trim={241,210,131},Material="Metal"},
}
return Gear
