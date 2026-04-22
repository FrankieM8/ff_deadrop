local ASSET_LOAD_TIMEOUT_MS = 5000
local SCENE_PROFILE_PREFIX = '^3[ff_deaddrops:scene_profile]^7'

local function normalizeHeading(heading)
    local normalized = (heading or 0.0) % 360.0
    if normalized < 0.0 then
        normalized = normalized + 360.0
    end

    return normalized + 0.0
end

local function getSignedHeadingDelta(a, b)
    return ((a - b + 180.0) % 360.0) - 180.0
end

local function getHeadingDelta(a, b)
    return math.abs(getSignedHeadingDelta(a, b))
end

local SceneLibrary = {
    payphones = {
        simple = {
            {
                anchorObjectIndex = 1,
                deltaZ = -1.0,
                animDict = 'oddjobs@assassinate@bus@call',
                pedAnim = 'ass_bus_call_p1',
                objects = {
                    {
                        anim = 'ass_bus_call_phone',
                        model = 'p_phonebox_01b_s',
                    },
                },
            },
            {
                anchorObjectIndex = 1,
                deltaZ = -1.0,
                animDict = 'oddjobs@assassinate@construction@call',
                pedAnim = 'ass_construction_call_p1',
                objects = {
                    {
                        anim = 'ass_construction_call_phone',
                        model = 'p_phonebox_01b_s',
                    },
                },
            },
        },
        contract = {
            {
                sequence = true,
                phases = {
                    {
                        name = 'enter',
                        anchorObjectIndex = 1,
                        deltaZ = -1.0,
                        animDict = 'anim@scripted@payphone_hits@male@',
                        pedAnim = 'enter_male',
                        objects = {
                            {
                                anim = 'enter_phone',
                                model = 'sf_prop_sf_phonebox_01b_s',
                            },
                        },
                    },
                    {
                        name = 'base',
                        anchorObjectIndex = 1,
                        deltaZ = -1.0,
                        animDict = 'anim@scripted@payphone_hits@male@',
                        pedAnim = 'base_male',
                        objects = {
                            {
                                anim = 'base_phone',
                                model = 'sf_prop_sf_phonebox_01b_s',
                            },
                        },
                    },
                    {
                        name = 'exit',
                        anchorObjectIndex = 1,
                        deltaZ = -1.0,
                        animDict = 'anim@scripted@payphone_hits@male@',
                        pedAnim = 'exit_left_male',
                        objects = {
                            {
                                anim = 'exit_left_phone',
                                model = 'sf_prop_sf_phonebox_01b_s',
                            },
                        },
                    },
                },
            },
        },
    },
    drops = {
        briefcase = {
            sequence = true,
            clueModel = 'hei_p_attache_case_01b_s',
            phases = {
                {
                    name = 'enter',
                    anchorObjectIndex = 1,
                    deltaZ = -0.95,
                    animDict = 'anim@heists@money_grab@briefcase',
                    pedAnim = 'enter',
                    objects = {
                        {
                            anim = 'enter_case',
                            model = 'hei_p_attache_case_01b_s',
                        },
                    },
                },
                {
                    name = 'loop',
                    anchorObjectIndex = 1,
                    deltaZ = -0.95,
                    animDict = 'anim@heists@money_grab@briefcase',
                    pedAnim = 'loop',
                    objects = {
                        {
                            anim = 'loop_case',
                            model = 'hei_p_attache_case_01b_s',
                        },
                    },
                },
                {
                    name = 'exit',
                    anchorObjectIndex = 1,
                    deltaZ = -0.95,
                    animDict = 'anim@heists@money_grab@briefcase',
                    pedAnim = 'exit',
                    objects = {
                        {
                            anim = 'exit_case',
                            model = 'hei_p_attache_case_01b_s',
                        },
                    },
                },
            },
        },
        duffel = {
            sequence = true,
            clueModel = 'p_ld_heist_bag_s_1',
            phases = {
                {
                    name = 'enter',
                    anchorObjectIndex = 1,
                    deltaZ = -1.0,
                    animDict = 'anim@heists@money_grab@duffel',
                    pedAnim = 'enter',
                    objects = {
                        {
                            anim = 'enter_bag',
                            model = 'p_ld_heist_bag_s_1',
                        },
                        {
                            anim = 'enter_strap',
                            model = 'p_csh_strap_01_s',
                        },
                    },
                },
                {
                    name = 'loop',
                    anchorObjectIndex = 1,
                    deltaZ = -1.0,
                    animDict = 'anim@heists@money_grab@duffel',
                    pedAnim = 'loop',
                    objects = {
                        {
                            anim = 'loop_bag',
                            model = 'p_ld_heist_bag_s_1',
                        },
                        {
                            anim = 'loop_strap',
                            model = 'p_csh_strap_01_s',
                        },
                    },
                },
                {
                    name = 'exit',
                    anchorObjectIndex = 1,
                    deltaZ = -1.0,
                    animDict = 'anim@heists@money_grab@duffel',
                    pedAnim = 'exit',
                    objects = {
                        {
                            anim = 'exit_bag',
                            model = 'p_ld_heist_bag_s_1',
                        },
                        {
                            anim = 'exit_strap',
                            model = 'p_csh_strap_01_s',
                        },
                    },
                },
            },
        },
        crate = {
            sequence = true,
            clueModel = 'xm3_prop_xm3_crate_01a',
            phases = {
                {
                    name = 'loot',
                    anchorObjectIndex = 2,
                    deltaZ = -1.0,
                    animDict = 'anim@scripted@player@mission@trn_ig1_loot@male@',
                    pedAnim = 'loot',
                    objects = {
                        {
                            anim = 'loot_can',
                            model = 'xm3_prop_xm3_can_hl_01a',
                        },
                        {
                            anim = 'loot_crate',
                            model = 'xm3_prop_xm3_crate_01a',
                        },
                        {
                            anim = 'loot_crowbar',
                            model = 'w_me_crowbar',
                        },
                    },
                },
                {
                    name = 'empty',
                    anchorObjectIndex = 1,
                    deltaZ = -1.0,
                    animDict = 'anim@scripted@player@mission@trn_ig2_empty@male@',
                    pedAnim = 'empty',
                    objects = {
                        {
                            anim = 'empty_crate',
                            model = 'xm3_prop_xm3_crate_01a',
                        },
                        {
                            anim = 'empty_crowbar',
                            model = 'w_me_crowbar',
                        },
                    },
                },
            },
        },
    },
}

local function loadAnimDict(dict)
    if not dict or dict == '' then
        return false
    end

    RequestAnimDict(dict)
    local timeoutAt = GetGameTimer() + ASSET_LOAD_TIMEOUT_MS
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > timeoutAt then
            FFUtils.Log(('Failed to load animation dictionary: %s'):format(dict))
            return false
        end

        Wait(0)
    end

    return true
end

local function unloadAnimDict(dict)
    if dict and dict ~= '' and HasAnimDictLoaded(dict) then
        RemoveAnimDict(dict)
    end
end

local function allowRemoteSyncedSceneEntity(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) or not SetEntityRemoteSyncedScenesAllowed then
        return
    end

    pcall(SetEntityRemoteSyncedScenesAllowed, entity, true)
end

local function loadModel(model)
    if not model then
        return 0
    end

    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelValid(hash) then
        FFUtils.Log(('Failed to load invalid model: %s'):format(model))
        return 0
    end

    RequestModel(hash)
    local timeoutAt = GetGameTimer() + ASSET_LOAD_TIMEOUT_MS
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeoutAt then
            FFUtils.Log(('Timed out loading model: %s'):format(model))
            return 0
        end

        Wait(0)
    end

    return hash
end

function DropClientRemoveEntity(entity)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        if IsEntityAttached(entity) then
            DetachEntity(entity, true, true)
        end

        SetEntityAsMissionEntity(entity, true, true)
        pcall(function()
            DeleteObject(entity)
        end)
        DeleteEntity(entity)
    end
end

function DropClientSpawnStaticProp(model, coords, heading, options)
    local hash = loadModel(model)
    if hash == 0 then
        return 0
    end

    local prop = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)
    if not prop or prop == 0 then
        SetModelAsNoLongerNeeded(hash)
        return 0
    end

    local propOptions = options or {}
    SetEntityCollision(prop, propOptions.collision == true, propOptions.collision == true)
    SetEntityHeading(prop, heading or 0.0)

    if propOptions.placeOnGround ~= false then
        PlaceObjectOnGroundProperly(prop)
    end

    if propOptions.freeze ~= false then
        FreezeEntityPosition(prop, true)
    end

    SetModelAsNoLongerNeeded(hash)
    return prop
end

function DropClientDrawMarker(coords)
    local marker = (((Config.Drops or {}).Clue or {}).MarkerFallback or {})
    if marker.Enabled == false then
        return
    end

    DrawMarker(
        marker.Type or 1,
        coords.x,
        coords.y,
        coords.z - 0.95,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        (marker.Scale and marker.Scale.x) or 0.35,
        (marker.Scale and marker.Scale.y) or 0.35,
        (marker.Scale and marker.Scale.z) or 0.2,
        (marker.Colour and marker.Colour.r) or 214,
        (marker.Colour and marker.Colour.g) or 178,
        (marker.Colour and marker.Colour.b) or 58,
        (marker.Colour and marker.Colour.a) or 130,
        false,
        true,
        2,
        false,
        false,
        false
    )
end

local function getPayphoneScene(sceneSet)
    local pool = SceneLibrary.payphones[sceneSet or 'simple'] or SceneLibrary.payphones.simple
    if not pool or #pool == 0 then
        return nil
    end

    return pool[math.random(1, #pool)]
end

local function getPayphoneSceneByIndex(sceneSet, sceneIndex)
    local pool = SceneLibrary.payphones[sceneSet or 'simple'] or SceneLibrary.payphones.simple
    if not pool or #pool == 0 then
        return nil
    end

    local normalizedIndex = tonumber(sceneIndex)
    if normalizedIndex then
        normalizedIndex = math.floor(normalizedIndex)
        if normalizedIndex >= 1 and normalizedIndex <= #pool then
            return pool[normalizedIndex]
        end
    end

    return nil
end

function DropClientPickPayphoneSceneIndex(sceneSet)
    local pool = SceneLibrary.payphones[sceneSet or 'simple'] or SceneLibrary.payphones.simple
    if not pool or #pool == 0 then
        return 1
    end

    return math.random(1, #pool)
end

local function getScenePhaseList(sceneOrEntry)
    if not sceneOrEntry then
        return {}
    end

    if sceneOrEntry.sequence == true and type(sceneOrEntry.phases) == 'table' then
        return sceneOrEntry.phases
    end

    return { sceneOrEntry }
end

local function getScenePhaseByIndex(sceneOrEntry, phaseIndex)
    local phases = getScenePhaseList(sceneOrEntry)
    local normalizedIndex = math.floor(tonumber(phaseIndex) or 0)
    if normalizedIndex < 1 or normalizedIndex > #phases then
        return nil, #phases
    end

    return phases[normalizedIndex], #phases
end

local function getDropScene(variant)
    return SceneLibrary.drops[variant] or SceneLibrary.drops.briefcase
end

local getRawSceneDurationMs

local function getSceneEntryDurationMs(sceneOrEntry)
    local phases = getScenePhaseList(sceneOrEntry)
    if #phases == 0 then
        return nil
    end

    local totalDurationMs = 0
    for index = 1, #phases do
        local phaseDurationMs = getRawSceneDurationMs(phases[index])
        if not phaseDurationMs then
            return nil
        end

        totalDurationMs = totalDurationMs + phaseDurationMs
    end

    return totalDurationMs
end

function DropClientGetPayphoneSceneDuration(sceneSet, sceneIndex)
    local sceneEntry = getPayphoneSceneByIndex(sceneSet, sceneIndex)
        or getPayphoneScene(sceneSet)
    return getSceneEntryDurationMs(sceneEntry)
end

function DropClientGetPayphoneClueModel(sceneSet)
    local pool = SceneLibrary.payphones[sceneSet or 'simple'] or SceneLibrary.payphones.simple
    local sceneEntry = pool and pool[1] or nil
    local phases = getScenePhaseList(sceneEntry)
    local scene = phases[1]
    return scene and scene.objects and scene.objects[1] and scene.objects[1].model or nil
end

function DropClientGetDropClueModel(variant)
    local scene = getDropScene(variant)
    return scene and scene.clueModel or nil
end

function DropClientGetDropSceneDuration(variant)
    return getSceneEntryDurationMs(getDropScene(variant))
end

function DropClientBuildScenePayload(payload, anchorEntity)
    local scenePayload = FFUtils and FFUtils.DeepCopy and FFUtils.DeepCopy(payload or {}) or (payload or {})
    if anchorEntity and anchorEntity ~= 0 and DoesEntityExist(anchorEntity) then
        local coords = GetEntityCoords(anchorEntity)
        scenePayload.anchorCoords = vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
        scenePayload.anchorHeading = GetEntityHeading(anchorEntity)
    end

    return scenePayload
end

getRawSceneDurationMs = function(scene)
    if not scene or not scene.animDict or not scene.pedAnim then
        return nil
    end

    local animWasLoaded = HasAnimDictLoaded(scene.animDict)
    if not animWasLoaded and not loadAnimDict(scene.animDict) then
        return nil
    end

    local duration = GetAnimDuration(scene.animDict, scene.pedAnim)
    if not animWasLoaded then
        unloadAnimDict(scene.animDict)
    end

    if not duration or duration <= 0 then
        return nil
    end

    return math.floor(duration * 1000)
end

local function getSceneDurationMs(scene, overrideMs)
    if type(overrideMs) == 'number' and overrideMs > 0 then
        return math.floor(overrideMs)
    end

    return getRawSceneDurationMs(scene) or 3000
end

local function shouldProfileScenes()
    return (((Config.Dev or {}).SceneProfiler or {}).Enabled == true)
end

local function shouldNotifySceneProfile()
    return (((Config.Dev or {}).SceneProfiler or {}).Notify == true)
end

local function shouldEchoSceneProfileToServer()
    return (((Config.Dev or {}).SceneProfiler or {}).EchoToServer == true)
end

local function printSceneProfile(message)
    print(('%s %s'):format(SCENE_PROFILE_PREFIX, message))
end

local function buildSceneDescriptor(stage, payload)
    if stage == 'payphone' then
        return ('sceneSet=%s sceneIndex=%s'):format(
            tostring(payload and payload.sceneSet or 'unknown'),
            tostring(payload and payload.sceneIndex or 'unknown')
        )
    end

    if stage == 'drop' then
        return ('variant=%s'):format(tostring(payload and payload.variant or 'briefcase'))
    end

    return 'unknown'
end

local function reportSceneProfile(stage, sceneOrEntry, payload)
    if not shouldProfileScenes() then
        return
    end

    local phases = getScenePhaseList(sceneOrEntry)
    if #phases == 0 then
        return
    end

    local descriptor = buildSceneDescriptor(stage, payload)
    if #phases == 1 then
        local scene = phases[1]
        local measuredMs = getRawSceneDurationMs(scene)
        if not measuredMs then
            return
        end

        local configuredMs = getSceneDurationMs(scene, payload and payload.duration)
        local deltaMs = measuredMs - (configuredMs or 0)
        printSceneProfile(
            ('%s %s clip=%s/%s measured=%sms configured=%sms delta=%+dms'):format(
                stage,
                descriptor,
                tostring(scene.animDict),
                tostring(scene.pedAnim),
                tostring(measuredMs),
                tostring(configuredMs or 'n/a'),
                deltaMs
            )
        )

        local suggestedLine = nil
        if stage == 'payphone' then
            suggestedLine = ('Config.Payphones.SceneDurationMs = %s,'):format(measuredMs)
        elseif stage == 'drop' then
            suggestedLine = ('%s = %s,'):format(tostring(payload and payload.variant or 'briefcase'), measuredMs)
        end

        if suggestedLine then
            printSceneProfile(('suggested config: %s'):format(suggestedLine))
        end

        if shouldNotifySceneProfile() then
            UIBridge.Notify({
                title = Config.Notifications.Title,
                description = ('Profiled %s scene: %sms. Check F8/server console.'):format(stage, measuredMs),
                type = 'inform',
            })
        end

        if shouldEchoSceneProfileToServer() then
            TriggerServerEvent('ff_deaddrops:server:reportSceneProfile', {
                stage = stage,
                descriptor = descriptor,
                animDict = scene.animDict,
                pedAnim = scene.pedAnim,
                measuredMs = measuredMs,
                configuredMs = configuredMs,
                suggestedLine = suggestedLine,
            })
        end

        return
    end

    local totalMeasuredMs = 0
    for index = 1, #phases do
        local phase = phases[index]
        local phaseMeasuredMs = getRawSceneDurationMs(phase)
        if phaseMeasuredMs then
            totalMeasuredMs = totalMeasuredMs + phaseMeasuredMs
            printSceneProfile(
                ('%s %s phase=%s clip=%s/%s measured=%sms'):format(
                    stage,
                    descriptor,
                    tostring(phase.name or index),
                    tostring(phase.animDict),
                    tostring(phase.pedAnim),
                    tostring(phaseMeasuredMs)
                )
            )
        end
    end

    if totalMeasuredMs <= 0 then
        return
    end

    local configuredMs = tonumber(payload and payload.duration) or 0
    local deltaMs = totalMeasuredMs - configuredMs
    printSceneProfile(
        ('%s %s sequence_total=%sms configured=%sms delta=%+dms'):format(
            stage,
            descriptor,
            totalMeasuredMs,
            configuredMs,
            deltaMs
        )
    )
    local suggestedLine = nil
    if stage == 'payphone' then
        suggestedLine = ('Config.Payphones.SceneDurationMs = %s,'):format(totalMeasuredMs)
    elseif stage == 'drop' then
        suggestedLine = ('%s = %s,'):format(tostring(payload and payload.variant or 'briefcase'), totalMeasuredMs)
    end

    if suggestedLine then
        printSceneProfile(('suggested config: %s'):format(suggestedLine))
    end

    if shouldNotifySceneProfile() then
        UIBridge.Notify({
            title = Config.Notifications.Title,
            description = ('Profiled %s sequence: %sms. Check F8/server console.'):format(stage, totalMeasuredMs),
            type = 'inform',
        })
    end

    if shouldEchoSceneProfileToServer() then
        TriggerServerEvent('ff_deaddrops:server:reportSceneProfile', {
            stage = stage,
            descriptor = descriptor,
            animDict = phases[1].animDict,
            pedAnim = ('sequence(%s)'):format(#phases),
            measuredMs = totalMeasuredMs,
            configuredMs = configuredMs,
            suggestedLine = suggestedLine,
        })
    end
end

local function runFallbackProgress(label, durationMs)
    return UIBridge.ProgressCircle({
        duration = durationMs,
        label = label,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            combat = true,
            car = true,
        }
    }) == true
end

local function getAnchorObject(scene)
    local objects = scene and scene.objects or {}
    if #objects == 0 then
        return nil
    end

    local anchorObject = objects[scene.anchorObjectIndex or 1]
    if anchorObject and anchorObject.anim and anchorObject.model then
        return anchorObject
    end

    for index = 1, #objects do
        local objectEntry = objects[index]
        if objectEntry.anim and objectEntry.model then
            return objectEntry
        end
    end

    return nil
end

local function buildSceneAlignment(scene, anchorCoords, anchorHeading)
    if not scene or not anchorCoords or not scene.animDict or not scene.pedAnim then
        return nil
    end

    local anchorObject = getAnchorObject(scene)
    if not anchorObject or not anchorObject.anim then
        return nil
    end

    if not loadAnimDict(scene.animDict) then
        return nil
    end

    local desiredAnchorCoords = vector3(anchorCoords.x + 0.0, anchorCoords.y + 0.0, anchorCoords.z + 0.0)
    local desiredAnchorHeading = normalizeHeading(anchorHeading or 0.0)
    local sceneOrigin = vector3(
        desiredAnchorCoords.x,
        desiredAnchorCoords.y,
        desiredAnchorCoords.z + (scene.deltaZ or 0.0)
    )

    local anchorRotation = GetAnimInitialOffsetRotation(
        scene.animDict,
        anchorObject.anim,
        sceneOrigin.x,
        sceneOrigin.y,
        sceneOrigin.z,
        0.0,
        0.0,
        desiredAnchorHeading,
        0,
        2
    )
    local headingOffset = getSignedHeadingDelta(
        (anchorRotation and anchorRotation.z) or desiredAnchorHeading,
        desiredAnchorHeading
    )
    local sceneHeading = normalizeHeading(desiredAnchorHeading - headingOffset)
    local resolvedAnchorCoords = nil

    for _ = 1, 2 do
        resolvedAnchorCoords = GetAnimInitialOffsetPosition(
            scene.animDict,
            anchorObject.anim,
            sceneOrigin.x,
            sceneOrigin.y,
            sceneOrigin.z,
            0.0,
            0.0,
            sceneHeading,
            0,
            2
        )

        if not resolvedAnchorCoords then
            break
        end

        local correction = vector3(
            desiredAnchorCoords.x - resolvedAnchorCoords.x,
            desiredAnchorCoords.y - resolvedAnchorCoords.y,
            desiredAnchorCoords.z - resolvedAnchorCoords.z
        )
        sceneOrigin = vector3(
            sceneOrigin.x + correction.x,
            sceneOrigin.y + correction.y,
            sceneOrigin.z + correction.z
        )

        if #correction <= 0.001 then
            break
        end
    end

    resolvedAnchorCoords = GetAnimInitialOffsetPosition(
        scene.animDict,
        anchorObject.anim,
        sceneOrigin.x,
        sceneOrigin.y,
        sceneOrigin.z,
        0.0,
        0.0,
        sceneHeading,
        0,
        2
    )

    local pedCoords = GetAnimInitialOffsetPosition(
        scene.animDict,
        scene.pedAnim,
        sceneOrigin.x,
        sceneOrigin.y,
        sceneOrigin.z,
        0.0,
        0.0,
        sceneHeading,
        0,
        2
    )
    local pedRotation = GetAnimInitialOffsetRotation(
        scene.animDict,
        scene.pedAnim,
        sceneOrigin.x,
        sceneOrigin.y,
        sceneOrigin.z,
        0.0,
        0.0,
        sceneHeading,
        0,
        2
    )

    unloadAnimDict(scene.animDict)

    if not pedCoords then
        return nil
    end

    local anchorError = 0.0
    if resolvedAnchorCoords then
        anchorError = #(desiredAnchorCoords - resolvedAnchorCoords)
    end

    if Config.Debug and anchorError > 0.03 then
        FFUtils.Log(
            ('Scene alignment residual %.3f for %s:%s'):format(
                anchorError,
                scene.animDict,
                scene.pedAnim
            )
        )
    end

    return {
        origin = sceneOrigin,
        heading = sceneHeading,
        pedCoords = pedCoords,
        pedHeading = normalizeHeading((pedRotation and pedRotation.z) or sceneHeading),
        anchorCoords = desiredAnchorCoords,
        anchorHeading = desiredAnchorHeading,
        anchorError = anchorError,
    }
end

local function preparePedForSceneAlignment(alignment, ped, snapTolerance, headingTolerance)
    if not alignment or not ped or ped == 0 or not DoesEntityExist(ped) then
        return false
    end

    local pedCoords = alignment.pedCoords
    if not pedCoords then
        return false
    end

    local positionTolerance = math.max(tonumber(snapTolerance) or 0.01, 0.01)
    local currentCoords = GetEntityCoords(ped)
    local currentHeading = GetEntityHeading(ped)
    local needsPosition = #(currentCoords - pedCoords) > positionTolerance
    local needsHeading = getHeadingDelta(currentHeading, alignment.pedHeading) > (tonumber(headingTolerance) or 2.0)
    if not needsPosition and not needsHeading then
        return true
    end

    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    if needsPosition then
        ClearPedTasksImmediately(ped)
        SetEntityCoordsNoOffset(ped, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
    end

    if needsHeading then
        SetEntityHeading(ped, alignment.pedHeading)
    end

    return true
end

local function runScene(scene, coords, heading, label, options)
    if not scene then
        return runFallbackProgress(label, 3000)
    end

    local runOptions = options or {}
    local ped = runOptions.ped or PlayerPedId()
    local isRemote = runOptions.remote == true
    local sceneDurationMs = getSceneDurationMs(scene, runOptions.durationMs)
    local anchorCoords = runOptions.anchorCoords or coords
    local anchorHeading = runOptions.anchorHeading or heading or 0.0
    local alignment = runOptions.fixedAlignment or buildSceneAlignment(scene, anchorCoords, anchorHeading)
    local sceneOrigin = alignment and alignment.origin or vector3(coords.x, coords.y, coords.z + (scene.deltaZ or 0.0))
    local sceneHeading = alignment and alignment.heading or normalizeHeading(heading or 0.0)
    local objectSpawnCoords = alignment and alignment.anchorCoords or vector3(coords.x, coords.y, coords.z)

    if not isRemote then
        if not preparePedForSceneAlignment(
            alignment,
            ped,
            runOptions.snapTolerance,
            runOptions.headingTolerance
        ) then
            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
            ClearPedTasksImmediately(ped)
            SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
            SetEntityHeading(ped, heading or 0.0)
        end
    end

    if not loadAnimDict(scene.animDict) then
        return runFallbackProgress(label, sceneDurationMs)
    end

    local spawnedObjects = {}
    local objectLoadFailed = false

    for index = 1, #(scene.objects or {}) do
        local objectEntry = scene.objects[index]
        local hash = loadModel(objectEntry.model)
        if hash == 0 then
            objectLoadFailed = true
            break
        end

        local entity = CreateObject(
            hash,
            objectSpawnCoords.x,
            objectSpawnCoords.y,
            objectSpawnCoords.z,
            true,
            true,
            false
        )
        if not entity or entity == 0 then
            objectLoadFailed = true
            SetModelAsNoLongerNeeded(hash)
            break
        end

        SetEntityAsMissionEntity(entity, true, true)
        FreezeEntityPosition(entity, false)
        SetEntityCollision(entity, false, false)
        SetEntityHeading(entity, sceneHeading)
        spawnedObjects[#spawnedObjects + 1] = {
            entity = entity,
            hash = hash,
            anim = objectEntry.anim,
        }
    end

    if objectLoadFailed then
        for index = 1, #spawnedObjects do
            DropClientRemoveEntity(spawnedObjects[index].entity)
            SetModelAsNoLongerNeeded(spawnedObjects[index].hash)
        end

        unloadAnimDict(scene.animDict)
        return runFallbackProgress(label, sceneDurationMs)
    end

    allowRemoteSyncedSceneEntity(ped)
    for index = 1, #spawnedObjects do
        allowRemoteSyncedSceneEntity(spawnedObjects[index].entity)
    end

    local sceneId = NetworkCreateSynchronisedScene(
        sceneOrigin.x,
        sceneOrigin.y,
        sceneOrigin.z,
        0.0,
        0.0,
        sceneHeading,
        2,
        true,
        false,
        -1.0,
        0,
        1.0
    )

    NetworkAddPedToSynchronisedScene(
        ped,
        sceneId,
        scene.animDict,
        scene.pedAnim,
        2.0,
        -4.0,
        1,
        0,
        1148846080,
        0
    )

    for index = 1, #spawnedObjects do
        NetworkAddEntityToSynchronisedScene(
            spawnedObjects[index].entity,
            sceneId,
            scene.animDict,
            spawnedObjects[index].anim,
            1.0,
            1.0,
            1
        )
    end

    NetworkStartSynchronisedScene(sceneId)
    Wait(sceneDurationMs)
    if not isRemote and runOptions.clearTasksOnFinish ~= false then
        ClearPedTasks(ped)
    end

    for index = 1, #spawnedObjects do
        DropClientRemoveEntity(spawnedObjects[index].entity)
        SetModelAsNoLongerNeeded(spawnedObjects[index].hash)
    end

    unloadAnimDict(scene.animDict)
    return true, sceneDurationMs
end

local function runSceneSequence(sceneOrEntry, coords, heading, label, options)
    local phases = getScenePhaseList(sceneOrEntry)
    if #phases == 0 then
        return runFallbackProgress(label, 3000)
    end

    local runOptions = options or {}
    local totalDurationMs = 0
    local sequenceAlignment = nil

    if #phases > 1 then
        sequenceAlignment = buildSceneAlignment(
            phases[1],
            runOptions.anchorCoords or coords,
            runOptions.anchorHeading or heading or 0.0
        )
    end

    for index = 1, #phases do
        local phaseOptions = FFUtils.DeepCopy(runOptions)
        local phase = phases[index]
        local phaseDurationMs = getRawSceneDurationMs(phase) or 0
        phaseOptions.clearTasksOnFinish = index == #phases
        phaseOptions.snapTolerance = index == 1 and 0.01 or (runOptions.sequenceSnapTolerance or 0.20)
        phaseOptions.headingTolerance = index == 1 and 2.0 or (runOptions.sequenceHeadingTolerance or 6.0)
        phaseOptions.fixedAlignment = sequenceAlignment
        if type(runOptions.onPhaseStart) == 'function' then
            runOptions.onPhaseStart(index, phase, #phases, phaseDurationMs)
        end

        local completed, resolvedDurationMs = runScene(phase, coords, heading, label, phaseOptions)
        if not completed then
            return false, totalDurationMs
        end

        totalDurationMs = totalDurationMs + (resolvedDurationMs or phaseDurationMs or 0)

        if index < #phases then
            Wait(runOptions.sequencePhaseGapMs or 0)
        end
    end

    return true, totalDurationMs
end

function DropClientRunPayphoneScene(payload, onPhaseStart)
    local sceneEntry = getPayphoneSceneByIndex(payload and payload.sceneSet or 'simple', payload and payload.sceneIndex)
        or getPayphoneScene(payload and payload.sceneSet or 'simple')
    reportSceneProfile('payphone', sceneEntry, payload)
    return runSceneSequence(sceneEntry, payload.coords, payload.heading or 0.0, Config.Payphones.ProgressLabel or 'Using payphone', {
        anchorCoords = payload and payload.anchorCoords,
        anchorHeading = payload and payload.anchorHeading,
        onPhaseStart = onPhaseStart,
    })
end

function DropClientRunDropScene(payload, onPhaseStart)
    local sceneEntry = getDropScene(payload and payload.variant or 'briefcase')
    reportSceneProfile('drop', sceneEntry, payload)
    return runSceneSequence(sceneEntry, payload.coords, payload.heading or 0.0, Config.Drops.ProgressLabel or 'Recovering dead drop', {
        anchorCoords = payload and payload.anchorCoords,
        anchorHeading = payload and payload.anchorHeading,
        onPhaseStart = onPhaseStart,
    })
end

function DropClientRunRemotePayphoneScene(serverId, ped, payload)
    local sceneEntry = getPayphoneSceneByIndex(payload and payload.sceneSet or 'simple', payload and payload.sceneIndex)
        or getPayphoneScene(payload and payload.sceneSet or 'simple')
    local phaseIndex = math.floor(tonumber(payload and payload.phaseIndex) or 0)
    if phaseIndex > 0 then
        local phase = getScenePhaseByIndex(sceneEntry, phaseIndex)
        if not phase then
            return false
        end

        return runScene(phase, payload.coords, payload.heading or 0.0, Config.Payphones.ProgressLabel or 'Using payphone', {
            anchorCoords = payload and payload.anchorCoords,
            anchorHeading = payload and payload.anchorHeading,
            ped = ped,
            remote = true,
        })
    end

    return runSceneSequence(sceneEntry, payload.coords, payload.heading or 0.0, Config.Payphones.ProgressLabel or 'Using payphone', {
        anchorCoords = payload and payload.anchorCoords,
        anchorHeading = payload and payload.anchorHeading,
        ped = ped,
        remote = true,
    })
end

function DropClientRunRemoteDropScene(serverId, ped, payload)
    local sceneEntry = getDropScene(payload and payload.variant or 'briefcase')
    local phaseIndex = math.floor(tonumber(payload and payload.phaseIndex) or 0)
    if phaseIndex > 0 then
        local phase = getScenePhaseByIndex(sceneEntry, phaseIndex)
        if not phase then
            return false
        end

        return runScene(phase, payload.coords, payload.heading or 0.0, Config.Drops.ProgressLabel or 'Recovering dead drop', {
            anchorCoords = payload and payload.anchorCoords,
            anchorHeading = payload and payload.anchorHeading,
            ped = ped,
            remote = true,
        })
    end

    return runSceneSequence(sceneEntry, payload.coords, payload.heading or 0.0, Config.Drops.ProgressLabel or 'Recovering dead drop', {
        anchorCoords = payload and payload.anchorCoords,
        anchorHeading = payload and payload.anchorHeading,
        ped = ped,
        remote = true,
    })
end
