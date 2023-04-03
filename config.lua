---@class tableConfig
local tableConfig = {}

tableConfig['players'] = {
        name = nil,
        dbid = nil,
        money = nil,
        isDead = false,
        spells = {}
}

---@class config
local config = {}

config.logsEnabled = true

return tableConfig, config 