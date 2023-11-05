local file = require("file")


function getPlayerData()
	return Game.GetScriptableSystemsContainer():Get("EquipmentSystem"):GetPlayerData(Game.GetPlayer())
end

function onBike()
	local vehicleTDBId = TDBID.ToStringDEBUG(Game.GetMountedVehicle(GetPlayer()):GetTDBID())
	return string.find(vehicleTDBId, "sportbike", 1) ~= nil
end


registerForEvent("onInit", function ()
	local config = file.readJSON("config.json")
	local clothingTDBId, slot = config["TDBId"], config["slot"]
	local clothingItemId = ItemID.FromTDBID(clothingTDBId)
	
	local wasOnBike = false

	Observe("DriveEvents", "OnEnter", function ()
		if onBike() and not wasOnBike then
			local playerData = getPlayerData()

			wasOnBike = true
			
			playerData:EquipVisuals(clothingItemId)
		end
	end)

	Observe("MotorcycleComponent", "OnUnmountingEvent", function ()
		if wasOnBike then
			local playerData = getPlayerData()
			
			wasOnBike = false

			if playerData:IsVisualSetActive() then
				playerData:EquipWardrobeSet(playerData:GetActiveWardrobeSet().setID)
			else
				playerData:ChangeAppearanceToItem(playerData:GetItemInEquipSlot(slot, 0))
			end
		end
	end)
end)
