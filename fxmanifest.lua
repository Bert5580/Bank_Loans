fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Bank Loan System with QB-Core Integration'
version 'Qv1.0.7'

lua54 'yes'

shared_scripts {
    'config.lua'
}

client_scripts {
    'locales/en.lua',
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'qb-core',
    'oxmysql',
    --'qb-menu' -- Ensure qb-menu is required for UI
    --'qb-target' -- Ensure qb-target is used properly for NPC interaction
}
