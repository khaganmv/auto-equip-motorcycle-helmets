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

registerForEvent("onInit", function ()
	local config = file.readJSON("config.json")
	local clothingTDBId, slot = config["TDBId"], config["slot"]
	local clothingItemId = ItemID.FromTDBID(clothingTDBId)
	
	local lastItemId = nil
	local lastTransmogId = nil

	Observe("MotorcycleComponent", "OnMountingEvent", function ()
		local player, transactionSystem, playerData = getMetadata()

		lastItemId = playerData:GetItemInEquipSlot(slot, 0)
		lastTransmogId = playerData:GetVisualItemInSlot(slot)
			
		playerData:UnequipVisuals(slot)
		transactionSystem:GiveItem(player, clothingItemId, 1)
		playerData:EquipItem(clothingItemId)
	end)

	Observe("MotorcycleComponent", "OnUnmountingEvent", function ()
		local player, transactionSystem, playerData = getMetadata()
		
		playerData:EquipItem(lastItemId)
		transactionSystem:RemoveItem(player, clothingItemId, 1)
		playerData:EquipVisuals(lastTransmogId)
	end)
end)
