---@meta

---@class openmw.interfaces
---@field MagExp_Player? openmw.interfaces.MagExp_Player
---@field MagExp? openmw.interfaces.MagExp

---@class openmw.interfaces.MagExp_Player
---@field consumeSpellCost fun(spellId: string, item: openmw.Object?):boolean
---@field Helpers MagExpHelpers

---@class openmw.interfaces.MagExp
---@field Helpers MagExpHelpers

---@class MagExpHelpers
---@field getSpellCastChance fun(spellId: string, actor: openmw.Object, opts: {isGodMode: boolean?, cost: number, ignoreFatigue? : boolean?}?):number
