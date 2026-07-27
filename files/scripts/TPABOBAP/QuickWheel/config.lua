---@omw-context player

local async = require('openmw.async')
local storage = require('openmw.storage')

local main = storage.playerSection('TPA_QuickWheel/MainSettings')
local potions = storage.playerSection('TPA_QuickWheel/PotionSettings')
local magic = storage.playerSection('TPA_QuickWheel/MagicSettings')
local equip = storage.playerSection('TPA_QuickWheel/EquipSettings')
local C = require('scripts.TPABOBAP.QuickWheel.constants')

---@class EquipWheelCfg
---@field b_AutoClose boolean
---@field b_AutoReady boolean
---@field b_ForceEquip boolean
---@field b_ShieldsAreWeapons boolean
---@field b_FilledGemTools boolean

---@class QuickWheelConfig
---@field main {s_KeyMode: string, b_ShowWheelAnimation:boolean, s_TimeMode: string, s_ControllerMode: ControllerMode, s_ControllerStick: ControllerStick, n_ControllerDeadZone: number, n_HysteresisStrength: number}
---@field potions {b_NoUnknownCategory: boolean, b_FilterPoisons: boolean, b_QuickApplyPoison: boolean, s_SeparateAlcohol: AlcoholModes}
---@field magic {s_MagicClickMode: MagicClickModes, b_UseOSSC: boolean, n_MagicCastDelay: number, n_MagicCastCooldown: number, s_QueueWidgetPosition: QueueWidgetPosition, b_ShowQueueWidget: boolean}
---@field equip EquipWheelCfg
---@field controllerActive boolean
---@field shouldUseController fun(): boolean
local config = {
    main = main:asTable(),
    potions = potions:asTable(),
    magic = magic:asTable(),
    equip = equip:asTable(),
    controllerActive = false,
}

config.shouldUseController = function()
    local mode = config.main.s_ControllerMode
    if mode == C.ControllerMode.Exclusive then
        return true
    elseif mode == C.ControllerMode.Auto then
        return config.controllerActive
    end
    return false
end

main:subscribe(async:callback(function() config.main = main:asTable() end))
potions:subscribe(async:callback(function() config.potions = potions:asTable() end))
magic:subscribe(async:callback(function() config.magic = magic:asTable() end))
equip:subscribe(async:callback(function() config.equip = equip:asTable() end))

return config
