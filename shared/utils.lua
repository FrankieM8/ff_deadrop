FFUtils = FFUtils or {}

function FFUtils.DeepCopy(tbl)
    if type(tbl) ~= 'table' then
        return tbl
    end

    local copy = {}
    for key, value in pairs(tbl) do
        copy[key] = FFUtils.DeepCopy(value)
    end
    return copy
end

function FFUtils.MergeDeep(base, override)
    local merged = FFUtils.DeepCopy(base or {})

    for key, value in pairs(override or {}) do
        if type(value) == 'table' and type(merged[key]) == 'table' then
            merged[key] = FFUtils.MergeDeep(merged[key], value)
        else
            merged[key] = FFUtils.DeepCopy(value)
        end
    end

    return merged
end

function FFUtils.RandomId(prefix)
    local salt = math.random(100000, 999999)
    return ('%s_%s_%s'):format(prefix or 'id', GetGameTimer(), salt)
end

function FFUtils.WeightedChoice(entries)
    local totalWeight = 0

    for index = 1, #entries do
        totalWeight = totalWeight + (entries[index].weight or 0)
    end

    if totalWeight <= 0 then
        return nil
    end

    local roll = math.random() * totalWeight
    local cursor = 0

    for index = 1, #entries do
        cursor = cursor + (entries[index].weight or 0)
        if roll <= cursor then
            return entries[index]
        end
    end

    return entries[#entries]
end

function FFUtils.VectorDistance(a, b)
    return #(a - b)
end

function FFUtils.Log(message)
    if not Config.Logging.Enabled then
        return
    end

    print(('%s %s'):format(Config.Logging.Prefix, message))
end
