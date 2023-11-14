State = {}
State.__index = State


function State.new()
    local self = setmetatable({}, State)

    self.items = {}
    self.wasOnBike = false
    self.wasTransmog = false
    self.wasToggled = false
    self.lastOutfit = nil
    self.lastItems = {}

    return self
end

function State:reset()
    self.wasOnBike = false
    self.wasTransmog = false
    self.wasToggled = false
    self.lastOutfit = nil
    self.lastItems = {}
end


return State
