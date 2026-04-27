DropState = DropState or {
    activeDrops = {},
    payphoneHistory = {},
    dropHistory = {},
}

DropService = DropService or {}
local SCENE_STATE_BAG_KEY = 'ff_deaddrops:scene'

local function getPlayerSource(source)
    local playerSource = tonumber(source)
    if not playerSource or playerSource <= 0 then
        return nil
    end

    return playerSource
end

local function isCoordsLike(value)
    return (type(value) == 'vector3' or type(value) == 'vector4')
        or (type(value) == 'table'
            and type(value.x) == 'number'
            and type(value.y) == 'number'
            and type(value.z) == 'number')
end

local function toVector3(value)
    return vector3(value.x + 0.0, value.y + 0.0, value.z + 0.0)
end

local function getHeadingFromCoordsLike(value, fallback)
    if not value then
        return fallback or 0.0
    end

    if type(value) == 'table' and type(value.heading) == 'number' then
        return value.heading
    end

    if type(value) == 'vector4' or (type(value) == 'table' and type(value.w) == 'number') then
        return value.w + 0.0
    end

    return fallback or 0.0
end

local function normalizeCoordPool(value)
    if isCoordsLike(value) then
        return { value }
    end

    if type(value) ~= 'table' then
        return nil
    end

    local pool = {}
    for index = 1, #value do
        if isCoordsLike(value[index]) then
            pool[#pool + 1] = value[index]
        end
    end

    if #pool == 0 then
        return nil
    end

    return pool
end

local function getLocationChoice(source, locations, historyTable)
    local identifier = FrameworkBridge.GetIdentifier(source)
    local lastIndex = historyTable[identifier]
    local pool = {}

    for index = 1, #locations do
        if not Config.Lead.AvoidImmediateRepeat or #locations == 1 or index ~= lastIndex then
            pool[#pool + 1] = index
        end
    end

    if #pool == 0 then
        pool[1] = 1
    end

    local selectedIndex = pool[math.random(1, #pool)]
    historyTable[identifier] = selectedIndex
    return selectedIndex, locations[selectedIndex]
end

local function resolvePayphoneLocation(location)
    if not isCoordsLike(location) then
        return nil, nil
    end

    return toVector3(location), getHeadingFromCoordsLike(location, 0.0)
end

local function resolveDropLocation(location)
    if isCoordsLike(location) then
        return toVector3(location), toVector3(location), getHeadingFromCoordsLike(location, 0.0)
    end

    if type(location) ~= 'table' then
        return nil, nil, nil
    end

    local searchCoords = nil
    if isCoordsLike(location.SearchCoords) then
        searchCoords = toVector3(location.SearchCoords)
    elseif isCoordsLike(location.searchCoords) then
        searchCoords = toVector3(location.searchCoords)
    end

    local pool = normalizeCoordPool(location.Coords or location.coords or location.Coord or location.coord)
    if pool then
        local selected = pool[math.random(1, #pool)]
        return toVector3(selected), searchCoords or toVector3(selected), getHeadingFromCoordsLike(selected, location.heading or location.Heading or 0.0)
    end

    if searchCoords then
        return searchCoords, searchCoords, location.heading or location.Heading or 0.0
    end

    return nil, nil, nil
end

local function normalizeSceneAnchor(anchorData, fallbackCoords, fallbackHeading, maxOffset)
    if type(anchorData) ~= 'table' or not isCoordsLike(anchorData.coords) then
        return fallbackCoords, fallbackHeading
    end

    local coords = toVector3(anchorData.coords)
    local heading = getHeadingFromCoordsLike(anchorData, anchorData.heading or fallbackHeading or 0.0)
    local limit = tonumber(maxOffset) or 3.0

    if fallbackCoords and FFUtils.VectorDistance(coords, fallbackCoords) > limit then
        return fallbackCoords, fallbackHeading
    end

    return coords, heading
end

local function buildRewardPackage()
    local reward = {
        cash = nil,
        item = nil,
    }

    local cashConfig = Config.Rewards.Cash or {}
    local itemsConfig = Config.Rewards.Items or {}
    local cashEnabled = cashConfig.Enabled == true
    local includeItemReward = cashEnabled ~= true or cashConfig.IncludeItemReward ~= false

    if cashEnabled then
        reward.cash = math.random(cashConfig.Min, cashConfig.Max)
    end

    local selected = includeItemReward and FFUtils.WeightedChoice(itemsConfig) or nil
    if selected then
        reward.item = {
            name = selected.item,
            label = selected.label or selected.item,
            amount = selected.amount or Config.Rewards.DefaultItemAmount or 1,
            metadata = FFUtils.DeepCopy(selected.metadata),
        }
    end

    return reward
end

local function getPayphoneDurationMs()
    return math.max(tonumber((Config.Payphones or {}).SceneDurationMs) or 3000, 1000)
end

local function getDropDurationMs(variant)
    local durations = (Config.Drops or {}).SceneDurationMs
    if type(durations) == 'table' then
        return math.max(tonumber(durations[variant]) or 3000, 1000)
    end

    return math.max(tonumber(durations) or 3000, 1000)
end

local function normalizeRequestedDurationMs(requestedDurationMs, fallbackDurationMs)
    local fallbackMs = math.max(tonumber(fallbackDurationMs) or 3000, 1000)
    local requestedMs = tonumber(requestedDurationMs)
    if not requestedMs then
        return fallbackMs
    end

    requestedMs = math.floor(requestedMs)
    requestedMs = math.max(requestedMs, fallbackMs)
    requestedMs = math.min(requestedMs, 30000)
    return requestedMs
end

local function getBusyStagePhaseCount(lead)
    if not lead or not lead.busyStage then
        return 0
    end

    if lead.busyStage == 'payphone' then
        return 2
    end

    if lead.busyStage == 'drop' then
        return 1
    end

    return 0
end

local function formatRewardSummary(reward)
    local parts = {}

    if reward.cash and reward.cash > 0 then
        parts[#parts + 1] = ('$%s'):format(reward.cash)
    end

    if reward.item then
        parts[#parts + 1] = ('%s x%s'):format(reward.item.label, reward.item.amount)
    end

    if #parts == 0 then
        return 'nothing'
    end

    return table.concat(parts, ' and ')
end

local function canCarryReward(source, reward)
    if not reward or not reward.item then
        return true
    end

    return InventoryBridge.CanCarryItem(source, reward.item.name, reward.item.amount, reward.item.metadata)
end

local function grantReward(source, reward)
    local itemGranted = false
    if reward.item then
        local added = InventoryBridge.AddItem(source, reward.item.name, reward.item.amount, reward.item.metadata)
        if not added then
            return false, 'You do not have enough inventory space for the dead drop.'
        end

        itemGranted = true
    end

    if reward.cash and reward.cash > 0 then
        local paid = FrameworkBridge.AddMoney(source, Config.Rewards.Cash.Account, reward.cash)
        if not paid then
            if itemGranted then
                InventoryBridge.RemoveItem(source, reward.item.name, reward.item.amount, reward.item.metadata, nil, 'ff_deaddrops-rollback')
            end

            return false, 'Failed to deliver the cash reward.'
        end
    end

    return true
end

local function buildClientLead(lead)
    if not lead then
        return nil
    end

    local clientLead = {
        id = lead.id,
        stage = lead.stage,
        assignedAt = lead.assignedAt,
        payphoneCoords = lead.payphoneCoords,
        payphoneHeading = lead.payphoneHeading,
    }

    if lead.stage == 'drop' then
        clientLead.dropCoords = lead.dropCoords
        clientLead.dropSearchCoords = lead.dropSearchCoords or lead.dropCoords
        clientLead.dropHeading = lead.dropHeading or 0.0
        clientLead.dropVariant = lead.dropVariant
    end

    return clientLead
end

local function clearOwnedDrop(source, syncClient)
    source = getPlayerSource(source)
    if not source then
        return
    end

    local lead = DropState.activeDrops[source]
    if not lead then
        return
    end

    local player = Player(source)
    if player and player.state then
        player.state:set(SCENE_STATE_BAG_KEY, {
            active = false,
            clearedAt = GetGameTimer(),
            leadId = lead.id,
        }, true)
    end

    DropState.activeDrops[source] = nil
    if syncClient ~= false then
        TriggerClientEvent('ff_deaddrops:client:clearLead', source)
    end
end

local function setPlayerSceneState(source, state)
    local player = Player(source)
    if not player or not player.state then
        return
    end

    player.state:set(SCENE_STATE_BAG_KEY, state, true)
end

local function isPlayerNearCoords(source, coords, maxDistance)
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then
        return false
    end

    return FFUtils.VectorDistance(GetEntityCoords(ped), coords) <= maxDistance
end

function DropService.Notify(source, description, notifyType)
    TriggerClientEvent('ff_deaddrops:client:notify', source, {
        title = Config.Notifications.Title,
        description = description,
        type = notifyType or 'inform',
    })
end

function DropService.GetLead(source)
    source = getPlayerSource(source)
    return source and DropState.activeDrops[source] or nil
end

function DropService.SyncLead(source)
    local lead = DropService.GetLead(source)
    if lead then
        TriggerClientEvent('ff_deaddrops:client:setLead', source, buildClientLead(lead))
    else
        TriggerClientEvent('ff_deaddrops:client:clearLead', source)
    end
end

function DropService.CanAssignLead(source)
    source = getPlayerSource(source)
    if not source then
        return false, 'Invalid player source.'
    end

    if Config.Lead.OneActiveLeadPerPlayer ~= false and DropService.GetLead(source) then
        return false, 'You already have an active dead drop.'
    end

    if #Config.Payphones.Locations == 0 then
        return false, 'No payphone locations are configured.'
    end

    if #Config.Drops.Locations == 0 then
        return false, 'No dead-drop locations are configured.'
    end

    if #Config.Drops.Variants == 0 then
        return false, 'No dead-drop variants are configured.'
    end

    return true
end

function DropService.AssignLead(source, itemName)
    source = getPlayerSource(source)
    local ok, reason = DropService.CanAssignLead(source)
    if not ok then
        return false, reason
    end

    local _, payphoneLocation = getLocationChoice(source, Config.Payphones.Locations, DropState.payphoneHistory)
    local _, dropLocation = getLocationChoice(source, Config.Drops.Locations, DropState.dropHistory)
    local payphoneCoords, payphoneHeading = resolvePayphoneLocation(payphoneLocation)
    local dropCoords, dropSearchCoords, dropHeading = resolveDropLocation(dropLocation)
    local variant = FFUtils.WeightedChoice(Config.Drops.Variants)

    if not payphoneCoords then
        return false, 'The selected payphone location is not configured correctly.'
    end

    if not dropCoords or not variant or not variant.name then
        return false, 'The selected dead-drop location is not configured correctly.'
    end

    local lead = {
        id = FFUtils.RandomId('drop'),
        owner = source,
        identifier = FrameworkBridge.GetIdentifier(source),
        itemName = itemName,
        assignedAt = GetGameTimer(),
        stage = 'payphone',
        payphoneCoords = payphoneCoords,
        payphoneHeading = payphoneHeading,
        dropCoords = dropCoords,
        dropSearchCoords = dropSearchCoords or dropCoords,
        dropHeading = dropHeading or 0.0,
        dropVariant = variant.name,
        reward = buildRewardPackage(),
        busy = false,
        busyStage = nil,
        busyToken = nil,
        busyStartedAt = nil,
        busyEndsAt = nil,
    }

    DropState.activeDrops[source] = lead
    TriggerClientEvent('ff_deaddrops:client:setLead', source, buildClientLead(lead))
    return true, lead
end

function DropService.ClearLead(source, syncClient)
    clearOwnedDrop(source, syncClient)
end

function DropService.StartPayphone(source, requestData)
    source = getPlayerSource(source)
    local lead = DropService.GetLead(source)
    if not lead then
        return false, 'You do not have an active dead drop.'
    end

    if lead.stage ~= 'payphone' then
        return false, 'The contact already gave you the drop location.'
    end

    if lead.busy then
        return false, 'You are already busy with this dead drop.'
    end

    if not isPlayerNearCoords(source, lead.payphoneCoords, Config.Payphones.StartRadius or Config.Payphones.InteractionRadius or 3.0) then
        return false, 'Move closer to the payphone.'
    end

    lead.busy = true
    lead.busyStage = 'payphone'
    lead.busyToken = FFUtils.RandomId('payphone')
    lead.busyStartedAt = GetGameTimer()
    lead.payphoneDurationMs = normalizeRequestedDurationMs(
        requestData and requestData.durationMs,
        getPayphoneDurationMs()
    )
    lead.busyEndsAt = lead.busyStartedAt + lead.payphoneDurationMs
    lead.payphoneSceneCoords, lead.payphoneSceneHeading = normalizeSceneAnchor(
        requestData and requestData.anchor,
        lead.payphoneCoords,
        lead.payphoneHeading,
        (Config.Payphones and Config.Payphones.AnchorMaxOffset) or 3.0
    )
    lead.payphoneSceneIndex = tonumber(requestData and requestData.sceneIndex) or 1

    setPlayerSceneState(source, {
        active = true,
        token = lead.busyToken,
        stage = 'payphone',
        coords = lead.payphoneCoords,
        heading = lead.payphoneHeading,
        anchorCoords = lead.payphoneSceneCoords,
        anchorHeading = lead.payphoneSceneHeading,
        sceneSet = Config.Payphones.SceneSet or 'contract',
        sceneIndex = lead.payphoneSceneIndex,
        phaseIndex = 0,
        duration = lead.payphoneDurationMs,
    })

    TriggerClientEvent('ff_deaddrops:client:startPayphoneScene', source, {
        leadId = lead.id,
        token = lead.busyToken,
        coords = lead.payphoneCoords,
        heading = lead.payphoneHeading,
        anchorCoords = lead.payphoneSceneCoords,
        anchorHeading = lead.payphoneSceneHeading,
        sceneSet = Config.Payphones.SceneSet or 'contract',
        sceneIndex = lead.payphoneSceneIndex,
        duration = lead.payphoneDurationMs,
    })

    return true
end

function DropService.CompletePayphone(source, leadId, token)
    source = getPlayerSource(source)
    local lead = DropService.GetLead(source)
    if not lead or lead.id ~= leadId or lead.busyStage ~= 'payphone' or lead.busyToken ~= token then
        return false, 'Invalid payphone completion.'
    end

    if not isPlayerNearCoords(source, lead.payphoneCoords, Config.Payphones.CompleteRadius or Config.Payphones.StartRadius or 4.0) then
        lead.busy = false
        lead.busyStage = nil
        lead.busyToken = nil
        lead.busyStartedAt = nil
        lead.busyEndsAt = nil
        lead.payphoneDurationMs = nil
        lead.payphoneSceneCoords = nil
        lead.payphoneSceneHeading = nil
        lead.payphoneSceneIndex = nil
        setPlayerSceneState(source, {
            active = false,
            clearedAt = GetGameTimer(),
            leadId = lead.id,
        })
        return false, 'You moved too far away from the payphone.'
    end

    if lead.busyEndsAt and (GetGameTimer() + 250) < lead.busyEndsAt then
        return false, 'Payphone contact completed too early.'
    end

    lead.busy = false
    lead.busyStage = nil
    lead.busyToken = nil
    lead.busyStartedAt = nil
    lead.busyEndsAt = nil
    lead.payphoneDurationMs = nil
    lead.payphoneSceneCoords = nil
    lead.payphoneSceneHeading = nil
    lead.payphoneSceneIndex = nil
    lead.stage = 'drop'

    setPlayerSceneState(source, {
        active = false,
        clearedAt = GetGameTimer(),
        leadId = lead.id,
    })

    TriggerClientEvent('ff_deaddrops:client:setLead', source, buildClientLead(lead))
    DropService.Notify(source, 'The contact gave you the dead-drop search area.', 'success')
    return true
end

function DropService.StartDropRecovery(source, requestData)
    source = getPlayerSource(source)
    local lead = DropService.GetLead(source)
    if not lead then
        return false, 'You do not have an active dead drop.'
    end

    if lead.stage ~= 'drop' then
        return false, 'You need to use the payphone first.'
    end

    if lead.busy then
        return false, 'You are already recovering this dead drop.'
    end

    if not isPlayerNearCoords(source, lead.dropCoords, Config.Drops.StartRadius or Config.Drops.InteractionRadius or 3.0) then
        return false, 'Move closer to the stash.'
    end

    if not canCarryReward(source, lead.reward) then
        return false, 'You do not have enough inventory space for the dead drop.'
    end

    lead.busy = true
    lead.busyStage = 'drop'
    lead.busyToken = FFUtils.RandomId('recover')
    lead.busyStartedAt = GetGameTimer()
    lead.dropDurationMs = normalizeRequestedDurationMs(
        requestData and requestData.durationMs,
        getDropDurationMs(lead.dropVariant)
    )
    lead.busyEndsAt = lead.busyStartedAt + lead.dropDurationMs
    lead.dropSceneCoords, lead.dropSceneHeading = normalizeSceneAnchor(
        requestData and requestData.anchor,
        lead.dropCoords,
        lead.dropHeading,
        (Config.Drops and Config.Drops.AnchorMaxOffset) or 3.0
    )

    setPlayerSceneState(source, {
        active = true,
        token = lead.busyToken,
        stage = 'drop',
        coords = lead.dropCoords,
        heading = lead.dropHeading,
        anchorCoords = lead.dropSceneCoords,
        anchorHeading = lead.dropSceneHeading,
        variant = lead.dropVariant,
        phaseIndex = 0,
        duration = lead.dropDurationMs,
    })

    TriggerClientEvent('ff_deaddrops:client:startDropScene', source, {
        leadId = lead.id,
        token = lead.busyToken,
        coords = lead.dropCoords,
        heading = lead.dropHeading,
        anchorCoords = lead.dropSceneCoords,
        anchorHeading = lead.dropSceneHeading,
        variant = lead.dropVariant,
        duration = lead.dropDurationMs,
    })

    return true
end

function DropService.CompleteDropRecovery(source, leadId, token)
    source = getPlayerSource(source)
    local lead = DropService.GetLead(source)
    if not lead or lead.id ~= leadId or lead.stage ~= 'drop' or lead.busyStage ~= 'drop' or lead.busyToken ~= token then
        return false, 'Invalid dead-drop completion.'
    end

    if not isPlayerNearCoords(source, lead.dropCoords, Config.Drops.CompleteRadius or Config.Drops.StartRadius or 4.5) then
        lead.busy = false
        lead.busyStage = nil
        lead.busyToken = nil
        lead.busyStartedAt = nil
        lead.busyEndsAt = nil
        lead.dropDurationMs = nil
        lead.dropSceneCoords = nil
        lead.dropSceneHeading = nil
        setPlayerSceneState(source, {
            active = false,
            clearedAt = GetGameTimer(),
            leadId = lead.id,
        })
        return false, 'You moved too far away from the stash.'
    end

    if not canCarryReward(source, lead.reward) then
        lead.busy = false
        lead.busyStage = nil
        lead.busyToken = nil
        lead.busyStartedAt = nil
        lead.busyEndsAt = nil
        lead.dropDurationMs = nil
        lead.dropSceneCoords = nil
        lead.dropSceneHeading = nil
        setPlayerSceneState(source, {
            active = false,
            clearedAt = GetGameTimer(),
            leadId = lead.id,
        })
        return false, 'You do not have enough inventory space for the dead drop.'
    end

    if lead.busyEndsAt and (GetGameTimer() + 250) < lead.busyEndsAt then
        return false, 'Dead-drop recovery completed too early.'
    end

    local rewardSummary = formatRewardSummary(lead.reward)
    local granted, grantReason = grantReward(source, lead.reward)
    if not granted then
        lead.busy = false
        lead.busyStage = nil
        lead.busyToken = nil
        lead.busyStartedAt = nil
        lead.busyEndsAt = nil
        lead.dropDurationMs = nil
        lead.dropSceneCoords = nil
        lead.dropSceneHeading = nil
        setPlayerSceneState(source, {
            active = false,
            clearedAt = GetGameTimer(),
            leadId = lead.id,
        })
        return false, grantReason or 'Failed to deliver the dead-drop reward.'
    end

    clearOwnedDrop(source, true)
    DropService.Notify(source, ('You recovered %s.'):format(rewardSummary), 'success')
    return true
end

function DropService.CancelBusyStage(source, leadId, token)
    source = getPlayerSource(source)
    local lead = DropService.GetLead(source)
    if not lead or lead.id ~= leadId or lead.busyToken ~= token then
        return false
    end

    lead.busy = false
    lead.busyStage = nil
    lead.busyToken = nil
    lead.busyStartedAt = nil
    lead.busyEndsAt = nil
    lead.payphoneDurationMs = nil
    lead.payphoneSceneCoords = nil
    lead.payphoneSceneHeading = nil
    lead.payphoneSceneIndex = nil
    lead.dropDurationMs = nil
    lead.dropSceneCoords = nil
    lead.dropSceneHeading = nil
    setPlayerSceneState(source, {
        active = false,
        clearedAt = GetGameTimer(),
        leadId = lead.id,
    })
    return true
end

function DropService.UpdateBusyStagePhase(source, leadId, token, phaseIndex)
    source = getPlayerSource(source)
    local lead = DropService.GetLead(source)
    if not lead or lead.id ~= leadId or lead.busy ~= true or lead.busyToken ~= token then
        return false
    end

    local normalizedPhaseIndex = math.floor(tonumber(phaseIndex) or 0)
    local maxPhaseCount = getBusyStagePhaseCount(lead)
    if normalizedPhaseIndex < 1 or (maxPhaseCount > 0 and normalizedPhaseIndex > maxPhaseCount) then
        return false
    end

    if lead.busyStage == 'payphone' then
        setPlayerSceneState(source, {
            active = true,
            token = lead.busyToken,
            stage = 'payphone',
            coords = lead.payphoneCoords,
            heading = lead.payphoneHeading,
            anchorCoords = lead.payphoneSceneCoords,
            anchorHeading = lead.payphoneSceneHeading,
            sceneSet = Config.Payphones.SceneSet or 'contract',
            sceneIndex = lead.payphoneSceneIndex,
            phaseIndex = normalizedPhaseIndex,
            duration = lead.payphoneDurationMs,
        })
        return true
    end

    if lead.busyStage == 'drop' then
        setPlayerSceneState(source, {
            active = true,
            token = lead.busyToken,
            stage = 'drop',
            coords = lead.dropCoords,
            heading = lead.dropHeading,
            anchorCoords = lead.dropSceneCoords,
            anchorHeading = lead.dropSceneHeading,
            variant = lead.dropVariant,
            phaseIndex = normalizedPhaseIndex,
            duration = lead.dropDurationMs,
        })
        return true
    end

    return false
end

function DropService.ClearExpiredBusyStages()
    local now = GetGameTimer()

    for source, lead in pairs(DropState.activeDrops) do
        if lead.busy == true and lead.busyEndsAt and now > (lead.busyEndsAt + 5000) then
            lead.busy = false
            lead.busyStage = nil
            lead.busyToken = nil
            lead.busyStartedAt = nil
            lead.busyEndsAt = nil
            lead.payphoneDurationMs = nil
            lead.payphoneSceneCoords = nil
            lead.payphoneSceneHeading = nil
            lead.payphoneSceneIndex = nil
            lead.dropDurationMs = nil
            lead.dropSceneCoords = nil
            lead.dropSceneHeading = nil
            setPlayerSceneState(source, {
                active = false,
                clearedAt = now,
                leadId = lead.id,
            })

            if GetPlayerPed(source) and GetPlayerPed(source) > 0 then
                DropService.Notify(source, 'The dead-drop interaction timed out. You can try again.', 'error')
            end
        end
    end
end
