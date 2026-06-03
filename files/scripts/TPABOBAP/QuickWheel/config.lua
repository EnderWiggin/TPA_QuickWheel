---@omw-context player

local async = require('openmw.async')
local storage = require('openmw.storage')

local main = storage.playerSection('TPA_QuickWheel/MainSettings')

---@type {main: {s_KeyMode: string, s_TimeMode: string, b_NoUnknownCategory: boolean}}
local config = {

}

local function updateConfig()
    config.main = main:asTable()
end

updateConfig()
main:subscribe(async:callback(updateConfig))

return config