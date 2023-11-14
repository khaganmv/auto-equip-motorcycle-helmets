local file = require("file")
local State = require("state")


BASE_SLOTS = {
	["Face"] = true,
	["Head"] = true
}

EQUIPMENT_EX_SLOTS = {
	["OutfitSlots.Head"] = true,
	["OutfitSlots.Balaclava"] = true,
	["OutfitSlots.Mask"] = true,
	["OutfitSlots.Glasses"] = true,
	["OutfitSlots.Wreath"] = true
}

local state = State.new()


local function getPlayerData()
	return Game.GetScriptableSystemsContainer():Get("EquipmentSystem"):GetPlayerData(Game.GetPlayer())
end

local function getOutfitSystem()
	return Game.GetScriptableSystemsContainer():Get("EquipmentEx.OutfitSystem")
end

local function getItems()
	local items = {}
	local config = file.readJSON("config.json")

	for i, item in ipairs(config) do
		items[i] = ItemID.FromTDBID(item)
	end

	return items
end

local function isOnBike()
	local mountedVehicle = Game.GetMountedVehicle(Game.GetPlayer())

	if not mountedVehicle then
		return false
	end

	return mountedVehicle:IsA("vehicleBikeBaseObject")
end

local function isTransmog()
	return getPlayerData():IsVisualSetActive()
end

local function getLastOutfit()
	local outfitSystem = getOutfitSystem()
	local outfits = outfitSystem:GetOutfits()

	for _, outfit in pairs(outfits) do
		if outfitSystem:IsEquipped(outfit) then
			return outfit
		end
	end

	return nil
end

local function getLastItems()
	local items = {}
	local player, transactionSystem = Game.GetPlayer(), Game.GetTransactionSystem()

	for slot, _ in pairs(BASE_SLOTS) do
		local item = getPlayerData():GetActiveItem(slot)

		if ItemID.IsValid(item) then
			items[slot] = item
		end
	end

	for slot, _ in pairs(EQUIPMENT_EX_SLOTS) do
		local item = transactionSystem:GetItemInSlot(player, slot)

		if item then
			items[slot] = item:GetItemID()
		end
	end

	return items
end

local function updateState()
	state.wasOnBike = isOnBike()
	state.wasTransmog = isTransmog()
	state.lastOutfit = getLastOutfit()
	state.lastItems = getLastItems()
end

local function baseToEEX(base)
	if base == "Face" then
		return "AttachmentSlots.Eyes"
	elseif base == "Head" then
		return "AttachmentSlots.Head"
	end

	return nil
end

local function equipItems(items)
	local outfitSystem = getOutfitSystem()
	local transactionSystem = Game.GetTransactionSystem()

	for slot, item in pairs(items) do
		if BASE_SLOTS[slot] then
			if not state.wasTransmog then
				transactionSystem:AddItemToSlot(Game.GetPlayer(), baseToEEX(slot), item, true)
			end
		else
			outfitSystem:EquipItem(item)
		end
	end
end

local function unequipItems(items)
	local outfitSystem = getOutfitSystem()
	local transactionSystem = Game.GetTransactionSystem()

	for slot, item in pairs(items) do
		if BASE_SLOTS[slot] then
			transactionSystem:RemoveItemFromSlot(Game.GetPlayer(), baseToEEX(slot))
		else
			outfitSystem:UnequipItem(item)

			if EQUIPMENT_EX_SLOTS[slot] then
				outfitSystem:DetachVisualFromSlot(item, slot)
			end
		end
	end
end


registerInput("toggle_headgear", "Toggle Headgear", function (keypress)
	if keypress then
		if isOnBike() then
			if state.wasToggled then
				equipItems(state.items)
			else
				unequipItems(state.items)
			end

			state.wasToggled = not state.wasToggled
		end
	end
end)

registerForEvent("onInit", function ()
	state.items = getItems()

	ObserveAfter("EquipmentSystemPlayerData", "OnRestored", function ()
		updateState()
	end)

	ObserveBefore("VehicleComponent", "OnVehicleCameraChange", function ()
		if isOnBike() and not state.wasOnBike then
			updateState()
			unequipItems(state.lastItems)
			equipItems(state.items)
		end
	end)

	ObserveBefore("MotorcycleComponent", "OnUnmountingEvent", function ()
		if state.wasOnBike then
			local outfitSystem = getOutfitSystem()

			unequipItems(state.items)
			equipItems(state.lastItems)

			if state.lastOutfit then
				outfitSystem:LoadOutfit(state.lastOutfit)
			elseif not state.wasTransmog then
				outfitSystem:Deactivate()
			end

			state:reset()
		end
	end)
end)
