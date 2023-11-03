file = {}

function file.fileExists(filePath)
    local f = io.open(filePath, "r")
    if f == nil then return false end
    f:close()
    return true
end

function file.readJSON(filePath)
    local f = io.open(filePath, "r")
    local d = json.decode(f:read("*a"))
    f:close()
    return d
end

function file.writeJSON(filePath, data)
    local f = io.open(filePath, "w")
    local e = json.encode(data)
    f:write(e)
    f:close()
end

function file.updateJSON(filePath, data)
    local d = file.readJSON(filePath)

    for k, v in pairs(data) do
        if d[k] == nil then
            d[k] = v
        end
    end

    file.writeJSON(filePath, d)
end

return file
