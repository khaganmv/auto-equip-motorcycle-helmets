local config = require("config")

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
	local d = config.readJSON("config.json")
	local clothingTDBId, slot = d["TDBId"], d["slot"]
	local clothingItemId = ItemID.FromTDBID(clothingTDBId)
	
	local transmog = false
	local lastItemId = nil
	local lastTransmogId = nil

	Observe("MotorcycleComponent", "OnMountingEvent", function ()
		local player, transactionSystem, playerData = getMetadata()

		transmog = playerData:IsVisualSetActive()
		lastItemId = playerData:GetItemInEquipSlot(slot, 0)

		if transmog then
			lastTransmogId = playerData:GetVisualItemInSlot(slot)
			playerData:UnequipVisuals(slot)
		end

		transactionSystem:GiveItem(player, clothingItemId, 1)
		playerData:EquipItem(clothingItemId)
	end)

	Observe("MotorcycleComponent", "OnUnmountingEvent", function ()
		local player, transactionSystem, playerData = getMetadata()
		
		playerData:UnequipItem(clothingItemId)
		transactionSystem:RemoveItem(player, clothingItemId, 1)
		
		if transmog then
			playerData:EquipVisuals(lastTransmogId)
		end

		playerData:EquipItem(lastItemId)
	end)
end)
