local FRAMEWORK_DEPENDENCIES = {
    ['qbx_core'] = 'qbox',
    ['qb-core'] = 'qbcore',
    ['es_extended'] = 'esx',
}
local SCENE_PROFILE_PREFIX = '^3[ff_deaddrops:scene_profile]^7'

local INVENTORY_DEPENDENCIES = {
    ['ox_inventory'] = 'ox_inventory',
    ['qb-inventory'] = 'qb_inventory',
    ['qb-core'] = 'qb_inventory',
}

local RuntimeState = {
    usableItemRegisteredFor = nil,
    waitingOnFrameworkLogged = false,
    waitingOnInventoryLogged = false,
    usableItemWarningLogged = false,
}

local function getSourceFromInventory(inventory)
    if type(inventory) == 'table' then
        return inventory.id or inventory.source
    end

    return inventory
end

local function normalizeExportArgs(arg1, arg2, arg3, arg4, arg5)
    if arg1 == 'usingItem' or arg1 == 'usedItem' or arg1 == 'buying' then
        return arg1, arg2, arg3, arg4, arg5
    end

    return arg2, arg3, arg4, arg5, nil
end

local function normalizePlayerSource(source)
    source = tonumber(source)
    if not source or source <= 0 then
        return nil
    end

    return source
end

local function findTriggerItem(itemName)
    for index = 1, #(Config.Items.Triggers or {}) do
        local item = Config.Items.Triggers[index]
        if item.name == itemName then
            return item
        end
    end

    return nil
end

local function notifyDeadDropError(source, reason)
    source = normalizePlayerSource(source)
    if not source or not reason or reason == '' then
        return
    end

    DropService.Notify(source, reason, 'error')
end

local function notifyDeadDropAssigned(source)
    source = normalizePlayerSource(source)
    if not source then
        return
    end

    DropService.Notify(source, 'A payphone contact was marked for your dead drop.', 'success')
end

local function isDeadDropSystemReady()
    if not FrameworkBridge.IsReady() then
        return false, 'Dead drops are still waiting for the framework to finish starting.'
    end

    if not InventoryBridge.IsReady() then
        return false, 'Dead drops are still waiting for the inventory to finish starting.'
    end

    return true
end

local function canUseTriggerItem(source)
    source = normalizePlayerSource(source)
    if not source then
        return false, 'Invalid player source.'
    end

    local ready, readyReason = isDeadDropSystemReady()
    if not ready then
        return false, readyReason
    end

    return DropService.CanAssignLead(source)
end

local function assignLeadFromItem(source, itemName)
    source = normalizePlayerSource(source)
    if not source then
        return false, 'Invalid player source.'
    end

    local ok, result = DropService.AssignLead(source, itemName)
    if not ok then
        return false, result
    end

    return true
end

local function useTriggerItem(source, itemName)
    local ok, reason = canUseTriggerItem(source)
    if not ok then
        notifyDeadDropError(source, reason)
        return false
    end

    local assigned, assignReason = assignLeadFromItem(source, itemName)
    if not assigned then
        notifyDeadDropError(source, assignReason)
        return false
    end

    notifyDeadDropAssigned(source)
    return true
end

local function registerTriggerItemHandler(itemConfig)
    if not itemConfig or not itemConfig.name then
        return false
    end

    if InventoryBridge.GetName() == 'qb_inventory' then
        local shouldConsume = itemConfig.consume ~= false
        return InventoryBridge.RegisterUsableItem(itemConfig.name, {
            beforeUse = function(playerSource)
                local ok, reason = canUseTriggerItem(playerSource)
                if not ok then
                    notifyDeadDropError(playerSource, reason)
                    return false
                end

                return true
            end,
            afterConsume = function(playerSource)
                if shouldConsume ~= true then
                    local ok, reason = assignLeadFromItem(playerSource, itemConfig.name)
                    if not ok then
                        notifyDeadDropError(playerSource, reason)
                        return false
                    end

                    notifyDeadDropAssigned(playerSource)
                    return true
                end

                local ok, reason = assignLeadFromItem(playerSource, itemConfig.name)
                if not ok then
                    notifyDeadDropError(playerSource, reason)
                    return false
                end

                notifyDeadDropAssigned(playerSource)
                return true
            end,
            onConsumeFailed = function(playerSource)
                if shouldConsume ~= true then
                    return
                end

                notifyDeadDropError(playerSource, ('Failed to consume the %s.'):format(itemConfig.label or itemConfig.name))
            end,
            consume = shouldConsume,
        })
    end

    return InventoryBridge.RegisterUsableItem(itemConfig.name, function(playerSource)
        return useTriggerItem(playerSource, itemConfig.name)
    end)
end

local function ensureTriggerHandlersRegistered()
    if not InventoryBridge.IsReady() then
        RuntimeState.usableItemRegisteredFor = nil
        return false
    end

    local inventoryName = InventoryBridge.GetName()
    if RuntimeState.usableItemRegisteredFor == inventoryName then
        return true
    end

    for index = 1, #(Config.Items.Triggers or {}) do
        local itemConfig = Config.Items.Triggers[index]
        if not registerTriggerItemHandler(itemConfig) then
            if not RuntimeState.usableItemWarningLogged then
                FFUtils.Log(('No usable item handler registered for %s. Check Config.Inventory and inventory start order.'):format(itemConfig.name))
                RuntimeState.usableItemWarningLogged = true
            end

            return false
        end
    end

    RuntimeState.usableItemRegisteredFor = inventoryName
    RuntimeState.usableItemWarningLogged = false
    return true
end

local function logBridgeWaitStates()
    if FrameworkBridge.IsReady() then
        RuntimeState.waitingOnFrameworkLogged = false
    elseif not RuntimeState.waitingOnFrameworkLogged then
        FFUtils.Log('Dead drops are waiting for a supported framework. The script will retry when qbox, qb-core, or es_extended starts.')
        RuntimeState.waitingOnFrameworkLogged = true
    end

    if InventoryBridge.IsReady() then
        RuntimeState.waitingOnInventoryLogged = false
    elseif not RuntimeState.waitingOnInventoryLogged then
        FFUtils.Log('Dead drops are waiting for a supported inventory. The script will retry when ox_inventory or qb-inventory starts.')
        RuntimeState.waitingOnInventoryLogged = true
    end
end

local function tryInitializeBridges()
    FrameworkBridge.Init()
    InventoryBridge.Init()
    logBridgeWaitStates()
    ensureTriggerHandlersRegistered()
end

local function handleDependencyStopped(resourceName)
    local stoppedFramework = FRAMEWORK_DEPENDENCIES[resourceName]
    if stoppedFramework and FrameworkBridge.GetName() == stoppedFramework then
        FrameworkBridge.Reset()
        RuntimeState.waitingOnFrameworkLogged = false
        FFUtils.Log(('Framework dependency stopped: %s. Dead drops will retry when it starts again.'):format(resourceName))
    end

    local stoppedInventory = INVENTORY_DEPENDENCIES[resourceName]
    if stoppedInventory and InventoryBridge.GetName() == stoppedInventory then
        InventoryBridge.Reset()
        RuntimeState.usableItemRegisteredFor = nil
        RuntimeState.waitingOnInventoryLogged = false
        RuntimeState.usableItemWarningLogged = false
        FFUtils.Log(('Inventory dependency stopped: %s. Dead drops will retry when it starts again.'):format(resourceName))
    end
end

local function shouldRetryForResource(resourceName)
    local frameworkName = FRAMEWORK_DEPENDENCIES[resourceName]
    if frameworkName and (not FrameworkBridge.IsReady() or FrameworkBridge.GetName() == frameworkName or Config.Framework == frameworkName) then
        return true
    end

    local inventoryName = INVENTORY_DEPENDENCIES[resourceName]
    if inventoryName and (not InventoryBridge.IsReady() or InventoryBridge.GetName() == inventoryName or Config.Inventory == inventoryName) then
        return true
    end

    return false
end

local function shouldEchoSceneProfileToServer()
    return (((Config.Dev or {}).SceneProfiler or {}).Enabled == true)
        and (((Config.Dev or {}).SceneProfiler or {}).EchoToServer == true)
end

local function printSceneProfile(message)
    print(('%s %s'):format(SCENE_PROFILE_PREFIX, message))
end

local function registerTriggerItemExports()
    local seenExports = {}

    for index = 1, #(Config.Items.Triggers or {}) do
        local itemConfig = Config.Items.Triggers[index]
        local itemName = itemConfig and itemConfig.name or nil
        local exportName = itemConfig and itemConfig.export or nil

        if type(itemName) ~= 'string' or itemName == '' then
            FFUtils.Log(('Skipping trigger export at index %s because it is missing a valid item name.'):format(index))
        elseif type(exportName) ~= 'string' or exportName == '' then
            FFUtils.Log(('Trigger item %s is missing Config.Items.Triggers[%s].export, so ox_inventory exports cannot be registered for it.'):format(itemName, index))
        elseif seenExports[exportName] then
            FFUtils.Log(('Skipping duplicate trigger export %s for item %s. It is already registered for %s.'):format(
                exportName,
                itemName,
                seenExports[exportName]
            ))
        else
            seenExports[exportName] = itemName
            exports(exportName, function(arg1, arg2, arg3, arg4, arg5)
                local event, _, inventory = normalizeExportArgs(arg1, arg2, arg3, arg4, arg5)
                if event ~= 'usingItem' then
                    return
                end

                return useTriggerItem(getSourceFromInventory(inventory), itemName)
            end)
        end
    end
end

registerTriggerItemExports()

CreateThread(function()
    tryInitializeBridges()
end)

CreateThread(function()
    while true do
        DropService.ClearExpiredBusyStages()
        Wait(1000)
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if shouldRetryForResource(resourceName) then
        CreateThread(function()
            tryInitializeBridges()
        end)
    end
end)

RegisterNetEvent('ff_deaddrops:server:requestLeadSync', function()
    DropService.SyncLead(source)
end)

RegisterNetEvent('ff_deaddrops:server:requestStartPayphone', function(requestData)
    local ok, reason = DropService.StartPayphone(source, requestData)
    if not ok then
        DropService.Notify(source, reason, 'error')
    end
end)

RegisterNetEvent('ff_deaddrops:server:completePayphone', function(leadId, token)
    local ok, reason = DropService.CompletePayphone(source, leadId, token)
    if not ok then
        DropService.Notify(source, reason, 'error')
    end
end)

RegisterNetEvent('ff_deaddrops:server:requestStartDrop', function(requestData)
    local ok, reason = DropService.StartDropRecovery(source, requestData)
    if not ok then
        DropService.Notify(source, reason, 'error')
    end
end)

RegisterNetEvent('ff_deaddrops:server:completeDrop', function(leadId, token)
    local ok, reason = DropService.CompleteDropRecovery(source, leadId, token)
    if not ok then
        DropService.Notify(source, reason, 'error')
    end
end)

RegisterNetEvent('ff_deaddrops:server:cancelStage', function(leadId, token)
    DropService.CancelBusyStage(source, leadId, token)
end)

RegisterNetEvent('ff_deaddrops:server:updateScenePhase', function(leadId, token, phaseIndex)
    DropService.UpdateBusyStagePhase(source, leadId, token, phaseIndex)
end)

RegisterNetEvent('ff_deaddrops:server:reportSceneProfile', function(data)
    if not shouldEchoSceneProfileToServer() or type(data) ~= 'table' then
        return
    end

    local stage = tostring(data.stage or 'unknown')
    local descriptor = tostring(data.descriptor or 'unknown')
    local animDict = tostring(data.animDict or 'unknown')
    local pedAnim = tostring(data.pedAnim or 'unknown')
    local measuredMs = tonumber(data.measuredMs) or 0
    local configuredMs = tonumber(data.configuredMs) or 0
    local deltaMs = measuredMs - configuredMs
    local playerLabel = GetPlayerName(source) or ('source_%s'):format(source)

    printSceneProfile(
        ('%s (%s) %s clip=%s/%s measured=%sms configured=%sms delta=%+dms'):format(
            playerLabel,
            tostring(source),
            ('%s %s'):format(stage, descriptor),
            animDict,
            pedAnim,
            measuredMs,
            configuredMs,
            deltaMs
        )
    )

    if data.suggestedLine then
        printSceneProfile(('suggested config: %s'):format(tostring(data.suggestedLine)))
    end
end)

AddEventHandler('playerDropped', function()
    DropService.ClearLead(source, true)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        handleDependencyStopped(resourceName)
        return
    end

    FrameworkBridge.Reset()
    InventoryBridge.Reset()

    local playerSources = {}
    for playerSource in pairs(DropState.activeDrops) do
        playerSources[#playerSources + 1] = playerSource
    end

    for index = 1, #playerSources do
        local playerSource = playerSources[index]
        DropService.ClearLead(playerSource, false)
        TriggerClientEvent('ff_deaddrops:client:clearLead', playerSource)
    end
end)
