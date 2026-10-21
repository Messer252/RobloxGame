local Recipes=if script then require(script.Parent.Recipes) else require("./Recipes")
local Gear=if script then require(script.Parent.GearCatalog) else require("./GearCatalog")
local Cards=if script then require(script.Parent.CardCatalog) else require("./CardCatalog")
local Polish=if script then require(script.Parent.BakeryPolish) else require("./BakeryPolish")
local Catalog={}
Catalog.Props={Conveyor=true,DoughMixer=true,BakerySign=true,RebirthPedestal=true,CollectionRegister=true,UpgradeConsole=true}
-- A finite allowlist: preview requests cannot name arbitrary instances/assets.
function Catalog.resolve(key)
 if type(key)~="string" or #key>60 then return nil end
 local kind,id=key:match("^(%a+):([%w]+)$")
 if not kind then return nil end
 local n=tonumber(id)
 if kind=="Pin" and n and n%1==0 and Gear.Pins[n] or kind=="Armor" and n and n%1==0 and Gear.Armor[n]
  or (kind=="Cookie" or kind=="Oven" or kind=="Glaze" or kind=="Sprinkles") and n and n%1==0 and Recipes[n]
  or kind=="Pack" and n and n%1==0 and Cards.Packs[n] then
  if tostring(n)~=id then return nil end
  return kind,n
 end
 if kind=="Decoration" and Polish.Decorations[id] or kind=="Prop" and Catalog.Props[id]
  or kind=="Machine" and (id=="Packager" or id=="Boxer" or id=="FinishingOven") then return kind,id end
 return nil
end
return Catalog
