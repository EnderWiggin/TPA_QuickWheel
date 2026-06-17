---@omw-context player

local async = require('openmw.async')
local storage = require('openmw.storage')

local main = storage.playerSection('TPA_QuickWheel/MainSettings')
local potions = storage.playerSection('TPA_QuickWheel/PotionSettings')
local magic = storage.playerSection('TPA_QuickWheel/MagicSettings')


---@class QuickWheelConfig
---@field main {s_KeyMode: string, s_TimeMode: string, b_ExclusiveController: boolean}
---@field potions {b_NoUnknownCategory: boolean, b_FilterPoisons: boolean, b_QuickApplyPoison: boolean, s_SeparateAlcohol: AlcoholModes}
---@field magic {s_MagicClickMode: MagicClickModes, b_UseOSSC: boolean, n_MagicCastDelay: number, n_MagicCastCooldown: number, s_QueueWidgetPosition: QueueWidgetPosition, b_ShowQueueWidget: boolean}
local config = {
    main = main:asTable(),
    potions = potions:asTable(),
    magic = magic:asTable(),
}

main:subscribe(async:callback(function() config.main = main:asTable() end))
potions:subscribe(async:callback(function() config.potions = potions:asTable() end))
magic:subscribe(async:callback(function() config.magic = magic:asTable() end))

return config
