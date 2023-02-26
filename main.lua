---@class core
local core = {}

core.functions = require 'custom.resdaynCore.functions'
core.tableConfig, core.config = require 'custom.resdaynCore.config'

---@param pid integer
function core.setupNewPlayer(pid)
    local player = core.tableConfig['players']
    player.dbid = core.functions.generateDbID()
    player.money = 500
    player.name = Players[pid].name
    HebiDB:insertToTable('players', { player })
end

---@param pid integer
---@param eventStatus table Unused but necessary
function core.onLogin(eventStatus, pid)
    if core.functions.getDbID(Players[pid].name) then return end
    if core.config.logsEnabled then core.functions.log("Player Entry Not Found, Creating Player") end
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

customCommandHooks.registerCommand("cash", core.moneyCommand)

customEventHooks.registerValidator("OnObjectDialogueChoice", core.functions.disableTradersTrainers)
customEventHooks.registerValidator("OnPlayerSpellsActive", core.functions.disableDuplicateMagicEffects)

customEventHooks.registerHandler("OnPlayerFinishLogin", core.onLogin)
customEventHooks.registerHandler("OnPlayerDisconnect", core.onDisconnect)

return core