State = require("modules/state")
Util = require("modules/util")


local state = State.new()




registerInput("toggle_headgear", "Toggle Headgear", function (keypress)
	if keypress then
		if Util.isOnBike() then
			if state.wasToggled then
				Util.equipItems(state.items)
			else
				Util.unequipItems(state.items)
			end

			state.wasToggled = not state.wasToggled
		end
	end
end)


registerForEvent("onInit", function ()
	state.items = Util.getItems()


	if #state.items == 0 then
		print("[ AEMHnG ] Config is empty.")
	else
		print("[ AEMHnG ] Config loaded:")

		for _, item in ipairs(state.items) do
			print("        " .. TDBID.ToStringDEBUG(item.id))
		end
	end


	ObserveAfter("EquipmentSystemPlayerData", "OnRestored", function ()
		state:update()
	end)


	ObserveBefore("VehicleComponent", "OnMountingEvent", function ()
		if Util.isOnBike() and not state.wasOnBike then
			print("[ AEMHnG ] Mounted bike: " .. TDBID.ToStringDEBUG(Game.GetMountedVehicle(Game.GetPlayer()):GetRecordID()))

			state:update()

			Util.unequipItems(state.lastItems)
			Util.equipItems(state.items)
		end
	end)

	
	ObserveBefore("VehicleComponent", "OnUnmountingEvent", function ()
		if state.wasOnBike then
			local outfitSystem = Util.getOutfitSystem()

			Util.unequipItems(state.items)
			Util.equipItems(state.lastItems)

			if state.lastOutfit then
				outfitSystem:LoadOutfit(state.lastOutfit)
			elseif not state.wasTransmog then
				outfitSystem:Deactivate()
			end

			state:reset()
		end
	end)
end)
