---@omw-context player

local async = require('openmw.async')
local storage = require('openmw.storage')

local main = storage.playerSection('TPA_QuickWheel/MainSettings')
local potions = storage.playerSection('TPA_QuickWheel/PotionSettings')
local magic = storage.playerSection('TPA_QuickWheel/MagicSettings')


---@class QuickWheelConfig
---@field main {s_KeyMode: string, s_TimeMode: string}
---@field potions {b_NoUnknownCategory: boolean}
---@field magic {s_MagicClickMode: MagicClickModes}
local config = {
    main = main:asTable(),
    potions = potions:asTable(),
    magic = magic:asTable(),
}

local function updateConfig()

end

updateConfig()
main:subscribe(async:callback(function() config.main = main:asTable() end))
potions:subscribe(async:callback(function() config.potions = potions:asTable() end))
magic:subscribe(async:callback(function() config.magic = magic:asTable() end))

return config
