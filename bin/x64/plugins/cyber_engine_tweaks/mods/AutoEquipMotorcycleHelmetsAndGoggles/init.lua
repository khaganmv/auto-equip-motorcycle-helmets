local file = require("file")


COMPATIBLE_VEHICLE_TDBIDS = {
	["Vehicle.bmw_s1000rr"] = true
}


function getPlayerData()
	return Game.GetScriptableSystemsContainer():Get("EquipmentSystem"):GetPlayerData(Game.GetPlayer())
end

function getOutfitSystem()
	return Game.GetScriptableSystemsContainer():Get("EquipmentEx.OutfitSystem")
end

function getEquippedOutfit()
	local outfitSystem = getOutfitSystem()
	local outfits = outfitSystem:GetOutfits()

	for k, v in pairs(outfits) do
		if outfitSystem:IsEquipped(v) then
			return v
		end
	end

	return nil
end

function isBike(TDBId)
	return string.find(TDBId, "sportbike", 1) ~= nil
end

function isOnBike()
	local mountedVehicle = Game.GetMountedVehicle(Game.GetPlayer())
	
	if not mountedVehicle then
		return false
	end
	
	local vehicleTDBId = TDBID.ToStringDEBUG(mountedVehicle:GetTDBID())

	return isBike(vehicleTDBId) or COMPATIBLE_VEHICLE_TDBIDS[vehicleTDBId]
end


registerForEvent("onInit", function ()
	local config = file.readJSON("config.json")
	local clothingTDBId, slot = config["TDBId"], config["slot"]
	local clothingItemId = ItemID.FromTDBID(clothingTDBId)
	
	local wasOnBike = false
	local wasTransmog = false

	local lastOutfit = nil
	local lastHeadItem = nil
	local lastWreathItem = nil

	Observe("EquipmentSystemPlayerData", "OnRestored", function()
		if isOnBike() then
			local transactionSystem, outfitSystem = Game.GetTransactionSystem(), getOutfitSystem()
			local player, playerData = Game.GetPlayer(), getPlayerData()
			
			wasOnBike = true
		
			outfitSystem:EquipItem(clothingItemId)
			playerData:EquipVisuals(clothingItemId)
		end
	end)

	Observe("DriveEvents", "OnEnter", function ()
		if isOnBike() and not wasOnBike then
			-- print('Mounting...')
			local transactionSystem, outfitSystem = Game.GetTransactionSystem(), getOutfitSystem()
			local player, playerData = Game.GetPlayer(), getPlayerData()
			
			wasOnBike = true
			wasTransmog = playerData:IsVisualSetActive()

			lastOutfit = getEquippedOutfit()
			lastHeadItem = transactionSystem:GetItemInSlot(player, "OutfitSlots.Head")
			lastWreathItem = transactionSystem:GetItemInSlot(player, "OutfitSlots.Wreath")

			if lastHeadItem then
				lastHeadItem = lastHeadItem:GetItemID()
			end

			if lastWreathItem then
				lastWreathItem = lastWreathItem:GetItemID()
				outfitSystem:DetachVisualFromSlot(lastWreathItem, "OutfitSlots.Wreath")
			end
			
			outfitSystem:EquipItem(clothingItemId)
			playerData:EquipVisuals(clothingItemId)
		end
	end)

	Observe("MotorcycleComponent", "OnUnmountingEvent", function ()
		if wasOnBike then
			-- print('Unmounting...')
			local transactionSystem, outfitSystem = Game.GetTransactionSystem(), getOutfitSystem()
			local player, playerData = Game.GetPlayer(), getPlayerData()

			wasOnBike = false
		
			playerData:UnequipVisuals(slot)

			if lastOutfit then
				outfitSystem:LoadOutfit(lastOutfit)
			else
				outfitSystem:UnequipItem(clothingItemId)

				if wasTransmog then
					if lastHeadItem then
						outfitSystem:EquipItem(lastHeadItem)
					end

					if lastWreathItem then
						outfitSystem:AttachVisualToSlot(lastWreathItem, "OutfitSlots.Wreath")
					end
				else
					outfitSystem:Deactivate()
				end
			end
		end
	end)
end)
