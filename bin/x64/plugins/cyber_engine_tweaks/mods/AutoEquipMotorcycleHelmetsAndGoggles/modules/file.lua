File = {}




function File.exists(filePath)
    local f = io.open(filePath, "r")

    if not f then
        return false
    end

    f:close()
    return true
end


function File.readJSON(filePath)
    local f = io.open(filePath, "r")
    
    if not f then
        return nil
    end

    local d = json.decode(f:read("*a"))
    f:close()
    return d
end


function File.writeJSON(filePath, data)
    local f = io.open(filePath, "w")
    
    if not f then
        return
    end

    local e = json.encode(data)
    f:write(e)
    f:close()
end




return File
