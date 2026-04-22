InventoryImplementations = InventoryImplementations or {}

local function getOx()
    if GetResourceState('ox_inventory') ~= 'started' then
        return nil
    end

    return exports.ox_inventory
end

local bridge = {}

function bridge.isAvailable()
    return getOx() ~= nil
end

function bridge.getName()
    return 'ox_inventory'
end

function bridge.registerUsableItem()
    return bridge.isAvailable()
end

function bridge.search(source, searchType, itemName, metadata)
    local ox = getOx()
    if not ox or not ox.Search then
        return nil
    end

    return ox:Search(source, searchType, itemName, metadata)
end

function bridge.removeItem(source, itemName, count, metadata, slot)
    local ox = getOx()
    if not ox or not ox.RemoveItem then
        return false
    end

    return ox:RemoveItem(source, itemName, count or 1, metadata, slot)
end

function bridge.addItem(source, itemName, count, metadata)
    local ox = getOx()
    if not ox or not ox.AddItem then
        return false
    end

    return ox:AddItem(source, itemName, count or 1, metadata)
end

function bridge.canCarryItem(source, itemName, count, metadata)
    local ox = getOx()
    if not ox or not ox.CanCarryItem then
        return true
    end

    return ox:CanCarryItem(source, itemName, count or 1, metadata)
end

InventoryImplementations.ox_inventory = bridge
