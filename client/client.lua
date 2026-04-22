ClientState = ClientState or {
    activeLead = nil,
    payphoneBlip = nil,
    dropBlip = nil,
    dropRadiusBlip = nil,
    promptVisible = false,
    stageBusy = false,
    requestThrottleAt = 0,
    payphoneProp = nil,
    dropProp = nil,
}
local SCENE_STATE_BAG_KEY = 'ff_deaddrops:scene'
local RemoteSceneState = {
    activeTokens = {},
}

local function removeBlip(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
end

local function notify(description, notifyType)
    UIBridge.Notify({
        title = Config.Notifications.Title,
        description = description,
        type = notifyType or 'inform',
    })
end

local function clearPrompt()
    if ClientState.promptVisible then
        UIBridge.HideTextUI()
        ClientState.promptVisible = false
    end
end

local function clearPayphoneProp()
    DropClientRemoveEntity(ClientState.payphoneProp)
    ClientState.payphoneProp = nil
end

local function clearDropProp()
    DropClientRemoveEntity(ClientState.dropProp)
    ClientState.dropProp = nil
end

local function clearStageBlips()
    removeBlip(ClientState.payphoneBlip)
    removeBlip(ClientState.dropBlip)
    removeBlip(ClientState.dropRadiusBlip)
    ClientState.payphoneBlip = nil
    ClientState.dropBlip = nil
    ClientState.dropRadiusBlip = nil
end

local function refreshLeadBlips()
    clearStageBlips()

    local lead = ClientState.activeLead
    if not lead then
        return
    end

    if lead.stage == 'payphone' and lead.payphoneCoords then
        local blipConfig = Config.Payphones.Blip or {}
        local blip = AddBlipForCoord(lead.payphoneCoords.x, lead.payphoneCoords.y, lead.payphoneCoords.z)
        SetBlipSprite(blip, blipConfig.Sprite or 304)
        SetBlipColour(blip, blipConfig.Colour or 2)
        SetBlipScale(blip, blipConfig.Scale or 0.85)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(blipConfig.Label or 'Dead Drop Contact')
        EndTextCommandSetBlipName(blip)
        ClientState.payphoneBlip = blip

        if Config.Lead.SetWaypoint ~= false then
            SetNewWaypoint(lead.payphoneCoords.x, lead.payphoneCoords.y)
        end

        return
    end

    if lead.stage == 'drop' and lead.dropSearchCoords then
        local blipConfig = Config.Drops.Blip or {}
        local blip = AddBlipForCoord(lead.dropSearchCoords.x, lead.dropSearchCoords.y, lead.dropSearchCoords.z)
        SetBlipSprite(blip, blipConfig.Sprite or 501)
        SetBlipColour(blip, blipConfig.Colour or 5)
        SetBlipScale(blip, blipConfig.Scale or 0.85)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(blipConfig.Label or 'Dead Drop Search Area')
        EndTextCommandSetBlipName(blip)
        ClientState.dropBlip = blip

        local radiusBlip = AddBlipForRadius(lead.dropSearchCoords.x, lead.dropSearchCoords.y, lead.dropSearchCoords.z, Config.Drops.SearchRadius + 0.0)
        SetBlipColour(radiusBlip, blipConfig.Colour or 5)
        SetBlipDisplay(radiusBlip, 3)
        SetBlipAlpha(radiusBlip, blipConfig.RadiusAlpha or 30)
        ClientState.dropRadiusBlip = radiusBlip

        if Config.Lead.SetWaypoint ~= false then
            SetNewWaypoint(lead.dropSearchCoords.x, lead.dropSearchCoords.y)
        end
    end
end

local function clearLeadState()
    clearPrompt()
    clearStageBlips()
    clearPayphoneProp()
    clearDropProp()
    ClientState.activeLead = nil
    ClientState.stageBusy = false
end

local function setLeadState(lead)
    clearPrompt()
    clearPayphoneProp()
    clearDropProp()
    ClientState.activeLead = lead
    ClientState.stageBusy = false
    refreshLeadBlips()
end

local function ensurePayphoneProp()
    local lead = ClientState.activeLead
    if not lead or lead.stage ~= 'payphone' or not lead.payphoneCoords then
        clearPayphoneProp()
        return
    end

    local coords = GetEntityCoords(PlayerPedId())
    if #(coords - lead.payphoneCoords) > (Config.Payphones.SpawnRadius or 80.0) then
        clearPayphoneProp()
        return
    end

    if ClientState.payphoneProp and DoesEntityExist(ClientState.payphoneProp) then
        return
    end

    local model = DropClientGetPayphoneClueModel(Config.Payphones.SceneSet or 'contract')
    if not model then
        return
    end

    ClientState.payphoneProp = DropClientSpawnStaticProp(model, lead.payphoneCoords, lead.payphoneHeading or 0.0, {
        freeze = ((Config.Payphones.Prop or {}).Freeze ~= false),
        collision = ((Config.Payphones.Prop or {}).Collision == true),
        placeOnGround = true,
    })
end

local function ensureDropProp()
    local lead = ClientState.activeLead
    if not lead or lead.stage ~= 'drop' or not lead.dropCoords or not lead.dropSearchCoords then
        clearDropProp()
        return
    end

    local coords = GetEntityCoords(PlayerPedId())
    if #(coords - lead.dropSearchCoords) > (Config.Drops.SearchRadius or 18.0) then
        clearDropProp()
        return
    end

    if #(coords - lead.dropCoords) > (((Config.Drops.Clue or {}).SpawnRadius) or 22.0) then
        clearDropProp()
        return
    end

    if ClientState.dropProp and DoesEntityExist(ClientState.dropProp) then
        return
    end

    local model = DropClientGetDropClueModel(lead.dropVariant)
    if not model then
        return
    end

    ClientState.dropProp = DropClientSpawnStaticProp(model, lead.dropCoords, lead.dropHeading or 0.0, {
        freeze = (((Config.Drops.Clue or {}).Freeze) ~= false),
        collision = (((Config.Drops.Clue or {}).Collision) == true),
        placeOnGround = (((Config.Drops.Clue or {}).PlaceOnGround) ~= false),
    })
end

local function requestStageStart(eventName)
    local now = GetGameTimer()
    if now < (ClientState.requestThrottleAt or 0) then
        return
    end

    ClientState.requestThrottleAt = now + 1000
    local lead = ClientState.activeLead
    local payload = {}

    if lead and lead.stage == 'payphone' then
        if ClientState.payphoneProp and DoesEntityExist(ClientState.payphoneProp) then
            local coords = GetEntityCoords(ClientState.payphoneProp)
            payload.anchor = {
                coords = vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0),
                heading = GetEntityHeading(ClientState.payphoneProp),
            }
        end

        payload.sceneIndex = DropClientPickPayphoneSceneIndex(Config.Payphones.SceneSet or 'contract')
        payload.durationMs = DropClientGetPayphoneSceneDuration(Config.Payphones.SceneSet or 'contract', payload.sceneIndex)
    elseif lead and lead.stage == 'drop' then
        if ClientState.dropProp and DoesEntityExist(ClientState.dropProp) then
            local coords = GetEntityCoords(ClientState.dropProp)
            payload.anchor = {
                coords = vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0),
                heading = GetEntityHeading(ClientState.dropProp),
            }
        end

        payload.durationMs = DropClientGetDropSceneDuration(lead.dropVariant)
    end

    TriggerServerEvent(eventName, payload)
end

local function getServerIdFromBagName(bagName)
    return tonumber(bagName and bagName:match('player:(%d+)'))
end

local function resolvePlayerPedFromServerId(serverId, timeoutMs)
    if (timeoutMs or 0) <= 0 then
        local player = GetPlayerFromServerId(serverId)
        if player ~= -1 then
            local ped = GetPlayerPed(player)
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                return ped
            end
        end

        return 0
    end

    local timeoutAt = GetGameTimer() + (timeoutMs or 2000)
    while GetGameTimer() <= timeoutAt do
        local player = GetPlayerFromServerId(serverId)
        if player ~= -1 then
            local ped = GetPlayerPed(player)
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                return ped
            end
        end

        Wait(0)
    end

    return 0
end

local function getStateBagValueForPlayer(serverId, key)
    local playerState = Player(serverId)
    if not playerState or not playerState.state then
        return nil
    end

    return playerState.state[key]
end

local function clearRemoteSceneToken(serverId)
    RemoteSceneState.activeTokens[serverId] = nil
end

local function getRemoteSceneReplayKey(value)
    if type(value) ~= 'table' or value.active ~= true or not value.token then
        return nil
    end

    local phaseIndex = math.floor(tonumber(value.phaseIndex) or 0)
    if phaseIndex < 1 then
        return nil
    end

    return ('%s:%s'):format(tostring(value.token), phaseIndex)
end

local function applyRemoteSceneState(serverId, value, timeoutMs)
    if serverId == GetPlayerServerId(PlayerId()) then
        return true
    end

    if type(value) ~= 'table' or value.active ~= true or not value.token then
        clearRemoteSceneToken(serverId)
        return true
    end

    local replayKey = getRemoteSceneReplayKey(value)
    if not replayKey then
        return true
    end

    if RemoteSceneState.activeTokens[serverId] == replayKey then
        return true
    end

    local ped = resolvePlayerPedFromServerId(serverId, timeoutMs or 0)
    if ped == 0 then
        return false
    end

    local targetCoordsSource = value.anchorCoords or value.coords
    local targetCoords = targetCoordsSource and vector3(targetCoordsSource.x + 0.0, targetCoordsSource.y + 0.0, targetCoordsSource.z + 0.0) or nil
    if targetCoords and #(GetEntityCoords(ped) - targetCoords) > 6.0 then
        return false
    end

    RemoteSceneState.activeTokens[serverId] = replayKey

    CreateThread(function()
        if value.stage == 'payphone' then
            DropClientRunRemotePayphoneScene(serverId, ped, value)
        elseif value.stage == 'drop' then
            DropClientRunRemoteDropScene(serverId, ped, value)
        end
    end)

    return true
end

AddStateBagChangeHandler(SCENE_STATE_BAG_KEY, nil, function(bagName, _, value)
    local serverId = getServerIdFromBagName(bagName)
    if not serverId then
        return
    end

    applyRemoteSceneState(serverId, value, 1500)
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent('ff_deaddrops:server:requestLeadSync')

    while true do
        local sleep = 1000
        local lead = ClientState.activeLead

        if not lead or ClientState.stageBusy then
            clearPrompt()
            if not lead then
                clearPayphoneProp()
                clearDropProp()
            end
        elseif lead.stage == 'payphone' and lead.payphoneCoords then
            sleep = 0
            ensurePayphoneProp()
            clearDropProp()

            local distance = #(GetEntityCoords(PlayerPedId()) - lead.payphoneCoords)
            if distance <= (Config.Payphones.InteractionRadius or 2.2) then
                if not ClientState.promptVisible then
                    UIBridge.ShowTextUI(Config.Payphones.Prompt or '[E] Use payphone')
                    ClientState.promptVisible = true
                end

                if IsControlJustPressed(0, 38) then
                    clearPrompt()
                    requestStageStart('ff_deaddrops:server:requestStartPayphone')
                    sleep = 500
                end
            else
                clearPrompt()
            end
        elseif lead.stage == 'drop' and lead.dropCoords and lead.dropSearchCoords then
            local coords = GetEntityCoords(PlayerPedId())
            local searchDistance = #(coords - lead.dropSearchCoords)
            clearPayphoneProp()

            if searchDistance <= (Config.Drops.SearchRadius or 18.0) then
                sleep = 0
                ensureDropProp()

                if (not ClientState.dropProp or not DoesEntityExist(ClientState.dropProp))
                    and ((((Config.Drops.Clue or {}).MarkerFallback) or {}).Enabled ~= false) then
                    DropClientDrawMarker(lead.dropCoords)
                end

                local distance = #(coords - lead.dropCoords)
                if distance <= (Config.Drops.InteractionRadius or 2.25) then
                    if not ClientState.promptVisible then
                        UIBridge.ShowTextUI(Config.Drops.Prompt or '[E] Recover dead drop')
                        ClientState.promptVisible = true
                    end

                    if IsControlJustPressed(0, 38) then
                        clearPrompt()
                        requestStageStart('ff_deaddrops:server:requestStartDrop')
                        sleep = 500
                    end
                else
                    clearPrompt()
                end
            else
                clearPrompt()
                clearDropProp()
            end
        else
            clearPrompt()
            clearPayphoneProp()
            clearDropProp()
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        for _, player in ipairs(GetActivePlayers()) do
            if player ~= PlayerId() then
                local serverId = GetPlayerServerId(player)
                applyRemoteSceneState(serverId, getStateBagValueForPlayer(serverId, SCENE_STATE_BAG_KEY), 0)
            end
        end

        Wait(1000)
    end
end)

RegisterNetEvent('ff_deaddrops:client:notify', function(data)
    UIBridge.Notify(data)
end)

RegisterNetEvent('ff_deaddrops:client:setLead', function(lead)
    setLeadState(lead)
end)

RegisterNetEvent('ff_deaddrops:client:clearLead', function()
    clearLeadState()
end)

RegisterNetEvent('ff_deaddrops:client:startPayphoneScene', function(payload)
    if ClientState.stageBusy then
        return
    end

    ClientState.stageBusy = true
    clearPrompt()
    local scenePayload = DropClientBuildScenePayload(payload or {}, ClientState.payphoneProp)
    clearPayphoneProp()

    local completed = DropClientRunPayphoneScene(scenePayload, function(phaseIndex)
        TriggerServerEvent('ff_deaddrops:server:updateScenePhase', payload.leadId, payload.token, phaseIndex)
    end)
    ClientState.stageBusy = false

    if completed then
        TriggerServerEvent('ff_deaddrops:server:completePayphone', payload.leadId, payload.token)
    else
        notify('You backed out of the payphone contact.', 'error')
        TriggerServerEvent('ff_deaddrops:server:cancelStage', payload.leadId, payload.token)
    end
end)

RegisterNetEvent('ff_deaddrops:client:startDropScene', function(payload)
    if ClientState.stageBusy then
        return
    end

    ClientState.stageBusy = true
    clearPrompt()
    local scenePayload = DropClientBuildScenePayload(payload or {}, ClientState.dropProp)
    clearDropProp()

    local completed = DropClientRunDropScene(scenePayload, function(phaseIndex)
        TriggerServerEvent('ff_deaddrops:server:updateScenePhase', payload.leadId, payload.token, phaseIndex)
    end)
    ClientState.stageBusy = false

    if completed then
        TriggerServerEvent('ff_deaddrops:server:completeDrop', payload.leadId, payload.token)
    else
        notify('You failed to recover the dead drop.', 'error')
        TriggerServerEvent('ff_deaddrops:server:cancelStage', payload.leadId, payload.token)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    clearLeadState()
end)
