---@omw-context menu
local core = require('openmw.core')
local ui = require('openmw.ui')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local ambient = require('openmw.ambient')
local util = require('openmw.util')
local storage = require('openmw.storage')

local interfaceL10n = core.l10n('interface')
local bindingSection = storage.playerSection('OMWInputBindings')
local MWUI = I.MWUI.templates
local v2 = util.vector2
local TextDefault = MWUI.textNormal.props.textColor
local TextHighlight = MWUI.textHeader.props.textColor

--- Clears bindings listed under 'actions` from storage of 'inputBinding' OMW built-in renderer
---if both 'settings' list and 'section' name are supplied - refreshes those settings - useful to immediately display keybind changes
---actions must be what's in the 'default' for the input binding setting
---settings must be what's in the key of the input binding setting (not in the argument)
---@param args {actions:table<number, string>, settings:table<number, string>|nil, section:string|nil}
return function(_, _, args)
    local actions = args.actions
    local settings = args.settings
    local section = args.section and storage.playerSection(args.section)

    local element = ui.create {
        name = 'reset_button',
        template = MWUI.boxSolid,
        props = {},
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    { props = { size = v2(8, 0), }, },
                    {
                        template = MWUI.textNormal,
                        props = {
                            text = interfaceL10n('Reset'),
                            textColor = TextDefault,
                            textAlignV = ui.ALIGNMENT.Center,
                        },
                        userData = { colorable = true },
                    },
                    { props = { size = v2(8, 0), }, },
                }
            }
        },
        events = {},
        userData = {},
    }
    element.layout.events.focusGain = async:callback(function()
        element.layout.content[1].content[2].props.textColor = TextHighlight
        element:update()
    end)
    element.layout.events.focusLoss = async:callback(function()
        element.layout.content[1].content[2].props.textColor = TextDefault
        element:update()
    end)
    element.layout.events.mousePress = async:callback(function()
        ambient.playSound('menu click')
    end)
    element.layout.events.mouseRelease = async:callback(function()
        for i = 1, #actions do
            bindingSection:set(actions[i], nil)
        end
        if settings and section then
            for i = 1, #settings do
                local v = settings[i]
                section:set(v, section:get(v))
            end
        end
    end)

    return element
end
