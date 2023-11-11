local file = require("file")


COMPATIBLE_SLOT_TDBIDS = {
	"OutfitSlots.Head",
	"OutfitSlots.Balaclava",
	"OutfitSlots.Mask",
	"OutfitSlots.Glasses",
	"OutfitSlots.Wreath",
}


local function getPlayerData()
	return Game.GetScriptableSystemsContainer():Get("EquipmentSystem"):GetPlayerData(Game.GetPlayer())
end

local function getOutfitSystem()
	return Game.GetScriptableSystemsContainer():Get("EquipmentEx.OutfitSystem")
end

local function getEquippedOutfit()
	local outfitSystem = getOutfitSystem()
	local outfits = outfitSystem:GetOutfits()

	for _, outfit in pairs(outfits) do
		if outfitSystem:IsEquipped(outfit) then
			return outfit
		end
	end

	return nil
end

local function isOnBike()
	local mountedVehicle = Game.GetMountedVehicle(Game.GetPlayer())

	if not mountedVehicle then
		return false
	end

	return mountedVehicle:IsA("vehicleBikeBaseObject")
end

local function newState(wasOnBike, wasTransmog, lastOutfit, lastItems)
	return {
		wasOnBike = wasOnBike,
		wasTransmog = wasTransmog,
		lastOutfit = lastOutfit,
		lastItems = lastItems
	}
end

local function getSlottedItems()
	local items = {}
	local player, transactionSystem = Game.GetPlayer(), Game.GetTransactionSystem()

	for _, slot in ipairs(COMPATIBLE_SLOT_TDBIDS) do
		local item = transactionSystem:GetItemInSlot(player, slot)

		if item then
			items[slot] = item:GetItemID()
		end
	end

	return items
end

local function equipItem(item)
	local outfitSystem = getOutfitSystem()

	outfitSystem:EquipItem(item)
	outfitSystem:AttachAllVisualsToSlots(true)
end

local function equipItems(items)
	local outfitSystem = getOutfitSystem()

	for _, slot in ipairs(COMPATIBLE_SLOT_TDBIDS) do
		if items[slot] then
			outfitSystem:EquipItem(items[slot])
		end
	end
end

local function unequipItems(items)
	local outfitSystem = getOutfitSystem()

	for _, slot in ipairs(COMPATIBLE_SLOT_TDBIDS) do
		if items[slot] then
			outfitSystem:UnequipItem(items[slot])
		end
	end
end


registerForEvent("onInit", function ()
	local config = file.readJSON("config.json")
	local clothingTDBId, slot = config["TDBId"], config["slot"]
	local clothingItemId = ItemID.FromTDBID(clothingTDBId)

	local state = {
		wasOnBike = false,
		wasTransmog = false,
		lastOutfit = nil,
		lastItems = {}
	}

	ObserveAfter("EquipmentSystemPlayerData", "OnRestored", function ()
		local playerData = getPlayerData()

		state = newState(isOnBike(), playerData:IsVisualSetActive(), nil, getSlottedItems())

		if state.wasOnBike then
			equipItem(clothingItemId)
		end
	end)

	ObserveBefore("VehicleComponent", "OnVehicleCameraChange", function ()
		if isOnBike() and not state.wasOnBike then
			local playerData = getPlayerData()

			state = newState(true, playerData:IsVisualSetActive(), getEquippedOutfit(), getSlottedItems())
			unequipItems(state.lastItems)
			equipItem(clothingItemId)
		end
	end)

	Observe("MotorcycleComponent", "OnUnmountingEvent", function ()
		if state.wasOnBike then
			local outfitSystem = getOutfitSystem()

			state.wasOnBike = false
			outfitSystem:UnequipItem(clothingItemId)

			if state.lastOutfit then
				outfitSystem:LoadOutfit(state.lastOutfit)
			else
				if state.wasTransmog then
					equipItems(state.lastItems)
					outfitSystem:AttachAllVisualsToSlots(true)
				else
					outfitSystem:Deactivate()
				end
			end
		end
	end)
end)
