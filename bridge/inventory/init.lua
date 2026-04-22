InventoryBridge = InventoryBridge or {}
InventoryImplementations = InventoryImplementations or {}

local function normalizeInventoryName(name)
    if type(name) ~= 'string' then
        return 'auto'
    end

    name = name:lower():gsub('%-', '_')
    if name == 'ox' then
        return 'ox_inventory'
    end
    if name == 'qb' then
        return 'qb_inventory'
    end

    return name
end

local function pickInventory()
    local configured = normalizeInventoryName(Config.Inventory)
    if configured ~= 'auto' then
        return InventoryImplementations[configured]
    end

    for _, key in ipairs({ 'ox_inventory', 'qb_inventory' }) do
        local implementation = InventoryImplementations[key]
        if implementation and implementation.isAvailable() then
            return implementation
        end
    end

    return nil
end

function InventoryBridge.Init()
    local selected = pickInventory()
    if not selected then
        InventoryBridge.Reset()
        return false
    end

    InventoryBridge.Active = selected
    if not InventoryBridge.Active.isAvailable() then
        FFUtils.Log(('Configured inventory bridge unavailable: %s'):format(selected.getName()))
        InventoryBridge.Reset()
        return false
    end

    FFUtils.Log(('Inventory bridge active: %s'):format(selected.getName()))
    return true
end

function InventoryBridge.GetName()
    return InventoryBridge.Active and InventoryBridge.Active.getName() or 'none'
end

function InventoryBridge.IsReady()
    return InventoryBridge.Active ~= nil and InventoryBridge.Active.isAvailable()
end

function InventoryBridge.Reset()
    if InventoryBridge.Active and InventoryBridge.Active.reset then
        InventoryBridge.Active.reset()
    end

    InventoryBridge.Active = nil
end

function InventoryBridge.RegisterUsableItem(itemName, handler)
    if not InventoryBridge.Active or not InventoryBridge.Active.registerUsableItem then
        return false
    end

    return InventoryBridge.Active.registerUsableItem(itemName, handler)
end

function InventoryBridge.Search(source, searchType, itemName, metadata)
    if not InventoryBridge.Active or not InventoryBridge.Active.search then
        return nil
    end

    return InventoryBridge.Active.search(source, searchType, itemName, metadata)
end

function InventoryBridge.RemoveItem(source, itemName, count, metadata, slot, reason)
    if not InventoryBridge.Active or not InventoryBridge.Active.removeItem then
        return false
    end

    return InventoryBridge.Active.removeItem(source, itemName, count or 1, metadata, slot, reason)
end

function InventoryBridge.AddItem(source, itemName, count, metadata)
    if not InventoryBridge.Active or not InventoryBridge.Active.addItem then
        return false
    end

    return InventoryBridge.Active.addItem(source, itemName, count or 1, metadata)
end

function InventoryBridge.CanCarryItem(source, itemName, count, metadata)
    if not InventoryBridge.Active or not InventoryBridge.Active.canCarryItem then
        return true
    end

    return InventoryBridge.Active.canCarryItem(source, itemName, count or 1, metadata)
end
