config = {}

function config.fileExists(filePath)
    local f = io.open(filePath, "r")
    if f == nil then return false end
    f:close()
    return true
end

function config.readJSON(filePath)
    local f = io.open(filePath, "r")
    local d = json.decode(f:read("*a"))
    f:close()
    return d
end

function config.writeJSON(filePath, data)
    local f = io.open(filePath, "w")
    local e = json.encode(data)
    f:write(e)
    f:close()
end

function config.updateJSON(filePath, data)
    local d = config.readJSON(filePath)

    for k, v in pairs(data) do
        if d[k] == nil then
            d[k] = v
        end
    end

    config.writeJSON(filePath, d)
end

return config
