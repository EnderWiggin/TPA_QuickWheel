local async = require('openmw.async')
local storage = require('openmw.storage')

local main = storage.playerSection('TPA_QuickWheel/MainSettings')

---@type {main: {k_PotionWheel: number, s_KeyMode: string}}
local config = {

}

local function updateConfig()
    config.main = main:asTable()
end

updateConfig()
main:subscribe(async:callback(updateConfig))

return config