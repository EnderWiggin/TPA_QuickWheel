---@meta

---@class openmw.interfaces
---@field OSSC? openmw.interfaces.OSSC

---@class openmw.interfaces.OSSC
---@field isCasting fun():boolean
---@field triggerQuickCast fun(data:{item?:openmw.Object, spell?:openmw.core.Spell, ignoreUIMode: boolean})

---@alias OSSCCallInfo {item:openmw.Object, spell:openmw.core.Spell, ignoreUIMode: boolean, ignoreWorldPause: boolean}
---@alias OSSCEventInfo {item:string, spell:string, ignoreUIMode: boolean, ignoreWorldPause: boolean}