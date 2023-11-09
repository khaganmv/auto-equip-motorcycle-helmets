local file = require("file")


COMPATIBLE_SLOT_TDBIDS = {
	"OutfitSlots.Head",
	"OutfitSlots.Balaclava",
	"OutfitSlots.Mask",
	"OutfitSlots.Glasses",
	"OutfitSlots.Wreath",
}

COMPATIBLE_VEHICLE_TDBIDS = {
	["Vehicle.bmw_s1000rr"] = true,
	["Vehicle.bmw_s1000rr_purchasable"] = true
}


local function getPlayerData()
	return Game.GetScriptableSystemsContainer():Get("EquipmentSystem"):GetPlayerData(Game.GetPlayer())
end

local function getOutfitSystem()
	return Game.GetScriptableSystemsContainer():Get("EquipmentEx.OutfitSystem")
end

local function getEquippedOutfit()
	local outfitSystem = getOutfitSystem()
	local outfits = outfitSystem:GetOutfits()

	for k, v in pairs(outfits) do
		if outfitSystem:IsEquipped(v) then
			return v
		end
	end

	return nil
end

local function isBike(TDBId)
	return string.find(TDBId, "sportbike", 1) ~= nil
end

local function isOnBike()
	local mountedVehicle = Game.GetMountedVehicle(Game.GetPlayer())
	
	if not mountedVehicle then
		return false
	end
	
	local vehicleTDBId = TDBID.ToStringDEBUG(mountedVehicle:GetTDBID())

	return isBike(vehicleTDBId) or COMPATIBLE_VEHICLE_TDBIDS[vehicleTDBId]
end

local function newState(wasOnBike, wasTransmog, lastOutfit, lastItems)
	return {
		wasOnBike = wasOnBike,
		wasTransmog = wasTransmog,
		lastOutfit = lastOutfit,
		lastItems = lastItems
	}
end

-- local function printState(state)
-- 	print("wasOnBike: ", tostring(state.wasOnBike))
-- 	print("wasTransmog: ", tostring(state.wasTransmog))
	
-- 	if state.lastOutfit then
-- 		print("lastOutfit: ", tostring(state.lastOutfit))
-- 	else 
-- 		print("lastOutfit: nil")
-- 	end
	
-- 	for slot, item in pairs(state.lastItems) do
		
-- 	end
-- end

local function getSlottedItems()
	local items = {}
	local player, transactionSystem = Game.GetPlayer(), Game.GetTransactionSystem()

	for i, slot in ipairs(COMPATIBLE_SLOT_TDBIDS) do
		local item = transactionSystem:GetItemInSlot(player, slot)
		
		if item then
			items[slot] = item:GetItemID()
		end
	end

	return items
end

local function equipItems(items)
	local outfitSystem = getOutfitSystem()
	
	for i, slot in ipairs(COMPATIBLE_SLOT_TDBIDS) do
		if items[slot] then
			outfitSystem:EquipItem(items[slot])
		end
	end
end

local function unequipItems(items)
	local outfitSystem = getOutfitSystem()
	
	for i, slot in ipairs(COMPATIBLE_SLOT_TDBIDS) do
		if items[slot] then
			outfitSystem:UnequipItem(items[slot])
		end
	end
end


registerForEvent("onInit", function ()
	local config = file.readJSON("config.json")
	local clothingTDBId, slot = config["TDBId"], config["slot"]
	local clothingItemId = ItemID.FromTDBID(clothingTDBId)
	
	local state = {
		wasOnBike = false,
		wasTransmog = false,
		lastOutfit = nil,
		lastItems = {}
	}

	ObserveAfter("EquipmentSystemPlayerData", "OnRestored", function()
		local playerData, outfitSystem = getPlayerData(), getOutfitSystem()
		
		state = newState(isOnBike(), playerData:IsVisualSetActive(), nil, getSlottedItems())

		if state.wasOnBike then
			outfitSystem:EquipItem(clothingItemId)
			outfitSystem:AttachAllVisualsToSlots(true)
		end
	end)

	ObserveAfter("DriveEvents", "OnEnter", function ()
		if isOnBike() and not state.wasOnBike then
			print('[ AEMHnG ] Mounting...')
			
			local playerData, outfitSystem = getPlayerData(), getOutfitSystem()
			
			state = newState(true, playerData:IsVisualSetActive(), getEquippedOutfit(), getSlottedItems())
			unequipItems(state.lastItems)
			outfitSystem:EquipItem(clothingItemId)
			outfitSystem:AttachAllVisualsToSlots(true)
		end
	end)

	Observe("MotorcycleComponent", "OnUnmountingEvent", function ()
		if state.wasOnBike then
			print('[ AEMHnG ] Unmounting...')

			local outfitSystem = getOutfitSystem()
			
			state.wasOnBike = false
			outfitSystem:UnequipItem(clothingItemId)

			if state.lastOutfit then
				outfitSystem:LoadOutfit(state.lastOutfit)
			else
				if state.wasTransmog then
					equipItems(state.lastItems)
					outfitSystem:AttachAllVisualsToSlots(true)
				else
					outfitSystem:Deactivate()
				end
			end
		end
	end)
end)
