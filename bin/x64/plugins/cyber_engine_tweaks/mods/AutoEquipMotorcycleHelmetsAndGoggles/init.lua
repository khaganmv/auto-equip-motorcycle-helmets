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
		if outfitSystem:IsEquipped(v) then return v end
	end

	return nil
end

function isBike(TDBId)
	return string.find(TDBId, "sportbike", 1) or COMPATIBLE_VEHICLE_TDBIDS[TDBId]
end

function isOnBike()
	local vehicleTDBId = TDBID.ToStringDEBUG(Game.GetMountedVehicle(Game.GetPlayer()):GetTDBID())
	return isBike(vehicleTDBId)
end


registerForEvent("onInit", function ()
	local config = file.readJSON("config.json")
	local clothingTDBId, slot = config["TDBId"], config["slot"]
	local clothingItemId = ItemID.FromTDBID(clothingTDBId)
	
	local wasOnBike = false
	local lastItemId = nil
	local lastOutfitCName = nil

	Observe("DriveEvents", "OnEnter", function ()
		if isOnBike() and not wasOnBike then
			local transactionSystem, outfitSystem = Game.GetTransactionSystem(), getOutfitSystem()
			local player, playerData = Game.GetPlayer(), getPlayerData()

			wasOnBike = true
			
			if playerData:IsVisualSetActive() then
				if outfitSystem then
					lastOutfitCName = getEquippedOutfit()
					outfitSystem:EquipItem(clothingItemId)
				end

				playerData:EquipVisuals(clothingItemId)
			else
				lastItemId = playerData:GetItemInEquipSlot(slot, 0)
				transactionSystem:GiveItem(player, clothingItemId, 1)
				playerData:EquipItem(clothingItemId)
				playerData:UnequipVisuals(slot)
			end
		end
	end)

	Observe("MotorcycleComponent", "OnUnmountingEvent", function ()
		if wasOnBike then
			local transactionSystem, outfitSystem = Game.GetTransactionSystem(), getOutfitSystem()
			local player, playerData = Game.GetPlayer(), getPlayerData()

			wasOnBike = false

			if playerData:IsVisualSetActive() then
				if outfitSystem then
					playerData:UnequipVisuals(slot)
					outfitSystem:LoadOutfit(lastOutfitCName)
				else
					playerData:EquipWardrobeSet(playerData:GetActiveWardrobeSet().setID)
				end
			else
				playerData:EquipItem(lastItemId)
				transactionSystem:RemoveItem(player, clothingItemId, 1)
			end
		end
	end)
end)
