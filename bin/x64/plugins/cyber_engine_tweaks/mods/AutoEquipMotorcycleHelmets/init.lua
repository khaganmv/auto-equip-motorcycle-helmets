local helmetTDBId = "Items.Helmet_01_basic_01"
local helmetItemId = ItemID.FromTDBID(helmetTDBId)

registerForEvent("onInit", function ()	
	local player = Game.GetPlayer()
	local transactionSystem = Game.GetTransactionSystem()
	local scriptableSystemsContainer = Game.GetScriptableSystemsContainer()
	
	local playerData = scriptableSystemsContainer:Get("EquipmentSystem"):GetPlayerData(player)
	-- local helmetCount = transactionSystem:GetItemQuantity(player, helmetItemId)
	-- local equippedHelmetTDBId = TDBID.ToStringDEBUG(playerData:GetItemInEquipSlot(17, 0).id)

	Observe("MotorcycleComponent", "OnMountingEvent", function ()
		transactionSystem:GiveItem(player, helmetItemId, 1)
		playerData:EquipItem(helmetItemId)
	end)

	Observe("MotorcycleComponent", "OnUnmountingEvent", function ()
		playerData:UnequipItem(helmetItemId)
		transactionSystem:RemoveItem(player, helmetItemId, 1)
	end)
end)
