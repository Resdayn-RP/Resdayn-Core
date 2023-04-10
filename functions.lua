---@class functions
---@field coolDowns table
local functions = {}

---@param seconds integer The amount of seconds you wish to hold the script by
function functions.wait(seconds)
    local clock = os.clock
    local t0 = clock()
    while clock() - t0 <= seconds do end
end

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

---@param source integer Source Player ID
---@return integer closestPid closest player's ID
function functions.getClosestPlayer(source)
    local sourceCoords = functions.getPlayerCoords(source)
    local closestPid, closestCoords
    for pid in pairs(Players) do
        if pid ~= source then
            if functions.getDistanceBetweenCoords(functions.getPlayerCoords(pid), sourceCoords) < closestCoords or not closestCoords then
                closestPid = pid
                closestCoords = functions.getPlayerCoords(pid)
            end
        end
    end
    return closestPid
end

---@return integer
function functions.generateDbID()
    local id = math.random(0, 999)
    repeat
        id = math.random(0, 999)
    until functions.checkForUniqueID(id)
    return id
end

---Check if person is a member of the given faction
---@param dbId integer DatabaseID
---@param faction string representing requested faction
---@return boolean indicating faction membership
function functions.checkFactionStatus(dbId, faction)
    local playerTables = HebiDB:getTable()
    local factionRequested = "is" .. faction:gsub("^%l", string.upper)
    for _, Table in pairs(playerTables) do
        for _, player in pairs(Table) do
            if player.dbid == dbId then
	      return player[factionRequested] or false
            end
        end
    end
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
    local playerTable = HebiDB:getTable()
    for _, Table in pairs(playerTable) do
        for _, player in pairs(Table) do
            if player.dbid == dbid then
                return player.money
            end
        end
    end
end

---@param dbid integer
function functions.changeDeathStatus(dbid)
    local playerTable = HebiDB.Table
    for _, Table in pairs(playerTable) do
        for _, player in pairs(Table) do
            if player.dbid == dbid then
                player.isDead = not player.isDead
            end
        end
    end
end

---@param dbid integer
---@return boolean IsDead?
function functions.getDeathStatus(dbid)
    local playerTable = HebiDB:getTable()
    for _, Table in pairs(playerTable) do
        for _, player in pairs(Table) do
            if player.dbid == dbid then
                return player.isDead
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

---@param eventStatus table
---@param playerPacket table
---@return boolean didChange
function functions.checkForSpellStackingChanges(eventStatus, playerPacket)
    local didChange = false

    if eventStatus.validDefaultHandler then return false end

    for spellId, spellInstances in pairs(playerPacket.spellsActive) do
        for key, spellInstance in ipairs(spellInstances) do
            if spellInstance.stackingState then
                playerPacket.spellsActive[spellId][key].stackingState = false
                didChange = true
            end
        end
    end

    return didChange
end

---@param eventStatus table
---@param pid integer
---@param playerPacket table
function functions.disableDuplicateMagicEffects(eventStatus, pid, playerPacket)
    local didChange = functions.checkForSpellStackingChanges(eventStatus, playerPacket) 

    if not didChange then return customEventHooks.makeEventStatus(nil, nil) end

    Players[pid]:SaveSpellsActive(playerPacket)
    Players[pid]:LoadSpellsActive()

    return customEventHooks.makeEventStatus(false, nil)
end

---@param player string
---@param refId string item reference id
---@return boolean hasPick
function functions.itemCheck(player, refId)
    if not inventoryHelper.getItemIndex(player.data.inventory, refId, -1) then
        return false
    end
    return true
end

---@param player table
---@param refId string
---@param amount integer
function functions.addItem(player, refId, amount)
    inventoryHelper.addItem(player.data.inventory, refId, amount, -1, -1, "")
    player:LoadInventory()
    player:LoadEquipment()
    player:QuicksaveToDrive()
end

---@param name string
---@param magnitude integer size of burden
function functions.createBurdenSpell(name, magnitude)
    local recordStore = RecordStores["spell"]
    recordStore.data.permanentRecords["burden_enable"] = {
		name = name,
		subtype = 1,
		cost = 0,
		flags = 0,
		effects = {
			{
				attribute = -1,
				area = 0,
				duration = 10,
				id = 7,
				rangeType = 0,
				skill = -1,
				magnitudeMin = magnitude,
				magnitudeMax = magnitude
			}
		}
	}
	recordStore:Save()
end

function functions.coolDown(pid, time)
    local sysTime = os.time()
    if functions.coolDowns[pid] and sysTime - functions.coolDowns[pid] < time then return true end
    functions.coolDowns[pid] = time
    return false
end

---@param pid integer PlayerID
function functions.updatePlayerSpellbook(pid)
    Players[pid]:LoadSpellbook()
end

---@param pid integer PlayerID
---@param id string Spell ID
---@param action integer Add/Remove
function functions.sendSpell(pid, id, action)
    tes3mp.ClearSpellbookChanges(pid)
    tes3mp.SetSpellbookChangesAction(pid, action)
    tes3mp.AddSpell(pid, id)
    tes3mp.SendSpellbookChanges(pid)
end

return functions
