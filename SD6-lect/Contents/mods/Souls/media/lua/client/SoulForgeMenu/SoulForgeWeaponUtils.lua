local Config = require("SoulForgeMenu/SoulForgedConfig")

WeaponUtils = {}

function WeaponUtils.logWeaponStats(stats)
    if not stats then
        print("[SoulForge][BaseStats] No stats available.")
        return
    end

    print("[SoulForge][BaseStats] ----- Weapon Stat Breakdown -----")
    print(string.format("Max Condition:          %s", tostring(stats.maxCondition)))
    print(string.format("Condition Lower Chance: %s", tostring(stats.condLowerChance)))
    print(string.format("Min Damage:             %s", tostring(stats.minDamage)))
    print(string.format("Max Damage:             %s", tostring(stats.maxDamage)))
    print(string.format("Critical Chance:        %s", tostring(stats.critChance)))
    print(string.format("Critical Multiplier:    %s", tostring(stats.critMult)))
    print("[SoulForge][BaseStats] ----------------------------------")
end

function WeaponUtils.isValidSoulForgeWeapon(item)
    if not item then
        print("[SoulForge][Validation] Item is nil")
        return false
    end

    local isWeapon = item:IsWeapon()
    local scriptItem = item:getScriptItem()
    local typeName = scriptItem and scriptItem:getType() or "nil"

    print(string.format("[SoulForge][Validation] %s | IsWeapon: %s | ScriptType: %s",
        item:getFullType(),
        tostring(isWeapon),
        tostring(typeName)
    ))

    return isWeapon and scriptItem and scriptItem:getType() ~= "None"
end

function WeaponUtils.getSoulCounts(weapon)
    if not weapon then
        print("[SoulForge] getSoulCounts: weapon is nil")
        return 0, math.huge
    end

    print("[SoulForge] --- modData dump for: " .. weapon:getFullType() .. " ---")
    local modData = weapon:getModData()
    for k, v in pairs(modData) do
        print(string.format("[SoulForge][modData] %s = %s", tostring(k), tostring(v)))
    end


    local modData = weapon:getModData()

    local stats = WeaponUtils.getBaseStats(weapon)
    print("[SoulForge] Base Stats - Init Check")
    WeaponUtils.logWeaponStats(stats)

    if not stats then return 0, math.huge end

    local soulsOwned = modData.KillCount or modData.SoulPower or 0

    local scriptItem = ScriptManager.instance:getItem(weapon:getFullType())
    local baseMin = scriptItem and scriptItem:getMinDamage() or 1
    local soulsRequired = math.floor(stats.maxCondition * stats.condLowerChance * baseMin) -- needs base min, not current min
    print("[Ely's Version]")
    print("Max Condition: " .. stats.maxCondition)
    print("Condition Lower Chance: " .. stats.condLowerChance)
    print("Min Damage: " .. weapon:getMinDamage())
    print("Souls Required: " .. soulsRequired)

    print(string.format("[SoulForge] Soul Power: %d / %d", soulsOwned, soulsRequired))
    return soulsOwned, soulsRequired
end

-- Utility function to resolve a stat with multiplier
local function resolveStat(scriptItem, modData, statKey, getterFunc, fallback)
    if not scriptItem or not getterFunc then
        print(string.format("[SoulForge][Resolve] Invalid getter for %s", statKey))
        return fallback
    end

    local success, base = pcall(getterFunc)
    if not success then
        print(string.format("[SoulForge][Resolve] Failed to get base for %s, using fallback %.2f", statKey, fallback))
        base = fallback
    end

    local modKey = Config.statMap[statKey]
    local multiplier = modData[modKey] or 1.0

    local result = base * multiplier

    print(string.format("[SoulForge][Resolve] %s: base=%.2f x mod=%.2f = %.2f", statKey, base, multiplier, result))

    return result
end


function WeaponUtils.getBaseStats(weapon)
    if not weapon then
        print("[SoulForge] getBaseStats: weapon is nil")
        return nil
    end

    local fullType = weapon:getFullType()
    local scriptItem = ScriptManager.instance:getItem(fullType)
    if not scriptItem then
        print("[SoulForge] getBaseStats: scriptItem not found for " .. fullType)
        return nil
    end

    local modData         = weapon:getModData()
    local stats           = {}

    -- Condition & Damage (safe on scriptItem)
    stats.maxCondition    = resolveStat(scriptItem, modData, "ConditionMax",
        function() return scriptItem:getConditionMax() end, 1)
    stats.condLowerChance = resolveStat(scriptItem, modData, "ConditionLowerChance",
        function() return scriptItem:getConditionLowerChance() end, 1)
    stats.minDamage       = resolveStat(scriptItem, modData, "MinDmg",
        function() return scriptItem:getMinDamage() end, 1)
    stats.maxDamage       = resolveStat(scriptItem, modData, "MaxDmg",
        function() return scriptItem:getMaxDamage() end, 1)

    -- Critical stats (may only exist on weapon)
    if weapon.getCriticalChance then
        stats.critChance = resolveStat(weapon, modData, "CriticalChance",
            function() return weapon:getCriticalChance() end, 0)
    else
        stats.critChance = 0
    end

    if weapon.getCriticalDamageMultiplier then
        stats.critMult = resolveStat(weapon, modData, "CritDmgMultiplier",
            function() return weapon:getCriticalDamageMultiplier() end, 1)
    else
        stats.critMult = 1
    end


    print("[SoulForge] Base Stats - Assignment Check (with multipliers)")
    WeaponUtils.logWeaponStats(stats)

    return stats
end

return WeaponUtils
