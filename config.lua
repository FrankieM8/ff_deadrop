Config = {}

Config.Framework = 'auto'
Config.Inventory = 'auto'
Config.Debug = false
Config.Dev = {
    SceneProfiler = {
        Enabled = true,
        Notify = true,
        EchoToServer = true,
    },
}

Config.Items = {
    Triggers = {
        {
            name = 'burnerphone',
            label = 'Burner Phone',
            export = 'useBurnerPhone',
            consume = true,
        },
        {
            name = 'codednote',
            label = 'Coded Note',
            export = 'useCodedNote',
            consume = true,
        },
    },
}

Config.Lead = {
    OneActiveLeadPerPlayer = true,
    AvoidImmediateRepeat = true,
    SetWaypoint = true,
}

Config.Payphones = {
    InteractionRadius = 2.2,
    StartRadius = 3.0,
    CompleteRadius = 4.0,
    SceneDurationMs = 4200,
    Prompt = '[E] Use payphone',
    ProgressLabel = 'Using payphone',
    SceneSet = 'contract',
    SpawnRadius = 80.0,
    Blip = {
        Sprite = 304,
        Colour = 2,
        Scale = 0.85,
        Label = 'Dead Drop Contact',
    },
    Prop = {
        Freeze = true,
        Collision = false,
    },
    Locations = {
        vector4(-561.96, -180.08, 37.12, 203.68),
    },
}

Config.Drops = {
    SearchRadius = 18.0,
    InteractionRadius = 2.25,
    StartRadius = 3.2,
    CompleteRadius = 4.5,
    SceneDurationMs = {
        street_handoff = 3200,
        counter_package = 3200,
    },
    Prompt = '[E] Recover dead drop',
    ProgressLabel = 'Recovering dead drop',
    Blip = {
        Sprite = 501,
        Colour = 5,
        Scale = 0.85,
        Label = 'Dead Drop Search Area',
        RadiusAlpha = 30,
    },
    Clue = {
        SpawnRadius = 22.0,
        Freeze = true,
        Collision = false,
        PlaceOnGround = true,
        MarkerFallback = {
            Enabled = true,
            Type = 1,
            Scale = { x = 0.35, y = 0.35, z = 0.2 },
            Colour = { r = 214, g = 178, b = 58, a = 130 },
        },
    },
    Variants = {
        { name = 'street_handoff', weight = 50 },
        { name = 'counter_package', weight = 50 },
    },
    Locations = {
        vector4(566.1108, -2262.4010, 6.8774, 180.0),
        vector4(972.0025, -2639.1370, 5.2237, 270.0),
        vector4(-1472.0480, -2199.2100, 5.4694, 90.0),
        vector4(-1627.6570, -2430.8560, 5.2252, 180.0),
        vector4(1557.5802, -2599.4595, 50.7662, 90.0),
        vector4(11.7224, 3270.1080, 41.4438, 180.0),
        vector4(167.6112, 2240.7060, 90.8916, 270.0),
        vector4(814.5887, 1304.3290, 363.1665, 20.0),
        vector4(-328.4383, 826.3292, 197.5365, 160.0),
        vector4(-440.0566, 5715.1016, 61.3938, 310.0),
        vector4(-2044.4957, 5256.3354, 16.9750, 135.0),
        vector4(1325.6049, 4481.9702, 61.1525, 20.0),
    },
}

Config.Rewards = {
    Cash = {
        Enabled = true,
        IncludeItemReward = false,
        Account = 'cash',
        Min = 800,
        Max = 3200,
    },
    DefaultItemAmount = 1,
    Items = {
        {
            item = 'cashroll',
            label = 'Cash Roll',
            weight = 30,
            amount = 1,
        },
        {
            item = 'bankenvelope',
            label = 'Bank Envelope',
            weight = 25,
            amount = 1,
        },
        {
            item = 'intelpacket',
            label = 'Intel Packet',
            weight = 20,
            amount = 1,
        },
        {
            item = 'rarewatch',
            label = 'Rare Watch',
            weight = 15,
            amount = 1,
        },
        {
            item = 'blackmailphotos',
            label = 'Blackmail Photos',
            weight = 10,
            amount = 1,
        },
    },
}

Config.Notifications = {
    Title = 'Dead Drops',
}

Config.Logging = {
    Enabled = true,
    Prefix = '^5[ff_deaddrops]^7',
}
