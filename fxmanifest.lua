fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Frankie / Codex'
description 'ff_deaddrops - payphone-routed dead drops with synced pickup scenes'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
    'bridge/framework/qbox.lua',
    'bridge/framework/qbcore.lua',
    'bridge/framework/esx.lua',
    'bridge/framework/init.lua',
    'bridge/inventory/ox_inventory.lua',
    'bridge/inventory/qb_inventory.lua',
    'bridge/inventory/init.lua',
    'bridge/ui/*.lua',
}

client_scripts {
    'client/functions.lua',
    'client/client.lua',
}

server_scripts {
    'server/server_functions.lua',
    'server/server.lua',
}

dependencies {
    'ox_lib',
}
