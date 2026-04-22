FrameworkImplementations = FrameworkImplementations or {}

local bridge = {}
local QBCore

local function getCore()
    if GetResourceState('qb-core') ~= 'started' then
        QBCore = nil
        return nil
    end

    if QBCore then
        return QBCore
    end

    if exports['qb-core'] and exports['qb-core'].GetCoreObject then
        QBCore = exports['qb-core']:GetCoreObject()
    end

    return QBCore
end

function bridge.isAvailable()
    return GetResourceState('qb-core') == 'started'
end

function bridge.init()
    return getCore() ~= nil
end

function bridge.getName()
    return 'qbcore'
end

function bridge.reset()
    QBCore = nil
end

function bridge.getPlayer(source)
    local core = getCore()
    return core and core.Functions.GetPlayer(source) or nil
end

function bridge.getIdentifier(source)
    local player = bridge.getPlayer(source)
    if not player then
        return tostring(source)
    end

    return player.PlayerData and (player.PlayerData.citizenid or player.PlayerData.license) or tostring(source)
end

function bridge.getCharacterName(source)
    local player = bridge.getPlayer(source)
    if not player then
        return ('player_%s'):format(source)
    end

    local charInfo = player.PlayerData and player.PlayerData.charinfo or {}
    return ('%s %s'):format(charInfo.firstname or 'Player', charInfo.lastname or source)
end

function bridge.addMoney(source, account, amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        return false
    end

    local player = bridge.getPlayer(source)
    if not player or not player.Functions or not player.Functions.AddMoney then
        return false
    end

    local moneyType = account or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end

    local ok, result = pcall(function()
        return player.Functions.AddMoney(moneyType, amount, 'ff_deaddrops-reward')
    end)

    return ok and result ~= false
end

FrameworkImplementations.qbcore = bridge
