FrameworkImplementations = FrameworkImplementations or {}
FrameworkBridge = FrameworkBridge or {}

local function pickFramework()
    if Config.Framework ~= 'auto' and FrameworkImplementations[Config.Framework] then
        return FrameworkImplementations[Config.Framework]
    end

    for _, key in ipairs({ 'qbox', 'qbcore', 'esx' }) do
        local implementation = FrameworkImplementations[key]
        if implementation and implementation.isAvailable() then
            return implementation
        end
    end

    return nil
end

function FrameworkBridge.Init()
    local selected = pickFramework()
    if not selected then
        FrameworkBridge.Reset()
        FFUtils.Log('No supported framework is started - supported frameworks: qbox, qb-core, es_extended.')
        return false
    end

    FrameworkBridge.Active = selected
    if not FrameworkBridge.Active.init() then
        FFUtils.Log(('Configured framework bridge unavailable: %s'):format(selected.getName()))
        FrameworkBridge.Reset()
        return false
    end

    FFUtils.Log(('Framework bridge active: %s'):format(selected.getName()))
    return true
end

function FrameworkBridge.GetName()
    return FrameworkBridge.Active and FrameworkBridge.Active.getName() or 'none'
end

function FrameworkBridge.IsReady()
    return FrameworkBridge.Active ~= nil and FrameworkBridge.Active.isAvailable()
end

function FrameworkBridge.Reset()
    if FrameworkBridge.Active and FrameworkBridge.Active.reset then
        FrameworkBridge.Active.reset()
    end

    FrameworkBridge.Active = nil
end

function FrameworkBridge.GetPlayer(source)
    return FrameworkBridge.Active and FrameworkBridge.Active.getPlayer(source) or nil
end

function FrameworkBridge.GetIdentifier(source)
    return FrameworkBridge.Active and FrameworkBridge.Active.getIdentifier(source) or tostring(source)
end

function FrameworkBridge.GetCharacterName(source)
    return FrameworkBridge.Active and FrameworkBridge.Active.getCharacterName(source) or ('player_%s'):format(source)
end

function FrameworkBridge.AddMoney(source, account, amount)
    return FrameworkBridge.Active and FrameworkBridge.Active.addMoney(source, account, amount) or false
end
