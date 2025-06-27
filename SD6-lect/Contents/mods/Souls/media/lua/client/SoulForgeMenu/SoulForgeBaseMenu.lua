local SoulForgeBaseMenu = {}

local WeaponUtils = require("SoulForgeMenu/SoulForgeWeaponUtils")
local Config = require("SoulForgeMenu/SoulForgedConfig")             -- Optional, for constants
local TooltipUtils = require("SoulForgeMenu/SoulForgedTooltipUtils") -- Optional, for rich tooltips

-- Require Checkers
if not SoulForgeBaseMenu then
    print("[SoulForge][ERROR] Failed to load SoulForgeBaseMenu!")
    return
end

-- Calculate how many souls it costs to perform an action based on repair stack
local function calculateSoulDiff(soulsRequired, weaponRepairedStack)
    local factor = (math.min(7, weaponRepairedStack - 1) - 1) / 2
    return math.floor(soulsRequired / factor)
end

-- Update remaining Soul Power after action
local function getNewSoulPower(soulsFreed, soulsRequired, weaponRepairedStack)
    return math.max(0, soulsFreed - calculateSoulDiff(soulsRequired, weaponRepairedStack))
end

-- Compute target weapon condition after repairing
local function getNewWeaponCondition(weapon, maxCond, soulForgeMaxCondMult)
    local curCond = weapon:getCondition()
    local repairAmount = math.ceil(maxCond / 3.5 * soulForgeMaxCondMult)
    return math.floor(math.min(curCond + repairAmount, maxCond * soulForgeMaxCondMult) + 0.5)
end

local function addRepairStackOption(submenu, player, weapon, soulsFreed, soulsRequired, weaponRepairedStack)
    print("[SoulForge] addRepairStackOption()")

    local modData = weapon:getModData()
    local soulDiff = calculateSoulDiff(soulsRequired, weaponRepairedStack)
    local newSoulPower = getNewSoulPower(soulsFreed, soulsRequired, weaponRepairedStack)

    if weaponRepairedStack >= 5 then
        print("[SoulForge] repair stack check passed (>=5)")
        submenu:addOption(
            "Remove 1x repair stack (-" ..
            soulDiff .. " souls). New Soul Power: " .. newSoulPower .. "/" .. soulsRequired,
            weapon,
            function()
                weapon:setHaveBeenRepaired(weaponRepairedStack - 2)
                modData.KillCount = newSoulPower
            end,
            player
        )
    else
        local option = submenu:addOption("Requires 4x repair stacks to remove", weapon, nil)
        option.notAvailable = true
        TooltipUtils.attachSimpleTooltip(option, "Repair Stack", "Requires 4x repair stacks.",
            TooltipUtils.getActionColor("Repair"))
    end
end

local function addConditionRepairOption(submenu, player, weapon, soulsFreed, soulsRequired, weaponRepairedStack)
    local modData = weapon:getModData()
    local soulDiff = calculateSoulDiff(soulsRequired, weaponRepairedStack)
    local newSoulPower = getNewSoulPower(soulsFreed, soulsRequired, weaponRepairedStack)

    local maxCond = ScriptManager.instance:getItem(weapon:getFullType()):getConditionMax()
    local forgeMult = modData.MaxCondition or 1.0
    local permaMult = player:getModData().PermaMaxConditionBonus or 1.0
    local totalMult = forgeMult * permaMult

    local newCond = getNewWeaponCondition(weapon, maxCond, totalMult)
    local maxCondAdj = math.floor(maxCond * totalMult + 0.5)

    if weaponRepairedStack >= 5 then
        submenu:addOption(
            "Repair weapon to: " .. newCond .. "/" .. maxCondAdj ..
            " (-" .. soulDiff .. " souls). New Soul Power: " .. newSoulPower .. "/" .. soulsRequired,
            weapon,
            function()
                weapon:setCondition(newCond)
                modData.KillCount = newSoulPower
            end,
            player
        )
    else
        local option = submenu:addOption("Requires 4x repair stacks to restore condition", weapon, nil)
        option.notAvailable = true
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = "This weapon is still serviceable. Higher repair stack requires less souls to mend."
        option.toolTip = tooltip
    end
end

function SoulForgeBaseMenu.injectMenu(submenu, player, weapon, soulsFreed, soulsRequired, weaponRepairedStack)
    print("[SoulForge] injectMenu() called")
    print("[SoulForge] weapon = " .. tostring(weapon:getFullType()))
    print("[SoulForge] soulsFreed = " .. tostring(soulsFreed))
    print("[SoulForge] soulsRequired = " .. tostring(soulsRequired))
    print("[SoulForge] weaponRepairedStack = " .. tostring(weaponRepairedStack))

    addRepairStackOption(submenu, player, weapon, soulsFreed, soulsRequired, weaponRepairedStack)
    addConditionRepairOption(submenu, player, weapon, soulsFreed, soulsRequired, weaponRepairedStack)
end

return SoulForgeBaseMenu
