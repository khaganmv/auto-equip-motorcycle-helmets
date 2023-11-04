local file = require("file")

function getMetadata()
	local player = Game.GetPlayer()
	local transactionSystem = Game.GetTransactionSystem()
	local scriptableSystemsContainer = Game.GetScriptableSystemsContainer()
	
	local playerData = scriptableSystemsContainer:Get("EquipmentSystem"):GetPlayerData(player)
	-- local helmetCount = transactionSystem:GetItemQuantity(player, helmetItemId)
	-- local equippedHelmetTDBId = TDBID.ToStringDEBUG(playerData:GetItemInEquipSlot(17, 0).id)

	return player, transactionSystem, playerData
end

function onBike()
	local vehicleTDBId = TDBID.ToStringDEBUG(Game.GetMountedVehicle(GetPlayer()):GetTDBID())
	return string.find(vehicleTDBId, "sportbike", 1) ~= nil
end

registerForEvent("onInit", function ()
	local config = file.readJSON("config.json")
	local clothingTDBId, slot = config["TDBId"], config["slot"]
	local clothingItemId = ItemID.FromTDBID(clothingTDBId)
	
	local lastItemId = nil
	local lastTransmogId = nil
	local wasOnBike = false

	Observe("DriveEvents", "OnEnter", function ()
		if onBike() then
			local player, transactionSystem, playerData = getMetadata()

			lastItemId = playerData:GetItemInEquipSlot(slot, 0)
			lastTransmogId = playerData:GetVisualItemInSlot(slot)
			wasOnBike = true
				
			transactionSystem:GiveItem(player, clothingItemId, 1)
			playerData:EquipItem(clothingItemId)
			playerData:UnequipVisuals(slot)
		end
	end)

	Observe("DriveEvents", "OnExit", function ()
		if wasOnBike then
			local player, transactionSystem, playerData = getMetadata()
			
			wasOnBike = false

			playerData:EquipItem(lastItemId)
			playerData:EquipVisuals(lastTransmogId)
			transactionSystem:RemoveItem(player, clothingItemId, 1)
		end
	end)
end)
