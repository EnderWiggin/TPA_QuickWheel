---@omw-context player
local Icon = require('scripts.TPABOBAP.QuickWheel.icons.base_icon')

---@class CategoryIcon: Icon
---@field public name string
---@field public provider fun():any[]
---@field public quickUse boolean
local CategoryIcon = Icon:new()


return CategoryIcon
