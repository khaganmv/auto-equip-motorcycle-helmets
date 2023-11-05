local file = require("file")


function getPlayerData()
	return Game.GetScriptableSystemsContainer():Get("EquipmentSystem"):GetPlayerData(Game.GetPlayer())
end

function isOnBike()
	local vehicleTDBId = TDBID.ToStringDEBUG(Game.GetMountedVehicle(Game.GetPlayer()):GetTDBID())
	return string.find(vehicleTDBId, "sportbike", 1) ~= nil
end


registerForEvent("onInit", function ()
	local config = file.readJSON("config.json")
	local clothingTDBId, slot = config["TDBId"], config["slot"]
	local clothingItemId = ItemID.FromTDBID(clothingTDBId)
	
	local wasOnBike = false
	local lastItemId = nil

	Observe("DriveEvents", "OnEnter", function ()
		if isOnBike() and not wasOnBike then
			local transactionSystem, player, playerData = Game.GetTransactionSystem(), Game.GetPlayer(), getPlayerData()

			wasOnBike = true
			
			if playerData:IsVisualSetActive() then
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
			local transactionSystem, player, playerData = Game.GetTransactionSystem(), Game.GetPlayer(), getPlayerData()
			
			wasOnBike = false

			if playerData:IsVisualSetActive() then
				playerData:EquipWardrobeSet(playerData:GetActiveWardrobeSet().setID)
			else
				playerData:EquipItem(lastItemId)
				transactionSystem:RemoveItem(player, clothingItemId, 1)
			end
		end
	end)
end)
