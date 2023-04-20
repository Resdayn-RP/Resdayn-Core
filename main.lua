---@class core
---@field isDead table
local core = {}

core.functions = require 'custom.resdaynCore.functions'
core.tableConfig, core.config = require 'custom.resdaynCore.config'

---@param pid integer
function core.setupNewPlayer(pid)
    local player = core.tableConfig['players']
    player.dbid = core.functions.generateDbID()
    player.money = 500
    player.isDead = false
    player.job = ""
    player.name = Players[pid].name
    HebiDB:insertToTable('players', { player })
end

---@param pid integer
---@param eventStatus table Unused but necessary
function core.onLogin(eventStatus, pid)
    if core.functions.getDbID(Players[pid].name) then return end
    core.setupNewPlayer(pid)
end

---@param pid integer
---@param eventStatus table Unused but necessary
function core.onDisconnect(eventStatus, pid)
    HebiDB:writeTable()
end

---@param pid integer
function core.moneyCommand(pid)
    local dbID = core.functions.getDbID(Players[pid].name)
    if not dbID then tes3mp.SendMessage(pid, "Can't find balance", false) return end
    local balance = core.functions.getBalance(dbID)
    local message = "Your balance is " .. tostring(balance) .. " septims  \n"
    tes3mp.SendMessage(pid, message, false)
end


---@param source integer Player ID
---@param target integer Target Player ID
---@param amount number Amount of money to transfer
function core.giveMoney(source, target, amount)
    local sourceDbId, targetDbId = core.functions.getDbId(Players[source].name), core.functions(Players[target].name)
    if not (sourceDbId or targetDbId) then
        tes3mp.SendMessage(source, "Can't find players.", false)
        return
    end
    
    local sCoords, tCoords = core.functions.getPlayerCoords(source), core.functions.getPlayerCoords(target)
    if #(sCoords - tCoords) < 10 then
        tes3mp.SendMessage(source, "Too far from target player.", false)
        return
    end

    core.functions.removeMoney(source, amount)
    core.functions.addMoney(target, amount)
end

function core.deathEventValidator(eventStatus, pid)
    eventStatus.validDefaultHandler = false
    return eventStatus
end

--- Death Handler - We want a basic medical system. Keep Player in Place Until Revive.
---@param eventStatus table
---@param pid integer Player ID
function core.onPlayerDeath(eventStatus, pid)
    local dbId = core.functions.getDbID(Players[pid].name)
    if not dbId then return end

    core.isDead[pid] = true
    core.functions.changeDeathStatus(dbId)
    
    core.functions.sendSpell(pid, "burden_enable", enumerations.spellbook.ADD)
    repeat
        core.functions.wait(0)
    until not (core.isDead[pid] or core.functions.coolDown(pid, 30))
    core.functions.sendSpell(pid, "burden_enable", enumerations.spellbook.REMOVE)
end

function core.reviveCommand(pid, target)
    if not target[2] then return end
    
    target = tonumber(target[2])
    if not core.functions.isPlayerOnline(target) or target == pid or target < 1 then
        tes3mp.SendMessage(pid, "Could not find player(s). \n", false)
        return
    end
    
    local sDbId = core.functions.getDbID(Players[pid].name)
    local tDbId = core.functions.getDbID(Players[target].name)

    if #(core.functions.getPlayerCoords(pid) - core.functions.getPlayerCoords(target)) > 1 then
        tes3mp.SendMessage(pid, "You are not close enough to revive. \n", false)
        return
    end

    if not core.functions.checkMedicStatus(sDbId) then
        tes3mp.SendMessage(pid, "You are not a medic. \n", false)
        return
    end

    tes3mp.SendMessage(pid, "Reviving Player \n", false)
    core.functions.sendSpell(pid, "burden_enable", enumerations.spellbook.ADD)
    core.functions.wait(10)
    core.functions.changeDeathStatus(tDbId)
    core.isDead[target] = not core.isDead[target]
    core.functions.sendSpell(pid, "burden_enable", enumerations.spellbook.REMOVE)
end

function core.OnServerPostInit()
    core.functions.createBurdenSpell("Dead", 900)
end

---@param pid integer Player invoking the command
---@param cmd string command requested referring to a specific PID
function core.checkPlayerJob(pid, cmd)
  if Players[pid].data.settings.staffRank < 1 then return end
  if not cmd[2] then return end

  if not Players[tonumber(cmd[2])] then
    tes3mp.SendMessage(pid, "Player not found.\n")
    return
  end

  local playerName = Players[tonumber(cmd[2])].name
  local dbId = core.functions.getDbID(playerName)

  requestedFactionStatus = core.functions.checkJob(dbId)

  local message = playerName

  if requestedFactionStatus == "" then
    message = message .. " has no job.\n"
  else
    message = message .. "'s current job is " .. requestedFactionStatus .. "\n"
  end

  tes3mp.SendMessage(pid, message, false)

end

function core.playerCoordsCommand(pid)
    tes3mp.SendMessage(pid, tostring(core.functions.getPlayerCoords(pid)) .. '\n', false)
end

customCommandHooks.registerCommand("cash", core.moneyCommand)
customCommandHooks.registerCommand("givemoney", core.giveMoney)
customCommandHooks.registerCommand("revive", core.reviveCommand)
customCommandHooks.registerCommand("job", core.checkPlayerJob)
customCommandHooks.registerCommand("coords", core.playerCoordsCommand)

customEventHooks.registerValidator("OnObjectDialogueChoice", core.functions.disableTradersTrainers)
customEventHooks.registerValidator("OnPlayerSpellsActive", core.functions.disableDuplicateMagicEffects)
customEventHooks.registerValidator("OnPlayerDeath", core.deathEventValidator)

customEventHooks.registerHandler("OnPlayerDeath", core.onPlayerDeath)
customEventHooks.registerHandler("OnServerPostInit", core.OnServerPostInit)
customEventHooks.registerHandler("OnPlayerFinishLogin", core.onLogin)
customEventHooks.registerHandler("OnPlayerDisconnect", core.onDisconnect)

return core
