InventoryImplementations = InventoryImplementations or {}

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

local function getInventory()
    if GetResourceState('qb-inventory') ~= 'started' then
        return nil
    end

    return exports['qb-inventory']
end

local function callInventoryExport(exportName, ...)
    local inventory = getInventory()
    if not inventory or not inventory[exportName] then
        return false
    end

    local ok, result, extra = pcall(function(...)
        return inventory[exportName](inventory, ...)
    end, ...)

    if not ok then
        return false
    end

    return result, extra
end

local function getPlayer(source)
    local core = getCore()
    return core and core.Functions and core.Functions.GetPlayer(source) or nil
end

local function resolveUsableHandler(handler)
    if type(handler) == 'function' then
        return handler, nil, nil, true
    end

    if type(handler) ~= 'table' then
        return nil, nil, nil, true
    end

    return handler.beforeUse or handler.validate,
        handler.afterConsume or handler.onConsumed,
        handler.onConsumeFailed or handler.consumeFailed,
        handler.consume ~= false
end

function bridge.isAvailable()
    return getCore() ~= nil and getInventory() ~= nil
end

function bridge.getName()
    return 'qb_inventory'
end

function bridge.reset()
    QBCore = nil
end

function bridge.registerUsableItem(itemName, handler)
    local core = getCore()
    if not core or not core.Functions then
        return false
    end

    local beforeUse, afterConsume, onConsumeFailed, shouldConsume = resolveUsableHandler(handler)
    if not beforeUse and not afterConsume then
        return false
    end

    local register = core.Functions.CreateUseableItem or core.Functions.CreateUsableItem
    if not register then
        return false
    end

    register(itemName, function(source, item)
        if beforeUse then
            local used = beforeUse(source, item)
            if used ~= true then
                return
            end
        end

        if shouldConsume ~= false then
            local slot = type(item) == 'table' and item.slot or false
            local removed = bridge.removeItem(source, itemName, 1, nil, slot, 'ff_deaddrops-item-used')
            if not removed then
                if type(onConsumeFailed) == 'function' then
                    onConsumeFailed(source, item)
                end

                if FFUtils and FFUtils.Log then
                    FFUtils.Log(('qb_inventory could not remove used item %s from player %s'):format(itemName, source))
                end

                return
            end
        end

        if not afterConsume then
            return
        end

        local committed = afterConsume(source, item)
        if committed == true then
            return
        end

        if shouldConsume ~= false then
            local metadata = type(item) == 'table' and (item.info or item.metadata) or nil
            local restored = bridge.addItem(source, itemName, 1, metadata)
            if not restored and FFUtils and FFUtils.Log then
                FFUtils.Log(('qb_inventory could not restore used item %s for player %s after post-consume failure'):format(itemName, source))
            end
        end
    end)

    return true
end

function bridge.search(source, searchType, itemName)
    if searchType ~= 'count' then
        return nil
    end

    local count = callInventoryExport('GetItemCount', source, itemName)
    if type(count) == 'number' then
        return count
    end

    local item = callInventoryExport('GetItemByName', source, itemName)
    if type(item) == 'table' then
        return tonumber(item.amount) or tonumber(item.count) or 0
    end

    local player = getPlayer(source)
    if player and player.Functions and player.Functions.GetItemByName then
        item = player.Functions.GetItemByName(itemName)
        if type(item) == 'table' then
            return tonumber(item.amount) or tonumber(item.count) or 0
        end
    end

    return 0
end

function bridge.removeItem(source, itemName, count, metadata, slot, reason)
    local removed = callInventoryExport('RemoveItem', source, itemName, count or 1, slot or false, reason or 'ff_deaddrops-remove')
    if removed ~= false and removed ~= nil then
        return removed == true
    end

    local player = getPlayer(source)
    if player and player.Functions and player.Functions.RemoveItem then
        return player.Functions.RemoveItem(itemName, count or 1, slot or false, reason or 'ff_deaddrops-remove') == true
    end

    return false
end

function bridge.addItem(source, itemName, count, metadata)
    local added = callInventoryExport('AddItem', source, itemName, count or 1, false, metadata or false, 'ff_deaddrops-reward')
    if added ~= false and added ~= nil then
        return added == true
    end

    local player = getPlayer(source)
    if player and player.Functions and player.Functions.AddItem then
        return player.Functions.AddItem(itemName, count or 1, false, metadata or false, 'ff_deaddrops-reward') == true
    end

    return false
end

function bridge.canCarryItem(source, itemName, count)
    local canAdd = callInventoryExport('CanAddItem', source, itemName, count or 1)
    if type(canAdd) == 'boolean' then
        return canAdd
    end

    return true
end

InventoryImplementations.qb_inventory = bridge
