FrameworkImplementations = FrameworkImplementations or {}

local bridge = {}

function bridge.isAvailable()
    return GetResourceState('qbx_core') == 'started'
end

function bridge.init()
    return bridge.isAvailable()
end

function bridge.getName()
    return 'qbox'
end

function bridge.getPlayer(source)
    if exports.qbx_core and exports.qbx_core.GetPlayer then
        return exports.qbx_core:GetPlayer(source)
    end

    return nil
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

    local moneyType = account or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end

    local player = bridge.getPlayer(source)
    if player and player.Functions and player.Functions.AddMoney then
        local ok, result = pcall(function()
            return player.Functions.AddMoney(moneyType, amount, 'ff_deaddrops-reward')
        end)

        if ok and result ~= false then
            return true
        end
    end

    if exports.qbx_core and exports.qbx_core.AddMoney then
        local ok, result = pcall(function()
            return exports.qbx_core:AddMoney(source, moneyType, amount, 'ff_deaddrops-reward')
        end)

        return ok and result ~= false
    end

    return false
end

FrameworkImplementations.qbox = bridge
