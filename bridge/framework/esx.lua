FrameworkImplementations = FrameworkImplementations or {}

local bridge = {}
local ESX

local function getSharedObject()
    if GetResourceState('es_extended') ~= 'started' then
        ESX = nil
        return nil
    end

    if ESX then
        return ESX
    end

    if exports.es_extended and exports.es_extended.getSharedObject then
        ESX = exports.es_extended:getSharedObject()
    else
        TriggerEvent('esx:getSharedObject', function(obj)
            ESX = obj
        end)
    end

    return ESX
end

function bridge.isAvailable()
    return GetResourceState('es_extended') == 'started'
end

function bridge.init()
    return getSharedObject() ~= nil
end

function bridge.getName()
    return 'esx'
end

function bridge.reset()
    ESX = nil
end

function bridge.getPlayer(source)
    local obj = getSharedObject()
    if not obj or not obj.GetPlayerFromId then
        return nil
    end

    return obj.GetPlayerFromId(source)
end

function bridge.getIdentifier(source)
    local player = bridge.getPlayer(source)
    if not player then
        return tostring(source)
    end

    return player.identifier or (player.getIdentifier and player.getIdentifier()) or tostring(source)
end

function bridge.getCharacterName(source)
    local player = bridge.getPlayer(source)
    if not player then
        return ('player_%s'):format(source)
    end

    local name = (player.getName and player.getName()) or player.name
    if type(name) == 'string' and name ~= '' then
        return name
    end

    return ('player_%s'):format(source)
end

function bridge.addMoney(source, account, amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        return false
    end

    local player = bridge.getPlayer(source)
    if not player then
        return false
    end

    local accountName = account or 'money'
    if accountName == 'cash' then
        accountName = 'money'
    end

    if accountName == 'money' and player.addMoney then
        local ok, result = pcall(function()
            return player.addMoney(amount)
        end)

        if ok and result ~= false then
            return true
        end
    end

    if player.addAccountMoney then
        local ok, result = pcall(function()
            return player.addAccountMoney(accountName, amount, 'ff_deaddrops-reward')
        end)

        if ok and result ~= false then
            return true
        end
    end

    return false
end

FrameworkImplementations.esx = bridge
