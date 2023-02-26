---@class functions
local functions = {}

---@func log message to console
---@param message string The message that is sent to log
---@return nil
function functions.log(message)
    tes3mp.LogMessage(enumerations.log.VERBOSE, "[ rCORE ]: " .. message)
end

---@param pid integer
---@return table playerCoords
function functions.getPlayerCoords(pid)
    return {x = tes3mp.GetPosX(pid), y = tes3mp.GetPosY(pid), z = tes3mp.GetPosZ(pid)}
end

---@param pos1 table
---@param pos2 table
---@return integer displacement
function functions.getDistanceBetweenCoords(pos1, pos2)
    return math.sqrt((pos1.x - pos2.x)^2 + (pos1.y - pos2.y)^2 + (pos1.z - pos2.z)^2)
end

---@return integer
function functions.generateDbID()
    local id = math.random(0, 999)
    repeat
        id = math.random(0, 999)
    until functions.checkForUniqueID(id)
    return id
end

---@param id integer
---@return boolean isUnique
function functions.checkForUniqueID(id)
    local playerTable = HebiDB:getTable()
    for _, Table in pairs(playerTable) do
        for _, player in pairs(Table) do
            if player.dbid == id then return false end
        end
    end
    return true
end

---@param name string
---@return integer|nil dbid
function functions.getDbID(name)
    local playerTable = HebiDB:getTable()
    for _, Table in pairs(playerTable) do
        for _, player in pairs(Table) do
            if player.name == name then return player.dbid end
        end
    end
    return nil
end     

---@param dbid integer
---@param amount integer
function functions.addMoney(dbid, amount)
    local playerTable = HebiDB.Table
    for _, Table in pairs(playerTable) do
        for _, player in pairs(Table) do
            if player.dbid == dbid then
                player.money = player.money + amount
            end
        end
    end
end

---@param dbid integer
---@param amount integer
function functions.removeMoney(dbid, amount)
    local playerTable = HebiDB.Table
    for _, Table in pairs(playerTable) do
        for _, player in pairs(Table) do
            if player.dbid == dbid then
                player.money = player.money - amount
            end
        end
    end
end

---@param dbid integer
---@return integer player.money
function functions.getBalance(dbid)
    local playerTable = HebiDB.Table
    for _, Table in pairs(playerTable) do
        for _, player in pairs(Table) do
            if player.dbid == dbid then
                return player.money
            end
        end
    end
end

---@param pid integer
---@param id integer
---@param message string
function functions.SendMessage(pid, id, message)
    tes3mp.CustomMessageBox(pid, id, message)
end

---@param eventStatus table
---@param pid integer
---@param cellDescription integer
---@param objects table
function functions.disableTradersTrainers(eventStatus, pid, cellDescription, objects)
    if not (Players[pid] or Players[pid]:IsLoggedIn()) then return end
    
    local ObjectIndex
    local ObjectRefid
    local ObjectDialogue 

    for _, object in pairs(objects) do
        ObjectIndex = object.uniqueIndex
        ObjectRefid = object.refId
        ObjectDialogue = object.dialogueChoiceType
    end
        
    if not (ObjectIndex and ObjectRefid) then return end
    if ObjectDialogue ~= 8 and ObjectDialogue ~= 3 then return end

    return customEventHooks.makeEventStatus(false, false)
end

return functions