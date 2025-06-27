MainMenu = {}

local WeaponUtils = require("SoulForgeMenu/SoulForgeWeaponUtils")

-- Menus that are added
local SoulForgeBaseMenu = require("SoulForgeMenu/SoulForgeBaseMenu")


function MainMenu.addContextMenu(player, context, items)
    print("[SoulForge] addContextMenu called")

    local playerObj = getSpecificPlayer(player)
    local weapon = playerObj and playerObj:getPrimaryHandItem()

    if weapon then
        print("[SoulForge] Held item: " .. weapon:getFullType())
    else
        print("[SoulForge] No item in primary hand")
        return
    end

    if not WeaponUtils.isValidSoulForgeWeapon(weapon) then
        print("[SoulForge] Held item is not a valid SoulForged weapon")
        return
    end

    print("[SoulForge] Injecting SoulForge menu")

    local soulsOwned, soulsRequired = WeaponUtils.getSoulCounts(weapon)

    if soulsOwned >= soulsRequired then
        local label = string.format("Soul Power [Test]: %d/%d", soulsOwned, soulsRequired)
        local option = context:addOption(label)
        local submenu = ISContextMenu:getNew(context)
        context:addSubMenu(option, submenu)

        -- Inject base enhancement submenu
        SoulForgeBaseMenu.injectMenu(submenu, player, weapon, soulsOwned, soulsRequired, weapon:getHaveBeenRepaired())
        -- SoulForgeForgingMenu.injectMenu(subMenu, player, weapon) (WIP)
        -- SoulForgeQualityMenu.injectMenu(subMenu, player, weapon) (WIP)
    else
        local option = context:addOption(string.format("Soul Power [Test]: %d/%d", soulsOwned, soulsRequired))
        option.notAvailable = true

        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = "<RGB:1,0.3,0.3> Free more souls."
        option.toolTip = tooltip
    end
end

return MainMenu
