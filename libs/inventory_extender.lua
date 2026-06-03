---@meta

---@class openmw.interfaces
---@field InventoryExtender? openmw.interfaces.InventoryExtender

---@class openmw.interfaces.InventoryExtender
---@field Templates openmw.interfaces.InventoryExtender.Templates
---@field getContext fun():any

---@class openmw.interfaces.InventoryExtender.Templates
---@field MAGIC openmw.interfaces.InventoryExtender.Templates.Magic

---@class openmw.interfaces.InventoryExtender.Templates.Magic
---@field itemTooltip fun(item: openmw.Object, showIcon: boolean, ctx: any):openmw.ui.Layout
