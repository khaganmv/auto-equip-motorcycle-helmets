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
	local clothingTDBId = "Items.Helmet_01_basic_03"
	local clothingItemId = ItemID.FromTDBID(clothingTDBId)
	
	Observe("MotorcycleComponent", "OnMountingEvent", function ()
		local player, transactionSystem, playerData = getMetadata()
		transactionSystem:GiveItem(player, clothingItemId, 1)
		playerData:EquipItem(clothingItemId)
	end)

	Observe("MotorcycleComponent", "OnUnmountingEvent", function ()
		local player, transactionSystem, playerData = getMetadata()
		playerData:UnequipItem(clothingItemId)
		transactionSystem:RemoveItem(player, clothingItemId, 1)
	end)
end)
