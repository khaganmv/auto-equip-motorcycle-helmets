local file = require("file")


COMPATIBLE_VEHICLE_TDBIDS = {
	["Vehicle.bmw_s1000rr"] = true
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

local function newState(wasOnBike, wasTransmog, lastOutfit, lastHeadItem, lastWreathItem)
	return { 
		wasOnBike = wasOnBike, 
		wasTransmog = wasTransmog, 
		lastOutfit = lastOutfit,
		lastHeadItem = lastHeadItem,  
		lastWreathItem = lastWreathItem 
	}
end

local function printState(state)
	print("wasOnBike: ", tostring(state.wasOnBike))
	print("wasTransmog: ", tostring(state.wasTransmog))
	
	if state.lastOutfit then 
		print("lastOutfit: ", tostring(state.lastOutfit)) 
	else 
		print("lastOutfit: nil") 
	end
	
	if state.lastHeadItem then 
		print("lastHeadItem: ", tostring(state.lastHeadItem)) 
	else 
		print("lastHeadItem: nil") 
	end
	
	if state.lastWreathItem then 
		print("lastWreathItem: ", tostring(state.lastWreathItem)) 
	else 
		print("lastWreathItem: nil") 
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
		lastHeadItem = nil,
		lastWreathItem = nil
	}

	Observe("EquipmentSystemPlayerData", "OnRestored", function()
		if isOnBike() then
			print('[ AEMHnG ] Mounted...')
			local transactionSystem, outfitSystem = Game.GetTransactionSystem(), getOutfitSystem()
			local player, playerData = Game.GetPlayer(), getPlayerData()
			
			-- printState(state)

			state = newState(true, playerData:IsVisualSetActive(), nil, nil, nil)
		
			-- printState(state)

			outfitSystem:EquipItem(clothingItemId)
			playerData:EquipVisuals(clothingItemId)
		end
	end)

	Observe("DriveEvents", "OnEnter", function ()
		if isOnBike() and not state.wasOnBike then
			print('[ AEMHnG ] Mounting...')
			local transactionSystem, outfitSystem = Game.GetTransactionSystem(), getOutfitSystem()
			local player, playerData = Game.GetPlayer(), getPlayerData()
			
			-- printState(state)

			state = newState(
				true,
				playerData:IsVisualSetActive(),
				getEquippedOutfit(),
				transactionSystem:GetItemInSlot(player, "OutfitSlots.Head"),
				transactionSystem:GetItemInSlot(player, "OutfitSlots.Wreath")
			)

			if state.lastHeadItem then
				state.lastHeadItem = state.lastHeadItem:GetItemID()
			end

			if state.lastWreathItem then
				state.lastWreathItem = state.lastWreathItem:GetItemID()
				outfitSystem:DetachVisualFromSlot(state.lastWreathItem, "OutfitSlots.Wreath")
			end

			-- printState(state)
			
			outfitSystem:EquipItem(clothingItemId)
			playerData:EquipVisuals(clothingItemId)
		end
	end)

	Observe("MotorcycleComponent", "OnUnmountingEvent", function ()
		if state.wasOnBike then
			print('[ AEMHnG ] Unmounting...')
			local transactionSystem, outfitSystem = Game.GetTransactionSystem(), getOutfitSystem()
			local player, playerData = Game.GetPlayer(), getPlayerData()

			-- printState(state)

			state.wasOnBike = false
		
			playerData:UnequipVisuals(slot)

			if state.lastOutfit then
				outfitSystem:LoadOutfit(state.lastOutfit)
			else
				outfitSystem:UnequipItem(clothingItemId)

				if state.wasTransmog then
					if state.lastHeadItem then
						outfitSystem:EquipItem(state.lastHeadItem)
					end

					if state.lastWreathItem then
						outfitSystem:AttachVisualToSlot(state.lastWreathItem, "OutfitSlots.Wreath")
					end
				else
					outfitSystem:Deactivate()
				end
			end

			-- printState(state)
		end
	end)
end)
